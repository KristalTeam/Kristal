---@class EditorGameView : EditorControl
---@field canvas love.Canvas?
---@field canvas_positioned boolean
---@field canvas_x number
---@field canvas_y number
---@field clip boolean
---@field document EditorMapDocument?
---@field dragging_canvas boolean
---@field editor Editor
---@field focus_on_wheel boolean
---@field focusable boolean
---@field is_game_preview boolean
---@field maximum_zoom number
---@field minimum_zoom number
---@field tile_editing_mode boolean
---@field view_zoom number
---@overload fun(editor?: table, document?: EditorMapDocument): EditorGameView
local EditorGameView, super = Class(EditorControl)

function EditorGameView:init(editor, document)
    super.init(self, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
    self.editor = editor
    self.document = document
    self.is_game_preview = true
    self.canvas = nil
    self.canvas_x = 0
    self.canvas_y = 0
    self.canvas_positioned = false
    self.dragging_canvas = false
    self.tile_editing_mode = false
    self.view_zoom = 1
    self.minimum_zoom = 0.25
    self.maximum_zoom = 4
    self.focusable = true
    self.focus_on_wheel = true
    self.clip = true
end

function EditorGameView:setDocument(document)
    self.document = document
end

function EditorGameView:getPrimaryEntry()
    return self.document and self.document:getPrimaryMap() or nil
end

function EditorGameView:getRuntimeEntry()
    local map = Game.world and Game.world.map
    return self.document and map and self.document.map_lookup[map.id]
        or self:getPrimaryEntry()
end

function EditorGameView:drawCompanionMaps()
    local document = self.document
    local runtime = self:getRuntimeEntry()
    if not document or not runtime then return end
    for _, entry in ipairs(document.maps) do
        if entry ~= runtime then
            love.graphics.push()
            love.graphics.applyTransform(Game.world.camera:getTransform())
            love.graphics.translate(entry.x - runtime.x, entry.y - runtime.y)
            document:drawPreview(entry)
            love.graphics.pop()
        end
    end
end

function EditorGameView:setCanvas(canvas)
    self.canvas = canvas
end

function EditorGameView:setTileEditingMode(enabled)
    self.dragging_canvas = false
end

function EditorGameView:setCanvasPosition(x, y)
    self.canvas_x = MathUtils.round(x)
    self.canvas_y = MathUtils.round(y)
    self.canvas_positioned = true
end

function EditorGameView:getCanvasPosition()
    return self.canvas_x, self.canvas_y
end

function EditorGameView:getCanvasDisplayCenter()
    return self.canvas_x + SCREEN_WIDTH * self.view_zoom / 2,
        self.canvas_y + SCREEN_HEIGHT * self.view_zoom / 2
end

function EditorGameView:centerCanvas()
    self:setCanvasPosition((self.width - SCREEN_WIDTH * self.view_zoom) / 2,
        (self.height - SCREEN_HEIGHT * self.view_zoom) / 2)
end

function EditorGameView:setViewZoom(zoom, anchor_x, anchor_y)
    local old_zoom = self.view_zoom
    zoom = MathUtils.clamp(zoom, self.minimum_zoom, self.maximum_zoom)
    if zoom == old_zoom then return false end

    anchor_x = anchor_x or self.width / 2
    anchor_y = anchor_y or self.height / 2
    local canvas_anchor_x = (anchor_x - self.canvas_x) / old_zoom
    local canvas_anchor_y = (anchor_y - self.canvas_y) / old_zoom
    self.view_zoom = zoom
    self:setCanvasPosition(anchor_x - canvas_anchor_x * zoom,
        anchor_y - canvas_anchor_y * zoom)
    return true
end

function EditorGameView:resetView()
    self.view_zoom = 1
    self:centerCanvas()
end

function EditorGameView:update(dt)
    if not self.canvas_positioned then self:centerCanvas() end
    super.update(self, dt)
end

function EditorGameView:onMousePressed(x, y, button)
    if button ~= 3 then return false end
    self.dragging_canvas = true
    return true
end

function EditorGameView:getCursorType(x, y)
    if self.dragging_canvas then return "grab" end
    if self.editor and self.editor:isGameObjectSelectionActive() then
        if Kristal.DebugSystem.context or self.editor:getGameObjectAtCursor() then return "select" end
    end
    return "default"
end

function EditorGameView:drawMapObjects(world)
    local map = world.map
    local included = {}
    for _, layer in ipairs(map.tile_layers) do included[layer] = true end
    for _, layer in pairs(map.image_layers) do included[layer] = true end
    for _, event in ipairs(map.events) do included[event] = true end

    love.graphics.push()
    world:preDraw()
    Draw.setColor(map.bg_color or { 0, 0, 0, 0 })
    love.graphics.rectangle("fill", 0, 0, world.width, world.height)
    Draw.setColor(1, 1, 1, 1)
    for _, child in ipairs(world.children) do
        if included[child] and child.visible and child.parent == world then child:fullDraw() end
    end
    map:draw()
    world:postDraw()
    love.graphics.pop()
end

function EditorGameView:drawEventBounds(offset_x, offset_y, view_zoom)
    local map = Game.world and Game.world.map
    if not map then return end
    offset_x, offset_y = offset_x or 0, offset_y or 0
    view_zoom = view_zoom or 1
    for _, event in ipairs(map.events) do
        if event.stage and event.visible then
            local rect = event:getDebugRectangle()
            love.graphics.push()
            love.graphics.origin()
            love.graphics.translate(offset_x, offset_y)
            love.graphics.scale(view_zoom, view_zoom)
            love.graphics.applyTransform(event:getFullTransform())
            love.graphics.setLineWidth(1)
            Draw.setColor(0, 1, 1, 0.9)
            love.graphics.rectangle("line", rect[1], rect[2], math.max(1, rect[3]), math.max(1, rect[4]))
            love.graphics.pop()
        end
    end
end

function EditorGameView:drawCollision(collision, offset_x, offset_y, view_zoom, r, g, b, a)
    love.graphics.push()
    love.graphics.origin()
    love.graphics.translate(offset_x or 0, offset_y or 0)
    love.graphics.scale(view_zoom or 1, view_zoom or 1)
    if collision.parent then love.graphics.applyTransform(collision.parent:getFullTransform()) end
    collision:draw(r, g, b, a)
    love.graphics.pop()
end

function EditorGameView:drawCollisionBounds(offset_x, offset_y, view_zoom)
    local map = Game.world and Game.world.map
    if not map then return end
    for _, collision in ipairs(map.collision) do
        self:drawCollision(collision, offset_x, offset_y, view_zoom, 0, 0, 1, 0.9)
    end
    for _, collision in ipairs(map.enemy_collision) do
        self:drawCollision(collision, offset_x, offset_y, view_zoom, 0, 1, 1, 0.9)
    end
    for _, collision in ipairs(map.block_collision) do
        self:drawCollision(collision, offset_x, offset_y, view_zoom, 1, 0.35, 0, 0.9)
    end
end

function EditorGameView:drawCameraRect()
    love.graphics.setLineWidth(2)
    Draw.setColor(0, 1, 1, 0.95)
    love.graphics.rectangle("line", self.canvas_x + 0.5, self.canvas_y + 0.5,
        SCREEN_WIDTH * self.view_zoom - 1, SCREEN_HEIGHT * self.view_zoom - 1)
end

function EditorGameView:drawMapOuterBounds()
    local world = Game.world
    local map = world and world.map
    if not map then return end

    love.graphics.push()
    love.graphics.translate(self.canvas_x, self.canvas_y)
    love.graphics.scale(self.view_zoom, self.view_zoom)
    world:preDraw()
    local camera_zoom = math.max(math.abs(world.camera.zoom_x), math.abs(world.camera.zoom_y), 0.001)
    love.graphics.setLineWidth(2 / (self.view_zoom * camera_zoom))
    Draw.setColor(1, 1, 1, 0.4)
    local runtime = self:getRuntimeEntry()
    local runtime_x, runtime_y = runtime and runtime.x or 0, runtime and runtime.y or 0
    love.graphics.rectangle("line", 0, 0, map.width * map.tile_width, map.height * map.tile_height)
    if self.editor and self.editor.show_tile_grid then
        self:drawTileGrid(0, 0, map.width * map.tile_width, map.height * map.tile_height,
            map.tile_width, map.tile_height, camera_zoom)
    end
    if self.document then
        for _, entry in ipairs(self.document.maps) do
            if entry ~= runtime and entry.width and entry.height then
                Draw.setColor(1, 1, 1, 0.4)
                love.graphics.rectangle("line", entry.x - runtime_x, entry.y - runtime_y,
                    entry.width, entry.height)
                if self.editor.show_tile_grid then
                    self:drawTileGrid(entry.x - runtime_x, entry.y - runtime_y, entry.width, entry.height,
                        entry.tile_width, entry.tile_height, camera_zoom)
                end
            end
        end
    end
    world:postDraw()
    love.graphics.pop()
end

function EditorGameView:drawTileGrid(x, y, width, height, tile_width, tile_height, camera_zoom)
    tile_width, tile_height = tile_width or 40, tile_height or 40
    camera_zoom = camera_zoom or 1
    local previous_line_width = love.graphics.getLineWidth()
    love.graphics.setLineWidth(1 / math.max(0.001, self.view_zoom * camera_zoom))
    Draw.setColor(0.75, 0.85, 1, 0.22)
    for line_x = 0, width, tile_width do
        love.graphics.line(x + line_x, y, x + line_x, y + height)
    end
    for line_y = 0, height, tile_height do
        love.graphics.line(x, y + line_y, x + width, y + line_y)
    end
    love.graphics.setLineWidth(previous_line_width)
end

function EditorGameView:drawScaleReadout()
    local font = EditorFont.get(16)
    local text = string.format("%d%%", MathUtils.round(self.view_zoom * 100))
    local x, y = 6, self.height - font:getHeight() - 8
    love.graphics.setFont(font)
    Draw.setColor(0, 0, 0, 0.75)
    love.graphics.rectangle("fill", x, y, font:getWidth(text) + 12, font:getHeight() + 8)
    Draw.setColor(0, 0, 0, 1)
    love.graphics.print(text, x + 7, y + 5)
    Draw.setColor(1, 1, 1, 1)
    love.graphics.print(text, x + 6, y + 4)
end

function EditorGameView:drawPlaybackState()
    if not self.editor or not self.editor.live_document then return end
    local owner = self.editor:getGamePreviewOwnerPanel()
    if not owner or owner.content ~= self then return end
    local texture = Assets.getTexture(self.editor.game_preview_paused
        and "kristal/menu_pause" or "kristal/menu_arrow_right")
    if not texture then return end
    local scale = 2
    local width, height = texture:getWidth() * scale, texture:getHeight() * scale
    local x, y = self.width - width - 8, 8
    Draw.setColor(0, 0, 0, 0.75)
    love.graphics.rectangle("fill", x - 4, y - 4, width + 8, height + 8)
    Draw.setColor(1, 1, 1, 1)
    Draw.draw(texture, x, y, 0, scale, scale)
end

function EditorGameView:drawMapContext()
    if not Game.world or not Game.world.map or self.width < 1 or self.height < 1 then return end
    local width, height = math.max(1, math.floor(self.width)), math.max(1, math.floor(self.height))
    local old_scissor = { love.graphics.getScissor() }
    love.graphics.setScissor()
    local map_canvas = Draw.pushCanvas(width, height)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.translate(self.canvas_x, self.canvas_y)
    love.graphics.scale(self.view_zoom, self.view_zoom)
    self:drawCompanionMaps()
    self:drawMapObjects(Game.world)
    self:drawEventBounds(self.canvas_x, self.canvas_y, self.view_zoom)
    self:drawCollisionBounds(self.canvas_x, self.canvas_y, self.view_zoom)
    Draw.popCanvas()
    love.graphics.setScissor(unpack(old_scissor))
    Draw.setColor(1, 1, 1, 0.5)
    Draw.draw(map_canvas, 0, 0)
end

function EditorGameView:drawRuntimeBounds()
    local old_scissor = { love.graphics.getScissor() }
    love.graphics.setScissor()
    local bounds_canvas = Draw.pushCanvas(SCREEN_WIDTH, SCREEN_HEIGHT)
    love.graphics.clear(0, 0, 0, 0)
    self:drawEventBounds()
    self:drawCollisionBounds()
    Draw.popCanvas()
    love.graphics.setScissor(unpack(old_scissor))
    Draw.setColor(1, 1, 1, 1)
    love.graphics.push()
    love.graphics.translate(self.canvas_x, self.canvas_y)
    love.graphics.scale(self.view_zoom, self.view_zoom)
    Draw.draw(bounds_canvas, 0, 0)
    love.graphics.pop()
end

function EditorGameView:drawObjectSelection()
    if not self.editor or not self.editor:isGameObjectSelectionActive() then return end
    local debug_system = Kristal.DebugSystem
    local object = debug_system.object
    if not object and not debug_system.context and not debug_system.grabbing then
        object = self.editor:getGameObjectAtCursor()
    end
    if not object or object:isRemoved() or not object:isFullyVisible() then return end
    local rect = object:getDebugRectangle() or { 0, 0, object.width, object.height }
    love.graphics.push()
    love.graphics.translate(self.canvas_x, self.canvas_y)
    love.graphics.scale(self.view_zoom, self.view_zoom)
    love.graphics.applyTransform(object:getFullTransform())
    love.graphics.setLineWidth(1 / math.max(self.view_zoom, 0.001))
    Draw.setColor(0, 1, 1, 0.95)
    love.graphics.rectangle("line", rect[1], rect[2], math.max(1, rect[3]), math.max(1, rect[4]))
    love.graphics.pop()
end

function EditorGameView:getMapCoordinates(x, y)
    if not Game.world or not Game.world.camera then return 0, 0 end
    local map_x, map_y = Game.world.camera:getTransform():inverseTransformPoint(
        (x - self.canvas_x) / self.view_zoom,
        (y - self.canvas_y) / self.view_zoom
    )
    local runtime = self:getRuntimeEntry()
    return map_x + (runtime and runtime.x or 0), map_y + (runtime and runtime.y or 0)
end

function EditorGameView:drawCursorAndCoordinates()
    if not love.window.hasMouseFocus() then return end
    local mouse_x, mouse_y = self.editor:getMousePosition()
    local global_x, global_y = self:getGlobalPosition()
    local x, y = mouse_x - global_x, mouse_y - global_y
    if x < 0 or y < 0 or x >= self.width or y >= self.height then return end

    local map_x, map_y = self:getMapCoordinates(x, y)
    local font = EditorFont.get(16)
    local text = string.format("Map: (%i, %i)", MathUtils.round(map_x), MathUtils.round(map_y))
    love.graphics.setFont(font)
    Draw.setColor(0, 0, 0, 0.75)
    love.graphics.rectangle("fill", 6, 6, font:getWidth(text) + 12, font:getHeight() + 8)
    Draw.setColor(0, 0, 0, 1)
    love.graphics.print(text, 13, 11)
    Draw.setColor(1, 1, 1, 1)
    love.graphics.print(text, 12, 10)
end

function EditorGameView:onMouseMoved(_, _, dx, dy)
    if not self.dragging_canvas then return false end
    self:setCanvasPosition(self.canvas_x + dx, self.canvas_y + dy)
    return true
end

function EditorGameView:onMouseReleased(_, _, button)
    if button ~= 3 or not self.dragging_canvas then return false end
    self.dragging_canvas = false
    return true
end

function EditorGameView:onWheelMoved(x, y)
    if Input.shift() then
        local speed = 40
        self:setCanvasPosition(self.canvas_x - (x * speed), self.canvas_y + (y * speed))
        return
    end
    if y == 0 then return false end
    local mouse_x, mouse_y = self.editor:getMousePosition()
    local global_x, global_y = self:getGlobalPosition()
    local anchor_x, anchor_y = mouse_x - global_x, mouse_y - global_y
    return self:setViewZoom(self.view_zoom * (1.15 ^ y), anchor_x, anchor_y)
end

function EditorGameView:onKeyPressed(key, is_repeat)
    if (key == "0" or key == "kp0") and not is_repeat then
        self:resetView()
        return true
    end
    return false
end

function EditorGameView:onFocus()
    if self.editor and not self.editor.suppress_panel_activation then
        self.editor:showGamePreview({ select_panel = false })
    end
end

function EditorGameView:drawPreview()
    self:drawMapContext()
    if self.canvas then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.push()
        love.graphics.translate(self.canvas_x, self.canvas_y)
        love.graphics.scale(self.view_zoom, self.view_zoom)
        Draw.draw(self.canvas, 0, 0)
        love.graphics.pop()
        self:drawRuntimeBounds()
        self:drawObjectSelection()
    end
    self:drawMapOuterBounds()
    if self.canvas then
        self:drawCameraRect()
    end
    self:drawCursorAndCoordinates()
end

function EditorGameView:drawSelf()
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    if not self.editor or not self.editor.game_faulted then
        if self.editor then
            self.editor:runGameDraw("map render", function() self:drawPreview() end)
        else
            self:drawPreview()
        end
    end
    if self.editor and self.editor.game_faulted then
        local font = EditorFont.get(16)
        local text = "Game preview paused after an error"
        love.graphics.setFont(font)
        Draw.setColor(0.75, 0.22, 0.22, 1)
        love.graphics.print(text, math.floor((self.width - font:getWidth(text)) / 2),
            math.floor((self.height - font:getHeight()) / 2))
    end
    self:drawScaleReadout()
    self:drawPlaybackState()
    Draw.setColor(1, 1, 1, 1)
end

return EditorGameView
