local EditorPushBlock, super = Class(EditorEvent)

EditorPushBlock.sprite_property = "sprite"
function EditorPushBlock:getEditorSprite(data)
    return data.properties.sprite or "world/events/push_block"
end
function EditorPushBlock:init(data, options)
    super.init(self, data, options)
    self:registerProperty("sprite", "string")
    self:registerProperty("solvedsprite", "string", { name = "Solved Sprite" })
    self:registerProperty("pushdist", "number", { name = "Push Distance", default = 40 })
    self:registerProperty("pushtime", "number", { name = "Push Time", default = 0.2 })
    self:registerProperty("pushsound", "string", { name = "Push Sound", default = "noise" })
    self:registerProperty("pressbuttons", "boolean", { name = "Press Buttons", default = true })
    self:registerProperty("lock", "boolean")
    self:registerProperty("inputlock", "boolean", { name = "Input Lock" })
end
return EditorPushBlock
