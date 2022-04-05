
# About
Model_DiagramGen is a plugin for the [Godot](https://github.com/godotengine/godot) game engine made with GDScript, uses to automaticaly generate block diagram reflecting project's nodes structure and interactions.


## Why Model_DiagramGen?
- Generate in one click an High level diagram for the project
- Help understanding the Interaction between the project's blocks/Nodes
- Help you to explain your project to 3rd party or remin yourself once what

---
# Getting Model_DiagramGen
## Godot Asset Library ([Godot Doc](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html))
Preferably, Model_DiagramGen is available in the [Godot Asset Library](link), allowing you to add it directly to your project from within Godot. Create or open an existing project and press on the 'AssetLib' tab found at the top of the editor. Once the asset library has loaded, search for  '*Model_DiagramGen*'. The top result should be this plugin, press on it and you'll be given the option to download it. Press to download and once it's completed Godot will ask you to select what you'd like to install. If you only want the plugin then only select the `addons` folder.

## Clone / Download
If for whatever reason you don't want to or can't download plugin via the in-engine Godot asset library, then you can always clone or download this repository directly. Once you've cloned or downloaded this repository, you can import it directly into Godot as a project to view the various examples and edit them directly. You may as well move the plugin's folder directly into your own project’s `addons` folder.

---
# Using Model_DiagramGen
**NOTE:** *After adding the plugin to your project you'll need to activate it in your project's `Plugins` configuration!*

Press `CTRL+G` to trigger the Plugin. <br>
The generated output will be by default located on the project root with the name `ModelDocumentation.md`

## Example of the output

![Example Diagram](https://github.com/arsany007/Model_DiagramGen/blob/main/Example/Example.png?raw=true)

### Color code
> Origin nodes -> Black - Solid - Blocks <br>
> Child nodes -> Red - Solid - Blocks <br>
> Dynamic added nodes -> Red - Dotted - Blocks
		
### Arrows syntax
> Parent to child relation "--->" <br>
> Signal call relation "-.->" 

### Limitation
>All Nodes in the Project have to have unique names. <br>
>Multi Dynamic Nodes Creation (ie within for,While loop.) are consider as 1 instance creation. <br>
>Conditional creation of Dynamic Nodes (ie within if condition ) are consider as 1 instance creation. <br>
---

<p align="center">
	<a href="https://github.com/arsany007/Model_DiagramGen/blob/main/LICENSE" style="vertical-align: middle;">
		MIT LICENSE
	</a>
</p>

----
