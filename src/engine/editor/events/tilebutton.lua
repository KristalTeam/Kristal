---@class EditorTileButton : EditorEvent
---@overload fun(data?: table, options?: table): EditorTileButton
local EditorTileButton, super = Class(EditorEvent)

EditorTileButton.sprite_property = "sprite"
function EditorTileButton:getEditorSprite(data)
    return data.properties.sprite or "world/events/glowtile/idle"
end
function EditorTileButton:init(data, options)
    super.init(self, data, options)
    self:registerProperty("sprite", "asset_path", {
        asset_registry = { "texture", "frames" },
        path_root = "assets/sprites", strip_extension = true,
        extensions = { "png", "jpg", "jpeg" }
    })
    self:registerProperty("pressedsprite", "asset_path", {
        name = "Pressed Sprite", asset_registry = { "texture", "frames" },
        path_root = "assets/sprites", strip_extension = true,
        extensions = { "png", "jpg", "jpeg" }
    })
    self:registerProperty("onsound", "asset_path", {
        name = "On Sound", asset_registry = "sound_data",
        path_root = "assets/sounds", strip_extension = true, extensions = { "wav", "ogg" }
    })
    self:registerProperty("offsound", "asset_path", {
        name = "Off Sound", asset_registry = "sound_data",
        path_root = "assets/sounds", strip_extension = true, extensions = { "wav", "ogg" }
    })
    self:registerProperty("blocks", "boolean")
    self:registerProperty("group", "string")
    self:registerProperty("flag", "string")
    self:registerProperty("once", "boolean")
    self:registerProperty("keepdown", "boolean", { name = "Keep Down" })
    self:registerProperty("cutscene", "script_path", {
        path_root = "scripts/world/cutscenes", strip_extension = true,
        extensions = { "lua" }, registry = "world_cutscenes"
    })
    self:registerProperty("script", "script_path", {
        path_root = "scripts/world/scripts", strip_extension = true,
        extensions = { "lua" }, registry = "event_scripts"
    })
end
function EditorTileButton:createObject(map, context)
    return TileButton(self.data.x, self.data.y, self:getRectData(), self.data.properties)
end

return EditorTileButton
