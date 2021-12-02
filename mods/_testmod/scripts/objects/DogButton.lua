local DogButton, super = Class(ActionButton)

function DogButton:init()
    super:init(self, "dog")
end

function DogButton:update(dt)
    self:setColor(Utils.hslToRgb((love.timer.getTime()/2) % 1, 1, 0.5))

    super:update(self, dt)
end

function DogButton:select()
    self:explode()
    Mod.dog_activated = false
    Game.battle.music:stop()
    for _,box in ipairs(Game.battle.battle_ui.action_boxes) do
        box:createButtons()
    end
end

return DogButton