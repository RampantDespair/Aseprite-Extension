-- INSTANCE DECLARATION
local asepriteImporter = {}

-- FIELDS
LayerCount = 0
ConfigHandler = nil
LayerHandler = nil
Config = {
    configSelect = {
        order = 100,
        type = "combobox",
        default = "global",
        value = nil,
        parent = nil,
        children = {},
        condition = nil,
    },
    inputSubdirectory = {
        order = 200,
        type = "entry",
        default = "sprite",
        value = nil,
        parent = nil,
        children = {},
        condition = nil,
    },
    inputDirectoriesAsGroups = {
        order = 201,
        type = "check",
        default = true,
        value = nil,
        parent = nil,
        children = {},
        condition = nil,
    },
    inputCenterImages = {
        order = 202,
        type = "check",
        default = true,
        value = nil,
        parent = nil,
        children = {},
        condition = nil,
    },
}
ConfigKeys = {}
ConfigPathLocal = ""
ConfigPathGlobal = ""
Dlg = Dialog("X")
ImportFileExtensions = { "png", "gif", "jpg", "jpeg" }

-- FUNCTIONS
---@param activeSprite Sprite
function asepriteImporter.Import(activeSprite)
    local importFiles = app.fs.listFiles(Dlg.data.inputPath)
    for _, value in ipairs(importFiles) do
        local importFile = app.fs.joinPath(Dlg.data.inputPath, value)
        importFile = app.fs.normalizePath(importFile)
        if app.fs.isDirectory(importFile) then
            app.alert(importFile)
        else
            local importFileExtension = app.fs.fileExtension(importFile)
            importFileExtension = string.lower(importFileExtension)
            if ConfigHandler.ArrayContainsValue(ImportFileExtensions, importFileExtension) then
                local newLayer = activeSprite:newLayer()
                newLayer.stackIndex = 1
                local importFileName = app.fs.fileTitle(importFile)
                -- TODO add formatting
                newLayer.name = importFileName
                local newImage = Image { fromFile = importFile }
                activeSprite:newCel(newLayer, activeSprite.frames[1], newImage, Point {0, 0})
            else
                app.alert("no")
            end
            --return
        end
    end
end

---@param activeSprite Sprite
function asepriteImporter.BuildDialog(activeSprite)
    Dlg:tab {
        id = "configSettings",
        text = "Config Settings",
    }
    Dlg:combobox {
        id = "configSelect",
        label = "Current Config:",
        option = Config.configSelect.value,
        options = { "global", "local" },
        onchange = function() ConfigHandler.UpdateConfigFile(activeSprite, Dlg.data.configSelect, asepriteImporter.ExtraDialogModifications) end,
    }
    Dlg:label {
        id = "globalConfigPath",
        label = "Global Config Path: ",
        text = ConfigPathGlobal,
    }
    Dlg:label {
        id = "localConfigPath",
        label = "Local Config Path: ",
        text = ConfigPathLocal,
    }

    Dlg:tab {
        id = "inputSettings",
        text = "Input Settings",
    }
    Dlg:file {
        id = "inputFile",
        label = "input File:",
        filename = activeSprite.filename,
        open = false,
        onchange = function()
            Dlg:modify {
                id = "inputPath",
                text = app.fs.joinPath(app.fs.filePath(Dlg.data.inputFile), Dlg.data.inputSubdirectory)
            }
        end,
    }
    Dlg:entry {
        id = "inputSubdirectory",
        label = "Input Subdirectory:",
        text = Config.inputSubdirectory.value,
        onchange = function()
            Config.inputSubdirectory.value = Dlg.data.inputSubdirectory
            Dlg:modify {
                id = "inputPath",
                text = app.fs.joinPath(app.fs.filePath(Dlg.data.inputFile), Dlg.data.inputSubdirectory)
            }
        end,
    }
    Dlg:label {
        id = "inputPath",
        label = "Input Path:",
        text = app.fs.joinPath(app.fs.filePath(Dlg.data.inputFile), Dlg.data.inputSubdirectory),
    }
    Dlg:check {
        id = "inputDirectoriesAsGroups",
        label = "Directories As Groups:",
        selected = Config.inputDirectoriesAsGroups.value,
        onclick = function() asepriteImporter.ConfigHandler.UpdateConfigValue("inputDirectoriesAsGroups", Dlg.data.inputDirectoriesAsGroups) end,
    }
    Dlg:check {
        id = "inputCenterImages",
        label = "Center Images:",
        selected = Config.inputCenterImages.value,
        onclick = function() ConfigHandler.UpdateConfigValue("inputCenterImages", Dlg.data.inputCenterImages) end,
    }

    Dlg:endtabs {}

    Dlg:entry {
        id = "help",
        label = "Need help? Visit my GitHub repository @",
        text = "https://github.com/RampantDespair/Aseprite-Exporter",
    }
    Dlg:separator {
        id = "helpSeparator",
    }

    Dlg:button {
        id = "confirm",
        text = "Confirm",
    }
    Dlg:button {
        id = "cancel",
        text = "Cancel",
    }
    Dlg:button {
        id = "reset",
        text = "Reset",
        onclick = function () ConfigHandler.ResetConfig(activeSprite, asepriteImporter.ExtraDialogModifications) end,
    }
end

---@param activeSprite Sprite
function asepriteImporter.ExtraDialogModifications(activeSprite)
    Dlg:modify {
        id = "inputFile",
        filename = activeSprite.filename,
    }
    Dlg:modify {
        id = "inputPath",
        text = app.fs.joinPath(app.fs.filePath(Dlg.data.inputFile), Dlg.data.inputSubdirectory),
    }
end

function asepriteImporter.Execute()
    if ConfigHandler == nil then
        app.alert("Failed to get ConfigHandler.")
        return
    end

    if LayerHandler == nil then
        app.alert("Failed to get LayerHandler.")
        return
    end

    local activeSprite = app.sprite

    if activeSprite == nil then
        app.alert("No sprite selected, script aborted.")
        return
    end

    local scriptPath = debug.getinfo(1).source
    scriptPath = string.sub(scriptPath, 2, string.len(scriptPath))
    scriptPath = app.fs.normalizePath(scriptPath)

    local scriptName = app.fs.fileTitle(scriptPath)
    local scriptDirectory = string.match(scriptPath, "(.*[/\\])")

    local spritePath = app.fs.filePath(activeSprite.filename)

    ConfigPathLocal = app.fs.joinPath(spritePath, scriptName .. ".conf")
    ConfigPathGlobal = app.fs.joinPath(scriptDirectory, scriptName .. ".conf")

    Dlg = Dialog(scriptName)

    ConfigHandler.InitializeConfig()
    ConfigHandler.InitializeConfigKeys()

    asepriteImporter.BuildDialog(activeSprite)

    Dlg:show()

    ConfigHandler.WriteConfig()

    if Dlg.data.cancel then
        return
    end

    if not Dlg.data.confirm then
        app.alert("Settings were not confirmed, script aborted.")
        return
    end

    if Dlg.data.inputPath == nil then
        app.alert("No input directory was specified, script aborted.")
        return
    end

    asepriteImporter.Import(activeSprite)
end

function asepriteImporter.Initialize(configHandler, layerHandler)
    ConfigHandler = configHandler
    LayerHandler = layerHandler
end

-- INSTANCE RETURN
return asepriteImporter
