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
---@field BuildDialog fun(self: AsepriteBase)
---@field BuildDialogSpecialized fun(self: AsepriteBase)
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

-- FUNCTIONS
function AsepriteBase:BuildDialog()
    self.configHandler.dialog:tab {
        id = "configSettings",
        text = "Config Settings",
    }
    self.configHandler.dialog:combobox {
        id = "configSelect",
        label = "Current Config:",
        option = self.configHandler.config.configSelect.value,
        options = self.configHandler.config.configSelect.defaults,
        onchange = function() self.configHandler:UpdateConfigFile(self.activeSprite, self.configHandler.dialog.data.configSelect, self.ExtraDialogModifications) end,
    }
    self.configHandler.dialog:label {
        id = "globalConfigPath",
        label = "Global Config Path: ",
        text = self.configHandler.configPathGlobal,
    }
    self.configHandler.dialog:label {
        id = "localConfigPath",
        label = "Local Config Path: ",
        text = self.configHandler.configPathLocal,
    }

    self:BuildDialogSpecialized()

    self.configHandler.dialog:endtabs {}

    self.configHandler.dialog:entry {
        id = "help",
        label = "Need help? Visit my GitHub repository @",
        text = "https://github.com/RampantDespair/Aseprite-Extension",
    }
    self.configHandler.dialog:separator {
        id = "helpSeparator",
    }

    self.configHandler.dialog:button {
        id = "confirm",
        text = "Confirm",
    }
    self.configHandler.dialog:button {
        id = "cancel",
        text = "Cancel",
    }
    self.configHandler.dialog:button {
        id = "reset",
        text = "Reset",
        onclick = function() self.configHandler:ResetConfig(self.activeSprite, self.ExtraDialogModifications) end,
    }

    self.configHandler.dialog:show()
end

-- CLASS RETURN
return AsepriteBase
