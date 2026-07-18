---@class EditorCodeCompletionPopup : EditorControl
---@field clip boolean
---@field enabled boolean
---@field items table
---@field maximum_rows number
---@field row_height number
---@field scroll number
---@field selected number
---@field visible boolean
---@overload fun(): EditorCodeCompletionPopup
local EditorCodeCompletionPopup, super = Class(EditorControl)

local KIND_NAMES = {
    "Text", "Method", "Function", "Constructor", "Field", "Variable", "Class", "Interface",
    "Module", "Property", "Unit", "Value", "Enum", "Keyword", "Snippet", "Color", "File",
    "Reference", "Folder", "Enum Member", "Constant", "Struct", "Event", "Operator", "Type"
}

function EditorCodeCompletionPopup:init()
    super.init(self, 0, 0, 0, 0)
    self.enabled = false
    self.visible = false
    self.clip = true
    self.items = {}
    self.selected = 1
    self.scroll = 0
    self.row_height = 24
    self.maximum_rows = 10
end

function EditorCodeCompletionPopup:open(items, anchor_x, anchor_y, parent_width, parent_height)
    self.items = items or {}
    if #self.items == 0 then return self:close() end
    self.selected, self.scroll = 1, 0
    local row_count = math.min(#self.items, self.maximum_rows)
    local width = math.min(420, math.max(180, parent_width - 8))
    local height = row_count * self.row_height + 2
    local x = MathUtils.clamp(anchor_x, 2, math.max(2, parent_width - width - 2))
    local y = anchor_y
    if y + height > parent_height - 2 then y = math.max(2, anchor_y - height - self.row_height) end
    self:setBounds(x, y, width, height)
    self.visible = true
    return true
end

function EditorCodeCompletionPopup:close()
    self.visible = false
    self.items = {}
    self.selected, self.scroll = 1, 0
    return true
end

function EditorCodeCompletionPopup:getSelectedItem()
    return self.visible and self.items[self.selected] or nil
end

function EditorCodeCompletionPopup:ensureSelectedVisible()
    if self.selected <= self.scroll then self.scroll = self.selected - 1 end
    if self.selected > self.scroll + self.maximum_rows then
        self.scroll = self.selected - self.maximum_rows
    end
    self.scroll = MathUtils.clamp(self.scroll, 0, math.max(0, #self.items - self.maximum_rows))
end

function EditorCodeCompletionPopup:moveSelection(amount)
    if not self.visible or #self.items == 0 then return false end
    self.selected = ((self.selected - 1 + amount) % #self.items) + 1
    self:ensureSelectedVisible()
    return true
end

function EditorCodeCompletionPopup:pageSelection(amount)
    if not self.visible or #self.items == 0 then return false end
    self.selected = MathUtils.clamp(self.selected + amount * self.maximum_rows, 1, #self.items)
    self:ensureSelectedVisible()
    return true
end

function EditorCodeCompletionPopup:scrollRows(amount)
    if not self.visible then return false end
    self.scroll = MathUtils.clamp(self.scroll + amount, 0, math.max(0, #self.items - self.maximum_rows))
    if self.selected <= self.scroll then self.selected = self.scroll + 1 end
    if self.selected > self.scroll + self.maximum_rows then
        self.selected = math.min(#self.items, self.scroll + self.maximum_rows)
    end
    return true
end

function EditorCodeCompletionPopup:getItemAt(x, y)
    if not self.visible or x < self.x or y < self.y or x >= self.x + self.width or y >= self.y + self.height then
        return nil
    end
    local row = math.floor((y - self.y - 1) / self.row_height) + 1
    local index = self.scroll + row
    return self.items[index] and index or nil
end

function EditorCodeCompletionPopup:drawSelf()
    Draw.setColor(0.075, 0.078, 0.095, 0.98)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    local font = EditorFont.getMono(16)
    love.graphics.setFont(font)
    local last = math.min(#self.items, self.scroll + self.maximum_rows)
    for index = self.scroll + 1, last do
        local item = self.items[index]
        local y = 1 + (index - self.scroll - 1) * self.row_height
        if index == self.selected then
            Draw.setColor(0.18, 0.29, 0.48, 1)
            love.graphics.rectangle("fill", 1, y, self.width - 2, self.row_height)
        end
        Draw.setColor(0.90, 0.90, 0.94, 1)
        love.graphics.print(tostring(item.label or ""), 7, y + math.floor((self.row_height - font:getHeight()) / 2))
        local kind = KIND_NAMES[tonumber(item.kind)] or ""
        if kind ~= "" then
            Draw.setColor(0.52, 0.58, 0.68, 1)
            love.graphics.print(kind, self.width - font:getWidth(kind) - 10,
                y + math.floor((self.row_height - font:getHeight()) / 2))
        end
    end
    if #self.items > self.maximum_rows then
        local track_height = self.height - 2
        local thumb_height = math.max(16, track_height * self.maximum_rows / #self.items)
        local maximum = #self.items - self.maximum_rows
        local thumb_y = 1 + (track_height - thumb_height) * self.scroll / maximum
        Draw.setColor(0.20, 0.21, 0.25, 1)
        love.graphics.rectangle("fill", self.width - 5, 1, 4, track_height)
        Draw.setColor(0.48, 0.54, 0.68, 1)
        love.graphics.rectangle("fill", self.width - 5, thumb_y, 4, thumb_height)
    end
    Draw.setColor(0.32, 0.35, 0.43, 1)
    love.graphics.rectangle("line", 0.5, 0.5, self.width - 1, self.height - 1)
end

return EditorCodeCompletionPopup
