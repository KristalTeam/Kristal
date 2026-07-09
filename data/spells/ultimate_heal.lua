local spell, super = Class(Spell, "ultimate_heal")

function spell:init()
    super.init(self)

    -- Display name
    -- Name displayed when cast (optional)
    if Game.chapter <= 2 then
        self.name = "UltimatHeal"
        self.cast_name = "ULTIMATEHEAL"
    elseif Game.chapter = 3 then
        self.name = "UltraHeal"
        self.cast_name = "ULTRATEHEAL"
    elseif Game.chapter >= 4 then
        self.name = "BetterHeal"
        self.cast_name = "BETTERHEAL"
    end
    -- Battle description
    if Game.chapter <= 2 then
        self.effect = "Best\nhealing"
    elseif Game.chapter >= 3 then
        self.effect = "Heal\nAlly"
    end

    -- Menu description
    if Game.chapter <= 2 then
        self.description = "Heals 1 party member to the\nbest of Susie's ability."
    elseif Game.chapter = 3 then
        self.description = "An awesome healing spell.\n...right?"
    elseif Game.chapter >= 4 then
        self.description = "A healing spell that has grown with practice and confidence."
    end
    -- TP cost
    if Game.chapter <= 2 then
        self.cost = 100
    elseif Game.chapter = 3 then
        self.cost = 85
    elseif Game.chapter >= 4 then
        self.cost = 75

    -- Target mode (ally, party, enemy, enemies, or none)
    self.target = "ally"

    -- Tags that apply to this spell
    self.tags = {"heal"}
end

function spell:onCast(user, target)
    if Game.chapter <= 2 then
        local base_heal = user.chara:getStat("magic") + 1
    elseif Game.chapter = 3 then
        local base_heal = (user.chara:getStat("magic") * 1.5) + 10
    elseif Game.chapter >= 4 then
        local base_heal = (user.chara:getStat("magic") * 7) + 45
    end

    local heal_amount = Game.battle:applyHealBonuses(base_heal, user.chara)

    target:heal(heal_amount)
end

return spell
