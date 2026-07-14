---@class EditorDockStack : Class
---@overload fun(id: string): EditorDockStack
local EditorDockStack = Class()

function EditorDockStack:init(id, region)
    self.id = id
    self.region = region or id
    self.panels = {}
    self.active_index = 1
    self.x, self.y, self.width, self.height = 0, 0, 0, 0
    self.tab_rects = {}
    self.tab_scroll = 0
    self.tab_total_width = 0
    self.tab_view_rect = nil
    self.tab_scroll_left_rect = nil
    self.tab_scroll_right_rect = nil
end

function EditorDockStack:addPanel(panel, index)
    if panel.stack == self then
        self:setActivePanel(panel)
        return
    end
    if panel.stack then panel.stack:removePanel(panel) end
    panel.stack = self
    panel.floating = nil
    table.insert(self.panels, index or (#self.panels + 1), panel)
    self.active_index = index or #self.panels
end

function EditorDockStack:removePanel(panel)
    for index, candidate in ipairs(self.panels) do
        if candidate == panel then
            table.remove(self.panels, index)
            panel.stack = nil
            self.active_index = MathUtils.clamp(self.active_index, 1, math.max(1, #self.panels))
            return panel
        end
    end
end

function EditorDockStack:getActivePanel()
    return self.panels[self.active_index]
end

function EditorDockStack:setActivePanel(panel, notify)
    for index, candidate in ipairs(self.panels) do
        if candidate == panel then
            local changed = self.active_index ~= index
            self.active_index = index
            if (changed or notify) and candidate.on_activate then candidate.on_activate(candidate) end
            return true
        end
    end
    return false
end

function EditorDockStack:isEmpty()
    return #self.panels == 0
end

return EditorDockStack
