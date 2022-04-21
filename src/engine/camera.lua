local Camera = Class()

function Camera:init(parent, x, y, width, height, keep_in_bounds)
    self.parent = parent

    self.x = x or 0
    self.y = y or 0
    self.width = width or SCREEN_WIDTH
    self.height = height or SCREEN_HEIGHT

    -- Camera offset
    self.ox = 0
    self.oy = 0

    -- Camera zoom (scale)
    self.zoom = 1

    -- Camera bounds (for clamping)
    self.bounds = nil
    -- Whether the camera should stay in bounds
    self.keep_in_bounds = keep_in_bounds ~= false

    -- Camera pan target (for automatic panning)
    self.pan_target = nil
end

function Camera:getBounds()
    if not self.bounds then
        if self.parent then
            return 0, 0, self.parent.width, self.parent.height
        else
            return 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT
        end
    else
        return self.bounds.x, self.bounds.y, self.bounds.width, self.bounds.height
    end
end

function Camera:setBounds(x, y, width, height)
    if x then
        self.bounds = {x = x, y = y, width = width, height = height}
    else
        self.bounds = nil
    end
end

function Camera:getRect()
    return self.x - self.width / 2, self.y - self.height / 2, self.width, self.height
end

function Camera:getPosition() return self.x, self.y end
function Camera:setPosition(x, y)
    self.x = x
    self.y = y
    self:keepInBounds()
end

function Camera:getOffset() return self.ox, self.oy end
function Camera:setOffset(ox, oy)
    self.ox = ox
    self.oy = oy
end

function Camera:getZoom() return self.zoom end
function Camera:setZoom(zoom)
    self.zoom = zoom
    self:keepInBounds()
end

function Camera:approach(x, y, amount)
    self.x = Utils.approach(self.x, x, amount)
    self.y = Utils.approach(self.y, y, amount)
    self:keepInBounds()
end

function Camera:approachLinear(x, y, amount)
    local angle = Utils.angle(self.x, self.y, x, y)
    self.x = Utils.approach(self.x, x, math.abs(math.cos(angle)) * amount)
    self.y = Utils.approach(self.y, y, math.abs(math.sin(angle)) * amount)
    self:keepInBounds()
end

function Camera:panTo(x, y, time, after)
    local min_x, min_y = self:getMinPosition()
    local max_x, max_y = self:getMaxPosition()

    x = Utils.clamp(x, min_x, max_x)
    y = Utils.clamp(y, min_y, max_y)

    if self.x ~= x or self.y ~= y then
        local dist = Utils.dist(self.x, self.y, x, y)
        self.pan_target = {x = x, y = y, speed = (dist / (time or 1)) / 30, after = after}
        return true
    else
        return false
    end
end

function Camera:panToSpeed(x, y, speed, after)
    local min_x, min_y = self:getMinPosition()
    local max_x, max_y = self:getMaxPosition()

    x = Utils.clamp(x, min_x, max_x)
    y = Utils.clamp(y, min_y, max_y)

    if self.x ~= x or self.y ~= y then
        self.pan_target = {x = x, y = y, speed = speed, after = after}
        return true
    else
        return false
    end
end

function Camera:getMinPosition()
    local x, y, w, h = self:getBounds()
    return x + (self.width / self.zoom) / 2, y + (self.height / self.zoom) / 2
end

function Camera:getMaxPosition()
    local x, y, w, h = self:getBounds()
    return x + w - (self.width / self.zoom) / 2, y + h - (self.height / self.zoom) / 2
end

function Camera:keepInBounds()
    if self.keep_in_bounds then
        local min_x, min_y = self:getMinPosition()
        local max_x, max_y = self:getMaxPosition()

        self.x = Utils.clamp(self.x, min_x, max_x)
        self.y = Utils.clamp(self.y, min_y, max_y)
    end
end

function Camera:update(dt)
    if self.pan_target then
        local min_x, min_y = self:getMinPosition()
        local max_x, max_y = self:getMaxPosition()

        local target_x = Utils.clamp(self.pan_target.x, min_x, max_x)
        local target_y = Utils.clamp(self.pan_target.y, min_y, max_y)

        self:approachLinear(target_x, target_y, self.pan_target.speed * DTMULT)

        if self.x == target_x and self.y == target_y then
            local after = self.pan_target.after

            self.pan_target = nil

            if after then
                after()
            end
        end
    end

    self:keepInBounds()
end

function Camera:getParallax(px, py, ox, oy)
    local x, y, w, h = self:getRect()

    x = x + self.ox
    y = y + self.oy

    local parallax_x, parallax_y

    if ox then
        parallax_x = (x - (ox - w/2)) * (1 - px)
    else
        parallax_x = x * (1 - px)
    end

    if oy then
        parallax_y = (y - (oy - h/2)) * (1 - py)
    else
        parallax_y = y * (1 - py)
    end

    return parallax_x, parallax_y
end

function Camera:applyTo(transform)
    transform:translate((-self.x + self.width/2) - self.ox, (-self.y + self.height/2) - self.oy)
    transform:scale(self.zoom, self.zoom)
end

function Camera:getTransform()
    local transform = love.math.newTransform()
    self:applyTo(transform)
    return transform
end

return Camera