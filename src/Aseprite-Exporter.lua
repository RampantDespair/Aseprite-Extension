local asepriteExporter = {}

-- FUNCTIONS
function asepriteExporter.GetRootPosition(activeSprite)
    if Config.spineExport.value == true and Config.spineSetRootPostion.value == true then
        if Config.spineRootPostionMethod.value == "manual" then
            return { x = Config.spineRootPostionX.value, y = Config.spineRootPostionY.value }
        elseif Config.spineRootPostionMethod.value == "automatic" then
            for _, layer in ipairs(activeSprite.layers) do
                if layer.name == "root" then
                    return { x = layer.cels[1].position.x, y = layer.cels[1].position.y }
                end
            end
        elseif Config.spineRootPostionMethod.value == "center" then
            return { x = activeSprite.width / 2, y = activeSprite.height / 2 }
        end
    end
    return { x = 0, y = 0 }
end

function asepriteExporter.Export(activeSprite, rootLayer, fileName, fileNameTemplate)
    if Config.spineExport.value == true then
        asepriteExporter.ExportSpineJsonStart(fileName)
    end

    asepriteExporter.ExportSpriteLayers(activeSprite, rootLayer, fileName, fileNameTemplate)

    if Config.spineExport.value == true then
        asepriteExporter.ExportSpineJsonEnd()
    end
end

function asepriteExporter.ExportSpriteLayers(activeSprite, rootLayer, fileName, fileNameTemplate)
    for _, layer in ipairs(rootLayer.layers) do
        local _fileNameTemplate = fileNameTemplate
        local layerName = layer.name

        if layerName ~= "root" then
            if layer.isGroup then
                local previousVisibility = layer.isVisible
                layer.isVisible = true

                if Config.outputGroupsAsDirectories.value == true then
                    _fileNameTemplate = app.fs.joinPath(layerName, _fileNameTemplate)
                end

                asepriteExporter.ExportSpriteLayers(activeSprite, layer, fileName, _fileNameTemplate)

                layer.isVisible = previousVisibility
            else
                layer.isVisible = true

                local layerParentName
                if pcall(function () layerParentName = layer.parent.name end) then
                    _fileNameTemplate = string.gsub(_fileNameTemplate, "{layergroup}", layerParentName)
                else
                    _fileNameTemplate = string.gsub(_fileNameTemplate, "{layergroup}", "default")
                end

                _fileNameTemplate = string.gsub(_fileNameTemplate, "{layername}", layerName)

                if #layer.cels ~= 0 then
                    if Config.spriteSheetExport.value == true then
                        asepriteExporter.ExportSpriteSheet(activeSprite, layer, _fileNameTemplate)
                    end

                    if Config.spineExport.value == true then
                        asepriteExporter.ExportSpineJsonParse(layer, _fileNameTemplate)
                    end

                    LayerCount = LayerCount + 1
                end

                layer.isVisible = false
            end
        end
    end
end

function asepriteExporter.ExportSpriteSheet(activeSprite, layer, fileNameTemplate)
    local cel = layer.cels[1]
    local currentLayer = Sprite(activeSprite)

    if Config.spriteSheetTrim.value == true then
        currentLayer:crop(cel.position.x, cel.position.y, cel.bounds.width, cel.bounds.height)
    end

    currentLayer:saveCopyAs(app.fs.joinPath(Dlg.data.outputPath, fileNameTemplate .. "." .. Config.spriteSheetFileFormat.value))
    currentLayer:close()
end

function asepriteExporter.ExportSpineJsonStart(fileName)
    local jsonFileName = app.fs.joinPath(app.fs.filePath(Dlg.data.outputFile), fileName .. ".json")

    os.execute("mkdir " .. Dlg.data.outputPath)
    JsonFile = io.open(jsonFileName, "w")

    JsonFile:write('{ ')
    JsonFile:write('"skeleton": { ')

    if Config.spineSetImagesPath.value == true then
        JsonFile:write(string.format([["images": "%s" ]], "./" .. Config.spineImagesPath.value .. "/"))
    end

    JsonFile:write('}, ')
    JsonFile:write('"bones": [ { ')
    JsonFile:write('"name": "root" ')
    JsonFile:write('} ')
    JsonFile:write('], ')

    SlotsJson = {}
    SkinsJson = {}
end

function asepriteExporter.ExportSpineJsonParse(layer, fileNameTemplate)
    local layerName = layer.name

    local slotName
    if Config.spineSetStaticSlot.value == true then
        slotName = Config.spineStaticSlotName.value
    else
        slotName = layerName
    end

    local slot = string.format([[{ "name": "%s", "bone": "%s", "attachment": "%s" }]], slotName, "root", slotName)

    local layerCel = layer.cels[1]

    local layerCelPosition = layerCel.position
    local layerCelX = layerCelPosition.x
    local layerCelY = layerCelPosition.y

    local layerCelBounds = layerCel.bounds
    local layerCelWidth = layerCelBounds.width
    local layerCelHeight = layerCelBounds.height

    local realPostionX = layerCelX + layerCelWidth / 2
    local realPositionY = layerCelY + layerCelHeight / 2

    local spriteX
    local spriteY

    if Config.spineSetRootPostion.value == true then
        spriteX = realPostionX - RootPositon.x
        spriteY = RootPositon.y - realPositionY
    else
        spriteX = realPostionX
        spriteY = realPositionY
    end

    if Config.spineGroupsAsSkins.value == true then
        fileNameTemplate = string.gsub(fileNameTemplate, "\\", "/")
        local skinName
        if pcall(function () skinName = layer.parent.name end) then
            skinName = string.gsub(Config.spineSkinNameFormat.value, "{layergroup}", layer.parent.name)
        end

        if skinName ~= nil then
            if ConfigHandler.ArrayContainsKey(SkinsJson, skinName) == false then
                SkinsJson[skinName] = {}
            end

            local skinAttachmentName = layerName

            if Config.spineSeparateSlotSkin.value == true then
                local separatorPosition = string.find(layerName, Config.spineLayerNameSeparator.value)

                if separatorPosition then
                    local layerNamePrefix = string.sub(layerName, 1, separatorPosition - 1)
                    local layerNameSuffix = string.sub(layerName, separatorPosition + 1, #layerName)

                    slotName = Config.spineSlotNameFormat.value
                    if slotName ~= nil then
                        slotName = string.gsub(slotName, "{layernameprefix}", layerNamePrefix)
                        slotName = string.gsub(slotName, "{layernamesuffix}", layerNameSuffix)
                    end

                    skinAttachmentName = Config.spineSkinAttachmentFormat.value
                    if skinAttachmentName ~= nil then
                        skinAttachmentName = string.gsub(skinAttachmentName, "{layernameprefix}", layerNamePrefix)
                        skinAttachmentName = string.gsub(skinAttachmentName, "{layernamesuffix}", layerNameSuffix) 
                    end

                    if slotName == skinAttachmentName then
                        slot = string.format([[{ "name": "%s", "bone": "%s", "attachment": "%s" }]], slotName, "root", skinAttachmentName)
                    else
                        slot = string.format([[{ "name": "%s", "bone": "%s"}]], slotName, "root")
                    end
                end
            end

            SkinsJson[skinName][#SkinsJson[skinName] + 1] = string.format([["%s": { "%s": { "name": "%s", "x": %.2f, "y": %.2f, "width": %d, "height": %d } }]], slotName, skinAttachmentName, fileNameTemplate, spriteX, spriteY, layerCelWidth, layerCelHeight)
        else
            if ConfigHandler.ArrayContainsKey(SkinsJson, "default") == false then
                SkinsJson["default"] = {}
            end

            fileNameTemplate = string.gsub(fileNameTemplate, "{layergroup}", "default")
            SkinsJson["default"][#SkinsJson["default"] + 1] = string.format([["%s": { "%s": { "x": %.2f, "y": %.2f, "width": %d, "height": %d } }]], slotName, fileNameTemplate, spriteX, spriteY, layerCelWidth, layerCelHeight)
        end
    else
        if ConfigHandler.ArrayContainsKey(SkinsJson, "default") == false then
            SkinsJson["default"] = {}
        end

        fileNameTemplate = string.gsub(fileNameTemplate, "{layergroup}", "default")
        SkinsJson["default"][#SkinsJson["default"] + 1] = string.format([["%s": { "%s": { "x": %.2f, "y": %.2f, "width": %d, "height": %d } }]], slotName, fileNameTemplate, spriteX, spriteY, layerCelWidth, layerCelHeight)
    end

    if ConfigHandler.ArrayContainsValue(SlotsJson, slot) == false then
        SlotsJson[#SlotsJson + 1] = slot
    end
end

function asepriteExporter.ExportSpineJsonEnd()
    JsonFile:write('"slots": [ ')
    JsonFile:write(table.concat(SlotsJson, ", "))
    JsonFile:write(" ], ")

    if Config.spineGroupsAsSkins.value == true then
        JsonFile:write('"skins": [ ')

        local parsedSkins = {}
        for key, value in pairs(SkinsJson) do
            parsedSkins[#parsedSkins + 1] = string.format([[{ "name": "%s", "attachments": { ]], key) .. table.concat(value, ", ") .. " } }"
        end

        JsonFile:write(table.concat(parsedSkins, ", "))
        JsonFile:write(' ], ')
    else
        JsonFile:write('"skins": { ')
        JsonFile:write('"default": { ')
        JsonFile:write(table.concat(SkinsJson["default"], ", "))
        JsonFile:write('} ')
        JsonFile:write('}, ')
    end

    JsonFile:write('"animations": { "animation": {} }')

    JsonFile:write("}")

    JsonFile:close()
end

function asepriteExporter.ExtraDialogModifications(activeSprite)
    Dlg:modify{
        id = "outputFile",
        filename = activeSprite.filename
    }
    Dlg:modify{
        id = "outputPath",
        text = app.fs.joinPath(app.fs.filePath(Dlg.data.outputFile), Dlg.data.outputSubdirectory)
    }
end

function asepriteExporter.Execute()
    LayerCount = 0
    local activeSprite = app.activeSprite

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

    Config = {
        configSelect = {
            order = 100,
            type = "combobox",
            default = "global",
            value = nil,
            parent = nil,
            children = {},
            condition = nil,
        },
        outputSubdirectory = {
            order = 200,
            type = "entry",
            default = "images",
            value = nil,
            parent = nil,
            children = {},
            condition = nil,
        },
        outputGroupsAsDirectories = {
            order = 201,
            type = "check",
            default = true,
            value = nil,
            parent = nil,
            children = {},
            condition = nil,
        },
        spriteSheetExport = {
            order = 300,
            type = "check",
            default = true,
            value = nil,
            parent = nil,
            children = {
                "spriteSheetNameTrim",
                "spriteSheetFileNameFormat",
                "spriteSheetFileFormat",
                "spriteSheetTrim",
            },
            condition = nil,
        },
        spriteSheetNameTrim = {
            order = 301,
            type = "check",
            default = true,
            value = nil,
            parent = "spriteSheetExport",
            children = {},
            condition = nil,
        },
        spriteSheetFileNameFormat = {
            order = 302,
            type = "entry",
            default = "{spritename}-{layergroup}-{layername}",
            value = nil,
            parent = "spriteSheetExport",
            children = {},
            condition = nil,
        },
        spriteSheetFileFormat = {
            order = 303,
            type = "combobox",
            default = "png",
            value = nil,
            parent = "spriteSheetExport",
            children = {},
            condition = nil,
        },
        spriteSheetTrim = {
            order = 304,
            type = "check",
            default = true,
            value = nil,
            parent = "spriteSheetExport",
            children = {},
            condition = nil,
        },
        spineExport = {
            order = 400,
            type = "check",
            default = true,
            value = nil,
            parent = nil,
            children = {
                "spineSetRootPostion",
                "spineSetImagesPath",
                "spineGroupsAsSkins",
                "spineSetStaticSlot",
            },
            condition = nil,
        },
        spineSetStaticSlot = {
            order = 401,
            type = "check",
            default = true,
            value = nil,
            parent = "spineExport",
            children = {
                "spineStaticSlotName",
            },
            condition = nil,
        },
        spineStaticSlotName = {
            order = 402,
            type = "entry",
            default = "slot",
            value = nil,
            parent = "spineSetStaticSlot",
            children = {},
            condition = nil,
        },
        spineSetRootPostion = {
            order = 403,
            type = "check",
            default = true,
            value = nil,
            parent = "spineExport",
            children = {
                "spineRootPostionMethod",
                "spineRootPostionX",
                "spineRootPostionY",
            },
            condition = nil,
        },
        spineRootPostionMethod = {
            order = 404,
            type = "combobox",
            default = "center",
            value = nil,
            parent = "spineSetRootPostion",
            children = {
                "spineRootPostionX",
                "spineRootPostionY",
            },
            condition = nil,
        },
        spineRootPostionX = {
            order = 405,
            type = "number",
            default = 0,
            value = nil,
            parent = "spineRootPostionMethod",
            children = {},
            condition = "manual",
        },
        spineRootPostionY = {
            order = 406,
            type = "number",
            default = 0,
            value = nil,
            parent = "spineRootPostionMethod",
            children = {},
            condition = "manual",
        },
        spineSetImagesPath = {
            order = 407,
            type = "check",
            default = true,
            value = nil,
            parent = "spineExport",
            children = {
                "spineImagesPath",
            },
            condition = nil,
        },
        spineImagesPath = {
            order = 408,
            type = "entry",
            default = "images",
            value = nil,
            parent = "spineSetImagesPath",
            children = {},
            condition = nil,
        },
        spineGroupsAsSkins = {
            order = 409,
            type = "check",
            default = true,
            value = nil,
            parent = "spineExport",
            children = {
                "spineSkinNameFormat",
                "spineSeparateSlotSkin",
            },
            condition = nil,
        },
        spineSkinNameFormat = {
            order = 410,
            type = "entry",
            default = "weapon-{layergroup}",
            value = nil,
            parent = "spineGroupsAsSkins",
            children = {},
            condition = nil,
        },
        spineSeparateSlotSkin = {
            order = 411,
            type = "check",
            default = true,
            value = nil,
            parent = "spineGroupsAsSkins",
            children = {
                "spineSlotNameFormat",
                "spineSkinAttachmentFormat",
                "spineLayerNameSeparator",
            },
            condition = nil,
        },
        spineSlotNameFormat = {
            order = 412,
            type = "entry",
            default = "{layernameprefix}",
            value = nil,
            parent = "spineSeparateSlotSkin",
            children = {},
            condition = nil,
        },
        spineSkinAttachmentFormat = {
            order = 413,
            type = "entry",
            default = "{layernameprefix}-{layernamesuffix}",
            value = nil,
            parent = "spineSeparateSlotSkin",
            children = {},
            condition = nil,
        },
        spineLayerNameSeparator = {
            order = 414,
            type = "entry",
            default = "-",
            value = nil,
            parent = "spineSeparateSlotSkin",
            children = {},
            condition = nil,
        },
    }

    ConfigKeys = {}

    Dlg = Dialog(scriptName)

    ConfigHandler.InitializeConfig()
    ConfigHandler.InitializeConfigKeys()

    do
        Dlg:tab {
            id = "configSettings",
            text = "Config Settings",
        }
        Dlg:combobox {
            id = "configSelect",
            label = "Current Config:",
            option = Config.configSelect.value,
            options = { "global", "local" },
            onchange = function() ConfigHandler.UpdateConfigFile(activeSprite, Dlg.data.configSelect, asepriteExporter.ExtraDialogModifications) end,
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
            id = "outputSettings",
            text = "Output Settings",
        }
        Dlg:file {
            id = "outputFile",
            label = "Output File:",
            filename = activeSprite.filename,
            open = false,
            onchange = function()
                Dlg:modify {
                    id = "outputPath",
                    text = app.fs.joinPath(app.fs.filePath(Dlg.data.outputFile), Dlg.data.outputSubdirectory)
                }
            end,
        }
        Dlg:entry {
            id = "outputSubdirectory",
            label = "Output Subdirectory:",
            text = Config.outputSubdirectory.value,
            onchange = function()
                Config.outputSubdirectory.value = Dlg.data.outputSubdirectory
                Dlg:modify {
                    id = "outputPath",
                    text = app.fs.joinPath(app.fs.filePath(Dlg.data.outputFile), Dlg.data.outputSubdirectory)
                }
            end,
        }
        Dlg:label {
            id = "outputPath",
            label = "Output Path:",
            text = app.fs.joinPath(app.fs.filePath(Dlg.data.outputFile), Dlg.data.outputSubdirectory),
        }
        Dlg:check {
            id = "outputGroupsAsDirectories",
            label = "Groups As Directories:",
            selected = Config.outputGroupsAsDirectories.value,
            onclick = function() ConfigHandler.UpdateConfigValue("outputGroupsAsDirectories", Dlg.data.outputGroupsAsDirectories) end,
        }

        Dlg:tab {
            id = "spriteSettingsTab",
            text = "Sprite Settings",
        }
        Dlg:check {
            id = "spriteSheetExport",
            label = "Export SpriteSheet:",
            selected = Config.spriteSheetExport.value,
            onclick = function() ConfigHandler.UpdateConfigValue("spriteSheetExport", Dlg.data.spriteSheetExport) end,
        }
        Dlg:check {
            id = "spriteSheetNameTrim",
            label = " Sprite Name Trim:",
            selected = Config.spriteSheetNameTrim.value,
            visible = Config.spriteSheetExport.value,
            onclick = function() ConfigHandler.UpdateConfigValue("spriteSheetNameTrim", Dlg.data.spriteSheetNameTrim) end,
        }
        Dlg:entry {
            id = "spriteSheetFileNameFormat",
            label = " File Name Format:",
            text = Config.spriteSheetFileNameFormat.value,
            visible = Config.spriteSheetExport.value,
            onchange = function() ConfigHandler.UpdateConfigValue("spriteSheetFileNameFormat", Dlg.data.spriteSheetFileNameFormat) end,
        }
        Dlg:combobox {
            id = "spriteSheetFileFormat",
            label = " File Format:",
            option = Config.spriteSheetFileFormat.value,
            options = { "png", "gif", "jpg" },
            onchange = function() ConfigHandler.UpdateConfigValue("spriteSheetFileFormat", Dlg.data.spriteSheetFileFormat) end,
        }
        Dlg:check {
            id = "spriteSheetTrim",
            label = " SpriteSheet Trim:",
            selected = Config.spriteSheetTrim.value,
            visible = Config.spriteSheetExport.value,
            onclick = function() ConfigHandler.UpdateConfigValue("spriteSheetTrim", Dlg.data.spriteSheetTrim) end,
        }

        Dlg:tab {
            id = "spineSettingsTab",
            text = "Spine Settings",
        }
        Dlg:check {
            id = "spineExport",
            label = "Export SpineSheet:",
            selected = Config.spineExport.value,
            onclick = function() ConfigHandler.UpdateConfigValue("spineExport", Dlg.data.spineExport) end,
        }
        Dlg:check {
            id = "spineSetStaticSlot",
            label = " Set Static Slot:",
            selected = Config.spineSetStaticSlot.value,
            visible = Config.spineExport.value,
            onclick = function() ConfigHandler.UpdateConfigValue("spineSetStaticSlot", Dlg.data.spineSetStaticSlot) end,
        }
        Dlg:entry {
            id = "spineStaticSlotName",
            label = "  Static Slot Name:",
            text = Config.spineStaticSlotName.value,
            visible = Config.spineExport.value and Config.spineSetStaticSlot.value,
            onchange = function() ConfigHandler.UpdateConfigValue("spineStaticSlotName", Dlg.data.spineStaticSlotName) end,
        }
        Dlg:check {
            id = "spineSetRootPostion",
            label = " Set Root Position:",
            selected = Config.spineSetRootPostion.value,
            visible = Config.spineExport.value,
            onclick = function() ConfigHandler.UpdateConfigValue("spineSetRootPostion", Dlg.data.spineSetRootPostion) end,
        }
        Dlg:combobox {
            id = "spineRootPostionMethod",
            label = "  Root position Method:",
            option = Config.spineRootPostionMethod.value,
            options = { "manual", "automatic", "center" },
            visible = Config.spineExport.value and Config.spineSetRootPostion.value,
            onchange = function() ConfigHandler.UpdateConfigValue("spineRootPostionMethod", Dlg.data.spineRootPostionMethod) end,
        }
        Dlg:number {
            id = "spineRootPostionX",
            label = "   Root Postion X:",
            text = Config.spineRootPostionX.value,
            visible = Config.spineExport.value and Config.spineSetRootPostion.value and Config.spineRootPostionMethod.value == "manual",
            decimals = 0,
            onchange = function() ConfigHandler.UpdateConfigValue("spineRootPostionX", Dlg.data.spineRootPostionX) end,
        }
        Dlg:number {
            id = "spineRootPostionY",
            label = "   Root Postion Y:",
            text = Config.spineRootPostionY.value,
            visible = Config.spineExport.value and Config.spineSetRootPostion.value and Config.spineRootPostionMethod.value == "manual",
            decimals = 0,
            onchange = function() ConfigHandler.UpdateConfigValue("spineRootPostionY", Dlg.data.spineRootPostionY) end,
        }
        Dlg:check {
            id = "spineSetImagesPath",
            label = " Set Images Path:",
            selected = Config.spineSetImagesPath.value,
            visible = Config.spineExport.value,
            onclick = function() ConfigHandler.UpdateConfigValue("spineSetImagesPath", Dlg.data.spineSetImagesPath) end,
        }
        Dlg:entry {
            id = "spineImagesPath",
            label = "  Images Path:",
            text = Config.spineImagesPath.value,
            visible = Config.spineExport.value and Config.spineSetImagesPath.value,
            onchange = function() ConfigHandler.UpdateConfigValue("spineImagesPath", Dlg.data.spineImagesPath) end,
        }
        Dlg:check {
            id = "spineGroupsAsSkins",
            label = " Groups As Skins:",
            selected = Config.spineGroupsAsSkins.value,
            visible = Config.spineExport.value,
            onclick = function() ConfigHandler.UpdateConfigValue("spineGroupsAsSkins", Dlg.data.spineGroupsAsSkins) end,
        }
        Dlg:entry {
            id = "spineSkinNameFormat",
            label = "  Skin Name Format:",
            text = Config.spineSkinNameFormat.value,
            visible = Config.spineExport.value and Config.spineGroupsAsSkins.value,
            onchange = function() ConfigHandler.UpdateConfigValue("spineSkinNameFormat", Dlg.data.spineSkinNameFormat) end,
        }
        Dlg:check {
            id = "spineSeparateSlotSkin",
            label = "  Separate Slot/Skin:",
            selected = Config.spineSeparateSlotSkin.value,
            visible = Config.spineExport.value and Config.spineGroupsAsSkins.value,
            onclick = function() ConfigHandler.UpdateConfigValue("spineSeparateSlotSkin", Dlg.data.spineSeparateSlotSkin) end,
        }
        Dlg:entry {
            id = "spineSlotNameFormat",
            label = "   Slot Name Format:",
            text = Config.spineSlotNameFormat.value,
            visible = Config.spineExport.value and Config.spineGroupsAsSkins.value and Config.spineSeparateSlotSkin.value,
            onchange = function() ConfigHandler.UpdateConfigValue("spineSlotNameFormat", Dlg.data.spineSlotNameFormat) end,
        }
        Dlg:entry {
            id = "spineSkinAttachmentFormat",
            label = "   Skin Attachment Format:",
            text = Config.spineSkinAttachmentFormat.value,
            visible = Config.spineExport.value and Config.spineGroupsAsSkins.value and Config.spineSeparateSlotSkin.value,
            onchange = function() ConfigHandler.UpdateConfigValue("spineSkinAttachmentFormat", Dlg.data.spineSkinAttachmentFormat) end,
        }
        Dlg:entry {
            id = "spineLayerNameSeparator",
            label = "   Layer Name Separator:",
            text = Config.spineLayerNameSeparator.value,
            visible = Config.spineExport.value and Config.spineGroupsAsSkins.value and Config.spineSeparateSlotSkin.value,
            onchange = function() ConfigHandler.UpdateConfigValue("spineLayerNameSeparator", Dlg.data.spineLayerNameSeparator) end,
        }

        Dlg:endtabs {}

        Dlg:entry {
            id = "help",
            label = "Need help? Visit my GitHub repository @",
            text = "https://github.com/RampantDespair/Aseprite-Exporter",
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
            onclick = function () ConfigHandler.ResetConfig(activeSprite, asepriteExporter.ExtraDialogModifications) end,
        }
    end

    Dlg:show()

    ConfigHandler.WriteConfig()

    if Dlg.data.cancel then
        return
    end

    if not Dlg.data.confirm then
        app.alert("Settings were not confirmed, script aborted.")
        return
    end

    if Dlg.data.outputPath == nil then
        app.alert("No output directory was specified, script aborted.")
        return
    end

    local fileName = app.fs.fileTitle(activeSprite.filename)

    if Dlg.data.spriteSheetNameTrim then
        local _index = string.find(fileName, "_")
        if _index ~= nil then
            fileName = string.sub(fileName, _index + 1, string.len(fileName))
        end
    end

    local fileNameTemplate = Dlg.data.spriteSheetFileNameFormat:gsub("{spritename}", fileName)

    if fileNameTemplate == nil then
        app.alert("No file name was specified, script aborted.")
        return
    end

    RootPositon = asepriteExporter.GetRootPosition(activeSprite)
    app.alert("RootPosition is x:" .. RootPositon.x .. " y:" .. RootPositon.y)

    local layerVisibilityData = LayerHandler.GetLayerVisibilityData(activeSprite)

    LayerHandler.HideLayers(activeSprite)
    asepriteExporter.Export(activeSprite, activeSprite, fileName, fileNameTemplate)
    LayerHandler.RestoreLayers(activeSprite, layerVisibilityData)

    app.alert("Exported " .. LayerCount .. " layers to " .. Dlg.data.outputPath)
end

function asepriteExporter.Initialize(configHandler, layerHandler)
    ConfigHandler = configHandler
    LayerHandler = layerHandler
end

return
