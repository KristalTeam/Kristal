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
function EditorSpriteEvent:createObject(map, context)
    local properties = self.data.properties
    local sprite = Sprite(properties.texture, self.data.x, self.data.y)
    sprite:play(properties.speed, true)
    sprite:setScale(properties.scalex or 2, properties.scaley or 2)
    return sprite
end

return EditorSpriteEvent
