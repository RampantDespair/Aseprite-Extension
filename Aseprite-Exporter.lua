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

function GetRootPosition(activeSprite, rootLayer, _, _, dlgData)
    if dlgData.spineExport == true and dlgData.spineSetRootPostion == true then
        if dlgData.spineRootPostionMethod == "manual" then
            return { x = dlgData.spineRootPostionX, y = dlgData.spineRootPostionY }
        elseif dlgData.spineRootPostionMethod == "automatic" then
            for _, layer in ipairs(rootLayer.layers) do
                if layer.name == "root" then
                    return { x = layer.cels[1].position.x, y = layer.cels[1].position.y }
                end
            end
        elseif dlgData.spineRootPostionMethod == "center" then
            return { x = activeSprite.width / 2, y = activeSprite.height / 2 }
        end
    end
    return { x = 0, y = 0 }
end

function Export(activeSprite, rootLayer, fileName, fileNameTemplate, dlgData)
    if dlgData.spineExport == true then
        ExportSpineJsonStart(fileName, dlgData)
    end

    ExportSpriteLayers(activeSprite, rootLayer, fileName, fileNameTemplate, dlgData)

    if dlgData.spineExport == true then
        ExportSpineJsonEnd(dlgData)
    end
end

function ExportSpriteLayers(activeSprite, rootLayer, fileName, fileNameTemplate, dlgData)
    for _, layer in ipairs(rootLayer.layers) do
        local _fileNameTemplate = fileNameTemplate
        local layerName = layer.name

        if layerName ~= "root" then
            if layer.isGroup then
                local previousVisibility = layer.isVisible
                layer.isVisible = true

                if dlgData.outputGroupsAsDirectories == true then
                    _fileNameTemplate = app.fs.joinPath(layerName, _fileNameTemplate)
                end

                ExportSpriteLayers(activeSprite, layer, fileName, _fileNameTemplate, dlgData)

                layer.isVisible = previousVisibility
            else
                layer.isVisible = true

                local layerParentName
                if pcall(function () layerParentName = layer.parent.name end) then
                    _fileNameTemplate = _fileNameTemplate:gsub("{layergroup}", layerParentName)
                else
                    _fileNameTemplate = _fileNameTemplate:gsub("{layergroup}", "default")
                end

                _fileNameTemplate = _fileNameTemplate:gsub("{layername}", layerName)

                if #layer.cels ~= 0 then
                    if dlgData.spriteSheetExport then
                        ExportSpriteSheet(activeSprite, layer, _fileNameTemplate, dlgData)
                    end

                    if dlgData.spineExport == true then
                        ExportSpineJsonParse(activeSprite, layer, _fileNameTemplate, dlgData)
                    end

                    LayerCount = LayerCount + 1
                end

                layer.isVisible = false
            end
        end
    end
end

function ExportSpriteSheet(activeSprite, layer, fileNameTemplate, dlgData)
    local cel = layer.cels[1]
    local currentLayer = Sprite(activeSprite)

    if dlgData.spriteSheetTrim then
        currentLayer:crop(cel.position.x, cel.position.y, cel.bounds.width, cel.bounds.height)
    end

    currentLayer:saveCopyAs(app.fs.joinPath(dlgData.outputPath, fileNameTemplate .. "." .. dlgData.spriteSheetFileFormat))
    currentLayer:close()
end

function ExportSpineJsonStart(fileName, dlgData)
    local jsonFileName = app.fs.joinPath(app.fs.filePath(dlgData.outputFile), fileName .. ".json")

    os.execute("mkdir " .. dlgData.outputPath)
    Json = io.open(jsonFileName, "w")

    Json:write('{ ')
    Json:write('"skeleton": { ')

    if dlgData.spineSetImagesPath then
        Json:write(string.format([["images": "%s" ]], "./" .. dlgData.spineImagesPath .. "/"))
    end

    Json:write('}, ')
    Json:write('"bones": [ { ')
    Json:write('"name": "root" ')
    Json:write('} ')
    Json:write('], ')

    SlotsJson = {}
    SkinsJson = {}
end

function ExportSpineJsonParse(_, layer, fileNameTemplate, dlgData)
    local layerName = layer.name

    local slot = string.format([[{ "name": "%s", "bone": "%s", "attachment": "%s" }]], layerName, "root", layerName)

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

    if dlgData.spineSetRootPostion == true then
        spriteX = realPostionX - RootPositon.x
        spriteY = RootPositon.y - realPositionY
    else
        spriteX = realPostionX
        spriteY = realPositionY
    end

    if dlgData.spineGroupsAsSkins == true then
        fileNameTemplate = fileNameTemplate:gsub("\\", "/")
        local skinName
        if pcall(function () skinName = layer.parent.name end) then
            skinName = dlgData.spineSkinNameFormat:gsub("{layergroup}", layer.parent.name)
        end

        if skinName ~= nil then
            if ArrayContainsKey(SkinsJson, skinName) == false then
                SkinsJson[skinName] = {}
            end

            local slotName = layerName
            local skinAttachmentName = layerName

            if dlgData.spineSeparateSlotSkin == true then
                local separatorPosition = string.find(layerName, dlgData.spineLayerNameSeparator)

                if separatorPosition then
                    local layerNamePrefix = string.sub(layerName, 1, separatorPosition - 1)
                    local layerNameSuffix = string.sub(layerName, separatorPosition + 1, #layerName)

                    slotName = dlgData.spineSlotNameFormat:gsub("{layernameprefix}", layerNamePrefix):gsub("{layernamesuffix}", layerNameSuffix)
                    skinAttachmentName = dlgData.spineSkinAttachmentFormat:gsub("{layernameprefix}", layerNamePrefix):gsub("{layernamesuffix}", layerNameSuffix)

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

            fileNameTemplate = fileNameTemplate:gsub("{layergroup}", "default")
            SkinsJson["default"][#SkinsJson["default"] + 1] = string.format([["%s": { "%s": { "x": %.2f, "y": %.2f, "width": %d, "height": %d } }]], layerName, fileNameTemplate, spriteX, spriteY, layerCelWidth, layerCelHeight)
        end
    else
        if ArrayContainsKey(SkinsJson, "default") == false then
            SkinsJson["default"] = {}
        end

        fileNameTemplate = fileNameTemplate:gsub("{layergroup}", "default")
        SkinsJson["default"][#SkinsJson["default"] + 1] = string.format([["%s": { "%s": { "x": %.2f, "y": %.2f, "width": %d, "height": %d } }]], layerName, fileNameTemplate, spriteX, spriteY, layerCelWidth, layerCelHeight)
    end

    if ArrayContainsValue(SlotsJson, slot) == false then
        SlotsJson[#SlotsJson + 1] = slot
    end
end

function ExportSpineJsonEnd(dlgData)
    Json:write('"slots": [ ')
    Json:write(table.concat(SlotsJson, ", "))
    Json:write(" ], ")

    if dlgData.spineGroupsAsSkins == true then
        Json:write('"skins": [ ')

        local parsedSkins = {}
        for key, value in pairs(SkinsJson) do
            parsedSkins[#parsedSkins + 1] = string.format([[{ "name": "%s", "attachments": { ]], key) .. table.concat(value, ", ") .. " } }"
        end

        Json:write(table.concat(parsedSkins, ", "))
        Json:write(' ] ')
    else
        Json:write('"skins": { ')
        Json:write('"default": { ')
        Json:write(table.concat(SkinsJson["default"], ", "))
        Json:write('} ')
        Json:write('} ')
    end

    Json:write("}")

    Json:close()
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

function InitializeConfig(configFile)
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
            end
        end
        if type(value.value) ~= type(value.default) then
            value.value = value.default
        end
    end

    for key, _ in pairs(Config) do
        table.insert(ConfigKeys, key)
    end

    table.sort(ConfigKeys)
end

function UpdateConfigValue(configKey)
    Config[configKey].value = Dlg.data[configKey]
    UpdateChildrenVisibility(configKey, Dlg.data[configKey])
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

function WriteConfig(configFile)
    if configFile ~= nil then
        for _, value in ipairs(ConfigKeys) do
            if type(Config[value].value) ~= "string" then
                configFile:write(value .. "=" .. tostring(Config[value].value) .. "\n")
            else
                configFile:write(value .. "=" .. Config[value].value .. "\n")
            end
        end
    end
end

function UpdateDialog(configKey)
    if Config[configKey].type == "check" or Config[configKey].type == "radio" then
        Dlg:modify {
            id = configKey,
            selected = Config[configKey].default,
        }
    elseif Config[configKey].type == "combobox" then
        Dlg:modify {
            id = configKey,
            option = Config[configKey].default,
        }
    elseif Config[configKey].type == "entry" or Config[configKey].type == "number" then
        Dlg:modify {
            id = configKey,
            text = Config[configKey].default,
        }
    elseif Config[configKey].type == "slider" then
        Dlg:modify {
            id = configKey,
            value = Config[configKey].default,
        }
    end
    UpdateConfigValue(configKey)
end

function ResetConfig(activeSprite)
    for key, _ in pairs(Config) do
        UpdateDialog(key)
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

local scriptPath = debug.getinfo(1).source
scriptPath = string.sub(scriptPath, 2, string.len(scriptPath))
scriptPath = app.fs.normalizePath(scriptPath)

local scriptDirectory = scriptPath:match("(.*[/\\])")

local configPath = app.fs.joinPath(scriptDirectory, "Aseprite-Exporter.conf")

Config = {
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
        },
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

local configFile = io.open(configPath, "r")
InitializeConfig(configFile)

Dlg = Dialog("Aseprite-Exporter")

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
    onclick = function() UpdateConfigValue("outputGroupsAsDirectories") end,
}

Dlg:tab {
    id = "spriteSettingsTab",
    text = "Sprite Settings",
}
Dlg:check {
    id = "spriteSheetExport",
    label = "Export SpriteSheet:",
    selected = Config.spriteSheetExport.value,
    onclick = function() UpdateConfigValue("spriteSheetExport") end,
}
Dlg:check {
    id = "spriteSheetNameTrim",
    label = " Sprite Name Trim:",
    selected = Config.spriteSheetNameTrim.value,
    visible = Config.spriteSheetExport.value,
    onclick = function() UpdateConfigValue("spriteSheetNameTrim") end,
}
Dlg:entry {
    id = "spriteSheetFileNameFormat",
    label = " File Name Format:",
    text = Config.spriteSheetFileNameFormat.value,
    visible = Config.spriteSheetExport.value,
    onchange = function() UpdateConfigValue("spriteSheetFileNameFormat") end,
}
Dlg:combobox {
    id = "spriteSheetFileFormat",
    label = " File Format:",
    option = Config.spriteSheetFileFormat.value,
    options = {"png", "gif", "jpg"},
    onchange = function() UpdateConfigValue("spriteSheetFileFormat") end,
}
Dlg:check {
    id = "spriteSheetTrim",
    label = " SpriteSheet Trim:",
    selected = Config.spriteSheetTrim.value,
    visible = Config.spriteSheetExport.value,
    onclick = function() UpdateConfigValue("spriteSheetTrim") end,
}

Dlg:tab {
    id = "spineSettingsTab",
    text = "Spine Settings",
}
Dlg:check {
    id = "spineExport",
    label = "Export SpineSheet:",
    selected = Config.spineExport.value,
    onclick = function() UpdateConfigValue("spineExport") end,
}
Dlg:check {
    id = "spineSetRootPostion",
    label = " Set Root Position:",
    selected = Config.spineSetRootPostion.value,
    visible = Config.spineExport.value,
    onclick = function() UpdateConfigValue("spineSetRootPostion") end,
}
Dlg:combobox {
    id = "spineRootPostionMethod",
    label = "  Root position Method:",
    option = Config.spineRootPostionMethod.value,
    options = {"manual", "automatic", "center"},
    visible = Config.spineExport.value and Config.spineSetRootPostion.value,
    onchange = function() UpdateConfigValue("spineRootPostionMethod") end,
}
Dlg:number {
    id = "spineRootPostionX",
    label = "   Root Postion X:",
    text = Config.spineRootPostionX.value,
    visible = Config.spineExport.value and Config.spineSetRootPostion.value and Config.spineRootPostionMethod.value == "manual",
    decimals = 0,
    onchange = function() UpdateConfigValue("spineRootPostionX") end,
}
Dlg:number {
    id = "spineRootPostionY",
    label = "   Root Postion Y:",
    text = Config.spineRootPostionY.value,
    visible = Config.spineExport.value and Config.spineSetRootPostion.value and Config.spineRootPostionMethod.value == "manual",
    decimals = 0,
    onchange = function() UpdateConfigValue("spineRootPostionY") end,
}
Dlg:check {
    id = "spineSetImagesPath",
    label = " Set Images Path:",
    selected = Config.spineSetImagesPath.value,
    visible = Config.spineExport.value,
    onclick = function() UpdateConfigValue("spineSetImagesPath") end,
}
Dlg:entry {
    id = "spineImagesPath",
    label = "  Images Path:",
    text = Config.spineImagesPath.value,
    visible = Config.spineExport.value and Config.spineSetImagesPath.value,
    onchange = function() UpdateConfigValue("spineImagesPath") end,
}
Dlg:check {
    id = "spineGroupsAsSkins",
    label = " Groups As Skins:",
    selected = Config.spineGroupsAsSkins.value,
    visible = Config.spineExport.value,
    onclick = function() UpdateConfigValue("spineGroupsAsSkins") end,
}
Dlg:entry {
    id = "spineSkinNameFormat",
    label = "  Skin Name Format:",
    text = Config.spineSkinNameFormat.value,
    visible = Config.spineExport.value and Config.spineGroupsAsSkins.value,
    onchange = function() UpdateConfigValue("spineSkinNameFormat") end,
}
Dlg:check {
    id = "spineSeparateSlotSkin",
    label = "  Separate Slot/Skin:",
    selected = Config.spineSeparateSlotSkin.value,
    visible = Config.spineExport.value and Config.spineGroupsAsSkins.value,
    onclick = function() UpdateConfigValue("spineSeparateSlotSkin") end,
}
Dlg:entry {
    id = "spineSlotNameFormat",
    label = "   Slot Name Format:",
    text = Config.spineSlotNameFormat.value,
    visible = Config.spineExport.value and Config.spineGroupsAsSkins.value and Config.spineSeparateSlotSkin.value,
    onchange = function() UpdateConfigValue("spineSlotNameFormat") end,
}
Dlg:entry {
    id = "spineSkinAttachmentFormat",
    label = "   Skin Attachment Format:",
    text = Config.spineSkinAttachmentFormat.value,
    visible = Config.spineExport.value and Config.spineGroupsAsSkins.value and Config.spineSeparateSlotSkin.value,
    onchange = function() UpdateConfigValue("spineSkinAttachmentFormat") end,
}
Dlg:entry {
    id = "spineLayerNameSeparator",
    label = "   Layer Name Separator:",
    text = Config.spineLayerNameSeparator.value,
    visible = Config.spineExport.value and Config.spineGroupsAsSkins.value and Config.spineSeparateSlotSkin.value,
    onchange = function() UpdateConfigValue("spineLayerNameSeparator") end,
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

configFile = io.open(configPath, "w")
WriteConfig(configFile)

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

RootPositon = GetRootPosition(activeSprite, activeSprite, fileName, fileNameTemplate, Dlg.data)
app.alert("RootPosition is x:" .. RootPositon.x .. " y:" .. RootPositon.y)

local layerVisibilityData = GetLayerVisibilityData(activeSprite)

HideLayers(activeSprite)
Export(activeSprite, activeSprite, fileName, fileNameTemplate, Dlg.data)
RestoreLayers(activeSprite, layerVisibilityData)

app.alert("Exported " .. LayerCount .. " layers to " .. Dlg.data.outputPath)

return
