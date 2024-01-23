-- INSTANCE DECLARATION
local asepriteRenamer = {}

-- FIELDS
LayerCount = 0
ConfigHandler = nil
LayerHandler = nil
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
    renameMatch = {
        order = 200,
        type = "entry",
        default = "this",
        defaults = nil,
        value = nil,
        parent = nil,
        children = {},
        condition = nil,
    },
    renameReplace = {
        order = 201,
        type = "entry",
        default = "that",
        defaults = nil,
        value = nil,
        parent = nil,
        children = {},
        condition = nil,
    },
    renamePrefix = {
        order = 202,
        type = "entry",
        default = "prefix",
        defaults = nil,
        value = nil,
        parent = nil,
        children = {},
        condition = nil,
    },
    renameSuffix = {
        order = 203,
        type = "entry",
        default = "suffix",
        defaults = nil,
        value = nil,
        parent = nil,
        children = {},
        condition = nil,
    },
}
ConfigKeys = {}
ConfigPathLocal = ""
ConfigPathGlobal = ""
Dlg = Dialog("X")

-- FUNCTIONS
---@param activeSprite Sprite
function asepriteRenamer.Rename(activeSprite)
    for _, layer in ipairs(activeSprite.layers) do
        layer.name = Config.renamePrefix.value .. string.gsub(layer.name, Config.renameMatch.value, Config.renameReplace.value) .. Config.renameSuffix.value
    end
end

---@param activeSprite Sprite
function asepriteRenamer.BuildDialog(activeSprite)
    Dlg:tab {
        id = "configSettings",
        text = "Config Settings",
    }
    Dlg:combobox {
        id = "configSelect",
        label = "Current Config:",
        option = Config.configSelect.value,
        options = Config.configSelect.defaults,
        onchange = function() ConfigHandler.UpdateConfigFile(activeSprite, Dlg.data.configSelect, asepriteRenamer.ExtraDialogModifications) end,
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
        id = "renameSettings",
        text = "Rename Settings",
    }
    Dlg:entry {
        id = "renameMatch",
        label = "Match:",
        text = Config.renameMatch.value,
        onchange = function()
            ConfigHandler.UpdateConfigValue("renameMatch", Dlg.data.renameMatch)
            asepriteRenamer.ExtraDialogModifications(activeSprite)
        end,
    }
    Dlg:entry {
        id = "renameReplace",
        label = "Replace:",
        text = Config.renameReplace.value,
        onchange = function()
            ConfigHandler.UpdateConfigValue("renameReplace", Dlg.data.renameReplace)
            asepriteRenamer.ExtraDialogModifications(activeSprite)
        end,
    }
    Dlg:entry {
        id = "renamePrefix",
        label = "Prefix:",
        text = Config.renamePrefix.value,
        onchange = function()
            ConfigHandler.UpdateConfigValue("renamePrefix", Dlg.data.renamePrefix)
            asepriteRenamer.ExtraDialogModifications(activeSprite)
        end,
    }
    Dlg:entry {
        id = "renameSuffix",
        label = "Suffix:",
        text = Config.renameSuffix.value,
        onchange = function()
            ConfigHandler.UpdateConfigValue("renameSuffix", Dlg.data.renameSuffix)
            asepriteRenamer.ExtraDialogModifications(activeSprite)
        end,
    }
    Dlg:label {
        id = "renamePreview",
        label = "Preview:",
        text = Config.renameMatch.value .. " -> " .. Config.renamePrefix.value .. Config.renameReplace.value .. Config.renameSuffix.value,
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
        onclick = function() ConfigHandler.ResetConfig(activeSprite, asepriteRenamer.ExtraDialogModifications) end,
    }
end

---@param activeSprite Sprite
function asepriteRenamer.ExtraDialogModifications(activeSprite)
    Dlg:modify {
        id = "renamePreview",
        text = Config.renameMatch.value .. " -> " .. Config.renamePrefix.value .. Config.renameReplace.value .. Config.renameSuffix.value,
    }
end

function asepriteRenamer.Execute()
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

    asepriteRenamer.BuildDialog(activeSprite)

    Dlg:show()

    ConfigHandler.WriteConfig()

    if Dlg.data.cancel then
        return
    end

    if not Dlg.data.confirm then
        app.alert("Settings were not confirmed, script aborted.")
        return
    end

    asepriteRenamer.Rename(activeSprite)
end

function asepriteRenamer.Initialize(configHandler, layerHandler)
    ConfigHandler = configHandler
    LayerHandler = layerHandler
end

-- INSTANCE RETURN
return asepriteRenamer
