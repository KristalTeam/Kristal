---@class EditorCoinBowl : EditorObject
---@overload fun(data?: table, options?: table): EditorCoinBowl
local EditorCoinBowl, super = Class(EditorObject)

EditorCoinBowl.editor_sprite = "world/events/coinbowl/bowl"
EditorCoinBowl.sprite_alignment = "top_left"
EditorCoinBowl.fixed_shape = "rectangle"
EditorCoinBowl.scaling_mode = "scale"

function EditorCoinBowl:init(data, options)
    super.init(self, data, options)
    self:registerProperty("value", "integer", { default = 5 })
    self:registerProperty("accurate_hitbox", "boolean", { name = "Accurate Hitbox", default = true })
end

function EditorCoinBowl:createObject(map, context)
    return CoinBowl(self.data.x, self.data.y, self.data.properties)
end

return EditorCoinBowl
