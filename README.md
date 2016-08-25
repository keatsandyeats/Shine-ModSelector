## [Shine] Mod Selector
A [Shine](https://github.com/Person8880/Shine) plugin for Natural Selection 2.  
Mod Selector allows you to enable and disable mods from in-game. It adds two console commands, `sh_enablemods` and `sh_disablemods`.  

Its Steam Workshop ID is [2cbea77a](https://steamcommunity.com/sharedfiles/filedetails/?id=750692218).  

Its GitHub repo is [here](https://github.com/keatsandyeats/Shine-ModSelector). Issues and pull requests are welcome.  

## Usage
`sh_enablemods` adds mods to the server's MapCycle. You can give it any number of hexadecimal mod IDs separated by non-hex characters (e.g. g, -, space). Case does not matter.
For example, `sh_enablemods abc123 123abc` will add two mod entries to MapCycle.json, `"abc123"` and `"123abc"`. 

`sh_disablemods` removes mods from the server's MapCycle. You can give it any number of hexadecimal mod IDs separated by non-hex characters (e.g. g, -, space). Case does not matter.
For example, `sh_disablemods abc123 123abc` will remove those two mod entries from MapCycle.json.  

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

## Future plans  
Use Shine's GUI to give you a selectable list of mods with human-readable names 

## Distant future plans
Currently I use vanilla NS2's config writing system to edit MapCycle.json. This makes your new MapCycle rather condensed and squashed. Eventually I hope to enhance this with pretty whitespace and newlines.