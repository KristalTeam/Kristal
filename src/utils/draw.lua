local Draw = {}
local self = Draw

local old_getScissor = love.graphics.getScissor

Draw._canvases = {}
Draw._used_canvas = setmetatable({},{__mode="k"})
Draw._locked_canvas = setmetatable({},{__mode="k"})
Draw._locked_canvas_stack = {}
Draw._canvas_stack = {}

Draw._scissor_stack = {}

--[[Draw.Transformer = {
    apply = function(self, tf) love.graphics.applyTransform(tf) end,
    clone = function(self) error("Transformer:clone() is not implemented") end,
    getMatrix = function(self) error("Transformer:getMatrix() is not implemented") end,
    setMatrix = function(self, m) error("Transformer:setMatrix() is not implemented") end,
    inverse = function(self) error("Transformer:inverse() is not implemented") end,
    inverseTransformPoint = function(self, x, y) return love.graphics.inverseTransformPoint(x, y) end,
    transformPoint = function(self, x, y) return love.graphics.transformPoint(x, y) end,
    reset = function(self) love.graphics.origin() end,
    rotate = function(self, angle) love.graphics.rotate(angle) end,
    scale = function(self, x, y) love.graphics.scale(x, y or x) end,
    shear = function(self, kx, ky) love.graphics.shear(kx, ky) end,
    translate = function(self, x, y) love.graphics.translate(x, y) end,
    setTransformation = function(self, x, y, angle, sx, sy, ox, oy, kx, ky)
        love.graphics.translate(x, y)
        love.graphics.rotate(angle or 0)
        love.graphics.scale(sx or 1, sy or sx or 1)
        love.graphics.translate(-ox or 0, -oy or 0)
        love.graphics.shear(kx or 0, ky or 0)
    end,
}]]

function Draw.pushCanvas(...)
    local args = {...}
    table.insert(self._canvas_stack, love.graphics.getCanvas())
    local canvas, clear_canvas
    if type(args[1]) == "userdata" then
        canvas = args[1]
    else
        local w, h = SCREEN_WIDTH, SCREEN_HEIGHT
        if type(args[1]) == "number" then
            w, h = args[1], args[2]
        end
        local cid = w..","..h
        self._canvases[cid] = self._canvases[cid] or {}
        for _,cached in ipairs(self._canvases[cid]) do
            if not self._locked_canvas[cached] then
                canvas = cached
                break
            end
        end
        if not canvas then
            canvas = love.graphics.newCanvas(w, h)
            table.insert(self._canvases[cid], canvas)
        end
        clear_canvas = true
    end
    local options = type(args[#args]) == "table" and args[#args] or {}
    if canvas then
        self._locked_canvas[canvas] = true
        self._used_canvas[canvas] = true
    end
    Draw.setCanvas(canvas, {stencil = options["stencil"]})
    love.graphics.push()
    if not options["keep_transform"] then
        love.graphics.origin()
    end
    if (options["clear"] == nil and clear_canvas) or options["clear"] then
        love.graphics.clear()
    end
    return canvas
end

function Draw.popCanvas(keep)
    local canvas = love.graphics.getCanvas()
    if canvas and not keep then
        self._locked_canvas[canvas] = nil
    end
    local old_canvas = table.remove(self._canvas_stack, #self._canvas_stack)
    love.graphics.pop()
    Draw.setCanvas(old_canvas)
    return old_canvas
end

function Draw.unlockCanvas(canvas)
    if canvas then
        self._locked_canvas[canvas] = nil
    end
end

function Draw.pushCanvasLocks()
    local current_locks = setmetatable({},{__mode="k"})
    for k,v in pairs(self._locked_canvas) do
        current_locks[k] = v
    end
    table.insert(self._locked_canvas_stack, current_locks)
end

function Draw.popCanvasLocks()
    self._locked_canvas = table.remove(self._locked_canvas_stack, #self._locked_canvas_stack)
end

function Draw.setCanvas(canvas, options)
    options = options or {}
    if canvas then
        if options["stencil"] == false then
            love.graphics.setCanvas(canvas)
        else
            love.graphics.setCanvas{canvas, stencil=true}
        end
    else
        love.graphics.setCanvas()
    end
end

function Draw._clearUnusedCanvases()
    for k,canvases in pairs(self._canvases) do
        local remove = {}
        for _,canvas in ipairs(canvases) do
            if not self._used_canvas[canvas] then
                table.insert(remove, canvas)
            end
        end
        for _,v in ipairs(remove) do
            Utils.removeFromTable(canvases, v)
        end
    end
    self._locked_canvas = {}
    self._used_canvas = {}
end

function Draw._clearStacks()
    self._canvases = {}
    self._used_canvas = setmetatable({},{__mode="k"})
    self._locked_canvas = setmetatable({},{__mode="k"})
    self._canvas_stack = {}

    self._scissor_stack = {}
end

function Draw.getScissor()
    if love.graphics.getScissor() then
        local x, y, w, h = love.graphics.getScissor()
        local x2, y2 = x + w, y + h

        x, y = love.graphics.inverseTransformPoint(x, y)
        x2, y2 = love.graphics.inverseTransformPoint(x2, y2)

        w, h = x2 - x, y2 - y

        return x, y, w, h
    else
        local x, y, w, h = 0, 0, love.graphics.getWidth(), love.graphics.getHeight()
        local x2, y2 = x + w, y + h

        x, y = love.graphics.inverseTransformPoint(x, y)
        x2, y2 = love.graphics.inverseTransformPoint(x2, y2)

        w, h = x2 - x, y2 - y

        return x, y, w, h
    end
end

function Draw.pushScissor()
    local x, y, w, h = old_getScissor()

    table.insert(self._scissor_stack, 1, {x, y, w, h})
end

function Draw.popScissor()
    local x, y, w, h = unpack(self._scissor_stack[1])

    love.graphics.setScissor(x, y, w, h)
    table.remove(self._scissor_stack, 1)
end

function Draw.scissor(x, y, w, h)
    self.scissorPoints(x, y, x+w, y+h)
end

function Draw.scissorPoints(x1, y1, x2, y2)
    local scrx, scry = love.graphics.inverseTransformPoint(0, 0)
    local scrx2, scry2 = love.graphics.inverseTransformPoint(SCREEN_WIDTH, SCREEN_HEIGHT)

    local tx1, ty1 = love.graphics.transformPoint(x1 or scrx, y1 or scry)
    local tx2, ty2 = love.graphics.transformPoint(x2 or scrx2, y2 or scry2)

    local sx, sy = Utils.clamp(tx1, 0, SCREEN_WIDTH), Utils.clamp(ty1, 0, SCREEN_HEIGHT)
    local sx2, sy2 = Utils.clamp(tx2, 0, SCREEN_WIDTH), Utils.clamp(ty2, 0, SCREEN_HEIGHT)

    local min_sx, min_sy = math.min(sx, sx2), math.min(sy, sy2)
    local max_sx, max_sy = math.max(sx, sx2), math.max(sy, sy2)

    if love.graphics.getScissor() == nil then
        love.graphics.setScissor(min_sx, min_sy, max_sx - min_sx, max_sy - min_sy)
    else
        love.graphics.intersectScissor(min_sx, min_sy, max_sx - min_sx, max_sy - min_sy)
    end
end

function Draw.drawCutout(texture, x, y, cx, cy, cw, ch, ...)
    local quad = love.graphics.newQuad(cx, cy, cw, ch, texture:getWidth(), texture:getHeight())
    love.graphics.draw(texture, quad, x, y, ...)
end

--- Modes: `none`
--- - `none`: Creates a canvas based on object size and draws the object at 0,0 (not transformed)
---   - extra arguments: `no_children`, `pad_x`, `pad_y`
function Draw.captureObject(object, mode, ...)
    -- TODO: Add more modes (centered canvas, absolute screen canvas, full width/height including children ?)

    mode = mode or "none"

    if mode == "none" then
        local no_children, pad_x, pad_y = ...

        no_children = no_children or false
        pad_x = pad_x or 0
        pad_y = pad_y or 0

        local canvas = Draw.pushCanvas(object.width + (pad_x * 2), object.height + (pad_y * 2))
        love.graphics.translate(pad_x, pad_y)
        object:drawSelf(no_children, true)
        Draw.popCanvas(true)
        return canvas
    else
        error("No draw mode: "..tostring(mode))
    end
end

return Draw