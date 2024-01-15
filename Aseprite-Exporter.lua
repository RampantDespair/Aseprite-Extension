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

    if dlgData.spriteSheetExport == true then
        ExportSpriteLayers(activeSprite, rootLayer, fileName, fileNameTemplate, dlgData)
    end

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

                if dlgData.spineGroupsAsSkins == true then
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

function GetInitialValue(variable, defaultValue)
    local ret
    if variable ~= nil then
        if variable == "true" then
            ret = true
        elseif variable == "false" then
            ret = false
        else
            ret = variable
        end
    end

    if type(ret) == type(defaultValue) then
        return ret
    else
        return defaultValue
    end
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
local configFile = io.open(configPath, "r")
local oldConfigFileContents = {}

if configFile ~= nil then
    for line in configFile:lines() do
        local index = string.find(line, "=")
        if index ~= nil then
            local key = string.sub(line, 1, index - 1)
            local value = string.sub(line, index + 1, string.len(line))
            oldConfigFileContents[key] = value;
        end
    end
end

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
    text = GetInitialValue(oldConfigFileContents["outputSubdirectory"], "images"),
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
    text = "Sprite Settings"
}
dlg:check{
    id = "spriteSheetExport",
    label = "Export SpriteSheet:",
    selected = GetInitialValue(oldConfigFileContents["spriteSheetExport"], true),
    onclick = function()
        dlg:modify{
            id = "spriteSheetNameTrim",
            visible = dlg.data.spriteSheetExport
        }
        dlg:modify{
            id = "spriteSheetFileNameFormat",
            visible = dlg.data.spriteSheetExport
        }
        dlg:modify{
            id = "spriteSheetFileFormat",
            visible = dlg.data.spriteSheetExport
        }
        dlg:modify{
            id = "spriteSheetTrim",
            visible = dlg.data.spriteSheetExport
        }
    end
}
dlg:check{
    id = "spriteSheetNameTrim",
    label = " Sprite Name Trim:",
    selected = GetInitialValue(oldConfigFileContents["spriteSheetNameTrim"], true),
    visible = GetInitialValue(oldConfigFileContents["spriteSheetExport"], true)
}
dlg:entry{
    id = "spriteSheetFileNameFormat",
    label = " File Name Format:",
    text = GetInitialValue(oldConfigFileContents["spriteSheetFileNameFormat"], "{spritename}-{layergroup}-{layername}"),
    visible = GetInitialValue(oldConfigFileContents["spriteSheetExport"], true)
}
dlg:combobox{
    id = "spriteSheetFileFormat",
    label = " File Format:",
    option = GetInitialValue(oldConfigFileContents["spriteSheetFileFormat"], "png"),
    options = {"png", "gif", "jpg"},
    visible = GetInitialValue(oldConfigFileContents["spriteSheetExport"], true)
}
dlg:check{
    id = "spriteSheetTrim",
    label = " SpriteSheet Trim:",
    selected = GetInitialValue(oldConfigFileContents["spriteSheetTrim"], true),
    visible = GetInitialValue(oldConfigFileContents["spriteSheetExport"], true)
}
dlg:separator{
    id = "separator3",
    text = "Spine Settings"
}
dlg:check{
    id = "spineExport",
    label = "Export SpineSheet:",
    selected = GetInitialValue(oldConfigFileContents["spineExport"], true),
    onclick = function()
        dlg:modify{
            id = "spineSetRootPostion",
            visible = dlg.data.spineExport
        }
        dlg:modify{
            id = "spineRootPostionMethod",
            visible = dlg.data.spineExport and dlg.data.spineSetRootPostion
        }
        dlg:modify{
            id = "spineRootPostionX",
            visible = dlg.data.spineExport and dlg.data.spineSetRootPostion and dlg.data.spineRootPostionMethod == "manual"
        }
        dlg:modify{
            id = "spineRootPostionY",
            visible = dlg.data.spineExport and dlg.data.spineSetRootPostion and dlg.data.spineRootPostionMethod == "manual"
        }
        dlg:modify{
            id = "spineSetImagesPath",
            visible = dlg.data.spineExport
        }
        dlg:modify{
            id = "spineImagesPath",
            visible = dlg.data.spineExport and dlg.data.spineSetImagesPath
        }
        dlg:modify{
            id = "spineGroupsAsSkins",
            visible = dlg.data.spineExport
        }
        dlg:modify{
            id = "spineSkinNameFormat",
            visible = dlg.data.spineExport and dlg.data.spineGroupsAsSkins
        }
        dlg:modify{
            id = "spineSeparateSlotSkin",
            visible = dlg.data.spineExport and dlg.data.spineGroupsAsSkins
        }
        dlg:modify{
            id = "spineSlotNameFormat",
            visible = dlg.data.spineExport and dlg.data.spineGroupsAsSkins and dlg.data.spineSeparateSlotSkin
        }
        dlg:modify{
            id = "spineSkinAttachmentFormat",
            visible = dlg.data.spineExport and dlg.data.spineGroupsAsSkins and dlg.data.spineSeparateSlotSkin
        }
        dlg:modify{
            id = "spineLayerNameSeparator",
            visible = dlg.data.spineExport and dlg.data.spineGroupsAsSkins and dlg.data.spineSeparateSlotSkin
        }
    end
}
dlg:check{
    id = "spineSetRootPostion",
    label = " Set Root Position:",
    selected = GetInitialValue(oldConfigFileContents["spineSetRootPostion"], true),
    visible = GetInitialValue(oldConfigFileContents["spineExport"], true),
    onclick = function()
        dlg:modify{
            id = "spineRootPostionMethod",
            visible = dlg.data.spineSetRootPostion
        }
        dlg:modify{
            id = "spineRootPostionX",
            visible = dlg.data.spineSetRootPostion and dlg.data.spineRootPostionMethod == "manual"
        }
        dlg:modify{
            id = "spineRootPostionY",
            visible = dlg.data.spineSetRootPostion and dlg.data.spineRootPostionMethod == "manual"
        }
    end
}
dlg:combobox{
    id = "spineRootPostionMethod",
    label = "  Root position Method:",
    option = GetInitialValue(oldConfigFileContents["spineRootPostionMethod"], "automatic"),
    options = {"manual", "automatic", "center"},
    visible = GetInitialValue(oldConfigFileContents["spineExport"], true) and GetInitialValue(oldConfigFileContents["spineSetRootPostion"], true),
    onchange = function()
        dlg:modify{
            id = "spineRootPostionX",
            visible = dlg.data.spineRootPostionMethod == "manual"
        }
        dlg:modify{
            id = "spineRootPostionY",
            visible = dlg.data.spineRootPostionMethod == "manual"
        }
    end
}
dlg:number{
    id = "spineRootPostionX",
    label = "   Root Postion X:",
    text = GetInitialValue(oldConfigFileContents["spineRootPostionX"], "0"),
    visible = GetInitialValue(oldConfigFileContents["spineExport"], true) and GetInitialValue(oldConfigFileContents["spineSetRootPostion"], true) and GetInitialValue(oldConfigFileContents["spineRootPostionMethod"], "automatic") == "manual",
    decimals = 0
}
dlg:number{
    id = "spineRootPostionY",
    label = "   Root Postion Y:",
    text = GetInitialValue(oldConfigFileContents["spineRootPostionY"], "0"),
    visible = GetInitialValue(oldConfigFileContents["spineExport"], true) and GetInitialValue(oldConfigFileContents["spineSetRootPostion"], true) and GetInitialValue(oldConfigFileContents["spineRootPostionMethod"], "automatic") == "manual",
    decimals = 0
}
dlg:check{
    id = "spineSetImagesPath",
    label = " Set Images Path:",
    selected = GetInitialValue(oldConfigFileContents["spineSetImagesPath"], true),
    visible = GetInitialValue(oldConfigFileContents["spineExport"], true),
    onclick = function()
        dlg:modify{
            id = "spineImagesPath",
            visible = dlg.data.spineSetImagesPath
        }
    end
}
dlg:entry{
    id = "spineImagesPath",
    label = "  Images Path:",
    text = GetInitialValue(oldConfigFileContents["spineImagesPath"], "images"),
    visible = GetInitialValue(oldConfigFileContents["spineExport"], true) and GetInitialValue(oldConfigFileContents["spineSetImagesPath"], true)
}
dlg:check{
    id = "spineGroupsAsSkins",
    label = " Groups As Skins:",
    selected = GetInitialValue(oldConfigFileContents["spineGroupsAsSkins"], true),
    onclick = function()
        dlg:modify{
            id = "spineSkinNameFormat",
            visible = dlg.data.spineGroupsAsSkins
        }
        dlg:modify{
            id = "spineSeparateSlotSkin",
            visible = dlg.data.spineGroupsAsSkins
        }
        dlg:modify{
            id = "spineSlotNameFormat",
            visible = dlg.data.spineGroupsAsSkins and dlg.data.spineSeparateSlotSkin
        }
        dlg:modify{
            id = "spineSkinAttachmentFormat",
            visible = dlg.data.spineGroupsAsSkins and dlg.data.spineSeparateSlotSkin
        }
        dlg:modify{
            id = "spineLayerNameSeparator",
            visible = dlg.data.spineGroupsAsSkins and dlg.data.spineSeparateSlotSkin
        }
    end
}
dlg:entry{
    id = "spineSkinNameFormat",
    label = "  Skin Name Format:",
    text = GetInitialValue(oldConfigFileContents["spineSkinNameFormat"], "weapon-{layergroup}"),
    visible = GetInitialValue(oldConfigFileContents["spineGroupsAsSkins"], true)
}
dlg:check{
    id = "spineSeparateSlotSkin",
    label = "  Separate Slot/Skin:",
    selected = GetInitialValue(oldConfigFileContents["spineSeparateSlotSkin"], true),
    visible = GetInitialValue(oldConfigFileContents["spineGroupsAsSkins"], true),
    onclick = function()
        dlg:modify{
            id = "spineSlotNameFormat",
            visible = dlg.data.spineSeparateSlotSkin
        }
        dlg:modify{
            id = "spineSkinAttachmentFormat",
            visible = dlg.data.spineSeparateSlotSkin
        }
        dlg:modify{
            id = "spineLayerNameSeparator",
            visible = dlg.data.spineSeparateSlotSkin
        }
    end
}
dlg:entry{
    id = "spineSlotNameFormat",
    label = "   Slot Name Format:",
    text = GetInitialValue(oldConfigFileContents["spineSlotNameFormat"], "{layernameprefix}"),
    visible = GetInitialValue(oldConfigFileContents["spineGroupsAsSkins"], true) and GetInitialValue(oldConfigFileContents["spineSeparateSlotSkin"], true)
}
dlg:entry{
    id = "spineSkinAttachmentFormat",
    label = "   Skin Attachment Format:",
    text = GetInitialValue(oldConfigFileContents["spineSkinAttachmentFormat"], "{layernameprefix}-{layernamesuffix}"),
    visible = GetInitialValue(oldConfigFileContents["spineGroupsAsSkins"], true) and GetInitialValue(oldConfigFileContents["spineSeparateSlotSkin"], true)
}
dlg:entry{
    id = "spineLayerNameSeparator",
    label = "   Layer Name Separator:",
    text = GetInitialValue(oldConfigFileContents["spineLayerNameSeparator"], "-"),
    visible = GetInitialValue(oldConfigFileContents["spineGroupsAsSkins"], true) and GetInitialValue(oldConfigFileContents["spineSeparateSlotSkin"], true)
}
dlg:separator{
    id = "separator4"
}
dlg:entry{
    id = "help",
    label = "Need help? Visit my GitHub repository @",
    text = "https://github.com/RampantDespair/Aseprite-Exporter"
}
dlg:separator{
    id = "separator5"
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
            id = "spriteSheetExport",
            selected = true
        }
        dlg:modify{
            id = "spriteSheetNameTrim",
            selected = true,
            visible = true
        }
        dlg:modify{
            id = "spriteSheetFileNameFormat",
            text = "{spritename}-{layergroup}-{layername}",
            visible = true
        }
        dlg:modify{
            id = "spriteSheetFileFormat",
            option = "png",
            visible = true
        }
        dlg:modify{
            id = "spriteSheetTrim",
            selected = true,
            visible = true
        }
        dlg:modify{
            id = "spineExport",
            selected = true
        }
        dlg:modify{
            id = "spineSetRootPostion",
            selected = true,
            visible = true
        }
        dlg:modify{
            id = "spineRootPostionMethod",
            option = "automatic",
            visible = true
        }
        dlg:modify{
            id = "spineRootPostionX",
            text = "0",
            visible = false
        }
        dlg:modify{
            id = "spineRootPostionY",
            text = "0",
            visible = false
        }
        dlg:modify{
            id = "spineSetImagesPath",
            selected = true,
            visible = true
        }
        dlg:modify{
            id = "spineImagesPath",
            text = "images",
            visible = true
        }
        dlg:modify{
            id = "spineGroupsAsSkins",
            selected = true
        }
        dlg:modify{
            id = "spineSkinNameFormat",
            text = "weapon-{layergroup}",
            visible = true
        }
        dlg:modify{
            id = "spineSeparateSlotSkin",
            selected = true,
            visible = true
        }
        dlg:modify{
            id = "spineSlotNameFormat",
            text = "{layernameprefix}",
            visible = true
        }
        dlg:modify{
            id = "spineSkinAttachmentFormat",
            text = "{layernameprefix}-{layernamesuffix}",
            visible = true
        }
        dlg:modify{
            id = "spineLayerNameSeparator",
            text = "-",
            visible = true
        }
    end
}
dlg:show()

configFile = io.open(configPath, "w")

local newConfigFileContents = {}

newConfigFileContents["outputSubdirectory"] = dlg.data.outputSubdirectory
newConfigFileContents["spriteSheetExport"] = dlg.data.spriteSheetExport
newConfigFileContents["spriteSheetNameTrim"] = dlg.data.spriteSheetNameTrim
newConfigFileContents["spriteSheetFileNameFormat"] = dlg.data.spriteSheetFileNameFormat
newConfigFileContents["spriteSheetFileFormat"] = dlg.data.spriteSheetFileFormat
newConfigFileContents["spriteSheetTrim"] = dlg.data.spriteSheetTrim
newConfigFileContents["spineExport"] = dlg.data.spineExport
newConfigFileContents["spineSetRootPostion"] = dlg.data.spineSetRootPostion
newConfigFileContents["spineRootPostionMethod"] = dlg.data.spineRootPostionMethod
newConfigFileContents["spineRootPostionX"] = dlg.data.spineRootPostionX
newConfigFileContents["spineRootPostionY"] = dlg.data.spineRootPostionY
newConfigFileContents["spineSetImagesPath"] = dlg.data.spineSetImagesPath
newConfigFileContents["spineImagesPath"] = dlg.data.spineImagesPath
newConfigFileContents["spineGroupsAsSkins"] = dlg.data.spineGroupsAsSkins
newConfigFileContents["spineSkinNameFormat"] = dlg.data.spineSkinNameFormat
newConfigFileContents["spineSeparateSlotSkin"] = dlg.data.spineSeparateSlotSkin
newConfigFileContents["spineSlotNameFormat"] = dlg.data.spineSlotNameFormat
newConfigFileContents["spineSkinAttachmentFormat"] = dlg.data.spineSkinAttachmentFormat
newConfigFileContents["spineLayerNameSeparator"] = dlg.data.spineLayerNameSeparator

local newConfigFileContentsKeys = {}
for key, _ in pairs(newConfigFileContents) do
    table.insert(newConfigFileContentsKeys, key)
end
table.sort(newConfigFileContentsKeys)

if configFile ~= nil then
    for _, value in ipairs(newConfigFileContentsKeys) do
        configFile:write(value .. "=" .. tostring(newConfigFileContents[value]) .. "\n")
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

if dlg.data.spriteSheetNameTrim then
    local _index = string.find(fileName, "_")
    if _index ~= nil then
        fileName = string.sub(fileName, _index + 1, string.len(fileName))
    end
end

local fileNameTemplate = dlg.data.spriteSheetFileNameFormat:gsub("{spritename}", fileName)

if fileNameTemplate == nil then
    app.alert("No file name was specified, script aborted.")
    return
end

RootPositon = GetRootPosition(activeSprite, activeSprite, fileName, fileNameTemplate, dlg.data)
app.alert("RootPosition is x:" .. RootPositon.x .. " y:" .. RootPositon.y)

local layerVisibilityData = GetLayerVisibilityData(activeSprite)

HideLayers(activeSprite)
Export(activeSprite, activeSprite, fileName, fileNameTemplate, dlg.data)
RestoreLayers(activeSprite, layerVisibilityData)

app.alert("Exported " .. LayerCount .. " layers to " .. dlg.data.outputPath)

return
