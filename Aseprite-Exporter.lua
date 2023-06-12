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

    ExportSpriteLayers(activeSprite, rootLayer, fileName, fileNameTemplate, dlgData)

    if dlgData.exportSpineSheet == true then
        ExportSpineJsonEnd(dlgData)
    end
end

function ExportSpriteLayers(activeSprite, rootLayer, fileName, fileNameTemplate, dlgData)
    for _, layer in ipairs(rootLayer.layers) do
        local _fileNameTemplate = fileNameTemplate
        local layerName = layer.name

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
    Json:write(string.format([["images": "%s", ]], "./" .. dlgData.imagesPath .. "/"))
    Json:write(string.format([["audio": "%s" ]], "./" .. dlgData.audioPath .. "/"))
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

    local spriteX = realPostionX - dlgData.rootPositionX
    local spriteY = dlgData.rootPositionY - realPositionY

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
        end
    else
        SkinsJson[#SkinsJson + 1] = string.format([["%s": { "%s": { "x": %.2f, "y": %.2f, "width": %d, "height": %d } } ]], layerName, fileNameTemplate, spriteX, spriteY, layerCelWidth, layerCelHeight)
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
        Json:write(table.concat(SkinsJson, ", "))
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

-- EXECUTION
LayerCount = 0
local activeSprite = app.activeSprite

if (activeSprite == nil) then
    app.alert("No sprite selected, script aborted.")
    return
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
            text = app.fs.joinPath(app.fs.filePath(dlg.data.outputFile), dlg.data.imagesPath)
        }
    end
}
dlg:entry{
    id = "imagesPath",
    label = "Images Path:",
    text = "sprite",
    onchange = function()
        dlg:modify{
            id = "outputPath",
            text = app.fs.joinPath(app.fs.filePath(dlg.data.outputFile), dlg.data.imagesPath)
        }
    end
}
dlg:entry{
    id = "audioPath",
    label = "Audio Path:",
    text = "sound"
}
dlg:label{
    id = "outputPath",
    label = "Output Path:",
    text = app.fs.joinPath(app.fs.filePath(dlg.data.outputFile), dlg.data.imagesPath)
}
dlg:separator{
    id = "separator2",
    text = "SpriteSheet Settings"
}
dlg:check{
    id = "exportSpriteSheet",
    label = "Export SpriteSheet:",
    selected = true,
    onclick = function()
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
dlg:entry{
    id = "exportFileNameFormat",
    label = " File Name Format:",
    text = "{spritename}-{layergroup}-{layername}"
}
dlg:combobox{
    id = "exportFileFormat",
    label = " File Format:",
    option = "png",
    options = {"png", "gif", "jpg"}
}
dlg:check{
    id = "exportSpriteSheetTrim",
    label = " SpriteSheet Trim:",
    selected = true
}
dlg:separator{
    id = "separator3",
    text = "Spine Settings"
}
dlg:check{
    id = "exportSpineSheet",
    label = "Export SpineSheet:",
    selected = true
}
dlg:check{
    id = "setRootPostion",
    label = "Set Root position",
    selected = true,
    onclick = function()
        dlg:modify{
            id = "rootPositionX",
            visible = dlg.data.setRootPostion
        }
        dlg:modify{
            id = "rootPositionY",
            visible = dlg.data.setRootPostion
        }
    end
}
dlg:number{
    id = "rootPositionX",
    label = " Root Postion X:",
    text = "0",
    decimals = 0
}
dlg:number{
    id = "rootPositionY",
    label = " Root Postion Y:",
    text = "0",
    decimals = 0
}
dlg:separator{
    id = "separator4",
    text = "Group Settings"
}
dlg:check{
    id = "groupsAsSkins",
    label = "Groups As Skins:",
    selected = true,
    onclick = function()
        dlg:modify{
            id = "skinNameFormat",
            visible = dlg.data.groupsAsSkins
        }
        dlg:modify{
            id = "slotNameFormat",
            visible = dlg.data.groupsAsSkins
        }
        dlg:modify{
            id = "skinAttachmentFormat",
            visible = dlg.data.groupsAsSkins
        }
        dlg:modify{
            id = "layerNameSeparator",
            visible = dlg.data.groupsAsSkins
        }
    end
}
dlg:entry{
    id = "skinNameFormat",
    label = " Skin Name Format:",
    text = "weapon-{layergroup}"
}
dlg:check{
    id = "separateSlotSkin",
    label = " Separate Slot/Skin:",
    selected = true,
    onclick = function()
        dlg:modify{
            id = "slotNameFormat",
            visible = dlg.data.groupsAsSkins
        }
        dlg:modify{
            id = "skinAttachmentFormat",
            visible = dlg.data.groupsAsSkins
        }
        dlg:modify{
            id = "layerNameSeparator",
            visible = dlg.data.groupsAsSkins
        }
    end
}
dlg:entry{
    id = "slotNameFormat",
    label = "  Slot Name Format:",
    text = "{layernameprefix}"
}
dlg:entry{
    id = "skinAttachmentFormat",
    label = "  Skin Attachment Format:",
    text = "{layernameprefix}-{layernamesuffix}"
}
dlg:entry{
    id = "layerNameSeparator",
    label = "  Layer Name Separator:",
    text = "-"
}
dlg:separator{
    id = "separator5"
}

dlg:button{id = "confirm", text = "Confirm"}
dlg:button{id = "cancel", text = "Cancel"}
dlg:show()

if not dlg.data.confirm then 
    app.alert("Settings were not confirmed, script aborted.")
    return
end

if dlg.data.outputPath == nil then
    app.alert("No output directory was specified, script aborted.")
    return
end

local fileName = app.fs.fileTitle(activeSprite.filename)
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
