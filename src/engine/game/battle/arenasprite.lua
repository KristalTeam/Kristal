--- A special object used to draw the arena to the screen.
---
---@class ArenaSprite : Object
---
---@field arena         Arena   The arena this Object is drawing.
---
---@field background    boolean Whether to draw the arena's background.
---
---@overload fun(arena:Arena, x?: number, y?:number) : ArenaSprite
local ArenaSprite, super = Class(Object)

---@param arena Arena
---@param x?    number
---@param y?    number
function ArenaSprite:init(arena, x, y)
    super.init(self, x, y)

    self.arena = arena

    self.width = arena.width
    self.height = arena.height

    self:setScaleOrigin(0.5, 0.5)
    self:setRotationOrigin(0.5, 0.5)

    self.background = true

    self.debug_select = false
end

function ArenaSprite:update()
    self.width = self.arena.width
    self.height = self.arena.height

    super.update(self)
end

function ArenaSprite:draw()
    if self.background then
        Draw.setColor(self.arena:getBackgroundColor())
        self:drawBackground()
    end

    super.draw(self)

    local r,g,b,a = self:getDrawColor()
    local arena_r,arena_g,arena_b,arena_a = self.arena:getDrawColor()

    Draw.setColor(r * arena_r, g * arena_g, b * arena_b, a * arena_a)
    love.graphics.setLineStyle("rough")
    love.graphics.setLineWidth(self.arena.line_width)
    love.graphics.line(unpack(self.arena.border_line))
end

function ArenaSprite:drawBackground()
    for _,triangle in ipairs(self.arena.triangles) do
        love.graphics.polygon("fill", unpack(triangle))
    end
end

---@param key any
---@return boolean
function ArenaSprite:canDeepCopyKey(key)
    return super.canDeepCopyKey(self, key) and key ~= "arena"
end

return ArenaSprite