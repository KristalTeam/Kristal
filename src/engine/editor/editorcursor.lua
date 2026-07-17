---@class EditorCursor : Class
---@overload fun(): EditorCursor
local EditorCursor = Class()

local CURSORS = {
    default = { path = "kristal/mouse", hotspot_x = 0, hotspot_y = 0, system = "arrow" },
    type = { path = "kristal/mouse/type", hotspot_x = 7, hotspot_y = 8, system = "ibeam" },
    select = { path = "kristal/mouse/select", hotspot_x = 0, hotspot_y = 0, system = "hand" },
    resize_vert = { path = "kristal/mouse/resize_vert", hotspot_x = 8, hotspot_y = 8, system = "sizens" },
    resize_hori = { path = "kristal/mouse/resize_hori", hotspot_x = 8, hotspot_y = 8, system = "sizewe" },
    resize_diag_r = { path = "kristal/mouse/resize_diag_r", hotspot_x = 7, hotspot_y = 7, system = "sizenesw" },
    resize_diag_l = { path = "kristal/mouse/resize_diag_l", hotspot_x = 7, hotspot_y = 7, system = "sizenwse" },
    resize_all = { path = "kristal/mouse/resize_all", hotspot_x = 7, hotspot_y = 8, system = "sizeall" },
    grab = { path = "kristal/mouse/grab", hotspot_x = 6, hotspot_y = 7, system = "hand" },
    crosshair = { path = "kristal/mouse/select", hotspot_x = 0, hotspot_y = 0, system = "crosshair" },
    link = { path = "kristal/mouse/select", hotspot_x = 0, hotspot_y = 0, system = "crosshair" },
    cannot = { path = "kristal/mouse/cannot", hotspot_x = 7, hotspot_y = 7, system = "no" }
}

function EditorCursor:init()
    self.type = nil
    self.custom_enabled = true
    self.custom_cursors = {}
    self.system_cursors = {}
    for id, cursor in pairs(CURSORS) do
        local image_data = Assets.getTextureData(cursor.path)
        if image_data then
            local success, hardware_cursor = pcall(love.mouse.newCursor, image_data,
                cursor.hotspot_x, cursor.hotspot_y)
            if success then self.custom_cursors[id] = hardware_cursor end
        end
        local success, system_cursor = pcall(love.mouse.getSystemCursor, cursor.system)
        if success then self.system_cursors[id] = system_cursor end
    end
end

function EditorCursor:setCustomEnabled(enabled)
    enabled = enabled ~= false
    if self.custom_enabled == enabled then return end
    self.custom_enabled = enabled
    local cursor_type = self.type or "default"
    self.type = nil
    self:setType(cursor_type)
end

function EditorCursor:setType(cursor_type)
    love.mouse.setVisible(true)
    local cursors = self.custom_enabled and self.custom_cursors or self.system_cursors
    if not CURSORS[cursor_type] or not cursors[cursor_type] then
        cursor_type = "default"
    end
    if self.type == cursor_type then return end
    self.type = cursor_type
    if cursors[cursor_type] then
        love.mouse.setCursor(cursors[cursor_type])
    elseif self.system_cursors[cursor_type] then
        love.mouse.setCursor(self.system_cursors[cursor_type])
    else
        love.mouse.setCursor()
    end
end

return EditorCursor
