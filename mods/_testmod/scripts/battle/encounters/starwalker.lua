local Starwalker, super = Class(Encounter)

function Starwalker:init()
    super.init(self)

    self.text = "* Star walker has changed forms...\n* [color:yellow]TP[color:reset] Gain reduced outside of [color:yellow]Fallen Stars![color:reset]"

    self.starwalker = self:addEnemy("starwalker", 530, 238)

    self.background = true

    self.no_end_message = false

    self.timer = 0

    -- music by nyako! give credit if used!
    self.music = "starwalker"

    self.reduced_tension = true
    --self.default_xactions = false

    --Game.battle:registerXAction("susie", "Snap")
    --Game.battle:registerXAction("susie", "Supercharge", "Charge\nfaster", 80)
end

function Starwalker:isAutoHealingEnabled(target)
    return false
end

function Starwalker:canSwoon(target)
    if (target.chara.id == "kris") then
        return false
    end
    return true
end

function Starwalker:update()
    super.update(self)

    for _, enemy in pairs(Game.battle.enemy_world_characters) do
        enemy:remove()
    end
end

function Starwalker:createSoul(x, y, color)
    if self.starwalker.blue then
        return BlueSoul(x, y)
    end
    return Soul(x, y, color)
end

return Starwalker
