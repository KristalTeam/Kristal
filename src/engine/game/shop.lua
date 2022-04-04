local Shop, super = Class(Object)

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
    -- Shown when you buy something
    self.buy_text = "Thanks for\nthat."
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
    self.sell_no_text = "No?"
    -- Shown when you sell something
    self.sell_yes_text = "That's it\nfor that."

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

    -- STATES: MAINMENU, BUYMENU, SELLMENU, TALKMENU, LEAVE, LEAVING
    self.state = "NONE"
    self.state_reason = nil
    self.music = Music()

    self.timer = Timer()
    self:addChild(self.timer)

    self.current_selecting = 1
    -- This'll be a separate variable because it keeps track of
    -- what you selected between main menu options. This can
    -- normally be done with hardcoded position sets, like in
    -- other places, but in the Spamton shop in Deltarune,
    -- SELL is replaced with BUYMORE!!!, and when you exit out
    -- of that menu, it places you on the correct menu option.
    self.main_current_selecting = 1
    -- Same here too...
    self.sell_current_selecting = 1

    -- Construct the UI
    self.large_box = DarkBox()
    local left, top = self.large_box:getBorder()
    self.large_box:setOrigin(0, 1)
    self.large_box.x = (left * 2)
    self.large_box.y = SCREEN_HEIGHT - (top * 2)
    self.large_box.width = SCREEN_WIDTH - (top * 4)
    self.large_box.height = 213 - 37
    self.large_box:setLayer(self.layers["large_box"])

    self.large_box.visible = false

    self:addChild(self.large_box)

    self.left_box = DarkBox()
    local left, top = self.left_box:getBorder()
    self.left_box:setOrigin(0, 1)
    self.left_box.x = (left * 2)
    self.left_box.y = SCREEN_HEIGHT - (top * 2)
    self.left_box.width = 338 + 14
    self.left_box.height = 213 - 37
    self.left_box:setLayer(self.layers["left_box"])

    self:addChild(self.left_box)

    self.right_box = DarkBox()
    local left, top = self.right_box:getBorder()
    self.right_box:setOrigin(1, 1)
    self.right_box.x = SCREEN_WIDTH - (left * 2)
    self.right_box.y = SCREEN_HEIGHT - (top * 2)
    self.right_box.width = 20 + 156
    self.right_box.height = 213 - 37
    self.right_box:setLayer(self.layers["right_box"])

    self:addChild(self.right_box)

    self.info_box = DarkBox()
    local left, top = self.info_box:getBorder()
    local right_left, right_top = self.right_box:getBorder()
    self.info_box:setOrigin(1, 1)
    self.info_box.x = SCREEN_WIDTH - (left * 2)
    -- find a more elegant way to do this...
    self.info_box.y = SCREEN_HEIGHT - (top * 2) - self.right_box.height  - (right_top * 4) + 16
    self.info_box.width = 20 + 156
    self.info_box.height = 213 - 37
    self.info_box:setLayer(self.layers["info_box"])

    self.info_box.visible = false

    self:addChild(self.info_box)

    self.post_dialogue_func = nil
    self.post_dialogue_state = "NONE"

    self.dialogue_table = nil
    self.dialogue_index = 1

    self.dialogue_text = Textbox(30, 53 + 219, SCREEN_WIDTH - 30, SCREEN_HEIGHT - 53, true)
    self.dialogue_text.text.line_offset = 8

    self.dialogue_text:setLayer(self.layers["dialogue"])
    self:addChild(self.dialogue_text)

    self:setState("MAINMENU")

    self.dialogue_text:setText(self.encounter_text)

    self.font = Assets.getFont("main")
    self.heart_sprite = Assets.getTexture("player/heart")

    self.fade_alpha = 0
    self.fading_out = false
    self.ease_timer = 0
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
    if new == "MAINMENU" then
        self.large_box.visible = false
        self.left_box.visible = true
        self.right_box.visible = true
        self.info_box.visible = false
        self.dialogue_text:setText(self.shop_text)
    elseif new == "BUYMENU" then
        self.dialogue_text:setText("")
        self.large_box.visible = false
        self.left_box.visible = true
        self.right_box.visible = true
        self.info_box.visible = true
        self.info_box.height = -8
        self.ease_timer = 0
    elseif new == "SELLMENU" then
        self.dialogue_text:setText("")
        self.large_box.visible = false
        self.left_box.visible = true
        self.right_box.visible = true
        self.info_box.visible = false
    elseif new == "TALKMENU" then
        self.dialogue_text:setText("")
        self.large_box.visible = true
        self.left_box.visible = false
        self.right_box.visible = false
        self.info_box.visible = false
        self:onTalk()
    elseif new == "LEAVE" then
        self.large_box.visible = true
        self.left_box.visible = false
        self.right_box.visible = false
        self.info_box.visible = false
        self:onLeave()
    elseif new == "LEAVING" then
        self.large_box.visible = true
        self.left_box.visible = false
        self.right_box.visible = false
        self.info_box.visible = false
        self:leave()
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

    if type(callback) =="function" then
        self.post_dialogue_func = callback
    elseif type(callback) =="string" then
        self.post_dialogue_state = callback
    end

    self:setState("DIALOGUE")

end

function Shop:dialogue(text,post_func)
    self.dialogue_index = 1
    if type(text) == "table" then
        self.dialogue_table = text
        self.dialogue_text:setText(text[1])
    else
        self.dialogue_table = nil
        self.dialogue_text:setText(text)
    end
    self.post_dialogue_func = post_func
    self.post_dialogue_state = self:getState()
    self:setState("DIALOGUE")
end

function Shop:update(dt)
    super:update(self, dt)

    self.ease_timer = math.min(1, self.ease_timer + dt)

    if self.state == "BUYMENU" then
        self.info_box.height = Utils.ease(-8, 220 - 48, self.ease_timer, "outExpo")
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
    end

    love.graphics.setColor(0, 0, 0, self.fade_alpha)
    love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
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