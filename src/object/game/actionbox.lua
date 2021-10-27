local ActionBox, super = Class(Object)

function ActionBox:init(x, y, index, battler)
    super:init(self, x, y)

    self.btn_fight  = {Assets.getTexture("ui/battle/btn/fight" ), Assets.getTexture("ui/battle/btn/fight_h" )}
    self.btn_act    = {Assets.getTexture("ui/battle/btn/act"   ), Assets.getTexture("ui/battle/btn/act_h"   )}
    self.btn_magic  = {Assets.getTexture("ui/battle/btn/magic" ), Assets.getTexture("ui/battle/btn/magic_h" )}
    self.btn_item   = {Assets.getTexture("ui/battle/btn/item"  ), Assets.getTexture("ui/battle/btn/item_h"  )}
    self.btn_spare  = {Assets.getTexture("ui/battle/btn/spare" ), Assets.getTexture("ui/battle/btn/spare_h" )}
    self.btn_defend = {Assets.getTexture("ui/battle/btn/defend"), Assets.getTexture("ui/battle/btn/defend_h")}

    self.buttons = {}

    table.insert(self.buttons,self.btn_fight)
    if battler.chara.has_act then
        table.insert(self.buttons,self.btn_act)
    end
    if battler.chara.has_spells then
        table.insert(self.buttons,self.btn_magic)
    end
    table.insert(self.buttons,self.btn_item)
    table.insert(self.buttons,self.btn_spare)
    table.insert(self.buttons,self.btn_defend)

    self.box_y_offset = 0
    self.animation_timer = 0

    self.index = index
    self.battler = battler

    self.selected_button = 1

    self.revert_to = 40

    self.head_sprite = Sprite(battler.chara.head_icons.."/head", 13, 11)
    self.name_sprite = Sprite(battler.chara.name_sprite,         51, 14)
    self.hp_sprite   = Sprite("ui/hp", 109, 22)

    self:addChild(self.head_sprite)
    self:addChild(self.name_sprite)
    self:addChild(self.hp_sprite)

    self.font = Assets.getFont("smallnumbers")
end

function ActionBox:setHeadIcon(icon)
    self.head_sprite:setSprite(self.battler.chara.head_icons.."/"..icon)
end

function ActionBox:draw()
    self:drawActionBox()

    self:drawChildren()
end

function ActionBox:select()  -- TODO: unhardcode!
    if self.selected_button == 1 then
        Game.battle:setState("ENEMYSELECT", "ATTACK")
    elseif self.selected_button == 2 then
        if self.battler.chara.has_act then
            Game.battle:setState("ENEMYSELECT", "ACT")
        else
            Game.battle.menu_items = {}
            for _,spell_id in ipairs(self.battler.chara.spells) do
                local spell = Registry.getSpell(spell_id)
                local item = {
                    ["name"] = spell.name,
                    ["tp"] = spell.cost,
                    ["description"] = spell.effect,
                    ["party"] = spell.party,
                    ["color"] = spell.color or {1, 1, 1, 1},
                    ["data"] = spell
                }
                table.insert(Game.battle.menu_items, item)
            end
            Game.battle:setState("MENUSELECT", "SPELLS")
        end
    elseif self.selected_button == 4 then
        Game.battle:setState("ENEMYSELECT", "SPARE")

    elseif self.selected_button == 5 then
        self.battler:setAnimation("battle/defend")
        self.head_sprite:setSprite(self.battler.chara.head_icons.."/defend")
        self.battler.defending = true
        self.revert_to = Game.battle.tension_bar:giveTension(40)
        Game.battle:nextParty()
    end
end

function ActionBox:unselect()
    -- We have to uncommit any action that we did before.
    self.battler:setAnimation("battle/idle")
    self.head_sprite:setSprite(self.battler.chara.head_icons.."/head")
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


    self.head_sprite.y = 11 - self.box_y_offset
    self.name_sprite.y = 14 - self.box_y_offset
    self.hp_sprite.y   = 22 - self.box_y_offset

    love.graphics.setColor(128/255, 0, 0, 1)
    love.graphics.rectangle("fill", 128, 22 - self.box_y_offset, 76, 9)

    local health = (self.battler.chara.health / self.battler.chara.stats.health) * 76

    if health > 0 then
        love.graphics.setColor(self.battler.chara.color)
        love.graphics.rectangle("fill", 128, 22 - self.box_y_offset, health, 9)
    end


    if health <= 0 then
        love.graphics.setColor(1, 0, 0, 1)
    elseif (self.battler.chara.health <= (self.battler.chara.stats.health / 4)) then
        love.graphics.setColor(1, 1, 0, 1)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end


    local health_offset = 0
    health_offset = (#tostring(self.battler.chara.health) - 1) * 8

    love.graphics.setFont(self.font)
    love.graphics.print(self.battler.chara.health, 152 - health_offset, 9 - self.box_y_offset)
    love.graphics.print("/", 161, 9 - self.box_y_offset)
    love.graphics.print(self.battler.chara.stats.health, 181, 9 - self.box_y_offset)
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