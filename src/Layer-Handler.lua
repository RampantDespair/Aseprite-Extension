-- INSTANCE DECLARATION
local layerHandler = {}

-- FIELDS

-- FUNCTIONS
---@param activeSprite Sprite | Layer
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

---@param activeSprite Sprite | Layer
function layerHandler.HideLayers(activeSprite)
    for _, layer in ipairs(activeSprite.layers) do
        if layer.isGroup then
            layerHandler.HideLayers(layer)
        else
            layer.isVisible = false
        end
    end
end

---@param activeSprite Sprite | Layer
---@param layerVisibilityData boolean
function layerHandler.RestoreLayers(activeSprite, layerVisibilityData)
    for i, layer in ipairs(activeSprite.layers) do
        if layer.isGroup then
            layerHandler.RestoreLayers(layer, layerVisibilityData[i])
        else
           layer.isVisible = layerVisibilityData[i]
        end
     end
end

-- INSTANCE RETURN
return layerHandler
