-- CLASS DEFINITION
---@class (exact) LayerHandler
---@field __index LayerHandler
---@field _init fun(self: LayerHandler)
---@field GetLayerVisibilityData fun(self: LayerHandler, activeSprite: Sprite | Layer): table
---@field HideLayers fun(self: LayerHandler, activeSprite: Sprite | Layer)
---@field RestoreLayers fun(self: LayerHandler, activeSprite: Sprite | Layer, layerVisibilityData: table)
local LayerHandler = {}
LayerHandler.__index = LayerHandler
setmetatable(LayerHandler, {
    __call = function(cls, ...)
        local self = setmetatable({}, cls)
        self:_init(...)
        return self
    end,
})

-- INITIALIZER
function LayerHandler:_init()

end

-- FUNCTIONS
function LayerHandler:GetLayerVisibilityData(activeSprite)
    local layerVisibilityData = {}
    for i, layer in ipairs(activeSprite.layers) do
        if layer.isGroup then
            layerVisibilityData[i] = self:GetLayerVisibilityData(layer)
        else
            layerVisibilityData[i] = layer.isVisible
            layer.isVisible = false
        end
    end
    return layerVisibilityData
end

function LayerHandler:HideLayers(activeSprite)
    for _, layer in ipairs(activeSprite.layers) do
        if layer.isGroup then
            self:HideLayers(layer)
        else
            layer.isVisible = false
        end
    end
end

function LayerHandler:RestoreLayers(activeSprite, layerVisibilityData)
    for i, layer in ipairs(activeSprite.layers) do
        if layer.isGroup then
            self:RestoreLayers(layer, layerVisibilityData[i])
        else
            layer.isVisible = layerVisibilityData[i]
        end
    end
end

-- CLASS RETURN
return LayerHandler
