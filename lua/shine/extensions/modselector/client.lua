--[[
    [Shine] ModSelector by Keats & Yeats.
    A Shine plugin to enable and disable server mods in-game.
    Please see https://github.com/keatsandyeats/Shine-ModSelector for more information.
--]]

local Shine = Shine
local Plugin = Plugin
local SGUI = Shine.GUI

Plugin.HasConfig = false

Plugin.ModsReceived = false --has the server sent us a mod yet?

function Plugin:Initialise()
    self:SetupAdminMenuCommands()

    self.Enabled = true

    return true
end

function Plugin:SetupAdminMenuCommands()
    local Units = SGUI.Layout.Units
    local HighResScaled = Units.HighResScaled
    local Percentage = Units.Percentage
    local Spacing = Units.Spacing
    local UnitVector = Units.UnitVector
    local Auto = Units.Auto

    ModTabData = {
        OnInit = function(Panel, Data)
            local Layout = SGUI.Layout:CreateLayout("Vertical", {
                Padding = Spacing(HighResScaled(16), HighResScaled(28),
                    HighResScaled(16), HighResScaled(16))
            })

            local List = SGUI:Create("List", Panel)
            List:SetColumns("Mod", "Config (Server)")
            List:SetSpacing(0.7, 0.3)
            List:SetSecondarySortColumn(2,1)
            List:SetFill(true)

            Shine.AdminMenu.SetupListWithScaling(List)

            Layout:AddElement(List)

            self.ModList = List

            self:RequestModData()

            --sort list by Enabled
            List:SortRows(2, nil, true)

            local Font, Scale = SGUI.FontManager.GetHighResFont("kAgencyFB", 27)

            local ControlLayout = SGUI.Layout:CreateLayout("Horizontal", {
                Margin = Spacing(0, HighResScaled(16), 0, 0),
                Fill = false
            })

            --returns the hexID of the selected mod
            local function GetSelectedMod()
                local Selected = List:GetSelectedRow()
                if not Selected then return end

                return Selected.HexID
            end

            local DisableMod = SGUI:Create("Button", Panel)
            DisableMod:SetText("Disable Mod")
            DisableMod:SetFontScale(Font, Scale)
            DisableMod:SetEnabled(List:HasSelectedRow())

            function DisableMod.DoClick(Button)
                local Mod = GetSelectedMod()
                local isEnabled = self.ModData[Mod]["enabled"]
                local isActive = self.ModData[Mod]["active"]

                if not Mod then return false end --a nil mod means no selection, so do nothing
                if not isEnabled then return false end --if mod is already disabled then do nothing

                --change mod's status in the mod table
                self.ModData[Mod]["enabled"] = false

                --change mod's status in the list
                for i=1,#List.Rows do --for loop is inefficient but I don't know a better way
                    if List.Rows[i]["HexID"] == Mod then
                        local newColumnText = string.format("%s (%s)", "Disabled", isActive and "Active" or "Inactive")

                        List.Rows[i]:SetColumnText(2, newColumnText)

                        break
                    end
                end

                Shine.AdminMenu:RunCommand("sh_disablemods", Mod)
            end

            ControlLayout:AddElement(DisableMod)

            local EnableMod = SGUI:Create("Button", Panel)
            EnableMod:SetText("Enable Mod")
            EnableMod:SetFontScale(Font, Scale)
            EnableMod:SetAlignment(SGUI.LayoutAlignment.MAX)
            EnableMod:SetEnabled(List:HasSelectedRow())

            function EnableMod.DoClick(Button)
                local Mod = GetSelectedMod()
                local isEnabled = self.ModData[Mod]["enabled"]
                local isActive = self.ModData[Mod]["active"]

                if not Mod then return false end --a nil mod means no selection, so do nothing
                if isEnabled then return false end --if mod is already enabled then do nothing

                --change mod's status in the mod table
                self.ModData[Mod]["enabled"] = true

                --change mod's status in the list
                for i=1,#List.Rows do --for loop is inefficient but I don't know a better way
                    if List.Rows[i]["HexID"] == Mod then
                        local newColumnText = string.format("%s (%s)", "Enabled", isActive and "Active" or "Inactive")

                        List.Rows[i]:SetColumnText(2, newColumnText)

                        break
                    end
                end

                Shine.AdminMenu:RunCommand("sh_enablemods", Mod)
            end

            ControlLayout:AddElement(EnableMod)

            function List:OnRowSelected()
                DisableMod:SetEnabled(true)
                EnableMod:SetEnabled(true)
            end

            function List:OnRowDeselected()
                DisableMod:SetEnabled(false)
                EnableMod:SetEnabled(false)
            end

            local ButtonWidth = Units.Max(
                HighResScaled(128),
                Auto(DisableMod) + HighResScaled(16),
                Auto(EnableMod) + HighResScaled(16)
            )

            DisableMod:SetAutoSize(UnitVector(ButtonWidth, Percentage(100)))
            EnableMod:SetAutoSize(UnitVector(ButtonWidth, Percentage(100)))

            local ButtonHeight = Auto(EnableMod) + HighResScaled(8)
            ControlLayout:SetAutoSize(UnitVector(Percentage(100), ButtonHeight))

            Layout:AddElement(ControlLayout)
            Panel:SetLayout(Layout)
            Panel:InvalidateLayout()

            if not self.ModsReceived then
                --delay populating the list to give network messages time to arrive
                self:CreateTimer("ModsListUpdate", 0.5, 1, function()
                    self:PopulateModList()
                end)
            else self:PopulateModList() end

        end,

        OnCleanup = function(Panel)
            self:DestroyTimer("ModsListUpdate")
        end
    }

    self:AddAdminMenuTab("Mods", ModTabData)
end

--[[
    Ask the server for all the mod data.
--]]
function Plugin:RequestModData()
    self:SendNetworkMessage("RequestModData", {}, true)
end

--[[
    handle the network message from the server that contains mod data
--]]
function Plugin:ReceiveModData(Data)
    self.ModData = self.ModData or {}
    self.ModData[Data.HexID] = {
        displayname = Data.DisplayName,
        enabled = Data.isEnabled,
        active = Data.isActive,
    }

    self.ModsReceived = true
end

--[[
    add a row for each mod to the mod list
--]]
function Plugin:PopulateModList()
    self.ModData = self.ModData or {}

    local List = self.ModList
    if not SGUI.IsValid(List) then return end

    for HexID, modData in pairs(self.ModData) do
        local enabledString = modData.enabled and "Enabled" or "Disabled"
        local activeString = modData.active and "Active" or "Inactive"
        local statusString = string.format("%s (%s)", enabledString, activeString)

        --add the row to the list display
        local Row = List:AddRow(modData.displayname, statusString)

        --add extra info for GetSelectedMod
        Row["HexID"] = HexID
    end
end
