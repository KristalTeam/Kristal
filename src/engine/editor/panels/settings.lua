--- Displays registered editor settings by page.
---@class EditorSettingsPanel : EditorControl
---@field clip boolean
---@field content_height number
---@field editor Editor
---@field generated_controls table
---@field page table?
---@field pages EditorItemList
---@field registry EditorSettingsRegistry
---@field rows table
---@field scroll_y number
---@field scrollbar EditorScrollbar
---@overload fun(editor: table): EditorSettingsPanel
local EditorSettingsPanel, super = Class(EditorControl)

local function displayKeybind(value)
    if type(value) == "table" then return table.concat(value, " + ") end
    return value and tostring(value) or "Unbound"
end

function EditorSettingsPanel:init(editor)
    super.init(self, 0, 0, 680, 480)
    self.editor = editor
    self.registry = editor.settings
    self.page = nil
    self.generated_controls = {}
    self.rows = {}
    self.scroll_y = 0
    self.content_height = 0
    self.clip = true
    self.pages = self:addChild(EditorItemList({
        row_height = 30,
        on_select = function(item) self:setPage(item and item.data) end,
        on_request_focus = function(control) editor.dockspace:setFocus(control) end
    }))
    self.scrollbar = self:addChild(EditorScrollbar({
        width = 12,
        on_changed = function(value) self.scroll_y = self:getMaxScroll() * value end
    }))
    self:refreshPages()
end

function EditorSettingsPanel:clearControls()
    for _, control in ipairs(self.generated_controls) do self:removeChild(control) end
    self.generated_controls, self.rows = {}, {}
end

function EditorSettingsPanel:addGenerated(control)
    table.insert(self.generated_controls, control)
    return self:addChild(control)
end

function EditorSettingsPanel:refreshPages()
    local items = {}
    for _, page in ipairs(self.registry:getPages()) do
        table.insert(items, { id = page.id, label = page.title, data = page })
    end
    self.pages:setItems(items)
    if #items > 0 then
        self.pages:select(1)
        self:setPage(self.pages:getSelectedItem().data)
    end
end

function EditorSettingsPanel:createKeybindControl(setting)
    local button
    button = EditorButton(displayKeybind(self.registry:getValue(setting.id)), function()
        button.capturing = true
        button.label = "Press a key..."
        self.editor.dockspace:setFocus(button)
    end)
    button.onKeyPressed = function(control, key)
        if not control.capturing then return EditorButton.onKeyPressed(control, key) end
        if key == "escape" then
            control.capturing = false
            control.label = displayKeybind(self.registry:getValue(setting.id))
            return true
        end
        if key == "lctrl" or key == "rctrl" or key == "lshift" or key == "rshift"
            or key == "lalt" or key == "ralt" or key == "lgui" or key == "rgui" then
            return true
        end
        local chord = {}
        if Input.ctrl() then table.insert(chord, "ctrl") end
        if Input.shift() then table.insert(chord, "shift") end
        if Input.alt() then table.insert(chord, "alt") end
        table.insert(chord, key)
        local value = #chord == 1 and chord[1] or chord
        if self.registry:setValue(setting.id, value) then
            control.capturing = false
            control.label = displayKeybind(self.registry:getValue(setting.id))
        end
        return true
    end
    return button
end

function EditorSettingsPanel:createControl(setting)
    local value = self.registry:getValue(setting.id)
    local control
    if setting.type == "boolean" then
        control = EditorCheckbox("", value == true, function(checked)
            self.registry:setValue(setting.id, checked)
        end)
    elseif setting.type == "choice" then
        local button
        local _, current_label = EditorChoiceUtils.find(self.registry:getChoices(setting), value)
        button = EditorButton(current_label or tostring(value or ""), function()
            local items = {}
            for _, choice in ipairs(self.registry:getChoices(setting)) do
                local choice_value = EditorChoiceUtils.getValue(choice)
                table.insert(items, {
                    label = EditorChoiceUtils.getLabel(choice),
                    checked = self.registry:getValue(setting.id) == choice_value,
                    action = function() self.registry:setValue(setting.id, choice_value) end
                })
            end
            local x, y = button:getGlobalPosition()
            self.editor.dockspace:openContextMenu(items, x, y + button.height, button, {
                searchable = #items > 12
            })
        end)
        control = button
    elseif setting.type == "color" then
        control = EditorColorInput(self.editor, value, {
            on_submit = function(color) return self.registry:setValue(setting.id, color) end
        })
    elseif setting.type == "keybind" then
        control = self:createKeybindControl(setting)
    else
        control = EditorTextInput({
            on_submit = function(input) return self.registry:setValue(setting.id, input) end
        })
        control:setValue(tostring(value or ""), true)
    end
    control.setting = setting
    return self:addGenerated(control)
end

function EditorSettingsPanel:setPage(page)
    if self.page == page then return end
    self.page = page
    self.scroll_y = 0
    self:clearControls()
    for _, setting in ipairs(page and page.settings or {}) do
        local control = self:createControl(setting)
        table.insert(self.rows, { setting = setting, control = control })
    end
end

function EditorSettingsPanel:refreshSetting(setting)
    for _, row in ipairs(self.rows) do
        if row.setting == setting then
            local value = self.registry:getValue(setting.id)
            if setting.type == "boolean" then
                row.control:setValue(value, true)
            elseif setting.type == "choice" then
                local _, label = EditorChoiceUtils.find(self.registry:getChoices(setting), value)
                row.control.label = label or tostring(value or "")
            elseif setting.type == "keybind" and not row.control.capturing then
                row.control.label = displayKeybind(value)
            elseif row.control.setValue then
                row.control:setValue(tostring(value or ""), true)
            end
            return true
        end
    end
    return false
end

function EditorSettingsPanel:isCapturingKeybind()
    for _, row in ipairs(self.rows) do
        if row.setting.type == "keybind" and row.control.capturing then return true end
    end
    return false
end

function EditorSettingsPanel:getMaxScroll()
    return math.max(0, self.content_height - self.height)
end

function EditorSettingsPanel:onWheelMoved(_, y)
    self.scroll_y = MathUtils.clamp(self.scroll_y - y * 42, 0, self:getMaxScroll())
    return true
end

function EditorSettingsPanel:update(dt)
    local page_width = math.min(190, math.max(140, self.width * 0.28))
    self.pages:setBounds(0, 0, page_width, self.height)
    local content_x, content_width = page_width + 16, math.max(0, self.width - page_width - 32)
    local y = 54 - self.scroll_y
    for _, row in ipairs(self.rows) do
        row.label_y = y
        row.control:setBounds(content_x, y + 22, content_width, 28)
        row.control.visible = row.control.y + row.control.height > 0 and row.control.y < self.height
        y = y + (row.setting.description and 78 or 60)
    end
    self.content_height = y + self.scroll_y + 12
    self.scroll_y = MathUtils.clamp(self.scroll_y, 0, self:getMaxScroll())
    local maximum = self:getMaxScroll()
    self.scrollbar.page = self.content_height == 0 and 1 or MathUtils.clamp(self.height / self.content_height, 0, 1)
    self.scrollbar.value = maximum == 0 and 0 or self.scroll_y / maximum
    self.scrollbar:setBounds(self.width - 12, 0, 12, self.height)
    super.update(self, dt)
end

function EditorSettingsPanel:drawSelf()
    Draw.setColor(0.08, 0.08, 0.09, 1)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    local page_width = math.min(190, math.max(140, self.width * 0.28))
    Draw.setColor(0.30, 0.30, 0.34, 1)
    love.graphics.line(page_width + 0.5, 0, page_width + 0.5, self.height)
    local font = EditorFont.get(16)
    love.graphics.setFont(font)
    if self.page then
        Draw.setColor(0.92, 0.92, 0.95, 1)
        love.graphics.print(self.page.title, page_width + 16, 14)
        for _, row in ipairs(self.rows) do
            if row.label_y and row.label_y >= 0 and row.label_y < self.height then
                Draw.setColor(0.78, 0.78, 0.82, 1)
                love.graphics.print(row.setting.name, page_width + 16, row.label_y)
                if row.setting.description then
                    Draw.setColor(0.52, 0.52, 0.56, 1)
                    love.graphics.print(row.setting.description, page_width + 16, row.label_y + 50)
                end
            end
        end
    end
end

return EditorSettingsPanel
