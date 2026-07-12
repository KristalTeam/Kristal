local EditorTransition, super = Class(EditorEvent)

EditorTransition.editor_sprite = "editor/transition"
EditorTransition.placement_shape = "region"
function EditorTransition:init(data, options)
    super.init(self, data, options)
    self:registerProperty("map", "chooser", {
        choices = Registry.editor_properties:registryChoices({ "maps", "map_data" }, { optional = true })
    })
    self:registerProperty("shop", "string")
    self:registerProperty("x", "number")
    self:registerProperty("y", "number")
    self:registerProperty("marker", "object_reference", {
        marker = true, target_map_property = "map"
    })
    self:registerProperty("facing", "choice", { choices = { "up", "down", "left", "right" } })
    self:registerProperty("sound", "string")
    self:registerProperty("pitch", "number", { default = 1 })
    self:registerProperty("exit_delay", "number", { name = "Exit Delay" })
    self:registerProperty("exit_sound", "string", { name = "Exit Sound" })
    self:registerProperty("exit_pitch", "number", { name = "Exit Pitch", default = 1 })
end

return EditorTransition
