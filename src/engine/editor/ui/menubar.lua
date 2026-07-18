---@class EditorMenuBar : Class
---@field button_rects table
---@field editor Editor
---@field height number
---@field item_rects table
---@field items table
---@field open_menu any
---@field providers table
---@field y number
---@field width number
---@field x number
---@overload fun(editor: table): EditorMenuBar
local EditorMenuBar = Class()

EditorMenuBar.HEIGHT = 30

local BUTTONS = {
    { id = "file", label = "File" },
    { id = "edit", label = "Edit" },
    { id = "properties", label = "Properties" },
    { id = "view", label = "View" },
    { id = "workspaces", label = "Workspaces" },
    { id = "window", label = "Window" },
    { id = "help", label = "Help" }
}

local BUTTON_LABELS = {}
for _, button in ipairs(BUTTONS) do BUTTON_LABELS[button.id] = button.label end

local function commandFromMenuItem(menu_id, item)
    if type(item.on_activate) ~= "function" then return nil end
    return {
        id = "menu:" .. menu_id .. ":" .. tostring(item.id),
        name = item.label,
        category = BUTTON_LABELS[menu_id] or StringUtils.titleCase(menu_id),
        keywords = item.keywords,
        is_enabled = item.is_enabled,
        get_checked = item.get_checked,
        action = item.on_activate
    }
end

function EditorMenuBar:init(editor)
    self.editor = editor
    self.x, self.y = 0, 0
    self.width, self.height = 0, self.HEIGHT
    self.open_menu = nil
    self.button_rects = {}
    self.item_rects = {}
    self.items = {}
    self.providers = {}
    for _, button in ipairs(BUTTONS) do
        self.items[button.id] = {}
        self.providers[button.id] = {}
    end
end

function EditorMenuBar:registerItem(menu_id, id, label, options)
    assert(self.items[menu_id], "Unknown editor menu: " .. tostring(menu_id))
    options = options or {}
    local item = {
        id = id,
        label = label,
        get_checked = options.get_checked,
        on_activate = options.on_activate,
        is_enabled = options.is_enabled,
        keywords = options.keywords
    }
    table.insert(self.items[menu_id], item)
    local command = commandFromMenuItem(menu_id, item)
    if command and self.editor.command_registry then
        self.editor.command_registry:register(command.id, command)
    end
    return item
end

function EditorMenuBar:registerToggle(menu_id, id, label, get_checked, set_checked)
    return self:registerItem(menu_id, id, label, {
        get_checked = get_checked,
        on_activate = function()
            set_checked(not get_checked())
        end
    })
end

function EditorMenuBar:registerProvider(menu_id, id, provider)
    assert(self.providers[menu_id], "Unknown editor menu: " .. tostring(menu_id))
    table.insert(self.providers[menu_id], { id = id, provider = provider })
    if self.editor.command_registry then
        self.editor.command_registry:registerProvider("menu:" .. menu_id .. ":" .. id, function()
            local commands = {}
            for _, item in ipairs(provider() or {}) do
                local command = commandFromMenuItem(menu_id, item)
                if command then table.insert(commands, command) end
            end
            return commands
        end)
    end
end

function EditorMenuBar:getItems(menu_id)
    local result = {}
    for _, item in ipairs(self.items[menu_id] or {}) do table.insert(result, item) end
    for _, entry in ipairs(self.providers[menu_id] or {}) do
        for _, item in ipairs(entry.provider() or {}) do table.insert(result, item) end
    end
    return result
end

function EditorMenuBar:setBounds(x, y, width)
    self.x, self.y = x, y
    self.width, self.height = width, self.HEIGHT
end

function EditorMenuBar:layout()
    local font = EditorFont.get(16)
    local x = self.x + 6
    self.button_rects = {}
    for _, button in ipairs(BUTTONS) do
        local width = font:getWidth(button.label) + 18
        self.button_rects[button.id] = { x = x, y = self.y, width = width, height = self.height }
        x = x + width
    end

    self.item_rects = {}
    if not self.open_menu then return end
    local button_rect = self.button_rects[self.open_menu]
    local items = self:getItems(self.open_menu)
    local menu_width = 200
    for _, item in ipairs(items) do
        menu_width = math.max(menu_width, font:getWidth(item.label) + (item.get_checked and 52 or 24))
    end
    local y = self.y + self.height
    for _, item in ipairs(items) do
        local item_rect = {
            item = item,
            id = item.id,
            label = item.label,
            enabled = not item.is_enabled or item.is_enabled(),
            x = button_rect.x,
            y = y,
            width = menu_width,
            height = 28
        }
        if item.get_checked then item_rect.checked = item.get_checked() == true end
        table.insert(self.item_rects, item_rect)
        y = y + 28
    end
end

function EditorMenuBar:getCursorType(x, y)
    self:layout()
    for _, item in ipairs(self.item_rects) do
        if item.enabled and MathUtils.pointInRect(x, y, item) then return "select" end
    end
    for _, rect in pairs(self.button_rects) do
        if MathUtils.pointInRect(x, y, rect) then return "select" end
    end
    return "default"
end

function EditorMenuBar:onMousePressed(x, y, button)
    if button ~= 1 then return self.open_menu ~= nil end
    self:layout()
    for _, rect in ipairs(self.item_rects) do
        if MathUtils.pointInRect(x, y, rect) then
            if rect.enabled and rect.item.on_activate then rect.item.on_activate() end
            self.open_menu = nil
            return true
        end
    end
    for id, rect in pairs(self.button_rects) do
        if MathUtils.pointInRect(x, y, rect) then
            if #self:getItems(id) > 0 then
                self.open_menu = self.open_menu == id and nil or id
            else
                self.open_menu = nil
            end
            return true
        end
    end
    local was_open = self.open_menu ~= nil
    self.open_menu = nil
    return was_open or y < self.y + self.height
end

function EditorMenuBar:onKeyPressed(key)
    if key == "escape" and self.open_menu then
        self.open_menu = nil
        return true
    end
    return false
end

function EditorMenuBar:drawText(text, x, y, color)
    local font = EditorFont.get(16)
    love.graphics.setFont(font)
    Draw.setColor(0, 0, 0, color[4])
    love.graphics.print(text, x + 1, y + 1)
    Draw.setColor(color)
    love.graphics.print(text, x, y)
end

function EditorMenuBar:draw()
    self:layout()
    local font = EditorFont.get(16)
    love.graphics.setLineWidth(1)
    Draw.setColor(0.12, 0.12, 0.14, 1)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    Draw.setColor(0.30, 0.30, 0.34, 1)
    love.graphics.line(self.x, self.y + self.height - 1, self.x + self.width, self.y + self.height - 1)

    for _, button in ipairs(BUTTONS) do
        local rect = self.button_rects[button.id]
        if self.open_menu == button.id then
            Draw.setColor(0.23, 0.23, 0.27, 1)
            love.graphics.rectangle("fill", rect.x, rect.y, rect.width, rect.height)
        end
        self:drawText(button.label, rect.x + 9, rect.y + math.floor((rect.height - font:getHeight()) / 2),
            { 0.9, 0.9, 0.92, 1 })
    end

    for _, item in ipairs(self.item_rects) do
        Draw.setColor(0.15, 0.15, 0.18, 1)
        love.graphics.rectangle("fill", item.x, item.y, item.width, item.height)
        Draw.setColor(0.32, 0.32, 0.37, 1)
        love.graphics.rectangle("line", item.x + 0.5, item.y + 0.5, item.width - 1, item.height - 1)
        local text_x = item.x + 12
        if item.checked ~= nil then
            self:drawText(item.checked and "[x]" or "[ ]", item.x + 7, item.y + 5,
                { 0.65, 0.82, 1, item.enabled and 1 or 0.45 })
            text_x = item.x + 38
        end
        self:drawText(item.label, text_x, item.y + 5,
            { 0.9, 0.9, 0.92, item.enabled and 1 or 0.45 })
    end
    Draw.setColor(1, 1, 1, 1)
end

return EditorMenuBar
