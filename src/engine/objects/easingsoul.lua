---@class EasingSoul : Object
---@overload fun(...) : EasingSoul
local EasingSoul, super = Class(Object)

function EasingSoul:init(x, y, target_x, target_y)
    super.init(self, x, y, 16, 16)
    self.sprite = self:addChild(Sprite("player/heart_menu", 0, 0))
    self.sprite:setScale(2)
    self.sprite:setColor(Kristal.getSoulColor())

    self.target_x = target_x or x
    self.target_y = target_y or y

    self.use_parent = false
    self.throw_error = true
end

function EasingSoul:setTarget(x, y)
    self.target_x = x
    self.target_y = y
end

function EasingSoul:update()
    super.update(self)

    if not self.use_parent then
        self.throw_error = false
        self:moveSoul()
        self.throw_error = true
    end
end

function EasingSoul:moveSoul()
    if self.throw_error and not self.use_parent then
        error("Soul moved manually while not in manual movement mode")
    end
    if (math.abs((self.target_x - self.x)) <= 2) then
        self.x = self.target_x
    end
    if (math.abs((self.target_y - self.y)) <= 2) then
        self.y = self.target_y
    end
    self.x = self.x + ((self.target_x - self.x) / 2) * DTMULT
    self.y = self.y + ((self.target_y - self.y) / 2) * DTMULT
end

return EasingSoul
