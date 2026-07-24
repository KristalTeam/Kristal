---@class EditorSpriteObject : EditorObject
---@overload fun(data?: table, options?: table): EditorSpriteObject
local EditorSpriteObject, super = Class(EditorObject)

EditorSpriteObject.sprite_property = "texture"
EditorSpriteObject.scaling_mode = "scale"
EditorSpriteObject.sprite_alignment = "top_left"

function EditorSpriteObject:getSpriteScale()
    return self.properties.scalex or 2, self.properties.scaley or 2
end

function EditorSpriteObject:init(data, options)
    super.init(self, data, options)
    self:registerProperty("texture", "asset_path", {
        asset_registry = { "texture", "frames" },
        path_root = "assets/sprites", strip_extension = true,
        extensions = { "png", "jpg", "jpeg" }
    })
    self:registerProperty("speed", "number")
    self:registerProperty("scalex", "number", { name = "Scale X", default = 2 })
    self:registerProperty("scaley", "number", { name = "Scale Y", default = 2 })
end
function EditorSpriteObject:createObject(map, context)
    local properties = self.data.properties
    local sprite = Sprite(properties.texture, self.data.x, self.data.y)
    sprite:play(properties.speed, true)
    sprite:setScale(properties.scalex or 2, properties.scaley or 2)
    return sprite
end

return EditorSpriteObject
