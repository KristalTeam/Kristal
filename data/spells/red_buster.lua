local spell, super = Class(Spell, "red_buster")

function spell:init()
    super.init(self)

    -- Display name
    self.name = "Red Buster"
    -- Name displayed when cast (optional)
    self.cast_name = nil

    -- Battle description
    self.effect = "Red\nDamage"
    -- Menu description
    self.description = "Deals large Red-elemental damage to\none foe. Depends on Attack & Magic."

    -- TP cost
    self.cost = 60

    -- Target mode (ally, party, enemy, enemies, or none)
    self.target = "enemy"

    -- Tags that apply to this spell
    self.tags = {"rude", "damage"}
end

function spell:getCastMessage(user, target)
    return "* "..user.chara:getName().." used "..self:getCastName().."!"
end

function spell:onCast(user, target)
    local buster_finished = false
    local anim_finished = false
    local function finishAnim()
        anim_finished = true
        if buster_finished then
            Game.battle:finishAction()
        end
    end
    if not user:setAnimation("battle/rude_buster", finishAnim) then
        anim_finished = false
        user:setAnimation("battle/attack", finishAnim)
    end
    Game.battle.timer:after(15/30, function()
        Assets.playSound("rudebuster_swing")
        local x, y = user:getRelativePos(user.width, user.height/2 - 10, Game.battle)
        local tx, ty = target:getRelativePos(target.width/2, target.height/2, Game.battle)
        local blast = RudeBusterBeam(true, x, y, tx, ty, function(pressed)
            local damage = self:getDamage(user, target, pressed)
            if pressed then
                Assets.playSound("scytheburst")
            end
            local flash = target:flash()
            flash.color_mask:setColor(1, 0, 0)
            target:hurt(damage, user)
            buster_finished = true
            if anim_finished then
                Game.battle:finishAction()
            end
        end)
        blast.layer = BATTLE_LAYERS["above_ui"]
        Game.battle:addChild(blast)
    end)
    return false
end

function spell:getDamage(user, target, pressed)
    local damage = math.ceil((user.chara:getStat("magic") * 6) + (user.chara:getStat("attack") * 13) - (target.defense * 6)) + 90
    if pressed then
        damage = damage + 30
    end
    return damage
end

return spell