-- INSTANCES
local ConfigHandler = require("handler-config")
local LayerHandler = require("handler-layer")
local AsepriteBase = require("aseprite-base")

-- CLASS DEFINITION
---@class (exact) AsepriteImporter: AsepriteBase
---@field importFileExtensions string[]
---@field __index AsepriteBase
---@field _init fun(self: AsepriteBase)
---@field Import fun(self: AsepriteImporter, activeSprite: Sprite, parentDirectory: string | nil, groupLayer: Layer | nil)
---@field CreateCels fun(self: AsepriteImporter, activeSprite: Sprite, newLayer: Layer, otherLayer: Layer)
---@field GetLayerByName fun(self: AsepriteImporter, layers: Layer[], layerName: string): Layer | nil
---@field GetColorMode fun(self: AsepriteImporter, colorMode: ColorMode): string
local AsepriteImporter = {}
AsepriteImporter.__index = AsepriteImporter
setmetatable(AsepriteImporter, {
    __index = AsepriteBase,
    __call = function(cls, ...)
        local self = setmetatable({}, cls)
        self:_init(...)
        return self
    end,
})

-- INITIALIZER
function AsepriteImporter:_init()
    self.importFileExtensions = { "png", "gif", "jpg", "jpeg" }

    ---@type table<string, ConfigEntry>
    local config = {
        inputSubdirectory = {
            order = 100,
            type = "entry",
            default = "sprite",
            defaults = {},
            value = nil,
            parent = nil,
            children = {},
            condition = nil,
        },
        inputDirectoriesAsGroups = {
            order = 101,
            type = "check",
            default = true,
            defaults = {},
            value = nil,
            parent = nil,
            children = {},
            condition = nil,
        },
        inputDuplicatesMode = {
            order = 102,
            type = "combobox",
            default = "override",
            defaults = {
                "override",
                "ignore",
                "skip",
            },
            value = nil,
            parent = nil,
            children = {},
            condition = nil,
        },
        inputSpritePosition = {
            order = 103,
            type = "combobox",
            default = "center",
            defaults = {
                "center",
                "inherit",
                "manual",
            },
            value = nil,
            parent = nil,
            children = {
                "inputSpritePositionX",
                "inputSpritePositionY",
            },
            condition = nil,
        },
        inputSpritePositionX = {
            order = 104,
            type = "number",
            default = "0",
            defaults = {},
            value = nil,
            parent = "inputSpritePosition",
            children = {},
            condition = "manual",
        },
        inputSpritePositionY = {
            order = 105,
            type = "number",
            default = "0",
            defaults = {},
            value = nil,
            parent = "inputSpritePosition",
            children = {},
            condition = "manual",
        },
    }

    local scriptPath = debug.getinfo(1).source
    local activeSprite = app.sprite
    local configHandler = ConfigHandler(config, scriptPath, activeSprite)
    local layerHandler = LayerHandler()

    AsepriteBase._init(self, activeSprite, configHandler, layerHandler)
end

-- FUNCTIONS
function AsepriteImporter:GetColorMode(colorMode)
    if (colorMode == ColorMode.RGB) then
        return "rgb"
    elseif (colorMode == ColorMode.GRAY) then
        return "gray"
    elseif (colorMode == ColorMode.INDEXED) then
        return "indexed"
    elseif (colorMode == ColorMode.TILEMAP) then
        return "tilemap"
    else
        return ""
    end
end

---@param layers Layer[]
---@param layerName string
function AsepriteImporter:GetLayerByName(layers, layerName)
    for _, value in ipairs(layers) do
        if value.name == layerName then
            return value
        end
    end
    return nil
end

function AsepriteImporter:CreateCels(activeSprite, newLayer, otherLayer)
    for _, otherCel in ipairs(otherLayer.cels) do
        if self.configHandler.config.inputSpritePosition.value == "center" then
            activeSprite:newCel(newLayer, otherCel.frameNumber, otherCel.image, Point(math.floor(activeSprite.width / 2) - math.floor(otherCel.bounds.width / 2), math.floor(activeSprite.height / 2) - math.floor(otherCel.bounds.height / 2)))
        elseif self.configHandler.config.inputSpritePosition.value == "inherit" then
            activeSprite:newCel(newLayer, otherCel.frameNumber, otherCel.image, otherCel.position)
        elseif self.configHandler.config.inputSpritePosition.value == "manual" then
            activeSprite:newCel(newLayer, otherCel.frameNumber, otherCel.image, Point(self.configHandler.config.inputSpritePositionX.value, self.configHandler.config.inputSpritePositionY.value))
        else
            error("Invalid inputSpritePosition value (" .. tostring(self.configHandler.config.inputSpritePosition.value) .. ")")
        end
    end
end

function AsepriteImporter:Import(activeSprite, parentDirectory, groupLayer)
    local activeColorMode = activeSprite.colorMode
    local activeColorModeName = self:GetColorMode(activeColorMode)

    local targetPath = self.configHandler.dialog.data.inputPath
    if parentDirectory ~= nil then
        targetPath = app.fs.joinPath(targetPath, parentDirectory)
        targetPath = app.fs.normalizePath(targetPath)
    end

    local importFiles = app.fs.listFiles(targetPath)
    for _, value in ipairs(importFiles) do
        local importFile = app.fs.joinPath(targetPath, value)
        importFile = app.fs.normalizePath(importFile)
        if app.fs.isDirectory(importFile) then
            local importFileDirectory = app.fs.fileTitle(importFile)
            local newLayer = self:GetLayerByName(activeSprite.layers, importFileDirectory)
            if newLayer ~= nil and newLayer.isGroup == false then
                newLayer = nil
            end

            if newLayer == nil or self.configHandler.config.inputDuplicatesMode.value == "ignore" then
                newLayer = activeSprite:newGroup()
                newLayer.stackIndex = 1
                newLayer.name = importFileDirectory
                self:Import(activeSprite, importFileDirectory, newLayer)
            elseif self.configHandler.config.inputDuplicatesMode.value == "override" then
                self:Import(activeSprite, importFileDirectory, newLayer)
            elseif self.configHandler.config.inputDuplicatesMode.value == "skip" then

            else
                error("Invalid inputDuplicatesMode value (" .. tostring(self.configHandler.config.inputDuplicatesMode.value) .. ")")
            end
        else
            local importFileExtension = app.fs.fileExtension(importFile)
            importFileExtension = string.lower(importFileExtension)
            if self.configHandler:ArrayContainsValue(self.importFileExtensions, importFileExtension) then
                local importFileName = app.fs.fileTitle(importFile)

                local otherSprite = Sprite({ fromFile = importFile })
                app.command.ChangePixelFormat {
                    format = activeColorModeName
                }

                while #activeSprite.frames < #otherSprite.frames do
                    activeSprite:newEmptyFrame(#activeSprite.frames + 1)
                end

                for _, otherLayer in ipairs(otherSprite.layers) do
                    local newLayer = self:GetLayerByName(groupLayer ~= nil and groupLayer.layers or activeSprite.layers, importFileName)
                    if newLayer == nil or self.configHandler.config.inputDuplicatesMode.value == "ignore" then
                        newLayer = activeSprite:newLayer()
                        newLayer.stackIndex = 1
                        newLayer.name = importFileName
                        newLayer.parent = groupLayer ~= nil and groupLayer or activeSprite
                        self:CreateCels(activeSprite, newLayer, otherLayer)
                    elseif self.configHandler.config.inputDuplicatesMode.value == "override" then
                        self:CreateCels(activeSprite, newLayer, otherLayer)
                    elseif self.configHandler.config.inputDuplicatesMode.value == "skip" then
                        self.layerCount = self.layerCount - 1
                    else
                        error("Invalid inputDuplicatesMode value (" .. tostring(self.configHandler.config.inputDuplicatesMode.value) .. ")")
                    end
                    self.layerCount = self.layerCount + 1
                end
                otherSprite:close()
            end
        end
    end
end

function AsepriteImporter:BuildDialogSpecialized()
    self.configHandler.dialog:tab {
        id = "inputSettings",
        text = "Input Settings",
    }
    self.configHandler.dialog:file {
        id = "inputFile",
        label = "Input File:",
        filename = self.activeSprite.filename,
        open = false,
        onchange = function()
            self.configHandler.dialog:modify {
                id = "inputPath",
                text = app.fs.joinPath(
                    app.fs.filePath(self.configHandler.dialog.data.inputFile),
                    self.configHandler.dialog.data.inputSubdirectory
                )
            }
        end,
    }
    self.configHandler.dialog:entry {
        id = "inputSubdirectory",
        label = "Input Subdirectory:",
        text = self.configHandler.config.inputSubdirectory.value,
        onchange = function()
            self.configHandler.config.inputSubdirectory.value = self.configHandler.dialog.data.inputSubdirectory
            self.configHandler.dialog:modify {
                id = "inputPath",
                text = app.fs.joinPath(
                    app.fs.filePath(self.configHandler.dialog.data.inputFile),
                    self.configHandler.dialog.data.inputSubdirectory
                )
            }
        end,
    }
    self.configHandler.dialog:label {
        id = "inputPath",
        label = "Input Path:",
        text = app.fs.joinPath(
            app.fs.filePath(self.configHandler.dialog.data.inputFile),
            self.configHandler.dialog.data.inputSubdirectory
        ),
    }
    self.configHandler.dialog:check {
        id = "inputDirectoriesAsGroups",
        label = "Directories As Groups:",
        selected = self.configHandler.config.inputDirectoriesAsGroups.value,
        onclick = function()
            self.configHandler:UpdateConfigValue(
                "inputDirectoriesAsGroups",
                self.configHandler.dialog.data.inputDirectoriesAsGroups
            )
        end,
    }
    self.configHandler.dialog:combobox {
        id = "inputDuplicatesMode",
        label = "Duplicates Mode:",
        option = self.configHandler.config.inputDuplicatesMode.value,
        options = self.configHandler.config.inputDuplicatesMode.defaults,
        onchange = function()
            self.configHandler:UpdateConfigValue(
                "inputDuplicatesMode",
                self.configHandler.dialog.data.inputDuplicatesMode
            )
        end,
    }
    self.configHandler.dialog:combobox {
        id = "inputSpritePosition",
        label = "Sprite Position Method:",
        option = self.configHandler.config.inputSpritePosition.value,
        options = self.configHandler.config.inputSpritePosition.defaults,
        onchange = function()
            self.configHandler:UpdateConfigValue(
                "inputSpritePosition",
                self.configHandler.dialog.data.inputSpritePosition
            )
        end,
    }
    self.configHandler.dialog:number {
        id = "inputSpritePositionX",
        label = " Sprite Postion X:",
        text = self.configHandler.config.inputSpritePositionX.value,
        visible = self.configHandler.config.inputSpritePosition.value == "manual",
        decimals = 0,
        onchange = function()
            self.configHandler:UpdateConfigValue(
                "inputSpritePositionX",
                self.configHandler.dialog.data.inputSpritePositionX
            )
        end,
    }
    self.configHandler.dialog:number {
        id = "inputSpritePositionY",
        label = " Sprite Postion Y:",
        text = self.configHandler.config.inputSpritePositionY.value,
        visible = self.configHandler.config.inputSpritePosition.value == "manual",
        decimals = 0,
        onchange = function()
            self.configHandler:UpdateConfigValue(
                "inputSpritePositionY",
                self.configHandler.dialog.data.inputSpritePositionY
            )
        end,
    }
end

function AsepriteImporter:ExtraDialogModifications(activeSprite)
    self.configHandler.dialog:modify {
        id = "inputFile",
        filename = activeSprite.filename,
    }
    self.configHandler.dialog:modify {
        id = "inputPath",
        text = app.fs.joinPath(
            app.fs.filePath(self.configHandler.dialog.data.inputFile),
            self.configHandler.dialog.data.inputSubdirectory
        ),
    }
end

function AsepriteImporter:Execute()
    self:BuildDialog()

    self.configHandler:WriteConfig()

    if self.configHandler.dialog.data.cancel then
        return
    end

    if not self.configHandler.dialog.data.confirm then
        app.alert("Settings were not confirmed, script aborted.")
        return
    end

    if self.configHandler.dialog.data.inputFile == nil then
        app.alert("No input file selected, script aborted.")
        return
    end

    if self.configHandler.dialog.data.inputPath == nil then
        app.alert("No input path selected, script aborted.")
        return
    end

    app.transaction("Importer", function() self:Import(self.activeSprite, nil, nil) end)

    app.alert("Imported " .. self.layerCount .. " layers")
end

-- CLASS RETURN
return AsepriteImporter
