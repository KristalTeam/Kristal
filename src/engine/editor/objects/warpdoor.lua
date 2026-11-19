---@class EditorWarpDoor : EditorObject
---@overload fun(data?: table, options?: table): EditorWarpDoor
local EditorWarpDoor, super = Class(EditorObject)
EditorWarpDoor.scaling_mode = "scale"
EditorWarpDoor.fixed_shape = "rectangle"
EditorWarpDoor.getPropertyBounds = EditorObject.getSpriteBounds

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
        indexed = true
    })
    destinations:registerProperty("map", "chooser", {
        choices = Registry.editor_properties:registryChoices({ "maps", "map_data" })
    })
    destinations:registerProperty("name", "string")
    destinations:registerProperty("marker", "object_reference", {
        allowed_types = { "marker", "player" }, target_map_property = "map", map_id = options.map_id
    })
    destinations:registerProperty("flag", "string")
end
function EditorWarpDoor:createObject(map, context)
    return WarpDoor(self.data.x, self.data.y, self.data.properties)
end

---@param map_data table?
function EditorWarpDoor:convertLegacyBounds(map_data)
    local old_x, old_y = self.data.x or 0, self.data.y or 0
    super.convertLegacyBounds(self, map_data)
    if self.data.gid or self.data.tileset and self.data.tile_id ~= nil then return end
    local width, height = self:getBounds()
    local x = old_x - width / 2 * math.cos(self.rotation) + height * math.sin(self.rotation)
    local y = old_y - width / 2 * math.sin(self.rotation) - height * math.cos(self.rotation)
    self.x = self.x + x - (self.data.x or 0)
    self.y = self.y + y - (self.data.y or 0)
    self.data.x, self.data.y = x, y
end

return EditorWarpDoor
