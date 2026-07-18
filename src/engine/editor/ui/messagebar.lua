--- Displays warnings/errors/status messages.
---@class EditorMessageBar : Class
---@field entries table
---@field height number
---@field maximum_entries number
---@field status string?
---@field y number
---@field width number
---@field x number
---@overload fun(): EditorMessageBar
local EditorMessageBar = Class()

EditorMessageBar.HEIGHT = 28

local COLORS = {
    warning = { 0.95, 0.70, 0.20, 1 },
    error = { 1, 0.32, 0.32, 1 }
}

function EditorMessageBar:init()
    self.x, self.y, self.width, self.height = 0, 0, 0, self.HEIGHT
    self.entries = {}
    self.maximum_entries = 100
    self.status = nil
end

function EditorMessageBar:setStatus(message, duration)
    self.status = {
        message = tostring(message or ""),
        expires = Kristal.getTime() + (duration or 2.5)
    }
end

function EditorMessageBar:setBounds(x, y, width)
    self.x, self.y = x, y
    self.width, self.height = math.max(0, width), self.HEIGHT
end

function EditorMessageBar:containsPoint(x, y)
    return x >= self.x and y >= self.y
        and x < self.x + self.width and y < self.y + self.height
end

function EditorMessageBar:add(severity, message, detail, source)
    assert(COLORS[severity], "Unknown editor diagnostic severity: " .. tostring(severity))
    local entry = {
        severity = severity,
        message = tostring(message or ""),
        detail = detail and tostring(detail) or nil,
        source = source,
        time = Kristal.getTime()
    }
    table.insert(self.entries, entry)
    while #self.entries > self.maximum_entries do table.remove(self.entries, 1) end
    return entry
end

function EditorMessageBar:addWarning(message, detail, source)
    return self:add("warning", message, detail, source)
end

function EditorMessageBar:addError(message, detail, source)
    return self:add("error", message, detail, source)
end

function EditorMessageBar:clear(source)
    if source == nil then
        self.entries = {}
        return
    end
    for index = #self.entries, 1, -1 do
        if self.entries[index].source == source then table.remove(self.entries, index) end
    end
end

function EditorMessageBar:getCounts()
    local warnings, errors = 0, 0
    for _, entry in ipairs(self.entries) do
        if entry.severity == "warning" then warnings = warnings + 1 end
        if entry.severity == "error" then errors = errors + 1 end
    end
    return warnings, errors
end

function EditorMessageBar:draw()
    if self.status and Kristal.getTime() >= self.status.expires then self.status = nil end
    local latest = self.entries[#self.entries]
    local font = EditorFont.get(16)
    love.graphics.setFont(font)
    love.graphics.setLineWidth(1)

    Draw.setColor(0.10, 0.10, 0.12, 1)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    Draw.setColor(0.30, 0.30, 0.34, 1)
    love.graphics.line(self.x, self.y + 0.5, self.x + self.width, self.y + 0.5)

    local warnings, errors = self:getCounts()
    local counts = string.format("%d error%s  %d warning%s", errors, errors == 1 and "" or "s",
        warnings, warnings == 1 and "" or "s")
    local counts_width = font:getWidth(counts)
    local text_y = self.y + math.floor((self.height - font:getHeight()) / 2)

    local old_scissor = { love.graphics.getScissor() }
    love.graphics.setScissor(self.x + 8, self.y, math.max(0, self.width - counts_width - 32), self.height)
    if self.status then
        Draw.setColor(0.72, 0.78, 0.90, 1)
        love.graphics.print(self.status.message, self.x + 8, text_y)
    elseif latest then
        Draw.setColor(COLORS[latest.severity])
        love.graphics.print(string.format("[%s] %s", string.upper(latest.severity), latest.message), self.x + 8, text_y)
    else
        Draw.setColor(0.58, 0.58, 0.62, 1)
        love.graphics.print("No warnings or errors", self.x + 8, text_y)
    end
    love.graphics.setScissor(unpack(old_scissor))

    Draw.setColor(errors > 0 and COLORS.error or (warnings > 0 and COLORS.warning or { 0.72, 0.72, 0.75, 1 }))
    love.graphics.print(counts, self.x + self.width - counts_width - 8, text_y)
    Draw.setColor(1, 1, 1, 1)
end

return EditorMessageBar
