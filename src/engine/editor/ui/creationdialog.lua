---@class EditorCreationDialog : EditorControl
---@field editor Editor
---@field title string
---@field templates table[]
---@field common_fields table[]
---@field context table
---@field on_create function?
---@field on_cancel function?
---@field template_list EditorItemList
---@field search EditorSearchBar
---@field form EditorControl
---@field scrollbar EditorScrollbar
---@field create_button EditorButton
---@field cancel_button EditorButton
---@field error_label DialogLabel
---@field field_tooltip DialogFieldTooltip
---@field inputs table<string, EditorControl>
---@field focusables EditorControl[]
---@field form_rows table[]
---@field template_values table
---@field template table?
---@field focused_control EditorControl?
---@field captured_control EditorControl?
---@field error_message string?
---@field form_scroll number
---@field form_content_height number
---@field panel_x number
---@field panel_y number
---@field panel_width number
---@field panel_height number
---@overload fun(editor: Editor, options: table): EditorCreationDialog
local EditorCreationDialog, super = Class(EditorControl)

---@class DialogLabel : EditorControl
---@field label string
---@field description string?
---@field header boolean
---@field code_name string?
---@overload fun(label: string, description?: string, header?: boolean, code_name?: string): DialogLabel
local DialogLabel, label_super = Class(EditorControl)

function DialogLabel:init(label, description, header, code_name)
    label_super.init(self, 0, 0, 170, description and 48 or 30)
    self.label = label
    self.description = description
    self.header = header == true
    self.code_name = code_name
end

function DialogLabel:drawSelf()
    local font = EditorFont.get(self.header and 20 or 16)
    love.graphics.setFont(font)
    Draw.setColor(self.header and { 0.78, 0.84, 0.96, 1 } or { 0.90, 0.90, 0.93, 1 })
    love.graphics.print(self.label, 0, self.header and 2 or 5)
    if self.description then
        love.graphics.setFont(EditorFont.get(14))
        Draw.setColor(0.58, 0.59, 0.64, 1)
        love.graphics.printf(self.description, 0, 25, self.width)
    end
end

---@class DialogFieldTooltip : EditorControl
---@field code_name string?
---@field prefix string
---@overload fun(): DialogFieldTooltip
local DialogFieldTooltip, tooltip_super = Class(EditorControl)

function DialogFieldTooltip:init()
    tooltip_super.init(self, 0, 0, 0, 26)
    self.enabled = false
    self.visible = false
end

function DialogFieldTooltip:setCodeName(code_name, x, y, maximum_width, maximum_height)
    self.code_name = tostring(code_name)
    local font = EditorFont.get(14)
    local prefix = ""
    self.prefix = prefix
    self.width = font:getWidth(prefix .. self.code_name) + 16
    self.x = MathUtils.clamp(x, 4, math.max(4, maximum_width - self.width - 4))
    self.y = MathUtils.clamp(y, 4, math.max(4, maximum_height - self.height - 4))
    self.visible = true
end

function DialogFieldTooltip:drawSelf()
    love.graphics.setLineWidth(1)
    Draw.setColor(0.075, 0.075, 0.09, 0.98)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height, 3)
    Draw.setColor(0.42, 0.48, 0.62, 1)
    love.graphics.rectangle("line", 0.5, 0.5, self.width - 1, self.height - 1, 3)
    local font = EditorFont.get(14)
    love.graphics.setFont(font)
    Draw.setColor(0.68, 0.69, 0.74, 1)
    love.graphics.print(self.prefix, 8, 5)
    Draw.setColor(0.52, 0.72, 1, 1)
    love.graphics.print(self.code_name, 8 + font:getWidth(self.prefix), 5)
end

---@class DialogChoice : EditorButton
---@field field table
---@field choices table[]
---@field value any
---@field on_changed function?
---@overload fun(field: table, value?: any, on_changed?: function): DialogChoice
local DialogChoice, choice_super = Class(EditorButton)

function DialogChoice:init(field, value, on_changed)
    self.field = field
    self.choices = type(field.choices) == "function" and field.choices(field) or field.choices or {}
    self.value = value
    choice_super.init(self, "", function() self:step(1) end)
    self.on_changed = on_changed
    self:updateLabel()
end

---@class DialogVector : EditorControl
---@field field table
---@field size number
---@field value table?
---@field on_changed function?
---@field inputs EditorTextInput[]
---@field labels string[]
---@overload fun(field: table, value?: table, on_changed?: function): DialogVector
local DialogVector, vector_super = Class(EditorControl)

function DialogVector:init(field, value, on_changed)
    vector_super.init(self, 0, 0, 260, 28)
    self.field = field
    self.size = field.size or (field.type == "vector4" and 4 or 2)
    self.value = type(value) == "table" and TableUtils.copy(value, true) or nil
    self.on_changed = on_changed
    self.inputs = {}
    local labels = field.components or (self.size == 4 and { "X", "Y", "W", "H" } or { "X", "Y" })
    self.labels = labels
    for index = 1, self.size do
        local component = index
        local input = self:addChild(EditorTextInput({
            value = self.value and self.value[index] or "", submit_feedback = false,
            on_changed = function(text)
                local candidate, any = {}, false
                for input_index, candidate_input in ipairs(self.inputs) do
                    local component_value = input_index == component and text or candidate_input.value
                    if component_value ~= "" then any = true candidate[input_index] = component_value end
                end
                self.value = any and candidate or nil
                if self.on_changed then self.on_changed(self.value, self) end
            end
        }))
        table.insert(self.inputs, input)
    end
end

function DialogVector:update(dt)
    local gap, label_width = 6, 14
    local width = math.max(36, (self.width - gap * (self.size - 1)) / self.size)
    for index, input in ipairs(self.inputs) do
        local x = (index - 1) * (width + gap)
        input:setBounds(x + label_width, 0, math.max(20, width - label_width), 28)
    end
    vector_super.update(self, dt)
end

function DialogVector:drawSelf()
    love.graphics.setFont(EditorFont.get(14))
    Draw.setColor(0.62, 0.64, 0.70, 1)
    local gap = 6
    local width = math.max(36, (self.width - gap * (self.size - 1)) / self.size)
    for index, label in ipairs(self.labels) do
        love.graphics.print(label, (index - 1) * (width + gap), 6)
    end
end

function DialogChoice:getChoiceValue(choice)
    if type(choice) == "table" then return choice.value ~= nil and choice.value or choice.id end
    return choice
end

function DialogChoice:getChoiceLabel(choice)
    if type(choice) == "table" then return tostring(choice.label or choice.name or self:getChoiceValue(choice)) end
    return tostring(choice)
end

function DialogChoice:updateLabel()
    local label = tostring(self.value or "")
    for _, choice in ipairs(self.choices) do
        if tostring(self:getChoiceValue(choice)) == tostring(self.value) then
            label = self:getChoiceLabel(choice)
            break
        end
    end
    self.label = "<  " .. label .. "  >"
end

function DialogChoice:step(direction)
    if #self.choices == 0 then return false end
    local index = 1
    for candidate, choice in ipairs(self.choices) do
        if tostring(self:getChoiceValue(choice)) == tostring(self.value) then index = candidate break end
    end
    index = ((index - 1 + direction) % #self.choices) + 1
    self.value = self:getChoiceValue(self.choices[index])
    self:updateLabel()
    if self.on_changed then self.on_changed(self.value, self) end
    return true
end

function DialogChoice:onKeyPressed(key)
    if key == "left" then return self:step(-1) end
    if key == "right" then return self:step(1) end
    return choice_super.onKeyPressed(self, key)
end

function EditorCreationDialog:init(editor, options)
    local ui_width, ui_height = editor:getUIDimensions()
    super.init(self, 0, 0, ui_width, ui_height)
    self.editor = editor
    self.title = options.title or "Create"
    self.templates = options.templates or {}
    self.common_fields = options.fields or {}
    self.context = options.context or {}
    self.on_create = options.on_create
    self.on_cancel = options.on_cancel
    self.template_values = {}
    self.form_rows = {}
    self.focusables = {}
    self.form_scroll = 0
    self.focused_control = nil
    self.captured_control = nil

    self.search = self:addChild(EditorSearchBar({
        placeholder = "Search templates...",
        on_changed = function(value) self.template_list:setFilter(value) end
    }))
    self.template_list = self:addChild(EditorItemList({
        on_select = function(item) if item then self:selectTemplate(item.data) end end,
        on_request_focus = function(control) self:setFocus(control) end
    }))
    self.form = self:addChild(EditorControl())
    self.form.clip = true
    self.scrollbar = self:addChild(EditorScrollbar({
        on_changed = function(value) self:setScrollValue(value) end
    }))
    self.error_label = self:addChild(DialogLabel("", nil, false))
    self.error_label.visible = false
    self.create_button = self:addChild(EditorButton(options.create_label or "Create", function() self:submit() end))
    self.cancel_button = self:addChild(EditorButton("Cancel", function() self:cancel() end))
    self.field_tooltip = self:addChild(DialogFieldTooltip())

    local items = {}
    for _, definition in ipairs(self.templates) do
        table.insert(items, {
            id = definition.id,
            label = definition.category .. " / " .. definition.name,
            data = definition
        })
    end
    table.sort(items, function(a, b) return a.label:lower() < b.label:lower() end)
    self.template_list:setItems(items)
    if items[1] then
        local selected = 1
        for index, item in ipairs(items) do
            if item.id == options.initial_template_id then selected = index break end
        end
        self.template_list:select(selected)
        self:selectTemplate(items[selected].data)
        self:setFocus(#items > 1 and self.search or self.focusables[1])
    end
end

function EditorCreationDialog:setFocus(control)
    if self.focused_control == control then return end
    if self.focused_control then self.focused_control:onBlur() end
    self.focused_control = control
    if control then control:onFocus() end
end

function EditorCreationDialog:getValues(definition)
    local values = self.template_values[definition.id]
    if values then return values end
    values = { _methods = {} }
    for _, field in ipairs(definition.variables or {}) do
        local override = self.context.defaults and self.context.defaults[field.id]
        values[field.id] = override ~= nil and override
            or EditorTemplateRegistry.defaultValue(field, values, self.context, definition)
    end
    for _, method in ipairs(definition.methods or {}) do values._methods[method.id] = method.default == true end
    for _, field in ipairs(self.common_fields) do
        local override = self.context.defaults and self.context.defaults[field.id]
        values[field.id] = override ~= nil and override
            or EditorTemplateRegistry.defaultValue(field, values, self.context, definition)
    end
    self.template_values[definition.id] = values
    return values
end

function EditorCreationDialog:addRow(field, value, on_changed)
    local height = field.description and 50 or 34
    local code_name = field.code_name == false and nil or (field.code_name or field.id)
    local label = self.form:addChild(DialogLabel(field.name or field.id, field.description, false, code_name))
    local control
    if field.type == "boolean" then
        control = self.form:addChild(EditorCheckbox("", value == true, on_changed))
    elseif field.type == "choice" then
        control = self.form:addChild(DialogChoice(field, value, on_changed))
    elseif field.type == "color" then
        control = self.form:addChild(EditorColorInput(self.editor, value, {
            on_submit = on_changed
        }))
    elseif field.control == "path" or field.type == "asset_path" or field.type == "script_path" then
        local options = TableUtils.copy(Registry.getEditorPropertyType(field.type or "string"), true)
        for key, option in pairs(field) do options[key] = option end
        options.on_submit = on_changed
        control = self.form:addChild(EditorPathInput(self.editor, value, options))
    elseif field.type == "asset_path_list" then
        local options = TableUtils.copy(field, true)
        options.on_changed = on_changed
        options.on_request_focus = function(input) self:setFocus(input) end
        control = self.form:addChild(EditorPathListInput(self.editor, value, options))
        height = math.max(height, (control.preferred_height or 120) + 6)
    elseif field.type == "table" then
        control = self.form:addChild(EditorTableInput(self.editor, value, {
            maximum_visible_rows = field.maximum_visible_rows or 4,
            on_changed = on_changed,
            on_request_focus = function(input) self:setFocus(input) end
        }))
        height = math.max(height, (control.preferred_height or 120) + 6)
    elseif field.type == "vector2" or field.type == "vector4" or field.type == "vector" then
        control = self.form:addChild(DialogVector(field, value, on_changed))
    elseif field.type == "value" then
        local display = type(value) == "table" and Registry.editor_properties:formatValue(value)
            or value == nil and "" or tostring(value)
        control = self.form:addChild(EditorTextInput({
            value = display, editor = self.editor, multiline = true,
            submit_feedback = false, on_changed = on_changed
        }))
        height = math.max(height, field.height or 82)
    else
        control = self.form:addChild(EditorTextInput({
            value = value == nil and "" or tostring(value), editor = self.editor,
            multiline = field.multiline == true,
            submit_feedback = false, on_changed = on_changed
        }))
        if field.multiline then height = math.max(height, field.height or 82) end
    end
    table.insert(self.form_rows, {
        label = label, control = control, height = height, minimum_height = height, field = field
    })
    if control.focusable then
        table.insert(self.focusables, control)
    elseif control.inputs and control.inputs[1] then
        table.insert(self.focusables, control.inputs[1])
    elseif control.add_button then
        table.insert(self.focusables, control.add_button)
    end
end

function EditorCreationDialog:selectTemplate(definition)
    if self.template == definition and #self.form_rows > 0 then return end
    self:setFocus(nil)
    self.template = definition
    self.form.children = {}
    self.form_rows = {}
    self.focusables = {}
    self.form_scroll = 0
    self.error_message = nil
    local values = self:getValues(definition)
    for _, field in ipairs(self.common_fields) do
        self:addRow(field, values[field.id], function(value) values[field.id] = value end)
    end
    for _, field in ipairs(definition.variables or {}) do
        self:addRow(field, values[field.id], function(value) values[field.id] = value end)
    end
    if #(definition.methods or {}) > 0 then
        local header = self.form:addChild(DialogLabel("Method Overrides", nil, true))
        table.insert(self.form_rows, { label = header, height = 34, header = true })
        for _, override in ipairs(definition.methods) do
            local method_id = override.id
            local field = { id = method_id, name = override.name or method_id, type = "boolean", code_name = false }
            self:addRow(field, values._methods[override.id], function(value)
                values._methods[method_id] = value
            end)
        end
    end
    self:layoutForm()
end

function EditorCreationDialog:setScrollValue(value)
    local maximum = math.max(0, self.form_content_height - self.form.height)
    self.form_scroll = maximum * value
    self:layoutForm()
end

function EditorCreationDialog:layoutForm()
    if not self.form then return end
    local y = 4 - self.form_scroll
    local input_x = math.min(190, math.floor(self.form.width * 0.42))
    for _, row in ipairs(self.form_rows) do
        if row.field and (row.field.type == "table" or row.field.type == "asset_path_list") then
            row.height = math.max(row.minimum_height or 0, (row.control.preferred_height or 90) + 6)
        end
        row.label:setBounds(6, y, math.max(80, input_x - 14), row.height)
        if row.control then
            local control_height = row.field
                and (row.field.type == "table" or row.field.type == "asset_path_list") and row.height - 6
                or row.field and (row.field.type == "value" or row.field.multiline) and row.height - 6 or 28
            row.control:setBounds(input_x, y + 2, math.max(80, self.form.width - input_x - 8), control_height)
        end
        y = y + row.height
    end
    self.form_content_height = y + self.form_scroll + 4
    local maximum = math.max(0, self.form_content_height - self.form.height)
    self.form_scroll = MathUtils.clamp(self.form_scroll, 0, maximum)
    self.scrollbar.visible = maximum > 0
    self.scrollbar.page = self.form.height / math.max(self.form.height, self.form_content_height)
    self.scrollbar:setValue(maximum > 0 and self.form_scroll / maximum or 0, true)
end

function EditorCreationDialog:update(dt)
    self:setBounds(0, 0, self.editor:getUIDimensions())
    local width = math.min(780, self.width - 48)
    local height = math.min(620, self.height - 48)
    self.panel_x = math.floor((self.width - width) / 2)
    self.panel_y = math.floor((self.height - height) / 2)
    self.panel_width, self.panel_height = width, height
    local multiple = #self.templates > 1
    local left_width = multiple and 235 or 0
    self.search.visible = multiple
    self.template_list.visible = multiple
    self.search:setBounds(self.panel_x + 16, self.panel_y + 54, left_width - 26, 28)
    self.template_list:setBounds(self.panel_x + 16, self.panel_y + 88, left_width - 26, height - 158)
    local form_x = self.panel_x + 18 + left_width
    local form_width = width - left_width - 36
    self.form:setBounds(form_x, self.panel_y + 58, form_width - 12, height - 142)
    self.scrollbar:setBounds(form_x + form_width - 10, self.panel_y + 58, 10, height - 142)
    self.error_label:setBounds(form_x, self.panel_y + height - 78, form_width, 22)
    self.create_button:setBounds(self.panel_x + width - 220, self.panel_y + height - 46, 96, 30)
    self.cancel_button:setBounds(self.panel_x + width - 114, self.panel_y + height - 46, 96, 30)
    self:layoutForm()
    super.update(self, dt)
    self:updateFieldTooltip()
end

function EditorCreationDialog:updateFieldTooltip()
    self.field_tooltip.visible = false
    local mouse_x, mouse_y = self.editor:getMousePosition()
    local target = self:getControlAt(mouse_x, mouse_y)
    while target and target ~= self do
        if target.code_name then
            local _, local_y = target:toLocal(mouse_x, mouse_y)
            if local_y >= 0 and local_y < 25 then
                local dialog_x, dialog_y = self:toLocal(mouse_x, mouse_y)
                self.field_tooltip:setCodeName(target.code_name, dialog_x + 12, dialog_y + 14,
                    self.width, self.height)
            end
            return
        end
        target = target.parent
    end
end

function EditorCreationDialog:submit()
    local definition = self.template
    if not definition then return false end
    local values = self:getValues(definition)
    for _, field in ipairs(self.common_fields) do
        local value, reason = EditorTemplateRegistry.coerce(field, values[field.id])
        if value == nil and reason then self.error_message = reason return false end
        values[field.id] = value
    end
    for _, field in ipairs(definition.variables or {}) do
        local value, reason = EditorTemplateRegistry.coerce(field, values[field.id])
        if value == nil and reason then self.error_message = reason return false end
        values[field.id] = value
    end
    local success, reason = self.on_create and self.on_create(values, definition, self.context)
    if success == false or success == nil then
        self.error_message = reason or "Could not create " .. definition.name:lower()
        return false
    end
    self.editor:closeCreationDialog(true)
    return true
end

function EditorCreationDialog:cancel()
    if self.on_cancel then self.on_cancel(self) end
    self.editor:closeCreationDialog(false)
    return true
end

function EditorCreationDialog:onKeyPressed(key, is_repeat)
    if key == "escape" then return self:cancel() end
    if key == "tab" then
        local focusables = {}
        for _, control in ipairs(self.focusables) do table.insert(focusables, control) end
        table.insert(focusables, self.create_button)
        table.insert(focusables, self.cancel_button)
        local index = 0
        for candidate, control in ipairs(focusables) do if control == self.focused_control then index = candidate break end end
        local direction = Input.shift() and -1 or 1
        index = ((index - 1 + direction) % #focusables) + 1
        self:setFocus(focusables[index])
        return true
    end
    if (key == "return" or key == "kpenter") and not is_repeat
        and self.focused_control and self.focused_control.accepts_text_input
        and not self.focused_control.multiline then
        self.focused_control:onKeyPressed(key, is_repeat)
        return self:submit()
    end
    if self.focused_control and self.focused_control:onKeyPressed(key, is_repeat) then return true end
    if (key == "return" or key == "kpenter") and not is_repeat then return self:submit() end
    return true
end

function EditorCreationDialog:onKeyReleased(key)
    if self.focused_control then self.focused_control:onKeyReleased(key) end
    return true
end

function EditorCreationDialog:onTextInput(text)
    if self.focused_control then self.focused_control:onTextInput(text) end
    return true
end

function EditorCreationDialog:onMousePressed(x, y, button, _, presses)
    local target = self:getControlAt(x, y)
    if target and target ~= self then
        if target.focusable then self:setFocus(target) elseif button == 1 then self:setFocus(nil) end
        local local_x, local_y = target:toLocal(x, y)
        if target:onMousePressed(local_x, local_y, button, presses) then self.captured_control = target end
    elseif button == 1 then
        self:setFocus(nil)
    end
    return true
end

function EditorCreationDialog:onMouseMoved(x, y, dx, dy)
    if self.captured_control then
        local local_x, local_y = self.captured_control:toLocal(x, y)
        self.captured_control:onMouseMoved(local_x, local_y, dx, dy)
    end
    return true
end

function EditorCreationDialog:onMouseReleased(x, y, button, _, presses)
    if self.captured_control then
        local target = self.captured_control
        local local_x, local_y = target:toLocal(x, y)
        target:onMouseReleased(local_x, local_y, button, presses)
        self.captured_control = nil
    end
    return true
end

function EditorCreationDialog:onWheelMoved(x, y)
    local mouse_x, mouse_y = self.editor:getMousePosition()
    local target = self:getControlAt(mouse_x, mouse_y)
    while target and target ~= self do
        if target:onWheelMoved(x, y) then return true end
        target = target.parent
    end
    if self.form:containsPoint(mouse_x, mouse_y) then
        local maximum = math.max(0, self.form_content_height - self.form.height)
        self.form_scroll = MathUtils.clamp(self.form_scroll - y * 36, 0, maximum)
        self:layoutForm()
    end
    return true
end

function EditorCreationDialog:getCursorType(x, y)
    local target = self:getControlAt(x, y)
    return target and target.cursor_type or "default"
end

function EditorCreationDialog:drawSelf()
    love.graphics.setLineWidth(1)
    Draw.setColor(0, 0, 0, 0.68)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    Draw.setColor(0.105, 0.105, 0.125, 1)
    love.graphics.rectangle("fill", self.panel_x, self.panel_y, self.panel_width, self.panel_height, 4)
    Draw.setColor(0.42, 0.48, 0.62, 1)
    love.graphics.rectangle("line", self.panel_x + 0.5, self.panel_y + 0.5,
        self.panel_width - 1, self.panel_height - 1, 4)
    love.graphics.setFont(EditorFont.get(24))
    Draw.setColor(0.94, 0.94, 0.97, 1)
    love.graphics.print(self.title, self.panel_x + 18, self.panel_y + 15)
    if self.template and self.template.description then
        love.graphics.setFont(EditorFont.get(14))
        Draw.setColor(0.62, 0.64, 0.70, 1)
        love.graphics.printf(self.template.description, self.panel_x + (#self.templates > 1 and 253 or 18),
            self.panel_y + 35, self.panel_width - (#self.templates > 1 and 270 or 36), "left")
    end
    if self.error_message then
        Draw.setColor(0.90, 0.34, 0.34, 1)
        love.graphics.setFont(EditorFont.get(14))
        love.graphics.print(self.error_message, self.error_label.x, self.error_label.y)
    end
end

return EditorCreationDialog
