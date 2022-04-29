local PushBlock, super = Class(Event)

function PushBlock:init(x, y, w, h, sprite)
    super:init(self, x, y, w, h)
    self:setSprite(sprite or "world/events/push_block")
    self.solid = true

    -- Options
    self.push_dist = 40
    self.push_time = 0.2

    self.play_noise = true

    -- State variables
    self.start_x = self.x
    self.start_y = self.y

    -- IDLE, PUSH, RESET
    self.state = "IDLE"
end

function PushBlock:onInteract(chara, facing)
    if self.play_noise then
        Assets.playSound("snd_noise", 0.8)
    end

    if self.state ~= "IDLE" then return true end

    if not self:checkCollision(facing) then
        self:onPush(facing)
    else
        self:onPushFail(facing)
    end

    return true
end

function PushBlock:checkCollision(facing)
    local collided = false

    local dx, dy = Utils.getFacingVector(facing)
    local target_x, target_y = self.x + dx * self.push_dist, self.y + dy * self.push_dist

    local x1, y1 = math.min(self.x, target_x), math.min(self.y, target_y)
    local x2, y2 = math.max(self.x + self.width, target_x + self.width), math.max(self.y + self.height, target_y + self.height)

    local bound_check = Hitbox(self.world, x1 + 1, y1 + 1, x2 - x1 - 2, y2 - y1 - 2)

    Object.startCache()
    for _,collider in ipairs(Game.world.map.block_collision) do
        if collider:collidesWith(bound_check) then
            collided = true
            break
        end
    end
    if not collided then
        self.collidable = false
        collided = self.world:checkCollision(bound_check)
        self.collidable = true
    end
    Object.endCache()

    return collided
end

function PushBlock:onPush(facing)
    self.state = "PUSH"
    local dx, dy = Utils.getFacingVector(facing)
    self:slideTo(self.x + dx * self.push_dist, self.y + dy * self.push_dist, self.push_time, "linear", function()
        self.state = "IDLE"
        self:onPushEnd(facing)
    end)
end

function PushBlock:onPushEnd(facing) end
function PushBlock:onPushFail(facing) end

function PushBlock:reset()
    self.state = "RESET"
    self.collidable = false
    self.sprite:fadeTo(0, 0.2, function()
        self.x = self.start_x
        self.y = self.start_y
        self.sprite:fadeTo(1, 0.2, function()
            self.collidable = true
            self.state = "IDLE"
        end)
    end)
end

return PushBlock