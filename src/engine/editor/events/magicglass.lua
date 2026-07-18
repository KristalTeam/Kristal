---@class EditorMagicGlass : EditorEvent
---@overload fun(data?: table, options?: table): EditorMagicGlass
local EditorMagicGlass, super = Class(EditorEvent)
function EditorMagicGlass:getEditorSprite(data)
    return data.properties.new_sprite and "world/events/magical_glass_new"
        or "world/events/magical_glass"
end
function EditorMagicGlass:init(data, options)
    super.init(self, data, options)
    self:registerProperty("new_sprite", "boolean", { name = "New Sprite" })
end
function EditorMagicGlass:createObject(map, context)
    return MagicGlass(self.data.x, self.data.y, self:getRectData(), self.data.properties)
end

return EditorMagicGlass
