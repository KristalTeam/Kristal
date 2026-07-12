---@class EditorTilesetPanel : EditorControl
---@overload fun(editor: table): EditorTilesetPanel
local EditorTilesetPanel, super = Class(EditorControl)

local MODES = {
    { id = "tileset", name = "Tileset" }, { id = "tile", name = "Tile" },
    { id = "terrain", name = "Terrain" }, { id = "collision", name = "Collision" },
    { id = "animation", name = "Animation" }
}

function EditorTilesetPanel:init(editor)
    super.init(self, 0, 0, 440, 420)
    self.editor = editor
    self.document = nil
    self.tile = nil
    self.mode = "tileset"
    self.mode_buttons = {}
    for _, mode in ipairs(MODES) do
        local id = mode.id
        local button = self:addChild(EditorButton(mode.name, function() self:setMode(id) end))
        table.insert(self.mode_buttons, button)
    end
    self.add_button = self:addChild(EditorButton("Add", function() self:addItem() end))
    self.tile_grid = self:addChild(EditorTilePalette(editor, {
        show_tools = false,
        on_selection = function()
            if self.mode == "tileset" then self:setMode("tile") end
        end
    }))
    self.list = self:addChild(EditorItemList({
        on_select = function(item) self:selectItem(item and item.data) end,
        on_drag_end = function(item, list, _, y) self:reorderItem(item, list:getItemIndexAt(y)) end,
        on_context_menu = function(item, list, x, y) self:openItemContext(item, list, x, y) end,
        on_request_focus = function(control) editor.dockspace:setFocus(control) end
    }))
    self.properties = self:addChild(EditorPropertiesPanel(editor))
    self.zoom_out_button = self:addChild(EditorButton("-", function() self.tile_grid:stepZoom(-1) end))
    self.zoom_label_button = self:addChild(EditorButton("100%", function() self.tile_grid:resetZoom() end))
    self.zoom_in_button = self:addChild(EditorButton("+", function() self.tile_grid:stepZoom(1) end))
end

function EditorTilesetPanel:setDocument(document)
    self.document = document
    self.tile_grid:setTilesetDocument(document)
    self.tile = document and document:getTile(0) or nil
    self:setMode("tileset")
end

function EditorTilesetPanel:setTile(tile)
    self.tile = tile
    self.tile_grid:setSelectedTile(tile)
    if self.mode ~= "tileset" then self:rebuild() end
end

function EditorTilesetPanel:setMode(mode)
    self.mode = mode
    self:rebuild()
end

function EditorTilesetPanel:getItems()
    if not self.document then return {} end
    if self.mode == "terrain" then return self.document:getTerrainSets() end
    if self.mode == "collision" then return self.document:getCollisionShapes(self.tile) end
    if self.mode == "animation" then return self.document:getAnimationFrames(self.tile) end
    return {}
end

function EditorTilesetPanel:refreshList(selected)
    local items = {}
    for index, value in ipairs(self:getItems()) do
        local label
        if self.mode == "terrain" then label = value.name or ("Terrain Set " .. index)
        elseif self.mode == "collision" then label = string.format("%s %d", StringUtils.titleCase(value.shape or "rectangle"), index)
        else label = string.format("Tile %s  -  %sms", tostring(value.tileid or 0), tostring(value.duration or 100)) end
        table.insert(items, { id = index, label = label, data = value })
    end
    self.list:setItems(items)
    if #items > 0 then
        local selected_index = 1
        for index, item in ipairs(self.list.filtered_items) do if item.data == selected then selected_index = index break end end
        self.list:select(selected_index)
        self:selectItem(self.list:getSelectedItem().data)
    else
        self.properties:setTarget(nil)
    end
end

function EditorTilesetPanel:rebuild()
    local list_mode = self.mode == "terrain" or self.mode == "collision" or self.mode == "animation"
    self.list.visible, self.add_button.visible = list_mode, list_mode
    self.properties.visible = true
    if not self.document then self.properties:setTarget(nil) return end
    if self.mode == "tileset" then
        self.properties:setTarget(self.document:getPropertiesTarget())
    elseif self.mode == "tile" then
        self.properties:setTarget(self.document:getTilePropertiesTarget(self.tile))
    else
        self:refreshList()
    end
end

function EditorTilesetPanel:addItem()
    if not self.document then return false end
    self.editor:beginHistoryTransaction("Add Tileset Item", self.document)
    local item
    if self.mode == "terrain" then item = self.document:addTerrainSet()
    elseif self.mode == "collision" then item = self.document:addCollisionShape(self.tile)
    elseif self.mode == "animation" then item = self.document:addAnimationFrame(self.tile) end
    if item then
        self.editor:markHistoryChanged()
        self.editor:commitHistoryTransaction()
        self:refreshList(item)
        return true
    end
    self.editor:cancelHistoryTransaction()
    return false
end

function EditorTilesetPanel:getItemTarget(item)
    if not item then return nil end
    item.properties = item.properties or {}
    item.__editor_property_types = item.__editor_property_types or {}
    local set = EditorPropertySet(item.properties, item.__editor_property_types)
    local function field(label, key, numeric)
        return EditorPropertyFields.value(item, label, key, { numeric = numeric == true })
    end
    local fields, title = {}, "Tileset Item"
    if self.mode == "terrain" then
        title = item.name or "Terrain Set"
        fields = { field("Name", "name"),
            EditorPropertyFields.choice(item, "Type", "type", { "corner", "edge", "mixed" },
                { default = "mixed" }) }
    elseif self.mode == "collision" then
        title = "Tile Collision Shape"
        fields = { EditorPropertyFields.choice(item, "Shape", "shape",
                { "point", "line", "rectangle", "ellipse", "polygon", "polyline" },
                { default = "rectangle" }),
            field("X", "x", true), field("Y", "y", true),
            field("Width", "width", true), field("Height", "height", true),
            field("Rotation", "rotation", true) }
    elseif self.mode == "animation" then
        title = "Animation Frame"
        fields = { field("Tile ID", "tileid", true), field("Duration (ms)", "duration", true) }
    end
    return { title = title, fields = fields, property_set = set, properties = item.properties,
        history_owner = self.document,
        property_types = item.__editor_property_types,
        on_changed = function() self:refreshList(item) end }
end

function EditorTilesetPanel:selectItem(item)
    self.selected_item = item
    self.properties:setTarget(self:getItemTarget(item))
end

function EditorTilesetPanel:removeItem(item)
    if not item then return false end
    self.editor:beginHistoryTransaction("Remove Tileset Item", self.document)
    TableUtils.removeValue(self:getItems(), item)
    self.editor:markHistoryChanged()
    self.editor:commitHistoryTransaction()
    self:refreshList()
    return true
end

function EditorTilesetPanel:reorderItem(item, target)
    if not item then return end
    local items = self:getItems()
    local source
    for index, value in ipairs(items) do if value == item.data then source = index break end end
    if not source then return end
    self.editor:beginHistoryTransaction("Reorder Tileset Item", self.document)
    local value = table.remove(items, source)
    table.insert(items, MathUtils.clamp(target, 1, #items + 1), value)
    self.editor:markHistoryChanged()
    self.editor:commitHistoryTransaction()
    self:refreshList(value)
end

function EditorTilesetPanel:openItemContext(item, list, x, y)
    local items = { { label = "Add", action = function() self:addItem() end } }
    if item then table.insert(items, { label = "Delete", action = function() self:removeItem(item.data) end }) end
    local gx, gy = list:getGlobalPosition()
    self.editor.dockspace:openContextMenu(items, gx + x, gy + y, list)
end

function EditorTilesetPanel:update(dt)
    local button_width = math.max(64, math.floor((self.width - 16) / #self.mode_buttons))
    local x = 8
    for _, button in ipairs(self.mode_buttons) do
        button:setBounds(x, 8, button_width - 4, 28)
        button.focused = self.mode == button.label:lower()
        x = x + button_width
    end
    local toolbar_y = 42
    self.zoom_out_button:setBounds(math.max(8, self.width - 148), toolbar_y, 36, 28)
    self.zoom_label_button:setBounds(math.max(48, self.width - 108), toolbar_y, 64, 28)
    self.zoom_in_button:setBounds(math.max(116, self.width - 40), toolbar_y, 36, 28)
    self.zoom_label_button.label = string.format("%d%%", MathUtils.round(self.tile_grid.zoom * 100))

    local atlas_y = 76
    local available_height = math.max(0, self.height - atlas_y - 4)
    local atlas_height = math.floor(available_height * 0.56)
    if available_height >= 180 then
        atlas_height = MathUtils.clamp(atlas_height, 100, available_height - 80)
    else
        atlas_height = available_height
    end
    self.tile_grid:setBounds(4, atlas_y, math.max(0, self.width - 8), atlas_height)
    local details_y = atlas_y + atlas_height + 4
    local details_height = math.max(0, self.height - details_y)
    if self.list.visible then
        local list_width = MathUtils.clamp(math.floor(self.width * 0.34), 150, math.max(150, self.width - 220))
        self.add_button:setBounds(4, details_y + 4, math.max(0, list_width - 8), 28)
        self.list:setBounds(4, details_y + 36,
            math.max(0, list_width - 8), math.max(0, details_height - 40))
        self.properties:setBounds(list_width, details_y,
            math.max(0, self.width - list_width), details_height)
    else
        self.properties:setBounds(0, details_y, self.width, details_height)
    end
    super.update(self, dt)
end

function EditorTilesetPanel:drawSelf()
    Draw.setColor(0.08, 0.08, 0.09, 1)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    Draw.setColor(0.78, 0.78, 0.82, 1)
    love.graphics.setFont(EditorFont.get(16))
    love.graphics.print("Tileset Atlas", 8, 48)
    Draw.setColor(0.30, 0.30, 0.34, 1)
    love.graphics.line(0, 38.5, self.width, 38.5)
    love.graphics.line(0, 73.5, self.width, 73.5)
    love.graphics.line(0, self.tile_grid.y + self.tile_grid.height + 2.5,
        self.width, self.tile_grid.y + self.tile_grid.height + 2.5)
    if self.list.visible then
        love.graphics.line(self.properties.x + 0.5, self.properties.y,
            self.properties.x + 0.5, self.height)
    end
    if self.mode == "terrain" then
        local lancer = Assets.getTexture("kristal/lancer_construction")
        Draw.setColor(1,1,1,1)
        Draw.draw(lancer, 108, 38, 0, 2, 2)
        Draw.setColor(COLORS.yellow)
        love.graphics.print("! UNDER CONSTRUCTION !", 168, 48)
    end
end

return EditorTilesetPanel
