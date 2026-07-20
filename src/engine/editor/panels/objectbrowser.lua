--- Directory for all registered EditorObjects that can be placed on maps.
---@class EditorObjectBrowser : EditorControl
---@field editor Editor
---@field list EditorItemList
---@field search EditorSearchBar
---@overload fun(editor: table): EditorObjectBrowser
local EditorObjectBrowser, super = Class(EditorControl)

function EditorObjectBrowser:init(editor)
    super.init(self, 0, 0, 240, 300)
    self.editor = editor
    self.search = self:addChild(EditorSearchBar({
        placeholder = "Search objects...",
        on_changed = function(value) self.list:setFilter(value) end
    }))
    self.list = self:addChild(EditorItemList({
        row_height = 48,
        on_select = function(item) self:selectObject(item) end,
        on_activate = function(item) self:selectObject(item) end,
        on_drag_start = function(item) self.editor:beginAssetDrag("object", item.id, item.label) end,
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

function EditorObjectBrowser:selectObject(item)
    if not item then return false end
    self.editor:setPlacementObject(item.id)
    local description = item.data and item.data.editor_description
    if description and self.editor.message_bar then self.editor.message_bar:setStatus(description) end
    return true
end

function EditorObjectBrowser:refresh()
    local items = {}
    for id, object in pairs(Registry.editor_objects or {}) do
        if not object.editor_hidden then
            local success, preview = pcall(Registry.createEditorObject, id, {
                x = 0, y = 0, width = 0, height = 0, properties = {}
            }, { layer_color = { 0.95, 0.75, 0.25, 1 } })
            table.insert(items, {
                id = id,
                label = object.editor_name or object.name or StringUtils.titleCase(id:gsub("[/_]", " ")),
                data = object,
                preview = success and preview or nil
            })
        end
    end
    table.sort(items, function(a, b) return a.label:lower() < b.label:lower() end)
    self.list:setItems(items)
end

function EditorObjectBrowser:update(dt)
    self.search:setBounds(8, 8, math.max(0, self.width - 16), 28)
    self.list:setBounds(8, 44, math.max(0, self.width - 16), math.max(0, self.height - 52))
    super.update(self, dt)
end

function EditorObjectBrowser:drawSelf()
    Draw.setColor(0.08, 0.08, 0.09, 1)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
end

return EditorObjectBrowser
