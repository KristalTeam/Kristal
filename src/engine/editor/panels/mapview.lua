---@class EditorMapView : EditorGameView
---@overload fun(editor?: table, document?: EditorMapDocument): EditorMapView
local EditorMapView, super = Class(EditorGameView)

local function pointsEqual(a, b)
    return a and b and a.x == b.x and a.y == b.y
end

local EXPLOSION_DURATION = 0.8
local UNEXPLOSION_SPEED = 1.5
local UNEXPLOSION_DELAY = 0.1

function EditorMapView:init(editor, document)
    super.init(self, editor, document)
    self.is_game_preview = false
    self.is_map_view = true
    self.explosions = {}
end

function EditorMapView:setCanvas() end
function EditorMapView:setTileEditingMode() end

function EditorMapView:getDocumentBounds()
    local primary = self:getPrimaryEntry()
    if not primary then return 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT end
    local min_x, min_y = primary.x, primary.y
    local max_x = primary.x + (primary.width or SCREEN_WIDTH)
    local max_y = primary.y + (primary.height or SCREEN_HEIGHT)
    for _, entry in ipairs(self.document.maps) do
        min_x = math.min(min_x, entry.x)
        min_y = math.min(min_y, entry.y)
        max_x = math.max(max_x, entry.x + (entry.width or 0))
        max_y = math.max(max_y, entry.y + (entry.height or 0))
    end
    return min_x, min_y, max_x, max_y
end

function EditorMapView:addExplosion(world_x, world_y)
    table.insert(self.explosions, { x = world_x, y = world_y, time = 0, reverse = false })
    Assets.playSound("badexplosion")
end

function EditorMapView:addUnexplosion(world_x, world_y)
    table.insert(self.explosions, { x = world_x, y = world_y, time = 0, reverse = true })
    Assets.playSound("noisolpxedab")
end

function EditorMapView:update(dt)
    for index = #self.explosions, 1, -1 do
        local effect = self.explosions[index]
        effect.time = effect.time + dt
        local duration = effect.reverse and (EXPLOSION_DURATION / UNEXPLOSION_SPEED)
            or EXPLOSION_DURATION
        local delay = effect.reverse and UNEXPLOSION_DELAY or 0
        if effect.time >= delay + duration then table.remove(self.explosions, index) end
    end
    if self.polygon_build and self.editor.live_document ~= self.document then
        local mouse_x, mouse_y = love.mouse.getPosition()
        local view_x, view_y = self:getGlobalPosition()
        local local_x, local_y = mouse_x - view_x, mouse_y - view_y
        if local_x >= 0 and local_y >= 0 and local_x < self.width and local_y < self.height then
            local world_x, world_y = self:getMapCoordinates(local_x, local_y)
            local entry = self.document.map_lookup[self.polygon_build.map_id]
            if entry then
                world_x, world_y = self:snapPointShapeToMapGrid(entry, world_x, world_y)
            end
            self.polygon_build.current_x, self.polygon_build.current_y = world_x, world_y
        else
            self.polygon_build.current_x, self.polygon_build.current_y = nil, nil
        end
    end
    super.update(self, dt)
end

function EditorMapView:centerCanvas()
    local primary = self:getPrimaryEntry()
    local primary_x, primary_y = primary and primary.x or 0, primary and primary.y or 0
    local min_x, min_y, max_x, max_y = self:getDocumentBounds()
    local width, height = (max_x - min_x) * self.view_zoom, (max_y - min_y) * self.view_zoom
    self:setCanvasPosition((self.width - width) / 2 - (min_x - primary_x) * self.view_zoom,
        (self.height - height) / 2 - (min_y - primary_y) * self.view_zoom)
end

function EditorMapView:focusMap(map_id)
    local entry = self.document and self.document.map_lookup[map_id]
    local primary = self:getPrimaryEntry()
    if not entry or not primary then return false end
    self.active_map_id = map_id
    self:setCanvasPosition(
        self.width / 2 - (entry.x + (entry.width or 0) / 2 - primary.x) * self.view_zoom,
        self.height / 2 - (entry.y + (entry.height or 0) / 2 - primary.y) * self.view_zoom)
    return true
end

function EditorMapView:selectWorldMap(entry)
    self.selected_world_map_id = entry and entry.id or nil
    self.active_map_id = entry and entry.id or self.active_map_id
    self.editor:selectMapObjects({})
    local world = self.document and self.document.world
    if entry and world and Registry.getEditorWorld(world.id) and self.editor.world_browser then
        self.editor.active_world_id = world.id
        self.editor.active_editor_world = world
        self.editor.world_browser:refresh(world.id)
        self.editor.world_browser:refreshMaps(world)
        self.editor.world_browser:selectWorldMap(entry)
    end
end

function EditorMapView:getCanvasDisplayCenter()
    local primary = self:getPrimaryEntry()
    return self.canvas_x + (primary and primary.width or SCREEN_WIDTH) * self.view_zoom / 2,
        self.canvas_y + (primary and primary.height or SCREEN_HEIGHT) * self.view_zoom / 2
end

function EditorMapView:getMapCoordinates(x, y)
    local primary = self:getPrimaryEntry()
    return (x - self.canvas_x) / self.view_zoom + (primary and primary.x or 0),
        (y - self.canvas_y) / self.view_zoom + (primary and primary.y or 0)
end

function EditorMapView:drawDocument()
    local document = self.document
    local primary = self:getPrimaryEntry()
    if not document or not primary then return end
    love.graphics.push()
    love.graphics.translate(self.canvas_x, self.canvas_y)
    love.graphics.scale(self.view_zoom, self.view_zoom)
    love.graphics.translate(-primary.x, -primary.y)
    local selected_object = self.editor and self.editor.selected_map_object
    local active_map_id = selected_object and selected_object.document == document and selected_object.map_id
        or self.active_map_id
        or document.primary_map_id
    for _, entry in ipairs(document.maps) do
        if entry.id ~= active_map_id then
            love.graphics.push()
            love.graphics.translate(entry.x, entry.y)
            document:drawPreview(entry, 1 / self.view_zoom)
            love.graphics.pop()
        end
    end
    local active_entry = document.map_lookup[active_map_id]
    if active_entry then
        love.graphics.push()
        love.graphics.translate(active_entry.x, active_entry.y)
        document:drawPreview(active_entry, 1 / self.view_zoom)
        love.graphics.pop()
    end
    love.graphics.setLineWidth(2 / self.view_zoom)
    Draw.setColor(1, 1, 1, 0.4)
    for _, entry in ipairs(document.maps) do
        if entry.width and entry.height then
            local selected = self.editor and self.editor.active_tool == "world_select"
                and self.selected_world_map_id == entry.id
            love.graphics.setLineWidth((selected and 3 or 2) / self.view_zoom)
            Draw.setColor(selected and { 1, 0.84, 0.2, 0.95 } or { 1, 1, 1, 0.4 })
            love.graphics.rectangle("line", entry.x, entry.y, entry.width, entry.height)
            if self.editor and self.editor.show_tile_grid then
                self:drawTileGrid(entry.x, entry.y, entry.width, entry.height,
                    entry.tile_width, entry.tile_height)
            end
        end
    end
    self:drawObjectLinks()
    self:drawSelectedObject()
    self:drawSelectionMarquee()
    self:drawShapePreview()
    self:drawExplosions()
    love.graphics.pop()
end

local function drawDashedLine(x1, y1, x2, y2, dash)
    local dx, dy = x2 - x1, y2 - y1
    local length = math.sqrt(dx * dx + dy * dy)
    if length == 0 then return end
    local nx, ny = dx / length, dy / length
    for distance = 0, length, dash * 2 do
        local finish = math.min(length, distance + dash)
        love.graphics.line(x1 + nx * distance, y1 + ny * distance,
            x1 + nx * finish, y1 + ny * finish)
    end
end

function EditorMapView:drawObjectLinks()
    love.graphics.setLineWidth(2 / self.view_zoom)
    Draw.setColor(0.45, 0.78, 1, 0.9)
    for _, selection in ipairs(self.editor and self.editor:getSelectedMapObjects(self.document) or {}) do
        local x1, y1 = self.document:getObjectWorldCenter(selection)
        for _, target in ipairs(self.document:getObjectLinks(selection)) do
            local x2, y2 = target.world_x, target.world_y
            if not x2 then x2, y2 = self.document:getObjectWorldCenter(target) end
            drawDashedLine(x1, y1, x2, y2, 8 / self.view_zoom)
        end
    end
    local drag = self.editor and (self.editor.object_link or self.editor.object_reference_drag)
    local source = drag and drag.source
    if source and source.document == self.document then
        local x1, y1 = self.document:getObjectWorldCenter(source)
        local mouse_x, mouse_y = love.mouse.getPosition()
        local local_x, local_y = self:toLocal(mouse_x, mouse_y)
        local x2, y2 = self:getMapCoordinates(local_x, local_y)
        local target = self.document:findObjectAt(x2, y2, { all_layers = true })
        if target and target.data ~= source.data then
            x2, y2 = self.document:getObjectWorldCenter(target)
            Draw.setColor(1, 0.84, 0.2, 0.95)
            love.graphics.circle("line", x2, y2, 7 / self.view_zoom)
        else
            Draw.setColor(0.72, 0.82, 1, 0.8)
        end
        drawDashedLine(x1, y1, x2, y2, 8 / self.view_zoom)
    end
end

function EditorMapView:getSelectionBounds(selections)
    selections = selections or (self.editor and self.editor:getSelectedMapObjects(self.document)) or {}
    local min_x, min_y, max_x, max_y
    for _, selection in ipairs(selections) do
        local left, top, right, bottom = self.document:getObjectWorldBounds(selection)
        min_x, min_y = min_x and math.min(min_x, left) or left, min_y and math.min(min_y, top) or top
        max_x, max_y = max_x and math.max(max_x, right) or right, max_y and math.max(max_y, bottom) or bottom
    end
    return min_x, min_y, max_x, max_y
end

function EditorMapView:getRotationHandle(selections)
    selections = selections or (self.editor and self.editor:getSelectedMapObjects(self.document)) or {}
    if #selections == 1 then
        local selection = selections[1]
        local origin_x, origin_y = self.document:getObjectWorldPosition(selection)
        local _, _, width = self.document:getObjectLocalRect(selection)
        local rotation = math.rad(selection.data.rotation or 0)
        local anchor_x = origin_x + width / 2 * math.cos(rotation)
        local anchor_y = origin_y + width / 2 * math.sin(rotation)
        local distance = 22 / self.view_zoom
        local handle_x = anchor_x + distance * math.sin(rotation)
        local handle_y = anchor_y - distance * math.cos(rotation)
        return handle_x, handle_y, anchor_x, anchor_y
    end
    local min_x, min_y, max_x = self:getSelectionBounds(selections)
    if not min_x then return nil end
    local anchor_x, anchor_y = (min_x + max_x) / 2, min_y
    return anchor_x, anchor_y - 22 / self.view_zoom, anchor_x, anchor_y
end

function EditorMapView:isRotationHandleAt(world_x, world_y)
    local selections = self.editor and self.editor:getSelectedMapObjects(self.document) or {}
    if #selections == 0 then return false end
    local handle_x, handle_y = self:getRotationHandle(selections)
    local distance = 9 / self.view_zoom
    return math.abs(world_x - handle_x) <= distance and math.abs(world_y - handle_y) <= distance
end

function EditorMapView:snapToMapGrid(entry, world_x, world_y)
    if Input.ctrl() then return world_x, world_y end
    local tile_width, tile_height = entry.tile_width or 40, entry.tile_height or 40
    return entry.x + MathUtils.round((world_x - entry.x) / tile_width) * tile_width,
        entry.y + MathUtils.round((world_y - entry.y) / tile_height) * tile_height
end

function EditorMapView:snapPointShapeToMapGrid(entry, world_x, world_y)
    if not Input.ctrl() then return world_x, world_y end
    local tile_width, tile_height = entry.tile_width or 40, entry.tile_height or 40
    return entry.x + MathUtils.round((world_x - entry.x) / tile_width) * tile_width,
        entry.y + MathUtils.round((world_y - entry.y) / tile_height) * tile_height
end

function EditorMapView:getTileEditTarget(world_x, world_y)
    local entry = self.document:getMapAt(world_x, world_y)
    if not entry then return nil, "Move the cursor inside a map before editing tiles" end
    local layer = self.document:getSelectedTileLayer(entry.id)
    if not layer then return nil, "Select a tile layer before editing tiles" end
    local tile_width, tile_height = self.document:getTileLayerCellSize(layer, entry.id)
    local offset_x, offset_y = layer.offsetx or 0, layer.offsety or 0
    local column = math.floor((world_x - entry.x - offset_x) / tile_width)
    local row = math.floor((world_y - entry.y - offset_y) / tile_height)
    local width, height = self.document:getTileLayerGridSize(layer, entry.id)
    if column < 0 or row < 0 or column >= width or row >= height then
        return nil, "Move the cursor inside the selected tile layer before editing tiles"
    end
    return {
        entry = entry, map_id = entry.id, layer = layer,
        column = column, row = row, width = width, height = height
    }
end

function EditorMapView:getTilePaintSource()
    local palette = self.editor and self.editor.tile_palette
    local tileset = palette and palette.document
    if not tileset or #palette.stamp == 0 then
        return nil, nil, "Select a tile in the Tile Palette before painting"
    end
    return palette, tileset
end

function EditorMapView:encodePaintTile(target, tileset, tile_id)
    local encoded, reason = self.document:encodeTileForLayer(
        target.layer, target.map_id, tileset.id, tile_id)
    if not encoded then return nil, reason end
    return encoded
end

function EditorMapView:paintTileAnchor(target, erase)
    local changed = false
    if erase then
        changed = self.document:setEncodedTile(target.layer, target.column, target.row,
            0, target.map_id, true)
    else
        local palette, tileset, reason = self:getTilePaintSource()
        if not palette then return false, reason end
        if palette.random_mode then
            local tile_id = palette:getRandomTile()
            local encoded
            encoded, reason = self:encodePaintTile(target, tileset, tile_id)
            if not encoded then return false, reason end
            changed = self.document:setEncodedTile(target.layer, target.column, target.row,
                encoded, target.map_id, true)
        else
            for stamp_y, stamp_row in ipairs(palette.stamp) do
                for stamp_x, tile_id in ipairs(stamp_row) do
                    if tile_id ~= false then
                        local column, row = target.column + stamp_x - 1, target.row + stamp_y - 1
                        if column >= 0 and row >= 0 and column < target.width and row < target.height then
                            local encoded
                            encoded, reason = self:encodePaintTile(target, tileset, tile_id)
                            if not encoded then return changed, reason end
                            if self.document:setEncodedTile(target.layer, column, row,
                                encoded, target.map_id, true) then changed = true end
                        end
                    end
                end
            end
        end
    end
    if changed then self.document:invalidatePreview(target.map_id) end
    return changed
end

function EditorMapView:fillTiles(target)
    local palette, tileset, reason = self:getTilePaintSource()
    if not palette then return false, reason end
    local original = self.document:getEncodedTile(
        target.layer, target.column, target.row, target.map_id)
    local queue = { { target.column, target.row } }
    local next_index, visited, changed = 1, {}, false
    while next_index <= #queue do
        local point = queue[next_index]
        next_index = next_index + 1
        local column, row = point[1], point[2]
        local key = column .. ":" .. row
        if not visited[key] then
            visited[key] = true
            if column >= 0 and row >= 0 and column < target.width and row < target.height
                and self.document:getEncodedTile(target.layer, column, row, target.map_id) == original then
                local tile_id = palette:getPaintTile(column - target.column, row - target.row)
                if tile_id ~= false and tile_id ~= nil then
                    local encoded
                    encoded, reason = self:encodePaintTile(target, tileset, tile_id)
                    if not encoded then return changed, reason end
                    if self.document:setEncodedTile(target.layer, column, row,
                        encoded, target.map_id, true) then changed = true end
                end
                table.insert(queue, { column - 1, row })
                table.insert(queue, { column + 1, row })
                table.insert(queue, { column, row - 1 })
                table.insert(queue, { column, row + 1 })
            end
        end
    end
    if changed then self.document:invalidatePreview(target.map_id) end
    return changed
end

function EditorMapView:beginTileEdit(tool, world_x, world_y)
    local target, reason = self:getTileEditTarget(world_x, world_y)
    if not target then
        self.editor:addWarning(reason, nil, "tile_editing")
        return true
    end
    if tool ~= "eraser" then
        local palette
        palette, _, reason = self:getTilePaintSource()
        if not palette then
            self.editor:addWarning(reason, nil, "tile_editing")
            return true
        end
    end
    self.editor:clearDiagnostics("tile_editing")
    if tool == "tile_fill" then
        self.editor:beginHistoryTransaction("Fill Tiles", self.document)
        local changed
        changed, reason = self:fillTiles(target)
        if reason then self.editor:addWarning(reason, nil, "tile_editing") end
        if changed then
            self.editor:markHistoryChanged()
            self.editor:commitHistoryTransaction()
        else
            self.editor:cancelHistoryTransaction()
        end
        return true
    end
    self.editor:beginHistoryTransaction(tool == "eraser" and "Erase Tiles" or "Paint Tiles",
        self.document)
    self.tile_stroke = { tool = tool, target = target, changed = false }
    local changed
    changed, reason = self:paintTileAnchor(target, tool == "eraser")
    self.tile_stroke.changed = changed
    if changed then self.editor:markHistoryChanged() end
    if reason then self.editor:addWarning(reason, nil, "tile_editing") end
    return true
end

function EditorMapView:continueTileEdit(world_x, world_y)
    local stroke = self.tile_stroke
    if not stroke then return false end
    local target = self:getTileEditTarget(world_x, world_y)
    if not target then return true end
    local previous = stroke.target
    if target.map_id ~= previous.map_id or target.layer ~= previous.layer then
        stroke.target = target
        local changed = self:paintTileAnchor(target, stroke.tool == "eraser")
        if changed then
            stroke.changed = true
            self.editor:markHistoryChanged()
        end
        return true
    end
    local x0, y0, x1, y1 = previous.column, previous.row, target.column, target.row
    local dx, sx = math.abs(x1 - x0), x0 < x1 and 1 or -1
    local dy, sy = -math.abs(y1 - y0), y0 < y1 and 1 or -1
    local error_value = dx + dy
    while true do
        if x0 ~= previous.column or y0 ~= previous.row then
            local anchor = {
                entry = target.entry, map_id = target.map_id, layer = target.layer,
                column = x0, row = y0, width = target.width, height = target.height
            }
            local changed, reason = self:paintTileAnchor(anchor, stroke.tool == "eraser")
            if changed then
                stroke.changed = true
                self.editor:markHistoryChanged()
            end
            if reason then self.editor:addWarning(reason, nil, "tile_editing") break end
        end
        if x0 == x1 and y0 == y1 then break end
        local doubled = 2 * error_value
        if doubled >= dy then error_value, x0 = error_value + dy, x0 + sx end
        if doubled <= dx then error_value, y0 = error_value + dx, y0 + sy end
    end
    stroke.target = target
    return true
end

function EditorMapView:getPolygonVertexAt(world_x, world_y)
    local selections = self.editor and self.editor:getSelectedMapObjects(self.document) or {}
    if #selections ~= 1 then return nil end
    local points = self.document:getPointShape(selections[1])
    if not points then return nil end
    local distance = 9 / self.view_zoom
    for index in ipairs(points) do
        local x, y = self.document:getPointShapeWorldPoint(selections[1], index)
        if x and math.abs(world_x - x) <= distance and math.abs(world_y - y) <= distance then
            return selections[1], index
        end
    end
end

function EditorMapView:getResizeCornerAt(selection, world_x, world_y)
    if not selection or selection.data.polygon or selection.data.shape == "line"
        or selection.data.shape == "polyline" then return nil end
    local _, _, width, height = self.document:getObjectLocalRect(selection)
    if width == 0 and height == 0 then return nil end
    local object_x, object_y = self.document:getObjectWorldPosition(selection)
    local rotation = -math.rad(selection.data.rotation or 0)
    local dx, dy = world_x - object_x, world_y - object_y
    local local_x = dx * math.cos(rotation) - dy * math.sin(rotation)
    local local_y = dx * math.sin(rotation) + dy * math.cos(rotation)
    local distance = 10 / self.view_zoom
    local corners = {
        { id = "nw", x = 0, y = 0 }, { id = "ne", x = width, y = 0 },
        { id = "sw", x = 0, y = height }, { id = "se", x = width, y = height }
    }
    for _, corner in ipairs(corners) do
        if math.abs(local_x - corner.x) <= distance
            and math.abs(local_y - corner.y) <= distance then return corner.id end
    end
end

function EditorMapView:getSelectedResizeCornerAt(world_x, world_y)
    local selections = self.editor and self.editor:getSelectedMapObjects(self.document) or {}
    if #selections ~= 1 then return nil end
    local corner = self:getResizeCornerAt(selections[1], world_x, world_y)
    if corner then return selections[1], corner end
end

function EditorMapView:getResizeCursor(selection, corner)
    local _, _, width, height = self.document:getObjectLocalRect(selection)
    local corner_x = (corner == "ne" or corner == "se") and width or 0
    local corner_y = (corner == "sw" or corner == "se") and height or 0
    local angle = math.atan2(corner_y - height / 2, corner_x - width / 2)
        + math.rad(selection.data.rotation or 0)
    return math.sin(angle * 2) >= 0 and "resize_diag_l" or "resize_diag_r"
end

function EditorMapView:openPolygonVertexContext(selection, index, x, y)
    local points = self.document:getPointShape(selection)
    local shape = StringUtils.titleCase(selection.data.shape or "polygon")
    if selection.data.shape == "line" then return false end
    local next_index = selection.data.polygon and index % #points + 1 or index + 1
    local items = {}
    if points[next_index] then
        local x1, y1 = self.document:getPointShapeWorldPoint(selection, index)
        local x2, y2 = self.document:getPointShapeWorldPoint(selection, next_index)
        table.insert(items, { label = "Insert Vertex After", action = function()
            local inserted = self.editor:performHistoryEdit("Insert " .. shape .. " Vertex", self.document, function()
                return self.document:insertPointShapeWorldPoint(selection, index, (x1 + x2) / 2, (y1 + y2) / 2)
            end)
            if inserted then self.editor:selectMapObjects({ selection }, selection) end
        end })
    end
    local minimum = selection.data.polygon and 3 or 2
    if #points > minimum then
        table.insert(items, { label = "Delete Vertex", action = function()
            if self.editor:performHistoryEdit("Delete " .. shape .. " Vertex", self.document, function()
                return self.document:removePointShapePoint(selection, index)
            end) then
                self.editor:selectMapObjects({ selection }, selection)
            end
        end })
    end
    return self.editor.dockspace:openContextMenu(items, x, y, self)
end

function EditorMapView:drawSelectedObject()
    local selections = self.editor and self.editor:getSelectedMapObjects(self.document) or {}
    if #selections == 0 then return end
    love.graphics.setLineWidth(2 / self.view_zoom)
    Draw.setColor(1, 0.86, 0.2, 1)
    for _, selection in ipairs(selections) do
        local x, y = self.document:getObjectWorldPosition(selection)
        local _, _, width, height = self.document:getObjectLocalRect(selection)
        love.graphics.push()
        love.graphics.translate(x, y)
        love.graphics.rotate(math.rad(selection.data.rotation or 0))
        if width == 0 and height == 0 then
            love.graphics.circle("line", 0, 0, 8 / self.view_zoom)
        elseif (selection.data.polygon and #selection.data.polygon >= 3)
            or ((selection.data.shape == "line" or selection.data.shape == "polyline")
                and selection.data.polyline
                and #selection.data.polyline >= 2) then
            local points = selection.data.polygon or selection.data.polyline
            local coordinates = {}
            for _, point in ipairs(points) do
                table.insert(coordinates, point.x or point[1] or 0)
                table.insert(coordinates, point.y or point[2] or 0)
            end
            if selection.data.polygon then
                love.graphics.polygon("line", coordinates)
            else
                for _, edge in ipairs(MapUtils.getPolylineEdges(selection.data, #points)) do
                    local first, second = points[edge[1]], points[edge[2]]
                    love.graphics.line(first.x or first[1] or 0, first.y or first[2] or 0,
                        second.x or second[1] or 0, second.y or second[2] or 0)
                end
            end
            if #selections == 1 then
                local radius = 5 / self.view_zoom
                for index = 1, #coordinates, 2 do
                    love.graphics.circle("fill", coordinates[index], coordinates[index + 1], radius)
                end
            end
        else
            love.graphics.rectangle("line", 0, 0, width, height)
            if #selections == 1 then
                local handle = 7 / self.view_zoom
                love.graphics.rectangle("fill", -handle / 2, -handle / 2, handle, handle)
                love.graphics.rectangle("fill", width - handle / 2, -handle / 2, handle, handle)
                love.graphics.rectangle("fill", -handle / 2, height - handle / 2, handle, handle)
                love.graphics.rectangle("fill", width - handle / 2, height - handle / 2, handle, handle)
            end
        end
        love.graphics.pop()
    end
    local min_x, min_y, max_x, max_y = self:getSelectionBounds(selections)
    if #selections > 1 then
        Draw.setColor(1, 0.86, 0.2, 0.7)
        love.graphics.rectangle("line", min_x, min_y, max_x - min_x, max_y - min_y)
    end
    local handle_x, handle_y, anchor_x, anchor_y = self:getRotationHandle(selections)
    Draw.setColor(1, 0.86, 0.2, 0.8)
    love.graphics.line(anchor_x, anchor_y, handle_x, handle_y)
    love.graphics.circle("fill", handle_x, handle_y, 5 / self.view_zoom)
end

function EditorMapView:drawSelectionMarquee()
    local drag = self.selection_marquee
    if not drag then return end
    local x, y = math.min(drag.start_x, drag.current_x), math.min(drag.start_y, drag.current_y)
    local width, height = math.abs(drag.current_x - drag.start_x), math.abs(drag.current_y - drag.start_y)
    Draw.setColor(0.3, 0.62, 1, 0.16)
    love.graphics.rectangle("fill", x, y, width, height)
    Draw.setColor(0.48, 0.76, 1, 0.95)
    love.graphics.setLineWidth(1 / self.view_zoom)
    love.graphics.rectangle("line", x, y, width, height)
end

function EditorMapView:drawShapePreview()
    if self.polygon_build then
        local build = self.polygon_build
        local coordinates = {}
        for _, point in ipairs(build.points) do
            table.insert(coordinates, point.x)
            table.insert(coordinates, point.y)
        end
        love.graphics.setLineWidth(2 / self.view_zoom)
        Draw.setColor(0.48, 0.78, 1, 0.9)
        if #coordinates >= 4 then love.graphics.line(coordinates) end
        if #build.points >= 1 and build.current_x then
            local last = build.points[#build.points]
            Draw.setColor(0.48, 0.78, 1, 0.45)
            if last.x ~= build.current_x or last.y ~= build.current_y then
                love.graphics.line(last.x, last.y, build.current_x, build.current_y)
            end
            love.graphics.circle("fill", build.current_x, build.current_y, 3 / self.view_zoom)
            love.graphics.circle("line", build.current_x, build.current_y, 6 / self.view_zoom)
            if build.shape == "polygon" and #build.points >= 2 then
                love.graphics.line(build.current_x, build.current_y, build.points[1].x, build.points[1].y)
            end
        end
        Draw.setColor(0.48, 0.78, 1, 1)
        for _, point in ipairs(build.points) do
            love.graphics.circle("fill", point.x, point.y, 4 / self.view_zoom)
        end
        return
    end
    local drag = self.event_region_drag or self.shape_drag
    if not drag then return end
    local x, y = math.min(drag.start_x, drag.current_x), math.min(drag.start_y, drag.current_y)
    local width, height = math.abs(drag.current_x - drag.start_x), math.abs(drag.current_y - drag.start_y)
    love.graphics.setLineWidth(2 / self.view_zoom)
    Draw.setColor(0.48, 0.78, 1, 0.9)
    if drag.shape == "ellipse" then
        love.graphics.ellipse("line", x + width / 2, y + height / 2, width / 2, height / 2)
    elseif drag.shape == "line" then
        love.graphics.line(drag.start_x, drag.start_y, drag.current_x, drag.current_y)
    else
        love.graphics.rectangle("line", x, y, width, height)
    end
end

function EditorMapView:finishPointShape()
    local build = self.polygon_build
    if not build then return false end
    local points = {}
    for _, point in ipairs(build.points) do
        if not pointsEqual(points[#points], point) then
            table.insert(points, { x = point.x, y = point.y })
        end
    end
    if build.shape == "polygon" and #points > 1 and pointsEqual(points[1], points[#points]) then
        table.remove(points)
    end
    local minimum = build.shape == "polygon" and 3 or 2
    if #points < minimum then
        local instructions = build.shape == "polygon"
            and "Click additional points, then press Enter, double-click, or click the first point to finish."
            or "Click additional points, then press Enter or double-click to finish."
        self.editor:addWarning("A " .. build.shape .. " requires at least " .. minimum .. " distinct points",
            instructions, "shape_placement")
        return true
    end
    if build.shape == "polygon" then
        local area = 0
        for index, point in ipairs(points) do
            local next_point = points[index % #points + 1]
            area = area + point.x * next_point.y - next_point.x * point.y
        end
        if math.abs(area) < 0.001 then
            self.editor:addWarning("A polygon needs a non-zero enclosed area", nil, "shape_placement")
            return true
        end
    end
    self.polygon_build = nil
    self.editor:clearDiagnostics("shape_placement")
    local object, layer_or_reason, map_id = self.document:addPointShapeObject(build.shape, build.map_id, points)
    if not object then
        self.editor:cancelHistoryTransaction()
        self.editor:addWarning(layer_or_reason, nil, "shape_placement")
        return true
    end
    local selection = self.document:getObjectSelection(map_id, layer_or_reason, object)
    selection.view = self
    self.editor:selectMapObject(selection)
    self.editor:markHistoryChanged()
    self.editor:commitHistoryTransaction()
    return true
end

function EditorMapView:finishPolygon()
    return self:finishPointShape()
end

function EditorMapView:cancelPolygon()
    if not self.polygon_build then return false end
    self.polygon_build = nil
    self.editor:cancelHistoryTransaction()
    self.editor:clearDiagnostics("shape_placement")
    return true
end

function EditorMapView:cancelEventRegion()
    if not self.event_region_drag then return false end
    self.event_region_drag = nil
    self.editor:cancelHistoryTransaction()
    return true
end

function EditorMapView:cancelEventPaint()
    if not self.event_paint_stroke then return false end
    self.event_paint_stroke = nil
    self.editor:cancelHistoryTransaction()
    return true
end

function EditorMapView:getEventPaintCell(event_id, world_x, world_y)
    local entry = self.document:getMapAt(world_x, world_y)
    if not entry then return nil, "Paint events within a map's bounds" end
    local layer = self.document:getSelectedObjectLayer(entry.id)
    if not layer then return nil, "Select an object layer before placing an event" end
    local tile_width, tile_height = entry.tile_width or 40, entry.tile_height or 40
    local base_x = entry.x + (layer.offsetx or 0)
    local base_y = entry.y + (layer.offsety or 0)
    local event_class = Registry.getEditorEvent(event_id)
    local point = event_class and event_class.placement_shape == "point"
    local local_x, local_y = world_x - base_x, world_y - base_y
    local cell_x = point and MathUtils.round(local_x / tile_width) or math.floor(local_x / tile_width)
    local cell_y = point and MathUtils.round(local_y / tile_height) or math.floor(local_y / tile_height)
    return {
        entry = entry, layer = layer, x = cell_x, y = cell_y,
        tile_width = tile_width, tile_height = tile_height, point = point,
        base_x = base_x, base_y = base_y,
        key = table.concat({ entry.id, layer._editor_uid or layer.id or layer.name, cell_x, cell_y }, ":")
    }
end

function EditorMapView:placeEventPaintCell(stroke, cell)
    if stroke.visited[cell.key] then return false end
    stroke.visited[cell.key] = true
    local world_x = cell.base_x + (cell.x + (cell.point and 0 or 0.5)) * cell.tile_width
    local world_y = cell.base_y + (cell.y + (cell.point and 0 or 0.5)) * cell.tile_height
    local object, layer_or_reason, map_id = self.document:addEditorObject(
        stroke.event_id, cell.entry.id, world_x, world_y, { free = false })
    if not object then
        stroke.error = layer_or_reason
        return false
    end
    stroke.changed = true
    stroke.selection = self.document:getObjectSelection(map_id, layer_or_reason, object)
    stroke.selection.view = self
    self.editor:markHistoryChanged()
    return true
end

function EditorMapView:beginEventPaint(event_id, world_x, world_y)
    local cell, reason = self:getEventPaintCell(event_id, world_x, world_y)
    if not cell then
        self.editor:addWarning(reason, nil, "event_placement")
        return true
    end
    self.editor:beginHistoryTransaction("Paint Events", self.document)
    local stroke = { event_id = event_id, visited = {}, changed = false, last_cell = cell }
    self.event_paint_stroke = stroke
    self:placeEventPaintCell(stroke, cell)
    return true
end

function EditorMapView:continueEventPaint(world_x, world_y)
    local stroke = self.event_paint_stroke
    if not stroke then return false end
    local cell = self:getEventPaintCell(stroke.event_id, world_x, world_y)
    if not cell then return true end
    local last = stroke.last_cell
    if last and last.entry == cell.entry and last.layer == cell.layer then
        local x0, y0, x1, y1 = last.x, last.y, cell.x, cell.y
        local dx, sx = math.abs(x1 - x0), x0 < x1 and 1 or -1
        local dy, sy = -math.abs(y1 - y0), y0 < y1 and 1 or -1
        local error_value = dx + dy
        while true do
            local step = TableUtils.copy(cell)
            step.x, step.y = x0, y0
            step.key = table.concat({ cell.entry.id,
                cell.layer._editor_uid or cell.layer.id or cell.layer.name, x0, y0 }, ":")
            self:placeEventPaintCell(stroke, step)
            if x0 == x1 and y0 == y1 then break end
            local doubled = 2 * error_value
            if doubled >= dy then error_value, x0 = error_value + dy, x0 + sx end
            if doubled <= dx then error_value, y0 = error_value + dx, y0 + sy end
        end
    else
        self:placeEventPaintCell(stroke, cell)
    end
    stroke.last_cell = cell
    return true
end

function EditorMapView:drawExplosions()
    local frames = Assets.getFrames("misc/realistic_explosion")
    if not frames or #frames == 0 then return end
    for _, effect in ipairs(self.explosions) do
        local delay = effect.reverse and UNEXPLOSION_DELAY or 0
        if effect.time >= delay then
            local duration = effect.reverse and (EXPLOSION_DURATION / UNEXPLOSION_SPEED)
                or EXPLOSION_DURATION
            local visual_time = effect.time - delay
            local frame_index = math.min(#frames, math.floor(visual_time / duration * #frames) + 1)
            if effect.reverse then frame_index = #frames - frame_index + 1 end
            local frame = frames[math.max(1, frame_index)]
            Draw.setColor(1, 1, 1, 1)
            Draw.draw(frame, effect.x, effect.y, 0, 2, 2, frame:getWidth() / 2, frame:getHeight() / 2)
        end
    end
end

function EditorMapView:drawPreview()
    self:drawDocument()
    self:drawCursorAndCoordinates()
end

function EditorMapView:drawSelf()
    Draw.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    self:drawPreview()
    self:drawScaleReadout()
    Draw.setColor(1, 1, 1, 1)
end

function EditorMapView:onFocus()
    if self.editor and not self.editor.suppress_panel_activation then
        self.editor:activateMapDocument(self.document, { select_panel = false })
    end
end

function EditorMapView:onMousePressed(x, y, button, presses)
    if self.editor and not self.editor.suppress_panel_activation
        and self.editor.active_document ~= self.document then
        self.editor:activateMapDocument(self.document, { select_panel = false })
    end
    if self.editor and self.editor.live_document == self.document then
        return self.editor.game_preview:onMousePressed(x, y, button, presses)
    end
    if button == 1 or button == 2 then
        local world_x, world_y = self:getMapCoordinates(x, y)
        local tool = self.editor.active_tool
        if tool == "link" then
            if button == 2 then
                return self.editor:cancelObjectLink() or true
            end
            local selection = self.document:findObjectAt(world_x, world_y,
                self.editor.object_link and { all_layers = true } or nil)
            if selection then selection.view = self end
            if self.editor.object_link then
                return self.editor:finishObjectLink(selection)
            end
            if not selection then
                if self.editor.message_bar then
                    self.editor.message_bar:setStatus("Link Objects: click the source object first")
                end
                return true
            end
            local global_x, global_y = self:getGlobalPosition()
            return self.editor:chooseObjectLink(selection, global_x + x, global_y + y)
        end
        if tool == "world_select" then
            if button == 1 then
                local entry = self.document:getMapAt(world_x, world_y)
                self:selectWorldMap(entry)
                if entry then
                    self.map_drag = {
                        entry = entry,
                        start_x = world_x,
                        start_y = world_y,
                        entry_x = entry.x,
                        entry_y = entry.y
                    }
                    self.editor:beginHistoryTransaction("Move Map", self.document)
                end
                return true
            end
            return false
        end
        if self.polygon_build and button == 2 then
            table.remove(self.polygon_build.points)
            if #self.polygon_build.points == 0 then self:cancelPolygon() end
            return true
        end
        if button == 1 and (tool == "tile_brush" or tool == "tile_fill") then
            return self:beginTileEdit(tool, world_x, world_y)
        end
        if button == 1 and tool == "eraser" then
            local entry = self.document:getMapAt(world_x, world_y)
            if entry and self.document:getSelectedTileLayer(entry.id) then
                return self:beginTileEdit(tool, world_x, world_y)
            end
        end
        if button == 1 and tool == "select" then
            local vertex_selection, vertex_index = self:getPolygonVertexAt(world_x, world_y)
            if vertex_selection then
                self.polygon_vertex_drag = { selection = vertex_selection, index = vertex_index }
                local shape = StringUtils.titleCase(vertex_selection.data.shape or "polygon")
                self.editor:beginHistoryTransaction("Move " .. shape .. " Vertex", self.document)
                return true
            end
        end
        if button == 2 and tool == "select" then
            local vertex_selection, vertex_index = self:getPolygonVertexAt(world_x, world_y)
            if vertex_selection and vertex_selection.data.shape ~= "line" then
                local global_x, global_y = self:getGlobalPosition()
                return self:openPolygonVertexContext(vertex_selection, vertex_index,
                    global_x + x, global_y + y)
            end
        end
        if button == 1 and tool == "select" and self:isRotationHandleAt(world_x, world_y) then
            local selections = self.editor:getSelectedMapObjects(self.document)
            local min_x, min_y, max_x, max_y = self:getSelectionBounds(selections)
            local center_x, center_y = (min_x + max_x) / 2, (min_y + max_y) / 2
            local snapshots = {}
            for _, selected in ipairs(selections) do
                local object_x, object_y = self.document:getObjectWorldCenter(selected)
                table.insert(snapshots, {
                    selection = selected,
                    rotation = selected.data.rotation or 0,
                    center_x = object_x,
                    center_y = object_y
                })
            end
            self.rotation_drag = {
                center_x = center_x, center_y = center_y,
                start_angle = math.atan2(world_y - center_y, world_x - center_x),
                snapshots = snapshots
            }
            self.editor:beginHistoryTransaction("Rotate Objects", self.document)
            return true
        end
        if button == 1 and tool == "select" then
            local resize_selection, resize_corner = self:getSelectedResizeCornerAt(world_x, world_y)
            if resize_selection then
                local object_x, object_y = self.document:getObjectWorldPosition(resize_selection)
                local _, _, width, height = self.document:getObjectLocalRect(resize_selection)
                local rotation = math.rad(resize_selection.data.rotation or 0)
                local opposite_x = (resize_corner == "nw" or resize_corner == "sw") and width or 0
                local opposite_y = (resize_corner == "nw" or resize_corner == "ne") and height or 0
                self.object_drag = {
                    selection = resize_selection,
                    selections = {},
                    resize = true,
                    resize_corner = resize_corner,
                    resize_cursor = self:getResizeCursor(resize_selection, resize_corner),
                    scaling_mode = self.document:getObjectScalingMode(resize_selection),
                    base_width = resize_selection.data.width or 0,
                    base_height = resize_selection.data.height or 0,
                    fixed_x = object_x + opposite_x * math.cos(rotation) - opposite_y * math.sin(rotation),
                    fixed_y = object_y + opposite_x * math.sin(rotation) + opposite_y * math.cos(rotation)
                }
                self.editor:beginHistoryTransaction("Resize Object", self.document)
                return true
            end
        end
        local selection = (button == 2 or tool ~= "object")
            and self.document:findObjectAt(world_x, world_y) or nil
        if selection then selection.view = self end
        if button == 2 then
            if selection then
                local global_x, global_y = self:getGlobalPosition()
                return self.editor:openMapObjectContext(selection, global_x + x, global_y + y)
            end
            return false
        end
        if tool == "object" and self.editor.placement_tile then
            local tile = self.editor.placement_tile
            return self.editor:placeTileObject(self, tile.tileset, tile.tile_id, world_x, world_y)
        elseif tool == "object" and self.editor.placement_event_id then
            local event_class = Registry.getEditorEvent(self.editor.placement_event_id)
            if event_class and event_class.placement_shape == "region" then
                local entry = self.document:getMapAt(world_x, world_y) or self.document:getPrimaryMap()
                if not self.document:getSelectedObjectLayer(entry.id) then
                    self.editor:addWarning("Select an object layer before placing an event",
                        nil, "event_placement")
                    return true
                end
                world_x, world_y = self:snapToMapGrid(entry, world_x, world_y)
                self.event_region_drag = {
                    event_id = self.editor.placement_event_id,
                    map_id = entry.id,
                    start_x = world_x, start_y = world_y,
                    current_x = world_x, current_y = world_y
                }
                self.editor:beginHistoryTransaction("Place Event Region", self.document)
                return true
            end
            if Input.alt() then
                return self:beginEventPaint(self.editor.placement_event_id, world_x, world_y)
            end
            return self.editor:placeEvent(self, self.editor.placement_event_id, world_x, world_y)
        elseif tool == "shape" and self.editor.shape_mode ~= "point"
            and self.editor.shape_mode ~= "line" and self.editor.shape_mode ~= "polygon"
            and self.editor.shape_mode ~= "polyline" then
            self.shape_drag = { shape = self.editor.shape_mode, start_x = world_x, start_y = world_y,
                current_x = world_x, current_y = world_y }
            self.editor:beginHistoryTransaction("Create Shape", self.document)
            return true
        elseif tool == "shape" and self.editor.shape_mode == "point" then
            local entry = self.document:getMapAt(world_x, world_y) or self.document:getPrimaryMap()
            if not Input.ctrl() then
                world_x = MathUtils.round(world_x / (entry.tile_width or 40)) * (entry.tile_width or 40)
                world_y = MathUtils.round(world_y / (entry.tile_height or 40)) * (entry.tile_height or 40)
            end
            self.editor:beginHistoryTransaction("Create Point", self.document)
            local object, layer_or_reason, map_id = self.document:addShapeObject("point", entry.id, world_x, world_y, 0, 0)
            if not object then
                self.editor:cancelHistoryTransaction()
                self.editor:addWarning(layer_or_reason, nil, "shape_placement")
                return true
            end
            local point_selection = self.document:getObjectSelection(map_id, layer_or_reason, object)
            point_selection.view = self
            self.editor:selectMapObject(point_selection)
            self.editor:markHistoryChanged()
            self.editor:commitHistoryTransaction()
            return true
        elseif tool == "shape" and (self.editor.shape_mode == "line"
            or self.editor.shape_mode == "polygon"
            or self.editor.shape_mode == "polyline") then
            local shape = self.editor.shape_mode
            local build = self.polygon_build
            local entry = build and self.document.map_lookup[build.map_id]
                or self.document:getMapAt(world_x, world_y) or self.document:getPrimaryMap()
            if not build then
                if not self.document:getSelectedObjectLayer(entry.id) then
                    self.editor:addWarning("Select an object layer before creating a " .. shape,
                        nil, "shape_placement")
                    return true
                end
                build = { shape = shape, map_id = entry.id, points = {} }
                self.polygon_build = build
                self.editor:beginHistoryTransaction("Create " .. StringUtils.titleCase(shape), self.document)
            end
            world_x, world_y = self:snapPointShapeToMapGrid(entry, world_x, world_y)
            local first = build.points[1]
            local close_distance = 9 / self.view_zoom
            if shape == "polygon" and #build.points >= 3 and first
                and math.abs(world_x - first.x) <= close_distance
                and math.abs(world_y - first.y) <= close_distance then
                return self:finishPointShape()
            end
            local point = { x = world_x, y = world_y }
            if not pointsEqual(build.points[#build.points], point) then table.insert(build.points, point) end
            build.current_x, build.current_y = world_x, world_y
            if shape == "line" and #build.points == 2 then return self:finishPointShape() end
            if presses and presses >= 2 then return self:finishPointShape() end
            return true
        elseif tool == "eraser" then
            self.editor:selectMapObject(selection)
            return selection and self.editor:deleteSelectedMapObject(false) or true
        end
        if selection and tool == "select" then
            if Input.shift() then
                self.editor:selectMapObject(selection, true)
                return true
            elseif not self.editor:isMapObjectSelected(selection) then
                self.editor:selectMapObject(selection)
            end
            local selections = self.editor:getSelectedMapObjects(self.document)
            local snapshots = {}
            for _, selected in ipairs(selections) do
                table.insert(snapshots, {
                    selection = selected,
                    x = selected.data.x or 0,
                    y = selected.data.y or 0,
                    width = selected.data.width or 0,
                    height = selected.data.height or 0
                })
            end
            self.object_drag = {
                selection = selection,
                selections = snapshots,
                resize = false,
                start_x = world_x,
                start_y = world_y,
                object_x = selection.data.x or 0,
                object_y = selection.data.y or 0,
                width = selection.data.width or 0,
                height = selection.data.height or 0
            }
            self.editor:beginHistoryTransaction("Move Objects", self.document)
            return true
        end
        if not selection and tool == "select" then
            local entry = self.document:getMapAt(world_x, world_y)
            local edge = 7 / self.view_zoom
            local on_edge = entry and (math.abs(world_x - entry.x) <= edge
                or math.abs(world_x - entry.x - entry.width) <= edge
                or math.abs(world_y - entry.y) <= edge
                or math.abs(world_y - entry.y - entry.height) <= edge)
            if on_edge then
                self.map_drag = { entry = entry, start_x = world_x, start_y = world_y,
                    entry_x = entry.x, entry_y = entry.y }
                self.editor:beginHistoryTransaction("Move Map", self.document)
                return true
            end
            self.selection_marquee = {
                start_x = world_x, start_y = world_y,
                current_x = world_x, current_y = world_y,
                additive = Input.shift()
            }
            return true
        end
        if tool == "select" or tool == "object" or tool == "link" then return true end
    end
    return super.onMousePressed(self, x, y, button, presses)
end

function EditorMapView:onMouseMoved(x, y, dx, dy)
    if self.editor and self.editor.live_document == self.document then
        return self.editor.game_preview:onMouseMoved(x, y, dx, dy)
    end
    local world_x, world_y = self:getMapCoordinates(x, y)
    if self.tile_stroke then return self:continueTileEdit(world_x, world_y) end
    if self.event_paint_stroke then return self:continueEventPaint(world_x, world_y) end
    if self.polygon_build then
        local entry = self.document.map_lookup[self.polygon_build.map_id]
        if entry then world_x, world_y = self:snapPointShapeToMapGrid(entry, world_x, world_y) end
        self.polygon_build.current_x, self.polygon_build.current_y = world_x, world_y
        return true
    end
    if self.polygon_vertex_drag then
        local drag = self.polygon_vertex_drag
        world_x, world_y = self:snapPointShapeToMapGrid(drag.selection.entry, world_x, world_y)
        if self.document:setPointShapeWorldPoint(drag.selection, drag.index, world_x, world_y) then
            self.editor:markHistoryChanged()
        end
        return true
    end
    if self.event_region_drag then
        local entry = self.document.map_lookup[self.event_region_drag.map_id]
        if entry then world_x, world_y = self:snapToMapGrid(entry, world_x, world_y) end
        self.event_region_drag.current_x, self.event_region_drag.current_y = world_x, world_y
        return true
    end
    if self.shape_drag then
        self.shape_drag.current_x, self.shape_drag.current_y = world_x, world_y
        return true
    end
    if self.selection_marquee then
        self.selection_marquee.current_x, self.selection_marquee.current_y = world_x, world_y
        return true
    end
    if self.rotation_drag then
        local drag = self.rotation_drag
        local angle = math.atan2(world_y - drag.center_y, world_x - drag.center_x)
        local delta = math.deg(angle - drag.start_angle)
        if not Input.ctrl() then delta = MathUtils.round(delta / 15) * 15 end
        local radians = math.rad(delta)
        local invalidated = {}
        for _, snapshot in ipairs(drag.snapshots) do
            local selection = snapshot.selection
            local relative_x, relative_y = snapshot.center_x - drag.center_x, snapshot.center_y - drag.center_y
            local center_x = drag.center_x + relative_x * math.cos(radians) - relative_y * math.sin(radians)
            local center_y = drag.center_y + relative_x * math.sin(radians) + relative_y * math.cos(radians)
            local rotation = snapshot.rotation + delta
            local object_rotation = math.rad(rotation)
            local _, _, width, height = self.document:getObjectLocalRect(selection)
            local half_width, half_height = width / 2, height / 2
            local top_left_x = center_x - half_width * math.cos(object_rotation) + half_height * math.sin(object_rotation)
            local top_left_y = center_y - half_width * math.sin(object_rotation) - half_height * math.cos(object_rotation)
            selection.data.x = top_left_x - selection.entry.x - (selection.layer.offsetx or 0)
            selection.data.y = top_left_y - selection.entry.y - (selection.layer.offsety or 0)
            selection.data.rotation = rotation % 360
            invalidated[selection.map_id] = true
        end
        for map_id in pairs(invalidated) do self.document:invalidatePreview(map_id) end
        self.editor:markHistoryChanged()
        return true
    end
    if self.object_drag then
        local drag = self.object_drag
        local data = drag.selection.data
        local tile_width = drag.selection.entry.tile_width or 40
        local tile_height = drag.selection.entry.tile_height or 40
        local function snap(value, size)
            return Input.ctrl() and value or MathUtils.round(value / size) * size
        end
        if drag.resize then
            local rotation = math.rad(data.rotation or 0)
            local inverse = -rotation
            local relative_x, relative_y = world_x - drag.fixed_x, world_y - drag.fixed_y
            local local_x = relative_x * math.cos(inverse) - relative_y * math.sin(inverse)
            local local_y = relative_x * math.sin(inverse) + relative_y * math.cos(inverse)
            local right = drag.resize_corner == "ne" or drag.resize_corner == "se"
            local bottom = drag.resize_corner == "sw" or drag.resize_corner == "se"
            local width = math.max(0, snap(right and local_x or -local_x, tile_width))
            local height = math.max(0, snap(bottom and local_y or -local_y, tile_height))
            if drag.scaling_mode == "scale" and drag.base_width > 0 and drag.base_height > 0 then
                data.scale_x = width / drag.base_width
                data.scale_y = height / drag.base_height
            else
                data.width, data.height = width, height
            end
            local opposite_x = right and 0 or width
            local opposite_y = bottom and 0 or height
            local origin_x = drag.fixed_x - opposite_x * math.cos(rotation) + opposite_y * math.sin(rotation)
            local origin_y = drag.fixed_y - opposite_x * math.sin(rotation) - opposite_y * math.cos(rotation)
            data.x = origin_x - drag.selection.entry.x - (drag.selection.layer.offsetx or 0)
            data.y = origin_y - drag.selection.entry.y - (drag.selection.layer.offsety or 0)
        else
            local delta_x, delta_y = world_x - drag.start_x, world_y - drag.start_y
            if not Input.ctrl() then
                delta_x = MathUtils.round(delta_x / tile_width) * tile_width
                delta_y = MathUtils.round(delta_y / tile_height) * tile_height
            end
            local invalidated = {}
            for _, snapshot in ipairs(drag.selections) do
                snapshot.selection.data.x = snapshot.x + delta_x
                snapshot.selection.data.y = snapshot.y + delta_y
                invalidated[snapshot.selection.map_id] = true
            end
            for map_id in pairs(invalidated) do self.document:invalidatePreview(map_id) end
            self.editor:markHistoryChanged()
            return true
        end
        self.document:invalidatePreview(drag.selection.map_id)
        self.editor:markHistoryChanged()
        return true
    end
    if self.map_drag then
        local drag = self.map_drag
        local x2, y2 = drag.entry_x + world_x - drag.start_x, drag.entry_y + world_y - drag.start_y
        if not Input.ctrl() then
            x2 = MathUtils.round(x2 / (drag.entry.tile_width or 40)) * (drag.entry.tile_width or 40)
            y2 = MathUtils.round(y2 / (drag.entry.tile_height or 40)) * (drag.entry.tile_height or 40)
        end
        self.document:setMapPosition(drag.entry.id, x2, y2)
        self.editor:markHistoryChanged()
        return true
    end
    return super.onMouseMoved(self, x, y, dx, dy)
end

function EditorMapView:onMouseReleased(x, y, button, presses)
    if self.editor and self.editor.live_document == self.document then
        return self.editor.game_preview:onMouseReleased(x, y, button, presses)
    end
    if button == 1 and self.tile_stroke then
        local changed = self.tile_stroke.changed
        self.tile_stroke = nil
        if changed then
            self.editor:commitHistoryTransaction()
        else
            self.editor:cancelHistoryTransaction()
        end
        return true
    end
    if button == 1 and self.event_paint_stroke then
        local stroke = self.event_paint_stroke
        self.event_paint_stroke = nil
        if stroke.changed then
            self.editor:commitHistoryTransaction()
            if stroke.selection then self.editor:selectMapObject(stroke.selection) end
            self.editor:clearDiagnostics("event_placement")
        else
            self.editor:cancelHistoryTransaction()
            if stroke.error then self.editor:addWarning(stroke.error, nil, "event_placement") end
        end
        return true
    end
    if button == 1 and self.event_region_drag then
        local drag = self.event_region_drag
        self.event_region_drag = nil
        local x1, y1 = math.min(drag.start_x, drag.current_x), math.min(drag.start_y, drag.current_y)
        local x2, y2 = math.max(drag.start_x, drag.current_x), math.max(drag.start_y, drag.current_y)
        local object, layer_or_reason, map_id = self.document:addEditorRegion(
            drag.event_id, drag.map_id, x1, y1, x2 - x1, y2 - y1)
        if not object then
            self.editor:cancelHistoryTransaction()
            self.editor:addWarning(layer_or_reason, nil, "event_placement")
            return true
        end
        local selection = self.document:getObjectSelection(map_id, layer_or_reason, object)
        selection.view = self
        self.editor:selectMapObject(selection)
        self.editor:clearDiagnostics("event_placement")
        self.editor:markHistoryChanged()
        self.editor:commitHistoryTransaction()
        self.editor:setActiveTool("select")
        return true
    end
    if button == 1 and self.shape_drag then
        local drag = self.shape_drag
        self.shape_drag = nil
        local x1, y1 = math.min(drag.start_x, drag.current_x), math.min(drag.start_y, drag.current_y)
        local x2, y2 = math.max(drag.start_x, drag.current_x), math.max(drag.start_y, drag.current_y)
        local entry = self.document:getMapAt(x1, y1) or self.document:getPrimaryMap()
        local tile_width, tile_height = entry.tile_width or 40, entry.tile_height or 40
        if not Input.ctrl() then
            x1, y1 = MathUtils.round(x1 / tile_width) * tile_width, MathUtils.round(y1 / tile_height) * tile_height
            x2, y2 = MathUtils.round(x2 / tile_width) * tile_width, MathUtils.round(y2 / tile_height) * tile_height
        end
        local object, layer_or_reason, map_id = self.document:addShapeObject(drag.shape, entry.id, x1, y1, x2 - x1, y2 - y1)
        if object then
            local selection = self.document:getObjectSelection(map_id, layer_or_reason, object)
            selection.view = self
            self.editor:selectMapObject(selection)
            self.editor:markHistoryChanged()
            self.editor:commitHistoryTransaction()
        else
            self.editor:cancelHistoryTransaction()
            self.editor:addWarning(layer_or_reason, nil, "shape_placement")
        end
        return true
    end
    if button == 1 and self.object_drag then
        self.object_drag = nil
        self.editor:commitHistoryTransaction()
        self.editor:selectMapObjects(self.editor:getSelectedMapObjects(), self.editor.selected_map_object)
        return true
    end
    if button == 1 and self.polygon_vertex_drag then
        local drag = self.polygon_vertex_drag
        self.polygon_vertex_drag = nil
        self.editor:commitHistoryTransaction()
        self.editor:selectMapObjects({ drag.selection }, drag.selection)
        return true
    end
    if button == 1 and self.rotation_drag then
        self.rotation_drag = nil
        self.editor:commitHistoryTransaction()
        self.editor:selectMapObjects(self.editor:getSelectedMapObjects(), self.editor.selected_map_object)
        return true
    end
    if button == 1 and self.selection_marquee then
        local drag = self.selection_marquee
        self.selection_marquee = nil
        local selections = self.document:findObjectsInRect(
            drag.start_x, drag.start_y, drag.current_x, drag.current_y)
        for _, selection in ipairs(selections) do selection.view = self end
        if drag.additive then
            local combined = self.editor:getSelectedMapObjects()
            for _, selection in ipairs(selections) do table.insert(combined, selection) end
            self.editor:selectMapObjects(combined, selections[1] or self.editor.selected_map_object)
        else
            self.editor:selectMapObjects(selections, selections[1])
        end
        return true
    end
    if button == 1 and self.map_drag then
        self.map_drag = nil
        self.editor:commitHistoryTransaction()
        return true
    end
    return super.onMouseReleased(self, x, y, button, presses)
end

function EditorMapView:onWheelMoved(x, y)
    if self.editor and self.editor.live_document == self.document then
        self.editor:activateMapDocument(self.document, { select_panel = false })
        return self.editor.game_preview:onWheelMoved(x, y)
    end
    return super.onWheelMoved(self, x, y)
end

function EditorMapView:getCursorType(x, y)
    if self.editor and self.editor.live_document == self.document then
        return self.editor.game_preview:getCursorType(x, y)
    end
    if self.object_drag then return self.object_drag.resize_cursor or "grab" end
    if self.map_drag or self.dragging_canvas then return "grab" end
    if self.polygon_vertex_drag then return "resize_all" end
    if self.rotation_drag then return "resize_all" end
    if self.tile_stroke then return "crosshair" end
    if self.editor and self.editor.active_tool == "link" then return "link" end
    if self.editor and self.editor.active_tool == "world_select" then
        local world_x, world_y = self:getMapCoordinates(x, y)
        return self.document:getMapAt(world_x, world_y) and "grab" or "default"
    end
    if self.editor and (self.editor.active_tool == "object" or self.editor.active_tool == "shape"
        or self.editor.active_tool == "tile_brush" or self.editor.active_tool == "tile_fill") then
        return "crosshair"
    end
    if self.editor and self.editor.active_tool == "eraser" then
        local world_x, world_y = self:getMapCoordinates(x, y)
        local entry = self.document:getMapAt(world_x, world_y)
        if entry and self.document:getSelectedTileLayer(entry.id) then return "crosshair" end
    end
    local world_x, world_y = self:getMapCoordinates(x, y)
    if self.editor and self.editor.active_tool == "select" then
        local resize_selection, resize_corner = self:getSelectedResizeCornerAt(world_x, world_y)
        if resize_selection then return self:getResizeCursor(resize_selection, resize_corner) end
    end
    if self.editor and self.editor.active_tool == "select" and self:getPolygonVertexAt(world_x, world_y) then
        return "resize_all"
    end
    if self.editor and self.editor.active_tool == "select" and self:isRotationHandleAt(world_x, world_y) then
        return "resize_all"
    end
    local selection = self.document:findObjectAt(world_x, world_y)
    if selection then
        return "select"
    end
    return super.getCursorType(self, x, y)
end

function EditorMapView:onKeyPressed(key, is_repeat)
    if not is_repeat and key == "escape" and self.editor and self.editor.placement_event_id then
        self:cancelEventRegion()
        self.editor:setActiveTool("select")
        return true
    end
    if not is_repeat and self.polygon_build then
        if key == "escape" then
            return self:cancelPolygon()
        end
        if key == "backspace" then
            table.remove(self.polygon_build.points)
            if #self.polygon_build.points == 0 then return self:cancelPolygon() end
            return true
        end
        if key == "return" or key == "kpenter" then return self:finishPointShape() end
    end
    return super.onKeyPressed(self, key, is_repeat)
end

return EditorMapView
