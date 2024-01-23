-- FIELDS
local configHandler = dofile("Config-Handler.lua")
local layerHandler = dofile("Layer-Handler.lua")

local appData = os.getenv("APPDATA")

if appData == nil then
    app.alert("APPDATA was nil, scripts won't load.")
    return
end

local extensionPath = app.fs.joinPath(appData, "Aseprite/extensions/aseprite-import-export-extension")
extensionPath = app.fs.normalizePath(extensionPath)

local asepriteExporterPath = app.fs.joinPath(extensionPath, "Aseprite-Exporter.lua")
local asepriteImporterPath = app.fs.joinPath(extensionPath, "Aseprite-Importer.lua")

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
        id = "asepriteImport",
        title = "Import",
        group = extensionGroup,
        onclick = function()
            local asepriteImporter = dofile(asepriteImporterPath)
            asepriteImporter.Initialize(configHandler, layerHandler)
            asepriteImporter.Execute()
        end,
        onenabled = function() return appData ~= nil and app.activeSprite ~= nil end,
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
        onenabled = function() return appData ~= nil and app.activeSprite ~= nil end,
    }
end

---@param plugin Plugin
function exit(plugin) end
