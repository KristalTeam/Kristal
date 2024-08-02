--- The class which all Shops in Kristal use. \
--- Shop files should be located in `scripts/shops`, and will use their filepath relative to this location as an id by default. \
--- Either [`World:shopTransition()`](lua://World.shopTransition) or a [`Transition`](lua://Transition) event with the property `shop` defined can be used to enter shops. 
---
---@class Shop : Object
---@overload fun(...) : Shop
---
---@field currency_text             string
---
---@field encounter_text            string
---@field shop_text                 string
---@field leaving_text              string
---@field buy_menu_text             string
---@field buy_confirmation_text     string
---@field buy_refuse_text           string
---@field buy_text                  string
---@field buy_storage_text          string
---@field buy_too_expensive_text    string
---@field buy_no_space_text         string
---@field sell_no_price_text        string
---@field sell_menu_text            string
---@field sell_nothing_text         string
---@field sell_confirmation_text    string
---@field sell_refuse_text          string
---@field sell_text                 string
---@field sell_no_storage_text      string
---@field sell_everything_text      string
---@field talk_text                 string
---
--- Defines the text shown when in each of the different SELL submenus. \
--- The keys `items`, `weapons`, `armors`, and `storage` can be defined for this table.
---@field sell_options_text         { items: string, weapons: string, armors: string, storage: string }
---
--- Whether the shop should hide the text showing your remaining storage text (Defaults to `false`)
---@field hide_storage_text         boolean
---
--- Whether item prices should be hidden (Defaults to `false`)
---@field hide_price                boolean
---
--- A table defining the options that will be displayed when on the main menu of the shop (State `MAINMENU`). \
--- Each entry in this table should be a two string table, defining the name of the option first, \
--- followed by the name of the [state](lua://shopstate) that the stop should enter when the option is selected.
---@field menu_options              table<[string, shopstate]>
---
--- A table defining the options that will be displayed when in the SELL menu of the shop (State `SELLMENU`). \
--- Each entry in this table should be a two string table, defining the name of the option first, \
--- followed by the name of the item storage that should be opened to sell from after.
---@field sell_options              table<[string, string]>
---
---@field items                     table       A table of items that the shop offers. Should be set through [`Shop:registerItem()`](lua://Shop.registerItem)
---@field talks                     table       A table of topics available in the TALK menu. Should be set through [`Shop:registerTalk()`](lua://Shop.registerTalk)
---@field talk_replacements         table       A table of topics that will replace other topics once they have been chosen. Should be set through [`Shop:registerTalkAfter()`](lua://Shop.registerTalkAfter)
---
---@field shopkeeper                Shopkeeper
---
---@field voice                     string      The filepath of the voice sound to use for the shop, relative to `assets/sounds/voice`.
---
---@field background                string      The filepath of the background texture for this shop, relative to `assets/sprites`
---@field background_sprite         Sprite      The Sprite instance used to control the background. Not defined in `Shop:init()`.
---
---@field shop_music                string      The filepath of the song to play in this shop, relative to `assets/music`
---@field music                     Music       The `Music` instance used to control the shop's music
---
--- A table defining the stat icons used when previewing items in this shop.
---@field stat_icons                { attack: love.Image, magic: love.Image, defense1: love.Image, defense2: love.Image }
---
---@field timer                     Timer
---
---@field state                     shopstate|string    The current [state](lua://shopstate) of the shop, **should only be set using [`Shop:setState()`](lua://Shop.setState).**
---@field state_reason              any                 The current reason for the state of the shop, **should only be set using [`Shop:setState()`](lua://Shop.setState).**
---
--- A table defining what will happen when the player leaves the shop.
--- The keys `map` (target map name), `x` and `y` OR `marker` (target position in map), `facing`, (player facing direction in map), `menu` (return to main menu) can be defined for this table.
---@field leave_options             { x: number, y: number, map: string, marker: string, facing: "up"|"right"|"down"|"left", menu: boolean }
---
local Shop, super = Class(Object, "shop")

---@alias shopstate
---| "MAINMENU" # The state used when the player is in the Main menu.
---| "BUYMENU"  # The state used when the player is in the Buy menu.
---| "SELLMENU" # The state used when the player is selecting the storage they wish to sell items from.
---| "SELLING"  # The state used after the player has selected a storage and is now choosing items to sell.
---| "TALKMENU" # The state used when the player is selecting a topic to talk about in the Talk menu.
---| "DIALOGUE" # The state used when dialogue is occurring.
---| "LEAVE"    # The state used to initiate leaving the shop.
---| "LEAVING"  # The state used whilst the shop is transitioning out.

--- Runs the moment the player enters the shop. \
--- Most dialogue and behaviour of the shop should be defined here. \
--- This includes (but is not limited to) defining most standard shop text (excluding TALK menu dialogue), 
--- registering items, talk topics, configuring the [`Shopkeeper`](lua://Shop.shopkeeper), and defining the assets to use (i.e. background and music).
function Shop:init()
    super.init(self)

    -- The label used for currency in this shop \
    -- Must include a `%d` to indicate where currency amounts should substitute in
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
    -- Shown when something doesn't have a sell price
    self.sell_no_price_text = "No\nprice\ntext"
    -- Shown when you're in the SELL menu
    self.sell_menu_text = "Sell\nmenu\ntext"
    -- Shown when you try to sell an empty spot
    self.sell_nothing_text = "Sell\nnothing\nattempt"
    -- Shown when you're about to sell something.
    self.sell_confirmation_text = "Sell it for\n%s ?"
    -- Shown when you refuse to sell something
    self.sell_refuse_text = "Sell\nrefuse\ntext"
    -- Shown when you sell something
    self.sell_text = "Sell\ntext"
    -- Shown when you have nothing in a storage
    self.sell_no_storage_text = "Empty\ninventory\ntext"
    -- Shown when you have sold all your items in a storage
    self.sell_everything_text = "Sold\neverything\ntext"
    -- Shown when you enter the talk menu.
    self.talk_text = "Talk\ntext"

    self.sell_options_text = {}
    self.sell_options_text["items"]   = "Item text"
    self.sell_options_text["weapons"] = "Weapon\ntext"
    self.sell_options_text["armors"]  = "Armor text"
    self.sell_options_text["storage"] = "Storage\ntext"

    self.hide_storage_text = false

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
    if Game.inventory.storage_enabled then
        self.sell_options = {
            {"Sell Items",        "items"},
            {"Sell Weapons",      "weapons"},
            {"Sell Armor",        "armors"},
            {"Sell Pocket Items", "storage"}
        }
    else
        self.sell_options = {
            {"Sell Items",        "items"},
            {"Sell Weapons",      "weapons"},
            {"Sell Armor",        "armors"}
        }
    end

    self.background = "ui/shop/bg_seam"

    self.state = "NONE"
    self.state_reason = nil

    self.buy_confirming = false
    self.sell_confirming = false

    self.shop_music = ""
    self.music = Music()

    self.timer = Timer()
    self:addChild(self.timer)

    self.voice = nil

    self.shopkeeper = Shopkeeper()
    self.shopkeeper:setPosition(SCREEN_WIDTH/2, SCREEN_HEIGHT/2)
    self.shopkeeper.layer = SHOP_LAYERS["shopkeeper"]
    self:addChild(self.shopkeeper)

    self.bg_cover = Rectangle(0, SCREEN_HEIGHT/2, SCREEN_WIDTH, SCREEN_HEIGHT)
    self.bg_cover:setColor(0, 0, 0)
    self.bg_cover.layer = SHOP_LAYERS["cover"]
    self:addChild(self.bg_cover)

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

    self.hide_price = false

    self.leave_options = {}
end

--- A function that runs later than `Shop:init()`, primarily setting up UI elements of the shop. \
--- Code that needs access to variables such as the shop's background Sprite object that would otherwise go in `Shop:init()` should go here.
function Shop:postInit()
    -- Mutate talks

    self:processReplacements()

    -- Make a sprite for the background
    if self.background and self.background ~= "" then
        self.background_sprite = Sprite(self.background, 0, 0)
        self.background_sprite:setScale(2, 2)
        self.background_sprite.layer = SHOP_LAYERS["background"]
        self:addChild(self.background_sprite)
    end

    -- Construct the UI
    self.large_box = UIBox()
    local left, top = self.large_box:getBorder()
    self.large_box:setOrigin(0, 1)
    self.large_box.x = left
    self.large_box.y = SCREEN_HEIGHT - top + 1
    self.large_box.width = SCREEN_WIDTH - (top * 2) + 1
    self.large_box.height = 213 - 37 + 1
    self.large_box:setLayer(SHOP_LAYERS["large_box"])

    self.large_box.visible = false

    self:addChild(self.large_box)

    self.left_box = UIBox()
    local left, top = self.left_box:getBorder()
    self.left_box:setOrigin(0, 1)
    self.left_box.x = left
    self.left_box.y = SCREEN_HEIGHT - top + 1
    self.left_box.width = 338 + 14
    self.left_box.height = 213 - 37 + 1
    self.left_box:setLayer(SHOP_LAYERS["left_box"])

    self:addChild(self.left_box)

    self.right_box = UIBox()
    local left, top = self.right_box:getBorder()
    self.right_box:setOrigin(1, 1)
    self.right_box.x = SCREEN_WIDTH - left + 1
    self.right_box.y = SCREEN_HEIGHT - top + 1
    self.right_box.width = 20 + 156 + 1
    self.right_box.height = 213 - 37 + 1
    self.right_box:setLayer(SHOP_LAYERS["right_box"])

    self:addChild(self.right_box)

    self.info_box = UIBox()
    local left, top = self.info_box:getBorder()
    local right_left, right_top = self.right_box:getBorder()
    self.info_box:setOrigin(1, 1)
    self.info_box.x = SCREEN_WIDTH - left + 1
    -- find a more elegant way to do this...
    self.info_box.y = SCREEN_HEIGHT - top - self.right_box.height - (right_top * 2) + 16 + 1
    self.info_box.width = 20 + 156 + 1
    self.info_box.height = 213 - 37
    self.info_box:setLayer(SHOP_LAYERS["info_box"])

    self.info_box.visible = false

    self:addChild(self.info_box)

    local emoteCommand = function(text, node)
        self:onEmote(node.arguments[1])
    end

    self.dialogue_text = DialogueText(nil, 30, 270, 372, 226)

    self.dialogue_text:registerCommand("emote", emoteCommand)

    self.dialogue_text:setLayer(SHOP_LAYERS["dialogue"])
    self:addChild(self.dialogue_text)
    self:setDialogueText(self.encounter_text)

    self.right_text = DialogueText("", 30 + 420, 260, 176, 206)

    self.right_text:registerCommand("emote", emoteCommand)

    self.right_text:setLayer(SHOP_LAYERS["dialogue"])
    self:addChild(self.right_text)
    self:setRightText("")

    self.talk_dialogue = {self.dialogue_text, self.right_text}
end

--- *(Override)* Runs every time the player selects a topic in the TALK menu. \ 
--- Call [`Shop:startDialogue()`](lua://Shop.startDialogue) from within this function with text appropriate to the selected topic.
---@param talk string   The name of the Topic that the player selected.
function Shop:startTalk(talk) end

--- *(Override)* Runs when the player enters the shop, after it has been fully initialised.
function Shop:onEnter()
    self:setState("MAINMENU")
    self:setDialogueText(self.encounter_text)
    -- Play music
    if self.shop_music and self.shop_music ~= "" then
        self.music:play(self.shop_music)
    end
end

---*(Override)*
---@param parent Object
function Shop:onRemove(parent)
    super.onRemove(self, parent)

    self.music:remove()
end

---@return string
function Shop:getVoice()
    return self.voice
end

--- Adds the [`voice`](lua://Shop.voice) of the Shop to a set of dialogue texts.
--- @param text string[]|string
--- @return string[]|string
function Shop:getVoicedText(text)
    local voice = self:getVoice()

    if not voice then return text end

    if type(text) == "table" then
        local voiced_text = {}
        for _,v in ipairs(text) do
            table.insert(voiced_text, "[voice:"..voice.."]"..v)
        end
        return voiced_text
    else
        return "[voice:"..voice.."]"..text
    end
end

---@param text string[]|string
---@param no_voice? boolean
function Shop:setDialogueText(text, no_voice)
    self.dialogue_text:setText(no_voice and text or self:getVoicedText(text))
end

---@param text string[]|string
---@param no_voice? boolean
function Shop:setRightText(text, no_voice)
    self.right_text:setText(no_voice and text or self:getVoicedText(text))
end

--- Changes the shop to a new state.
---@param state shopstate   The new state of the shop.
---@param reason? any Additional information that the new state needs, if required:
---- SELLING - The selected entry of the [`sell_options`](lua://Shop.sell_options) table in SELLMENU.
---- TALKMENU - An optional `"DIALOGUE"` string literal to indicate that the user has returned from the `"DIALOGUE"` state.
function Shop:setState(state, reason)
    local old = self.state
    self.state = state
    self.state_reason = reason
    self:onStateChange(old, self.state)
end

---@return string|shopstate
function Shop:getState()
    return self.state
end

--- *(Override)*
---@param old shopstate|string
---@param new shopstate|string
function Shop:onStateChange(old,new)
    Game.key_repeat = false
    self.buy_confirming = false
    self.sell_confirming = false
    if new == "MAINMENU" then
        self.large_box.visible = false
        self.left_box.visible = true
        self.right_box.visible = true
        self.info_box.visible = false
        self.dialogue_text.width = 372
        self:setDialogueText(self.shop_text)
        self:setRightText("")
    elseif new == "BUYMENU" then
        self:setDialogueText("")
        self:setRightText(self.buy_menu_text)
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
        self:setDialogueText("")
        if not self.state_reason then
            self:setRightText(self.sell_menu_text)
        end
        self.large_box.visible = false
        self.left_box.visible = true
        self.right_box.visible = true
        self.info_box.visible = false
    elseif new == "SELLING" then
        Game.key_repeat = true
        self:setDialogueText("")
        if self.state_reason and type(self.state_reason) == "table" then
            if self.sell_options_text[self.state_reason[2]] then
                self:setRightText(self.sell_options_text[self.state_reason[2]])
            else
                self:setRightText("Invalid\nmenu\ntext")
            end
        else
            self:setRightText("Invalid\nstate\nreason")
        end
        self.large_box.visible = false
        self.left_box.visible = true
        self.right_box.visible = true
        self.info_box.visible = false
        self.item_current_selecting = 1
        self.item_offset = 0
    elseif new == "TALKMENU" then
        self:setDialogueText("")
        self:setRightText(self.talk_text)
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
        self:setRightText("")
        self.large_box.visible = true
        self.left_box.visible = false
        self.right_box.visible = false
        self.info_box.visible = false
        self:onLeave()
    elseif new == "LEAVING" then
        self:setRightText("")
        self:setDialogueText("")
        self.large_box.visible = true
        self.left_box.visible = false
        self.right_box.visible = false
        self.info_box.visible = false
        self:leave()
    elseif new == "DIALOGUE" then
        self.dialogue_text.width = 598
        self:setRightText("")
        self.large_box.visible = true
        self.left_box.visible = false
        self.right_box.visible = false
        self.info_box.visible = false
    end
end

--- *(Override)* Called when the player selects to leave the shop from the main menu, happens at the same time the leaving dialogue begins.
function Shop:onLeave()
    self:startDialogue(self.leaving_text, "LEAVING")
end

--- Leaves the shop with a fade out transition.
function Shop:leave()
    self.fading_out = true
    self.music:fade(0, 20/30)
end

--- Leaves the shop instantly, without a transition.
function Shop:leaveImmediate()
    self:remove()
    Game.shop = nil
    Game.state = "OVERWORLD"
    Game.fader.alpha = 1
    Game.fader:fadeIn()
    Game.world:setState("GAMEPLAY")

    --self.transition_target.shop = nil
    --Game.world:transitionImmediate(self.transition_target)
    if self.leave_options["menu"] then
        Game:returnToMenu()
    elseif self.leave_options["x"] then
        Game.world:mapTransition(self.leave_options["map"] or Game.world.map.id, self.leave_options["x"], self.leave_options["y"], self.leave_options["facing"])
    elseif self.leave_options["marker"] then
        Game.world:mapTransition(self.leave_options["map"] or Game.world.map.id, self.leave_options["marker"], self.leave_options["facing"])
    else
        if self.leave_options["facing"] then
            Game.world.player:setFacing(self.leave_options["facing"])
        end
        Game.world.music:resume()
    end
end

--- *(Override)* Called whenever the player enters the TALK submenu.
function Shop:onTalk() end

--- *(Override)* Called whenever the `[emote:...]` text tag is used in Shop dialogue. Sets the sprite of the shopkeeper.
---@param emote string The path to the image to set, or id of the animation to set.
function Shop:onEmote(emote)
    -- Default behaviour: set sprite / animation
    self.shopkeeper:onEmote(emote)
end

--- Starts a dialogue with the shopkeeper, setting the state to `DIALOGUE`. Use this function inside of [`Shop:startTalk(topic)`](lua://Shop.startTalk).
---@param text string[]|string      One or more lines of dialogue, supporting Text Commands. Additionally supports the command `[emote:name]` which will cause the Shopkeeper's sprite to change to the sprite specified by `name` and `onEmote()` to run.
---@param callback? string|fun()    As a function, this argument is called when the dialogue finishes. If it returns `true`, the shop state will not reset when the dialogue finishes. As a string, the shop is set to this state when the dialogue finishes.
function Shop:startDialogue(text,callback)

    local state = "MAINMENU"
    if self.state == "TALKMENU" then
        state = "TALKMENU"
    end

    self:setState("DIALOGUE")
    self:setDialogueText(text)

    self.dialogue_text.advance_callback = (function()
        if type(callback) == "string" then
            state = callback
        elseif type(callback) == "function" then
            if callback() then
                return
            end
        end

        self:setState(state, "DIALOGUE")
    end)
end

--- Adds an item to the shop at the next available index.
---@param item      string|Item An `Item` instance or the id of an item to add to the shop.
---@param options?  table       An optional list of properties that can be defined for this item in the shop, overriding the default values set on the item:
---| "name"         # The name of the item shown in the shop.
---| "description"  # The description of the item shown in the shop
---| "price"        # The price of the item in this shop
---| "bonuses"      # The preview stat bonuses provided by the item (does not affect actual item stat bonuses)
---| "color"        # The color of the item name text
---| "flag"         # The name of a flag used to store the remaining stock of this item. Defaults to `stock_<index>_<item.id>`
---| "stock"        # The default number of stock of this item. Infinite if unspecified.
---@return boolean success Whether the item was successfully added to the shop.
function Shop:registerItem(item, options)
    return self:replaceItem(#self.items + 1, item, options)
end

--- Adds or replaces an item in the shop.
---@param index     integer     The index in the shop which this item should appear at.
---@param item      string|Item An `Item` instance or the id of an item to add to the shop.
---@param options?  table       An optional list of properties that can be defined for this item in the shop, overriding the default values set on the item:
---| "name"         # The name of the item shown in the shop.
---| "description"  # The description of the item shown in the shop
---| "price"        # The price of the item in this shop
---| "bonuses"      # The preview stat bonuses provided by the item (does not affect actual item stat bonuses)
---| "color"        # The color of the item name text
---| "flag"         # The name of a flag used to store the remaining stock of this item. Defaults to `stock_<index>_<item.id>`
---| "stock"        # The default number of stock of this item. Infinite if unspecified.
---@return boolean  success Whether the item was successfully added to the shop.
function Shop:replaceItem(index, item, options)
    if type(item) == "string" then
        item = Registry.createItem(item)
    end
    if item then
        options = options or {}
        options["name"]        = options["name"]        or item:getName()
        options["description"] = options["description"] or item:getShopDescription()
        options["price"]       = options["price"]       or item:getBuyPrice()
        options["bonuses"]     = options["bonuses"]     or item:getStatBonuses()
        options["color"]       = options["color"]       or {1, 1, 1, 1}
        options["flag"]        = options["flag"]        or ("stock_" .. tostring(index) .. "_" .. item.id)

        options["stock"] = self:getFlag(options["flag"], options["stock"])

        self.items[index] = {
            item = item,
            options = options
        }
        return true
    else
        return false
    end
end

--- Registers a talk topic that will appear in the TALK submenu.
---@param talk      string                              The name of the topic.
---@param color?    [number, number, number, number?]   The color that the topic name will appear as. Defaults to white.
function Shop:registerTalk(talk, color)
    table.insert(self.talks, {talk, {color=color or COLORS.white}})
end

--- Replaces one talk topic with another.
---@param talk      string                              The name of the topic.
---@param index     integer                             The index that will be replaced with this topic.
---@param color?    [number, number, number, number?]   The color that the topic name will appear as. Defaults to yellow.
function Shop:replaceTalk(talk, index, color)
    self.talks[index] = {talk, {color=color or COLORS.yellow}}
end

--- Registers a talk topic that will appear in the TALK submenu when specific conditions are met. \
--- By default, the new topic will appear after the current topic at `index` has been chosen once.
---@param talk      string                              The name of the topic.
---@param index     integer                             The index that will be replaced with this topic.
---@param flag?     string                              The name of the flag that will be checked against to determine when the topic should be replaced.
---@param value?    any                                 The value the flag should be at for the topic to be replaced.
---@param color?    [number, number, number, number?]   The color that the topic name will appear as. Defaults to yellow.
function Shop:registerTalkAfter(talk, index, flag, value, color)
    table.insert(self.talk_replacements, {index, {talk, {flag=flag or ("talk_" .. tostring(index)), value=value, color=color or COLORS.yellow}}})
end

function Shop:processReplacements()
    for i = 1, #self.talks do
        -- Replace talk option if any replacements flag is set
        -- (Replacements registered later have higher priority)
        for j = 1, #self.talk_replacements do
            if self.talk_replacements[j][1] == i then
                local talk_replacement = self.talk_replacements[j][2]
                if self:getFlag(talk_replacement[2].flag) == (talk_replacement[2].value or true) then
                    self:replaceTalk(talk_replacement[1], i, talk_replacement[2].color)
                end
            end
        end
    end
end

function Shop:update()
    -- Update talk sprites
    for _,object in ipairs(self.talk_dialogue) do
        if self.shopkeeper.talk_sprite then
            object.talk_sprite = self.shopkeeper.sprite
        else
            object.talk_sprite = nil
        end
    end

    super.update(self)

    self.box_ease_timer = math.min(1, self.box_ease_timer + (DT * self.box_ease_multiplier))

    if self.state == "BUYMENU" then
        self.info_box.height = Utils.ease(self.box_ease_beginning, self.box_ease_top, self.box_ease_timer, self.box_ease_method)

        if self.shopkeeper.slide then
            local target_x = SCREEN_WIDTH/2 - 80
            if self.shopkeeper.x > target_x + 60 then
                self.shopkeeper.x = Utils.approach(self.shopkeeper.x, target_x, 4 * DTMULT)
            end
            if self.shopkeeper.x > target_x + 40 then
                self.shopkeeper.x = Utils.approach(self.shopkeeper.x, target_x, 4 * DTMULT)
            end
            if self.shopkeeper.x > target_x then
                self.shopkeeper.x = Utils.approach(self.shopkeeper.x, target_x, 4 * DTMULT)
            end
        end
    elseif self.shopkeeper.slide then
        local target_x = SCREEN_WIDTH/2
        if self.shopkeeper.x < target_x - 50 then
            self.shopkeeper.x = Utils.approach(self.shopkeeper.x, target_x, 4 * DTMULT)
        end
        if self.shopkeeper.x < target_x - 30 then
            self.shopkeeper.x = Utils.approach(self.shopkeeper.x, target_x, 4 * DTMULT)
        end
        if self.shopkeeper.x < target_x then
            self.shopkeeper.x = Utils.approach(self.shopkeeper.x, target_x, 4 * DTMULT)
        end
    end

    if self.fading_out then
        self.fade_alpha = self.fade_alpha + (DT * 2)
        if self.fade_alpha >= 1 then
            self:leaveImmediate()
        end
    end
end

function Shop:draw()
    self:drawBackground()

    super.draw(self)

    love.graphics.setFont(self.font)
    if self.state == "MAINMENU" then
        Draw.setColor(COLORS.white)
        for i = 1, #self.menu_options do
            love.graphics.print(self.menu_options[i][1], 480, 220 + (i * 40))
        end
        Draw.setColor(Game:getSoulColor())
        Draw.draw(self.heart_sprite, 450, 230 + (self.main_current_selecting * 40))
    elseif self.state == "BUYMENU" then

        while self.current_selecting - self.item_offset > 5 do
            self.item_offset = self.item_offset + 1
        end

        while self.current_selecting - self.item_offset < 1 do
            self.item_offset = self.item_offset - 1
        end

        if self.item_offset + 5 > #self.items + 1 then
            if #self.items + 1 > 5 then
                self.item_offset = self.item_offset - 1
            end
        end

        if #self.items + 1 == 5 then
            self.item_offset = 0
        end

        -- Item type (item, key, weapon, armor)
        for i = 1 + self.item_offset, self.item_offset + math.max(4, math.min(5, #self.items)) do
            if i == math.max(4, #self.items) + 1 then break end
            local y = 220 + ((i - self.item_offset) * 40)
            local item = self.items[i]
            if not item then
                -- If the item is null, add some empty space
                Draw.setColor(COLORS.dkgray)
                love.graphics.print("--------", 60, y)
            elseif item.options["stock"] and (item.options["stock"] <= 0) then
                -- If we've depleted the stock, show a "sold out" message
                Draw.setColor(COLORS.gray)
                love.graphics.print("--SOLD OUT--", 60, y)
            else
                Draw.setColor(item.options["color"])
                love.graphics.print(item.options["name"], 60, y)
                if not self.hide_price then
                    Draw.setColor(COLORS.white)
                    love.graphics.print(string.format(self.currency_text, item.options["price"] or 0), 60 + 240, y)
                end
            end
        end
        Draw.setColor(COLORS.white)
        if self.item_offset == math.max(4, #self.items) - 4 then
            love.graphics.print("Exit", 60, 220 + (math.max(4, #self.items) + 1 - self.item_offset) * 40)
        end
        Draw.setColor(Game:getSoulColor())
        if not self.buy_confirming then
            Draw.draw(self.heart_sprite, 30, 230 + ((self.current_selecting - self.item_offset) * 40))
        else
            Draw.draw(self.heart_sprite, 30 + 420, 230 + 80 + 10 + (self.current_selecting_choice * 30))
            Draw.setColor(COLORS.white)
            local lines = Utils.split(string.format(self.buy_confirmation_text, string.format(self.currency_text, self.items[self.current_selecting].options["price"] or 0)), "\n")
            for i = 1, #lines do
                love.graphics.print(lines[i], 60 + 400, 420 - 160 + ((i - 1) * 30))
            end
            love.graphics.print("Yes", 60 + 420, 420 - 80)
            love.graphics.print("No",  60 + 420, 420 - 80 + 30)
        end
        Draw.setColor(COLORS.white)

        if (self.current_selecting <= #self.items) then
            local current_item = self.items[self.current_selecting]
            local box_left, box_top = self.info_box:getBorder()

            local left = self.info_box.x - self.info_box.width - (box_left / 2) * 1.5
            local top = self.info_box.y - self.info_box.height - (box_top / 2) * 1.5
            local width = self.info_box.width + box_left * 1.5
            local height = self.info_box.height + box_top * 1.5

            Draw.pushScissor()
            Draw.scissor(left, top, width, height)

            Draw.setColor(COLORS.white)
            love.graphics.print(current_item.options["description"], left + 32, top + 20)

            if current_item.item.type == "armor" or current_item.item.type == "weapon" then
                for i = 1, #Game.party do
                    -- Turn the index into a 2 wide grid (0-indexed)
                    local transformed_x = (i - 1) % 2
                    local transformed_y = math.floor((i - 1) / 2)

                    -- Transform the grid into coordinates
                    local offset_x = transformed_x * 100
                    local offset_y = transformed_y * 45

                    local party_member = Game.party[i]
                    local can_equip = party_member:canEquip(current_item.item)
                    local head_path = ""

                    love.graphics.setFont(self.plain_font)
                    Draw.setColor(COLORS.white)

                    if can_equip then
                        head_path = Assets.getTexture(party_member:getHeadIcons() .. "/head")
                        if current_item.item.type == "armor" then
                            Draw.draw(self.stat_icons["defense_1"], offset_x + 470, offset_y + 127 + top)
                            Draw.draw(self.stat_icons["defense_2"], offset_x + 470, offset_y + 147 + top)

                            for j = 1, 2 do
                                self:drawBonuses(party_member, party_member:getArmor(j), current_item.options["bonuses"], "defense", offset_x + 470 + 21, offset_y + 127 + ((j - 1) * 20) + top)
                            end

                        elseif current_item.item.type == "weapon" then
                            Draw.draw(self.stat_icons["attack"], offset_x + 470, offset_y + 127 + top)
                            Draw.draw(self.stat_icons["magic" ], offset_x + 470, offset_y + 147 + top)
                            self:drawBonuses(party_member, party_member:getWeapon(), current_item.options["bonuses"], "attack", offset_x + 470 + 21, offset_y + 127 + top)
                            self:drawBonuses(party_member, party_member:getWeapon(), current_item.options["bonuses"], "magic",  offset_x + 470 + 21, offset_y + 147 + top)
                        end
                    else
                        head_path = Assets.getTexture(party_member:getHeadIcons() .. "/head_error")
                    end

                    Draw.draw(head_path, offset_x + 426, offset_y + 132 + top)
                end
            end

            Draw.popScissor()

            Draw.setColor(COLORS.white)

            if not self.hide_storage_text then
                love.graphics.setFont(self.plain_font)

                local current_storage = Game.inventory:getDefaultStorage(current_item.item)
                local space = Game.inventory:getFreeSpace(current_storage)

                if space <= 0 then
                    love.graphics.print("NO SPACE", 521, 430)
                else
                    love.graphics.print("Space:" .. space, 521, 430)
                end
            end
        end
    elseif self.state == "SELLMENU" then
        Draw.setColor(Game:getSoulColor())
        Draw.draw(self.heart_sprite, 50, 230 + (self.sell_current_selecting * 40))
        Draw.setColor(COLORS.white)
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

        Draw.setColor(Game:getSoulColor())

        Draw.draw(self.heart_sprite, 30, 230 + ((self.item_current_selecting - self.item_offset) * 40))
        if self.sell_confirming then
            Draw.draw(self.heart_sprite, 30 + 420, 230 + 80 + 10 + (self.current_selecting_choice * 30))
            Draw.setColor(COLORS.white)
            local lines = Utils.split(string.format(self.sell_confirmation_text, string.format(self.currency_text, inventory[self.item_current_selecting]:getSellPrice())), "\n")
            for i = 1, #lines do
                love.graphics.print(lines[i], 60 + 400, 420 - 160 + ((i - 1) * 30))
            end
            love.graphics.print("Yes", 60 + 420, 420 - 80)
            love.graphics.print("No",  60 + 420, 420 - 80 + 30)
        end

        Draw.setColor(COLORS.white)

        if inventory then
            for i = 1 + self.item_offset, self.item_offset + math.min(5, inventory.max) do
                local item = inventory[i]
                love.graphics.setFont(self.font)

                if item then
                    Draw.setColor(COLORS.white)
                    love.graphics.print(item:getName(), 60, 220 + ((i - self.item_offset) * 40))
                    if item:isSellable() then
                        love.graphics.print(string.format(self.currency_text, item:getSellPrice()), 60 + 240, 220 + ((i - self.item_offset) * 40))
                    end
                else
                    Draw.setColor(COLORS.dkgray)
                    love.graphics.print("--------", 60, 220 + ((i - self.item_offset) * 40))
                end
            end

            local max = inventory.max
            if inventory.sorted then
                max = #inventory
            end

            Draw.setColor(COLORS.white)

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
                    local sine_off = math.sin((Kristal.getTime()*30)/6) * 3
                    if self.item_offset + 4 < (max - 1) then
                        Draw.draw(self.arrow_sprite, 370, 149 + sine_off + 291)
                    end
                    if self.item_offset > 0 then
                        Draw.draw(self.arrow_sprite, 370, 14 - sine_off + 291 - 25, 0, 1, -1)
                    end
                end
            end
        else
            love.graphics.print("Invalid storage", 60, 220 + (1 * 40))
        end
    elseif self.state == "TALKMENU" then
        Draw.setColor(Game:getSoulColor())
        Draw.draw(self.heart_sprite, 50, 230 + (self.current_selecting * 40))
        Draw.setColor(COLORS.white)
        love.graphics.setFont(self.font)
        for i = 1, math.max(4, #self.talks) do
            local v = self.talks[i]
            if v then
                Draw.setColor(v[2].color)
                love.graphics.print(v[1], 80, 220 + (i * 40))
            else
                Draw.setColor(COLORS.dkgray)
                love.graphics.print("--------", 80, 220 + (i * 40))
            end
        end
        Draw.setColor(COLORS.white)
        love.graphics.print("Exit", 80, 220 + ((math.max(4, #self.talks) + 1) * 40))
    end

    if self.state == "MAINMENU" or
       self.state == "BUYMENU"  or
       self.state == "SELLMENU" or
       self.state == "SELLING"  or
       self.state == "TALKMENU" then
        Draw.setColor(COLORS.white)
        love.graphics.setFont(self.font)
        love.graphics.print(string.format(self.currency_text, self:getMoney()), 440, 420)
    end

    Draw.setColor(0, 0, 0, self.fade_alpha)
    love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
end

--- Used to draw the comparative bonus number for an item stat against a party member's current equipment.
---@param party_member  PartyMember
---@param old_item      Item
---@param bonuses       table
---@param stat          string
---@param x             number
---@param y             number      
function Shop:drawBonuses(party_member, old_item, bonuses, stat, x, y)
    local old_stat = 0

    if old_item then
        old_stat = old_item:getStatBonus(stat) or 0
    end

    local amount = (bonuses[stat] or 0) - old_stat
    local amount_string = tostring(amount)
    if amount < 0 then
        Draw.setColor(COLORS.aqua)
    elseif amount == 0 then
        Draw.setColor(COLORS.white)
    elseif amount > 0 then
        Draw.setColor(COLORS.yellow)
        amount_string = "+" .. amount_string
    end
    love.graphics.print(amount_string, x, y)
    Draw.setColor(COLORS.white)
end

--- *(Override)* Draws a background for the shop.
function Shop:drawBackground()
    -- Draw a black backdrop
    Draw.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
end

---@param key       string
---@param is_repeat boolean
function Shop:onKeyPressed(key, is_repeat)
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
                local current_item = self.items[self.current_selecting]
                if self.current_selecting_choice == 1 then
                    self:buyItem(current_item)
                elseif self.current_selecting_choice == 2 then
                    self:setRightText(self.buy_refuse_text)
                else
                    self:setRightText("What?????[wait:5]\ndid you\ndo????")
                end
            elseif Input.isCancel(key) then
                self.buy_confirming = false
                self:setRightText(self.buy_refuse_text)
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
                    if self.items[self.current_selecting].options["stock"] then
                        if self.items[self.current_selecting].options["stock"] <= 0 then
                            return
                        end
                    end
                    self.buy_confirming = true
                    self.current_selecting_choice = 1
                    self:setRightText("")
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
                    Game.key_repeat = true
                    local current_item = inventory[self.item_current_selecting]
                    if self.current_selecting_choice == 1 then
                        self:sellItem(current_item)
                        if inventory.sorted then
                            if self.item_current_selecting > #inventory then
                                self.item_current_selecting = self.item_current_selecting - 1
                            end
                        end
                        if self.item_current_selecting == 0 or Game.inventory:getItemCount(self.state_reason[2], false) == 0 then
                            self:setRightText(self.sell_everything_text)
                            self:setState("SELLMENU", true)
                        end
                    elseif self.current_selecting_choice == 2 then
                        self:setRightText(self.sell_refuse_text)
                    else
                        self:setRightText("What?????[wait:5]\ndid you\ndo????")
                    end
                elseif Input.isCancel(key) then
                    self.sell_confirming = false
                    Game.key_repeat = true
                    self:setRightText(self.sell_refuse_text)
                elseif Input.is("up", key) or Input.is("down", key) then
                    if self.current_selecting_choice == 1 then
                        self.current_selecting_choice = 2
                    else
                        self.current_selecting_choice = 1
                    end
                end
            else
                if Input.isConfirm(key) and not is_repeat then
                    if inventory[self.item_current_selecting] then
                        if inventory[self.item_current_selecting]:isSellable() then
                            self.sell_confirming = true
                            Game.key_repeat = false
                            self.current_selecting_choice = 1
                            self:setRightText("")
                        else
                            self:setRightText(self.sell_no_price_text)
                        end
                    else
                        self:setRightText(self.sell_nothing_text)
                    end
                elseif Input.isCancel(key) and not is_repeat then
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
    end
end

---@param sell_data [string, string]    An entry in the [sell_options](lua://Shop.sell_options) table reflecting the storage to enter.
function Shop:enterSellMenu(sell_data)
    if not sell_data then
        self:setRightText(self.sell_no_storage_text)
    elseif not Game.inventory:getStorage(sell_data[2]) then
        self:setRightText(self.sell_no_storage_text)
    elseif Game.inventory:getItemCount(sell_data[2], false) == 0 then
        self:setRightText(self.sell_no_storage_text)
    else
        self:setState("SELLING", sell_data)
    end
end

--- Checks that the player meets the conditions to purchase an item, and then purchases it.
---@param current_item { item: Item, options: table }   The shop entry of the item being purchased.
function Shop:buyItem(current_item)
    if (current_item.options["price"] or 0) > self:getMoney() then
        self:setRightText(self.buy_too_expensive_text)
    else
        -- Decrement the stock
        if current_item.options["stock"] then
            current_item.options["stock"] = current_item.options["stock"] - 1
            self:setFlag(current_item.options["flag"], current_item.options["stock"])
        end

        -- Add the item to the inventory
        local new_item = Registry.createItem(current_item.item.id)
        new_item:load(current_item.item:save())
        if Game.inventory:addItem(new_item) then
            -- Visual/auditorial feedback (did I spell that right?)
            Assets.playSound("locker")
            self:setRightText(self.buy_text)
            
            -- PURCHASE THE ITEM
            -- Remove the money
            self:removeMoney(current_item.options["price"] or 0)
        else
            -- Not enough space, oops
            self:setRightText(self.buy_no_space_text)
        end
    end
end

---@param name  string
---@param value any
function Shop:setFlag(name, value)
    Game:setFlag("shop#" .. self.id .. ":" .. name, value)
end

---@param name      string
---@param default?  any
---@return any
function Shop:getFlag(name, default)
    return Game:getFlag("shop#" .. self.id .. ":" .. name, default)
end

---@param current_item Item
function Shop:sellItem(current_item)
    -- SELL THE ITEM
    -- Add the gold
    self:addMoney(current_item:getSellPrice())
    Game.inventory:removeItem(current_item)

    Assets.playSound("locker")
    self:setRightText(self.sell_text)
end

---@return number
function Shop:getMoney()
    return Game.money
end

---@param amount number
function Shop:setMoney(amount)
    Game.money = amount
end

---@param amount number
function Shop:addMoney(amount)
    self:setMoney(self:getMoney() + amount)
end

---@param amount number
function Shop:removeMoney(amount)
    self:setMoney(self:getMoney() - amount)
end

return Shop