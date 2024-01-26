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
        defaults = {
            "global",
            "local",
        },
        value = nil,
        parent = nil,
        children = {},
        condition = nil,
    },
    inputSubdirectory = {
        order = 200,
        type = "entry",
        default = "sprite",
        defaults = nil,
        value = nil,
        parent = nil,
        children = {},
        condition = nil,
    },
    inputDirectoriesAsGroups = {
        order = 201,
        type = "check",
        default = true,
        defaults = nil,
        value = nil,
        parent = nil,
        children = {},
        condition = nil,
    },
    inputDuplicatesMode = {
        order = 202,
        type = "combobox",
        default = "override",
        defaults = {
            "override",
            "ignore",
            "skip",
        },
        value = nil,
        parent = nil,
        children = {},
        condition = nil,
    },
    inputSpritePosition = {
        order = 203,
        type = "combobox",
        default = "center",
        defaults = {
            "center",
            "inherit",
            "manual",
        },
        value = nil,
        parent = nil,
        children = {
            "inputSpritePositionX",
            "inputSpritePositionY",
        },
        condition = nil,
    },
    inputSpritePositionX = {
        order = 204,
        type = "number",
        default = 0,
        defaults = nil,
        value = nil,
        parent = "inputSpritePosition",
        children = {},
        condition = "manual",
    },
    inputSpritePositionY = {
        order = 205,
        type = "number",
        default = 0,
        defaults = nil,
        value = nil,
        parent = "inputSpritePosition",
        children = {},
        condition = "manual",
    },
}
ConfigKeys = {}
ConfigPathLocal = ""
ConfigPathGlobal = ""
Dlg = Dialog("X")
ImportFileExtensions = { "png", "gif", "jpg", "jpeg" }

-- FUNCTIONS
---@return string
---@param colorMode ColorMode
function asepriteImporter.GetColorMode(colorMode)
    if (colorMode == ColorMode.RGB) then
        return "rgb"
    elseif (colorMode == ColorMode.GRAY) then
        return "gray"
    elseif (colorMode == ColorMode.INDEXED) then
        return "indexed"
    elseif (colorMode == ColorMode.TILEMAP) then
        return "tilemap"
    else
        return ""
    end
end

---@return Layer | nil
---@param layers Layer[]
---@param layerName string
function asepriteImporter.GetLayerByName(layers, layerName)
    for _, value in ipairs(layers) do
        if value.name == layerName then
            return value
        end
    end
    return nil
end

---@param activeSprite Sprite
---@param newLayer Layer
---@param otherLayer Layer
function asepriteImporter.CreateCels(activeSprite, newLayer, otherLayer)
    for _, otherCel in ipairs(otherLayer.cels) do
        if Config.inputSpritePosition.value == "center" then
            activeSprite:newCel(newLayer, otherCel.frameNumber, otherCel.image, Point(math.floor(activeSprite.width / 2) - math.floor(otherCel.bounds.width / 2), math.floor(activeSprite.height / 2) - math.floor(otherCel.bounds.height / 2)))
        elseif Config.inputSpritePosition.value == "inherit" then
            activeSprite:newCel(newLayer, otherCel.frameNumber, otherCel.image, otherCel.position)
        elseif Config.inputSpritePosition.value == "manual" then
            activeSprite:newCel(newLayer, otherCel.frameNumber, otherCel.image, Point(Config.inputSpritePositionX.value, Config.inputSpritePositionY.value))
        else
            error("Invalid inputSpritePosition value (" .. tostring(Config.inputSpritePosition.value) .. ")")
        end
    end
end

---@param activeSprite Sprite
function asepriteImporter.Import(activeSprite)
    local activeColorMode = activeSprite.colorMode
    local activeColorModeName = asepriteImporter.GetColorMode(activeColorMode)
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
                local importFileName = app.fs.fileTitle(importFile)

                local otherSprite = Sprite({ fromFile = importFile })
                app.command.ChangePixelFormat {
                    format = activeColorModeName
                }

                while #activeSprite.frames < #otherSprite.frames do
                    activeSprite:newEmptyFrame(#activeSprite.frames + 1)
                end

                for _, otherLayer in ipairs(otherSprite.layers) do
                    local newLayer = asepriteImporter.GetLayerByName(activeSprite.layers, importFileName)
                    if newLayer == nil or Config.inputDuplicatesMode.value == "ignore" then
                        newLayer = activeSprite:newLayer()
                        newLayer.stackIndex = 1
                        newLayer.name = importFileName
                        asepriteImporter.CreateCels(activeSprite, newLayer, otherLayer)
                    elseif Config.inputDuplicatesMode.value == "override" then
                        asepriteImporter.CreateCels(activeSprite, newLayer, otherLayer)
                    elseif Config.inputDuplicatesMode.value == "skip" then
                        LayerCount = LayerCount - 1
                    else
                        error("Invalid inputDuplicatesMode value (" .. tostring(Config.inputDuplicatesMode.value) .. ")")
                    end
                    LayerCount = LayerCount + 1
                end
                otherSprite:close()
            end
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
        options = Config.configSelect.defaults,
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
        label = "Input File:",
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
    Dlg:combobox {
        id = "inputDuplicatesMode",
        label = "Duplicates Mode:",
        option = Config.inputDuplicatesMode.value,
        options = Config.inputDuplicatesMode.defaults,
        onchange = function() ConfigHandler.UpdateConfigValue("inputDuplicatesMode", Dlg.data.inputDuplicatesMode) end,
    }
    Dlg:combobox {
        id = "inputSpritePosition",
        label = "Sprite Position Method:",
        option = Config.inputSpritePosition.value,
        options = Config.inputSpritePosition.defaults,
        onchange = function() ConfigHandler.UpdateConfigValue("inputSpritePosition", Dlg.data.inputSpritePosition) end,
    }
    Dlg:number {
        id = "inputSpritePositionX",
        label = " Sprite Postion X:",
        text = Config.inputSpritePositionX.value,
        visible = Config.inputSpritePosition.value == "manual",
        decimals = 0,
        onchange = function() ConfigHandler.UpdateConfigValue("inputSpritePositionX", Dlg.data.inputSpritePositionX) end,
    }
    Dlg:number {
        id = "inputSpritePositionY",
        label = " Sprite Postion Y:",
        text = Config.inputSpritePositionY.value,
        visible = Config.inputSpritePosition.value == "manual",
        decimals = 0,
        onchange = function() ConfigHandler.UpdateConfigValue("inputSpritePositionY", Dlg.data.inputSpritePositionY) end,
    }

    Dlg:endtabs {}

    Dlg:entry {
        id = "help",
        label = "Need help? Visit my GitHub repository @",
        text = "https://github.com/RampantDespair/Aseprite-Extension",
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
        onclick = function() ConfigHandler.ResetConfig(activeSprite, asepriteImporter.ExtraDialogModifications) end,
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
        app.alert("Failed to get ConfigHandler, script aborted.")
        return
    end

    if LayerHandler == nil then
        app.alert("Failed to get LayerHandler, script aborted.")
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

    app.transaction("Importer", function() asepriteImporter.Import(activeSprite) end)

    app.alert("Imported " .. LayerCount .. " layers")
end

function asepriteImporter.Initialize(configHandler, layerHandler)
    ConfigHandler = configHandler
    LayerHandler = layerHandler
end

-- INSTANCE RETURN
return asepriteImporter
