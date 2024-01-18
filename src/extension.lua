-- FUNCTIONS

function init(plugin)
    local parentGroup = "file_scripts"
    local extensionGroup = "import_importy_export"

    plugin:newMenuSeparator {
        group = parentGroup,
    }

    plugin:newMenuGroup {
        id = extensionGroup,
        title = "Import/Export",
        group = parentGroup,
    }

    plugin:newCommand {
        id = "asepriteImport",
        title = "Import",
        group = extensionGroup,
        onclick = function()
            
        end,
        onenabled = function() return app.activeSprite ~= nil end,
    }

    plugin:newCommand {
        id = "asepriteExport",
        title = "Export",
        group = extensionGroup,
        onclick = function()
            
        end,
        onenabled = function() return app.activeSprite ~= nil end,
    }
end

function exit(plugin) end
