local EditorSpriteEvent, super = Class(EditorEvent)

EditorSpriteEvent.sprite_property = "texture"
EditorSpriteEvent.scaling_mode = "scale"
function EditorSpriteEvent:init(data, options)
    super.init(self, data, options)
    self:registerProperty("texture", "string")
    self:registerProperty("speed", "number")
    self:registerProperty("scalex", "number", { name = "Scale X", default = 2 })
    self:registerProperty("scaley", "number", { name = "Scale Y", default = 2 })
end
return EditorSpriteEvent
