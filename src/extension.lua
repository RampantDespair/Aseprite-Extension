-- FIELDS
local configHandler = require("Config-Handler")
local layerHandler = require("Layer-Handler")

local asepriteExporter = require("Aseprite-Exporter")
local asepriteImporter = require("Aseprite-Importer")
local asepriteRenamer = require("Aseprite-Renamer")
local asepriteSorter = require("Aseprite-Sorter")

-- FUNCTIONS
---@param plugin Plugin
function init(plugin)
    local parentGroup = "file_scripts"
    local extensionGroup = "despair_extension"

    plugin:newMenuSeparator {
        group = parentGroup,
    }

    plugin:newMenuGroup {
        id = extensionGroup,
        title = "Despair Extension",
        group = parentGroup,
    }

    plugin:newCommand {
        id = "asepriteExport",
        title = "Export",
        group = extensionGroup,
        onclick = function()
            asepriteExporter.Initialize(configHandler, layerHandler)
            asepriteExporter.Execute()
        end,
        onenabled = function() return app.activeSprite ~= nil end,
    }

    plugin:newCommand {
        id = "asepriteImport",
        title = "Import",
        group = extensionGroup,
        onclick = function()
            asepriteImporter.Initialize(configHandler, layerHandler)
            asepriteImporter.Execute()
        end,
        onenabled = function() return app.activeSprite ~= nil end,
    }

    plugin:newCommand {
        id = "asepriteRename",
        title = "Rename",
        group = extensionGroup,
        onclick = function()
            asepriteRenamer.Initialize(configHandler, layerHandler)
            asepriteRenamer.Execute()
        end,
        onenabled = function() return app.activeSprite ~= nil end,
    }

    plugin:newCommand {
        id = "asepriteSort",
        title = "Sort",
        group = extensionGroup,
        onclick = function()
            asepriteSorter.Initialize(configHandler, layerHandler)
            asepriteSorter.Execute()
        end,
        onenabled = function() return app.activeSprite ~= nil end,
    }
end

---@param plugin Plugin
function exit(plugin) end
