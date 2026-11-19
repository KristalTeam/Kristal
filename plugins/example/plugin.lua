---@class ExamplePlugin : EditorPlugin
---@overload fun(info: table): ExamplePlugin
local ExamplePlugin, super = Class(EditorPlugin)

function ExamplePlugin:init(info)
    super.init(self, info)
end

function ExamplePlugin:onInit(editor)
    local HelpDirectory = self:require("scripts.controls.helpdirectory")

    local panel = self:registerPanel("help_directory", "Help Directory", function()
        return HelpDirectory(self)
    end, {
        region = "right",
        visible = false,
        preferred_width = 360,
        preferred_height = 260
    })

    self:registerMenuItem("help", "show_help_directory", "Show Very Helpful", {
        on_activate = function()
            if panel.panel then
                editor.dockspace:setPanelVisible(panel.panel, true, panel.panel.last_region or "right")
                if panel.panel.stack then panel.panel.stack:setActivePanel(panel.panel) end
                editor.dockspace:setFocus(panel.panel.content)
            end
        end
    })

    self:registerWorkspace("help", "Help", function(active_editor)
        local layout = active_editor:getDefaultPanelLayout()
        local right = layout.regions.right
        right.stacks = right.stacks or {}
        right.stacks[1] = right.stacks[1] or { id = "right", panels = {} }
        layout.panels[panel.panel_id] = { visible = true, last_region = right.stacks[1].id }
        table.insert(right.stacks[1].panels, panel.panel_id)
        right.stacks[1].active = panel.panel_id
        return layout
    end)
end

return ExamplePlugin
