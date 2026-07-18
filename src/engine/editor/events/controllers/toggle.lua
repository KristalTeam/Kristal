---@class EditorToggleController : EditorEvent
---@overload fun(data?: table, options?: table): EditorToggleController
local EditorToggleController, super = Class(EditorEvent)

EditorToggleController.runtime_type = "controller"

function EditorToggleController:init(data, options)
    super.init(self, data, options)
    self:registerProperty("flag", "string")
    self:registerProperty("inverted", "boolean")
    self:registerProperty("value", "value")
    local found_target = false
    for name in pairs(self.properties) do
        if name:match("^target%d*$") then
            self:registerProperty(name, "object_reference", { name = StringUtils.titleCase(name) })
            found_target = true
        end
    end
    if not found_target then self:registerProperty("target", "object_reference", { name = "Target" }) end
end

function EditorToggleController:createObject(map, context)
    return ToggleController(self.data.properties)
end

return EditorToggleController
