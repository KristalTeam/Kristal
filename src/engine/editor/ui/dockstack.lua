--- Represents a group of tabbed panels in a dock space.
---@class EditorDockStack : Class
---@field active_index number
---@field height number
---@field id string?
---@field layout_weight number
---@field panels table
---@field region any
---@field tab_rects table
---@field tab_scroll number
---@field tab_scroll_left_rect any
---@field tab_scroll_right_rect any
---@field tab_total_width number
---@field tab_view_rect any
---@field width number
---@field x number
---@field y number
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
    self.layout_weight = 1
end

function EditorDockStack:addPanel(panel, index)
    if panel.stack == self then
        self:setActivePanel(panel, true)
        return
    end
    if panel.stack then panel.stack:removePanel(panel) end
    panel.stack = self
    panel.floating = nil
    table.insert(self.panels, index or (#self.panels + 1), panel)
    self.active_index = index or #self.panels
end

function EditorDockStack:removePanel(panel)
    local active = self:getActivePanel()
    for index, candidate in ipairs(self.panels) do
        if candidate == panel then
            table.remove(self.panels, index)
            panel.stack = nil
            if #self.panels == 0 then
                self.active_index = 1
            elseif active == panel then
                self.active_index = math.min(index, #self.panels)
            else
                for active_index, remaining in ipairs(self.panels) do
                    if remaining == active then
                        self.active_index = active_index
                        break
                    end
                end
            end
            return panel, active == panel
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
