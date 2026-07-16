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
    self:registerProperty("sound", "asset_path", {
        asset_registry = "sound_data", path_root = "assets/sounds",
        strip_extension = true, extensions = { "wav", "ogg" }
    })
    self:registerProperty("pitch", "number", { default = 1 })
    self:registerProperty("exit_delay", "number", { name = "Exit Delay" })
    self:registerProperty("exit_sound", "asset_path", {
        name = "Exit Sound", asset_registry = "sound_data",
        path_root = "assets/sounds", strip_extension = true, extensions = { "wav", "ogg" }
    })
    self:registerProperty("exit_pitch", "number", { name = "Exit Pitch", default = 1 })
end

function EditorTransition:createObject(map, context)
    return Transition(self.data.x, self.data.y, self:getShapeData(), self.data.properties)
end

return EditorTransition
