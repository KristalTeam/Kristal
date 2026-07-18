--- Directory for all registered EditorEvents so you can drag/drop them in the editor.
---@class EditorEventBrowser : EditorControl
---@field editor Editor
---@field list EditorItemList
---@field search EditorSearchBar
---@overload fun(editor: table): EditorEventBrowser
local EditorEventBrowser, super = Class(EditorControl)

function EditorEventBrowser:init(editor)
    super.init(self, 0, 0, 240, 300)
    self.editor = editor
    self.search = self:addChild(EditorSearchBar({
        placeholder = "Search events...",
        on_changed = function(value) self.list:setFilter(value) end
    }))
    self.list = self:addChild(EditorItemList({
        row_height = 48,
        on_select = function(item) if item then self.editor:setPlacementEvent(item.id) end end,
        on_activate = function(item) if item then self.editor:setPlacementEvent(item.id) end end,
        on_drag_start = function(item) self.editor:beginAssetDrag("event", item.id, item.label) end,
        on_drag_move = function(_, list, x, y)
            local gx, gy = list:getGlobalPosition()
            self.editor:updateAssetDrag(gx + x, gy + y)
        end,
        on_drag_end = function(_, list, x, y)
            local gx, gy = list:getGlobalPosition()
            self.editor:finishAssetDrag(gx + x, gy + y)
        end,
        on_request_focus = function(control) self.editor.dockspace:setFocus(control) end
    }))
    self:refresh()
end

function EditorEventBrowser:refresh()
    local items = {}
    for id, event in pairs(Registry.editor_events or {}) do
        local success, preview = pcall(Registry.createEditorEvent, id, {
            x = 0, y = 0, width = 0, height = 0, properties = {}
        }, { layer_color = { 0.95, 0.75, 0.25, 1 } })
        table.insert(items, {
            id = id,
            label = event.editor_name or event.name or StringUtils.titleCase(id:gsub("[/_]", " ")),
            data = event,
            preview = success and preview or nil
        })
    end
    table.sort(items, function(a, b) return a.label:lower() < b.label:lower() end)
    self.list:setItems(items)
end

function EditorEventBrowser:update(dt)
    self.search:setBounds(8, 8, math.max(0, self.width - 16), 28)
    self.list:setBounds(8, 44, math.max(0, self.width - 16), math.max(0, self.height - 52))
    super.update(self, dt)
end

function EditorEventBrowser:drawSelf()
    Draw.setColor(0.08, 0.08, 0.09, 1)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
end

return EditorEventBrowser
