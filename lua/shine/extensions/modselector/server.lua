--[[
    [Shine] ModSelector by Keats & Yeats.
    A Shine plugin to enable and disable server mods in-game.
    Please see https://github.com/keatsandyeats/Shine-ModSelector for more information.
--]]

local Shine = Shine
local Plugin = Plugin

Plugin.Version = "1.3"

Plugin.HasConfig = true
Plugin.ConfigName = "ModSelector.json"

Plugin.CheckConfig = false
Plugin.CheckConfigTypes = false

Plugin.DefaultConfig = {
    Mods = {
        exampleHex = {
            displayname = "human-readable name",
            enabled = false
        }
    }
}

Plugin.ConfigMigrationSteps = {
    {
        -- version 1.3 moved the mod list from the top level of the config to a "Mods" table
        VersionTo = "1.3",
        Apply = function(Config)
            Config.Mods = Config.Mods or {}

            for modID,modData in pairs(Config) do
                if modID ~= "__Version" and modID ~= "Mods" then
                    Config.Mods[modID] = Config.Mods[modID] or modData
                    Config[modID] = nil
                end
            end
        end
    }
}

Plugin.MapCycleFileName = "MapCycle.json"

function Plugin:Initialise()
    self:SanitizeConfig()

    self.MapCycle = LoadConfigFile(self.MapCycleFileName)

    self:SanitizeMapCycle()

    self:MapCycleToConfig() --add mods from the mapcycle to the internal config
    self:SaveConfig() --make sure we write to the config at least once

    self:CreateCommands()

    self.Enabled = true

    return true
end

--[[
    handle the network message from the client that requests mod data
--]]
function Plugin:ReceiveRequestModData(Client, Data)
    if not (Shine:GetPermission(Client, "sh_enablemods") or Shine:GetPermission(Client, "sh_disablemods")) then
        return --if the client doesn't have access to the right commands then ignore his request
    end

    for modID, modData in pairs(self.Config.Mods) do
        if modID ~= "examplehex" then -- don't send the example entry
            local enabled = modData.enabled
            local displayname = modData.displayname
                self:SendNetworkMessage(Client, "ModData", {
                    HexID = modID,
                    DisplayName = displayname,
                    Enabled = enabled,
                    }, true)
        end
    end
end

--[[
    make sh_ commands for shine
--]]
function Plugin:CreateCommands()

    local function EnableMods(client, modString)
        modArray = ExplodeHex(modString)

        self:ChangeMods(client, true, unpack(modArray))
    end

    local EnableModsCommand = self:BindCommand("sh_enablemods", "enablemods", EnableMods, false, true)
    EnableModsCommand:AddParam{Type = "string", TakeRestOfLine = true, Help = "mod hexes separated by space"}
    EnableModsCommand:Help("Add mod(s) to the MapCycle.")

    local function DisableMods(client, modString)
        modArray = ExplodeHex(modString)

        self:ChangeMods(client, false, unpack(modArray))
    end

    local DisableModsCommand = self:BindCommand("sh_disablemods", "disablemods", DisableMods, false, true)
    DisableModsCommand:AddParam{Type = "string", TakeRestOfLine = true, Help = "mod hexes separated by space"}
    DisableModsCommand:Help("Remove mod(s) from the MapCycle.")

    --[[
        take a string of hexadecimals delimited by non-hex chars and put them all
        in an array
    --]]
    function ExplodeHex(hexString)
        local hexArray = {}

        for hex in string.gmatch(hexString, "%x+") do
            table.insert(hexArray, hex)
        end

        return hexArray
    end
end

--[[
    Enables or disables a list of mods.
--]]
function Plugin:ChangeMods(Client, enabled, ...)
    local arg = {...}
    local changed --are any mods actually changing state?

    if enabled == false or enabled == "false" or enabled == "0"  or enabled == 0 then
        enabled = false
    else
        enabled = true
    end

    for _,newMod in ipairs(arg) do
        newMod = SanitizeMod(newMod)

        if self.Config.Mods[newMod] then --check if entry exists
            if self.Config.Mods[newMod]["enabled"] ~= enabled then
                self.Config.Mods[newMod]["enabled"] = enabled

                changed = true
            end
        else --if the mod is not in the Config, ignore it
            local enabledString = enabled and "enabled" or "disabled"
            local whitelistMessage = string.format("Mod %s is not whitelisted. It has not been %s.",
                newMod, enabledString)

            Shine.PrintToConsole(Client, whitelistMessage)
        end
    end

    if changed then
        self:SaveConfig() --update the Config file

        self:ConfigToMapCycle() --update the mapcycle
    end
end

--[[
    Write enabled mods to the mapcycle. Remove disabled mods from the mapcycle.
--]]
function Plugin:ConfigToMapCycle()
    local changed --will the mapcycle be changed?

    for configMod,configModData in pairs(self.Config.Mods) do

        local enabled = configModData["enabled"]

        if table.HasValue(self.MapCycle["mods"], configMod) then

            if not enabled then
                --remove mod from mapcycle

                --iterate backwards so removing doesn't skip entries
                for i=#self.MapCycle["mods"],1,-1 do
                    if self.MapCycle["mods"][i] == configMod then
                        table.remove(self.MapCycle["mods"], i)

                        changed = true
                    end
                end
            end
        elseif enabled then
            --add mod to mapcycle
            table.insert(self.MapCycle["mods"], configMod)

            changed = true
        end
    end

    if changed then
        SaveConfigFile(self.MapCycleFileName, self.MapCycle) --write to MapCycle.json
    end
end

--[[
    Import mods from the mapcycle to the Config file.
    Imported mods are enabled. Existing mods in Config are disabled.
--]]
function Plugin:MapCycleToConfig()

    --disable all mods in config
    for _,configModData in pairs(self.Config.Mods) do
        configModData["enabled"] = false
    end

    --enable mods from mapcycle
    for _,mapCycleMod in ipairs(self.MapCycle["mods"]) do
        if self.Config.Mods[mapCycleMod] then
            self.Config.Mods[mapCycleMod]["enabled"] = true
        else
            self.Config.Mods[mapCycleMod] = {["displayname"] = mapCycleMod, ["enabled"] = true}
        end
    end
end

--[[
    keeps mods consistently named for comparability
    input handling is not required as NS2 will gracefully ignore hex IDs that aren't mods
--]]
function SanitizeMod(modName)
    return string.lower(tostring(modName))
end

--[[
    cleans up the mapcycle so that we can read it properly
--]]
function Plugin:SanitizeMapCycle()

    --if MapCycle doesn't have a mod section then make an empty one
    if not self.MapCycle["mods"] then
        self.MapCycle["mods"] = {}
    end

    for i,modName in ipairs(self.MapCycle["mods"]) do
        self.MapCycle["mods"][i] = SanitizeMod(modName)
    end
end

--[[
    cleans up the Config file in case the user edited it badly
    TODO: make this more robust
--]]
function Plugin:SanitizeConfig()
    local cleanModName

    for modName,modData in pairs(self.Config.Mods) do
        cleanModName = SanitizeMod(modName)

        --make the entries we want if they don't exist
        modData.displayname = modData.displayname or modName
        modData.enabled = modData.enabled or false

        --order is important in case mod is already clean
        self.Config.Mods[modName] = nil --remove the dirty mod
        self.Config.Mods[cleanModName] = modData --add the sanitized mod
    end
end
