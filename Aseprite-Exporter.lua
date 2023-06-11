-- FUNCTIONS
function getLayerVisibilityData(activeSprite)
    local layerVisibilityData = {}
    for i, layer in ipairs(activeSprite.layers) do
        if layer.isGroup then
            layerVisibilityData[i] = getLayerVisibilityData(layer)
         else
            layerVisibilityData[i] = layer.isVisible
            layer.isVisible = false
         end
    end
    return layerVisibilityData
end

function hideLayers(activeSprite)
    for i, layer in ipairs(activeSprite.layers) do
        if (layer.isGroup) then
            hideLayers(layer)
        else
            layer.isVisible = false
        end
    end
end

function restoreLayers(activeSprite, layerVisibilityData)
    for i, layer in ipairs(activeSprite.layers) do
        if layer.isGroup then
            restoreLayers(layer, layerVisibilityData[i])
        else
           layer.isVisible = layerVisibilityData[i]
        end
     end
end

function export(activeSprite, rootLayer, fileName, fileNameTemplate, dlgData)
    if dlgData.exportSpineSheet == true then
        exportSpineJsonStart(fileName, dlgData)
    end

    exportSpriteLayers(activeSprite, rootLayer, fileName, fileNameTemplate, dlgData)
    
    if dlgData.exportSpineSheet == true then
        exportSpineJsonEnd(dlgData)
    end
end

function exportSpriteLayers(activeSprite, rootLayer, fileName, fileNameTemplate, dlgData)
    for i, layer in ipairs(rootLayer.layers) do
        local fileNameTemplate = fileNameTemplate
        local outputPath = dlgData.outputPath
        if layer.isGroup then
            local previousVisibility = layer.isVisible
            layer.isVisible = true

            if dlgData.groupsAsSkins == true then
                fileNameTemplate = app.fs.joinPath(layer.name, fileNameTemplate)
            end

            exportSpriteLayers(activeSprite, layer, fileName, fileNameTemplate, dlgData)

            layer.isVisible = previousVisibility
        else
            layer.isVisible = true

            fileNameTemplate = fileNameTemplate:gsub("{layergroup}", layer.parent.name)
            fileNameTemplate = fileNameTemplate:gsub("{layername}", layer.name)

            if dlgData.exportSpriteSheet then
                exportSpriteSheet(activeSprite, layer, fileNameTemplate, dlgData)
            end

            layer.isVisible = false

            if dlgData.exportSpineSheet == true then
                exportSpineJsonParse(activeSprite, layer, fileNameTemplate, dlgData)
            end

            layerCount = layerCount + 1
        end
    end
end

function exportSpriteSheet(activeSprite, layer, fileNameTemplate, dlgData)
    local cel = layer.cels[1]
    local currentLayer = Sprite(activeSprite)
    if dlgData.exportSpriteSheetTrim then
        currentLayer:crop(cel.position.x, cel.position.y, cel.bounds.width, cel.bounds.height)
    end

    currentLayer:saveCopyAs(app.fs.joinPath(dlgData.outputPath, fileNameTemplate))
    currentLayer:close()
end

function exportSpineJsonStart(fileName, dlgData)
    local jsonFileName = app.fs.joinPath(app.fs.filePath(dlgData.outputFile), fileName .. ".json")
    os.execute("mkdir " .. dlgData.outputPath)
    json = io.open(jsonFileName, "w")

    json:write('{ ')
    json:write('"skeleton": { ')
    json:write(string.format([["images": "%s" }, ]], dlgData.outputSubPath .. "/"))
    json:write('"bones": [ { ')
    json:write('"name": "root" ')
    json:write('} ')
    json:write('], ')

    slotsJson = {}
    skinsJson = {}
end

function exportSpineJsonParse(activeSprite, layer, fileNameTemplate, dlgData)
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
        local fileNameTemplate = fileNameTemplate:gsub("\\", "/")
        local skinName = dlgData.skinNameFormat:gsub("{layergroup}", layer.parent.name)

        if arrayContainsKey(skinsJson, skinName) == false then
            skinsJson[skinName] = {}
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

        skinsJson[skinName][#skinsJson[skinName] + 1] = string.format([["%s": { "%s": { "name": "%s", "x": %.2f, "y": %.2f, "width": %d, "height": %d } } ]], slotName, skinAttachmentName, fileNameTemplate, spriteX, spriteY, layerCelWidth, layerCelHeight)
    else
        skinsJson[#skinsJson + 1] = string.format([["%s": { "%s": { "x": %.2f, "y": %.2f, "width": %d, "height": %d } } ]], layerName, fileNameTemplate, spriteX, spriteY, layerCelWidth, layerCelHeight)
    end

    if arrayContainsValue(slotsJson, slot) == false then
        slotsJson[#slotsJson + 1] = slot
    end
end

function exportSpineJsonEnd(dlgData)
    json:write('"slots": [ ')
    json:write(table.concat(slotsJson, ", "))
    json:write("], ")

    if dlgData.groupsAsSkins == true then 
        json:write('"skins": [ ')

        local parsedSkins = {}
        for key, value in pairs(skinsJson) do
            parsedSkins[#parsedSkins + 1] = string.format([[{ "name": "%s", "attachments": { ]], key) .. table.concat(value, ", ") .. "} }"
        end

        json:write(table.concat(parsedSkins, ", "))
        json:write('] ')
    else 
        json:write('"skins": { ')
        json:write('"default": { ')
        json:write(table.concat(skinsJson, ", "))
        json:write('} ')
        json:write('} ')
    end

    json:write("}")

    json:close()
end

function arrayContainsValue(table, targetValue)
    for i, value in ipairs(table) do
        if value == targetValue then
            return true, i
        end
    end
    return false
end

function arrayContainsKey(table, targetKey)
    for key, value in pairs(table) do
        if key == targetKey then
            return true, i
        end
    end
    return false
end

-- EXECUTION
layerCount = 0
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
            text = app.fs.joinPath(app.fs.filePath(dlg.data.outputFile), dlg.data.outputSubPath)
        }
    end
}
dlg:entry{
    id = "outputSubPath",
    label = "Output SubPath:",
    text = "sprite",
    onchange = function()
        dlg:modify{
            id = "outputPath",
            text = app.fs.joinPath(app.fs.filePath(dlg.data.outputFile), dlg.data.outputSubPath)
        }
    end
}
dlg:label{
    id = "outputPath",
    label = "Output Path:",
    text = app.fs.joinPath(app.fs.filePath(dlg.data.outputFile), dlg.data.outputSubPath)
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
local fileNameTemplate = dlg.data.exportFileNameFormat .. "." .. dlg.data.exportFileFormat
fileNameTemplate = fileNameTemplate:gsub("{spritename}", fileName)

if fileNameTemplate == nil then
    app.alert("No file name was specified, script aborted.")
    return
end

local layerVisibilityData = getLayerVisibilityData(activeSprite)

hideLayers(activeSprite)
export(activeSprite, activeSprite, fileName, fileNameTemplate, dlg.data)
restoreLayers(activeSprite, layerVisibilityData)

app.alert("Exported " .. layerCount .. " layers to " .. dlg.data.outputPath)

return
