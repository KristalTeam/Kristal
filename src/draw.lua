local Draw = {}
local self = Draw

local old_getScissor = love.graphics.getScissor

Draw._canvases = {}
Draw._keep_canvas = {}
Draw._used_canvas = {}

Draw._scissor_stack = {}

function Draw.getCanvas(id, width, height, keep)
    self._used_canvas[id] = true
    self._keep_canvas[id] = keep
    local canvas = self._canvases[id]
    if not canvas or canvas[2] ~= width or canvas[3] ~= height then
        canvas = {love.graphics.newCanvas(width, height), width, height}
        self._canvases[id] = canvas
    end
    return canvas[1]
end

function Draw._clearUnusedCanvases()
    local remove = {}
    for k,_ in pairs(self._canvases) do
        if not self._keep_canvas[k] and not self._used_canvas[k] then
            table.insert(remove, k)
        end
    end
    for _,v in ipairs(remove) do
        self._canvases[v][1] = nil
        self._canvases[v] = nil
    end
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
    self.scissorPoints(x, y, x+w, x+h)
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
    local quad = Assets.getQuad(cx, cy, cw, ch, texture:getWidth(), texture:getHeight())
    love.graphics.draw(texture, quad, x, y, ...)
end

return Draw