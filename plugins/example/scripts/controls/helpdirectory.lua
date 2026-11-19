---@class ExamplePluginHelpDirectory : EditorControl
---@field plugin EditorPlugin
---@overload fun(plugin: EditorPlugin): ExamplePluginHelpDirectory
local HelpDirectory, super = Class(EditorControl)

function HelpDirectory:init(plugin)
    super.init(self, 0, 0, 360, 260)
    self.plugin = plugin
    self.focusable = true
end

function HelpDirectory:drawSelf()
    local font = EditorFont.get(16)
    love.graphics.setFont(font)

    Draw.setColor(0.09, 0.09, 0.11, 1)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)

    Draw.setColor(0.72, 0.86, 1, 1)
    love.graphics.print("Example Editor Plugin", 16, 14)

    Draw.setColor(0.68, 0.68, 0.72, 1)
    love.graphics.printf(
        "uwaa... so helpful!",
        16, 108, math.max(0, self.width - 32), "left")

    Draw.setColor(0.52, 0.58, 0.66, 1)
    love.graphics.print("Plugin ID: " .. self.plugin.id, 16, self.height - font:getHeight() - 14)
    Draw.setColor(1, 1, 1, 1)
end

return HelpDirectory
