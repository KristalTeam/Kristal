local spell, super = Class(Spell, "scythemare")

function spell:init()
    super.init(self)

    -- Display name
    self.name = "Scythemare"
    -- Name displayed when cast (optional)
    self.cast_name = nil

    -- Battle description
    self.effect = "Spare all\nTIRED foes"

    -- Menu description
    self.description = "Inflicts all enemies with bad dreams.\nAll TIRED enemies will be SPAREd."

    -- TP cost
    self.cost = 40

    -- Target mode (ally, party, enemy, enemies, or none)
    self.target = "enemies"

    -- Tags that apply to this spell
    self.tags = {"spare_tired"}
end

function spell:getTPCost(chara)
    local cost = super.getTPCost(self, chara)

    if chara and chara:checkArmor("o_glove") then
        cost = cost - 20
    end

    return cost
end

function spell:onCast(user, targets)
    local count = 0
    for _, target in ipairs(targets) do
        if target.done_state == nil then
            count = count + 1
            local curr_count = count
            Game.battle.timer:after((10 * (count - 1)) / 30, function()
                local effect_x, effect_y = target:getRelativePos(target.width / 2, target.height / 2)

                local effect = ScythemareEffect(effect_x, effect_y, target.tired, {
                    index = count,
                    joker = user.chara:checkWeapon("devilsknife"),
                    on_finish_func = function(effect)
                        if effect.success then
                            target:spare(true)
                        end
                    end,
                    play_sound = curr_count == 1,
                    laugh = curr_count == 1,
                })

                effect.layer = target.layer + (count * 0.1)

                target.parent:addChild(effect)
            end)
        end
    end

    Game.battle.timer:after((64 + (10 * count)) / 30, function()
        Game.battle:finishAction()
    end)

    -- Don't manually finish the action, we wanna do it ourselves
    return false
end

return spell
