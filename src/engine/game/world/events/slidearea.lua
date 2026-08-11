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
        if chara.is_player and chara.jumping then
            return
        end

        if not chara:isSliding() then
            if chara:checkSlideStop() then
                return
            end

            Assets.stopAndPlaySound("noise")
        end

        if self.lock_movement then
            chara:setState("SLIDE_LOCK")
        else
            chara:setState("SLIDE")
        end
    end
end

function SlideArea:update()
    if not Game.world.player then
        return
    end

    Object.startCache()

    if Game.world.player.y > self.y + self.height and not Game.world.player:meetsCollider(self.collider) then
        self.solid = true
    else
        self.solid = false
    end

    Object.endCache()

    super.update(self)
end

return SlideArea
