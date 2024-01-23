<!-- PROJECT LOGO -->
<div align="center">
  <img src="media/logo.png" alt="Logo" width="200" height="120">
  <h2>Aseprite-Extension</h3>
  <p>An Aseprite extension that lets you mass-import images, export importable Spine data and manipulate layers</p>
  <div>
    <a href="https://github.com/RampantDespair/Aseprite-Extension/issues"><img alt="Report Bug" src="https://img.shields.io/badge/Report%20Bug-red"></a>
    <a href="https://github.com/RampantDespair/Aseprite-Extension/issues"><img alt="Request Feature" src="https://img.shields.io/badge/Request%20Feature-green"></a>
  </div>
  <a href="https://github.com/RampantDespair/Aseprite-Extension?tab=GPL-2.0-1-ov-file">
    <img alt="License" src="https://img.shields.io/github/license/RampantDespair/Aseprite-Extension">
  </a>
</div>

<!-- PROJECT SHIELDS -->
<hr>
<div align="center">
  <a href="https://www.aseprite.org/"><img alt="Aseprite" src="https://img.shields.io/badge/Aseprite-gray?logo=aseprite"></a>
  <a href="https://esotericsoftware.com/"><img alt="Spine" src="https://img.shields.io/badge/Spine-gray?logo=spine"></a>
</div>
<div align="center">
  <a href="https://www.lua.org/"><img alt="Lua" src="https://img.shields.io/badge/v5.4.6-blue?logo=lua&label=Lua&labelColor=gray"></a>
</div>
<hr>

<!-- PROJECT SHOWCASE -->

<!-- ABOUT THE PROJECT -->
## About The Project

This project was made to remove a few hassles I had when working with Asperite:

-  Exporting a sprite to Spine.
-  Mass importing images into a Sprite.
-  Renaming sprite layers.
-  Sorting sprite layers.

With that in mind, this Aseprite extension lets you do all of the above with ease.

<!-- FEATURES -->
## Features

*  Automatically save your settings to global/local config

<!-- INSTALLATION -->
## Installation

1.  Download the [latest-release](https://github.com/RampantDespair/Aseprite-Extension/releases)
2.  Go to your downloads folder
3.  Execute the `asperite-extension` file
4.  Go to **Edit > Preferences > Extensions**
5.  Make sure that `Despair Extension` is present under the **Scripts** category

<!-- USAGE -->
## Usage

1.  Click **File > Despair Extension**

<!-- SETTINGS -->
## Settings

### Config Settings

| Option | Description | Default Value |
| --- | --- | --- |
| Current Config | The current config file that's being used. | global |

## Buttons Information

| Button | Description |
| --- | --- |
| Confirm | Confirms the settings for export. |
| Cancel | Cancels the export altogether. |
| Reset | Resets the settings to their default values. |

<!-- SCRIPTS -->
## Scripts

<details>
<summary>Exporter</summary>

<!-- SHOWCASE -->
<div align="center">
  <img alt="Showcase" src="media/showcase-v4.0.gif">
</div>

<!-- EXAMPLE -->
### Example

#### Transform this:

![aseprite-example](media/aseprite-example.png)

#### Into that:

![spine-example](media/spine-example.png)

<!-- FEATURES -->
### Features

#### Generic

*   Configurable output path
*   Configurable images & sound paths
*   Ability to export Sprite sheet
*   Ability to trim a Sprite's file name
*   Ability to format the Sprite's file name
*   Configurable export file format
*   Ability to trim the Sprite sheet

#### Spine

*   Ability to convert SpriteSheet into importable Spine data
*   Configurable root positioning
*   Ability to convert Aseprite groups into Spine skins
*   Ability to format slot and attachment names

<!-- IMPORTANT -->
### Important

*   You cannot name your skins "default" as this is reserved by Spine itself

<!-- SETTINGS -->
### Settings

#### Output Settings

| Option | Description | Default Value |
| --- | --- | --- |
| Output File | The parent directory of the selected file will be used for export. | the file itself |
| Output Subdirectory | The subdirectory used for export. | images |
| Groups As Directories | If each group while be exported to it's own directory. | true |

#### Sprite Settings

| Option | Description | Default Value |
| --- | --- | --- |
| Export SpriteSheet | If the sprite sheet will be exported. | true |
| Sprite Name Trim | If the sprite name will be trimmed.<br> Trims the first instance "_" and everything preceding it. | true |
| File Name Format | The file name's format with modifiable placeholders. | {spritename}-{layergroup}-{layername} |
| File Format | The files' export format. | png |
| SpriteSheet Trim | If the exported files' will have there excess space trimmed. | true |

#### Spine Settings

| Option | Description | Default Value |
| --- | --- | --- |
| Export SpineSheet | If the spine sheet will be exported. | true |
| Set Static Slot | If the same slot will be used for everything that's exported. | true |
| Static Slot Name | The name of that static slot. | slot |
| Set Root Position | If the root position will be set in the export file. | true |
| Root Position Method | The method which will be used for setting the position.<br> <ins>Automatic</ins>: To use this method, create a layer called "root" and place a single pixel where you want the root to be.<br> <ins>Center</ins>: The center off the canvas will be used as root.<br> <ins>Manual</ins>: Input the coordinates manually in the subsequent fields. | center |
| Root Position X | The X coordinate of the root. | 0 |
| Root Position Y | The Y coordinate of the root. | 0 |
| Set Images Paths | If the images path whithin the exported spine file will be set. | true |
| Images Path | The images path. | images |
| Groups As Skins | If you want to convert aseprite groups to spine skins. | true |
| Skin Name Format | The skins' format with modifiable placeholders. | weapon-{layergroup} |
| Seperate Slot/Skin | If you want to seperate the slots and skins. | true |
| Slot Name Format | The slots' name format with modifiable placeholders. | {layernameprefix} |
| Skin Attachement Format | The skins' attachement format with modifiable placeholders. | {layernameprefix}-{layernamesuffix} |
| Layer Name Separator | The layers' name seperator. | - |

</details>

<br>
<details>
<summary>Importer</summary>
<br>

<!-- SHOWCASE -->
<div align="center">
  <img alt="Showcase" src="media/showcase-v4.0.gif">
</div>

<!-- FEATURES -->
### Features

*   Configurable input path
*   Ability to convert directories into layer groups
*   Ability to decide how the images should be positioned
*   Ability to manage how duplicates should be handled

<!-- SETTINGS -->
### Settings

#### Input Settings

| Option | Description | Default Value |
| --- | --- | --- |
| Input File | The parent directory of the selected file will be used for import. | the file itself |
| Input Subdirectory | The subdirectory used for import. | sprite |
| Directories As Groups | If each directory will be imported to it's own group. | true |
| Duplicates Mode | The method which will be used for handling duplicate layers.<br> <ins>Ignore</ins>: The duplicates will be ignored and a new copy will be created.<br> <ins>Override</ins>: The duplicates will be updated with the newly imported cels.<br> <ins>Skips</ins>: The duplicates will be skipped (nothing will happen). | override |
| Sprite Position Method | The method which will be used for positioning cels.<br> <ins>Center</ins>: The cels will be centered to canvas.<br> <ins>Inherit</ins>: The cels will keep their position from the imported file.<br> <ins>Manual</ins>: The cels will have the position specified. | center |

</details>

<br>
<details>
<summary>Renamer</summary>
<br>

<!-- SHOWCASE -->
<div align="center">
  <img alt="Showcase" src="media/showcase-v4.0.gif">
</div>

<!-- FEATURES -->
### Features

*   Ability to mass rename all layers present in Sprite

<!-- SETTINGS -->
### Settings

#### Input Settings

| Option | Description | Default Value |
| --- | --- | --- |
| Match | Matches the specified string for replacement. | this |
| Replace | Replaces the matched string with the one specified here. | that |
| Prefix | Adds the specified string at the start of the layer name. | prefix |
| Suffix | Adds the specified string at the end of the layer name. | suffix |

</details>
<br>

<details>
<summary>Sorter</summary>
<br>

<!-- SHOWCASE -->
<div align="center">
  <img alt="Showcase" src="media/showcase-v4.0.gif">
</div>

<!-- FEATURES -->
### Features

*   Ability to sort all layers present in Sprite

<!-- SETTINGS -->
### Settings

#### Input Settings

| Option | Description | Default Value |
| --- | --- | --- |
| Sort Method | The method which will be used for sorting layers.<br> <ins>Ascending</ins>: The layers will be sorted ascendingly.<br> <ins>Descending</ins>: The layers will be sorted descendingly. | ascending |

</details>
<br>

<!-- CONTRIBUTING -->
## Contributing

If you have a suggestion that would make this better, please fork the repo and create a pull request.
<br>
You can also simply open an issue with the tag "enhancement".
<br>
Any contributions you make are **greatly appreciated**.

<!-- LINKS -->
## Links

*   [Esoteric Software Forums](https://esotericsoftware.com/forum/d/24339-aseprite-spine-script) (Spine Animation Forums)

<!-- ACKNOWLEDGMENTS -->
## Acknowledgments

*   [aseprite-to-spine](https://github.com/jordanbleu/aseprite-to-spine) made by [jordanbleu](https://github.com/jordanbleu)
*   [AsepriteScripts](https://github.com/PKGaspi/AsepriteScripts) made by [PKGaspi](https://github.com/PKGaspi)
*   [Shields.io](https://shields.io/) for badges
