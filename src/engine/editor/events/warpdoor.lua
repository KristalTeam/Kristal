---@class EditorWarpDoor : EditorEvent
---@overload fun(data?: table, options?: table): EditorWarpDoor
local EditorWarpDoor, super = Class(EditorEvent)
EditorWarpDoor.scaling_mode = "scale"

function EditorWarpDoor:getEditorSprite(data)
    return data.properties.open == false and "world/events/shortcut_door_off"
        or "world/events/shortcut_door"
end

function EditorWarpDoor:init(data, options)
    super.init(self, data, options)
    self:registerProperty("open", "boolean", { default = true })
    self:registerProperty("openflag", "string", { name = "Open Flag" })
    local destinations = self:registerPropertyGroup("destinations", {
        name = "Destination",
        indexed = true,
        primary = "map"
    })
    destinations:registerProperty("map", "chooser", {
        choices = Registry.editor_properties:registryChoices({ "maps", "map_data" })
    })
    destinations:registerProperty("name", "string")
    destinations:registerProperty("marker", "object_reference", {
        allowed_types = { "marker" }, target_map_property = "map", map_id = options.map_id
    })
    destinations:registerProperty("flag", "string")
end
function EditorWarpDoor:createObject(map, context)
    return WarpDoor(self.data.x, self.data.y, self.data.properties)
end

return EditorWarpDoor
