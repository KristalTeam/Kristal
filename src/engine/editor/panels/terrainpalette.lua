---@class EditorTerrainPalette : EditorControl
---@field document EditorTilesetDocument?
---@field editor Editor
---@field list EditorItemList
---@field search EditorSearchBar
---@overload fun(editor: table): EditorTerrainPalette
local EditorTerrainPalette, super = Class(EditorControl)

function EditorTerrainPalette:init(editor)
    super.init(self, 0, 0, 320, 240)
    self.editor = editor
    self.document = nil
    self.search = self:addChild(EditorSearchBar({
        placeholder = "Search terrains...",
        on_changed = function(value)
            self.list:setFilter(value)
            self:selectCurrent(false)
        end
    }))
    self.list = self:addChild(EditorItemList({
        row_height = 40,
        on_select = function(item) self:selectItem(item) end,
        on_activate = function(item)
            if self:selectItem(item) then self.editor:setActiveTool("terrain_brush") end
        end,
        on_request_focus = function(control) editor.dockspace:setFocus(control) end
    }))
end

function EditorTerrainPalette:getTilePreview(tile_id)
    tile_id = tonumber(tile_id)
    if not self.document or not tile_id or tile_id < 0
        or tile_id % 1 ~= 0 or tile_id >= self.document:getTileCount() then return nil end
    local document = self.document
    return function(x, y, width, height, alpha)
        Draw.setColor(1, 1, 1, alpha or 1)
        if document.tileset then
            document.tileset:drawGridTile(tile_id, x, y, width, height)
        else
            love.graphics.rectangle("line", x, y, width, height)
            love.graphics.print(tostring(tile_id), x + 3, y + 2)
        end
    end
end

function EditorTerrainPalette:setDocument(document, refresh)
    if self.document == document and not refresh then return end
    self.document = document
    self:refresh()
end

function EditorTerrainPalette:refresh()
    local items = {}
    for _, terrain in ipairs(self.document and self.document:getTerrainSets() or {}) do
        table.insert(items, {
            id = "set:" .. tostring(terrain.id),
            label = terrain.name or terrain.id,
            preview = self:getTilePreview(terrain.tile_icon),
            data = { kind = "set", terrain = terrain }
        })
        for _, variant in ipairs(terrain.terrain_variants or {}) do
            table.insert(items, {
                id = "variant:" .. tostring(terrain.id) .. ":" .. tostring(variant.id),
                label = variant.name or ("Terrain " .. tostring(variant.id)),
                indent = 1,
                preview = self:getTilePreview(variant.tile_icon),
                data = { kind = "variant", terrain = terrain, variant = variant }
            })
        end
    end
    self.list:setItems(items)
    self:selectCurrent(true)
end

function EditorTerrainPalette:selectCurrent(select_default)
    local _, terrain, variant = self.editor:getSelectedTerrain()
    for index, item in ipairs(self.list.filtered_items) do
        if item.data.kind == "variant" and item.data.terrain == terrain
            and item.data.variant == variant then
            self.list:select(index)
            return true
        end
    end
    if select_default then
        for index, item in ipairs(self.list.filtered_items) do
            if item.data.kind == "variant" then
                self.list:select(index)
                return self:selectItem(item)
            end
        end
    end
    self.list.selected_index = nil
    return false
end

function EditorTerrainPalette:selectItem(item)
    local data = item and item.data
    if not data then return false end
    if data.kind == "set" then
        local variant = data.terrain.terrain_variants
            and data.terrain.terrain_variants[1]
        if not variant then return false end
        return self.editor:setSelectedTerrain(self.document, data.terrain, variant)
    end
    if data.kind ~= "variant" then return false end
    return self.editor:setSelectedTerrain(self.document, data.terrain, data.variant)
end

function EditorTerrainPalette:update(dt)
    self.search:setBounds(8, 8, math.max(0, self.width - 16), 28)
    self.list:setBounds(8, 44, math.max(0, self.width - 16), math.max(0, self.height - 52))
    super.update(self, dt)
end

function EditorTerrainPalette:drawSelf()
    Draw.setColor(0.08, 0.08, 0.09, 1)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    if self.document and #self.document:getTerrainSets() == 0 then
        Draw.setColor(0.55, 0.55, 0.58, 1)
        love.graphics.setFont(EditorFont.get(16))
        love.graphics.printf("Create terrain sets in the Tileset Editor.",
            16, 54, math.max(0, self.width - 32), "center")
    end
end

return EditorTerrainPalette
