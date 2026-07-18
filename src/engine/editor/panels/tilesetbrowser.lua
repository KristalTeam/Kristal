--- Displays and manages tilesets in the current project.
---@class EditorTilesetBrowser : EditorControl
---@field editor Editor
---@field list EditorItemList
---@field new_button EditorButton
---@field search EditorSearchBar
---@overload fun(editor: table): EditorTilesetBrowser
local EditorTilesetBrowser, super = Class(EditorControl)

function EditorTilesetBrowser:init(editor)
    super.init(self, 0, 0, 260, 320)
    self.editor = editor
    self.search = self:addChild(EditorSearchBar({
        placeholder = "Search tilesets...",
        on_changed = function(value) self.list:setFilter(value) end
    }))
    self.new_button = self:addChild(EditorButton("New Tileset", function() self:createTileset() end))
    self.list = self:addChild(EditorItemList({
        on_select = function(item) if item then editor:setActiveTileset(item.data) end end,
        on_activate = function(item) if item then editor:showTilesetEditor(item.data) end end,
        on_rename = function(item, _, name)
            editor:performHistoryEdit("Rename Tileset", item.data, function()
                item.data.data.name = name
                return true
            end)
        end,
        on_context_menu = function(item, list, x, y) self:openContextMenu(item, list, x, y) end,
        on_drag_start = function(item)
            editor:beginDragPreview("tileset", item.label, "editor/ui/layer/tile", item.data)
        end,
        on_drag_move = function(_, list, x, y)
            local gx, gy = list:getGlobalPosition()
            editor:updateDragPreview(gx + x, gy + y)
        end,
        on_drag_end = function() editor:finishDragPreview() end,
        on_request_focus = function(control) editor.dockspace:setFocus(control) end
    }))
    self:refresh()
end

function EditorTilesetBrowser:refresh(selected_id)
    local items = {}
    for _, document in ipairs(self.editor.tileset_documents or {}) do
        table.insert(items, { id = document.id, label = document:getName(), data = document,
            icon = "editor/ui/layer/tile" })
    end
    table.sort(items, function(a, b) return a.label:lower() < b.label:lower() end)
    self.list:setItems(items)
    for index, item in ipairs(self.list.filtered_items) do
        if item.id == (selected_id or self.editor.active_tileset_id) then self.list:select(index) break end
    end
end

function EditorTilesetBrowser:createTileset()
    local used, index = {}, 1
    for _, document in ipairs(self.editor.tileset_documents) do used[document.id] = true end
    local id = "new_tileset"
    while used[id] do index = index + 1 id = "new_tileset_" .. index end
    return self.editor:openCreationDialog({
        title = "Create Tileset", templates = { Registry.getEditorTemplate("core:tileset") },
        context = { defaults = { id = id } },
        on_create = function(values)
            for _, existing in ipairs(self.editor.tileset_documents) do
                if existing.id == values.id then return false, "A tileset with that id already exists" end
            end
            local image
            if values.image and #values.image == 1 then
                image = values.image[1]
            elseif values.image and #values.image > 1 then
                image = TableUtils.copy(values.image, true)
            end
            local tile_count = values.tile_count
            if type(image) == "table" then tile_count = #image end
            local data = {
                name = values.name,
                image = image,
                tile_width = values.tile_width,
                tile_height = values.tile_height,
                tile_count = tile_count,
                tile_columns = values.tile_columns,
                margin = values.margin,
                spacing = values.spacing,
                properties = {}, tiles = {}, terrains = {}
            }
            local document = EditorTilesetDocument(self.editor, values.id, nil, data)
            table.insert(self.editor.tileset_documents, document)
            self.editor.history.serial = self.editor.history.serial + 1
            document.history_revision = self.editor.history.serial
            self:refresh(values.id)
            self.editor:setActiveTileset(document)
            self.editor:showTilesetEditor(document)
            self.editor:onHistoryChanged({ document }, false)
            return true
        end
    })
end

function EditorTilesetBrowser:openContextMenu(item, list, x, y)
    local items = { { label = "New Tileset", action = function() self:createTileset() end } }
    if item then
        table.insert(items, { label = "Open Tileset Editor", action = function() self.editor:showTilesetEditor(item.data) end })
        table.insert(items, {
            label = "Save",
            action = function() self.editor:saveTilesetDocumentToProject(item.data) end
        })
        table.insert(items, { label = "Rename", action = function() list:beginRename(item) end })
        if item.data.virtual then
            table.insert(items, { label = "Remove", action = function()
                TableUtils.removeValue(self.editor.tileset_documents, item.data)
                self:refresh()
            end })
        end
    end
    local gx, gy = list:getGlobalPosition()
    self.editor.dockspace:openContextMenu(items, gx + x, gy + y, list)
end

function EditorTilesetBrowser:update(dt)
    self.search:setBounds(8, 8, math.max(0, self.width - 16), 28)
    self.new_button:setBounds(8, 44, math.max(0, self.width - 16), 28)
    self.list:setBounds(8, 80, math.max(0, self.width - 16), math.max(0, self.height - 88))
    super.update(self, dt)
end

function EditorTilesetBrowser:drawSelf()
    Draw.setColor(0.08, 0.08, 0.09, 1)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
end

return EditorTilesetBrowser
