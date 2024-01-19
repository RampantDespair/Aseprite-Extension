---@class (exact) ConfigHandler
---@field ArrayContainsValue fun(table: table, targetValue: any): boolean
---@field ArrayContainsKey fun(table: table, targetKey: any): boolean
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
