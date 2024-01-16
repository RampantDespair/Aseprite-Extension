-- FUNCTIONS
function GetLayerVisibilityData(activeSprite)
    local layerVisibilityData = {}
    for i, layer in ipairs(activeSprite.layers) do
        if layer.isGroup then
            layerVisibilityData[i] = GetLayerVisibilityData(layer)
        else
            layerVisibilityData[i] = layer.isVisible
            layer.isVisible = false
        end
    end
    return layerVisibilityData
end

function HideLayers(activeSprite)
    for _, layer in ipairs(activeSprite.layers) do
        if layer.isGroup then
            HideLayers(layer)
        else
            layer.isVisible = false
        end
    end
end

function RestoreLayers(activeSprite, layerVisibilityData)
    for i, layer in ipairs(activeSprite.layers) do
        if layer.isGroup then
            RestoreLayers(layer, layerVisibilityData[i])
        else
           layer.isVisible = layerVisibilityData[i]
        end
     end
end

function GetRootPosition(activeSprite)
    if Config.spineExport.value == true and Config.spineSetRootPostion.value == true then
        if Config.spineRootPostionMethod.value == "manual" then
            return { x = Config.spineRootPostionX.value, y = Config.spineRootPostionY.value }
        elseif Config.spineRootPostionMethod.value == "automatic" then
            for _, layer in ipairs(activeSprite.layers) do
                if layer.name == "root" then
                    return { x = layer.cels[1].position.x, y = layer.cels[1].position.y }
                end
            end
        elseif Config.spineRootPostionMethod.value == "center" then
            return { x = activeSprite.width / 2, y = activeSprite.height / 2 }
        end
    end
    return { x = 0, y = 0 }
end

function Export(activeSprite, rootLayer, fileName, fileNameTemplate)
    if Config.spineExport.value == true then
        ExportSpineJsonStart(fileName)
    end

    ExportSpriteLayers(activeSprite, rootLayer, fileName, fileNameTemplate)

    if Config.spineExport.value == true then
        ExportSpineJsonEnd()
    end
end

function ExportSpriteLayers(activeSprite, rootLayer, fileName, fileNameTemplate)
    for _, layer in ipairs(rootLayer.layers) do
        local _fileNameTemplate = fileNameTemplate
        local layerName = layer.name

        if layerName ~= "root" then
            if layer.isGroup then
                local previousVisibility = layer.isVisible
                layer.isVisible = true

                if Config.outputGroupsAsDirectories.value == true then
                    _fileNameTemplate = app.fs.joinPath(layerName, _fileNameTemplate)
                end

                ExportSpriteLayers(activeSprite, layer, fileName, _fileNameTemplate)

                layer.isVisible = previousVisibility
            else
                layer.isVisible = true

                local layerParentName
                if pcall(function () layerParentName = layer.parent.name end) then
                    _fileNameTemplate = string.gsub(_fileNameTemplate, "{layergroup}", layerParentName)
                else
                    _fileNameTemplate = string.gsub(_fileNameTemplate, "{layergroup}", "default")
                end

                _fileNameTemplate = string.gsub(_fileNameTemplate, "{layername}", layerName)

                if #layer.cels ~= 0 then
                    if Config.spriteSheetExport.value == true then
                        ExportSpriteSheet(activeSprite, layer, _fileNameTemplate)
                    end

                    if Config.spineExport.value == true then
                        ExportSpineJsonParse(layer, _fileNameTemplate)
                    end

                    LayerCount = LayerCount + 1
                end

                layer.isVisible = false
            end
        end
    end
end

function ExportSpriteSheet(activeSprite, layer, fileNameTemplate)
    local cel = layer.cels[1]
    local currentLayer = Sprite(activeSprite)

    if Config.spriteSheetTrim.value == true then
        currentLayer:crop(cel.position.x, cel.position.y, cel.bounds.width, cel.bounds.height)
    end

    currentLayer:saveCopyAs(app.fs.joinPath(Dlg.data.outputPath, fileNameTemplate .. "." .. Config.spriteSheetFileFormat.value))
    currentLayer:close()
end

function ExportSpineJsonStart(fileName)
    local jsonFileName = app.fs.joinPath(app.fs.filePath(Dlg.data.outputFile), fileName .. ".json")

    os.execute("mkdir " .. Dlg.data.outputPath)
    JsonFile = io.open(jsonFileName, "w")

    JsonFile:write('{ ')
    JsonFile:write('"skeleton": { ')

    if Config.spineSetImagesPath.value == true then
        JsonFile:write(string.format([["images": "%s" ]], "./" .. Config.spineImagesPath.value .. "/"))
    end

    JsonFile:write('}, ')
    JsonFile:write('"bones": [ { ')
    JsonFile:write('"name": "root" ')
    JsonFile:write('} ')
    JsonFile:write('], ')

    SlotsJson = {}
    SkinsJson = {}
end

function ExportSpineJsonParse(layer, fileNameTemplate)
    local layerName = layer.name

    local slotName
    if Config.spineSetStaticSlot.value == true then
        slotName = Config.spineStaticSlotName.value
    else
        slotName = layerName
    end

    local slot = string.format([[{ "name": "%s", "bone": "%s", "attachment": "%s" }]], slotName, "root", slotName)

    local layerCel = layer.cels[1]

    local layerCelPosition = layerCel.position
    local layerCelX = layerCelPosition.x
    local layerCelY = layerCelPosition.y

    local layerCelBounds = layerCel.bounds
    local layerCelWidth = layerCelBounds.width
    local layerCelHeight = layerCelBounds.height

    local realPostionX = layerCelX + layerCelWidth / 2
    local realPositionY = layerCelY + layerCelHeight / 2

    local spriteX
    local spriteY

    if Config.spineSetRootPostion.value == true then
        spriteX = realPostionX - RootPositon.x
        spriteY = RootPositon.y - realPositionY
    else
        spriteX = realPostionX
        spriteY = realPositionY
    end

    if Config.spineGroupsAsSkins.value == true then
        fileNameTemplate = string.gsub(fileNameTemplate, "\\", "/")
        local skinName
        if pcall(function () skinName = layer.parent.name end) then
            skinName = string.gsub(Config.spineSkinNameFormat.value, "{layergroup}", layer.parent.name)
        end

        if skinName ~= nil then
            if ArrayContainsKey(SkinsJson, skinName) == false then
                SkinsJson[skinName] = {}
            end

            local skinAttachmentName = layerName

            if Config.spineSeparateSlotSkin.value == true then
                local separatorPosition = string.find(layerName, Config.spineLayerNameSeparator.value)

                if separatorPosition then
                    local layerNamePrefix = string.sub(layerName, 1, separatorPosition - 1)
                    local layerNameSuffix = string.sub(layerName, separatorPosition + 1, #layerName)

                    slotName = Config.spineSlotNameFormat.value
                    if slotName ~= nil then
                        slotName = string.gsub(slotName, "{layernameprefix}", layerNamePrefix)
                        slotName = string.gsub(slotName, "{layernamesuffix}", layerNameSuffix)
                    end

                    skinAttachmentName = Config.spineSkinAttachmentFormat.value
                    if skinAttachmentName ~= nil then
                        skinAttachmentName = string.gsub(skinAttachmentName, "{layernameprefix}", layerNamePrefix)
                        skinAttachmentName = string.gsub(skinAttachmentName, "{layernamesuffix}", layerNameSuffix) 
                    end

                    if slotName == skinAttachmentName then
                        slot = string.format([[{ "name": "%s", "bone": "%s", "attachment": "%s" }]], slotName, "root", skinAttachmentName)
                    else
                        slot = string.format([[{ "name": "%s", "bone": "%s"}]], slotName, "root")
                    end
                end
            end

            SkinsJson[skinName][#SkinsJson[skinName] + 1] = string.format([["%s": { "%s": { "name": "%s", "x": %.2f, "y": %.2f, "width": %d, "height": %d } }]], slotName, skinAttachmentName, fileNameTemplate, spriteX, spriteY, layerCelWidth, layerCelHeight)
        else
            if ArrayContainsKey(SkinsJson, "default") == false then
                SkinsJson["default"] = {}
            end

            fileNameTemplate = string.gsub(fileNameTemplate, "{layergroup}", "default")
            SkinsJson["default"][#SkinsJson["default"] + 1] = string.format([["%s": { "%s": { "x": %.2f, "y": %.2f, "width": %d, "height": %d } }]], slotName, fileNameTemplate, spriteX, spriteY, layerCelWidth, layerCelHeight)
        end
    else
        if ArrayContainsKey(SkinsJson, "default") == false then
            SkinsJson["default"] = {}
        end

        fileNameTemplate = string.gsub(fileNameTemplate, "{layergroup}", "default")
        SkinsJson["default"][#SkinsJson["default"] + 1] = string.format([["%s": { "%s": { "x": %.2f, "y": %.2f, "width": %d, "height": %d } }]], slotName, fileNameTemplate, spriteX, spriteY, layerCelWidth, layerCelHeight)
    end

    if ArrayContainsValue(SlotsJson, slot) == false then
        SlotsJson[#SlotsJson + 1] = slot
    end
end

function ExportSpineJsonEnd()
    JsonFile:write('"slots": [ ')
    JsonFile:write(table.concat(SlotsJson, ", "))
    JsonFile:write(" ], ")

    if Config.spineGroupsAsSkins.value == true then
        JsonFile:write('"skins": [ ')

        local parsedSkins = {}
        for key, value in pairs(SkinsJson) do
            parsedSkins[#parsedSkins + 1] = string.format([[{ "name": "%s", "attachments": { ]], key) .. table.concat(value, ", ") .. " } }"
        end

        JsonFile:write(table.concat(parsedSkins, ", "))
        JsonFile:write(' ], ')
    else
        JsonFile:write('"skins": { ')
        JsonFile:write('"default": { ')
        JsonFile:write(table.concat(SkinsJson["default"], ", "))
        JsonFile:write('} ')
        JsonFile:write('}, ')
    end

    JsonFile:write('"animations": { "animation": {} }')

    JsonFile:write("}")

    JsonFile:close()
end

function ArrayContainsValue(table, targetValue)
    for _, value in ipairs(table) do
        if value == targetValue then
            return true
        end
    end
    return false
end

function ArrayContainsKey(table, targetKey)
    for key, _ in pairs(table) do
        if key == targetKey then
            return true
        end
    end
    return false
end

function InitializeConfig()
    local configFile

    if Config.configSelect.value == nil then
        configFile = io.open(ConfigPathGlobal, "r")
        PopulateConfig(configFile)

        if configFile ~= nil then
            io.close(configFile)
        end
    end

    if Config.configSelect.value == "local" then
        configFile = io.open(ConfigPathLocal, "r")
    else
        configFile = io.open(ConfigPathGlobal, "r")
    end
    PopulateConfig(configFile)

    if configFile ~= nil then
        io.close(configFile)
    end
end

function PopulateConfig(configFile)
    if configFile ~= nil then
        for line in configFile:lines() do
            local index = string.find(line, "=")
            if index ~= nil then
                local key = string.sub(line, 1, index - 1)
                local value = string.sub(line, index + 1, string.len(line))
                if Config[key] ~= nil then
                    Config[key].value = value;
                end
            end
        end
    end
    for _, value in pairs(Config) do
        if value.value == nil then
            value.value = value.default
        else
            if value.value == "true" then
                value.value = true
            elseif value.value == "false" then
                value.value = false
            elseif value.value == "nil" then
                value.value = nil
            end
        end
        if type(value.value) ~= type(value.default) then
            value.value = value.default
        end
    end
end

function InitializeConfigKeys()
    for key, _ in pairs(Config) do
        table.insert(ConfigKeys, key)
    end

    table.sort(ConfigKeys)
end

function UpdateConfigFile(activeSprite)
    WriteConfig()
    InitializeConfig()

    for key, value in pairs(Config) do
        UpdateDialog(key, value.value)
    end
    Dlg:modify{
        id = "outputFile",
        filename = activeSprite.filename
    }
    Dlg:modify{
        id = "outputPath",
        text = app.fs.joinPath(app.fs.filePath(Dlg.data.outputFile), Dlg.data.outputSubdirectory)
    }
end

function UpdateConfigValue(configKey, newValue)
    Config[configKey].value = newValue
    UpdateChildrenVisibility(configKey, newValue)
end

function UpdateChildrenVisibility(configKey, visibility)
    for _, value in pairs(Config[configKey].children) do
        if Config[value].parent ~= nil then
            visibility = visibility and Config[configKey].value == Config[value].parent
        end
        Dlg:modify {
            id = value,
            visible = visibility,
        }
        if #Config[value].children ~= 0 then
            UpdateChildrenVisibility(value, visibility and Config[value].value)
        end
    end
end

function WriteConfig()
    local configFile
    if Config.configSelect.value == "local" then
        configFile = io.open(ConfigPathLocal, "w")
    else
        configFile = io.open(ConfigPathGlobal, "w")
    end

    if configFile ~= nil then
        for _, value in ipairs(ConfigKeys) do
            if type(Config[value].value) ~= "string" then
                configFile:write(value .. "=" .. tostring(Config[value].value) .. "\n")
            else
                configFile:write(value .. "=" .. Config[value].value .. "\n")
            end
        end
    end

    if configFile ~= nil then
        io.close(configFile)
    end
end

function UpdateDialog(configKey, newValue)
    if Config[configKey].type == "check" or Config[configKey].type == "radio" then
        Dlg:modify {
            id = configKey,
            selected = newValue,
        }
    elseif Config[configKey].type == "combobox" then
        Dlg:modify {
            id = configKey,
            option = newValue,
        }
    elseif Config[configKey].type == "entry" or Config[configKey].type == "number" then
        Dlg:modify {
            id = configKey,
            text = newValue,
        }
    elseif Config[configKey].type == "slider" then
        Dlg:modify {
            id = configKey,
            value = newValue,
        }
    end
    UpdateConfigValue(configKey, newValue)
end

function ResetConfig(activeSprite)
    for key, value in pairs(Config) do
        UpdateDialog(key, value.default)
    end
    Dlg:modify{
        id = "outputFile",
        filename = activeSprite.filename
    }
    Dlg:modify{
        id = "outputPath",
        text = app.fs.joinPath(app.fs.filePath(Dlg.data.outputFile), Dlg.data.outputSubdirectory)
    }
end

-- EXECUTION
LayerCount = 0
local activeSprite = app.activeSprite

if activeSprite == nil then
    app.alert("No sprite selected, script aborted.")
    return
end

local spritePath = app.fs.filePath(activeSprite.filename)
local scriptPath = debug.getinfo(1).source
scriptPath = string.sub(scriptPath, 2, string.len(scriptPath))
scriptPath = app.fs.normalizePath(scriptPath)

local scriptDirectory = string.match(scriptPath, "(.*[/\\])")

ConfigPathLocal = app.fs.joinPath(spritePath, "Aseprite-Exporter.conf")
ConfigPathGlobal = app.fs.joinPath(scriptDirectory, "Aseprite-Exporter.conf")

Config = {
    configSelect = {
        type = "combobox",
        default = "global",
        value = nil,
        parent = nil,
        children = {},
    },
    outputSubdirectory = {
        type = "entry",
        default = "images",
        value = nil,
        parent = nil,
        children = {},
    },
    outputGroupsAsDirectories = {
        type = "check",
        default = true,
        value = nil,
        parent = nil,
        children = {},
    },
    spriteSheetExport = {
        type = "check",
        default = true,
        value = nil,
        parent = nil,
        children = {
            "spriteSheetNameTrim",
            "spriteSheetFileNameFormat",
            "spriteSheetFileFormat",
            "spriteSheetTrim",
        },
    },
    spriteSheetNameTrim = {
        type = "check",
        default = true,
        value = nil,
        parent = nil,
        children = {},
    },
    spriteSheetFileNameFormat = {
        type = "entry",
        default = "{spritename}-{layergroup}-{layername}",
        value = nil,
        parent = nil,
        children = {},
    },
    spriteSheetFileFormat = {
        type = "combobox",
        default = "png",
        value = nil,
        parent = nil,
        children = {},
    },
    spriteSheetTrim = {
        type = "check",
        default = true,
        value = nil,
        parent = nil,
        children = {},
    },
    spineExport = {
        type = "check",
        default = true,
        value = nil,
        parent = nil,
        children = {
            "spineSetRootPostion",
            "spineSetImagesPath",
            "spineGroupsAsSkins",
            "spineSetStaticSlot",
        },
    },
    spineSetStaticSlot = {
        type = "check",
        default = true,
        value = nil,
        parent = nil,
        children = {
            "spineStaticSlotName",
        },
    },
    spineStaticSlotName = {
        type = "entry",
        default = "slot",
        value = nil,
        parent = nil,
        children = {},
    },
    spineSetRootPostion = {
        type = "check",
        default = true,
        value = nil,
        parent = nil,
        children = {
            "spineRootPostionMethod",
            "spineRootPostionX",
            "spineRootPostionY",
        },
    },
    spineRootPostionMethod = {
        type = "combobox",
        default = "center",
        value = nil,
        parent = nil,
        children = {
            "spineRootPostionX",
            "spineRootPostionY",
        },
    },
    spineRootPostionX = {
        type = "number",
        default = 0,
        value = nil,
        parent = "manual",
        children = {},
    },
    spineRootPostionY = {
        type = "number",
        default = 0,
        value = nil,
        parent = "manual",
        children = {},
    },
    spineSetImagesPath = {
        type = "check",
        default = true,
        value = nil,
        parent = nil,
        children = {
            "spineImagesPath",
        },
    },
    spineImagesPath = {
        type = "entry",
        default = "images",
        value = nil,
        parent = nil,
        children = {},
    },
    spineGroupsAsSkins = {
        type = "check",
        default = true,
        value = nil,
        parent = nil,
        children = {
            "spineSkinNameFormat",
            "spineSeparateSlotSkin",
        },
    },
    spineSkinNameFormat = {
        type = "entry",
        default = "weapon-{layergroup}",
        value = nil,
        parent = nil,
        children = {},
    },
    spineSeparateSlotSkin = {
        type = "check",
        default = true,
        value = nil,
        parent = nil,
        children = {
            "spineSlotNameFormat",
            "spineSkinAttachmentFormat",
            "spineLayerNameSeparator",
        },
    },
    spineSlotNameFormat = {
        type = "entry",
        default = "{layernameprefix}",
        value = nil,
        parent = nil,
        children = {},
    },
    spineSkinAttachmentFormat = {
        type = "entry",
        default = "{layernameprefix}-{layernamesuffix}",
        value = nil,
        parent = nil,
        children = {},
    },
    spineLayerNameSeparator = {
        type = "entry",
        default = "-",
        value = nil,
        parent = nil,
        children = {},
    },
}

ConfigKeys = {}

InitializeConfig()
InitializeConfigKeys()

Dlg = Dialog("Aseprite-Exporter")

Dlg:tab {
    id = "configSettings",
    text = "Config Settings",
}
Dlg:combobox {
    id = "configSelect",
    label = "Current Config:",
    option = Config.configSelect.value,
    options = { "global", "local" },
    onchange = function()
        UpdateConfigValue("configSelect", Dlg.data.configSelect)
        UpdateConfigFile(activeSprite)
    end,
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
    id = "outputSettings",
    text = "Output Settings",
}
Dlg:file {
    id = "outputFile",
    label = "Output File:",
    filename = activeSprite.filename,
    open = false,
    onchange = function()
        Dlg:modify {
            id = "outputPath",
            text = app.fs.joinPath(app.fs.filePath(Dlg.data.outputFile), Dlg.data.outputSubdirectory)
        }
    end,
}
Dlg:entry {
    id = "outputSubdirectory",
    label = "Output Subdirectory:",
    text = Config.outputSubdirectory.value,
    onchange = function()
        Config.outputSubdirectory.value = Dlg.data.outputSubdirectory
        Dlg:modify {
            id = "outputPath",
            text = app.fs.joinPath(app.fs.filePath(Dlg.data.outputFile), Dlg.data.outputSubdirectory)
        }
    end,
}
Dlg:label {
    id = "outputPath",
    label = "Output Path:",
    text = app.fs.joinPath(app.fs.filePath(Dlg.data.outputFile), Dlg.data.outputSubdirectory),
}
Dlg:check {
    id = "outputGroupsAsDirectories",
    label = "Groups As Directories:",
    selected = Config.outputGroupsAsDirectories.value,
    visible = Config.spriteSheetExport.value,
    onclick = function() UpdateConfigValue("outputGroupsAsDirectories", Dlg.data.outputGroupsAsDirectories) end,
}

Dlg:tab {
    id = "spriteSettingsTab",
    text = "Sprite Settings",
}
Dlg:check {
    id = "spriteSheetExport",
    label = "Export SpriteSheet:",
    selected = Config.spriteSheetExport.value,
    onclick = function() UpdateConfigValue("spriteSheetExport", Dlg.data.spriteSheetExport) end,
}
Dlg:check {
    id = "spriteSheetNameTrim",
    label = " Sprite Name Trim:",
    selected = Config.spriteSheetNameTrim.value,
    visible = Config.spriteSheetExport.value,
    onclick = function() UpdateConfigValue("spriteSheetNameTrim", Dlg.data.spriteSheetNameTrim) end,
}
Dlg:entry {
    id = "spriteSheetFileNameFormat",
    label = " File Name Format:",
    text = Config.spriteSheetFileNameFormat.value,
    visible = Config.spriteSheetExport.value,
    onchange = function() UpdateConfigValue("spriteSheetFileNameFormat", Dlg.data.spriteSheetFileNameFormat) end,
}
Dlg:combobox {
    id = "spriteSheetFileFormat",
    label = " File Format:",
    option = Config.spriteSheetFileFormat.value,
    options = { "png", "gif", "jpg" },
    onchange = function() UpdateConfigValue("spriteSheetFileFormat", Dlg.data.spriteSheetFileFormat) end,
}
Dlg:check {
    id = "spriteSheetTrim",
    label = " SpriteSheet Trim:",
    selected = Config.spriteSheetTrim.value,
    visible = Config.spriteSheetExport.value,
    onclick = function() UpdateConfigValue("spriteSheetTrim", Dlg.data.spriteSheetTrim) end,
}

Dlg:tab {
    id = "spineSettingsTab",
    text = "Spine Settings",
}
Dlg:check {
    id = "spineExport",
    label = "Export SpineSheet:",
    selected = Config.spineExport.value,
    onclick = function() UpdateConfigValue("spineExport", Dlg.data.spineExport) end,
}
Dlg:check {
    id = "spineSetStaticSlot",
    label = " Set Static Slot:",
    selected = Config.spineSetStaticSlot.value,
    visible = Config.spineExport.value,
    onclick = function() UpdateConfigValue("spineSetStaticSlot", Dlg.data.spineSetStaticSlot) end,
}
Dlg:entry {
    id = "spineStaticSlotName",
    label = "  Static Slot Name:",
    text = Config.spineStaticSlotName.value,
    visible = Config.spineExport.value and Config.spineSetStaticSlot.value,
    onchange = function() UpdateConfigValue("spineStaticSlotName", Dlg.data.spineStaticSlotName) end,
}
Dlg:check {
    id = "spineSetRootPostion",
    label = " Set Root Position:",
    selected = Config.spineSetRootPostion.value,
    visible = Config.spineExport.value,
    onclick = function() UpdateConfigValue("spineSetRootPostion", Dlg.data.spineSetRootPostion) end,
}
Dlg:combobox {
    id = "spineRootPostionMethod",
    label = "  Root position Method:",
    option = Config.spineRootPostionMethod.value,
    options = { "manual", "automatic", "center" },
    visible = Config.spineExport.value and Config.spineSetRootPostion.value,
    onchange = function() UpdateConfigValue("spineRootPostionMethod", Dlg.data.spineRootPostionMethod) end,
}
Dlg:number {
    id = "spineRootPostionX",
    label = "   Root Postion X:",
    text = Config.spineRootPostionX.value,
    visible = Config.spineExport.value and Config.spineSetRootPostion.value and Config.spineRootPostionMethod.value == "manual",
    decimals = 0,
    onchange = function() UpdateConfigValue("spineRootPostionX", Dlg.data.spineRootPostionX) end,
}
Dlg:number {
    id = "spineRootPostionY",
    label = "   Root Postion Y:",
    text = Config.spineRootPostionY.value,
    visible = Config.spineExport.value and Config.spineSetRootPostion.value and Config.spineRootPostionMethod.value == "manual",
    decimals = 0,
    onchange = function() UpdateConfigValue("spineRootPostionY", Dlg.data.spineRootPostionY) end,
}
Dlg:check {
    id = "spineSetImagesPath",
    label = " Set Images Path:",
    selected = Config.spineSetImagesPath.value,
    visible = Config.spineExport.value,
    onclick = function() UpdateConfigValue("spineSetImagesPath", Dlg.data.spineSetImagesPath) end,
}
Dlg:entry {
    id = "spineImagesPath",
    label = "  Images Path:",
    text = Config.spineImagesPath.value,
    visible = Config.spineExport.value and Config.spineSetImagesPath.value,
    onchange = function() UpdateConfigValue("spineImagesPath", Dlg.data.spineImagesPath) end,
}
Dlg:check {
    id = "spineGroupsAsSkins",
    label = " Groups As Skins:",
    selected = Config.spineGroupsAsSkins.value,
    visible = Config.spineExport.value,
    onclick = function() UpdateConfigValue("spineGroupsAsSkins", Dlg.data.spineGroupsAsSkins) end,
}
Dlg:entry {
    id = "spineSkinNameFormat",
    label = "  Skin Name Format:",
    text = Config.spineSkinNameFormat.value,
    visible = Config.spineExport.value and Config.spineGroupsAsSkins.value,
    onchange = function() UpdateConfigValue("spineSkinNameFormat", Dlg.data.spineSkinNameFormat) end,
}
Dlg:check {
    id = "spineSeparateSlotSkin",
    label = "  Separate Slot/Skin:",
    selected = Config.spineSeparateSlotSkin.value,
    visible = Config.spineExport.value and Config.spineGroupsAsSkins.value,
    onclick = function() UpdateConfigValue("spineSeparateSlotSkin", Dlg.data.spineSeparateSlotSkin) end,
}
Dlg:entry {
    id = "spineSlotNameFormat",
    label = "   Slot Name Format:",
    text = Config.spineSlotNameFormat.value,
    visible = Config.spineExport.value and Config.spineGroupsAsSkins.value and Config.spineSeparateSlotSkin.value,
    onchange = function() UpdateConfigValue("spineSlotNameFormat", Dlg.data.spineSlotNameFormat) end,
}
Dlg:entry {
    id = "spineSkinAttachmentFormat",
    label = "   Skin Attachment Format:",
    text = Config.spineSkinAttachmentFormat.value,
    visible = Config.spineExport.value and Config.spineGroupsAsSkins.value and Config.spineSeparateSlotSkin.value,
    onchange = function() UpdateConfigValue("spineSkinAttachmentFormat", Dlg.data.spineSkinAttachmentFormat) end,
}
Dlg:entry {
    id = "spineLayerNameSeparator",
    label = "   Layer Name Separator:",
    text = Config.spineLayerNameSeparator.value,
    visible = Config.spineExport.value and Config.spineGroupsAsSkins.value and Config.spineSeparateSlotSkin.value,
    onchange = function() UpdateConfigValue("spineLayerNameSeparator", Dlg.data.spineLayerNameSeparator) end,
}
Dlg:endtabs {
    id = "spineSettingsTab",
}

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
    onclick = function () ResetConfig(activeSprite) end,
}

Dlg:show()

WriteConfig()

if Dlg.data.cancel then
    return
end

if not Dlg.data.confirm then
    app.alert("Settings were not confirmed, script aborted.")
    return
end

if Dlg.data.outputPath == nil then
    app.alert("No output directory was specified, script aborted.")
    return
end

local fileName = app.fs.fileTitle(activeSprite.filename)

if Dlg.data.spriteSheetNameTrim then
    local _index = string.find(fileName, "_")
    if _index ~= nil then
        fileName = string.sub(fileName, _index + 1, string.len(fileName))
    end
end

local fileNameTemplate = Dlg.data.spriteSheetFileNameFormat:gsub("{spritename}", fileName)

if fileNameTemplate == nil then
    app.alert("No file name was specified, script aborted.")
    return
end

RootPositon = GetRootPosition(activeSprite)
app.alert("RootPosition is x:" .. RootPositon.x .. " y:" .. RootPositon.y)

local layerVisibilityData = GetLayerVisibilityData(activeSprite)

HideLayers(activeSprite)
Export(activeSprite, activeSprite, fileName, fileNameTemplate)
RestoreLayers(activeSprite, layerVisibilityData)

app.alert("Exported " .. LayerCount .. " layers to " .. Dlg.data.outputPath)

return
