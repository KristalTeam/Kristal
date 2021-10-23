local ActionBox, super = Class(Object)

function ActionBox:init(x, y, index, battler)
    super:init(self, x, y)

    self.btn_fight  = {Assets.getTexture("ui/battle/btn/fight" ), Assets.getTexture("ui/battle/btn/fight_h" )}
    self.btn_act    = {Assets.getTexture("ui/battle/btn/act"   ), Assets.getTexture("ui/battle/btn/act_h"   )}
    self.btn_magic  = {Assets.getTexture("ui/battle/btn/magic" ), Assets.getTexture("ui/battle/btn/magic_h" )}
    self.btn_item   = {Assets.getTexture("ui/battle/btn/item"  ), Assets.getTexture("ui/battle/btn/item_h"  )}
    self.btn_spare  = {Assets.getTexture("ui/battle/btn/spare" ), Assets.getTexture("ui/battle/btn/spare_h" )}
    self.btn_defend = {Assets.getTexture("ui/battle/btn/defend"), Assets.getTexture("ui/battle/btn/defend_h")}

    self.buttons = {
        self.btn_fight,
        self.btn_act,
        self.btn_item,
        self.btn_spare,
        self.btn_defend
    }

    self.box_y_offset = 0
    self.animation_timer = 0

    self.index = index
    self.battler = battler

    self.selected_button = 1

    self.revert_to = 40
end

function ActionBox:draw()
    self:drawActionBox()

    self:drawChildren()
end

function ActionBox:select()
    if self.selected_button == 1 then
        Game.battle:setState("ENEMYSELECT", "ATTACK")
    elseif self.selected_button == 2 then
        Game.battle:setState("ENEMYSELECT", "ACT")
    elseif self.selected_button == 4 then
        Game.battle:setState("ENEMYSELECT", "SPARE")

    elseif self.selected_button == 5 then -- TODO: unhardcode!
        self.battler:setBattleSprite("defend", 1/15, false)
        self.battler.defending = true
        self.revert_to = Game.battle.tension_bar:giveTension(40)
        Game.battle:nextParty()
    end
end

function ActionBox:unselect()
    -- We have to uncommit any action that we did before.
    self.battler:setBattleSprite("idle", 1/5, true)
    if self.selected_button == 5 then -- TODO: unhardcode!
        self.battler.defending = false
        Game.battle.tension_bar:removeTension(self.revert_to)
    elseif self.selected_button == 4 then -- TODO: unhardcode!
        Game.battle:removeAction(Game.battle.current_selecting)
    elseif self.selected_button == 2 then -- TODO: unhardcode!
        Game.battle:removeAction(Game.battle.current_selecting)
    elseif self.selected_button == 1 then -- TODO: unhardcode!
        Game.battle:removeAction(Game.battle.current_selecting)
    end
end

function ActionBox:drawActionBox()
    love.graphics.setColor(1, 1, 1, 1)

    -- Draw the buttons
    for index, button in ipairs(self.buttons) do
        local frame = 1
        if (index == self.selected_button) and (self.index == Game.battle.current_selecting) then
            -- If it's highlighted, use the second texture in the table
            frame = 2
        end
        -- Draw the button, 35 pixels between each
        love.graphics.draw(button[frame], 20 + (35 * (index - 1)), 8)
    end

    if (Game.battle.current_selecting == self.index) then
        self.animation_timer = self.animation_timer + 1 * (DT * 30)
    else
        self.animation_timer = self.animation_timer - 1 * (DT * 30)
    end

    if self.animation_timer > 7 then
        self.animation_timer = 7
    end

    if (Game.battle.current_selecting ~= self.index) and (self.animation_timer > 3) then
        self.animation_timer = 3
    end

    if self.animation_timer < 0 then
        self.animation_timer = 0
    end

    if Game.battle.current_selecting == self.index then
        self.box_y_offset = Ease.outCubic(self.animation_timer, 0, 32, 7)
        love.graphics.setColor(self.battler.chara.color)
    else
        self.box_y_offset = Ease.outCubic(3 - self.animation_timer, 32, -32, 3)
        love.graphics.setColor(51/255, 32/255, 51/255, 1)
    end

    love.graphics.setLineWidth(2)
    love.graphics.line(1  , 2 - self.box_y_offset, 1,   37 - self.box_y_offset)
    love.graphics.line(212, 2 - self.box_y_offset, 212, 37 - self.box_y_offset)
    love.graphics.line(0  , 1 - self.box_y_offset, 213, 1  - self.box_y_offset)

    if Game.battle.current_selecting == self.index then
        love.graphics.setColor(self.battler.chara.color)
    else
        love.graphics.setColor(0, 0, 0, 1)
    end

    love.graphics.setLineWidth(2)
    love.graphics.line(1  , 2, 1,   37)
    love.graphics.line(212, 2, 212, 37)
    love.graphics.line(0  , 6, 213, 6 )

    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", 2, 327 - self.box_y_offset - 325, 209, 35)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(Assets.getTexture(self.battler.chara.head_icons .. "/head"), 12 + 1, 11 - self.box_y_offset)
    love.graphics.draw(Assets.getTexture(self.battler.chara.name_sprite),               51, 14 - self.box_y_offset)
end

function ActionBox:drawActionArena()
    -- Draw the top line of the action area
    love.graphics.setColor(51/255, 32/255, 51/255, 1)
    love.graphics.rectangle("fill", 0, 362, 640, 3)
    -- Draw the background of the action area
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", 0, 365, 640, 115)
end

return ActionBox