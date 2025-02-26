-- INSTANCES
local ConfigHandler = require("handler-config")
local LayerHandler = require("handler-layer")
local AsepriteBase = require("aseprite-base")

-- CLASS DEFINITION
---@class (exact) AsepriteExporter: AsepriteBase
---@field rootPosition Point
---@field spineFile file*?
---@field spineSlots table<string, string[]>
---@field spineSkins table<string, table<string, string[]>>
---@field __index AsepriteBase
---@field _init fun(self: AsepriteBase)
---@field Export fun(self: AsepriteExporter, activeSprite: Sprite | Layer, rootLayer: Sprite | Layer, fileName: string, fileNameTemplate: string)
---@field ExportJsonEnd fun(self: AsepriteExporter)
---@field ExportJsonParse fun(self: AsepriteExporter, layer: Layer, cel: Cel, fileNameTemplate: string)
---@field ExportJsonStart fun(self: AsepriteExporter, fileName: string)
---@field ExportSpriteSheet fun(self: AsepriteExporter, activeSprite: Sprite | Layer, cel: Cel, fileNameTemplate: string)
---@field ExportSpriteLayers fun(self: AsepriteExporter, activeSprite: Sprite | Layer, rootLayer: Sprite | Layer, fileName: string, fileNameTemplate: string)
---@field ValidateRootPosition fun(self: AsepriteExporter): boolean
---@field GetRootPosition fun(self: AsepriteExporter): string
---@field SetRootPosition fun(self: AsepriteExporter)
local AsepriteExporter = {}
AsepriteExporter.__index = AsepriteExporter
setmetatable(AsepriteExporter, {
    __index = AsepriteBase,
    __call = function(cls, ...)
        local self = setmetatable({}, cls)
        self:_init(...)
        return self
    end,
})

-- INITIALIZER
function AsepriteExporter:_init()
    self.rootPosition = {
        x = 0,
        y = 0,
    }
    self.spineFile = nil
    self.spineSlots = {}
    self.spineSkins = {}

    ---@type table<string, ConfigEntry>
    local config = {
        outputSubdirectory = {
            order = 100,
            type = "entry",
            default = "images",
            defaults = {},
            value = nil,
            parent = nil,
            children = {},
            condition = nil,
        },
        outputGroupsAsDirectories = {
            order = 101,
            type = "check",
            default = true,
            defaults = {},
            value = nil,
            parent = nil,
            children = {},
            condition = nil,
        },
        spriteSheetExport = {
            order = 200,
            type = "check",
            default = true,
            defaults = {},
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
            order = 201,
            type = "check",
            default = true,
            defaults = {},
            value = nil,
            parent = "spriteSheetExport",
            children = {},
            condition = nil,
        },
        spriteSheetFileNameFormat = {
            order = 202,
            type = "entry",
            default = "{spritename}-{layergroup}-{layername}",
            defaults = {},
            value = nil,
            parent = "spriteSheetExport",
            children = {},
            condition = nil,
        },
        spriteSheetFileFormat = {
            order = 203,
            type = "combobox",
            default = "png",
            defaults = {
                "png",
                "jpg",
                "gif",
            },
            value = nil,
            parent = "spriteSheetExport",
            children = {},
            condition = nil,
        },
        spriteSheetTrim = {
            order = 204,
            type = "check",
            default = true,
            defaults = {},
            value = nil,
            parent = "spriteSheetExport",
            children = {},
            condition = nil,
        },
        spineExport = {
            order = 300,
            type = "check",
            default = true,
            defaults = {},
            value = nil,
            parent = nil,
            children = {
                "spineSetStaticSlot",
                "spineSetRootPosition",
                "spineSetImagesPath",
                "spineSkins",
            },
            condition = nil,
        },
        spineSetStaticSlot = {
            order = 301,
            type = "check",
            default = true,
            defaults = {},
            value = nil,
            parent = "spineExport",
            children = {
                "spineStaticSlotName",
            },
            condition = nil,
        },
        spineStaticSlotName = {
            order = 302,
            type = "entry",
            default = "slot",
            defaults = {},
            value = nil,
            parent = "spineSetStaticSlot",
            children = {},
            condition = nil,
        },
        spineSetRootPosition = {
            order = 303,
            type = "check",
            default = true,
            defaults = {},
            value = nil,
            parent = "spineExport",
            children = {
                "spineRootPositionMethod",
                "spineRootPosition",
            },
            condition = nil,
        },
        spineRootPositionMethod = {
            order = 304,
            type = "combobox",
            default = "center",
            defaults = {
                "center",
                "manual",
                "percentage",
            },
            value = nil,
            parent = "spineSetRootPosition",
            children = {
                "spineRootPositionX",
                "spineRootPositionY",
                "spineRootPositionPX",
                "spineRootPositionPY",
            },
            condition = nil,
        },
        spineRootPositionPX = {
            order = 305,
            type = "number",
            default = "0.50",
            defaults = {},
            value = nil,
            parent = "spineRootPositionMethod",
            children = {},
            condition = "percentage",
        },
        spineRootPositionPY = {
            order = 306,
            type = "number",
            default = "0.50",
            defaults = {},
            value = nil,
            parent = "spineRootPositionMethod",
            children = {},
            condition = "percentage",
        },
        spineRootPositionX = {
            order = 307,
            type = "number",
            default = "0",
            defaults = {},
            value = nil,
            parent = "spineRootPositionMethod",
            children = {},
            condition = "manual",
        },
        spineRootPositionY = {
            order = 308,
            type = "number",
            default = "0",
            defaults = {},
            value = nil,
            parent = "spineRootPositionMethod",
            children = {},
            condition = "manual",
        },
        spineSetImagesPath = {
            order = 309,
            type = "check",
            default = true,
            defaults = {},
            value = nil,
            parent = "spineExport",
            children = {
                "spineImagesPath",
            },
            condition = nil,
        },
        spineImagesPath = {
            order = 310,
            type = "entry",
            default = "images",
            defaults = {},
            value = nil,
            parent = "spineSetImagesPath",
            children = {},
            condition = nil,
        },
        spineSkins = {
            order = 311,
            type = "check",
            default = true,
            defaults = {},
            value = nil,
            parent = "spineExport",
            children = {
                "spineSkinsMode",
                "spineSkinNameFormat",
                "spineSeparateSlotSkin",
            },
            condition = nil,
        },
        spineSkinsMode = {
            order = 312,
            type = "combobox",
            default = "groups",
            defaults = {
                "groups",
                "layers",
            },
            value = nil,
            parent = "spineSkins",
            children = {},
            condition = nil,
        },
        spineSkinNameFormat = {
            order = 313,
            type = "entry",
            default = "weapon-{layergroup}",
            defaults = {},
            value = nil,
            parent = "spineSkins",
            children = {},
            condition = nil,
        },
        spineSeparateSlotSkin = {
            order = 314,
            type = "check",
            default = true,
            defaults = {},
            value = nil,
            parent = "spineSkins",
            children = {
                "spineSlotNameFormat",
                "spineSkinAttachmentFormat",
                "spineLayerNameSeparator",
            },
            condition = nil,
        },
        spineSlotNameFormat = {
            order = 315,
            type = "entry",
            default = "{layernameprefix}",
            defaults = {},
            value = nil,
            parent = "spineSeparateSlotSkin",
            children = {},
            condition = nil,
        },
        spineSkinAttachmentFormat = {
            order = 316,
            type = "entry",
            default = "{layernameprefix}-{layernamesuffix}",
            defaults = {},
            value = nil,
            parent = "spineSeparateSlotSkin",
            children = {},
            condition = nil,
        },
        spineLayerNameSeparator = {
            order = 317,
            type = "entry",
            default = "-",
            defaults = {},
            value = nil,
            parent = "spineSeparateSlotSkin",
            children = {},
            condition = nil,
        },
    }

    local scriptPath = debug.getinfo(1).source
    local activeSprite = app.sprite
    local configHandler = ConfigHandler(config, scriptPath, activeSprite)
    local layerHandler = LayerHandler()

    AsepriteBase._init(self, activeSprite, configHandler, layerHandler)
end

-- FUNCTIONS
function AsepriteExporter:SetRootPosition()
    if self.configHandler.config.spineExport.value == true and self.configHandler.config.spineSetRootPosition.value == true then
        if self.configHandler.config.spineRootPositionMethod.value == "center" then
            self.rootPosition = {
                x = self.activeSprite.width / 2,
                y = self.activeSprite.height / 2
            }
        elseif self.configHandler.config.spineRootPositionMethod.value == "manual" then
            self.rootPosition = {
                x = tonumber(self.configHandler.config.spineRootPositionX.value),
                y = tonumber(self.configHandler.config.spineRootPositionY.value)
            }
        elseif self.configHandler.config.spineRootPositionMethod.value == "percentage" then
            self.rootPosition = {
                x = self.activeSprite.width * tonumber(self.configHandler.config.spineRootPositionPX.value),
                y = self.activeSprite.height * tonumber(self.configHandler.config.spineRootPositionPY.value)
            }
        else
            error("Invalid spineRootPositionMethod value (" .. tostring(self.configHandler.config.spineRootPositionMethod.value) .. ")")
        end
    end
end

function AsepriteExporter:GetRootPosition()
    return "[" .. self.rootPosition.x .. ", " .. self.rootPosition.y .. "]" .. (self:ValidateRootPosition() and "" or " (invalid)")
end

function AsepriteExporter:ValidateRootPosition()
    return
        self.rootPosition.x > 0 and
        self.rootPosition.x < self.activeSprite.width and
        self.rootPosition.y > 0 and
        self.rootPosition.y < self.activeSprite.height
end

function AsepriteExporter:ExportSpriteLayers(activeSprite, rootLayer, fileName, fileNameTemplate)
    app.command.GotoFirstFrame()

    for _, layer in ipairs(rootLayer.layers) do
        local _fileNameTemplate = fileNameTemplate
        local layerName = layer.name

        if layer.isGroup then
            local previousVisibility = layer.isVisible
            layer.isVisible = true

            if self.configHandler.config.outputGroupsAsDirectories.value == true then
                _fileNameTemplate = app.fs.joinPath(layerName, _fileNameTemplate)
            end

            self:ExportSpriteLayers(activeSprite, layer, fileName, _fileNameTemplate)

            layer.isVisible = previousVisibility
        else
            layer.isVisible = true

            local layerParentName
            if pcall(function() layerParentName = layer.parent.name end) then
                _fileNameTemplate = string.gsub(_fileNameTemplate, "{layergroup}", layerParentName)
            else
                _fileNameTemplate = string.gsub(_fileNameTemplate, "{layergroup}", "default")
            end

            _fileNameTemplate = string.gsub(_fileNameTemplate, "{layername}", layerName)

            if #activeSprite.frames > 1 then
                for i = 1, #activeSprite.frames, 1 do
                    local cel = layer:cel(i)
                    local tempFileNameTemplate = _fileNameTemplate

                    if cel ~= nil then
                        if #layer.cels > 1 then
                            tempFileNameTemplate = tempFileNameTemplate .. "-" .. tostring(i)
                        end

                        if self.configHandler.config.spriteSheetExport.value == true then
                            local tempSprite = Sprite(activeSprite.width, activeSprite.height)
                            tempSprite:newCel(tempSprite.layers[1], 1, cel.image, cel.position)
                            self:ExportSpriteSheet(tempSprite, cel, tempFileNameTemplate)
                            tempSprite:close()
                        end

                        if self.configHandler.config.spineExport.value == true then
                            self:ExportSpineJsonParse(layer, cel, tempFileNameTemplate)
                        end
                    end

                    app.command.GotoNextFrame()
                end

                self.layerCount = self.layerCount + 1
            else
                if #layer.cels == 1 then
                    if self.configHandler.config.spriteSheetExport.value == true then
                        self:ExportSpriteSheet(activeSprite, layer.cels[1], _fileNameTemplate)
                    end

                    if self.configHandler.config.spineExport.value == true then
                        self:ExportSpineJsonParse(layer, layer.cels[1], _fileNameTemplate)
                    end

                    LayerCount = LayerCount + 1
                end
            end

            layer.isVisible = false
            app.command.GotoFirstFrame()
        end
    end
end

function AsepriteExporter:ExportSpriteSheet(activeSprite, cel, fileNameTemplate)
    local currentLayer = Sprite(activeSprite)

    if self.configHandler.config.spriteSheetTrim.value == true then
        currentLayer:crop(cel.position.x, cel.position.y, cel.bounds.width, cel.bounds.height)
    end

    local newPath = app.fs.joinPath(self.configHandler.dialog.data.outputPath, fileNameTemplate .. "." .. self.configHandler.config.spriteSheetFileFormat.value)
    currentLayer:saveCopyAs(newPath)
    currentLayer:close()
end

function AsepriteExporter:ExportSpineJsonStart(fileName)
    local spineFileName = app.fs.joinPath(app.fs.filePath(self.configHandler.dialog.data.outputFile), fileName .. ".json")

    os.execute("mkdir " .. self.configHandler.dialog.data.outputPath)
    self.spineFile = io.open(spineFileName, "w")

    self.spineFile:write('{ ')
    self.spineFile:write('"skeleton": { ')

    if self.configHandler.config.spineSetImagesPath.value == true then
        self.spineFile:write(string.format([["images": "%s" ]], "./" .. self.configHandler.config.spineImagesPath.value .. "/"))
    end

    self.spineFile:write('}, ')
    self.spineFile:write('"bones": [ { ')
    self.spineFile:write('"name": "root" ')
    self.spineFile:write('} ')
    self.spineFile:write('], ')
end

function AsepriteExporter:ExportSpineJsonParse(layer, cel, fileNameTemplate)
    local layerName = layer.name

    local slotName
    if self.configHandler.config.spineSetStaticSlot.value == true then
        slotName = self.configHandler.config.spineStaticSlotName.value
    else
        slotName = layerName
    end

    local celPosition = cel.position
    local celX = celPosition.x
    local celY = celPosition.y

    local celBounds = cel.bounds
    local celWidth = celBounds.width
    local celHeight = celBounds.height

    local realPositionX = celX + celWidth / 2
    local realPositionY = celY + celHeight / 2

    local spriteX
    local spriteY

    if self.configHandler.config.spineSetRootPosition.value == true then
        spriteX = realPositionX - self.rootPosition.x
        spriteY = self.rootPosition.y - realPositionY
    else
        spriteX = realPositionX
        spriteY = realPositionY
    end

    if self.configHandler.config.spineSkins.value == true then
        fileNameTemplate = string.gsub(fileNameTemplate, "\\", "/")
        if self.configHandler.config.spineSkinsMode.value == "groups" then
            local skinName
            if pcall(function() skinName = layer.parent.name end) then
                skinName = string.gsub(self.configHandler.config.spineSkinNameFormat.value, "{layergroup}", layer.parent.name)
            end

            if skinName ~= nil then
                if self.configHandler:ArrayContainsKey(self.spineSkins, skinName) == false then
                    self.spineSkins[skinName] = {}
                end

                local skinAttachmentName = layerName

                if self.configHandler.config.spineSeparateSlotSkin.value == true then
                    local separatorPosition = string.find(layerName, self.configHandler.config.spineLayerNameSeparator.value)

                    if separatorPosition then
                        local layerNamePrefix = string.sub(layerName, 1, separatorPosition - 1)
                        local layerNameSuffix = string.sub(layerName, separatorPosition + 1, #layerName)

                        slotName = self.configHandler.config.spineSlotNameFormat.value
                        if slotName ~= nil then
                            slotName = string.gsub(slotName, "{layernameprefix}", layerNamePrefix)
                            slotName = string.gsub(slotName, "{layernamesuffix}", layerNameSuffix)
                        end

                        skinAttachmentName = self.configHandler.config.spineSkinAttachmentFormat.value
                        if skinAttachmentName ~= nil then
                            skinAttachmentName = string.gsub(skinAttachmentName, "{layernameprefix}", layerNamePrefix)
                            skinAttachmentName = string.gsub(skinAttachmentName, "{layernamesuffix}", layerNameSuffix)
                        end
                    end
                end

                self.spineSkins[skinName][#self.spineSkins[skinName] + 1] = string.format(
                    [["%s": { "%s": { "name": "%s", "x": %.2f, "y": %.2f, "width": %d, "height": %d } }]],
                    slotName, skinAttachmentName, fileNameTemplate, spriteX, spriteY, celWidth, celHeight
                )
            else
                if self.configHandler:ArrayContainsKey(self.spineSkins, "default") == false then
                    self.spineSkins["default"] = {}
                end

                fileNameTemplate = string.gsub(fileNameTemplate, "{layergroup}", "default")
                self.spineSkins["default"][#self.spineSkins["default"] + 1] = string.format(
                    [["%s": { "%s": { "x": %.2f, "y": %.2f, "width": %d, "height": %d } }]],
                    slotName, fileNameTemplate, spriteX, spriteY, celWidth, celHeight
                )
            end
        elseif self.configHandler.config.spineSkinsMode.value == "layers" then
            local skinName
            if pcall(function() skinName = layer.name end) then
                skinName = string.gsub(self.configHandler.config.spineSkinNameFormat.value, "{layergroup}", layer.name)
            end

            if skinName ~= nil then
                if self.configHandler:ArrayContainsKey(self.spineSkins, skinName) == false then
                    self.spineSkins[skinName] = {}
                end

                local skinAttachmentName = layerName

                if self.configHandler.config.spineSeparateSlotSkin.value == true then
                    local separatorPosition = string.find(layerName, self.configHandler.config.spineLayerNameSeparator.value)

                    if separatorPosition then
                        local layerNamePrefix = string.sub(layerName, 1, separatorPosition - 1)
                        local layerNameSuffix = string.sub(layerName, separatorPosition + 1, #layerName)

                        slotName = self.configHandler.config.spineSlotNameFormat.value
                        if slotName ~= nil then
                            slotName = string.gsub(slotName, "{layernameprefix}", layerNamePrefix)
                            slotName = string.gsub(slotName, "{layernamesuffix}", layerNameSuffix)
                        end

                        skinAttachmentName = self.configHandler.config.spineSkinAttachmentFormat.value
                        if skinAttachmentName ~= nil then
                            skinAttachmentName = string.gsub(skinAttachmentName, "{layernameprefix}", layerNamePrefix)
                            skinAttachmentName = string.gsub(skinAttachmentName, "{layernamesuffix}", layerNameSuffix)
                        end
                    end
                end

                self.spineSkins[skinName][#self.spineSkins[skinName] + 1] = string.format(
                    [["%s": { "%s": { "name": "%s", "x": %.2f, "y": %.2f, "width": %d, "height": %d } }]],
                    slotName, skinAttachmentName, fileNameTemplate, spriteX, spriteY, celWidth, celHeight
                )
            else
                if self.configHandler:ArrayContainsKey(self.spineSkins, "default") == false then
                    self.spineSkins["default"] = {}
                end

                fileNameTemplate = string.gsub(fileNameTemplate, "{layergroup}", "default")
                self.spineSkins["default"][#self.spineSkins["default"] + 1] = string.format(
                    [["%s": { "%s": { "x": %.2f, "y": %.2f, "width": %d, "height": %d } }]],
                    slotName, fileNameTemplate, spriteX, spriteY, celWidth, celHeight
                )
            end
        else
            error("Invalid spineSkinsMode value (" .. tostring(self.configHandler.config.spineSkinsMode.value) .. ")")
        end
    else
        if self.configHandler:ArrayContainsKey(self.spineSkins, "default") == false then
            self.spineSkins["default"] = {}
        end

        fileNameTemplate = string.gsub(fileNameTemplate, "{layergroup}", "default")
        self.spineSkins["default"][#self.spineSkins["default"] + 1] = string.format(
            [["%s": { "%s": { "x": %.2f, "y": %.2f, "width": %d, "height": %d } }]],
            slotName, fileNameTemplate, spriteX, spriteY, celWidth, celHeight
        )
    end

    if self.configHandler:ArrayContainsValue(self.spineSlots, slotName) == false then
        self.spineSlots[#self.spineSlots + 1] = slotName
    end
end

function AsepriteExporter:ExportSpineJsonEnd()
    self.spineFile:write('"slots": [ ')

    local serializedSlots = {}
    for _, slotName in ipairs(self.spineSlots) do
        local slotJson = string.format([[{ "name": "%s", "bone": "%s", "attachment": "%s" }]], slotName, "root", slotName)
        table.insert(serializedSlots, slotJson)
    end

    self.spineFile:write(table.concat(serializedSlots, ", "))
    self.spineFile:write(" ], ")

    if self.configHandler.config.spineSkins.value == true then
        self.spineFile:write('"skins": [ ')

        local parsedSkins = {}
        for key, value in pairs(self.spineSkins) do
            parsedSkins[#parsedSkins + 1] = string.format([[{ "name": "%s", "attachments": { ]], key) .. table.concat(value, ", ") .. " } }"
        end

        self.spineFile:write(table.concat(parsedSkins, ", "))
        self.spineFile:write(' ], ')
    else
        self.spineFile:write('"skins": { ')
        self.spineFile:write('"default": { ')
        self.spineFile:write(table.concat(self.spineSkins["default"], ", "))
        self.spineFile:write('} ')
        self.spineFile:write('}, ')
    end

    self.spineFile:write('"animations": { "animation": {} } ')

    self.spineFile:write("}")

    self.spineFile:close()
end

function AsepriteExporter:Export(activeSprite, rootLayer, fileName, fileNameTemplate)
    if self.configHandler.config.spineExport.value == true then
        self:ExportSpineJsonStart(fileName)
    end

    self:ExportSpriteLayers(activeSprite, rootLayer, fileName, fileNameTemplate)

    if self.configHandler.config.spineExport.value == true then
        self:ExportSpineJsonEnd()
    end
end

function AsepriteExporter:BuildDialogSpecialized()
    self.configHandler.dialog:tab {
        id = "outputSettings",
        text = "Output Settings",
    }
    self.configHandler.dialog:file {
        id = "outputFile",
        label = "Output File:",
        filename = self.activeSprite.filename,
        open = false,
        onchange = function()
            self.configHandler.dialog:modify {
                id = "outputPath",
                text = app.fs.joinPath(
                    app.fs.filePath(self.configHandler.dialog.data.outputFile),
                    self.configHandler.dialog.data.outputSubdirectory
                )
            }
        end,
    }
    self.configHandler.dialog:entry {
        id = "outputSubdirectory",
        label = "Output Subdirectory:",
        text = self.configHandler.config.outputSubdirectory.value,
        onchange = function()
            self.configHandler.config.outputSubdirectory.value = self.configHandler.dialog.data.outputSubdirectory
            self.configHandler.dialog:modify {
                id = "outputPath",
                text = app.fs.joinPath(
                    app.fs.filePath(self.configHandler.dialog.data.outputFile),
                    self.configHandler.dialog.data.outputSubdirectory
                )
            }
        end,
    }
    self.configHandler.dialog:label {
        id = "outputPath",
        label = "Output Path:",
        text = app.fs.joinPath(
            app.fs.filePath(self.configHandler.dialog.data.outputFile),
            self.configHandler.dialog.data.outputSubdirectory
        ),
    }
    self.configHandler.dialog:check {
        id = "outputGroupsAsDirectories",
        label = "Groups As Directories:",
        selected = self.configHandler.config.outputGroupsAsDirectories.value,
        onclick = function()
            self.configHandler:UpdateConfigValue(
                "outputGroupsAsDirectories",
                self.configHandler.dialog.data.outputGroupsAsDirectories
            )
        end,
    }

    self.configHandler.dialog:tab {
        id = "spriteSettingsTab",
        text = "Sprite Settings",
    }
    self.configHandler.dialog:check {
        id = "spriteSheetExport",
        label = "Export SpriteSheet:",
        selected = self.configHandler.config.spriteSheetExport.value,
        onclick = function()
            self.configHandler:UpdateConfigValue(
                "spriteSheetExport",
                self.configHandler.dialog.data.spriteSheetExport
            )
        end,
    }
    self.configHandler.dialog:check {
        id = "spriteSheetNameTrim",
        label = " Sprite Name Trim:",
        selected = self.configHandler.config.spriteSheetNameTrim.value,
        visible = self.configHandler.config.spriteSheetExport.value,
        onclick = function()
            self.configHandler:UpdateConfigValue(
                "spriteSheetNameTrim",
                self.configHandler.dialog.data.spriteSheetNameTrim
            )
        end,
    }
    self.configHandler.dialog:entry {
        id = "spriteSheetFileNameFormat",
        label = " File Name Format:",
        text = self.configHandler.config.spriteSheetFileNameFormat.value,
        visible = self.configHandler.config.spriteSheetExport.value,
        onchange = function()
            self.configHandler:UpdateConfigValue(
                "spriteSheetFileNameFormat",
                self.configHandler.dialog.data.spriteSheetFileNameFormat
            )
        end,
    }
    self.configHandler.dialog:combobox {
        id = "spriteSheetFileFormat",
        label = " File Format:",
        option = self.configHandler.config.spriteSheetFileFormat.value,
        options = self.configHandler.config.spriteSheetFileFormat.defaults,
        onchange = function()
            self.configHandler:UpdateConfigValue(
                "spriteSheetFileFormat",
                self.configHandler.dialog.data.spriteSheetFileFormat
            )
        end,
    }
    self.configHandler.dialog:check {
        id = "spriteSheetTrim",
        label = " SpriteSheet Trim:",
        selected = self.configHandler.config.spriteSheetTrim.value,
        visible = self.configHandler.config.spriteSheetExport.value,
        onclick = function()
            self.configHandler:UpdateConfigValue(
                "spriteSheetTrim",
                self.configHandler.dialog.data.spriteSheetTrim
            )
        end,
    }

    self.configHandler.dialog:tab {
        id = "spineSettingsTab",
        text = "Spine Settings",
    }
    self.configHandler.dialog:check {
        id = "spineExport",
        label = "Export SpineSheet:",
        selected = self.configHandler.config.spineExport.value,
        onclick = function()
            self.configHandler:UpdateConfigValue(
                "spineExport",
                self.configHandler.dialog.data.spineExport
            )
        end,
    }
    self.configHandler.dialog:check {
        id = "spineSetStaticSlot",
        label = " Set Static Slot:",
        selected = self.configHandler.config.spineSetStaticSlot.value,
        visible = self.configHandler.config.spineExport.value,
        onclick = function()
            self.configHandler:UpdateConfigValue(
                "spineSetStaticSlot",
                self.configHandler.dialog.data.spineSetStaticSlot
            )
        end,
    }
    self.configHandler.dialog:entry {
        id = "spineStaticSlotName",
        label = "  Static Slot Name:",
        text = self.configHandler.config.spineStaticSlotName.value,
        visible = self.configHandler.config.spineExport.value and self.configHandler.config.spineSetStaticSlot.value,
        onchange = function()
            self.configHandler:UpdateConfigValue(
                "spineStaticSlotName",
                self.configHandler.dialog.data.spineStaticSlotName
            )
        end,
    }
    self.configHandler.dialog:check {
        id = "spineSetRootPosition",
        label = " Set Root Position:",
        selected = self.configHandler.config.spineSetRootPosition.value,
        visible = self.configHandler.config.spineExport.value,
        onclick = function()
            self.configHandler:UpdateConfigValue(
                "spineSetRootPosition",
                self.configHandler.dialog.data.spineSetRootPosition
            )
        end,
    }
    self.configHandler.dialog:combobox {
        id = "spineRootPositionMethod",
        label = "  Root position Method:",
        option = self.configHandler.config.spineRootPositionMethod.value,
        options = self.configHandler.config.spineRootPositionMethod.defaults,
        visible = self.configHandler.config.spineExport.value and self.configHandler.config.spineSetRootPosition.value,
        onchange = function()
            self.configHandler:UpdateConfigValue(
                "spineRootPositionMethod",
                self.configHandler.dialog.data.spineRootPositionMethod
            )
            self:SetRootPosition()
            self.configHandler.dialog:modify {
                id = "spineRootPosition",
                text = self:GetRootPosition(),
            }
        end,
    }
    self.configHandler.dialog:number {
        id = "spineRootPositionX",
        label = "   Root Position X:",
        text = self.configHandler.config.spineRootPositionX.value,
        visible = self.configHandler.config.spineExport.value and self.configHandler.config.spineSetRootPosition.value and self.configHandler.config.spineRootPositionMethod.value == "manual",
        decimals = 0,
        onchange = function()
            self.configHandler:UpdateConfigValue(
                "spineRootPositionX",
                self.configHandler.dialog.data.spineRootPositionX
            )
            self:SetRootPosition()
            self.configHandler.dialog:modify {
                id = "spineRootPosition",
                text = self:GetRootPosition(),
            }
        end,
    }
    self.configHandler.dialog:number {
        id = "spineRootPositionY",
        label = "   Root Position Y:",
        text = self.configHandler.config.spineRootPositionY.value,
        visible = self.configHandler.config.spineExport.value and self.configHandler.config.spineSetRootPosition.value and self.configHandler.config.spineRootPositionMethod.value == "manual",
        decimals = 0,
        onchange = function()
            self.configHandler:UpdateConfigValue(
                "spineRootPositionY",
                self.configHandler.dialog.data.spineRootPositionY
            )
            self:SetRootPosition()
            self.configHandler.dialog:modify {
                id = "spineRootPosition",
                self:GetRootPosition(),
            }
        end,
    }
    self.configHandler.dialog:number {
        id = "spineRootPositionPX",
        label = "   Root Position PX:",
        text = self.configHandler.config.spineRootPositionPX.value,
        visible = self.configHandler.config.spineExport.value and self.configHandler.config.spineSetRootPosition.value and self.configHandler.config.spineRootPositionMethod.value == "percentage",
        decimals = 2,
        onchange = function()
            self.configHandler:UpdateConfigValue(
                "spineRootPositionPX",
                self.configHandler.dialog.data.spineRootPositionPX
            )
            self:SetRootPosition()
            self.configHandler.dialog:modify {
                id = "spineRootPosition",
                text = self:GetRootPosition(),
            }
        end,
    }
    self.configHandler.dialog:number {
        id = "spineRootPositionPY",
        label = "   Root Position PY:",
        text = self.configHandler.config.spineRootPositionPY.value,
        visible = self.configHandler.config.spineExport.value and self.configHandler.config.spineSetRootPosition.value and self.configHandler.config.spineRootPositionMethod.value == "percentage",
        decimals = 2,
        onchange = function()
            self.configHandler:UpdateConfigValue(
                "spineRootPositionPY",
                self.configHandler.dialog.data.spineRootPositionPY
            )
            self:SetRootPosition()
            self.configHandler.dialog:modify {
                id = "spineRootPosition",
                text = self:GetRootPosition(),
            }
        end,
    }
    self.configHandler.dialog:label {
        id = "spineRootPosition",
        label = "  Root Position:",
        text = self:GetRootPosition(),
        visible = self.configHandler.config.spineExport.value and self.configHandler.config.spineSetRootPosition.value,
    }
    self.configHandler.dialog:check {
        id = "spineSetImagesPath",
        label = " Set Images Path:",
        selected = self.configHandler.config.spineSetImagesPath.value,
        visible = self.configHandler.config.spineExport.value,
        onclick = function()
            self.configHandler:UpdateConfigValue(
                "spineSetImagesPath",
                self.configHandler.dialog.data.spineSetImagesPath
            )
        end,
    }
    self.configHandler.dialog:entry {
        id = "spineImagesPath",
        label = "  Images Path:",
        text = self.configHandler.config.spineImagesPath.value,
        visible = self.configHandler.config.spineExport.value and self.configHandler.config.spineSetImagesPath.value,
        onchange = function()
            self.configHandler:UpdateConfigValue(
                "spineImagesPath",
                self.configHandler.dialog.data.spineImagesPath
            )
        end,
    }
    self.configHandler.dialog:check {
        id = "spineSkins",
        label = " Skins:",
        selected = self.configHandler.config.spineSkins.value,
        visible = self.configHandler.config.spineExport.value,
        onclick = function()
            self.configHandler:UpdateConfigValue(
                "spineSkins",
                self.configHandler.dialog.data.spineSkins
            )
        end,
    }
    self.configHandler.dialog:combobox {
        id = "spineSkinsMode",
        label = "  Mode:",
        option = self.configHandler.config.spineSkinsMode.value,
        options = self.configHandler.config.spineSkinsMode.defaults,
        visible = self.configHandler.config.spineExport.value and self.configHandler.config.spineSkins.value,
        onchange = function()
            self.configHandler:UpdateConfigValue(
                "spineSkinsMode",
                self.configHandler.dialog.data.spineSkinsMode
            )
        end,
    }
    self.configHandler.dialog:entry {
        id = "spineSkinNameFormat",
        label = "  Skin Name Format:",
        text = self.configHandler.config.spineSkinNameFormat.value,
        visible = self.configHandler.config.spineExport.value and self.configHandler.config.spineSkins.value,
        onchange = function()
            self.configHandler:UpdateConfigValue(
                "spineSkinNameFormat",
                self.configHandler.dialog.data.spineSkinNameFormat
            )
        end,
    }
    self.configHandler.dialog:check {
        id = "spineSeparateSlotSkin",
        label = "  Separate Slot/Skin:",
        selected = self.configHandler.config.spineSeparateSlotSkin.value,
        visible = self.configHandler.config.spineExport.value and self.configHandler.config.spineSkins.value,
        onclick = function()
            self.configHandler:UpdateConfigValue(
                "spineSeparateSlotSkin",
                self.configHandler.dialog.data.spineSeparateSlotSkin
            )
        end,
    }
    self.configHandler.dialog:entry {
        id = "spineSlotNameFormat",
        label = "   Slot Name Format:",
        text = self.configHandler.config.spineSlotNameFormat.value,
        visible = self.configHandler.config.spineExport.value and self.configHandler.config.spineSkins.value and self.configHandler.config.spineSeparateSlotSkin.value,
        onchange = function()
            self.configHandler:UpdateConfigValue(
                "spineSlotNameFormat",
                self.configHandler.dialog.data.spineSlotNameFormat
            )
        end,
    }
    self.configHandler.dialog:entry {
        id = "spineSkinAttachmentFormat",
        label = "   Skin Attachment Format:",
        text = self.configHandler.config.spineSkinAttachmentFormat.value,
        visible = self.configHandler.config.spineExport.value and self.configHandler.config.spineSkins.value and self.configHandler.config.spineSeparateSlotSkin.value,
        onchange = function()
            self.configHandler:UpdateConfigValue(
                "spineSkinAttachmentFormat",
                self.configHandler.dialog.data.spineSkinAttachmentFormat
            )
        end,
    }
    self.configHandler.dialog:entry {
        id = "spineLayerNameSeparator",
        label = "   Layer Name Separator:",
        text = self.configHandler.config.spineLayerNameSeparator.value,
        visible = self.configHandler.config.spineExport.value and self.configHandler.config.spineSkins.value and self.configHandler.config.spineSeparateSlotSkin.value,
        onchange = function()
            self.configHandler:UpdateConfigValue(
                "spineLayerNameSeparator",
                self.configHandler.dialog.data.spineLayerNameSeparator
            )
        end,
    }
end

function AsepriteExporter:ExtraDialogModifications(activeSprite)
    self.configHandler.dialog:modify {
        id = "outputFile",
        filename = activeSprite.filename,
    }
    self.configHandler.dialog:modify {
        id = "outputPath",
        text = app.fs.joinPath(
            app.fs.filePath(self.configHandler.dialog.data.outputFile),
            self.configHandler.dialog.data.outputSubdirectory
        ),
    }
end

function AsepriteExporter:Execute()
    self:SetRootPosition()

    self:BuildDialog()

    self.configHandler:WriteConfig()

    if self.configHandler.dialog.data.cancel then
        return
    end

    if not self.configHandler.dialog.data.confirm then
        app.alert("Settings were not confirmed, script aborted.")
        return
    end

    if self.configHandler.dialog.data.outputPath == nil then
        app.alert("No output directory was specified, script aborted.")
        return
    end

    if self:ValidateRootPosition() == false then
        app.alert("Invalid root position, script aborted.")
        return
    end

    local fileName = app.fs.fileTitle(self.activeSprite.filename)

    if self.configHandler.dialog.data.spriteSheetNameTrim then
        local _index = string.find(fileName, "_")
        if _index ~= nil then
            fileName = string.sub(fileName, _index + 1, string.len(fileName))
        end
    end

    local fileNameTemplate = self.configHandler.dialog.data.spriteSheetFileNameFormat:gsub("{spritename}", fileName)

    if fileNameTemplate == nil then
        app.alert("No file name was specified, script aborted.")
        return
    end

    local layerVisibilityData = self.layerHandler:GetLayerVisibilityData(self.activeSprite)

    app.transaction("Exporter", function()
        self.layerHandler:HideLayers(self.activeSprite)
        self:Export(self.activeSprite, self.activeSprite, fileName, fileNameTemplate)
        self.layerHandler:RestoreLayers(self.activeSprite, layerVisibilityData)
    end)

    app.alert("Exported " .. self.layerCount .. " layers to " .. self.configHandler.dialog.data.outputPath)
end

-- CLASS RETURN
return AsepriteExporter
