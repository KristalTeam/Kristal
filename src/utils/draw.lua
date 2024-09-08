---@class Draw
---
---@field private _canvases table<string, love.Canvas>
---@field private _used_canvas table<love.Canvas, boolean>
---@field private _locked_canvas table<love.Canvas, boolean>
---@field private _locked_canvas_stack table<love.Canvas, boolean>[]
---@field private _canvas_stack love.Canvas[]
---@field private _scissor_stack number[][]
---@field private _shader_stack love.Shader[]
---
local Draw = {}
local self = Draw

local old_getScissor = love.graphics.getScissor

Draw._canvases = {}
Draw._used_canvas = setmetatable({}, { __mode = "k" })
Draw._locked_canvas = setmetatable({}, { __mode = "k" })
Draw._locked_canvas_stack = {}
Draw._canvas_stack = {}

Draw._scissor_stack = {}

Draw._shader_stack = {}

---@class Draw.canvasOptions
---@field clear boolean|nil
---@field stencil boolean|nil
---@field keep_transform boolean|nil

---@overload fun(options?: Draw.canvasOptions) : love.Canvas
---@overload fun(canvas: love.Canvas, options?: Draw.canvasOptions) : love.Canvas
---@overload fun(width: number, height: number, options?: Draw.canvasOptions) : love.Canvas
function Draw.pushCanvas(...)
    local args = { ... }
    table.insert(self._canvas_stack, love.graphics.getCanvas())
    local canvas, clear_canvas
    if type(args[1]) == "userdata" then
        canvas = args[1]
    else
        local w, h = SCREEN_WIDTH, SCREEN_HEIGHT
        if type(args[1]) == "number" then
            w, h = args[1], args[2]
        end
        local cid = w .. "," .. h
        self._canvases[cid] = self._canvases[cid] or {}
        for _, cached in ipairs(self._canvases[cid]) do
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
    Draw.setCanvas(canvas, { stencil = options["stencil"] })
    love.graphics.push()
    if not options["keep_transform"] then
        love.graphics.origin()
    end
    if (options["clear"] == nil and clear_canvas) or options["clear"] then
        love.graphics.clear()
    end
    return canvas
end

---@param keep? boolean
---@return love.Canvas
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

---@param canvas love.Canvas
function Draw.unlockCanvas(canvas)
    if canvas then
        self._locked_canvas[canvas] = nil
    end
end

function Draw.pushCanvasLocks()
    local current_locks = setmetatable({}, { __mode = "k" })
    for k, v in pairs(self._locked_canvas) do
        current_locks[k] = v
    end
    table.insert(self._locked_canvas_stack, current_locks)
end

function Draw.popCanvasLocks()
    self._locked_canvas = table.remove(self._locked_canvas_stack, #self._locked_canvas_stack)
end

---@private
---@param canvas? love.Canvas
---@param options? {stencil: boolean}
function Draw.setCanvas(canvas, options)
    options = options or {}
    if canvas then
        if options["stencil"] == false then
            love.graphics.setCanvas(canvas)
        else
            love.graphics.setCanvas { canvas, stencil = true }
        end
    else
        love.graphics.setCanvas()
    end
end

---@private
function Draw._clearUnusedCanvases()
    for k, canvases in pairs(self._canvases) do
        local remove = {}
        for _, canvas in ipairs(canvases) do
            if not self._used_canvas[canvas] then
                table.insert(remove, canvas)
            end
        end
        for _, v in ipairs(remove) do
            Utils.removeFromTable(canvases, v)
        end
    end
    self._used_canvas = setmetatable({}, { __mode = "k" })
end

---@private
function Draw._clearStacks()
    self._canvases = {}
    self._used_canvas = setmetatable({}, { __mode = "k" })
    self._locked_canvas = setmetatable({}, { __mode = "k" })
    self._canvas_stack = {}

    self._scissor_stack = {}
    self._shader_stack = {}
end

---@return number x, number y, number w, number h
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

    table.insert(self._scissor_stack, 1, { x, y, w, h })
end

function Draw.popScissor()
    local x, y, w, h = unpack(self._scissor_stack[1])

    love.graphics.setScissor(x, y, w, h)
    table.remove(self._scissor_stack, 1)
end

---@param x number
---@param y number
---@param w number
---@param h number
function Draw.scissor(x, y, w, h)
    self.scissorPoints(x, y, x + w, y + h)
end

---@param x1? number
---@param y1? number
---@param x2? number
---@param y2? number
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

---@param shader love.Shader|string
---@return love.Shader
function Draw.pushShader(shader, vars)
    if type(shader) == "string" then
        shader = Kristal.Shaders[shader]
    end
    table.insert(self._shader_stack, 1, love.graphics.getShader())
    for k, v in pairs(vars) do
        if type(v) == "function" then
            shader:send(k, v())
        else
            shader:send(k, v)
        end
    end
    love.graphics.setShader(shader)
    return shader
end

function Draw.popShader()
    love.graphics.setShader(table.remove(self._shader_stack, 1))
end

---@param r? number
---@param g? number
---@param b? number
---@param a? number
---@overload fun(color: number[], alpha?: number)
function Draw.setColor(r, g, b, a)
    if type(r) == "table" then
        local alpha = r[4] or 1
        if type(g) == "number" then
            alpha = alpha * g
        end
        love.graphics.setColor(r[1] or 1, r[2] or 1, r[3] or 1, alpha)
    else
        love.graphics.setColor(r or 1, g or 1, b or 1, a or 1)
    end
end

---@overload fun(drawable: love.Drawable, x?: number, y?: number, r?: number, sx?: number, sy?: number, ox?: number, oy?: number, kx?: number, ky?: number)
---@overload fun(texture: love.Texture, quad: love.Quad, x?: number, y?: number, r?: number, sx?: number, sy?: number, ox?: number, oy?: number, kx?: number, ky?: number)
---@overload fun(drawable: love.Drawable, transform: love.Transform)
---@overload fun(texture: love.Texture, quad: love.Quad, transform: love.Transform)
function Draw.draw(...)
    love.graphics.draw(...)
end

---@param texture love.Texture # The texture to cut out.
---@param x       number       # The position to draw the cut-out texture (x-axis).
---@param y       number       # The position to draw the cut-out texture (y-axis).
---@param cx      number       # X position of the cut-out rectangle.
---@param cy      number       # Y position of the cut-out rectangle.
---@param cw      number       # Width of the cut-out rectangle.
---@param ch      number       # Height of the cut-out rectangle.
---@param r?      number       # Orientation (radians).
---@param sx?     number       # Scale factor (x-axis).
---@param sy?     number       # Scale factor (y-axis).
---@param ox?     number       # Origin offset (x-axis).
---@param oy?     number       # Origin offset (y-axis).
---@param kx?     number       # Shearing factor (x-axis).
---@param ky?     number       # Shearing factor (y-axis).
function Draw.drawPart(texture, x, y, cx, cy, cw, ch, r, sx, sy, ox, oy, kx, ky)
    local quad = Assets.getQuad(cx, cy, cw, ch, texture:getWidth(), texture:getHeight())
    Draw.draw(texture, quad, x, y, r, sx, sy, ox, oy, kx, ky)
end

---@overload fun(canvas: love.Canvas, x?: number, y?: number, r?: number, sx?: number, sy?: number, ox?: number, oy?: number, kx?: number, ky?: number)
---@overload fun(canvas: love.Canvas, quad: love.Quad, x?: number, y?: number, r?: number, sx?: number, sy?: number, ox?: number, oy?: number, kx?: number, ky?: number)
---@overload fun(canvas: love.Canvas, transform: love.Transform)
---@overload fun(canvas: love.Canvas, quad: love.Quad, transform: love.Transform)
function Draw.drawCanvas(...)
    local mode, alphamode = love.graphics.getBlendMode()
    love.graphics.setBlendMode(mode, "premultiplied")
    Draw.draw(...)
    love.graphics.setBlendMode(mode, alphamode)
end

---@param canvas love.Canvas # The canvas to cut out.
---@param x      number      # The position to draw the cut-out texture (x-axis).
---@param y      number      # The position to draw the cut-out texture (y-axis).
---@param cx     number      # X position of the cut-out rectangle.
---@param cy     number      # Y position of the cut-out rectangle.
---@param cw     number      # Width of the cut-out rectangle.
---@param ch     number      # Height of the cut-out rectangle.
---@param r?     number      # Orientation (radians).
---@param sx?    number      # Scale factor (x-axis).
---@param sy?    number      # Scale factor (y-axis).
---@param ox?    number      # Origin offset (x-axis).
---@param oy?    number      # Origin offset (y-axis).
---@param kx?    number      # Shearing factor (x-axis).
---@param ky?    number      # Shearing factor (y-axis).
function Draw.drawCanvasPart(canvas, x, y, cx, cy, cw, ch, r, sx, sy, ox, oy, kx, ky)
    local quad = Assets.getQuad(cx, cy, cw, ch, canvas:getWidth(), canvas:getHeight())
    Draw.drawCanvas(canvas, quad, x, y, r, sx, sy, ox, oy, kx, ky)
end

---@param drawable love.Texture|love.Canvas # The texture to draw wrapped.
---@param wrap_x?  boolean                  # Whether the image will repeat along the x-axis.
---@param wrap_y?  boolean                  # Whether the image will repeat along the y-axis.
---@param x?       number                   # The position to draw the texture (x-axis).
---@param y?       number                   # The position to draw the texture (y-axis).
---@param r?       number                   # Orientation (radians).
---@param sx?      number                   # Scale factor (x-axis).
---@param sy?      number                   # Scale factor (y-axis).
---@param ox?      number                   # Origin offset (x-axis).
---@param oy?      number                   # Origin offset (y-axis).
---@param kx?      number                   # Shearing factor (x-axis).
---@param ky?      number                   # Shearing factor (y-axis).
function Draw.drawWrapped(drawable, wrap_x, wrap_y, x, y, r, sx, sy, ox, oy, kx, ky)
    local dw, dh = drawable:getDimensions()

    if x then
        x, y = x or 0, y or 0
        r, sx, sy = r or 0, sx or 1, sy or 1
        ox, oy = ox or 0, oy or 0
        kx, ky = kx or 0, ky or 0

        love.graphics.push()
        if x ~= 0 or y ~= 0 then love.graphics.translate(x, y) end
        if r ~= 0 then love.graphics.rotate(r) end
        if sx ~= 1 or sy ~= 1 then love.graphics.scale(sx, sy) end
        if kx ~= 0 or ky ~= 0 then love.graphics.shear(kx, ky) end
        if ox ~= 0 or oy ~= 0 then love.graphics.translate(-ox, -oy) end
    end

    local screen_l, screen_u = love.graphics.inverseTransformPoint(0, 0)
    local screen_r, screen_d = love.graphics.inverseTransformPoint(SCREEN_WIDTH, SCREEN_HEIGHT)

    local x1, y1 = math.min(screen_l, screen_r), math.min(screen_u, screen_d)
    local x2, y2 = math.max(screen_l, screen_r), math.max(screen_u, screen_d)

    local x_offset = math.floor(x1 / dw) * dw
    local y_offset = math.floor(y1 / dh) * dh

    local wrap_width = math.ceil((x2 - x_offset) / dw)
    local wrap_height = math.ceil((y2 - y_offset) / dh)

    if wrap_x and wrap_y then
        for i = 1, wrap_width do
            for j = 1, wrap_height do
                Draw.draw(drawable, x_offset + (i - 1) * dw, y_offset + (j - 1) * dh)
            end
        end
    elseif wrap_x then
        for i = 1, wrap_width do
            Draw.draw(drawable, x_offset + (i - 1) * dw, 0)
        end
    elseif wrap_y then
        for j = 1, wrap_height do
            Draw.draw(drawable, 0, y_offset + (j - 1) * dh)
        end
    end

    if x then
        love.graphics.pop()
    end
end

---
--- Draws text with a black drop shadow behind it.
---
---@param text string|table     # A text string, or table of color-formatted text.
---@param x? number             # The position on the x-axis.
---@param y? number             # The position on the y-axis.
---@param offset? number        # The offset of the drop shadow. (Defaults to 2)
---@param align? love.AlignMode # The alignment.
---@param limit? number         # Wrap the line after this many horizontal pixels.
---
function Draw.printShadow(text, x, y, offset, align, limit)
    x, y = x or 0, y or 0
    offset = offset or 2

    local r, g, b, a = love.graphics.getColor()

    local width = love.graphics.getFont():getWidth(Utils.getCombinedText(text))

    -- Draw the shadow, offset by a given amount of pixels to the bottom right
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.printf(text, x + offset, y + offset, limit or width, align or "left")

    -- Draw the main text
    love.graphics.setColor(r, g, b, a)
    love.graphics.printf(text, x, y, limit or width, align or "left")
end

--- Modes: `none`
--- - `none`: Creates a canvas based on object size and draws the object at 0,0 (not transformed)
---
---@overload fun(object: Object, mode: "none", no_children?: boolean, pad_x?: number, pad_y?: number)
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
        error("No draw mode: " .. tostring(mode))
    end
end

function Draw.rectangle(type, x, y, width, height)
    if type == "line" or type == "fill" then
        love.graphics.rectangle(type, x, y, width, height)
    elseif type == "stripes" then
        -- TODO: optimize lol
        Draw.pushScissor()
        Draw.scissor(x, y, width, height)

        for line = 0, math.max(SCREEN_WIDTH, SCREEN_HEIGHT) * 2, 8 do
            love.graphics.line(0, line, line, 0)
        end

        Draw.popScissor()
    end
end

-- Same as love.graphics.print(), but has the align parameter after the y param
-- Available align options: "left", "center" and "right"
-- If using align as a table, you can spcify the key "align" for the alignment and "line_offset" for the new line spacing.
function Draw.printAlign(text, x, y, align, r, sx, sy, ox, oy, kx, ky)
    local new_line_space = 0
    local new_line_space_height = love.graphics.getFont():getHeight()
    if type(align) == "table" then
        if align["line_offset"] then
            new_line_space_height = align["line_offset"]
        end
        if align["align"] then
            align = align["align"]
        end
    end
    for line in string.gmatch(text, "([^\n]+)") do
        love.graphics.print(line, x - ((align == "center" or align == "right") and love.graphics.getFont():getWidth(line) or 0) / (align == "center" and 2 or 1) * ((align == "center" or align == "right") and sx or 1), y + new_line_space, r, sx, sy, ox, oy, kx, ky)
        new_line_space = new_line_space + new_line_space_height * (sy or 1)
    end
end

return Draw
