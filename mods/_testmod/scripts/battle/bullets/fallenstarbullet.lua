local FallenStarBullet, super = Class("StarBullet", "FallenStarBullet")

function FallenStarBullet:init(x, y)
    super.init(self, x, y)
    self.sprite:setColor(1, 1, 0)
end

function FallenStarBullet:onCollide(soul)
    -- I get that this seems tempting to copy into your mod, but don't forget the #1 testmod rule:
    -- NONE OF THIS IS INTENDED TO BE USED BY OTHER PEOPLE.
    -- THIS IS NOT HOW DELTARUNE WORKS. THIS IS INACCURATE AND ONLY MADE FOR TESTING.
    -- You're better off waiting for someone else to make a proper implementation.

    Assets.playSound("swallow")
    self:remove()
    Game:giveTension(4) -- Jackenstein's treasure gives 2.5 (1%), these are infrequent so give 4%

    -- TODO: This creates an AfterImage of the tension bar.
    -- DR actually has a separate object to flash the bar.
    -- Kristal should probably implement something similar, as it doesn't seem like Darkness is going to be a chapter gimmick.
    local afterimage = Game.battle:addChild(AfterImage(Game.battle.tension_bar, 1, 0.1))
    afterimage.layer = Game.battle.tension_bar.layer + 1
    afterimage:addFX(ColorMaskFX({ 1, 1, 1 }, 1))

    -- (Also, this is completely missing the sparkles...)
end

return FallenStarBullet
