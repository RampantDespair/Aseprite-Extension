local layerHandler = {}

function layerHandler.GetLayerVisibilityData(activeSprite)
    local layerVisibilityData = {}
    for i, layer in ipairs(activeSprite.layers) do
        if layer.isGroup then
            layerVisibilityData[i] = layerHandler.GetLayerVisibilityData(layer)
        else
            layerVisibilityData[i] = layer.isVisible
            layer.isVisible = false
        end
    end
    return layerVisibilityData
end

function layerHandler.HideLayers(activeSprite)
    for _, layer in ipairs(activeSprite.layers) do
        if layer.isGroup then
            layerHandler.HideLayers(layer)
        else
            layer.isVisible = false
        end
    end
end

function layerHandler.RestoreLayers(activeSprite, layerVisibilityData)
    for i, layer in ipairs(activeSprite.layers) do
        if layer.isGroup then
            layerHandler.RestoreLayers(layer, layerVisibilityData[i])
        else
           layer.isVisible = layerVisibilityData[i]
        end
     end
end

return layerHandler
