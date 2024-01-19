local asepriteExporter = dofile("Aseprite-Exporter.lua")
local asepriteImporter = dofile("Aseprite-Importer.lua")
local configHandler = dofile("Config-Handler.lua")
local layerHandler = dofile("Layer-Handler.lua")

asepriteExporter.Initialize(configHandler, layerHandler)
asepriteImporter.Initialize(configHandler, layerHandler)

-- FUNCTIONS
---@param plugin plugin
function init(plugin)
    local parentGroup = "file_scripts"
    local extensionGroup = "import_importy_export"

    plugin:newMenuSeparator {
        group = parentGroup,
    }

    plugin:newMenuGroup {
        id = extensionGroup,
        title = "Import/Export",
        group = parentGroup,
    }

    plugin:newCommand {
        id = "asepriteImport",
        title = "Import",
        group = extensionGroup,
        onclick = function() asepriteImporter.Execute() end,
        onenabled = function() return app.activeSprite ~= nil end,
    }

    plugin:newCommand {
        id = "asepriteExport",
        title = "Export",
        group = extensionGroup,
        onclick = function() asepriteExporter.Execute() end,
        onenabled = function() return app.activeSprite ~= nil end,
    }
end

---@param plugin plugin
function exit(plugin) end
