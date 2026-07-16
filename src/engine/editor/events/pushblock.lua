local EditorPushBlock, super = Class(EditorEvent)

EditorPushBlock.sprite_property = "sprite"
function EditorPushBlock:getEditorSprite(data)
    return data.properties.sprite or "world/events/push_block"
end
function EditorPushBlock:init(data, options)
    super.init(self, data, options)
    self:registerProperty("sprite", "asset_path", {
        asset_registry = { "texture", "frames" },
        path_root = "assets/sprites", strip_extension = true,
        extensions = { "png", "jpg", "jpeg" }
    })
    self:registerProperty("solvedsprite", "asset_path", {
        name = "Solved Sprite", asset_registry = { "texture", "frames" },
        path_root = "assets/sprites", strip_extension = true,
        extensions = { "png", "jpg", "jpeg" }
    })
    self:registerProperty("pushdist", "number", { name = "Push Distance", default = 40 })
    self:registerProperty("pushtime", "number", { name = "Push Time", default = 0.2 })
    self:registerProperty("pushsound", "asset_path", {
        name = "Push Sound", default = "noise", asset_registry = "sound_data",
        path_root = "assets/sounds", strip_extension = true, extensions = { "wav", "ogg" }
    })
    self:registerProperty("pressbuttons", "boolean", { name = "Press Buttons", default = true })
    self:registerProperty("lock", "boolean")
    self:registerProperty("inputlock", "boolean", { name = "Input Lock" })
end
function EditorPushBlock:createObject(map, context)
    return PushBlock(self.data.x, self.data.y, self:getRectData(), self.data.properties)
end

return EditorPushBlock
