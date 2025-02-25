-- INSTANCE DECLARATION
local asepriteSorter = {}

-- FUNCTIONS
---@param activeSprite Sprite | Layer
function asepriteSorter.Sort(activeSprite)
    local layerNames = {}
    for _, layer in ipairs(activeSprite.layers) do
        table.insert(layerNames, layer.name)
        if layer.isGroup == true then
            asepriteSorter.Sort(layer)
        end
    end

    if Config.sortMethod.value == "ascending" then
        table.sort(layerNames, function(a, b) return a > b end)
    elseif Config.sortMethod.value == "descending" then
        table.sort(layerNames, function(a, b) return a < b end)
    else
        app.alert("Invalid sortMethod value (" .. tostring(Config.sortMethod.value) .. ")")
        return
    end

    for i = 1, #activeSprite.layers, 1 do
        while activeSprite.layers[i].name ~= layerNames[i] do
            activeSprite.layers[i].stackIndex = #activeSprite.layers
        end
        LayerCount = LayerCount + 1
    end
end

---@param activeSprite Sprite
function asepriteSorter.BuildDialog(activeSprite)
    Dlg:tab {
        id = "configSettings",
        text = "Config Settings",
    }
    Dlg:combobox {
        id = "configSelect",
        label = "Current Config:",
        option = Config.configSelect.value,
        options = Config.configSelect.defaults,
        onchange = function() ConfigHandler.UpdateConfigFile(activeSprite, Dlg.data.configSelect, asepriteSorter.ExtraDialogModifications) end,
    }
    Dlg:label {
        id = "globalConfigPath",
        label = "Global Config Path: ",
        text = ConfigPathGlobal,
    }
    Dlg:label {
        id = "localConfigPath",
        label = "Local Config Path: ",
        text = ConfigPathLocal,
    }

    Dlg:tab {
        id = "sortSettings",
        text = "Sort Settings",
    }
    Dlg:combobox {
        id = "sortMethod",
        label = "Sort Method:",
        option = Config.sortMethod.value,
        options = Config.sortMethod.defaults,
        onchange = function() ConfigHandler.UpdateConfigValue("sortMethod", Dlg.data.sortMethod) end,
    }

    Dlg:endtabs {}

    Dlg:entry {
        id = "help",
        label = "Need help? Visit my GitHub repository @",
        text = "https://github.com/RampantDespair/Aseprite-Extension",
    }
    Dlg:separator {
        id = "helpSeparator",
    }

    Dlg:button {
        id = "confirm",
        text = "Confirm",
    }
    Dlg:button {
        id = "cancel",
        text = "Cancel",
    }
    Dlg:button {
        id = "reset",
        text = "Reset",
        onclick = function() ConfigHandler.ResetConfig(activeSprite, asepriteSorter.ExtraDialogModifications) end,
    }
end

---@param activeSprite Sprite
function asepriteSorter.ExtraDialogModifications(activeSprite)

end

function asepriteSorter.Execute()
    if ConfigHandler == nil then
        app.alert("Failed to get ConfigHandler.")
        return
    end

    if LayerHandler == nil then
        app.alert("Failed to get LayerHandler.")
        return
    end

    local activeSprite = app.sprite

    if activeSprite == nil then
        app.alert("No sprite selected, script aborted.")
        return
    end

    local scriptPath = debug.getinfo(1).source
    scriptPath = string.sub(scriptPath, 2, string.len(scriptPath))
    scriptPath = app.fs.normalizePath(scriptPath)

    local scriptName = app.fs.fileTitle(scriptPath)
    local scriptDirectory = string.match(scriptPath, "(.*[/\\])")

    local spritePath = app.fs.filePath(activeSprite.filename)

    ConfigPathLocal = app.fs.joinPath(spritePath, scriptName .. ".conf")
    ConfigPathGlobal = app.fs.joinPath(scriptDirectory, scriptName .. ".conf")

    Dlg = Dialog(scriptName)

    ConfigHandler.InitializeConfig()
    ConfigHandler.InitializeConfigKeys()

    asepriteSorter.BuildDialog(activeSprite)

    Dlg:show()

    ConfigHandler.WriteConfig()

    if Dlg.data.cancel then
        return
    end

    if not Dlg.data.confirm then
        app.alert("Settings were not confirmed, script aborted.")
        return
    end

    app.transaction("Sorter", function() asepriteSorter.Sort(activeSprite) end)

    app.alert("Sorted " .. LayerCount .. " layers")
end

function asepriteSorter.Initialize(configHandler, layerHandler)
    ConfigHandler = configHandler
    LayerHandler = layerHandler

    -- FIELDS
    ---@type table<string, ConfigEntry>
    Config = {
        configSelect = {
            order = 100,
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
        },
        sortMethod = {
            order = 200,
            type = "combobox",
            default = "ascending",
            defaults = { "ascending", "descending" },
            value = nil,
            parent = nil,
            children = {},
            condition = nil,
        },
    }
    LayerCount = 0
    ConfigKeys = {}
    ConfigPathLocal = ""
    ConfigPathGlobal = ""
    Dlg = Dialog("X")
end

-- INSTANCE RETURN
return asepriteSorter
