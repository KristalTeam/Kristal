--- SlideAreas cause the party to slide down them when entered. \
--- `SlideArea` is an [`Event`](lua://Event.init) - naming an object `slidearea` on an `objects` layer in a map creates this object. \
--- See this object's Fields for the configurable properties on this object.
---@class SlideArea : Event
---
---@field lock_movement boolean *[Property `lock`]* Whether the player's movement is locked while sliding (Defaults to `false`)
---
---@field solid boolean
---
---@overload fun(...) : SlideArea
local SlideArea, super = Class(Event)

function SlideArea:init(x, y, shape, properties)
    super.init(self, x, y, shape)

    self.lock_movement = properties["lock"] or false
end

function SlideArea:onCollide(chara)
    if (chara.last_y or chara.y) < self.y + self.height and chara.is_player then
        if chara.state ~= "SLIDE" then
            if self:checkAgainstWall(chara) then return end

            Assets.stopAndPlaySound("noise")
        end

        chara:setState("SLIDE", false, self.lock_movement)

        chara.current_slide_area = self
    end
end

function SlideArea:update()
    if not Game.world.player then return end

    local stopped = false

    Object.startCache()

    if Game.world.player.y > self.y + self.height and not Game.world.player:collidesWith(self.collider) then
        self.solid = true

        if Game.world.player.state == "SLIDE" and Game.world.player.current_slide_area == self then
            stopped = true
        end
    else
        self.solid = false
    end

    if not stopped and Game.world.player.state == "SLIDE" and Game.world.player.current_slide_area == self then
        stopped = self:checkAgainstWall(Game.world.player)
    end

    Object.endCache()

    if stopped then
        Game.world.player:setState("WALK")

        Game.world.player.current_slide_area = nil
    end

    super.update(self)
end

function SlideArea:checkAgainstWall(chara)
    local hb = chara.collider

    if hb and hb:includes(Hitbox) then
        local extended_hitbox = Hitbox(chara, hb.x + 0.25, hb.y + 0.25, hb.width - 0.5, (hb.height - 0.5) * 1.5)

        if self.world:checkCollision(extended_hitbox) then
            return true
        end
    end

    return false
end

return SlideArea