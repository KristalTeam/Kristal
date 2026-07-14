---@class EditorToolbar : EditorControl
---@overload fun(editor: table): EditorToolbar
local EditorToolbar, super = Class(EditorControl)

function EditorToolbar:init(editor)
    super.init(self, 0, 0, 800, 40)
    self.editor = editor
    self.buttons = {}
    for _, tool in ipairs(editor.tool_registry:getAll()) do
        local id = tool.id
        local button
        button = self:addChild(EditorToolButton(tool, function()
            if id == "shape" then
                local items = {}
                for _, mode in ipairs(editor:getShapeModes()) do
                    local shape_mode = mode.id
                    table.insert(items, {
                        label = mode.name,
                        checked = editor.shape_mode == shape_mode,
                        action = function() editor:setShapeMode(shape_mode) end
                    })
                end
                local x, y = button:getGlobalPosition()
                editor.dockspace:openContextMenu(items, x, y + button.height, button)
            else
                editor:setActiveTool(id)
            end
        end))
        button.tool_id = id
        table.insert(self.buttons, button)
    end
    self.undo_button = self:addChild(EditorToolButton({
        id = "undo", name = "Undo", icon = "editor/ui/tool/undo"
    }, function() editor:undo() end))
    self.redo_button = self:addChild(EditorToolButton({
        id = "redo", name = "Redo", icon = "editor/ui/tool/redo"
    }, function() editor:redo() end))
end

function EditorToolbar:update(dt)
    local x, height = 6, math.max(24, self.height - 8)
    self.hovered_tool = nil
    local mouse_x, mouse_y = self.editor:getMousePosition()
    for _, button in ipairs(self.buttons) do
        if button.tool_id == "shape" then
            for _, mode in ipairs(self.editor:getShapeModes()) do
                if mode.id == self.editor.shape_mode then
                    button.tool.icon = mode.icon
                    button.label = "Shape: " .. mode.name
                    break
                end
            end
        end
        local width = 28
        button:setBounds(x, 4, width, height)
        button.focused = self.editor.active_tool == button.tool_id
        if button:containsPoint(mouse_x, mouse_y) then self.hovered_tool = button.tool end
        x = x + width + 5
    end
    self.tooltip_x = x + 5
    local history_width, gap = 28, 5
    self.redo_button:setBounds(math.max(x, self.width - history_width - 6), 4, history_width, height)
    self.undo_button:setBounds(math.max(x, self.redo_button.x - history_width - gap), 4, history_width, height)
    self.undo_button.enabled = self.editor:canUndo()
    self.redo_button.enabled = self.editor:canRedo()
    local undo_label = self.editor:getUndoLabel()
    local redo_label = self.editor:getRedoLabel()
    self.undo_button.tool.name = undo_label and ("Undo " .. undo_label) or "Undo"
    self.redo_button.tool.name = redo_label and ("Redo " .. redo_label) or "Redo"
    if self.undo_button:containsPoint(mouse_x, mouse_y) then
        self.hovered_tool = self.undo_button.tool
    elseif self.redo_button:containsPoint(mouse_x, mouse_y) then
        self.hovered_tool = self.redo_button.tool
    end
    super.update(self, dt)
end

function EditorToolbar:drawSelf()
    Draw.setColor(0.10, 0.10, 0.12, 1)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    if self.hovered_tool then
        local font = EditorFont.get(16)
        love.graphics.setFont(font)
        Draw.setColor(0.78, 0.78, 0.82, 1)
        local label = self.hovered_tool.name
        if self.hovered_tool.id == "shape" then
            label = label .. ": " .. StringUtils.titleCase(self.editor.shape_mode)
        end
        if self.hovered_tool.keybind then
            label = label .. " (" .. Input.getText(self.hovered_tool.keybind, false) .. ")"
        end
        love.graphics.print(label, self.tooltip_x or 8,
            math.floor((self.height - font:getHeight()) / 2))
    end
end

return EditorToolbar
