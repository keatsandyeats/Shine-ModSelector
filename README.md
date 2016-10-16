## [Shine] Mod Selector
A [Shine](https://github.com/Person8880/Shine) plugin for Natural Selection 2.  
Mod Selector allows you to enable and disable mods from in-game. It adds two console commands, `sh_enablemods` and `sh_disablemods`. It also adds a "Mods" tab to the Admin Menu, where mods can be toggled graphically.   

Its Steam Workshop ID is [2cbea77a](https://steamcommunity.com/sharedfiles/filedetails/?id=750692218).  

Its GitHub repo is [here](https://github.com/keatsandyeats/Shine-ModSelector). Issues and pull requests are welcome.  

## Usage  
Make sure you have activated the plugin with Shine.    

`sh_enablemods` adds mods to the server's MapCycle. You can give it any number of hexadecimal mod IDs separated by non-hex characters (e.g. g, -, space). Case does not matter.
For example, `sh_enablemods aBc123 123ABC` will add two mod entries to MapCycle.json, `"abc123"` and `"123abc"`. 

`sh_disablemods` removes mods from the server's MapCycle. You can give it any number of hexadecimal mod IDs separated by non-hex characters (e.g. g, -, space). Case does not matter.
For example, `sh_disablemods AbC123 123abc` will remove those two mod entries from MapCycle.json.  

Users with access to `sh_adminmenu` and either command above will have access to the new "Mods" tab of Shine's graphical Admin Menu.
Users with access to `sh_enablemods`, but not `sh_disablemods`, will be able to enable mods but not disable them. Users with access to `sh_disablemods`, but not `sh_enablemods`, will be able to disable mods but not enable them.  
See the section *Configuration file* to learn how to populate this menu with mod names.    

**Note that changes to MapCycle.json will not be reflected on the server until the map has changed twice.** This is because NS2 caches the MapCycle on the server.  


## Configuration file  
The plugin looks for its config file at `config://shine/plugins/ModSelector.json`, or wherever you told Shine to place its plugins.  
If the file does not exist, a default one is created that looks like this:  
````    
{
    "exampleHex" = {
		"displayname" = "human-readable name",
		"enabled" = false
	}
}  
````  
Mods that are already in MapCycle.json will be imported to the config each time the plugin loads. Their display names will be "unknown" until you edit their config entries. This display name will be shown in the Admin Menu (the hex ID will not).  

To add a new mod to the Admin Menu, replace "exampleHex" with a hexadecimal Workshop ID (e.g. "2cbea77a"). Replace "human-readable name" with a unique, identifiable string (e.g. "Shine ModSelector").  

Each mod entry must have the "enabled" parameter, but its boolean value is for internal use only. If you are manually adding a new mod entry, be sure to include `"enabled" = false`.  

If you have added at least one other mod to the config, you may safely delete the "exampleHex" entry. Or you can simply leave it in the config; it will not appear in the Admin Menu.  

## Known Issues  

## Future plans  
Remove "enabled" from the config as it is not actually changeable by the user.  
Automatically retrieve mod names from Steam Workshop.  
