-- INSTANCE DECLARATION
local configHandler = {}

-- FIELDS

-- FUNCTIONS
---@return boolean
---@param table table
---@param targetValue any
function configHandler.ArrayContainsValue(table, targetValue)
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

---@return boolean
---@param table table
---@param targetKey any
function configHandler.ArrayContainsKey(table, targetKey)
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

---@return integer
---@param table table
---@param targetValue any
function configHandler.ArrayGetValueIndex(table, targetValue)
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
---@return table
---@param input string
---@param seperator string
function configHandler.SplitString(input, seperator)
    if seperator == nil then
        return {}
    end
    local values = {}
    for value in string.gmatch(input, "([^" .. seperator .. "]+)") do
        table.insert(values, value)
    end
    return values
end

function configHandler.InitializeConfig()
    local configFile
    if Config.configSelect.value == nil then
        configFile = io.open(ConfigPathGlobal, "r")
        configHandler.PopulateConfig(configFile)

        if configFile ~= nil then
            io.close(configFile)
        end
    end

    if Config.configSelect.value == "local" then
        configFile = io.open(ConfigPathLocal, "r")
    else
        configFile = io.open(ConfigPathGlobal, "r")
    end
    configHandler.PopulateConfig(configFile)

    if configFile ~= nil then
        io.close(configFile)
    end
end

---@param configFile file*?
function configHandler.PopulateConfig(configFile)
    if configFile ~= nil then
        for line in configFile:lines() do
            local index = string.find(line, "=")
            if index ~= nil then
                local key = string.sub(line, 1, index - 1)
                local value = string.sub(line, index + 1, string.len(line))
                if Config[key] ~= nil then
                    Config[key].value = value;
                end
            end
        end
    end
    for _, entry in pairs(Config) do
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
                local values = configHandler.SplitString(entry.value, ";")
                if #values == 4 then
                    entry.value = Color{ 
                        r=tonumber(values[1]) or 0,
                        g=tonumber(values[2]) or 0,
                        b=tonumber(values[3]) or 0,
                        a=tonumber(values[4]) or 0
                    }
                end
            end
        end
        if type(entry.default) ~= "userdata" and type(entry.value) ~= type(entry.default) or (#entry.defaults ~= 0 and not configHandler.ArrayContainsValue(entry.defaults, entry.value)) then
            entry.value = entry.default
        end
    end
end

function configHandler.InitializeConfigKeys()
    for key, value in pairs(Config) do
        table.insert(ConfigKeys, { key = key, order = value.order })
    end

    table.sort(ConfigKeys, function (a, b) return a.order < b.order end)
end

---@param activeSprite Sprite
---@param newValue any
---@param extraDialogModifications fun(activeSprite: Sprite)
function configHandler.UpdateConfigFile(activeSprite, newValue, extraDialogModifications)
    configHandler.WriteConfig()
    configHandler.UpdateConfigValue("configSelect", newValue)
    configHandler.InitializeConfig()

    for _, value in ipairs(ConfigKeys) do
        configHandler.UpdateDialog(value.key, Config[value.key].value)
    end

    extraDialogModifications(activeSprite)
end

function configHandler.UpdateConfigValue(configKey, newValue)
    Config[configKey].value = newValue
    configHandler.UpdateChildrenVisibility(configKey, newValue)
end

---@param configKey string
---@param visibility boolean
function configHandler.UpdateChildrenVisibility(configKey, visibility)
    for _, value in pairs(Config[configKey].children) do
        local parent = Config[value].parent
        while parent ~= nil do
            visibility = visibility and Config[parent].value
            parent = Config[parent].parent
        end
        if Config[value].condition ~= nil then
            visibility = visibility and Config[configKey].value == Config[value].condition
        end
        Dlg:modify {
            id = value,
            visible = visibility,
        }
        if #Config[value].children ~= 0 then
            configHandler.UpdateChildrenVisibility(value, visibility and Config[value].value)
        end
    end
end

function configHandler.WriteConfig()
    local configFile
    if Config.configSelect.value == "local" then
        configFile = io.open(ConfigPathLocal, "w")
    else
        configFile = io.open(ConfigPathGlobal, "w")
    end

    if configFile ~= nil then
        for _, value in ipairs(ConfigKeys) do
            if Config[value.key].type == "color" then
                configFile:write(value.key .. "=" .. tostring(Config[value.key].value.red).. ";" .. tostring(Config[value.key].value.green).. ";" .. tostring(Config[value.key].value.blue).. ";" .. tostring(Config[value.key].value.alpha).. ";" .. "\n")
            elseif type(Config[value.key].value) ~= "string" then
                configFile:write(value.key .. "=" .. tostring(Config[value.key].value) .. "\n")
            else
                configFile:write(value.key .. "=" .. Config[value.key].value .. "\n")
            end
        end
    end

    if configFile ~= nil then
        io.close(configFile)
    end
end

---@param configKey string
---@param newValue any
function configHandler.UpdateDialog(configKey, newValue)
    if Config[configKey].type == "check" or Config[configKey].type == "radio" then
        Dlg:modify {
            id = configKey,
            selected = newValue,
        }
    elseif Config[configKey].type == "color" then
        Dlg:modify {
            id = configKey,
            color = newValue,
        }
    elseif Config[configKey].type == "combobox" then
        Dlg:modify {
            id = configKey,
            option = newValue,
        }
    elseif Config[configKey].type == "entry" or Config[configKey].type == "number" then
        Dlg:modify {
            id = configKey,
            text = newValue,
        }
    elseif Config[configKey].type == "slider" then
        Dlg:modify {
            id = configKey,
            value = newValue,
        }
    else
        app.alert("Unknown config entry type (" .. tostring(Config[configKey].type) .. ") for config key (" .. tostring(configKey) .. ")")
    end
    configHandler.UpdateConfigValue(configKey, newValue)
end

---@param activeSprite Sprite
---@param extraDialogModifications fun(activeSprite: Sprite)
function configHandler.ResetConfig(activeSprite, extraDialogModifications)
    for _, value in ipairs(ConfigKeys) do
        configHandler.UpdateDialog(value.key, Config[value.key].default)
    end

    extraDialogModifications(activeSprite)
end

-- INSTANCE RETURN
return configHandler
