---@class EditorInteractable : EditorEvent
---@overload fun(data?: table, options?: table): EditorInteractable
local EditorInteractable, super = Class(EditorEvent)

EditorInteractable.editor_sprite = "editor/interactable"
function EditorInteractable:init(data, options)
    super.init(self, data, options)
    self:registerProperty("solid", "boolean")
    self:registerProperty("cutscene", "script_path", {
        path_root = "scripts/world/cutscenes", strip_extension = true,
        extensions = { "lua" }, registry = "world_cutscenes"
    })
    self:registerProperty("script", "script_path", {
        path_root = "scripts/world/scripts", strip_extension = true,
        extensions = { "lua" }, registry = "event_scripts"
    })
    self:registerProperty("setflag", "string", { name = "Set Flag" })
    self:registerProperty("setvalue", "value", { name = "Set Value" })
    self:registerProperty("once", "boolean")
    self:registerProperty("usetile", "boolean", { name = "Use Tile" })
end

function EditorInteractable:createObject(map, context)
    return Interactable(self.data.x, self.data.y, self:getShapeData(), self.data.properties)
end

return EditorInteractable
