local Savepoint, super = Class(Event)

function Savepoint:init(data)
    super:init(self, data.center_x, data.center_y, data.width, data.height)

    self.solid = true

    self:setOrigin(0.5, 0.5)
    self:setSprite("world/event/savepoint", 1/6)
end

function Savepoint:onInteract(player, dir)
    Assets.playSound("snd_power")

    --local text = DialogueText("* The power of [color:pink]test dialogue[color:reset]\nshines within you.")
    --text.x = SCREEN_WIDTH/2 - ((28 / 2) * 16)
    --text.y = SCREEN_HEIGHT - (3 * 30)
    --self.stage:addChild(text)
    Cutscene.start("test")

    return true
end

return Savepoint