-- FIELDS
local configHandler = dofile("Config-Handler.lua")
local layerHandler = dofile("Layer-Handler.lua")

local appData = os.getenv("APPDATA")

if appData == nil then
    app.alert("APPDATA was nil, scripts won't load.")
    return
end

local extensionPath = app.fs.joinPath(appData, "Aseprite/extensions/aseprite-extension")
extensionPath = app.fs.normalizePath(extensionPath)

local asepriteExporterPath = app.fs.joinPath(extensionPath, "Aseprite-Exporter.lua")
local asepriteImporterPath = app.fs.joinPath(extensionPath, "Aseprite-Importer.lua")
local asepriteRenamerPath = app.fs.joinPath(extensionPath, "Aseprite-Renamer.lua")
local asepriteSorterPath = app.fs.joinPath(extensionPath, "Aseprite-Sorter.lua")

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
            local asepriteExporter = dofile(asepriteExporterPath)
            asepriteExporter.Initialize(configHandler, layerHandler)
            asepriteExporter.Execute()
        end,
        onenabled = function() return appData ~= nil and app.activeSprite ~= nil end,
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
        id = "asepriteRename",
        title = "Rename",
        group = extensionGroup,
        onclick = function()
            local asepriteRenamer = dofile(asepriteRenamerPath)
            asepriteRenamer.Initialize(configHandler, layerHandler)
            asepriteRenamer.Execute()
        end,
        onenabled = function() return appData ~= nil and app.activeSprite ~= nil end,
    }

    plugin:newCommand {
        id = "asepriteSort",
        title = "Sort",
        group = extensionGroup,
        onclick = function()
            local asepriteSorter = dofile(asepriteSorterPath)
            asepriteSorter.Initialize(configHandler, layerHandler)
            asepriteSorter.Execute()
        end,
        onenabled = function() return appData ~= nil and app.activeSprite ~= nil end,
    }
end

---@param plugin Plugin
function exit(plugin) end
