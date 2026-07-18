--- Displays map tools and shared editing actions.
---@class EditorToolbar : EditorControl
---@field brush_label_x number
---@field brush_size_down EditorButton
---@field brush_size_input EditorTextInput
---@field brush_size_up EditorButton
---@field buttons table
---@field editor Editor
---@field hovered_tool table?
---@field redo_button EditorToolButton
---@field tooltip_x number
---@field undo_button EditorToolButton
---@overload fun(editor: table): EditorToolbar
local EditorToolbar, super = Class(EditorControl)

function EditorToolbar:openToolMenu(button, tools)
    local items = {}
    for _, member in ipairs(tools) do
        local tool = member
        table.insert(items, {
            label = tool.name,
            checked = self.editor.active_tool == tool.id,
            action = function() self.editor:setActiveTool(tool.id) end
        })
    end
    local x, y = button:getGlobalPosition()
    return self.editor.dockspace:openContextMenu(items, x, y + button.height, button)
end

function EditorToolbar:init(editor)
    super.init(self, 0, 0, 800, 40)
    self.editor = editor
    self.buttons = {}
    local entries, groups = {}, {}
    for _, tool in ipairs(editor.tool_registry:getAll()) do
        if tool.toolbar_group then
            local entry = groups[tool.toolbar_group]
            if not entry then
                entry = { id = tool.toolbar_group, tools = {} }
                groups[tool.toolbar_group] = entry
                table.insert(entries, entry)
            end
            table.insert(entry.tools, tool)
        else
            table.insert(entries, { tool = tool })
        end
    end
    for _, entry in ipairs(entries) do
        local toolbar_entry = entry
        local tool = entry.tool or entry.tools[1]
        local id = tool.id
        local button
        button = self:addChild(EditorToolButton(tool, function()
            if toolbar_entry.tools then
                self:openToolMenu(button, toolbar_entry.tools)
            elseif id == "shape" then
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
        button.tool_group = toolbar_entry.id
        button.group_tools = toolbar_entry.tools
        table.insert(self.buttons, button)
    end
    self.undo_button = self:addChild(EditorToolButton({
        id = "undo", name = "Undo", icon = "editor/ui/tool/undo"
    }, function() editor:undo() end))
    self.redo_button = self:addChild(EditorToolButton({
        id = "redo", name = "Redo", icon = "editor/ui/tool/redo"
    }, function() editor:redo() end))
    self.brush_size_down = self:addChild(EditorButton("-", function() self:changeBrushSize(-1) end))
    self.brush_size_input = self:addChild(EditorTextInput({
        editor = editor,
        value = tostring(editor:getBrushSize()),
        submit_feedback = false,
        on_submit = function(value) return self:setConfiguredBrushSize(value) end
    }))
    self.brush_size_up = self:addChild(EditorButton("+", function() self:changeBrushSize(1) end))
end

function EditorToolbar:setBrushSize(value)
    value = MathUtils.clamp(MathUtils.round(tonumber(value) or 1), 1, 32)
    if self.brush_size_input then self.brush_size_input:setValue(tostring(value), true) end
end

function EditorToolbar:setConfiguredBrushSize(value)
    value = tonumber(value)
    if not value then
        self:setBrushSize(self.editor:getBrushSize())
        return false
    end
    return self.editor.settings:setValue("editing.brush_size", value)
end

function EditorToolbar:changeBrushSize(amount)
    return self.editor.settings:setValue("editing.brush_size", self.editor:getBrushSize() + amount)
end

function EditorToolbar:update(dt)
    local x, height = 6, math.max(24, self.height - 8)
    self.hovered_tool = nil
    local mouse_x, mouse_y = self.editor:getMousePosition()
    for _, button in ipairs(self.buttons) do
        if button.group_tools then
            button.focused = false
            for _, tool in ipairs(button.group_tools) do
                if tool.id == self.editor.active_tool then
                    button.tool = tool
                    button.label = tool.short_name or tool.name
                    button.tool_id = tool.id
                    button.focused = true
                    break
                end
            end
        elseif button.tool_id == "shape" then
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
        if not button.group_tools then button.focused = self.editor.active_tool == button.tool_id end
        if button:containsPoint(mouse_x, mouse_y) then self.hovered_tool = button.tool end
        x = x + width + 5
    end
    self.brush_label_x = x + 2
    x = x + 39
    self.brush_size_down:setBounds(x, 6, 22, math.max(20, height - 4))
    self.brush_size_input:setBounds(x + 25, 6, 34, math.max(20, height - 4))
    self.brush_size_up:setBounds(x + 62, 6, 22, math.max(20, height - 4))
    x = x + 89
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
    Draw.setColor(0.72, 0.72, 0.76, 1)
    love.graphics.setFont(EditorFont.get(14))
    love.graphics.print("Size", self.brush_label_x or 8,
        math.floor((self.height - EditorFont.get(14):getHeight()) / 2))
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
