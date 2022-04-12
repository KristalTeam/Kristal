local Shop, super = Class(Object, "shop")

function Shop:init()
    super:init(self)

    self.currency_text = "$%d"

    -- Shown when you first enter a shop
    self.encounter_text = "* Encounter text"
    -- Shown when you return to the main menu of the shop
    self.shop_text = "* Shop text"
    -- Shown when you leave a shop
    self.leaving_text = "* Leaving text"
    -- Shown when you're in the BUY menu
    self.buy_menu_text = "Purchase\ntext"
    -- Shown when you're about to buy something.
    self.buy_confirmation_text = "Buy it for\n%s ?"
    -- Shown when you refuse to buy something
    self.buy_refuse_text = "Buy\nrefused\ntext"
    -- Shown when you buy something
    self.buy_text = "Buy text"
    -- Shown when you buy something and it goes in your storage
    self.buy_storage_text = "Storage\nbuy text"
    -- Shown when you don't have enough money to buy something
    self.buy_too_expensive_text = "Not\nenough\nmoney."
    -- Shown when you don't have enough space to buy something.
    self.buy_no_space_text = "You're\ncarrying\ntoo much."
    -- Shown when something doesn't have a price
    self.buy_no_price_text = "No\nprice\ntext"
    -- Shown when you're in the SELL menu
    self.sell_menu_text = "Sell\nmenu\ntext"
    -- Shown when you try to sell an empty spot
    self.sell_nothing_text = "Sell\nnothing\attempt"
    -- Shown when you're about to sell something.
    self.sell_confirmation_text = "Sell it for\n%s ?"
    -- Shown when you refuse to sell something
    self.sell_refuse_text = "Sell\nrefuse\ntext"
    -- Shown when you sell something
    self.sell_text = "Sell\ntext"
    -- Shown when you have nothing in a storage
    self.sell_no_storage_text = "Empty\ninventory\ntext"
    -- Shown when you enter the talk menu.
    self.talk_text = "Talk\ntext"

    self.hide_storage_text = false

    self.layers = {
        ["large_box"] = 16,
        ["left_box"]  = 32,
        ["right_box"] = 34,
        ["info_box"]  = 33,
        ["dialogue"]  = 64
    }

    -- MAINMENU
    self.menu_options = {
        {"Buy",  "BUYMENU" },
        {"Sell", "SELLMENU"},
        {"Talk", "TALKMENU"},
        {"Exit", "LEAVE"   }
    }

    self.items = {}
    self.talks = {}
    self.talk_replacements = {}

    -- SELLMENU
    self.sell_options = {
        {"Sell Items",        "item",   "Item text"   },
        {"Sell Weapons",      "weapon", "Weapon\ntext"},
        {"Sell Armor",        "armor",  "Armor text"  },
        {"Sell Pocket Items", "pocket", "Pocket\ntext"}
    }

    --self:registerItem("tensionbit")
    --self:registerItem("manual")
    --self:registerItem("cell_phone", 1)
    --self:registerItem("snowring", 1)
    --self:registerItem("amber_card")

    --self:registerTalk("Reflect")
    --self:registerTalk("Where I Am")
    --self:registerTalk("Who Am I Talking To")
    --self:registerTalk("What Is Going To Happen")

    --self:registerTalkAfter("Why Am I Here", 2)

    self.background = Assets.getTexture("ui/shop/bg_seam")

    -- STATES: MAINMENU, BUYMENU, SELLMENU, SELLING, TALKMENU, LEAVE, LEAVING, DIALOGUE
    self.state = "NONE"
    self.state_reason = nil

    self.buy_confirming = false
    self.sell_confirming = false

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
    -- Oh my god
    self.item_current_selecting = 1


    self.item_offset = 0

    self.post_dialogue_func = nil
    self.post_dialogue_state = "NONE"

    self.dialogue_table = nil
    self.dialogue_index = 1

    self.font = Assets.getFont("main")
    self.plain_font = Assets.getFont("plain")
    self.heart_sprite = Assets.getTexture("player/heart")
    self.arrow_sprite = Assets.getTexture("ui/page_arrow_down")

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
    -- Mutate talks

    self:processReplacements()

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

function Shop:startTalk(talk)
    if talk == "Where I Am" then
        self:startDialogue({
            "* Where this is isn't important.",
            "* I mean,[wait:5] hey,[wait:5] it might be to some\npeople.",
            "* Not you.",
            "* No,[wait:5] this place is utterly\nworthless for you.[wait:5]\n* Not that I know how you're here,[wait:5]\ntoo.",
            "* Actually,[wait:5] I don't think you're\nhere at all.[wait:5]\n* I'm just talking to myself.",
            "* It's just me.",
            "* Me and my thoughts alone."
        })
    elseif talk == "Why Am I Here" then
        self:startDialogue({
            "* I'm here for one reason.",
            "* I may not know what it is,[wait:5] but I\nknow that it's important.",
            "* Now that I think about it,[wait:5] I really\nknow just about nothing about\nwhat I'm doing.",
            "* So again I ask,[wait:5] why am I here?",
            "* I guess we'll just have to find\nout."
        })
    end
end

function Shop:onEnter()
    self:setState("MAINMENU")
    self.dialogue_text:setText(self.encounter_text)
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
    love.keyboard.setKeyRepeat(false)
    self.buy_confirming = false
    self.sell_confirming = false
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
        if #self.items > 0 then
            self.box_ease_top = 220 - 48
        else
            self.box_ease_top = -8
        end
        self.box_ease_method = "outExpo"
        self.box_ease_multiplier = 1
        self.current_selecting = 1
    elseif new == "SELLMENU" then
        self.dialogue_text:setText("")
        if not self.state_reason then
            self.right_text:setText(self.sell_menu_text)
        end
        self.large_box.visible = false
        self.left_box.visible = true
        self.right_box.visible = true
        self.info_box.visible = false
    elseif new == "SELLING" then
        love.keyboard.setKeyRepeat(true)
        self.dialogue_text:setText("")
        if self.state_reason and type(self.state_reason) == "table" and self.state_reason[3] then
            self.right_text:setText(self.state_reason[3])
        else
            self.right_text:setText("Invalid\nstate\nreason")
        end
        self.large_box.visible = false
        self.left_box.visible = true
        self.right_box.visible = true
        self.info_box.visible = false
        self.item_current_selecting = 1
        self.item_offset = 0
    elseif new == "TALKMENU" then
        self.dialogue_text:setText("")
        self.right_text:setText(self.talk_text)
        self.large_box.visible = false
        self.left_box.visible = true
        self.right_box.visible = true
        self.info_box.visible = false
        if self.state_reason ~= "DIALOGUE" then
            self.current_selecting = 1
        end
        self:processReplacements()
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
    Game.fader.alpha = 1
    Game.fader:fadeIn()
end

function Shop:onTalk() end

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
    if self.state == "TALKMENU" then
        self.post_dialogue_state = "TALKMENU"
    end

    if type(callback) == "function" then
        self.post_dialogue_func = callback
    elseif type(callback) == "string" then
        self.post_dialogue_state = callback
    end

    self:setState("DIALOGUE")

end

function Shop:registerItem(item, amount, flag)
    return self:replaceItem(item, #self.items + 1, amount, flag)
end

function Shop:replaceItem(item, index, amount, flag)
    if type(item) == "string" then
        item = Registry.createItem(item)
    end
    if item then
        if flag then
            amount = self:getFlag(flag, amount)
        end
        self.items[index] = {item, amount, flag}
        return true
    else
        return false
    end
end

function Shop:registerTalk(talk, color)
    table.insert(self.talks, {talk, {color=color or COLORS.white}})
end

function Shop:replaceTalk(talk, index, color)
    self.talks[index] = {talk, {color=color or COLORS.yellow}}
end

function Shop:registerTalkAfter(talk, index, flag, value, color)
    table.insert(self.talk_replacements, {index, {talk, {flag=flag or ("talk_" .. tostring(index)), value=value, color=color or COLORS.yellow}}})
end

function Shop:processReplacements()
    for i = 1, #self.talks do
        local talk_replacement = nil
        for j = 1, #self.talk_replacements do 
            if self.talk_replacements[j][1] == i then
                talk_replacement = self.talk_replacements[j][2]
                break
            end
        end

        if talk_replacement then
            if self:getFlag(talk_replacement[2].flag, talk_replacement[2].value) then
                self:replaceTalk(talk_replacement[1], i, talk_replacement[2].color)
            end
        end
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
    self:drawBackgroundCover()

    super:draw(self)

    love.graphics.setFont(self.font)
    if self.state == "MAINMENU" then
        love.graphics.setColor(1, 1, 1, 1)
        for i = 1, #self.menu_options do
            love.graphics.print(self.menu_options[i][1], 480, 220 + (i * 40))
        end
        love.graphics.setColor(Game:getSoulColor())
        love.graphics.draw(self.heart_sprite, 450, 230 + (self.main_current_selecting * 40))
    elseif self.state == "BUYMENU" then
        -- Item type (item, key, weapon, armor)
        for i = 1, math.max(4, #self.items) do
            if i > #self.items then
                love.graphics.setColor(COLORS.dkgray)
                love.graphics.print("--------", 60, 220 + (i * 40))
            elseif self.items[i][2] and (self.items[i][2] <= 0) then
                love.graphics.setColor(COLORS.gray)
                love.graphics.print("--SOLD OUT--", 60, 220 + (i * 40))
            else
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.print(self.items[i][1].name, 60, 220 + (i * 40))
                love.graphics.print(string.format(self.currency_text, self.items[i][1]:getBuyPrice() or 0), 60 + 240, 220 + (i * 40))
            end
        end
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("Exit", 60, 220 + ((math.max(4, #self.items) + 1) * 40))
        love.graphics.setColor(Game:getSoulColor())
        if not self.buy_confirming then
            love.graphics.draw(self.heart_sprite, 30, 230 + (self.current_selecting * 40))
        else
            love.graphics.draw(self.heart_sprite, 30 + 420, 230 + 80 + 10 + (self.current_selecting_choice * 30))
            love.graphics.setColor(1, 1, 1, 1)
            local lines = Utils.split(string.format(self.buy_confirmation_text, string.format(self.currency_text, self.items[self.current_selecting][1]:getBuyPrice() or 0)), "\n")
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

            if not self.hide_storage_text then
                love.graphics.setFont(self.plain_font)

                local space = Game.inventory:getFreeSpace(current_item.type)

                if space <= 0 then
                    love.graphics.print("NO SPACE", 521, 430)
                else    
                    love.graphics.print("Space:" .. space, 521, 430)
                end
            end
        end
    elseif self.state == "SELLMENU" then
        love.graphics.setColor(Game:getSoulColor())
        love.graphics.draw(self.heart_sprite, 50, 230 + (self.sell_current_selecting * 40))
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(self.font)
        for i, v in ipairs(self.sell_options) do
            love.graphics.print(v[1], 80, 220 + (i * 40))
        end
        love.graphics.print("Return", 80, 220 + ((#self.sell_options + 1) * 40))
    elseif self.state == "SELLING" then
        if self.item_current_selecting - self.item_offset > 5 then
            self.item_offset = self.item_offset + 1
        end

        if self.item_current_selecting - self.item_offset < 1 then
            self.item_offset = self.item_offset - 1
        end

        local inventory = Game.inventory:getStorage(self.state_reason[2])

        if inventory and inventory.sorted then
            if self.item_offset + 5 > #inventory then
                if #inventory > 5 then
                    self.item_offset = self.item_offset - 1
                end
            end
            if #inventory == 5 then
                self.item_offset = 0
            end
        end

        love.graphics.setColor(Game:getSoulColor())

        love.graphics.draw(self.heart_sprite, 30, 230 + ((self.item_current_selecting - self.item_offset) * 40))
        if self.sell_confirming then
            love.graphics.draw(self.heart_sprite, 30 + 420, 230 + 80 + 10 + (self.current_selecting_choice * 30))
            love.graphics.setColor(1, 1, 1, 1)
            if inventory[self.item_current_selecting]:getSellPrice() then
                local lines = Utils.split(string.format(self.sell_confirmation_text, string.format(self.currency_text, inventory[self.item_current_selecting]:getSellPrice())), "\n")
            end
            for i = 1, #lines do
                love.graphics.print(lines[i], 60 + 400, 420 - 160 + ((i - 1) * 30))
            end
            love.graphics.print("Yes", 60 + 420, 420 - 80)
            love.graphics.print("No",  60 + 420, 420 - 80 + 30)
        end

        love.graphics.setColor(1, 1, 1, 1)

        if inventory then
            for i = 1 + self.item_offset, self.item_offset + math.min(5, inventory.max) do
                local item = inventory[i]
                love.graphics.setFont(self.font)

                if item then
                    love.graphics.setColor(1, 1, 1, 1)
                    love.graphics.print(item:getName(), 60, 220 + ((i - self.item_offset) * 40))
                    if item:getSellPrice() then
                        love.graphics.print(string.format(self.currency_text, item:getSellPrice()), 60 + 240, 220 + ((i - self.item_offset) * 40))
                    end
                else
                    love.graphics.setColor(COLORS.dkgray)
                    love.graphics.print("--------", 60, 220 + ((i - self.item_offset) * 40))
                end
            end

            local max = inventory.max
            if inventory.sorted then
                max = #inventory
            end

            love.graphics.setColor(1, 1, 1, 1)

            if max > 5 then

                for i = 1, max do
                    local percentage = (i - 1) / (max - 1)
                    local height = 129
    
                    local draw_location = percentage * height
    
                    local tocheck = self.item_current_selecting
                    if self.sell_confirming then
                        tocheck = self.current_selecting_choice
                    end

                    if i == tocheck then
                        love.graphics.rectangle("fill", 372, 292 + draw_location, 9, 9)
                    elseif inventory.sorted then
                        love.graphics.rectangle("fill", 372 + 3, 292 + 3 + draw_location, 3, 3)
                    end
                end

                -- Draw arrows
                if not self.sell_confirming then
                    local sine_off = math.sin((love.timer.getTime()*30)/6) * 3
                    -- Deltarune hides the arrow one item too early so we'll do that too
                    if self.item_offset + 5 < (max - 1) then
                        love.graphics.draw(self.arrow_sprite, 370, 149 + sine_off + 291)
                    end
                    if self.item_offset > 0 then
                        love.graphics.draw(self.arrow_sprite, 370, 14 - sine_off + 291 - 25, 0, 1, -1)
                    end
                end
            end
        else
            love.graphics.print("Invalid storage", 60, 220 + (1 * 40))
        end
    elseif self.state == "TALKMENU" then
        love.graphics.setColor(Game:getSoulColor())
        love.graphics.draw(self.heart_sprite, 50, 230 + (self.current_selecting * 40))
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(self.font)
        --for i, v in ipairs(self.talks) do
        --    love.graphics.setColor(v[2].color)
        --    love.graphics.print(v[1], 80, 220 + (i * 40))
        --end
        for i = 1, math.max(4, #self.talks) do
            local v = self.talks[i]
            if v then
                love.graphics.setColor(v[2].color)
                love.graphics.print(v[1], 80, 220 + (i * 40))
            else
                love.graphics.setColor(COLORS.dkgray)
                love.graphics.print("--------", 80, 220 + (i * 40))
            end
        end
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("Exit", 80, 220 + ((math.max(4, #self.talks) + 1) * 40))
    end

    if self.state == "MAINMENU" or
       self.state == "BUYMENU"  or
       self.state == "SELLMENU" or
       self.state == "SELLING"  or
       self.state == "TALKMENU" then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(self.font)
        love.graphics.print(string.format(self.currency_text, Game.gold), 440, 420)
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
    -- First, draw a black backdrop
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)

    -- Draw the shop background
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.push()
    love.graphics.scale(2, 2)
    love.graphics.draw(self.background, 0, 0)
    love.graphics.pop()
end

function Shop:drawBackgroundCover()
    -- Draw background cover
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", 0, 240, SCREEN_WIDTH, SCREEN_HEIGHT)
    love.graphics.setColor(1, 1, 1, 1)
end

function Shop:keypressed(key)
    if Game.console.is_open then return end

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
                    self:buyItem(current_item, current_item_data)
                elseif self.current_selecting_choice == 2 then
                    self.right_text:setText(self.buy_refuse_text)
                else
                    self.right_text:setText("What?????[wait:5]\ndid you\ndo????")
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
    elseif self.state == "SELLMENU" then
        if Input.isConfirm(key) then
            if (self.sell_current_selecting <= #self.sell_options) then
                self:enterSellMenu(self.sell_options[self.sell_current_selecting])
            else
                self:setState("MAINMENU")
            end
        elseif Input.isCancel(key) then
            self:setState("MAINMENU")
        elseif Input.is("up", key) then
            self.sell_current_selecting = self.sell_current_selecting - 1
            if (self.sell_current_selecting <= 0) then
                self.sell_current_selecting = #self.sell_options + 1
            end
        elseif Input.is("down", key) then
            self.sell_current_selecting = self.sell_current_selecting + 1
            if (self.sell_current_selecting > #self.sell_options + 1) then
                self.sell_current_selecting = 1
            end
        end
    elseif self.state == "SELLING" then
        local inventory = Game.inventory:getStorage(self.state_reason[2])
        if inventory then
            if self.sell_confirming then
                if Input.isConfirm(key) then
                    self.sell_confirming = false
                    love.keyboard.setKeyRepeat(true)
                    local current_item = inventory[self.item_current_selecting]
                    if self.current_selecting_choice == 1 then
                        self:sellItem(current_item)
                        if inventory.sorted then
                            if self.item_current_selecting > #inventory then
                                self.item_current_selecting = self.item_current_selecting - 1
                            end
                            if self.item_current_selecting == 0 then
                                self:setState("SELLMENU", true)
                            end
                        end
                    elseif self.current_selecting_choice == 2 then
                        self.right_text:setText(self.sell_refuse_text)
                    else
                        self.right_text:setText("What?????[wait:5]\ndid you\ndo????")
                    end
                elseif Input.isCancel(key) then
                    self.sell_confirming = false
                    love.keyboard.setKeyRepeat(true)
                    self.right_text:setText(self.sell_refuse_text)
                elseif Input.is("up", key) or Input.is("down", key) then
                    if self.current_selecting_choice == 1 then
                        self.current_selecting_choice = 2
                    else
                        self.current_selecting_choice = 1
                    end
                end
            else
                if Input.isConfirm(key) then
                    if inventory[self.item_current_selecting] then
                        if inventory[self.item_current_selecting]:getSellPrice() then
                            self.sell_confirming = true
                            love.keyboard.setKeyRepeat(false)
                            self.current_selecting_choice = 1
                            self.right_text:setText("")
                        else
                            self.right_text:setText(self.buy_no_price_text)
                        end
                    else
                        self.right_text:setText(self.sell_nothing_text)
                    end
                elseif Input.isCancel(key) then
                    self:setState("SELLMENU")
                elseif Input.is("up", key) then
                    self.item_current_selecting = self.item_current_selecting - 1
                    if (self.item_current_selecting <= 0) then
                        self.item_current_selecting = 1
                    end
                elseif Input.is("down", key) then
                    local max = inventory.max
                    if inventory.sorted then
                        max = #inventory
                    end
                    self.item_current_selecting = self.item_current_selecting + 1
                    if (self.item_current_selecting > max) then
                        self.item_current_selecting = max
                    end
                end
            end
        else
            if Input.isConfirm(key) or Input.isCancel(key) then
                self:setState("MAINMENU")
            end
        end
    elseif self.state == "TALKMENU" then
        if Input.isConfirm(key) then
            if (self.current_selecting <= #self.talks) then
                local talk = self.talks[self.current_selecting]
                self:setFlag("talk_" .. self.current_selecting, true)
                self:startTalk(talk[1])
            elseif self.current_selecting == math.max(4, #self.talks) + 1 then
                self:setState("MAINMENU")
            end
        elseif Input.isCancel(key) then
            self:setState("MAINMENU")
        elseif Input.is("up", key) then
            self.current_selecting = self.current_selecting - 1
            if (self.current_selecting <= 0) then
                self.current_selecting = math.max(4, #self.talks) + 1
            end
        elseif Input.is("down", key) then
            self.current_selecting = self.current_selecting + 1
            if (self.current_selecting > math.max(4, #self.talks) + 1) then
                self.current_selecting = 1
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

function Shop:enterSellMenu(sell_data)
    if not sell_data then
        self.right_text:setText(self.sell_no_storage_text)
    elseif not Game.inventory:getStorage(sell_data[2]) then
        self.right_text:setText(self.sell_no_storage_text)
    elseif #Game.inventory:getStorage(sell_data[2]) <= 0 then
        self.right_text:setText(self.sell_no_storage_text)
    else
        self:setState("SELLING", sell_data)
    end
end

function Shop:buyItem(current_item, current_item_data)
    if (current_item:getBuyPrice() or 0) > Game.gold then
        self.right_text:setText(self.buy_too_expensive_text)
    else
        -- PURCHASE THE ITEM
        -- Remove the gold
        Game.gold = Game.gold - current_item:getBuyPrice() or 0

        -- Decrement the stock
        if current_item_data[2] then
            current_item_data[2] = current_item_data[2] - 1
            if current_item_data[3] then
                self:setFlag(current_item_data[3], current_item_data[2])
            end
        end

        -- Add the item to the inventory
        if Game.inventory:addItem(current_item:clone()) then
            -- Visual/auditorial feedback (did I spell that right?)
            Assets.playSound("snd_locker")
            self.right_text:setText(self.buy_text)
        else
            -- Not enough space, oops
            self.right_text:setText(self.buy_no_space_text)
        end
    end
end

function Shop:setFlag(name, value)
    Game:setFlag("shop#" .. self.id .. ":" .. name, value)
end

function Shop:getFlag(name)
    return Game:getFlag("shop#" .. self.id .. ":" .. name)
end

function Shop:sellItem(current_item)
    -- SELL THE ITEM
    -- Add the gold
    Game.gold = Game.gold + (current_item:getSellPrice() or 0)
    Game.inventory:removeItemClass(current_item.type, current_item)

    Assets.playSound("snd_locker")
    self.right_text:setText(self.sell_text)
end

return Shop