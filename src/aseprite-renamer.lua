local ConfigHandler = require("handler-config")
local LayerHandler = require("handler-layer")
local AsepriteBase = require("aseprite-base")

-- CLASS DEFINITION
---@class (exact) AsepriteRenamer: AsepriteBase
---@field __index AsepriteBase
---@field _init fun(self: AsepriteBase)
---@field Rename fun(self: AsepriteRenamer, activeSprite: Sprite)
local AsepriteRenamer = {}
AsepriteRenamer.__index = AsepriteRenamer
setmetatable(AsepriteRenamer, {
    __index = AsepriteBase,
    __call = function(cls, ...)
        local self = setmetatable({}, cls)
        self:_init(...)
        return self
    end,
})

-- INITIALIZER
function AsepriteRenamer:_init()
    ---@type table<string, ConfigEntry>
    local config = {
        renameMatch = {
            order = 100,
            type = "entry",
            default = "this",
            defaults = {},
            value = nil,
            parent = nil,
            children = {},
            condition = nil,
        },
        renameReplace = {
            order = 101,
            type = "entry",
            default = "that",
            defaults = {},
            value = nil,
            parent = nil,
            children = {},
            condition = nil,
        },
        renamePrefix = {
            order = 102,
            type = "entry",
            default = "prefix",
            defaults = {},
            value = nil,
            parent = nil,
            children = {},
            condition = nil,
        },
        renameSuffix = {
            order = 103,
            type = "entry",
            default = "suffix",
            defaults = {},
            value = nil,
            parent = nil,
            children = {},
            condition = nil,
        },
    }

    local activeSprite = app.sprite
    local configHandler = ConfigHandler(config, activeSprite)
    local layerHandler = LayerHandler()

    AsepriteBase._init(self, activeSprite, configHandler, layerHandler)
end

-- FUNCTIONS
function AsepriteRenamer:Rename(activeSprite)
    for _, layer in ipairs(activeSprite.layers) do
        layer.name = self.configHandler.config.renamePrefix.value .. string.gsub(layer.name, self.configHandler.config.renameMatch.value, self.configHandler.config.renameReplace.value) .. self.configHandler.config.renameSuffix.value
        self.layerCount = self.layerCount + 1
    end
end

function AsepriteRenamer:BuildDialogSpecialized()
    self.configHandler.dialog:tab {
        id = "renameSettings",
        text = "Rename Settings",
    }
    self.configHandler.dialog:entry {
        id = "renameMatch",
        label = "Match:",
        text = self.configHandler.config.renameMatch.value,
        onchange = function()
            self.configHandler:UpdateConfigValue("renameMatch", self.configHandler.dialog.data.renameMatch)
            self:ExtraDialogModifications(self.activeSprite)
        end,
    }
    self.configHandler.dialog:entry {
        id = "renameReplace",
        label = "Replace:",
        text = self.configHandler.config.renameReplace.value,
        onchange = function()
            self.configHandler:UpdateConfigValue("renameReplace", self.configHandler.dialog.data.renameReplace)
            self:ExtraDialogModifications(self.activeSprite)
        end,
    }
    self.configHandler.dialog:entry {
        id = "renamePrefix",
        label = "Prefix:",
        text = self.configHandler.config.renamePrefix.value,
        onchange = function()
            self.configHandler:UpdateConfigValue("renamePrefix", self.configHandler.dialog.data.renamePrefix)
            self:ExtraDialogModifications(self.activeSprite)
        end,
    }
    self.configHandler.dialog:entry {
        id = "renameSuffix",
        label = "Suffix:",
        text = self.configHandler.config.renameSuffix.value,
        onchange = function()
            self.configHandler:UpdateConfigValue("renameSuffix", self.configHandler.dialog.data.renameSuffix)
            self:ExtraDialogModifications(self.activeSprite)
        end,
    }
    self.configHandler.dialog:label {
        id = "renamePreview",
        label = "Preview:",
        text = self.configHandler.config.renameMatch.value .. " -> " .. self.configHandler.config.renamePrefix.value .. self.configHandler.config.renameReplace.value .. self.configHandler.config.renameSuffix.value,
    }
end

function AsepriteRenamer:ExtraDialogModifications(activeSprite)
    self.configHandler.dialog:modify {
        id = "renamePreview",
        text = self.configHandler.config.renameMatch.value .. " -> " .. self.configHandler.config.renamePrefix.value .. self.configHandler.config.renameReplace.value .. self.configHandler.config.renameSuffix.value,
    }
end

function AsepriteRenamer:Execute()
    self:BuildDialog()
    self.configHandler.dialog:show()

    self.configHandler:WriteConfig()

    if self.configHandler.dialog.data.cancel then
        return
    end

    if not self.configHandler.dialog.data.confirm then
        app.alert("Settings were not confirmed, script aborted.")
        return
    end

    app.transaction("Renamer", function() self:Rename(self.activeSprite) end)

    app.alert("Renamed " .. self.layerCount .. " layers")
end

-- CLASS RETURN
return AsepriteRenamer
