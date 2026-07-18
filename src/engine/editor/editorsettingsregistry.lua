---@class EditorSettingsRegistry : Class
---@field editor Editor
---@field page_order table
---@field pages table
---@field settings table
---@field stored_values table
---@overload fun(editor: table, stored_values?: table): EditorSettingsRegistry
local EditorSettingsRegistry = Class()

function EditorSettingsRegistry:init(editor, stored_values)
    self.editor = editor
    self.stored_values = TableUtils.copy(stored_values or {}, true)
    self.pages = {}
    self.page_order = {}
    self.settings = {}
end

function EditorSettingsRegistry:registerPage(id, title, options)
    assert(type(id) == "string" and id ~= "", "Editor settings pages require an id")
    assert(not self.pages[id], "Duplicate editor settings page: " .. id)
    options = options or {}
    local page = {
        id = id,
        title = title or StringUtils.titleCase(id:gsub("[_/]", " ")),
        description = options.description,
        owner = options.owner,
        settings = {}
    }
    self.pages[id] = page
    table.insert(self.page_order, page)
    return page
end

---@param setting table
---@param value any
---@return any value
function EditorSettingsRegistry:coerce(setting, value)
    if setting.type == "boolean" then return value == true end
    if setting.type == "number" or setting.type == "integer" then
        value = tonumber(value)
        if not value then return nil end
        if setting.type == "integer" then value = MathUtils.round(value) end
        if setting.minimum then value = math.max(setting.minimum, value) end
        if setting.maximum then value = math.min(setting.maximum, value) end
        return value
    end
    if setting.type == "choice" then
        for _, choice in ipairs(self:getChoices(setting)) do
            local choice_value = EditorChoiceUtils.getValue(choice)
            if choice_value == value or tostring(choice_value) == tostring(value) then return choice_value end
        end
        return nil
    end
    if setting.type == "color" then
        value = tostring(value or "")
        local hex = value:gsub("^#", "")
        if (#hex == 6 or #hex == 8) and hex:match("^%x+$") then
            return "#" .. hex:upper()
        end
        return nil
    end
    if setting.type == "keybind" then return value end
    return tostring(value or "")
end

function EditorSettingsRegistry:getChoices(setting)
    if type(setting) == "string" then setting = self.settings[setting] end
    return setting and EditorChoiceUtils.resolve(setting.choices, setting) or {}
end

function EditorSettingsRegistry:registerSetting(page_id, id, definition)
    local page = assert(self.pages[page_id], "Unknown editor settings page: " .. tostring(page_id))
    assert(type(id) == "string" and id ~= "", "Editor settings require an id")
    assert(not self.settings[id], "Duplicate editor setting: " .. id)
    local owner = definition and definition.owner
    definition = TableUtils.copy(definition or {}, true)
    definition.owner = owner
    local setting = definition
    setting.id = id
    setting.page_id = page_id
    setting.name = setting.name or StringUtils.titleCase(id:gsub("[_/]", " "))
    setting.type = setting.type or "string"
    setting.owner = setting.owner or page.owner
    setting.persistent = setting.persistent ~= false
    local value
    if setting.persistent then value = self.stored_values[id] end
    if value == nil and setting.get then value = setting.get(self.editor, setting) end
    if value == nil then value = setting.default end
    value = self:coerce(setting, value)
    if value == nil then value = self:coerce(setting, setting.default) end
    setting.value = value
    self.settings[id] = setting
    table.insert(page.settings, setting)
    if setting.set and setting.apply_initial ~= false then setting.set(value, self.editor, setting, true) end
    if setting.on_changed and setting.apply_initial_callback == true then
        setting.on_changed(value, nil, self.editor, setting, true)
    end
    return setting
end

function EditorSettingsRegistry:getPage(id)
    return self.pages[id]
end

function EditorSettingsRegistry:getPages()
    return self.page_order
end

function EditorSettingsRegistry:getSetting(id)
    return self.settings[id]
end

function EditorSettingsRegistry:getValue(id)
    local setting = self.settings[id]
    if not setting then return nil end
    if setting.get then return setting.get(self.editor, setting) end
    return setting.value
end

function EditorSettingsRegistry:setValue(id, value)
    local setting = self.settings[id]
    if not setting then return false end
    value = self:coerce(setting, value)
    if value == nil then return false end
    local previous = self:getValue(id)
    if setting.set and setting.set(value, self.editor, setting, false) == false then return false end
    setting.value = value
    if setting.on_changed then setting.on_changed(value, previous, self.editor, setting, false) end
    if self.editor.settings_browser then self.editor.settings_browser:refreshSetting(setting) end
    return true
end

function EditorSettingsRegistry:getStoredValues()
    local values = {}
    for id, setting in pairs(self.settings) do
        if setting.persistent then values[id] = self:getValue(id) end
    end
    return values
end

function EditorSettingsRegistry:removeOwner(owner)
    for page_index = #self.page_order, 1, -1 do
        local page = self.page_order[page_index]
        for setting_index = #page.settings, 1, -1 do
            local setting = page.settings[setting_index]
            if setting.owner == owner then
                self.settings[setting.id] = nil
                table.remove(page.settings, setting_index)
            end
        end
        if page.owner == owner then
            self.pages[page.id] = nil
            table.remove(self.page_order, page_index)
        end
    end
end

return EditorSettingsRegistry
