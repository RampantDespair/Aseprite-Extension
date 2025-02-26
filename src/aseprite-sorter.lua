local ConfigHandler = require("handler-config")
local LayerHandler = require("handler-layer")
local AsepriteBase = require("aseprite-base")

-- CLASS DEFINITION
---@class (exact) AsepriteSorter: AsepriteBase
---@field __index AsepriteBase
---@field _init fun(self: AsepriteBase)
---@field Sort fun(self: AsepriteSorter, activeSprite: Sprite | Layer)
local AsepriteSorter = {}
AsepriteSorter.__index = AsepriteSorter
setmetatable(AsepriteSorter, {
    __index = AsepriteBase,
    __call = function(cls, ...)
        local self = setmetatable({}, cls)
        self:_init(...)
        return self
    end,
})

-- INITIALIZER
function AsepriteSorter:_init()
    ---@type table<string, ConfigEntry>
    local config = {
        sortMethod = {
            order = 100,
            type = "combobox",
            default = "ascending",
            defaults = { "ascending", "descending" },
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
function AsepriteSorter:Sort(activeSprite)
    local layerNames = {}
    for _, layer in ipairs(activeSprite.layers) do
        table.insert(layerNames, layer.name)
        if layer.isGroup == true then
            self:Sort(layer)
        end
    end

    if self.configHandler.config.sortMethod.value == "ascending" then
        table.sort(layerNames, function(a, b) return a > b end)
    elseif self.configHandler.config.sortMethod.value == "descending" then
        table.sort(layerNames, function(a, b) return a < b end)
    else
        app.alert("Invalid sortMethod value (" .. tostring(self.configHandler.config.sortMethod.value) .. ")")
        return
    end

    for i = 1, #activeSprite.layers, 1 do
        while activeSprite.layers[i].name ~= layerNames[i] do
            activeSprite.layers[i].stackIndex = #activeSprite.layers
        end
        self.layerCount = self.layerCount + 1
    end
end

function AsepriteSorter:BuildDialog(activeSprite)
    self.configHandler.dialog:tab {
        id = "configSettings",
        text = "Config Settings",
    }
    self.configHandler.dialog:combobox {
        id = "configSelect",
        label = "Current Config:",
        option = self.configHandler.config.configSelect.value,
        options = self.configHandler.config.configSelect.defaults,
        onchange = function() self.configHandler:UpdateConfigFile(activeSprite, self.configHandler.dialog.data.configSelect, self.ExtraDialogModifications) end,
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

    self.configHandler.dialog:tab {
        id = "sortSettings",
        text = "Sort Settings",
    }
    self.configHandler.dialog:combobox {
        id = "sortMethod",
        label = "Sort Method:",
        option = self.configHandler.config.sortMethod.value,
        options = self.configHandler.config.sortMethod.defaults,
        onchange = function() self.configHandler:UpdateConfigValue("sortMethod", self.configHandler.dialog.data.sortMethod) end,
    }

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
        onclick = function() self.configHandler:ResetConfig(activeSprite, self.ExtraDialogModifications) end,
    }
end

function AsepriteSorter:ExtraDialogModifications(activeSprite)

end

function AsepriteSorter:Execute()
    self:BuildDialog(self.activeSprite)

    self.configHandler.dialog:show()
    self.configHandler:WriteConfig()

    if self.configHandler.dialog.data.cancel then
        return
    end

    if not self.configHandler.dialog.data.confirm then
        app.alert("Settings were not confirmed, script aborted.")
        return
    end

    app.transaction("Sorter", function() self:Sort(self.activeSprite) end)

    app.alert("Sorted " .. self.layerCount .. " layers")
end

-- CLASS RETURN
return AsepriteSorter
