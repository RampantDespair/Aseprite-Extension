-- INSTANCES
local asepriteExporterInstance = require("aseprite-exporter")
local asepriteImporterInstance = require("aseprite-importer")
local asepriteRenamerInstance = require("aseprite-renamer")
local asepriteSorterInstance = require("aseprite-sorter")

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
            local asepriteExporter = asepriteExporterInstance()
            asepriteExporter:Execute()
        end,
        onenabled = function() return app.activeSprite ~= nil end,
    }

    plugin:newCommand {
        id = "asepriteImport",
        title = "Import",
        group = extensionGroup,
        onclick = function()
            local asepriteImporter = asepriteImporterInstance()
            asepriteImporter:Execute()
        end,
        onenabled = function() return app.activeSprite ~= nil end,
    }

    plugin:newCommand {
        id = "asepriteRename",
        title = "Rename",
        group = extensionGroup,
        onclick = function()
            local asepriteRenamer = asepriteRenamerInstance()
            asepriteRenamer:Execute()
        end,
        onenabled = function() return app.activeSprite ~= nil end,
    }

    plugin:newCommand {
        id = "asepriteSort",
        title = "Sort",
        group = extensionGroup,
        onclick = function()
            local asepriteSorter = asepriteSorterInstance()
            asepriteSorter:Execute()
        end,
        onenabled = function() return app.activeSprite ~= nil end,
    }
end

---@param plugin Plugin
function exit(plugin) end
