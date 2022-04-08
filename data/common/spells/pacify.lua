local spell, super = Class(Spell, "pacify")

function spell:init()
    super:init(self)

    -- Display name
    self.name = "Pacify"

    -- Battle description
    self.effect = "Spare\nTIRED foe"
    -- Menu description
    self.description = "SPARE a tired enemy by putting them to sleep."

    -- TP cost
    self.cost = 16

    -- Target mode (party, enemy, or none/nil)
    self.target = "enemy"

    -- Tags that apply to this spell
    self.tags = {"spare_tired"}
end

function spell:getCastMessage(user, target)
    if target.tired then
        return "* "..user.chara.name.." cast PACIFY!"
    elseif target.mercy < 100 then
        return "* "..user.chara.name.." cast PACIFY!\n[wait:0.25s]* But the enemy wasn't [color:blue]TIRED[color:reset]..."
    else
        return "* "..user.chara.name.." cast PACIFY!\n[wait:0.25s]* But the foe wasn't [color:blue]TIRED[color:reset]... try\n[color:yellow]SPARING[color:reset]!"
    end
end

function spell:onCast(user, target)
    if target.tired then
        Assets.playSound("snd_spell_pacify")

        target:spare(true)

        local pacify_x, pacify_y = target:getRelativePos(target.width/2, target.height/2)
        local z_count = 0
        local z_parent = target.parent
        Game.battle.timer:every(1/15, function()
            z_count = z_count + 1
            local z = SpareZ(z_count * -40, pacify_x, pacify_y)
            z.layer = target.layer + 0.002
            z_parent:addChild(z)
        end, 8)
    else
        local recolor = target:addFX(RecolorFX())
        Game.battle.timer:during(8/30, function()
            recolor.color = Utils.lerp(recolor.color, {0, 0, 1}, 0.12 * DTMULT)
        end, function()
            Game.battle.timer:during(8/30, function()
                recolor.color = Utils.lerp(recolor.color, {1, 1, 1}, 0.16 * DTMULT)
            end, function()
                target:removeFX(recolor)
            end)
        end)
    end
end

return spell