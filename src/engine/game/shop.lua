local Shop, super = Class(Object, "shop")

function Shop:init()
    super:init(self)

    -- Shown when you first enter a shop
    self.encounter_text = "* Hee hee...[wait:5]\n* Welcome,[wait:5] travellers."
    -- Shown when you return to the main menu of the shop
    self.shop_text = "* Take your time...[wait:5]\n* Ain't like it's\nbetter spent."
    -- Shown when you leave a shop
    self.leaving_text = "* This is leaving text."
    -- Shown when you're in the BUY menu
    self.buy_menu_text = "What do\nyou like\nto buy?"
    -- Shown when you're about to buy something.
    self.buy_confirmation_text = "Buy it for\n$%d ?"
    -- Shown when you refuse to buy something
    self.buy_refuse_text = "What,\nnot good\nenough?"
    -- Shown when you buy something
    self.buy_text = "Thanks for\nthat."
    -- Shown when you buy something and it goes in your storage
    self.buy_storage_text = "Thanks, it'll\nbe in your\nSTORAGE."
    -- Shown when you don't have enough money to buy something
    self.buy_too_expensive_text = "Not\nenough\nmoney."
    -- Shown when you don't have enough space to buy something.
    self.buy_no_space_text = "You're\ncarrying\ntoo much."
    -- Shown when you're in the SELL menu
    self.sell_menu_text = "What kind\nof junk\nyou got?"
    -- Shown when you're in the SELL ITEMS menu
    self.sell_items_text = "Alright,\ngive me\nan ITEM."
    -- Shown when you're in the SELL WEAPONS menu
    self.sell_weapons_text = "What WEAPON\nwill you\ngive me?"
    -- Shown when you're in the SELL ARMOR menu
    self.sell_armor_text = "What ARMOR\nwill you\ngive me?"
    -- Shown when you're in the SELL POCKET ITEMS menu
    self.sell_pocket_text = "Alright,\ngive me\nan ITEM."
    -- Shown when you try to sell an empty spot
    self.sell_nothing_text = "That's\nnothing."
    -- Shown when you refuse to sell something
    self.sell_refuse_text = "No?"
    -- Shown when you sell something
    self.sell_text = "That's it\nfor that."

    self.layers = {
        ["large_box"] = 16,
        ["left_box"]  = 32,
        ["right_box"] = 34,
        ["info_box"]  = 33,
        ["dialogue"]  = 64
    }

    -- MAINMENU
    self.menu_options = {
        {"Buy",  "BUYMENU"},
        {"Sell", "SELLMENU"},
        {"Talk", "TALKMENU"},
        {"Exit", "LEAVE"}
    }
    self.items = {}

    self:registerItem("tensionbit")
    self:registerItem("cell_phone")
    self:registerItem("snowring", 1)
    self:registerItem("amber_card")

    -- STATES: MAINMENU, BUYMENU, SELLMENU, TALKMENU, LEAVE, LEAVING, DIALOGUE
    self.state = "NONE"
    self.state_reason = nil

    self.buy_confirming = false

    self.music = Music()

    self.timer = Timer()
    self:addChild(self.timer)

    self.current_selecting = 1
    -- self.current_selecting will be in use... so let's just add another????????
    self.current_selecting_choice = 1
    -- This'll be a separate variable because it keeps track of
    -- what you selected between main menu options. This can
    -- normally be done with hardcoded position sets, like in
    -- other places, but in the Spamton shop in Deltarune,
    -- SELL is replaced with BUYMORE!!!, and when you exit out
    -- of that menu, it places you on the correct menu option.
    self.main_current_selecting = 1
    -- Same here too...
    self.sell_current_selecting = 1

    self.post_dialogue_func = nil
    self.post_dialogue_state = "NONE"

    self.dialogue_table = nil
    self.dialogue_index = 1

    self.font = Assets.getFont("main")
    self.plain_font = Assets.getFont("plain")
    self.heart_sprite = Assets.getTexture("player/heart")

    self.stat_icons = {
        ["attack"   ] = Assets.getTexture("ui/shop/icon_attack"   ),
        ["magic"    ] = Assets.getTexture("ui/shop/icon_magic"    ),
        ["defense_1"] = Assets.getTexture("ui/shop/icon_defense_1"),
        ["defense_2"] = Assets.getTexture("ui/shop/icon_defense_2"),
    }

    self.fade_alpha = 0
    self.fading_out = false
    self.box_ease_timer = 0
    self.box_ease_beginning = -8
    self.box_ease_top = 220 - 48
    self.box_ease_method = "outExpo"
    self.box_ease_multiplier = 1
end

function Shop:postInit()
    -- Construct the UI
    self.large_box = DarkBox()
    local left, top = self.large_box:getBorder()
    self.large_box:setOrigin(0, 1)
    self.large_box.x = (left * 2)
    self.large_box.y = SCREEN_HEIGHT - (top * 2) + 1
    self.large_box.width = SCREEN_WIDTH - (top * 4) + 1
    self.large_box.height = 213 - 37 + 1
    self.large_box:setLayer(self.layers["large_box"])

    self.large_box.visible = false

    self:addChild(self.large_box)

    self.left_box = DarkBox()
    local left, top = self.left_box:getBorder()
    self.left_box:setOrigin(0, 1)
    self.left_box.x = (left * 2)
    self.left_box.y = SCREEN_HEIGHT - (top * 2) + 1
    self.left_box.width = 338 + 14
    self.left_box.height = 213 - 37 + 1
    self.left_box:setLayer(self.layers["left_box"])

    self:addChild(self.left_box)

    self.right_box = DarkBox()
    local left, top = self.right_box:getBorder()
    self.right_box:setOrigin(1, 1)
    self.right_box.x = SCREEN_WIDTH - (left * 2) + 1
    self.right_box.y = SCREEN_HEIGHT - (top * 2) + 1
    self.right_box.width = 20 + 156 + 1
    self.right_box.height = 213 - 37 + 1
    self.right_box:setLayer(self.layers["right_box"])

    self:addChild(self.right_box)

    self.info_box = DarkBox()
    local left, top = self.info_box:getBorder()
    local right_left, right_top = self.right_box:getBorder()
    self.info_box:setOrigin(1, 1)
    self.info_box.x = SCREEN_WIDTH - (left * 2) + 1
    -- find a more elegant way to do this...
    self.info_box.y = SCREEN_HEIGHT - (top * 2) - self.right_box.height  - (right_top * 4) + 16 + 1
    self.info_box.width = 20 + 156 + 1
    self.info_box.height = 213 - 37
    self.info_box:setLayer(self.layers["info_box"])

    self.info_box.visible = false

    self:addChild(self.info_box)

    self.dialogue_text = Textbox(30, 53 + 219, SCREEN_WIDTH - 30, SCREEN_HEIGHT - 53, "main_mono", nil, true)
    self.dialogue_text.text.line_offset = 8

    self.dialogue_text:setLayer(self.layers["dialogue"])
    self:addChild(self.dialogue_text)
    self.dialogue_text:setText(self.encounter_text)


    self.right_text = Textbox(30 + 420, 53 + 209, SCREEN_WIDTH - 30, SCREEN_HEIGHT - 53, "main_mono", nil, true)
    self.right_text.text.line_offset = 8

    self.right_text:setLayer(self.layers["dialogue"])
    self:addChild(self.right_text)
    self.right_text:setText("")
end

function Shop:onEnter()
    self:setState("MAINMENU")
end

function Shop:onRemove(parent)
    super:onRemove(self, parent)

    self.music:remove()
end

function Shop:setState(state, reason)
    local old = self.state
    self.state = state
    self.state_reason = reason
    self:onStateChange(old, self.state)
end

function Shop:getState()
    return self.state
end

function Shop:onStateChange(old,new)
    self.buy_confirming = false
    if new == "MAINMENU" then
        self.large_box.visible = false
        self.left_box.visible = true
        self.right_box.visible = true
        self.info_box.visible = false
        self.dialogue_text:setText(self.shop_text)
        self.right_text:setText("")
    elseif new == "BUYMENU" then
        self.dialogue_text:setText("")
        self.right_text:setText(self.buy_menu_text)
        self.large_box.visible = false
        self.left_box.visible = true
        self.right_box.visible = true
        self.info_box.visible = true
        self.info_box.height = -8
        self.box_ease_timer = 0
        self.box_ease_beginning = -8
        self.box_ease_top = 220 - 48
        self.box_ease_method = "outExpo"
        self.box_ease_multiplier = 1
        self.current_selecting = 1
    elseif new == "SELLMENU" then
        self.dialogue_text:setText("")
        self.right_text:setText(self.sell_menu_text)
        self.large_box.visible = false
        self.left_box.visible = true
        self.right_box.visible = true
        self.info_box.visible = false
    elseif new == "TALKMENU" then
        self.dialogue_text:setText("")
        self.right_text:setText("")
        self.large_box.visible = true
        self.left_box.visible = false
        self.right_box.visible = false
        self.info_box.visible = false
        self:onTalk()
    elseif new == "LEAVE" then
        self.right_text:setText("")
        self.large_box.visible = true
        self.left_box.visible = false
        self.right_box.visible = false
        self.info_box.visible = false
        self:onLeave()
    elseif new == "LEAVING" then
        self.right_text:setText("")
        self.large_box.visible = true
        self.left_box.visible = false
        self.right_box.visible = false
        self.info_box.visible = false
        self:leave()
    elseif new == "DIALOGUE" then
        self.right_text:setText("")
        self.large_box.visible = true
        self.left_box.visible = false
        self.right_box.visible = false
        self.info_box.visible = false
    end
end

function Shop:onLeave()
    self:startDialogue(self.leaving_text, "LEAVING")
end

function Shop:leave()
    self.fading_out = true
end

function Shop:leaveImmediate()
    self:remove()
    Game.shop = nil
    Game.state = "OVERWORLD"
    Game.world.transition_fade = 1
    Game.world.state = "TRANSITION_IN"
end

function Shop:onTalk()
    self:startDialogue({
        "* ... What is that?[wait:5] It appears\nyou have a Shadow Crystal.",
        "* ...",
        "* Unfortunately,[wait:5] I believe that\nyou are missing one from your\nprevious adventures.",
        "* ...",
        "* But,[wait:5] are you sure?[wait:5] Are you sure\nyou didn't defeat that\nclown...?",
        "* Perhaps...[wait:5] You just haven't\nremembered that you had yet.",
        "* That's right,[wait:5] as long as you\never defeated that enemy in the\npast...",
        "* Then perhaps,[wait:5] even now,[wait:5] that\nCrystal might turn up somewhere\nclose...[wait:5] Perhaps!"
    })
end

function Shop:startDialogue(text,callback)
    self.dialogue_index = 1
    if type(text) == "table" then
        self.dialogue_table = text
        self.dialogue_text:setText(text[1])
    else
        self.dialogue_table = nil
        self.dialogue_text:setText(text)
    end
    self.post_dialogue_func = nil
    self.post_dialogue_state = "MAINMENU"

    if type(callback) == "function" then
        self.post_dialogue_func = callback
    elseif type(callback) == "string" then
        self.post_dialogue_state = callback
    end

    self:setState("DIALOGUE")

end

function Shop:registerItem(item, amount, flag)
    if type(item) == "string" then
        item = Registry.createItem(item)
    end
    if item then
        if flag then
            amount = Game:getFlag("shop#" .. self.id .. ":" .. flag, amount)
        end
        table.insert(self.items, {item, amount, flag})
        return true
    else
        return false
    end
end

function Shop:update(dt)
    super:update(self, dt)

    self.box_ease_timer = math.min(1, self.box_ease_timer + (dt * self.box_ease_multiplier))

    if self.state == "BUYMENU" then
        self.info_box.height = Utils.ease(self.box_ease_beginning, self.box_ease_top, self.box_ease_timer, self.box_ease_method)
    end

    if self.fading_out then
        self.fade_alpha = self.fade_alpha + (dt * 2)
        if self.fade_alpha >= 1 then
            self:leaveImmediate()
        end
    end
end

function Shop:draw()
    self:drawBackground()

    super:draw(self)

    love.graphics.setFont(self.font)
    if self.state == "MAINMENU" then
        love.graphics.setColor(1, 1, 1, 1)
        for i = 1, #self.menu_options do
            love.graphics.print(self.menu_options[i][1], 480, 220 + (i * 40))
        end
        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.draw(self.heart_sprite, 450, 230 + (self.main_current_selecting * 40))
    elseif self.state == "BUYMENU" then
        -- Item type (item, key, weapon, armor)
        for i = 1, 4 do
            if i > #self.items then
                love.graphics.setColor(COLORS.dkgray)
                love.graphics.print("--------", 60, 220 + (i * 40))
            elseif self.items[i][2] and (self.items[i][2] <= 0) then
                love.graphics.setColor(COLORS.gray)
                love.graphics.print("--SOLD OUT--", 60, 220 + (i * 40))
            else
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.print(self.items[i][1].name, 60, 220 + (i * 40))
                love.graphics.print("$" .. self.items[i][1].price , 60 + 240, 220 + (i * 40))
            end
        end
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("Exit", 60, 220 + (5 * 40))
        love.graphics.setColor(Game:getSoulColor())
        if not self.buy_confirming then
            love.graphics.draw(self.heart_sprite, 30, 230 + (self.current_selecting * 40))
        else
            love.graphics.draw(self.heart_sprite, 30 + 420, 230 + 80 + 10 + (self.current_selecting_choice * 30))
            love.graphics.setColor(1, 1, 1, 1)
            local lines = Utils.split(string.format(self.buy_confirmation_text, self.items[self.current_selecting][1]:getPrice()), "\n")
            for i = 1, #lines do
                love.graphics.print(lines[i], 60 + 400, 420 - 160 + ((i - 1) * 30))
            end
            love.graphics.print("Yes", 60 + 420, 420 - 80)
            love.graphics.print("No",  60 + 420, 420 - 80 + 30)
        end
        love.graphics.setColor(1, 1, 1, 1)

        if (self.current_selecting <= #self.items) then
            local current_item = self.items[self.current_selecting][1]
            local box_left, box_top = self.info_box:getBorder()

            local left = self.info_box.x - self.info_box.width - box_left * 1.5
            local top = self.info_box.y - self.info_box.height - box_top * 1.5
            local width = self.info_box.width + box_left * 2 * 1.5
            local height = self.info_box.height + box_top * 2 * 1.5

            Draw.pushScissor()
            Draw.scissor(left, top, width, height)

            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(current_item:getShopDescription(), left + 32, top + 20)

            if current_item.type == "armor" or current_item.type == "weapon" then
                for i = 1, #Game.party do
                    local offset_x = 0
                    local offset_y = 0
                    -- TODO: more than 3 party member support
                    if i == 1 then
                        offset_x = 0
                        offset_y = 0
                    elseif i == 2 then
                        offset_x = 100
                        offset_y = 0
                    elseif i == 3 then
                        offset_x = 0
                        offset_y = 45
                    end
                    local party_member = Game.party[i]
                    local can_equip = party_member:canEquip(current_item)
                    local head_path = ""

                    love.graphics.setFont(self.plain_font)
                    love.graphics.setColor(1, 1, 1, 1)

                    if can_equip then
                        head_path = Assets.getTexture(party_member.head_icons .. "/head")
                        if current_item.type == "armor" then
                            love.graphics.draw(self.stat_icons["defense_1"], offset_x + 470, offset_y + 127 + top)
                            love.graphics.draw(self.stat_icons["defense_2"], offset_x + 470, offset_y + 147 + top)

                            for j = 1, 2 do
                                self:drawBonuses(party_member, party_member:getArmor(j), current_item, "defense", offset_x + 470 + 21, offset_y + 127 + ((j - 1) * 20) + top)
                            end

                        elseif current_item.type == "weapon" then
                            love.graphics.draw(self.stat_icons["attack"], offset_x + 470, offset_y + 127 + top)
                            love.graphics.draw(self.stat_icons["magic" ], offset_x + 470, offset_y + 147 + top)
                            self:drawBonuses(party_member, party_member:getWeapon(), current_item, "attack", offset_x + 470 + 21, offset_y + 127 + top)
                            self:drawBonuses(party_member, party_member:getWeapon(), current_item, "magic",  offset_x + 470 + 21, offset_y + 147 + top)
                        end
                    else
                        head_path = Assets.getTexture(party_member.head_icons .. "/head_error")
                    end

                    love.graphics.draw(head_path, offset_x + 426, offset_y + 132 + top)
                end
            end

            Draw.popScissor()

            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.setFont(self.plain_font)

            local space = Game.inventory:getFreeSpace(current_item.type)

            if space <= 0 then
                love.graphics.print("NO SPACE", 521, 430)
            else    
                love.graphics.print("Space:" .. space, 521, 430)
            end
        end
    end

    if self.state == "MAINMENU" or
       self.state == "BUYMENU"  or
       self.state == "SELLMENU" or
       self.state == "TALKMENU" then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(self.font)
        love.graphics.print("$" .. Game.gold, 440, 420)
    end

    love.graphics.setColor(0, 0, 0, self.fade_alpha)
    love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
end

function Shop:drawBonuses(party_member, old_item, new_item, stat, x, y)
    local old_stat = 0

    if old_item then
        old_stat = old_item:getStatBonus(stat) or 0
    end

    local amount = (new_item:getStatBonus(stat) or 0) - old_stat
    local amount_string = tostring(amount)
    if amount < 0 then
        love.graphics.setColor(COLORS.aqua)
    elseif amount == 0 then
        love.graphics.setColor(COLORS.white)
    elseif amount > 0 then
        love.graphics.setColor(COLORS.yellow)
        amount_string = "+" .. amount_string
    end
    love.graphics.print(amount_string, x, y)
    love.graphics.setColor(1, 1, 1, 1)
end

function Shop:drawBackground()
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
end

function Shop:keypressed(key)
    if Game.console.is_open then return end

    if Kristal.Config["debug"] then
        if Input.isMenu(key) then
            self:setState("MAINMENU")
        end
    end

    if self.state == "MAINMENU" then
        if Input.isConfirm(key) then
            local selection = self.menu_options[self.main_current_selecting][2]
            if type(selection) == "string" then
                self:setState(selection)
            elseif type(selection) == "function" then
                selection()
            end
        elseif Input.is("up", key) then
            self.main_current_selecting = self.main_current_selecting - 1
            if (self.main_current_selecting <= 0) then
                self.main_current_selecting = #self.menu_options
            end
        elseif Input.is("down", key) then
            self.main_current_selecting = self.main_current_selecting + 1
            if (self.main_current_selecting > #self.menu_options) then
                self.main_current_selecting = 1
            end
        end
    elseif self.state == "BUYMENU" then
        if self.buy_confirming then
            if Input.isConfirm(key) then
                self.buy_confirming = false
                local current_item_data = self.items[self.current_selecting]
                local current_item = current_item_data[1]
                if self.current_selecting_choice == 1 then
                    if current_item:getPrice() > Game.gold then
                        self.right_text:setText(self.buy_too_expensive_text)
                    else
                        -- PURCHASE THE ITEM
                        -- Remove the gold
                        Game.gold = Game.gold - current_item:getPrice()

                        -- Decrement the stock
                        if current_item_data[2] then
                            current_item_data[2] = current_item_data[2] - 1
                            if current_item_data[3] then
                                Game:setFlag("shop#" .. self.id .. ":" .. current_item_data[3], current_item_data[2])
                            end
                        end

                        -- Add the item to the inventory
                        if Game.inventory:addItem(current_item) then
                            -- Visual/auditorial feedback (did I spell that right?)
                            Assets.playSound("snd_locker")
                            self.right_text:setText(self.buy_text)
                        else
                            -- Not enough space, oops
                            self.right_text:setText(self.buy_no_space_text)
                        end
                    end
                elseif self.current_selecting_choice == 2 then
                    self.right_text:setText(self.buy_refuse_text)
                else
                    self.right_text:setText("What????? did\nyou do????")
                end
            elseif Input.isCancel(key) then
                self.buy_confirming = false
                self.right_text:setText(self.buy_refuse_text)
            elseif Input.is("up", key) or Input.is("down", key) then
                if self.current_selecting_choice == 1 then
                    self.current_selecting_choice = 2
                else
                    self.current_selecting_choice = 1
                end
            end
        else
            local old_selecting = self.current_selecting
            if Input.isConfirm(key) then
                if self.current_selecting == math.max(#self.items, 4) + 1 then
                    self:setState("MAINMENU")
                elseif self.items[self.current_selecting] then
                    if self.items[self.current_selecting][2] then
                        if self.items[self.current_selecting][2] <= 0 then
                            return
                        end
                    end
                    self.buy_confirming = true
                    self.current_selecting_choice = 1
                    self.right_text:setText("")
                end
            elseif Input.isCancel(key) then
                self:setState("MAINMENU")
            elseif Input.is("up", key) then
                self.current_selecting = self.current_selecting - 1
                if (self.current_selecting <= 0) then
                    self.current_selecting = math.max(#self.items, 4) + 1
                end
            elseif Input.is("down", key) then
                self.current_selecting = self.current_selecting + 1
                if (self.current_selecting > math.max(#self.items, 4) + 1) then
                    self.current_selecting = 1
                end
            end
            if Input.is("up", key) or Input.is("down", key) then
                if self.current_selecting >= #self.items + 1 then
                    self.box_ease_timer = 0
                    self.box_ease_beginning = self.info_box.height
                    self.box_ease_top = -8
                    self.box_ease_method = "linear"
                    self.box_ease_multiplier = 8
                elseif (old_selecting >= #self.items + 1) and (self.current_selecting <= #self.items) then
                    self.box_ease_timer = 0
                    self.box_ease_beginning = self.info_box.height
                    self.box_ease_top = 220 - 48
                    self.box_ease_method = "outExpo"
                    self.box_ease_multiplier = 1
                end
            end
        end
    elseif self.state == "DIALOGUE" then
        if Input.isConfirm(key) then
            if not self.dialogue_text:isTyping() then
                if self.dialogue_table ~= nil then
                    self.dialogue_index = self.dialogue_index + 1
                    if self.dialogue_index <= #self.dialogue_table then
                        self.dialogue_text:setText(self.dialogue_table[self.dialogue_index])
                        return
                    end
                end
                self.dialogue_text:setText("")
                if self.post_dialogue_func then
                    self:post_dialogue_func()
                else
                    self:setState(self.post_dialogue_state, "DIALOGUE")
                end
            end
        end
    end
end

return Shop