local Starwalker, super = Class(Encounter)

function Starwalker:init()
    super.init(self)

    self.text = "* Star walker has      changed forms"

    self.starwalker = self:addEnemy("starwalker", 530, 238)

    self.background = true

    self.no_end_message = false

    self.timer = 0

    -- music by nyako! give credit if used!
    self.music = "starwalker"

    --self.default_xactions = false

    --Game.battle:registerXAction("susie", "Snap")
    --Game.battle:registerXAction("susie", "Supercharge", "Charge\nfaster", 80)
end

function Starwalker:update()
    super.update(self)

    for _,enemy in pairs(Game.battle.enemy_world_characters) do
        enemy:remove()
    end
end

return Starwalker