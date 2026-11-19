--- Represents a legacy registered event that has no associated EditorObject.
---@class EditorLegacyObject : EditorObject
---@overload fun(data?: table, options?: table): EditorLegacyObject
local EditorLegacyObject = Class(EditorObject)

EditorLegacyObject.sprite_property = "sprite"

function EditorLegacyObject:createObject(map, context)
    return Registry.createLegacyEvent(self.id, self.data)
end

return EditorLegacyObject
