---@class PushBlock : Event
---@overload fun(...) : PushBlock
local PushBlock, super = Class(Event)

function PushBlock:init(x, y, w, h, properties, sprite, solved_sprite)
    super.init(self, x, y, w, h)

    properties = properties or {}

    self.default_sprite = properties["sprite"] or sprite or "world/events/push_block"
    self.solved_sprite = properties["solvedsprite"] or properties["sprite"] or solved_sprite or sprite or "world/events/push_block_solved"

    self:setSprite(self.default_sprite)
    self.solid = true

    -- Options
    self.push_dist = properties["pushdist"] or 40
    self.push_time = properties["pushtime"] or 0.2

    self.push_sound = properties["pushsound"] or "noise"

    self.press_buttons = properties["pressbuttons"] ~= false

    self.lock_in_place = properties["lock"] or false
    self.input_lock = properties["inputlock"]

    -- State variables
    self.start_x = self.x
    self.start_y = self.y

    -- IDLE, PUSH, RESET
    self.state = "IDLE"

    self.solved = false
end

function PushBlock:onInteract(chara, facing)
    self:playPushSound()

    if self.state ~= "IDLE" then return true end

    if not self:checkCollision(facing) then
        self:onPush(facing)
    else
        self:onPushFail(facing)
    end

    return true
end

function PushBlock:playPushSound()
    if self.push_sound and self.push_sound ~= "" then
        Assets.stopAndPlaySound(self.push_sound)
    end
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
    if self.solved then
        if self.lock_in_place then
            return
        end

        self.solved = false
        self:onUnsolved()
    end

    local input_lock = Game:getConfig("pushBlockInputLock")
    if self.input_lock ~= nil then
        input_lock = self.input_lock
    end

    if input_lock then
        Game.lock_movement = true
    end

    self.state = "PUSH"
    local dx, dy = Utils.getFacingVector(facing)
    self:slideTo(self.x + dx * self.push_dist, self.y + dy * self.push_dist, self.push_time, "linear", function()
        self.state = "IDLE"
        self:onPushEnd(facing)

        if input_lock and not self.world.cutscene then
            Game.lock_movement = false
        end
    end)
end

function PushBlock:onSolved()
    self:setSprite(self.solved_sprite)
end

function PushBlock:onUnsolved()
    self:setSprite(self.default_sprite)
end

function PushBlock:onPushEnd(facing) end
function PushBlock:onPushFail(facing) end

function PushBlock:reset()
    if self.solved then
        self.solved = false
        self:onUnsolved()
    end

    self.state = "RESET"
    self.collidable = false
    self.sprite:fadeToSpeed(0, 0.2, function()
        self.x = self.start_x
        self.y = self.start_y
        self:onReset()
        self.sprite:fadeToSpeed(1, 0.2, function()
            self.collidable = true
            self.state = "IDLE"
        end)
    end)
end

function PushBlock:onReset() end

return PushBlock