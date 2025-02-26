-- CLASS DEFINITION
---@class (exact) ConfigHandler
---@field __index ConfigHandler
---@field config table<string, ConfigEntry>
---@field configKeys table
---@field configPathGlobal string
---@field configPathLocal string
---@field dialog Dialog
---@field _init fun(self: ConfigHandler, config: table<string, ConfigEntry>, scriptPath:string, activeSprite: Sprite)
---@field ArrayContainsValue fun(self: ConfigHandler, table: table, targetValue: any): boolean
---@field ArrayContainsKey fun(self: ConfigHandler, table: table, targetKey: any): boolean
---@field ArrayGetValueIndex fun(self: ConfigHandler, table: table, targetValue: any): integer
---@field SplitString fun(self: ConfigHandler, input: string, seperator: string): table
---@field InitializeConfig fun(self: ConfigHandler)
---@field PopulateConfig fun(self: ConfigHandler, configFile: file*?)
---@field InitializeConfigKeys fun(self: ConfigHandler)
---@field UpdateConfigFile fun(self: ConfigHandler, activeSprite: Sprite, newValue: any, extraDialogModifications: fun(activeSprite: Sprite))
---@field UpdateConfigValue fun(self: ConfigHandler, configKey: string, newValue: any)
---@field UpdateChildrenVisibility fun(self: ConfigHandler, configKey: string, visibility: boolean | string)
---@field WriteConfig fun(self: ConfigHandler)
---@field UpdateDialog fun(self: ConfigHandler, configKey: string, newValue: any)
---@field ResetConfig fun(self: ConfigHandler, activeSprite: Sprite, extraDialogModifications: fun() | fun(activeSprite: Sprite))
local ConfigHandler = {}
ConfigHandler.__index = ConfigHandler
setmetatable(ConfigHandler, {
    __call = function(cls, ...)
        local self = setmetatable({}, cls)
        self:_init(...)
        return self
    end,
})

---@class (exact) ConfigEntry
---@field order integer
---@field type "check" | "color" | "combobox" | "entry" | "number" | "radio" | "slider"
---@field default any
---@field defaults string[]
---@field value any
---@field parent string | nil
---@field children string[]
---@field condition string | nil
local ConfigEntry = {}

-- INITIALIZER
function ConfigHandler:_init(config, scriptPath, activeSprite)
    self.config = config
    self.config["configSelect"] = {
        order = 1,
        type = "combobox",
        default = "global",
        defaults = {
            "global",
            "local",
        },
        value = nil,
        parent = nil,
        children = {},
        condition = nil,
    }
    self.configKeys = {}

    scriptPath = string.sub(scriptPath, 2, string.len(scriptPath))
    scriptPath = app.fs.normalizePath(scriptPath)

    local scriptName = app.fs.fileTitle(scriptPath)
    local scriptDirectory = string.match(scriptPath, "(.*[/\\])")

    local spritePath = app.fs.filePath(activeSprite.filename)

    self.configPathLocal = app.fs.joinPath(spritePath, scriptName .. ".conf")
    self.configPathGlobal = app.fs.joinPath(scriptDirectory, scriptName .. ".conf")

    self:InitializeConfig()
    self:InitializeConfigKeys()

    self.dialog = Dialog("X")
end

-- FUNCTIONS
function ConfigHandler:ArrayContainsValue(table, targetValue)
    if table == nil then
        return false
    end
    for _, value in ipairs(table) do
        if value == targetValue then
            return true
        end
    end
    return false
end

function ConfigHandler:ArrayContainsKey(table, targetKey)
    if table == nil then
        return false
    end
    for key, _ in pairs(table) do
        if key == targetKey then
            return true
        end
    end
    return false
end

function ConfigHandler:ArrayGetValueIndex(table, targetValue)
    if table == nil then
        return -1
    end
    for index, value in ipairs(table) do
        if value == targetValue then
            return index
        end
    end
    return -1
end

---https://stackoverflow.com/questions/1426954/split-string-in-lua
function ConfigHandler:SplitString(input, seperator)
    if seperator == nil then
        return {}
    end
    local values = {}
    for value in string.gmatch(input, "([^" .. seperator .. "]+)") do
        table.insert(values, value)
    end
    return values
end

function ConfigHandler:InitializeConfig()
    local configFile
    if self.config.configSelect.value == nil then
        configFile = io.open(self.configPathGlobal, "r")
        self:PopulateConfig(configFile)

        if configFile ~= nil then
            io.close(configFile)
        end
    end

    if self.config.configSelect.value == "local" then
        configFile = io.open(self.configPathLocal, "r")
    else
        configFile = io.open(self.configPathGlobal, "r")
    end
    self:PopulateConfig(configFile)

    if configFile ~= nil then
        io.close(configFile)
    end
end

function ConfigHandler:PopulateConfig(configFile)
    if configFile ~= nil then
        for line in configFile:lines() do
            local index = string.find(line, "=")
            if index ~= nil then
                local key = string.sub(line, 1, index - 1)
                local value = string.sub(line, index + 1, string.len(line))
                if self.config[key] ~= nil then
                    self.config[key].value = value;
                end
            end
        end
    end
    for _, entry in pairs(self.config) do
        if entry.value == nil then
            entry.value = entry.default
        else
            if entry.value == "true" then
                entry.value = true
            elseif entry.value == "false" then
                entry.value = false
            elseif entry.value == "nil" then
                entry.value = nil
            end

            if entry.type == "color" then
                local values = self:SplitString(entry.value, ";")
                if #values == 4 then
                    entry.value = Color {
                        r = tonumber(values[1]) or 0,
                        g = tonumber(values[2]) or 0,
                        b = tonumber(values[3]) or 0,
                        a = tonumber(values[4]) or 0
                    }
                end
            end
        end
        if type(entry.default) ~= "userdata" and type(entry.value) ~= type(entry.default) or (#entry.defaults ~= 0 and not self:ArrayContainsValue(entry.defaults, entry.value)) then
            entry.value = entry.default
        end
    end
end

function ConfigHandler:InitializeConfigKeys()
    for key, value in pairs(self.config) do
        table.insert(self.configKeys, { key = key, order = value.order })
    end

    table.sort(self.configKeys, function(a, b) return a.order < b.order end)
end

function ConfigHandler:UpdateConfigFile(activeSprite, newValue, extraDialogModifications)
    self:WriteConfig()
    self:UpdateConfigValue("configSelect", newValue)
    self:InitializeConfig()

    for _, value in ipairs(self.configKeys) do
        self:UpdateDialog(value.key, self.config[value.key].value)
    end

    extraDialogModifications(activeSprite)
end

function ConfigHandler:UpdateConfigValue(configKey, newValue)
    self.config[configKey].value = newValue
    self:UpdateChildrenVisibility(configKey, newValue)
end

function ConfigHandler:UpdateChildrenVisibility(configKey, visibility)
    for _, value in pairs(self.config[configKey].children) do
        local visible = visibility
        if self.config[value] ~= nil and self.config[value].condition ~= nil then
            visible = visible and self.config[configKey].value == self.config[value].condition
        end
        self.dialog:modify {
            id = value,
            visible = (visible == true),
        }
        if self.config[value] ~= nil and #self.config[value].children ~= 0 then
            self:UpdateChildrenVisibility(value, visible and self.config[value].value)
        end
    end
end

function ConfigHandler:WriteConfig()
    local configFile
    if self.config.configSelect.value == "local" then
        configFile = io.open(self.configPathLocal, "w")
    else
        configFile = io.open(self.configPathGlobal, "w")
    end

    if configFile ~= nil then
        for _, value in ipairs(self.configKeys) do
            if self.config[value.key].type == "color" then
                configFile:write(value.key .. "=" .. tostring(self.config[value.key].value.red) .. ";" .. tostring(self.config[value.key].value.green) .. ";" .. tostring(self.config[value.key].value.blue) .. ";" .. tostring(self.config[value.key].value.alpha) .. ";" .. "\n")
            elseif type(self.config[value.key].value) ~= "string" then
                configFile:write(value.key .. "=" .. tostring(self.config[value.key].value) .. "\n")
            else
                configFile:write(value.key .. "=" .. self.config[value.key].value .. "\n")
            end
        end
    end

    if configFile ~= nil then
        io.close(configFile)
    end
end

function ConfigHandler:UpdateDialog(configKey, newValue)
    if self.config[configKey].type == "check" or self.config[configKey].type == "radio" then
        self.dialog:modify {
            id = configKey,
            selected = newValue,
        }
    elseif self.config[configKey].type == "color" then
        self.dialog:modify {
            id = configKey,
            color = newValue,
        }
    elseif self.config[configKey].type == "combobox" then
        self.dialog:modify {
            id = configKey,
            option = newValue,
        }
    elseif self.config[configKey].type == "entry" or self.config[configKey].type == "number" then
        self.dialog:modify {
            id = configKey,
            text = newValue,
        }
    elseif self.config[configKey].type == "slider" then
        self.dialog:modify {
            id = configKey,
            value = newValue,
        }
    else
        app.alert("Unknown config entry type (" .. tostring(self.config[configKey].type) .. ") for config key (" .. tostring(configKey) .. ")")
    end
    self:UpdateConfigValue(configKey, newValue)
end

function ConfigHandler:ResetConfig(activeSprite, extraDialogModifications)
    for _, value in ipairs(self.configKeys) do
        self:UpdateDialog(value.key, self.config[value.key].default)
    end

    extraDialogModifications(activeSprite)
end

-- CLASS RETURN
return ConfigHandler
