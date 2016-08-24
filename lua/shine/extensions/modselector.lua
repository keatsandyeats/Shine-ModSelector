--[[
	A Shine plugin to enable and disable server mods in-game.
	
	The config will have a list of mod hexes, each with true/false attribute.
	The config will pull mods from MapCycle.json or mods can be manually added to the config.
	The config list is just so shine's gui has something to pull from.
	Manually editing true/false will be overwritten at plugin load when it reads from MapCycle.json.
	TODO: The command will be hooked up to Shine's admin menu.
	TODO: Possibly change Config.Mod values to string modnames instead of bools
--]]

local Shine = Shine
local Plugin = {}

Plugin.Version = "0.5"

Plugin.HasConfig = true
Plugin.ConfigName = "ModSelector.json"
Plugin.CheckConfig = true
Plugin.CheckConfigTypes = true

Plugin.DefaultConfig = {
	Mods =
	{
		
	}
}

Plugin.MapCycleFileName = "MapCycle.json"

function Plugin:Initialise()
	self:SanitizeConfig()
	
	self.MapCycle = LoadConfigFile(self.MapCycleFileName)
	
	self:SanitizeMapCycle()
	
	self:MapCycleToConfig() --add mods from the mapcycle to the config
	
	self:CreateCommands()
	
	self.Enabled = true
	
	return true
end

--[[
	make sh_ commands for shine
--]]
function Plugin:CreateCommands()

	--don't know how to get shine commands to accept variable arguments so 1 string -> unpacked array
	local function EnableMods(client, modString)
		modArray = ExplodeHex(modString)
		
		self:ChangeMods(true, unpack(modArray))
	end
	
	local EnableModsCommand = self:BindCommand("sh_enablemods", "enablemods", EnableMods, false, true)
	EnableModsCommand:AddParam{Type = "string", TakeRestOfLine = true, Help = "mod hexes separated by space"}
	EnableModsCommand:Help("Add mod(s) to the MapCycle.")
	
	local function DisableMods(client, modString)
		modArray = ExplodeHex(modString)
		
		self:ChangeMods(false, unpack(modArray))
	end
	
	local DisableModsCommand = self:BindCommand("sh_disablemods", "disablemods", DisableMods, false, true)
	DisableModsCommand:AddParam{Type = "string", TakeRestOfLine = true, Help = "mod hexes separated by space"}
	DisableModsCommand:Help("Remove mod(s) from the MapCycle.")
	
	--[[ 
		take a string of hexadecimals delimited by non-hex chars and put them all
		in an array
	--]]
	--local?
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
	TODO: maybe change boolean value to string (mod name for GUI). figure out how to do that with only one mapcycle.json write
--]]
function Plugin:ChangeMods(enabled, ...)
	local arg = {...}
	local changed --are any mods actually changing state?
	
	if enabled == false or enabled == "false" or enabled == "0"  or enabled == 0 then
		enabled = false
	else
		enabled = true
	end
	
	for i,newMod in ipairs(arg) do
		newMod = SanitizeMod(newMod)
		
		if self.Config.Mods[newMod] ~= enabled then
			self.Config.Mods[newMod] = enabled
		
			changed = true
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
	
	for configMod,enabled in pairs(self.Config.Mods) do
		if table.HasValue(self.MapCycle["mods"], configMod) then
			if not enabled then
				--remove mod from mapcycle
				
				--note: a mapCycleIndex can be gotten from table.HasValue, but that wouldn't handle dupes
				for mapCycleIndex,mapCycleMod in ipairs(self.MapCycle["mods"]) do
					if mapCycleMod == configMod then
						table.remove(self.MapCycle["mods"], mapCycleIndex)
						
						--TODO: comment-out mod in mapcycle instead?
						
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
	
	--TODO: vanilla's dkjson formatting sucks. copy shine's lua->json write somehow
	SaveConfigFile(self.MapCycleFileName, self.MapCycle) --write to MapCycle.json
end

--[[
	Import mods from the mapcycle to the Config file. 
	Imported mods are enabled. Existing mods in Config are disabled.
	TODO: handle commented mods?
	TODO: save comments somehow? (maybe impossible)
--]]
function Plugin:MapCycleToConfig()

	--disable all mods in config
	for configMod,_ in pairs(self.Config.Mods) do
		self.Config.Mods[configMod] = false
	end
	
	--enable mods from mapcycle
	for _,mapCycleMod in ipairs(self.MapCycle["mods"]) do
		self.Config.Mods[mapCycleMod] = true
	end
	
	--self:SaveConfig() --write to config file?
end

--[[
	keeps mods consistently named for comparability
	TODO: check for alpha-num, utf8, add error handling
--]]
function SanitizeMod(modName)
	return string.lower(tostring(modName))
end

--[[
	cleans up the mapcycle so that we can read it properly
	TODO: remove dupes?
--]]
function Plugin:SanitizeMapCycle()

	--if MapCycle doesn't have a mod section then make an empty one
	if not self.MapCycle["mods"] then
		self.MapCycle["mods"] = {}
	end

	for i,modName in ipairs(self.MapCycle["mods"]) do
		self.MapCycle["mods"][i] = SanitizeMod(modName)
	end
	
	--SaveConfigFile(self.MapCycleFileName, self.MapCycle) --write to mapcycle.json?
end

--[[
	cleans up the Config file in case the user edited it badly
	TODO: make this more robust
	shine already checks for missing entries and types
--]]
function Plugin:SanitizeConfig()
	local cleanModName
	
	for modName,enabled in pairs(self.Config.Mods) do
		cleanModName = SanitizeMod(modName)
		
		--order is important in case mod is already clean
		self.Config.Mods[modName] = nil --remove the dirty mod
		self.Config.Mods[cleanModName] = enabled --add the sanitized mod
	end
	
	--self:SaveConfig() --write to config file. necessary?
end

Shine:RegisterExtension("modselector", Plugin)
