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
        if (layer.isGroup) then
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

function Export(activeSprite, rootLayer, fileName, fileNameTemplate, dlgData)
    if dlgData.exportSpineSheet == true then
        ExportSpineJsonStart(fileName, dlgData)
    end

    if dlgData.exportSpineSheet == true and dlgData.setRootPostion == true and dlgData.rootPostionMethod == "automatic" then
        for _, layer in ipairs(rootLayer.layers) do
            if layer.name == "root" then
                RootPositon = layer.cels[1].position
                break
            end
        end
        app.alert("Automatic RootPosition is x:" .. RootPositon.x .. " y:" .. RootPositon.y)
    end

    ExportSpriteLayers(activeSprite, rootLayer, fileName, fileNameTemplate, dlgData)

    if dlgData.exportSpineSheet == true then
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

                if dlgData.groupsAsSkins == true then
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
                    if dlgData.exportSpriteSheet then
                        ExportSpriteSheet(activeSprite, layer, _fileNameTemplate, dlgData)
                    end

                    if dlgData.exportSpineSheet == true then
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

    if dlgData.exportSpriteSheetTrim then
        currentLayer:crop(cel.position.x, cel.position.y, cel.bounds.width, cel.bounds.height)
    end

    currentLayer:saveCopyAs(app.fs.joinPath(dlgData.outputPath, fileNameTemplate .. "." .. dlgData.exportFileFormat))
    currentLayer:close()
end

function ExportSpineJsonStart(fileName, dlgData)
    local jsonFileName = app.fs.joinPath(app.fs.filePath(dlgData.outputFile), fileName .. ".json")

    os.execute("mkdir " .. dlgData.outputPath)
    Json = io.open(jsonFileName, "w")

    Json:write('{ ')
    Json:write('"skeleton": { ')

    if dlgData.setSpinePaths then
        Json:write(string.format([["images": "%s", ]], "./" .. dlgData.spineImagesPath .. "/"))
        Json:write(string.format([["audio": "%s" ]], "./" .. dlgData.spineAudioPath .. "/"))
    end

    Json:write('}, ')
    Json:write('"bones": [ { ')
    Json:write('"name": "root" ')
    Json:write('} ')
    Json:write('], ')

    SlotsJson = {}
    SkinsJson = {}
end

function ExportSpineJsonParse(activeSprite, layer, fileNameTemplate, dlgData)
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

    if dlgData.setRootPostion == true then
        if dlgData.rootPostionMethod == "automatic" then
            spriteX = realPostionX - RootPositon.x
            spriteY = RootPositon.y - realPositionY
        else
            spriteX = realPostionX - dlgData.rootPositionX
            spriteY = dlgData.rootPositionY - realPositionY
        end
    else
        spriteX = realPostionX
        spriteY = realPositionY
    end

    if dlgData.groupsAsSkins == true then
        fileNameTemplate = fileNameTemplate:gsub("\\", "/")
        local skinName
        if pcall(function () skinName = layer.parent.name end) then
            skinName = dlgData.skinNameFormat:gsub("{layergroup}", layer.parent.name)
        end

        if skinName ~= nil then
            if ArrayContainsKey(SkinsJson, skinName) == false then
                SkinsJson[skinName] = {}
            end

            local slotName = layerName
            local skinAttachmentName = layerName

            if dlgData.separateSlotSkin == true then
                local separatorPosition = string.find(layerName, dlgData.layerNameSeparator)

                if separatorPosition then
                    local layerNamePrefix = string.sub(layerName, 1, separatorPosition - 1)
                    local layerNameSuffix = string.sub(layerName, separatorPosition + 1, #layerName)

                    slotName = dlgData.slotNameFormat:gsub("{layernameprefix}", layerNamePrefix):gsub("{layernamesuffix}", layerNameSuffix)
                    skinAttachmentName = dlgData.skinAttachmentFormat:gsub("{layernameprefix}", layerNamePrefix):gsub("{layernamesuffix}", layerNameSuffix)

                    if slotName == skinAttachmentName then
                        slot = string.format([[{ "name": "%s", "bone": "%s", "attachment": "%s" }]], slotName, "root", skinAttachmentName)
                    else
                        slot = string.format([[{ "name": "%s", "bone": "%s"}]], slotName, "root")
                    end
                end
            end

            SkinsJson[skinName][#SkinsJson[skinName] + 1] = string.format([["%s": { "%s": { "name": "%s", "x": %.2f, "y": %.2f, "width": %d, "height": %d } } ]], slotName, skinAttachmentName, fileNameTemplate, spriteX, spriteY, layerCelWidth, layerCelHeight)
        else
            if ArrayContainsKey(SkinsJson, "default") == false then
                SkinsJson["default"] = {}
            end

            fileNameTemplate = fileNameTemplate:gsub("{layergroup}", "default")
            SkinsJson["default"][#SkinsJson["default"] + 1] = string.format([["%s": { "%s": { "x": %.2f, "y": %.2f, "width": %d, "height": %d } } ]], layerName, fileNameTemplate, spriteX, spriteY, layerCelWidth, layerCelHeight)
        end
    else
        if ArrayContainsKey(SkinsJson, "default") == false then
            SkinsJson["default"] = {}
        end

        fileNameTemplate = fileNameTemplate:gsub("{layergroup}", "default")
        SkinsJson["default"][#SkinsJson["default"] + 1] = string.format([["%s": { "%s": { "x": %.2f, "y": %.2f, "width": %d, "height": %d } } ]], layerName, fileNameTemplate, spriteX, spriteY, layerCelWidth, layerCelHeight)
    end

    if ArrayContainsValue(SlotsJson, slot) == false then
        SlotsJson[#SlotsJson + 1] = slot
    end
end

function ExportSpineJsonEnd(dlgData)
    Json:write('"slots": [ ')
    Json:write(table.concat(SlotsJson, ", "))
    Json:write("], ")

    if dlgData.groupsAsSkins == true then
        Json:write('"skins": [ ')

        local parsedSkins = {}
        for key, value in pairs(SkinsJson) do
            parsedSkins[#parsedSkins + 1] = string.format([[{ "name": "%s", "attachments": { ]], key) .. table.concat(value, ", ") .. "} }"
        end

        Json:write(table.concat(parsedSkins, ", "))
        Json:write('] ')
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

function GetInitialValue(variable, defaultValue)
    if variable ~= nil then
        if variable == "true" then
            return true
        elseif variable == "false" then
            return false
        else
            return variable
        end
    else
        return defaultValue
    end
end

-- EXECUTION
LayerCount = 0
local activeSprite = app.activeSprite

if (activeSprite == nil) then
    app.alert("No sprite selected, script aborted.")
    return
end

local scriptPath = debug.getinfo(1).source
scriptPath = string.sub(scriptPath, 2, string.len(scriptPath))
scriptPath = app.fs.normalizePath(scriptPath)

local scriptDirectory = scriptPath:match("(.*[/\\])")

local configPath = app.fs.joinPath(scriptDirectory, "Aseprite-Exporter.conf")
local configFile = io.open(configPath, "r")
local configFileContents = {}

if configFile ~= nil then
    for line in configFile:lines() do
        local index = string.find(line, "=")
        if index ~= nil then
            local key = string.sub(line, 1, index - 1)
            local value = string.sub(line, index + 1, string.len(line))
            configFileContents[key] = value;
        end
    end
end

configFile = io.open(configPath, "w")

local dlg = Dialog("Aseprite-Exporter")
dlg:separator{
    id = "separator1",
    text = "Output Settings"
}
dlg:file{
    id = "outputFile",
    label = "Output File:",
    filename = activeSprite.filename,
    open = false,
    onchange = function()
        dlg:modify{
            id = "outputPath",
            text = app.fs.joinPath(app.fs.filePath(dlg.data.outputFile), dlg.data.outputSubdirectory)
        }
    end
}
dlg:entry{
    id = "outputSubdirectory",
    label = "Output Subdirectory:",
    text = GetInitialValue(configFileContents["outputSubdirectory"], "images"),
    onchange = function()
        dlg:modify{
            id = "outputPath",
            text = app.fs.joinPath(app.fs.filePath(dlg.data.outputFile), dlg.data.outputSubdirectory)
        }
    end
}
dlg:label{
    id = "outputPath",
    label = "Output Path:",
    text = app.fs.joinPath(app.fs.filePath(dlg.data.outputFile), dlg.data.outputSubdirectory)
}
dlg:separator{
    id = "separator2",
    text = "SpriteSheet Settings"
}
dlg:check{
    id = "exportSpriteSheet",
    label = "Export SpriteSheet:",
    selected = GetInitialValue(configFileContents["exportSpriteSheet"], true),
    onclick = function()
        dlg:modify{
            id = "exportSpriteNameTrim",
            visible = dlg.data.exportSpriteSheet
        }
        dlg:modify{
            id = "exportFileNameFormat",
            visible = dlg.data.exportSpriteSheet
        }
        dlg:modify{
            id = "exportFileFormat",
            visible = dlg.data.exportSpriteSheet
        }
        dlg:modify{
            id = "exportSpriteSheetTrim",
            visible = dlg.data.exportSpriteSheet
        }
    end
}
dlg:check{
    id = "exportSpriteNameTrim",
    label = " Sprite Name Trim:",
    selected = GetInitialValue(configFileContents["exportSpriteNameTrim"], true),
    visible = GetInitialValue(configFileContents["exportSpriteSheet"], true)
}
dlg:entry{
    id = "exportFileNameFormat",
    label = " File Name Format:",
    text = GetInitialValue(configFileContents["exportFileNameFormat"], "{spritename}-{layergroup}-{layername}"),
    visible = GetInitialValue(configFileContents["exportSpriteSheet"], true)
}
dlg:combobox{
    id = "exportFileFormat",
    label = " File Format:",
    option = GetInitialValue(configFileContents["exportFileFormat"], "png"),
    options = {"png", "gif", "jpg"},
    visible = GetInitialValue(configFileContents["exportSpriteSheet"], true)
}
dlg:check{
    id = "exportSpriteSheetTrim",
    label = " SpriteSheet Trim:",
    selected = GetInitialValue(configFileContents["exportSpriteSheetTrim"], true),
    visible = GetInitialValue(configFileContents["exportSpriteSheet"], true)
}
dlg:separator{
    id = "separator3",
    text = "Spine Settings"
}
dlg:check{
    id = "exportSpineSheet",
    label = "Export SpineSheet:",
    selected = GetInitialValue(configFileContents["exportSpineSheet"], true),
    onclick = function()
        dlg:modify{
            id = "setRootPostion",
            visible = dlg.data.exportSpineSheet
        }
        dlg:modify{
            id = "rootPostionMethod",
            visible = dlg.data.exportSpineSheet and dlg.data.setRootPostion
        }
        dlg:modify{
            id = "rootPositionX",
            visible = dlg.data.exportSpineSheet and dlg.data.setRootPostion and dlg.data.rootPostionMethod == "manual"
        }
        dlg:modify{
            id = "rootPositionY",
            visible = dlg.data.exportSpineSheet and dlg.data.setRootPostion and dlg.data.rootPostionMethod == "manual"
        }
        dlg:modify{
            id = "setSpinePaths",
            visible = dlg.data.exportSpineSheet
        }
        dlg:modify{
            id = "spineImagesPath",
            visible = dlg.data.exportSpineSheet and dlg.data.setSpinePaths
        }
        dlg:modify{
            id = "spineAudioPath",
            visible = dlg.data.exportSpineSheet and dlg.data.setSpinePaths
        }
    end
}
dlg:check{
    id = "setRootPostion",
    label = " Set Root Position:",
    selected = GetInitialValue(configFileContents["setRootPostion"], true),
    visible = GetInitialValue(configFileContents["exportSpineSheet"], true),
    onclick = function()
        dlg:modify{
            id = "rootPostionMethod",
            visible = dlg.data.setRootPostion
        }
        dlg:modify{
            id = "rootPositionX",
            visible = dlg.data.setRootPostion and dlg.data.rootPostionMethod == "manual"
        }
        dlg:modify{
            id = "rootPositionY",
            visible = dlg.data.setRootPostion and dlg.data.rootPostionMethod == "manual"
        }
    end
}
dlg:combobox{
    id = "rootPostionMethod",
    label = "  Root position Method:",
    option = GetInitialValue(configFileContents["rootPostionMethod"], "automatic"),
    options = {"manual", "automatic"},
    visible = GetInitialValue(configFileContents["exportSpineSheet"], true) and GetInitialValue(configFileContents["setRootPostion"], true),
    onchange = function()
        dlg:modify{
            id = "rootPositionX",
            visible = dlg.data.rootPostionMethod == "manual"
        }
        dlg:modify{
            id = "rootPositionY",
            visible = dlg.data.rootPostionMethod == "manual"
        }
    end
}
dlg:number{
    id = "rootPositionX",
    label = "   Root Postion X:",
    text = GetInitialValue(configFileContents["rootPositionX"], "0"),
    visible = GetInitialValue(configFileContents["exportSpineSheet"], true) and GetInitialValue(configFileContents["setRootPostion"], true) and GetInitialValue(configFileContents["rootPostionMethod"], "automatic") == "manual",
    decimals = 0
}
dlg:number{
    id = "rootPositionY",
    label = "   Root Postion Y:",
    text = GetInitialValue(configFileContents["rootPositionY"], "0"),
    visible = GetInitialValue(configFileContents["exportSpineSheet"], true) and GetInitialValue(configFileContents["setRootPostion"], true) and GetInitialValue(configFileContents["rootPostionMethod"], "automatic") == "manual",
    decimals = 0
}
dlg:check{
    id = "setSpinePaths",
    label = " Set Spine Paths:",
    selected = GetInitialValue(configFileContents["setSpinePaths"], true),
    visible = GetInitialValue(configFileContents["exportSpineSheet"], true),
    onclick = function()
        dlg:modify{
            id = "spineImagesPath",
            visible = dlg.data.setSpinePaths
        }
        dlg:modify{
            id = "spineAudioPath",
            visible = dlg.data.setSpinePaths
        }
    end
}
dlg:entry{
    id = "spineImagesPath",
    label = "  Images Path:",
    text = GetInitialValue(configFileContents["spineImagesPath"], "images"),
    visible = GetInitialValue(configFileContents["exportSpineSheet"], true) and GetInitialValue(configFileContents["setSpinePaths"], true)
}
dlg:entry{
    id = "spineAudioPath",
    label = "  Audio Path:",
    text = GetInitialValue(configFileContents["spineAudioPath"], "audio"),
    visible = GetInitialValue(configFileContents["exportSpineSheet"], true) and GetInitialValue(configFileContents["setSpinePaths"], true)
}
dlg:separator{
    id = "separator4",
    text = "Group Settings"
}
dlg:check{
    id = "groupsAsSkins",
    label = "Groups As Skins:",
    selected = GetInitialValue(configFileContents["groupsAsSkins"], true),
    onclick = function()
        dlg:modify{
            id = "skinNameFormat",
            visible = dlg.data.groupsAsSkins
        }
        dlg:modify{
            id = "separateSlotSkin",
            visible = dlg.data.groupsAsSkins
        }
        dlg:modify{
            id = "slotNameFormat",
            visible = dlg.data.groupsAsSkins and dlg.data.separateSlotSkin
        }
        dlg:modify{
            id = "skinAttachmentFormat",
            visible = dlg.data.groupsAsSkins and dlg.data.separateSlotSkin
        }
        dlg:modify{
            id = "layerNameSeparator",
            visible = dlg.data.groupsAsSkins and dlg.data.separateSlotSkin
        }
    end
}
dlg:entry{
    id = "skinNameFormat",
    label = " Skin Name Format:",
    text = GetInitialValue(configFileContents["skinNameFormat"], "weapon-{layergroup}"),
    visible = GetInitialValue(configFileContents["groupsAsSkins"], true)
}
dlg:check{
    id = "separateSlotSkin",
    label = " Separate Slot/Skin:",
    selected = GetInitialValue(configFileContents["separateSlotSkin"], true),
    visible = GetInitialValue(configFileContents["groupsAsSkins"], true),
    onclick = function()
        dlg:modify{
            id = "slotNameFormat",
            visible = dlg.data.separateSlotSkin
        }
        dlg:modify{
            id = "skinAttachmentFormat",
            visible = dlg.data.separateSlotSkin
        }
        dlg:modify{
            id = "layerNameSeparator",
            visible = dlg.data.separateSlotSkin
        }
    end
}
dlg:entry{
    id = "slotNameFormat",
    label = "  Slot Name Format:",
    text = GetInitialValue(configFileContents["slotNameFormat"], "{layernameprefix}"),
    visible = GetInitialValue(configFileContents["groupsAsSkins"], true) and GetInitialValue(configFileContents["separateSlotSkin"], true)
}
dlg:entry{
    id = "skinAttachmentFormat",
    label = "  Skin Attachment Format:",
    text = GetInitialValue(configFileContents["skinAttachmentFormat"], "{layernameprefix}-{layernamesuffix}"),
    visible = GetInitialValue(configFileContents["groupsAsSkins"], true) and GetInitialValue(configFileContents["separateSlotSkin"], true)
}
dlg:entry{
    id = "layerNameSeparator",
    label = "  Layer Name Separator:",
    text = GetInitialValue(configFileContents["layerNameSeparator"], "-"),
    visible = GetInitialValue(configFileContents["groupsAsSkins"], true) and GetInitialValue(configFileContents["separateSlotSkin"], true)
}
dlg:separator{
    id = "separator5"
}
dlg:entry{
    id = "help",
    label = "Need help? Visit my GitHub repository @",
    text = "https://github.com/RampantDespair/Aseprite-Exporter"
}
dlg:separator{
    id = "separator6"
}

dlg:button{
    id = "confirm",
    text = "Confirm"
}
dlg:button{
    id = "cancel",
    text = "Cancel"
}
dlg:button{
    id = "reset",
    text = "Reset",
    onclick = function ()
        dlg:modify{
            id = "outputFile",
            filename = activeSprite.filename
        }
        dlg:modify{
            id = "outputSubdirectory",
            text = "images"
        }
        dlg:modify{
            id = "outputPath",
            text = app.fs.joinPath(app.fs.filePath(dlg.data.outputFile), dlg.data.outputSubdirectory)
        }
        dlg:modify{
            id = "exportSpriteSheet",
            selected = true
        }
        dlg:modify{
            id = "exportSpriteNameTrim",
            selected = true,
            visible = true
        }
        dlg:modify{
            id = "exportFileNameFormat",
            text = "{spritename}-{layergroup}-{layername}",
            visible = true
        }
        dlg:modify{
            id = "exportFileFormat",
            option = "png",
            visible = true
        }
        dlg:modify{
            id = "exportSpriteSheetTrim",
            selected = true,
            visible = true
        }
        dlg:modify{
            id = "exportSpineSheet",
            selected = true
        }
        dlg:modify{
            id = "setRootPostion",
            selected = true,
            visible = true
        }
        dlg:modify{
            id = "rootPostionMethod",
            option = "automatic",
            visible = true
        }
        dlg:modify{
            id = "rootPositionX",
            text = "0",
            visible = false
        }
        dlg:modify{
            id = "rootPositionY",
            text = "0",
            visible = false
        }
        dlg:modify{
            id = "setSpinePaths",
            selected = true,
            visible = true
        }
        dlg:modify{
            id = "spineImagesPath",
            text = "images",
            visible = true
        }
        dlg:modify{
            id = "spineAudioPath",
            text = "audio",
            visible = true
        }
        dlg:modify{
            id = "groupsAsSkins",
            selected = true
        }
        dlg:modify{
            id = "skinNameFormat",
            text = "weapon-{layergroup}",
            visible = true
        }
        dlg:modify{
            id = "separateSlotSkin",
            selected = true,
            visible = true
        }
        dlg:modify{
            id = "slotNameFormat",
            text = "{layernameprefix}",
            visible = true
        }
        dlg:modify{
            id = "skinAttachmentFormat",
            text = "{layernameprefix}-{layernamesuffix}",
            visible = true
        }
        dlg:modify{
            id = "layerNameSeparator",
            text = "-",
            visible = true
        }
    end
}
dlg:show()

configFileContents["outputSubdirectory"] = dlg.data.outputSubdirectory
configFileContents["exportSpriteSheet"] = dlg.data.exportSpriteSheet
configFileContents["exportSpriteNameTrim"] = dlg.data.exportSpriteNameTrim
configFileContents["exportFileNameFormat"] = dlg.data.exportFileNameFormat
configFileContents["exportFileFormat"] = dlg.data.exportFileFormat
configFileContents["exportSpriteSheetTrim"] = dlg.data.exportSpriteSheetTrim
configFileContents["exportSpineSheet"] = dlg.data.exportSpineSheet
configFileContents["setRootPostion"] = dlg.data.setRootPostion
configFileContents["rootPostionMethod"] = dlg.data.rootPostionMethod
configFileContents["rootPositionX"] = dlg.data.rootPositionX
configFileContents["rootPositionY"] = dlg.data.rootPositionY
configFileContents["setSpinePaths"] = dlg.data.setSpinePaths
configFileContents["spineImagesPath"] = dlg.data.spineImagesPath
configFileContents["spineAudioPath"] = dlg.data.spineAudioPath
configFileContents["groupsAsSkins"] = dlg.data.groupsAsSkins
configFileContents["skinNameFormat"] = dlg.data.skinNameFormat
configFileContents["separateSlotSkin"] = dlg.data.separateSlotSkin
configFileContents["slotNameFormat"] = dlg.data.slotNameFormat
configFileContents["skinAttachmentFormat"] = dlg.data.skinAttachmentFormat
configFileContents["layerNameSeparator"] = dlg.data.layerNameSeparator

table.sort(configFileContents)
if configFile ~= nil then
    for key, value in pairs(configFileContents) do
        configFile:write(key .. "=" .. tostring(value) .. "\n")
    end
end

if dlg.data.cancel then
    return
end

if not dlg.data.confirm then
    app.alert("Settings were not confirmed, script aborted.")
    return
end

if dlg.data.outputPath == nil then
    app.alert("No output directory was specified, script aborted.")
    return
end

local fileName = app.fs.fileTitle(activeSprite.filename)

if dlg.data.exportSpriteNameTrim then
    local _index = string.find(fileName, "_")
    if _index ~= nil then
        fileName = string.sub(fileName, _index + 1, string.len(fileName))
    end
end

local fileNameTemplate = dlg.data.exportFileNameFormat:gsub("{spritename}", fileName)

if fileNameTemplate == nil then
    app.alert("No file name was specified, script aborted.")
    return
end

local layerVisibilityData = GetLayerVisibilityData(activeSprite)

HideLayers(activeSprite)
Export(activeSprite, activeSprite, fileName, fileNameTemplate, dlg.data)
RestoreLayers(activeSprite, layerVisibilityData)

app.alert("Exported " .. LayerCount .. " layers to " .. dlg.data.outputPath)

return
