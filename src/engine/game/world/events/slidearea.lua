local SlideArea, super = Class(Event)

function SlideArea:init(x, y, w, h)
    super:init(self, x, y, w, h)
end

function SlideArea:onEnter(chara)
    if chara.y <= self.y + self.height/2 and chara.is_player then
        if chara.state ~= "SLIDE" then
            Assets.stopAndPlaySound("noise")
        end

        chara:setState("SLIDE")

        chara.current_slide_area = self
    end
end

function SlideArea:update()
    if not Game.world.player then return end

    if Game.world.player.y > self.y + self.height and not Game.world.player:collidesWith(self.collider) then
        self.solid = true

        if Game.world.player.state == "SLIDE" and Game.world.player.current_slide_area == self then
            Game.world.player:setState("WALK")

            Game.world.player.current_slide_area = nil
        end
    else
        self.solid = false
    end

    super:update(self)
end

return SlideArea