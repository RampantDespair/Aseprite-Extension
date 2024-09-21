---@class (exact) ConfigHandler
---@field ArrayContainsValue fun(table: table, targetValue: any): boolean
---@field ArrayContainsKey fun(table: table, targetKey: any): boolean
---@field ArrayGetValueIndex fun(table: table, targetValue: any): integer
---@field InitializeConfig fun()
---@field PopulateConfig fun(configFile: string)
---@field InitializeConfigKeys fun()
---@field UpdateConfigFile fun(activeSprite: Sprite, newValue: any, extraDialogModifications: fun())
---@field UpdateConfigValue fun(configKey: string, newValue: any)
---@field UpdateChildrenVisibility fun(configKey: string, visibility: string)
---@field WriteConfig fun()
---@field UpdateDialog fun(configKey: string, newValue: any)
---@field ResetConfig fun(activeSprite: Sprite, extraDialogModifications: fun())
ConfigHandler = {}

---@class (exact) LayerHandler
---@field GetLayerVisibilityData fun(activeSprite: Sprite): table
---@field HideLayers fun(activeSprite: Sprite)
---@field RestoreLayers fun(activeSprite: Sprite, layerVisibilityData: table)
LayerHandler = {}

---@class (exact) ConfigEntry
---@field order integer
---@field type "check" | "color" | "combobox" | "entry" | "number" | "radio" | "slider",
---@field default any,
---@field defaults string[],
---@field value any,
---@field parent string | nil,
---@field children string[],
---@field condition string | nil,
ConfigEntry = {}
