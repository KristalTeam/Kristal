local DarkPowerMenu, super = Class(Object)

function DarkPowerMenu:init()
    super:init(self, 82, 112, 477, 277)

    self.draw_children_below = 0

    self.font = Assets.getFont("main")

    self.ui_move = Assets.newSound("ui_move")
    self.ui_select = Assets.newSound("ui_select")
    self.ui_cant_select = Assets.newSound("ui_cant_select")
    self.ui_cancel_small = Assets.newSound("ui_cancel_small")

    self.heart_sprite = Assets.getTexture("player/heart")
    self.arrow_sprite = Assets.getTexture("ui/page_arrow")

    self.tp_sprite = Assets.getTexture("ui/menu/caption_tp")

    self.caption_sprites = {
          ["char"] = Assets.getTexture("ui/menu/caption_char"),
         ["stats"] = Assets.getTexture("ui/menu/caption_stats"),
        ["spells"] = Assets.getTexture("ui/menu/caption_spells"),
    }

    self.stat_icons = {
         ["attack"] = Assets.getTexture("ui/menu/icon/sword"),
        ["defense"] = Assets.getTexture("ui/menu/icon/armor"),
          ["magic"] = Assets.getTexture("ui/menu/icon/magic"),
   }

    self.bg = DarkBox(0, 0, self.width, self.height)
    self.bg.layer = -1
    self:addChild(self.bg)

    self.party = DarkMenuPartySelect(8, 48)
    self.party.focused = true
    self:addChild(self.party)

    self.party.on_select = function(new, old)
        Game.party[old]:onPowerDeselect(self)
        Game.party[new]:onPowerSelect(self)
    end

    -- PARTY, SPELLS
    self.state = "PARTY"

    self.selected_spell = 1

    self.scroll_y = 1
end

function DarkPowerMenu:getSpells()
    local spells = {}
    local party = self.party:getSelected()
    if party.has_act then
        table.insert(spells, Registry.createSpell("_act"))
    end
    for _,spell in ipairs(party.spells) do
        table.insert(spells, spell)
    end
    return spells
end

function DarkPowerMenu:updateDescription()
    if self.state == "PARTY" then
        Game.world.menu:setDescription("", false)
    elseif self.state == "SPELLS" then
        local spell = self:getSpells()[self.selected_spell]
        Game.world.menu:setDescription(spell and spell.description or "", true)
    end
end

function DarkPowerMenu:onRemove(parent)
    super:onRemove(parent)
    Game.world.menu:updateSelectedBoxes()
end

function DarkPowerMenu:update(dt)
    if self.state == "PARTY" then
        if Input.pressed("cancel") then
            self.ui_cancel_small:stop()
            self.ui_cancel_small:play()
            Game.world.menu:closeBox()
            return
        elseif Input.pressed("confirm") then
            if #self:getSpells() > 0 then
                self.state = "SPELLS"

                self.party.focused = false

                self.ui_select:stop()
                self.ui_select:play()

                self.selected_spell = 1
                self.scroll_y = 1

                love.keyboard.setKeyRepeat(true)
                self:updateDescription()
            else
                self.ui_select:stop()
                self.ui_select:play()
            end
        end
    elseif self.state == "SPELLS" then
        if Input.pressed("cancel") then
            self.state = "PARTY"

            self.ui_cancel_small:stop()
            self.ui_cancel_small:play()

            self.party.focused = true
            
            love.keyboard.setKeyRepeat(false)
            self:updateDescription()
            return
        end
        local spells = self:getSpells()
        local old_selected = self.selected_spell
        if Input.pressed("up") then
            self.selected_spell = self.selected_spell - 1
        end
        if Input.pressed("down") then
            self.selected_spell = self.selected_spell + 1
        end
        self.selected_spell = Utils.clamp(self.selected_spell, 1, #spells)
        if self.selected_spell ~= old_selected then
            local min_scroll = math.max(1, self.selected_spell - 5)
            local max_scroll = math.min(math.max(1, #spells - 5), self.selected_spell)
            self.scroll_y = Utils.clamp(self.scroll_y, min_scroll, max_scroll)

            self.ui_move:stop()
            self.ui_move:play()
            self:updateDescription()
        end
    end
    super:update(self, dt)
end

function DarkPowerMenu:draw()
    love.graphics.setFont(self.font)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", -24, 104, 525, 6)
    love.graphics.rectangle("fill", 212, 104, 6, 200)

    love.graphics.draw(self.caption_sprites[  "char"],  42, -28, 0, 2, 2)
    love.graphics.draw(self.caption_sprites[ "stats"],  42,  98, 0, 2, 2)
    love.graphics.draw(self.caption_sprites["spells"], 298,  98, 0, 2, 2)

    self:drawChar()
    self:drawStats()
    self:drawSpells()

    super:draw(self)
end

function DarkPowerMenu:drawChar()
    local party = self.party:getSelected()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(party.name, 48, -7)
    love.graphics.print(party:getTitle(), 238, -7)
end

function DarkPowerMenu:drawStats()
    local party = self.party:getSelected()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.stat_icons[ "attack"], -8, 124, 0, 2, 2)
    love.graphics.draw(self.stat_icons["defense"], -8, 149, 0, 2, 2)
    love.graphics.draw(self.stat_icons[  "magic"], -8, 174, 0, 2, 2)
    love.graphics.print( "Attack:", 18, 118)
    love.graphics.print("Defense:", 18, 143)
    love.graphics.print(  "Magic:", 18, 168)
    local stats = party:getStats()
    love.graphics.print(stats[ "attack"], 148, 118)
    love.graphics.print(stats["defense"], 148, 143)
    love.graphics.print(stats[  "magic"], 148, 168)
    for i = 1, 3 do
        local x, y = 18, 168 + (i * 25)
        love.graphics.setFont(self.font)
        love.graphics.setColor(1, 1, 1)
        love.graphics.push()
        if not party:drawPowerStat(i, x, y, self) then
            love.graphics.setColor(0.25, 0.25, 0.25)
            love.graphics.print("???", x, y)
        end
        love.graphics.pop()
    end
end

function DarkPowerMenu:drawSpells()
    local spells = self:getSpells()

    local tp_x, tp_y
    local name_x, name_y

    if #spells <= 6 then
        tp_x, tp_y = 258, 118
        name_x, name_y = 328, 118
    else
        tp_x, tp_y = 242, 118
        name_x, name_y = 302, 118
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(self.tp_sprite, tp_x, tp_y - 5)

    for i = self.scroll_y, math.min(#spells, self.scroll_y + 5) do
        local spell = spells[i]
        local offset = i - self.scroll_y

        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print(tostring(spell.cost).."%", tp_x, tp_y + (offset * 25))
        love.graphics.print(spell.name, name_x, name_y + (offset * 25))
    end

    if self.state == "SPELLS" then
        love.graphics.setColor(Game:getSoulColor())
        love.graphics.draw(self.heart_sprite, tp_x - 20, tp_y + 10 + ((self.selected_spell - self.scroll_y) * 25))

        if #spells > 6 then
            love.graphics.setColor(1, 1, 1)
            local sine_off = math.sin((love.timer.getTime()*30)/12) * 3
            if self.scroll_y + 6 <= #spells then
                love.graphics.draw(self.arrow_sprite, 469, 273 + sine_off)
            end
            if self.scroll_y > 1 then
                love.graphics.draw(self.arrow_sprite, 469, 138 - sine_off, 0, 1, -1)
            end
            love.graphics.setColor(0.25, 0.25, 0.25)
            love.graphics.rectangle("fill", 473, 148, 6, 119)
            local percent = (self.scroll_y - 1) / (#spells - 6)
            love.graphics.setColor(1, 1, 1)
            love.graphics.rectangle("fill", 473, 148 + math.floor(percent * (119-6)), 6, 6)
        end
    end
end

return DarkPowerMenu