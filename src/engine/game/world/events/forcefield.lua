--- Creates an electric forcefield that the player cannot pass through until a condition is met. \
--- `Forcefield` is an [`Event`](lua://Event.init) - naming an object `forcefield` on an `objects` layer in a map creates this object. \
--- See this object's Fields for the configurable properties on this object.
---@class Forcefield : Event
---
---@field end_sprite        love.Image[]
---@field middle_sprite     love.Image[]
---@field single_sprite     love.Image[]
---
---@field anim_speed        number  Speed of the forcefield animation, in seconds (Defaults to `3/30`)
---@field anim_timer        number  Internal timer for the sprite animation
---
---@field solid             boolean *[Property `solid`]* Whether the forcefield is solid (Defaults to `true`)
---@field always_visible    boolean *[Property `visible`]* Whether the forcefield is visible even when the player is not nearby (Defaults to `false`)
---
---@field flag              string  *[Property `flag`]* The name of the flag to check for whether this forcefield is active - if `!` is at the start of the flag, the check will be [`inverted`](lua://Forcefield.inverted)
---@field inverted          boolean *[Property `inverted`]* Whether the flagcheck is inverted such that if `flag` is `flag_value`, the forcefield is inactive, and is active otherwise
---@field flag_value        boolean *[Property `value`]* The value that `flag` should be for the forcefield to be active
---
---@overload fun(...) : Forcefield
local Forcefield, super = Class(Event)

---@param x number
---@param y number
---@param shape? {[1]: number, [2]: number, [3]: table?}
---@param properties? table
function Forcefield:init(x, y, shape, properties)
    super.init(self, x, y, shape)

    self.end_sprite = Assets.getFramesOrTexture("world/events/forcefield/end")
    self.middle_sprite = Assets.getFramesOrTexture("world/events/forcefield/middle")
    self.single_sprite = Assets.getFramesOrTexture("world/events/forcefield/single")

    self.anim_speed = 3 / 30
    self.anim_timer = 0

    self:updateSize()

    properties = properties or {}

    self.solid = properties["solid"] ~= false

    self.always_visible = properties["visible"] or false

    self.flag, self.inverted, self.flag_value = TiledUtils.parseFlagProperties("flag", "inverted", "value", nil, properties)

    self:updateActive()
end

function Forcefield:updateSize()
    if self.width == self.height or (self.width < 40 and self.height < 40) then
        self.dir = "none"

        self.start_x = self.width / 2
        self.start_y = self.height / 2

        self.end_x = self.start_x
        self.end_y = self.start_y
    elseif self.width > self.height then
        self.dir = "right"

        self.start_x = math.min(20, self.width / 2)
        self.start_y = self.height / 2

        self.end_x = self.width - self.start_x
        self.end_y = self.start_y
    elseif self.height > self.width then
        self.dir = "down"

        self.start_x = self.width / 2
        self.start_y = math.min(20, self.height / 2)

        self.end_x = self.start_x
        self.end_y = self.height - self.start_y
    end
end

function Forcefield:updateActive()
    local success = false

    if self.flag then
        local value = Game:getFlag(self.flag) or (self.world and self.world.map:getFlag(self.flag))

        if self.flag_value ~= nil then
            success = (value == self.flag_value)
        else
            success = (value or false)
        end
    else
        success = true
    end

    if success ~= self.inverted then
        self.visible = true
        self.collidable = true
    else
        self.visible = false
        self.collidable = false
    end
end

function Forcefield:onInteract(player, dir)
    Game.world:showText("* (It appears to be some kind of forcefield.)")

    return true
end

function Forcefield:update()
    self.anim_timer = self.anim_timer + DT

    if self.always_visible then
        self.alpha = 1
    elseif self.world and self.world.player then
        local player = self.world.player

        local dist_x, dist_y = 0, 0

        if player.x >= self.x and player.x < self.x + self.width then
            dist_x = 0
        else
            dist_x = math.min(math.abs(player.x - self.x), math.abs(player.x - (self.x + self.width)))
        end

        if player.y >= self.y and player.y < self.y + self.height then
            dist_y = 0
        else
            dist_y = math.min(math.abs(player.y - self.y), math.abs(player.y - (self.y + self.height)))
        end

        local fade_dist = MathUtils.clamp(math.max(dist_x, dist_y), 20, 80)

        self.alpha = 1 - (fade_dist - 20) / 60
    end

    self:updateActive()

    super.update(self)
end

function Forcefield:draw()
    local anim_speed = Kristal.Config["simplifyVFX"] and (self.anim_speed * 4) or self.anim_speed
    local frame = self.anim_speed > 0 and math.floor(self.anim_timer / anim_speed) or 0

    if self.dir == "none" then
        local sprite = self.single_sprite[(frame % #self.single_sprite) + 1]
        Draw.draw(sprite, self.start_x, self.start_y, 0, 2, 2, sprite:getWidth() / 2, sprite:getHeight() / 2)
    else
        local end_sprite = self.end_sprite[(frame % #self.end_sprite) + 1]
        local middle_sprite = self.middle_sprite[(frame % #self.middle_sprite) + 1]

        local rot = (self.dir == "down") and math.rad(90) or 0

        local mid_size = (self.dir == "down") and (self.end_y - self.start_y) or (self.end_x - self.start_x)
        mid_size = mid_size - 40

        local mid_count = math.ceil(mid_size / 40)
        local mid_scale = (mid_size / mid_count) / 40

        for i = 1, mid_count do
            local mid_x, mid_y = self.start_x, self.start_y
            local sx, sy = 2 * mid_scale, 2
            if self.dir == "right" then
                mid_x = self.start_x + 20 + (20 * mid_scale) + ((i - 1) * 40 * mid_scale)
            elseif self.dir == "down" then
                mid_y = self.start_y + 20 + (20 * mid_scale) + ((i - 1) * 40 * mid_scale)
            end
            Draw.draw(middle_sprite, mid_x, mid_y, rot, sx, sy, middle_sprite:getWidth() / 2, middle_sprite:getHeight() / 2)
        end

        Draw.draw(end_sprite, self.start_x, self.start_y, rot, 2, 2, end_sprite:getWidth() / 2, end_sprite:getHeight() / 2)
        Draw.draw(end_sprite, self.end_x, self.end_y, rot + math.rad(180), 2, 2, end_sprite:getWidth() / 2, end_sprite:getHeight() / 2)
    end

    super.draw(self)
end

return Forcefield
