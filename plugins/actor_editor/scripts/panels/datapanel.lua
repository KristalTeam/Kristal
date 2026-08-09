local DataModel = ...
---@class ActorEditorDataPanel : EditorControl
---@field continuous_edit boolean
---@field diagnostic_id string
---@field editor Editor
---@field entity_name string
---@field entries table
---@field entry_list_field string
---@field entry_scanner string
---@field entry_lookup table
---@field field_rows table
---@field field_getter string
---@field field_setter string
---@field mode string
---@field mode_buttons table
---@field mode_controls table
---@field model table?
---@field models table
---@field model_factory string
---@field panel_definition_key string
---@field panel_title string
---@field plugin ActorEditorPlugin
---@field save_button EditorButton
---@field saved_signatures table
---@field selected_id string?
---@overload fun(editor: Editor, plugin: ActorEditorPlugin): ActorEditorDataPanel
local ActorEditorDataPanel, super = Class(EditorControl)

function ActorEditorDataPanel:init(editor, plugin)
    super.init(self, 0, 0, 980, 680)
    self.editor = editor
    self.plugin = plugin
    self.entries = {}
    self.entry_lookup = {}
    self.models = {}
    self.saved_signatures = {}
    self.model = nil
    self.selected_id = nil
    self.field_rows = {}
    self.mode_controls = {}
    self.mode_buttons = {}
    self.continuous_edit = false
    self.focusable = true
    self.clip = true
end

function ActorEditorDataPanel:addModeControl(mode, control)
    self.mode_controls[mode] = self.mode_controls[mode] or {}
    table.insert(self.mode_controls[mode], control)
    return self:addChild(control)
end

function ActorEditorDataPanel:addField(mode, label, control, compact)
    control = self:addModeControl(mode, control)
    table.insert(self.field_rows, {
        mode = mode,
        label = label,
        control = control,
        compact = compact == true
    })
    return control
end

function ActorEditorDataPanel:getPanel()
    local definition = self.plugin[self.panel_definition_key]
    return definition and definition.panel
end

function ActorEditorDataPanel:isVisibleAndDirty()
    local panel = self:getPanel()
    return panel and panel.visible and self:isDirty()
end

function ActorEditorDataPanel:isDirty()
    for _, model in pairs(self.models) do
        if model.dirty then return true end
    end
    return false
end

function ActorEditorDataPanel:performEdit(label, callback)
    if self.continuous_edit then
        return true, callback()
    end
    local result
    local performed = self.editor:performHistoryEdit(label, self, function()
        result = callback()
        return result ~= false
    end)
    return performed, result
end

function ActorEditorDataPanel:beginContinuousEdit(label)
    if self.continuous_edit then return end
    self.continuous_edit = self.editor:beginHistoryTransaction(label, self)
end

function ActorEditorDataPanel:finishContinuousEdit()
    if not self.continuous_edit then return end
    self.continuous_edit = false
    self.editor:markHistoryChanged()
    self.editor:commitHistoryTransaction()
    self:refreshModelControls()
end

function ActorEditorDataPanel:refreshEntries(preserve)
    local selected = preserve and self.selected_id
    self.entries = DataModel[self.entry_scanner]()
    self.entry_lookup = {}
    for _, entry in ipairs(self.entries) do self.entry_lookup[entry.id] = entry end
    self:refreshEntryList()
    if selected and self.entry_lookup[selected] then
        self:selectEntryById(selected)
    elseif self.entries[1] then
        self:selectEntry(self.entries[1])
    else
        self.model, self.selected_id = nil, nil
        self:refreshModelControls()
    end
end

function ActorEditorDataPanel:refreshEntryList()
    local items = {}
    for _, entry in ipairs(self.entries) do
        local model = self.models[entry.id]
        table.insert(items, {
            id = entry.id,
            label = entry.id .. (model and model.dirty and " *" or ""),
            data = entry
        })
    end
    local list = self[self.entry_list_field]
    list:setItems(items)
    if self.selected_id then
        for index, item in ipairs(list.filtered_items) do
            if item.id == self.selected_id then list:select(index) break end
        end
    end
end

function ActorEditorDataPanel:selectEntry(entry)
    if not entry then return false end
    local model = self.models[entry.id]
    if not model then
        local reason
        model, reason = DataModel[self.model_factory](entry)
        if not model then
            self.editor:addError("Could not open " .. self.entity_name .. " '" .. entry.id .. "'",
                reason, self.diagnostic_id)
            return false
        end
        self.models[entry.id] = model
        self.saved_signatures[entry.id] = DataModel.signature(model)
    end
    self.editor:clearDiagnostics(self.diagnostic_id)
    self.model, self.selected_id = model, entry.id
    if self.onModelSelected then self:onModelSelected(model) end
    self:refreshModelControls()
    return true
end

function ActorEditorDataPanel:selectEntryById(id)
    local entry = self.entry_lookup and self.entry_lookup[id]
    return entry and self:selectEntry(entry) or false
end

function ActorEditorDataPanel:setVectorField(key, index, value)
    local vector = DataModel.copy(self[self.field_getter](self, key) or { 0, 0 })
    vector[index] = value
    return self[self.field_setter](self, key, vector)
end

function ActorEditorDataPanel:setMode(mode)
    self.mode = mode
    for id, controls in pairs(self.mode_controls) do
        for _, control in ipairs(controls) do control.visible = id == mode end
    end
    for id, button in pairs(self.mode_buttons) do button.focused = id == mode end
    if self.onModeChanged then self:onModeChanged(mode) end
    self:refreshModelControls()
end

function ActorEditorDataPanel:updateDirtyPresentation()
    for id, model in pairs(self.models) do
        model.dirty = DataModel.signature(model) ~= self.saved_signatures[id]
    end
    self.save_button.enabled = self.model ~= nil and self.model.dirty
    self:refreshEntryList()
    local dirty = self:isDirty()
    local panel = self:getPanel()
    if panel then panel.title = self.panel_title .. (dirty and " *" or "") end
    if dirty ~= self.last_dirty_warning then
        self.last_dirty_warning = dirty
        self.editor:clearDiagnostics(self.diagnostic_id .. "_unsaved")
        if dirty then
            self.editor:addWarning(self.panel_title .. " has unsaved changes",
                "Use Ctrl+S while the " .. self.panel_title .. " is focused, or File > Save All.",
                self.diagnostic_id .. "_unsaved")
        end
    end
end

function ActorEditorDataPanel:saveSelected()
    if not self.model or not self.model.dirty then return false end
    local saved, reason = DataModel.save(self.model)
    if not saved then
        self.editor:addError("Could not save " .. self.entity_name .. " '" .. self.model.id .. "'",
            reason, self.diagnostic_id .. "_save")
        return false
    end
    self.editor:clearDiagnostics(self.diagnostic_id .. "_save")
    self.saved_signatures[self.model.id] = DataModel.signature(self.model)
    self.model.dirty = false
    if reason then
        self.editor:addWarning(StringUtils.titleCase(self.entity_name) .. " saved with a reload warning",
            reason, self.diagnostic_id .. "_save")
    end
    if self.editor.message_bar then
        self.editor.message_bar:setStatus("Saved " .. self.entity_name .. ": " .. self.model.id, 4)
    end
    self:updateDirtyPresentation()
    return true
end

function ActorEditorDataPanel:saveAll()
    for _, model in pairs(self.models) do
        if model.dirty then
            local saved, reason = DataModel.save(model)
            if not saved then
                self.editor:addError("Could not save " .. self.entity_name .. " '" .. model.id .. "'",
                    reason, self.diagnostic_id .. "_save")
                return false
            elseif reason then
                self.editor:addWarning(StringUtils.titleCase(self.entity_name) .. " '" .. model.id
                    .. "' saved with a reload warning", reason, self.diagnostic_id .. "_save")
            end
            self.saved_signatures[model.id] = DataModel.signature(model)
            model.dirty = false
        end
    end
    self:updateDirtyPresentation()
    return true
end

return ActorEditorDataPanel
