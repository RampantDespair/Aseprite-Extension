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

    json:write('{')
    json:write(string.format([[ "skeleton": { "images": "%s" }, ]], dlgData.outputSubPath .. "/"))
    json:write([[ "bones": [ { "name": "root" }	], ]])

    slotsJson = {}
    skinsJson = {}
    slotsIndex = 1
    skinsIndex = 1
end

function exportSpineJsonParse(activeSprite, layer, fileNameTemplate, dlgData)
    local name = layer.name
    local cel = layer.cels[1]

    local targetSlot = string.format([[ { "name": "%s", "bone": "%s", "attachment": "%s" } ]], name, "root", name)

    if arrayContains(slotsJson, targetSlot) == false then
        slotsJson[slotsIndex] = targetSlot
        slotsIndex = slotsIndex + 1
    end

    if dlgData.groupsAsSkins == true then 
        local fileNameTemplate = fileNameTemplate:gsub("\\", "/")
        local attachmentName = dlgData.skinAttachmentFormat:gsub("{layergroup}", layer.parent.name)
        skinsJson[skinsIndex] = string.format([[ { "name": "%s", "attachments": { "%s": { "%s": { "name": "%s", "x": %.2f, "y": %.2f, "width": 1, "height": 1 } } } } ]], attachmentName, name, name, fileNameTemplate, cel.bounds.width/2 + cel.position.x - activeSprite.bounds.width/2, activeSprite.bounds.height - cel.position.y - cel.bounds.height/2)
    else
        skinsJson[skinsIndex] = string.format([[ "%s": { "%s": { "x": %.2f, "y": %.2f, "width": 1, "height": 1 } } ]], name, name, cel.bounds.width/2 + cel.position.x - activeSprite.bounds.width/2, activeSprite.bounds.height - cel.position.y - cel.bounds.height/2)
    end

    skinsIndex = skinsIndex + 1
end

function exportSpineJsonEnd(dlgData)
    json:write('"slots": [')
    json:write(table.concat(slotsJson, ","))
    json:write("],")

    if dlgData.groupsAsSkins == true then 
        json:write('"skins": [')
        json:write(table.concat(skinsJson, ","))
        json:write(']')
    else 
        json:write('"skins": {')
        json:write('"default": {')
        json:write(table.concat(skinsJson, ","))
        json:write('}')
        json:write('}')
    end

    json:write("}")

    json:close()
end

function arrayContains(table, targetValue)
    for i, value in ipairs(table) do
        if value == targetValue then
            return true
        end
    end
    return false
end

-- EXECUTION
layerCount = 0
local activeSprite = app.activeSprite

if (activeSprite == nil) then
    app.alert("Please click the sprite you'd like to export")
    return
elseif (activeSprite.filename == "") then
    app.alert("Please save the current sprite before running this script")
    return
end

local dlg = Dialog("Aseprite-Exporter")
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
dlg:label{
    id = "spacer1",
    label = " ",
    text = " "
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
dlg:slider{
    id = "exportFileScale", 
    label = " SpriteSheet Scale:", 
    min = 1, 
    max = 10, 
    value = 1
}
dlg:check{
    id = "exportSpriteSheetTrim",
    label = " SpriteSheet Trim:",
    selected = true
}
dlg:label{
    id = "spacer2",
    label = " ",
    text = " "
}
dlg:check{
    id = "exportSpineSheet",
    label = "Export SpineSheet:",
    selected = true
}
dlg:label{
    id = "spacer3",
    label = " ",
    text = " "
}
dlg:check{
    id = "groupsAsSkins",
    label = "Groups As Skins:",
    selected = true,
    onclick = function()
        dlg:modify{
            id = "skinAttachmentFormat",
            visible = dlg.data.groupsAsSkins
        }
    end
}
dlg:entry{
    id = "skinAttachmentFormat",
    label = "Skin Attachment Format:",
    text = "weapon-{layergroup}"
}
dlg:label{
    id = "spacer4",
    label = " ",
    text = " "
}

dlg:button{id = "confirm", text = "Confirm"}
dlg:button{id = "cancel", text = "Cancel"}
dlg:show()

if not dlg.data.confirm then 
    app.alert("Settings were not confirmed, script aborted.")
    return 0 
end

if dlg.data.outputPath == nil then
    app.alert("No output directory was specified, script aborted.")
    return 0
end

local fileName = app.fs.fileTitle(activeSprite.filename)
local fileNameTemplate = dlg.data.exportFileNameFormat .. "." .. dlg.data.exportFileFormat
fileNameTemplate = fileNameTemplate:gsub("{spritename}", fileName)

if fileNameTemplate == nil then
    app.alert("No file name was specified, script aborted.")
    return 0
end

local layerVisibilityData = getLayerVisibilityData(activeSprite)

hideLayers(activeSprite)
export(activeSprite, activeSprite, fileName, fileNameTemplate, dlg.data)
restoreLayers(activeSprite, layerVisibilityData)

app.alert("Exported " .. layerCount .. " layers to " .. dlg.data.outputPath)

return 0
