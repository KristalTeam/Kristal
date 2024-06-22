---@class love.graphics
local graphics = love.graphics

local old_replaceTransform = love.graphics.replaceTransform

local transformStack = {}

local transform = love.math.newTransform()

function graphics.reset()
    transformStack = {}
    love.graphics.origin()

    Draw._scissor_stack = {}
    love.graphics.setScissor()
end

---
---Draws formatted text, with word wrap, alignment and outline.
---
---See additional notes in love.graphics.print.
---
---The word wrap limit is applied before any scaling, rotation, and other coordinate transformations. Therefore the amount of text per line stays constant given the same wrap limit, even if the scale arguments change.
---
---@param text string # A text string.
---@param x number # The position on the x-axis.
---@param y number # The position on the y-axis.
---@param outline number # The size of the outline.
---@param limit? number # Wrap the line after this many horizontal pixels.
---@param align? love.AlignMode # The alignment.
---@param r? number # Orientation (radians).
---@param sx? number # Scale factor (x-axis).
---@param sy? number # Scale factor (y-axis).
---@param ox? number # Origin offset (x-axis).
---@param oy? number # Origin offset (y-axis).
---@param kx? number # Shearing factor (x-axis).
---@param ky? number # Shearing factor (y-axis).
function graphics.printfOutline(text, x, y, outline, limit, align, r, sx, sy, ox, oy, kx, ky)
    local old_color = { love.graphics.getColor() }

    Draw.setColor(0, 0, 0)

    local drawn = {}
    for i = -(outline or 1), (outline or 1) do
        for j = -(outline or 1), (outline or 1) do
            if i ~= 0 or j ~= 0 then
                love.graphics.printf(text, x + i, y + j, limit or math.huge, align, r, sx, sy, ox, oy, kx, ky)
            end
        end
    end

    Draw.setColor(unpack(old_color))

    love.graphics.printf(text, x, y, limit or math.huge, align, r, sx, sy, ox, oy, kx, ky)
end

--[[ Transforms ]]
--

-- Gets a copy of the Transform object for the current coordinate transformation.
---@return love.Transform transform A copy of the Transform object for the current coordinate transformation.
function graphics.getTransform()
    return transform:clone()
end

-- Gets a direct reference of the Transform object for the current coordinate transformation.
---@return love.Transform transform_ref A direct reference of the Transform object for the current coordinate transformation.
function graphics.getTransformRef()
    return transform
end

function graphics.applyTransform(t)
    transform:apply(t)
    old_replaceTransform(transform)
end

function graphics.inverseTransformPoint(screenX, screenY)
    return transform:inverseTransformPoint(screenX, screenY)
end

function graphics.origin()
    transform:reset()
    old_replaceTransform(transform)
end

function graphics.pop()
    transform = table.remove(transformStack, 1)
    old_replaceTransform(transform)
end

function graphics.push()
    table.insert(transformStack, 1, transform)
    transform = transform:clone()
end

function graphics.replaceTransform(t)
    transform = t
    old_replaceTransform(transform)
end

function graphics.rotate(angle)
    transform:rotate(angle)
    old_replaceTransform(transform)
end

function graphics.scale(sx, sy)
    transform:scale(sx, sy or sx)
    old_replaceTransform(transform)
end

function graphics.shear(kx, ky)
    transform:shear(kx, ky)
    old_replaceTransform(transform)
end

function graphics.transformPoint(globalX, globalY)
    return transform:transformPoint(globalX, globalY)
end

function graphics.translate(dx, dy)
    transform:translate(dx, dy)
    old_replaceTransform(transform)
end