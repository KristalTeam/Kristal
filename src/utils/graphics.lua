local graphics = love.graphics

local old_reset = love.graphics.reset
local old_replaceTransform = love.graphics.replaceTransform

local transformStack = {}

local transform = love.math.newTransform()

function graphics.reset()
  transformStack = {}
  love.graphics.origin()

  Draw._scissor_stack = {}
  love.graphics.setScissor()
end

function graphics.printfOutline(text, x, y, outline, limit, ...)
  local old_color = {love.graphics.getColor()}

  love.graphics.setColor(0, 0, 0)

  local drawn = {}
  for i = -(outline or 1),(outline or 1) do
    for j = -(outline or 1),(outline or 1) do
      if i ~= 0 or j ~= 0 then
        love.graphics.printf(text, x+i, y+j, limit or math.huge, ...)
      end
    end
  end

  love.graphics.setColor(unpack(old_color))

  love.graphics.printf(text, x, y, limit or math.huge, ...)
end

function graphics.drawCanvas(canvas, ...)
  local mode,alphamode = love.graphics.getBlendMode()
  love.graphics.setBlendMode(mode, "premultiplied")
  love.graphics.draw(canvas, ...)
  love.graphics.setBlendMode(mode, alphamode)
end

--[[ Transforms ]]--

function graphics.getTransform()
  return transform:clone()
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