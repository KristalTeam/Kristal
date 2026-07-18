--- Lists registered editor DrawFX that can be added to objects.
---@class EditorFXBrowser : EditorControl
---@field editor Editor
---@field list EditorItemList
---@field search EditorSearchBar
---@overload fun(editor: table): EditorFXBrowser
local EditorFXBrowser, super = Class(EditorControl)

function EditorFXBrowser:init(editor)
    super.init(self, 0, 0, 260, 300)
    self.editor = editor
    self.search = self:addChild(EditorSearchBar({
        placeholder = "Search DrawFX...",
        on_changed = function(value) self.list:setFilter(value) end
    }))
    self.list = self:addChild(EditorItemList({
        on_activate = function(item)
            if item and self.editor.selected_map_object then
                self.editor:applyDrawFXToSelection(item.id)
            end
        end,
        on_drag_start = function(item) self.editor:beginAssetDrag("drawfx", item.id, item.label) end,
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

function EditorFXBrowser:refresh()
    local items = {}
    for _, definition in ipairs(Registry.getEditorDrawFXAll()) do
        table.insert(items, { id = definition.id, label = definition.name, icon = definition.icon })
    end
    table.sort(items, function(a, b) return a.label:lower() < b.label:lower() end)
    self.list:setItems(items)
end

function EditorFXBrowser:update(dt)
    self.search:setBounds(8, 8, math.max(0, self.width - 16), 28)
    self.list:setBounds(8, 44, math.max(0, self.width - 16), math.max(0, self.height - 52))
    super.update(self, dt)
end

function EditorFXBrowser:drawSelf()
    Draw.setColor(0.08, 0.08, 0.09, 1)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
end

return EditorFXBrowser
