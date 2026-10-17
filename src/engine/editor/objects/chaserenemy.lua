---@class EditorChaserEnemy : EditorObject
---@overload fun(data?: table, options?: table): EditorChaserEnemy
local EditorChaserEnemy, super = Class(EditorObject)
EditorChaserEnemy.editor_sprite = "editor/enemy"
EditorChaserEnemy.scaling_mode = "scale"
EditorChaserEnemy.fixed_shape = "rectangle"
EditorChaserEnemy.getPropertyBounds = EditorNPC.getPropertyBounds

EditorChaserEnemy.getEditorSprite = EditorNPC.getEditorSprite
EditorChaserEnemy.convertLegacyBounds = EditorNPC.convertLegacyBounds
function EditorChaserEnemy:init(data, options)
    super.init(self, data, options)
    self:registerProperty("actor", "chooser", {
        choices = Registry.editor_properties:registryChoices("actors")
    })
    self:registerProperty("sprite", "string")
    self:registerProperty("animation", "string")
    self:registerProperty("facing", "choice", { choices = { "up", "down", "left", "right" } })
    self:registerProperty("encounter", "chooser", {
        choices = Registry.editor_properties:registryChoices("encounters", { optional = true })
    })
    self:registerProperty("enemy", "chooser", {
        choices = Registry.editor_properties:registryChoices("enemies", { optional = true })
    })
    self:registerProperty("group", "string")
    self:registerProperty("path", "string")
    self:registerProperty("speed", "number", { default = 6 })
    self:registerProperty("progress", "number")
    self:registerProperty("chase", "boolean")
    self:registerProperty("chasing", "boolean")
    self:registerProperty("chasedist", "number", { name = "Chase Distance", default = 200 })
    self:registerProperty("chasetype", "choice", {
        name = "Chase Type", default = "linear", choices = { "linear", "flee", "multiplier" }
    })
    self:registerProperty("chasespeed", "number", { name = "Chase Speed", default = 9 })
    self:registerProperty("chasemax", "number", { name = "Chase Maximum" })
    self:registerProperty("chaseaccel", "number", { name = "Chase Acceleration" })
    self:registerProperty("pacetype", "choice", {
        name = "Pace Type", choices = { "wander", "randomwander", "verticalswing", "horizontalswing" }
    })
    self:registerProperty("paceinterval", "number", { name = "Pace Interval", default = 24 })
    self:registerProperty("marker", "table", {
        name = "Patrol Markers", array = true, entry_type = "object_reference",
        entry_options = { allowed_types = { "marker", "player" }, map_id = self.map_id }
    })
    self:registerProperty("pacereturn", "boolean", { name = "Pace Return", default = true })
    self:registerProperty("pacespeed", "number", { name = "Pace Speed", default = 4 })
    self:registerProperty("swingdiv", "number", { name = "Swing Divisor", default = 24 })
    self:registerProperty("swinglength", "number", { name = "Swing Length", default = 400 })
    self:registerProperty("once", "boolean")
    self:registerProperty("aura", "boolean", { default = true })
end

function EditorChaserEnemy:createObject(map, context)
    local x, y = self:getCharacterPosition(map)
    return ChaserEnemy(self.data.properties.actor, x, y, self.data.properties)
end

return EditorChaserEnemy
