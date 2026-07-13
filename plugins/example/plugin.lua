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
end

return ExamplePlugin
