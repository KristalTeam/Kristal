local FallenStarBullet, super = Class("StarBullet", "FallenStarBullet")

function FallenStarBullet:init(x, y)
    super.init(self, x, y)
    self.sprite:setColor(1, 1, 0)
end

function FallenStarBullet:onCollide(soul)
    Game.battle.tension_bar:flash()

    Assets.playSound("swallow")
    Assets.playSound("bell_bounce_short", 1, Utils.random(1, 1.3))
    self:remove()
    Game:giveTension(4) -- Jackenstein's treasure gives 2.5 (1%), these are infrequent so give 4%
end

return FallenStarBullet
