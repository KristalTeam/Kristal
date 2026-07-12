local EditorCyberTrashCan, super = Class(EditorEvent)
EditorCyberTrashCan.editor_sprite = "world/events/cyber_trash"
EditorCyberTrashCan.scaling_mode = "scale"
function EditorCyberTrashCan:init(data, options)
    super.init(self, data, options)
    self:registerProperty("item", "chooser", {
        choices = Registry.editor_properties:registryChoices("items", { optional = true })
    })
    self:registerProperty("money", "integer")
    self:registerProperty("setflag", "string", { name = "Set Flag" })
    self:registerProperty("setvalue", "value", { name = "Set Value" })
end
return EditorCyberTrashCan
