-- CLASS DEFINITION
---@class (exact) AsepriteBase
---@field __index AsepriteBase
---@field configHandler ConfigHandler
---@field layerHandler LayerHandler
---@field layerCount integer
---@field activeSprite Sprite
---@field _init fun(self: AsepriteBase, activeSprite: Sprite, configHandler: ConfigHandler, layerHandler: LayerHandler)
---@field Execute fun(self: AsepriteBase)
---@field ExtraDialogModifications fun(self: AsepriteBase, activeSprite: Sprite)
---@field BuildDialog fun(self: AsepriteBase, activeSprite: Sprite)
local AsepriteBase = {}
AsepriteBase.__index = AsepriteBase
setmetatable(AsepriteBase, {
    __call = function(cls, ...)
        local self = setmetatable({}, cls)
        self:_init(...)
        return self
    end,
})

-- INITIALIZER
function AsepriteBase:_init(activeSprite, configHandler, layerHandler)
    self.activeSprite = activeSprite
    self.configHandler = configHandler
    self.layerHandler = layerHandler
    self.layerCount = 0
end

-- CLASS RETURN
return AsepriteBase
