--[[
	A Shine plugin to enable and disable server mods in-game.
--]]
	-- The config will have a list of mod hexes, each with a string and a boolean attribute.
	-- The config will pull mods from MapCycle.json or mods can be manually added to the config.
	-- The config list is just so shine's gui has something to pull from.
	-- Manually editing true/false will be overwritten at plugin load when it reads from MapCycle.json.
	-- TODO: The command will be hooked up to Shine's admin menu.
	-- TODO: remove boolean from config as it's useless for the end user


local Shine = Shine
local Plugin = {}

Shine:RegisterExtension("modselector", Plugin)