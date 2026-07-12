--- A rectangular hitbox used for collision detection.
---@class Hitbox : Collider
---@field x number # The X coordinate of the hitbox.
---@field y number # The Y coordinate of the hitbox.
---@field width number # The width of the hitbox.
---@field height number # The height of the hitbox.
---@overload fun(owner: Object?, x: number?, y: number?, width: number?, height: number?, mode: Collider.Mode?) : Hitbox
local Hitbox, super = Class(Collider)

---@param owner Object?
---@param x number?
---@param y number?
---@param width number?
---@param height number?
---@param mode Collider.Mode?
function Hitbox:init(owner, x, y, width, height, mode)
    super.init(self, owner, mode)

    self.x = x or 0
    self.y = y or 0
    self.width = width or 0
    self.height = height or 0
end

function Hitbox:getColliderType()
    return CollisionRegistry.RECTANGLE
end

--- Gets the axis-aligned bounding box of the hitbox.
---@return number x # The X coordinate of the bounding box.
---@return number y # The Y coordinate of the bounding box.
---@return number width # The width of the bounding box.
---@return number height # The height of the bounding box.
function Hitbox:getRect()
    return self.x, self.y, self.width, self.height
end

--- Sets the axis-aligned bounding box of the hitbox.
---@param x number # The X coordinate of the bounding box.
---@param y number # The Y coordinate of the bounding box.
---@param width number # The width of the bounding box.
---@param height number # The height of the bounding box.
function Hitbox:setRect(x, y, width, height)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
end

--- Gets this collider's shape as a rectangle or polygon (depending on transformation) for the given other collider.
---@param other Collider # The other collider to get the shape for.
---@return boolean aabb # `true` if the shape is a rectangle, `false` if it is a polygon.
---@return [number, number, number, number]|number[][] shape # The shape of the collider as a rectangle or polygon.
function Hitbox:getRectOrPolyFor(other)
    local tf1, tf2 = other:getTransformsWith(self)

    local x, y, width, height = self:getRect()

    local ul_x, ul_y = other:getLocalPoint(tf1, tf2, x, y)
    local ur_x, ur_y = other:getLocalPoint(tf1, tf2, x + width, y)
    local dr_x, dr_y = other:getLocalPoint(tf1, tf2, x + width, y + height)
    local dl_x, dl_y = other:getLocalPoint(tf1, tf2, x, y + height)

    if ul_y == ur_y and ul_x == dl_x then
        local min_x, min_y = math.min(ul_x, dr_x), math.min(ul_y, dr_y)
        local max_x, max_y = math.max(ul_x, dr_x), math.max(ul_y, dr_y)

        return true, {min_x, min_y, max_x - min_x, max_y - min_y}
    end

    return false, {
        {ul_x, ul_y},
        {ur_x, ur_y},
        {dr_x, dr_y},
        {dl_x, dl_y}
    }
end

--- Draws the hitbox outlined with the given color.
---@param r number? # The red component of the color.
---@param g number? # The green component of the color.
---@param b number? # The blue component of the color.
---@param a number? # The alpha component of the color.
function Hitbox:draw(r, g, b, a)
    Draw.setColor(r, g, b, a)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", self.x, self.y, MathUtils.absClamp(self.width, 1, math.huge), MathUtils.absClamp(self.height, 1, math.huge))
    Draw.setColor(1, 1, 1, 1)
end

--- Draws the hitbox filled with the given color.
---@param r number? # The red component of the color.
---@param g number? # The green component of the color.
---@param b number? # The blue component of the color.
---@param a number? # The alpha component of the color.
function Hitbox:drawFill(r, g, b, a)
    Draw.setColor(r, g, b, a)
    love.graphics.rectangle("fill", self.x, self.y, MathUtils.absClamp(self.width, 1, math.huge), MathUtils.absClamp(self.height, 1, math.huge))
    Draw.setColor(1, 1, 1, 1)
end

return Hitbox
