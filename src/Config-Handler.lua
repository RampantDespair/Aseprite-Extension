-- INSTANCE DECLARATION
local configHandler = {}

-- FIELDS

-- FUNCTIONS
function configHandler.ArrayContainsValue(table, targetValue)
    for _, value in ipairs(table) do
        if value == targetValue then
            return true
        end
    end
    return false
end

function configHandler.ArrayContainsKey(table, targetKey)
    for key, _ in pairs(table) do
        if key == targetKey then
            return true
        end
    end
    return false
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
    for _, value in pairs(Config) do
        if value.value == nil then
            value.value = value.default
        else
            if value.value == "true" then
                value.value = true
            elseif value.value == "false" then
                value.value = false
            elseif value.value == "nil" then
                value.value = nil
            end
        end
        if type(value.value) ~= type(value.default) then
            value.value = value.default
        end
    end
end

function configHandler.InitializeConfigKeys()
    for key, value in pairs(Config) do
        table.insert(ConfigKeys, { key = key, order = value.order })
    end

    table.sort(ConfigKeys, function (a, b) return a.order < b.order end)
end

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
            if type(Config[value.key].value) ~= "string" then
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

function configHandler.UpdateDialog(configKey, newValue)
    if Config[configKey].type == "check" or Config[configKey].type == "radio" then
        Dlg:modify {
            id = configKey,
            selected = newValue,
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

function configHandler.ResetConfig(activeSprite, extraDialogModifications)
    for _, value in ipairs(ConfigKeys) do
        configHandler.UpdateDialog(value.key, Config[value.key].default)
    end

    extraDialogModifications(activeSprite)
end

-- INSTANCE RETURN
return configHandler
