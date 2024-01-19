-- FIELDS
local configHandler = dofile("Config-Handler.lua")
local layerHandler = dofile("Layer-Handler.lua")

local extensionPath = app.fs.joinPath(os.getenv("APPDATA"), "Aseprite/extensions/aseprite-import-export-extension")
extensionPath = app.fs.normalizePath(extensionPath)

local asepriteExporterPath = app.fs.joinPath(extensionPath, "Aseprite-Exporter.lua")
local asepriteImporterPath = app.fs.joinPath(extensionPath, "Aseprite-Importer.lua")

-- FUNCTIONS
---@param plugin Plugin
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
        onclick = function()
            local asepriteImporter = dofile(asepriteImporterPath)
            asepriteImporter.Initialize(configHandler, layerHandler)
            asepriteImporter.Execute()
        end,
        onenabled = function() return app.activeSprite ~= nil end,
    }

    plugin:newCommand {
        id = "asepriteExport",
        title = "Export",
        group = extensionGroup,
        onclick = function()
            local asepriteExporter = dofile(asepriteExporterPath)
            asepriteExporter.Initialize(configHandler, layerHandler)
            asepriteExporter.Execute()
        end,
        onenabled = function() return app.activeSprite ~= nil end,
    }
end

---@param plugin Plugin
function exit(plugin) end
