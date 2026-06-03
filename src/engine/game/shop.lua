--- The class which all Shops in Kristal use. \
--- Shop files should be located in `scripts/shops`, and will use their filepath relative to this location as an id by default. \
--- Either [`World:shopTransition()`](lua://World.shopTransition) or a [`Transition`](lua://Transition) event with the property `shop` defined can be used to enter shops. 
---
---@class Shop : Object
---@overload fun(...) : Shop
---
--- The label used for currency in this shop.
---
--- Must include a `%d` to indicate where currency amounts should substitute in.
---
--- Defaults to `$%d`.
---@field currency_text             string
---
--- Text shown on the right side when you first enter a shop.
---@field encounter_text            string
--- Text shown on the right side when you return to the main menu of the shop.
---@field shop_text                 string
--- Text shown on the right side when you leave a shop.
---@field leaving_text              string
--- Text shown on the right side when you're in the BUY menu.
---@field buy_menu_text             string
--- Text shown on the right side when you're about to buy something.
---@field buy_confirmation_text     string
--- Text shown on the right side when you refuse to buy something.
---@field buy_refuse_text           string
--- Text shown on the right side when you buy something.
---@field buy_text                  string
--- Text shown on the right side when you buy something and it goes in your storage.
---@field buy_storage_text          string
--- Text shown on the right side when you don't have enough money to buy something.
---@field buy_too_expensive_text    string
--- Text shown on the right side when you don't have enough space to buy something.
---@field buy_no_space_text         string
--- Text shown on the right side when something doesn't have a sell price.
---@field sell_no_price_text        string
--- Text shown on the right side when you're in the SELL menu.
---@field sell_menu_text            string
--- Text shown on the right side when you try to sell an empty spot.
---@field sell_nothing_text         string
--- Text shown on the right side when you're about to sell something.
---@field sell_confirmation_text    string
--- Text shown on the right side when you refuse to sell something.
---@field sell_refuse_text          string
--- Text shown on the right side when you sell something.
---@field sell_text                 string
--- Text shown on the right side when you have nothing in a storage.
---@field sell_no_storage_text      string
--- Text shown on the right side when you have sold all your items in a storage.
---@field sell_everything_text      string
--- Text shown on the right side when you enter the talk menu.
---@field talk_text                 string
---
--- Defines the Text shown when in each of the different SELL submenus. \
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
---@field menu_options              table<[string, ShopState]>
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
---@field background_speed          number      The animation speed of the background texture.
---
---@field shop_music                string      The filepath of the song to play in this shop, relative to `assets/music`
---@field music                     Music       The `Music` instance used to control the shop's music
---
--- A table defining the stat icons used when previewing items in this shop.
---@field stat_icons                { attack: love.Image, magic: love.Image, defense1: love.Image, defense2: love.Image }
---
---@field timer                     Timer
---
---@field state                     ShopState|string    The current [state](lua://ShopState) of the shop, **should only be set using [`Shop:setState()`](lua://Shop.setState).**
---@field state_reason              any                 The current reason for the state of the shop, **should only be set using [`Shop:setState()`](lua://Shop.setState).**
---
--- A table defining what will happen when the player leaves the shop.
--- The keys `map` (target map name), `x` and `y` OR `marker` (target position in map), `facing`, (player facing direction in map), `menu` (return to main menu) can be defined for this table.
---@field leave_options             { x: number, y: number, map: string, marker: string, facing: FacingDirection, menu: boolean }
---
---@field expand_box                boolean     Whether the right side `info_box` should be expanded.
---
---@field private current_selected_item integer The current selected item index in the BUYMENU or SELLING states.
---@field private current_selecting_choice integer The current selected choice index in the BUYCONFIRM or SELLCONFIRM states.
---@field private current_selected_main_option integer The current selected menu option in the MAINMENU state.
---@field private current_selecting_storage integer The current selected item storage index in the SELLMENU state.
---
local Shop, super = Class(Object, "shop")

---@alias ShopState
---| "MAINMENU"    # The state used when the player is in the Main menu.
---| "BUYMENU"     # The state used when the player is in the Buy menu.
---| "BUYCONFIRM"  # The state used when the player is in the Buy menu, confirming their purchase.
---| "SELLMENU"    # The state used when the player is selecting the storage they wish to sell items from.
---| "SELLING"     # The state used after the player has selected a storage and is now choosing items to sell.
---| "SELLCONFIRM" # The state used when the player is in the Sell menu, confirming their sale.
---| "TALKMENU"    # The state used when the player is selecting a topic to talk about in the Talk menu.
---| "DIALOGUE"    # The state used when dialogue is occurring.
---| "LEAVE"       # The state used to initiate leaving the shop.
---| "LEAVING"     # The state used whilst the shop is transitioning out.

--- Runs the moment the player enters the shop. \
--- Most dialogue and behaviour of the shop should be defined here. \
--- This includes (but is not limited to) defining most standard shop text (excluding TALK menu dialogue), 
--- registering items, talk topics, configuring the [`Shopkeeper`](lua://Shop.shopkeeper), and defining the assets to use (i.e. background and music).
function Shop:init()
    super.init(self)

    self.currency_text = "$%d"

    self.encounter_text = "* Encounter text"
    self.shop_text = "* Shop text"
    self.leaving_text = "* Leaving text"
    self.buy_menu_text = "Purchase\ntext"
    self.buy_confirmation_text = "Buy it for\n%s ?"
    self.buy_refuse_text = "Buy\nrefused\ntext"
    self.buy_text = "Buy text"
    self.buy_storage_text = "Storage\nbuy text"
    self.buy_too_expensive_text = "Not\nenough\nmoney."
    self.buy_no_space_text = "You're\ncarrying\ntoo much."
    self.sell_no_price_text = "No\nprice\ntext"
    self.sell_menu_text = "Sell\nmenu\ntext"
    self.sell_nothing_text = "Sell\nnothing\nattempt"
    self.sell_confirmation_text = "Sell it for\n%s ?"
    self.sell_refuse_text = "Sell\nrefuse\ntext"
    self.sell_text = "Sell\ntext"
    self.sell_no_storage_text = "Empty\ninventory\ntext"
    self.sell_everything_text = "Sold\neverything\ntext"
    self.talk_text = "Talk\ntext"

    self.sell_options_text = {}
    self.sell_options_text["items"]   = "Item text"
    self.sell_options_text["weapons"] = "Weapon\ntext"
    self.sell_options_text["armors"]  = "Armor text"
    self.sell_options_text["storage"] = "Storage\ntext"

    self.hide_storage_text = false

    self.menu_options = {
        { "Buy",  "BUYMENU" },
        { "Sell", "SELLMENU" },
        { "Talk", "TALKMENU" },
        { "Exit", "LEAVE" }
    }

    self.items = {}
    self.talks = {}
    self.talk_replacements = {}

    -- SELLMENU
    if Game.inventory.storage_enabled then
        self.sell_options = {
            { "Sell Items", "items" },
            { "Sell Weapons", "weapons" },
            { "Sell Armor", "armors" },
            { "Sell Pocket Items", "storage" }
        }
    else
        self.sell_options = {
            { "Sell Items", "items" },
            { "Sell Weapons", "weapons" },
            { "Sell Armor", "armors" }
        }
    end

    self.background = nil
    self.background_speed = 5 / 30

    self.state = "NONE"
    self.state_reason = nil

    self.shop_music = ""
    self.music = Music()

    self.timer = Timer()
    self:addChild(self.timer)

    self.voice = nil

    self.shopkeeper = Shopkeeper()
    self.shopkeeper:setPosition(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2)
    self.shopkeeper.layer = SHOP_LAYERS["shopkeeper"]
    self:addChild(self.shopkeeper)

    self.bg_cover = Rectangle(0, SCREEN_HEIGHT / 2, SCREEN_WIDTH, SCREEN_HEIGHT)
    self.bg_cover:setColor(0, 0, 0)
    self.bg_cover.layer = SHOP_LAYERS["cover"]
    self:addChild(self.bg_cover)

    self.current_selected_item = 1
    self.current_selecting_choice = 1

    self.current_selected_main_option = 1
    self.current_selecting_storage = 1

    self.item_offset = 0

    self.font = Assets.getFont("main")
    self.plain_font = Assets.getFont("plain")
    self.space_font = Assets.getFont(Game:getConfig("shopSpaceUIFont") or "8bit")
    self.heart_sprite = Assets.getTexture("player/heart")
    self.arrow_sprite = Assets.getTexture("ui/page_arrow_down")
    self.ui_hold_sprite = Assets.getTexture("ui/shop/ui_hold")
    self.ui_storage_sprite = Assets.getTexture("ui/shop/ui_storage")
    self.ui_armor_sprite = Assets.getTexture("ui/shop/ui_armor")
    self.ui_weapon_sprite = Assets.getTexture("ui/shop/ui_weapon")
    self.ui_pocket_sprite = Assets.getTexture("ui/shop/ui_pocket")

    self.stat_icons = {
        ["attack"] = Assets.getTexture("ui/shop/icon_attack"),
        ["magic"] = Assets.getTexture("ui/shop/icon_magic"),
        ["defense_1"] = Assets.getTexture("ui/shop/icon_defense_1"),
        ["defense_2"] = Assets.getTexture("ui/shop/icon_defense_2"),
    }

    self.fade_alpha = 0
    self.fading_out = false
    self.expand_box = false

    self.hide_price = false

    self.leave_options = {}

    self.hide_world = true
    self.hide_main_menu_currency = false
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
        self.background_sprite:play(self.background_speed, true)
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

    self.dialogue_text = DialogueText("", 30, 270, 372, 226, {
        font = self:getFont(),
        actor = self.shopkeeper:getActor(),
        indent_string = self:getIndentString()
    })

    self.dialogue_text:registerCommand("emote", emoteCommand)

    self.dialogue_text:setLayer(SHOP_LAYERS["dialogue"])
    self:addChild(self.dialogue_text)
    self:setDialogueText(self.encounter_text)

    self.right_text = DialogueText("", 30 + 420, 260, 176, 206, {
        font = self:getFont(),
        actor = self.shopkeeper:getActor(),
        indent_string = self:getIndentString()
    })

    self.right_text:registerCommand("emote", emoteCommand)

    self.right_text:setLayer(SHOP_LAYERS["dialogue"])
    self:addChild(self.right_text)
    self:setRightText("")

    self.talk_dialogue = { self.dialogue_text, self.right_text }
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
    local actor = self.shopkeeper:getActor()
    return self.voice or (actor and actor:getVoice())
end

--- Adds the [`voice`](lua://Shop.voice) of the Shop to a set of dialogue texts.
--- @param text string[]|string
--- @return string[]|string
function Shop:getVoicedText(text)
    local voice = self:getVoice()

    if not voice then
        return text
    end

    if type(text) == "table" then
        local voiced_text = {}

        for _, v in ipairs(text) do
            table.insert(voiced_text, "[voice:" .. voice .. "]" .. v)
        end

        return voiced_text
    else
        return "[voice:" .. voice .. "]" .. text
    end
end

---@return string?
function Shop:getFont()
    local actor = self.shopkeeper:getActor()
    if actor then
        return actor:getFont()
    end

    return nil
end

---@return string?
function Shop:getIndentString()
    local actor = self.shopkeeper:getActor()
    if actor then
        return actor:getIndentString()
    end

    return nil
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
---@param state ShopState|string The new state of the shop.
---@param reason? any Additional information that the new state needs, if required:
---- SELLING - The selected entry of the [`sell_options`](lua://Shop.sell_options) table in SELLMENU.
---- TALKMENU - An optional `"DIALOGUE"` string literal to indicate that the user has returned from the `"DIALOGUE"` state.
function Shop:setState(state, reason)
    local old = self.state
    self.state = state
    self.state_reason = reason
    self:onStateChange(old, self.state)
end

---@return ShopState|string
function Shop:getState()
    return self.state
end

--- Shows the info box on the right side of the screen, used in the BUYMENU state.
function Shop:showInfoBox()
    if self.info_box.visible then
        return
    end

    self.info_box.visible = true

    self.info_box.height = -8

    if #self.items > 0 then
        self.expand_box = true
    else
        self.expand_box = false
    end
end

--- Hides the info box on the right side of the screen, used in the BUYMENU state.
function Shop:hideInfoBox()
    self.info_box.visible = false
end

---@param old ShopState|string The previous state.
---@private
function Shop:onMainMenuState(old)
    self.large_box.visible = false
    self.left_box.visible = true
    self.right_box.visible = true

    self:hideInfoBox()

    self.dialogue_text.width = 372
    self:setDialogueText(self.shop_text)
    self:setRightText("")
end

---@param old ShopState|string The previous state.
---@private
function Shop:onBuyMenuState(old)
    self:setDialogueText("")
    self:setRightText(self.buy_menu_text)
    self.large_box.visible = false
    self.left_box.visible = true
    self.right_box.visible = true

    self:showInfoBox()

    if old ~= "BUYCONFIRM" then
        self.current_selected_item = 1
        self:adjustBuyScroll()
    end
end

---@param old ShopState|string The previous state.
---@private
function Shop:onBuyConfirmState(old)
    self:setDialogueText("")
    self:setRightText("")
    self.large_box.visible = false
    self.left_box.visible = true
    self.right_box.visible = true

    self:showInfoBox()
end

---@param old ShopState|string The previous state.
---@private
function Shop:onSellMenuState(old)
    self:setDialogueText("")
    self:setRightText(self.sell_menu_text)
    self.large_box.visible = false
    self.left_box.visible = true
    self.right_box.visible = true
    self:hideInfoBox()
end

---@param old ShopState|string The previous state.
---@private
function Shop:onSellingState(old)
    self:setDialogueText("")
    if self.selected_storage ~= nil then
        if self.sell_options_text[self.selected_storage] then
            self:setRightText(self.sell_options_text[self.selected_storage])
        else
            self:setRightText("Invalid\nmenu\ntext")
        end
    else
        self:setRightText("Invalid\nstate\nreason")
    end
    self.large_box.visible = false
    self.left_box.visible = true
    self.right_box.visible = true

    self:hideInfoBox()

    if old ~= "SELLCONFIRM" then
        self.current_selected_item = 1
        self.item_offset = 0
        self:adjustSellScroll()
    end
end

---@param old ShopState|string The previous state.
---@private
function Shop:onSellConfirmState(old)
    self:setDialogueText("")

    self.large_box.visible = false
    self.left_box.visible = true
    self.right_box.visible = true

    self:hideInfoBox()

    self.current_selecting_choice = 1
    self:setRightText("")
end

---@param old ShopState|string The previous state.
---@private
function Shop:onTalkMenuState(old)
    self:setDialogueText("")
    self:setRightText(self.talk_text)
    self.large_box.visible = false
    self.left_box.visible = true
    self.right_box.visible = true

    self:hideInfoBox()

    if self.state_reason ~= "DIALOGUE" then
        self.current_selected_item = 1
    end

    self:processReplacements()
    self:onTalk()
end

---@param old ShopState|string The previous state.
---@private
function Shop:onLeaveState(old)
    self:setRightText("")
    self.large_box.visible = true
    self.left_box.visible = false
    self.right_box.visible = false
    self:hideInfoBox()
    self:onLeave()
end

---@param old ShopState|string The previous state.
---@private
function Shop:onLeavingState(old)
    self:setRightText("")
    self:setDialogueText("")
    self.large_box.visible = true
    self.left_box.visible = false
    self.right_box.visible = false
    self:hideInfoBox()
    self:leave()
end

---@param old ShopState|string The previous state.
---@private
function Shop:onDialogueState(old)
    self.dialogue_text.width = 598
    self:setRightText("")
    self.large_box.visible = true
    self.left_box.visible = false
    self.right_box.visible = false
    self:hideInfoBox()
end

--- *(Override)*
---@param old ShopState|string
---@param new ShopState|string
function Shop:onStateChange(old, new)
    if new == "MAINMENU" then
        self:onMainMenuState(old)
    elseif new == "BUYMENU" then
        self:onBuyMenuState(old)
    elseif new == "BUYCONFIRM" then
        self:onBuyConfirmState(old)
    elseif new == "SELLMENU" then
        self:onSellMenuState(old)
    elseif new == "SELLING" then
        self:onSellingState(old)
    elseif new == "SELLCONFIRM" then
        self:onSellConfirmState(old)
    elseif new == "TALKMENU" then
        self:onTalkMenuState(old)
    elseif new == "LEAVE" then
        self:onLeaveState(old)
    elseif new == "LEAVING" then
        self:onLeavingState(old)
    elseif new == "DIALOGUE" then
        self:onDialogueState(old)
    end
end

--- *(Override)* Called when the player selects to leave the shop from the main menu, happens at the same time the leaving dialogue begins.
function Shop:onLeave()
    self:startDialogue(self.leaving_text, "LEAVING")
end

--- Leaves the shop with a fade out transition.
function Shop:leave()
    if self:shouldFade() then
        self.fading_out = true
        self.music:fade(0, 20 / 30)
    else
        self:leaveImmediate()
    end
end

--- Leaves the shop instantly, without a transition.
function Shop:leaveImmediate()
    self:remove()
    Game.shop = nil
    Game.state = "OVERWORLD"
    if self:shouldFade() then
        Game.fader.alpha = 1
        Game.fader:fadeIn()
    end
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

function Shop:shouldFade()
    return self.leave_options["fade"] or self:isWorldHidden()
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
function Shop:startDialogue(text, callback)

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
        options["name"]        = options["name"] or item:getName()
        options["description"] = options["description"] or item:getShopDescription()
        options["price"]       = options["price"] or item:getBuyPrice()
        options["bonuses"]     = options["bonuses"] or item:getStatBonuses()
        options["color"]       = options["color"] or { 1, 1, 1, 1 }
        options["flag"]        = options["flag"] or ("stock_" .. tostring(index) .. "_" .. item.id)

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
---@param talk string The name of the topic.
---@param color? Color The color that the topic name will appear as. Defaults to white.
function Shop:registerTalk(talk, color)
    table.insert(self.talks, { talk, { color = color or COLORS.white } })
end

--- Replaces one talk topic with another.
---@param talk string The name of the topic.
---@param index integer The index that will be replaced with this topic.
---@param color? Color The color that the topic name will appear as. Defaults to yellow.
function Shop:replaceTalk(talk, index, color)
    self.talks[index] = { talk, { color = color or COLORS.yellow } }
end

--- Registers a talk topic that will appear in the TALK submenu when specific conditions are met. \
--- By default, the new topic will appear after the current topic at `index` has been chosen once.
---@param talk string The name of the topic.
---@param index integer The index that will be replaced with this topic.
---@param flag? string The name of the flag that will be checked against to determine when the topic should be replaced.
---@param value? any The value the flag should be at for the topic to be replaced.
---@param color? Color The color that the topic name will appear as. Defaults to yellow.
function Shop:registerTalkAfter(talk, index, flag, value, color)
    table.insert(self.talk_replacements, { index, { talk, { flag = flag or ("talk_" .. tostring(index)), value = value, color = color or COLORS.yellow } } })
end

function Shop:processReplacements()
    for i = 1, #self.talks do
        -- Replace talk option if any replacements flag is set
        -- (Replacements registered later have higher priority)
        for j = 1, #self.talk_replacements do
            if self.talk_replacements[j][1] == i then
                local talk_replacement = self.talk_replacements[j][2]
                if self:getFlag(talk_replacement[2].flag) == (talk_replacement[2].value == nil and true or talk_replacement[2].value) then
                    self:replaceTalk(talk_replacement[1], i, talk_replacement[2].color)
                end
            end
        end
    end
end

--- Internal function to adjust the scroll of the buy menu.
---@private
function Shop:adjustBuyScroll()
    local total = #self.items + 1
    local visible = 5

    -- keep selection inside visible area
    self.item_offset = MathUtils.clamp(self.item_offset, self.current_selected_item - visible, self.current_selected_item - 1)

    -- clamp to valid range
    self.item_offset = MathUtils.clamp(self.item_offset, 0, total - visible)

    -- dont scroll at all if we have enough
    if total <= visible then
        self.item_offset = 0
    end
end

--- Internal function to adjust the scroll of the sell menu.
---@private
function Shop:adjustSellScroll()
    if self.current_selected_item - self.item_offset > 5 then
        self.item_offset = self.item_offset + 1
    end

    if self.current_selected_item - self.item_offset < 1 then
        self.item_offset = self.item_offset - 1
    end

    local inventory = Game.inventory:getStorage(self.selected_storage)

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
end

--- Internal function to update the grow/shrink animation of the shop box.
---@internal
function Shop:updateExpandingBox()
    -- Deltarune constricts the shopbox height (minimenuy) from 200 (bottom/smallest) to 20 (top/tallest)
    -- Kristal UIBoxes work differently, so our new constraints are height from -8 (smallest) to 172 (tallest)
    if self.expand_box then
        if self.info_box.height >= 180 - 8 then
            self.info_box.height = 180 - 8
        end
        if self.info_box.height < 180 - 8 then
            self.info_box.height = self.info_box.height + 5 * DTMULT
        end
        if self.info_box.height < 150 - 8 then
            self.info_box.height = self.info_box.height + 5 * DTMULT
        end
        if self.info_box.height < 100 - 8 then
            self.info_box.height = self.info_box.height + 8 * DTMULT
        end
        if self.info_box.height < 50 - 8 then
            self.info_box.height = self.info_box.height + 10 * DTMULT
        end
    else
        if self.info_box.height > -8 then
            self.info_box.height = self.info_box.height - 40 * DTMULT
        end
        if self.info_box.height <= -8 then
            self.info_box.height = -8
        end
    end
end

--- Internal function to move the shopkeeper.
---@param away boolean
---@private
function Shop:slideShopkeeper(away)
    if away then
        local target_x = SCREEN_WIDTH / 2 - 80
        if self.shopkeeper.x > target_x + 60 then
            self.shopkeeper.x = MathUtils.approach(self.shopkeeper.x, target_x, 4 * DTMULT)
        end
        if self.shopkeeper.x > target_x + 40 then
            self.shopkeeper.x = MathUtils.approach(self.shopkeeper.x, target_x, 4 * DTMULT)
        end
        if self.shopkeeper.x > target_x then
            self.shopkeeper.x = MathUtils.approach(self.shopkeeper.x, target_x, 4 * DTMULT)
        end
    else
        local target_x = SCREEN_WIDTH / 2
        if self.shopkeeper.x < target_x - 50 then
            self.shopkeeper.x = MathUtils.approach(self.shopkeeper.x, target_x, 4 * DTMULT)
        end
        if self.shopkeeper.x < target_x - 30 then
            self.shopkeeper.x = MathUtils.approach(self.shopkeeper.x, target_x, 4 * DTMULT)
        end
        if self.shopkeeper.x < target_x then
            self.shopkeeper.x = MathUtils.approach(self.shopkeeper.x, target_x, 4 * DTMULT)
        end
    end
end

--- Internal functin to update the state machine.
---@private
function Shop:updateStates()
    if self.state == "BUYMENU" or self.state == "BUYCONFIRM" then
        self:updateExpandingBox()

        if self.shopkeeper.slide then
            self:slideShopkeeper(true)
        end
    else
        if self.shopkeeper.slide then
            self:slideShopkeeper(false)
        end
    end
end

--- Internal function to update the fade out transition.
---@private
function Shop:updateFade()
    if self.fading_out then
        self.fade_alpha = self.fade_alpha + (DT * 2)
        if self.fade_alpha >= 1 then
            self:leaveImmediate()
        end
    end
end

--- Internal function to update the talk sprites of the shopkeeper.
---@private
function Shop:updateTalkSprites()
    for _, object in ipairs(self.talk_dialogue) do
        if self.shopkeeper.talk_sprite then
            object.talk_sprite = self.shopkeeper.sprite
        else
            object.talk_sprite = nil
        end
    end
end

--- Internal function to process input in the main menu.
---@private
function Shop:processMainMenuInput()
    if Input.pressed("confirm") then
        local selection = self.menu_options[self.current_selected_main_option][2]
        if type(selection) == "string" then
            self:setState(selection)
        elseif type(selection) == "function" then
            selection()
        end
    elseif Input.pressed("up") then
        self.current_selected_main_option = self.current_selected_main_option - 1
        if (self.current_selected_main_option <= 0) then
            self.current_selected_main_option = #self.menu_options
        end
    elseif Input.pressed("down") then
        self.current_selected_main_option = self.current_selected_main_option + 1
        if (self.current_selected_main_option > #self.menu_options) then
            self.current_selected_main_option = 1
        end
    end
end

--- Internal function to process input in the buy menu.
---@private
function Shop:processBuyMenuInput()
    local old_selecting = self.current_selected_item

    if Input.pressed("confirm") then
        if self.current_selected_item == math.max(#self.items, 4) + 1 then
            self:setState("MAINMENU")
        elseif self.items[self.current_selected_item] then
            if self.items[self.current_selected_item].options["stock"] then
                if self.items[self.current_selected_item].options["stock"] <= 0 then
                    return
                end
            end
            self:setState("BUYCONFIRM")
            self.current_selecting_choice = 1
            self:setRightText("")
        end
    elseif Input.pressed("cancel") then
        self:setState("MAINMENU")
    elseif Input.pressed("up") then
        self.current_selected_item = self.current_selected_item - 1
        if (self.current_selected_item <= 0) then
            self.current_selected_item = math.max(#self.items, 4) + 1
        end
        self:adjustBuyScroll()
    elseif Input.pressed("down") then
        self.current_selected_item = self.current_selected_item + 1
        if (self.current_selected_item > math.max(#self.items, 4) + 1) then
            self.current_selected_item = 1
        end
        self:adjustBuyScroll()
    end

    if old_selecting ~= self.current_selected_item then
        if self.current_selected_item >= #self.items + 1 then
            self.expand_box = false
        elseif (old_selecting >= #self.items + 1) and (self.current_selected_item <= #self.items) then
            self.expand_box = true
        end
    end
end

--- Internal function to process input in the buy confirmation menu.
---@private
function Shop:processBuyConfirmInput()
    if Input.pressed("confirm") then
        self:setState("BUYMENU")
        local current_item = self.items[self.current_selected_item]
        if self.current_selecting_choice == 1 then
            self:buyItem(current_item)
        else
            self:setRightText(self.buy_refuse_text)
        end
    elseif Input.pressed("cancel") then
        self:setState("BUYMENU")
        self:setRightText(self.buy_refuse_text)
    elseif Input.pressed("up") or Input.pressed("down") then
        if self.current_selecting_choice == 1 then
            self.current_selecting_choice = 2
        else
            self.current_selecting_choice = 1
        end
    end
end

--- Internal function to process input in the sell menu.
---@private
function Shop:processSellMenuInput()
    if Input.pressed("confirm") then
        if (self.current_selecting_storage <= #self.sell_options) then
            local data = self.sell_options[self.current_selecting_storage]
            self:enterSellMenu(data[2])
        else
            self:setState("MAINMENU")
        end
    elseif Input.pressed("cancel") then
        self:setState("MAINMENU")
    elseif Input.pressed("up") then
        self.current_selecting_storage = self.current_selecting_storage - 1
        if (self.current_selecting_storage <= 0) then
            self.current_selecting_storage = #self.sell_options + 1
        end
    elseif Input.pressed("down") then
        self.current_selecting_storage = self.current_selecting_storage + 1
        if (self.current_selecting_storage > #self.sell_options + 1) then
            self.current_selecting_storage = 1
        end
    end
end

--- Internal function to process input in the selling menu.
---@private
function Shop:processSellingInput()
    local inventory = Game.inventory:getStorage(self.selected_storage)
    if not inventory then
        -- Somehow we don't have an inventory for this, so...
        if Input.pressed("confirm") or Input.pressed("cancel") then
            self:setState("MAINMENU")
        end
        return
    end

    if Input.pressed("confirm") then
        if inventory[self.current_selected_item] then
            if inventory[self.current_selected_item]:isSellable() then
                self:setState("SELLCONFIRM")
            else
                self:setRightText(self.sell_no_price_text)
            end
        else
            self:setRightText(self.sell_nothing_text)
        end
    elseif Input.pressed("cancel") then
        self:setState("SELLMENU")
        self:setRightText(self.sell_menu_text)
    elseif Input.pressed("up", true) then
        self.current_selected_item = self.current_selected_item - 1
        if (self.current_selected_item <= 0) then
            self.current_selected_item = 1
        end
        self:adjustSellScroll()
    elseif Input.pressed("down", true) then
        local max = inventory.max
        if inventory.sorted then
            max = #inventory
        end
        self.current_selected_item = self.current_selected_item + 1
        if (self.current_selected_item > max) then
            self.current_selected_item = max
        end
        self:adjustSellScroll()
    end
end

function Shop:processSellConfirmInput()
    local inventory = Game.inventory:getStorage(self.selected_storage)
    if not inventory then
        return
    end

    if Input.pressed("confirm") then
        local current_item = inventory[self.current_selected_item]
        if self.current_selecting_choice == 1 then
            self:sellItem(current_item)
            if inventory.sorted then
                if self.current_selected_item > #inventory then
                    self.current_selected_item = self.current_selected_item - 1
                    self:adjustSellScroll()
                end
            end
            if self.current_selected_item == 0 or Game.inventory:getItemCount(self.selected_storage, false) == 0 then
                self:setState("SELLMENU")
                self:setRightText(self.sell_everything_text)
            else
                self:setState("SELLING")
                self:setRightText(self.sell_text)
            end
        else
            self:setState("SELLING")
            self:setRightText(self.sell_refuse_text)
        end
    elseif Input.pressed("cancel") then
        self:setState("SELLING")
        self:setRightText(self.sell_refuse_text)
    elseif Input.pressed("up") or Input.pressed("down") then
        if self.current_selecting_choice == 1 then
            self.current_selecting_choice = 2
        else
            self.current_selecting_choice = 1
        end
    end
end

--- Internal function to process input in the talk menu.
---@private
function Shop:processTalkMenuInput()
    if Input.pressed("confirm") then
        if (self.current_selected_item <= #self.talks) then
            local talk = self.talks[self.current_selected_item]
            self:setFlag("talk_" .. self.current_selected_item, true)
            self:startTalk(talk[1])
        elseif self.current_selected_item == math.max(4, #self.talks) + 1 then
            self:setState("MAINMENU")
        end
    elseif Input.pressed("cancel") then
        self:setState("MAINMENU")
    elseif Input.pressed("up") then
        self.current_selected_item = self.current_selected_item - 1
        if (self.current_selected_item <= 0) then
            self.current_selected_item = math.max(4, #self.talks) + 1
        end
    elseif Input.pressed("down") then
        self.current_selected_item = self.current_selected_item + 1
        if (self.current_selected_item > math.max(4, #self.talks) + 1) then
            self.current_selected_item = 1
        end
    end
end

--- Internal function to process input.
---@private
function Shop:processInput()
    if self.state == "MAINMENU" then
        self:processMainMenuInput()
    elseif self.state == "BUYMENU" then
        self:processBuyMenuInput()
    elseif self.state == "BUYCONFIRM" then
        self:processBuyConfirmInput()
    elseif self.state == "SELLMENU" then
        self:processSellMenuInput()
    elseif self.state == "SELLING" then
        self:processSellingInput()
    elseif self.state == "SELLCONFIRM" then
        self:processSellConfirmInput()
    elseif self.state == "TALKMENU" then
        self:processTalkMenuInput()
    end
end

function Shop:update()
    self:processInput()

    self:updateTalkSprites()

    super.update(self)

    self:updateStates()

    self:updateFade()
end

function Shop:drawMainMenu()
    love.graphics.setFont(self.font)
    Draw.setColor(COLORS.white)

    for i = 1, #self.menu_options do
        love.graphics.print(self.menu_options[i][1], 480, 220 + (i * 40))
    end

    Draw.setColor(Game:getSoulColor())
    Draw.draw(self.heart_sprite, 450, 230 + (self.current_selected_main_option * 40))
end

--- The draw function responsible for drawing the items in the buy menu states.
---@param draw_soul boolean Whether to draw the soul cursor next to the currently selected item.
function Shop:drawBuyItems(draw_soul)
    local heart_pos = 30
    local text_pos = 60

    local total_items = #self.items + 1
    local visible_items = 5

    local first_item = 1 + self.item_offset
    local last_item = self.item_offset + visible_items

    local return_index = math.max(last_item, total_items)

    -- Show items
    for i = first_item, last_item do
        local y = 220 + ((i - self.item_offset) * 40)
        local item = self.items[i]

        if i == return_index then
            Draw.setColor(COLORS.white)
            love.graphics.print("Exit", text_pos, y)
        elseif item == nil then
            -- If there's no item there, show empty slot
            Draw.setColor(COLORS.dkgray)
            love.graphics.print("--------", text_pos, y)
        elseif item.options["stock"] and (item.options["stock"] <= 0) then
            -- If we've depleted the stock, show a "sold out" message
            Draw.setColor(COLORS.gray)
            love.graphics.print("--SOLD OUT--", text_pos, y)
        else
            -- Valid item, show it
            Draw.setColor(item.options["color"])
            love.graphics.print(item.options["name"], text_pos, y)
            if not self.hide_price then
                Draw.setColor(COLORS.white)
                love.graphics.print(string.format(self.currency_text, item.options["price"] or 0), 300, y)
            end
        end

        if draw_soul and (i == self.current_selected_item) then
            -- Draw the soul if we're selecting this option
            Draw.setColor(Game:getSoulColor())
            Draw.draw(self.heart_sprite, heart_pos, y + 10)
        end
    end
end

---@param box_y number The y offset of the info box.
---@param item Item The item being previewed.
---@param item_options table The options for the item being previewed.
function Shop:drawPartyBonusInfo(box_y, item, item_options)
    for i = 1, #Game.party do
        -- Turn the index into a 2 wide grid (0-indexed)
        local transformed_x = (i - 1) % 2
        local transformed_y = math.floor((i - 1) / 2)

        -- Transform the grid into coordinates
        local offset_x = transformed_x * 100
        local offset_y = transformed_y * 45

        local party_member = Game.party[i]
        local can_equip = party_member:canEquip(item)
        local head_path

        Draw.setColor(COLORS.white)

        if can_equip then
            head_path = Assets.getTexture(party_member:getHeadIcons() .. "/head")
            if item.type == "armor" then
                Draw.draw(self.stat_icons["defense_1"], offset_x + 470, offset_y + 127 + box_y)
                Draw.draw(self.stat_icons["defense_2"], offset_x + 470, offset_y + 147 + box_y)

                for j = 1, 2 do
                    self:drawBonuses(party_member, party_member:getArmor(j), item_options["bonuses"], "defense", offset_x + 470 + 20, offset_y + 127 + ((j - 1) * 20) + box_y)
                end

            elseif item.type == "weapon" then
                Draw.draw(self.stat_icons["attack"], offset_x + 470, offset_y + 127 + box_y)
                Draw.draw(self.stat_icons["magic"], offset_x + 470, offset_y + 147 + box_y)

                self:drawBonuses(
                    party_member,
                    party_member:getWeapon(),
                    item_options["bonuses"],
                    "attack",
                    offset_x + 470 + 20,
                    offset_y + 127 + box_y
                )

                self:drawBonuses(
                    party_member,
                    party_member:getWeapon(),
                    item_options["bonuses"],
                    "magic",
                    offset_x + 470 + 20,
                    offset_y + 147 + box_y
                )
            end
        else
            head_path = Assets.getTexture(party_member:getHeadIcons() .. "/head_error")
        end

        Draw.draw(head_path, offset_x + 426, offset_y + 132 + box_y)
    end
end

function Shop:drawItemDisplay()
    Draw.setColor(COLORS.white)

    local current_item = self.items[self.current_selected_item]
    if current_item == nil then
        return
    end

    local box_left, box_top = self.info_box:getBorder()

    local left = self.info_box.x - math.floor(self.info_box.width) - (box_left / 2) * 1.5
    local top = self.info_box.y - math.floor(self.info_box.height) - (box_top / 2) * 1.5
    local width = math.floor(self.info_box.width) + box_left * 1.5
    local height = math.floor(self.info_box.height) + box_top * 1.5

    Draw.pushScissor()
    Draw.scissor(left, top, width, height)

    Draw.setColor(COLORS.white)
    love.graphics.print(current_item.options["description"], left + 32, top + 20)

    if current_item.item.type == "armor" or current_item.item.type == "weapon" then
        self:drawPartyBonusInfo(top, current_item.item, current_item.options)
    end

    Draw.popScissor()
end

function Shop:drawOldStorageDisplay()
    local current_item = self.items[self.current_selected_item]

    if current_item == nil then
        return
    end

    local current_storage = Game.inventory:getDefaultStorage(current_item.item)

    Draw.setColor(COLORS.white)
    local space = Game.inventory:getFreeSpace(current_storage)
    love.graphics.setFont(self.plain_font)

    if space <= 0 then
        love.graphics.print("NO SPACE", 520, 430)
    else
        love.graphics.print("Space:" .. space, 520, 430)
    end
end

function Shop:drawStorageDisplay()
    local current_item = self.items[self.current_selected_item]

    if current_item == nil then
        return
    end

    local current_storage = Game.inventory:getDefaultStorage(current_item.item)

    Draw.setColor(COLORS.white)
    local item_type = current_item.item.type

    local space = Game.inventory:getFreeSpace(current_storage, false)
    local space_count = Game.inventory:getItemCount(current_storage, false)
    local total_space = space + space_count

    local storage_space = Game.inventory:getFreeSpace("storage")
    local storage_space_count = Game.inventory:getItemCount("storage")
    local storage_total_space = storage_space + storage_space_count

    local display_x = 545

    love.graphics.setFont(self.space_font)
    if item_type ~= "armor" and item_type ~= "weapon" and item_type ~= "key" then
        Draw.draw(self.ui_hold_sprite, display_x, 398)
        love.graphics.print(string.format("%02d", space_count) .. "/" .. string.format("%02d", total_space), display_x + 1, 412, 0, 0.5, 0.5)
        Draw.draw(self.ui_storage_sprite, display_x, 430)
        love.graphics.print(string.format("%02d", storage_space_count) .. "/" .. string.format("%02d", storage_total_space), display_x + 1, 444, 0, 0.5, 0.5)
    else
        love.graphics.print(string.format("%02d", space_count) .. "/" .. string.format("%02d", total_space), display_x + 1, 436, 0, 0.5, 0.5)
        Draw.draw(self.ui_hold_sprite, display_x, 422)
        if item_type == "armor" then
            Draw.draw(self.ui_armor_sprite, display_x, 410)
        elseif item_type == "weapon" then
            Draw.draw(self.ui_weapon_sprite, display_x, 410)
        elseif item_type == "key" then
            Draw.draw(self.ui_pocket_sprite, display_x, 410)
        end
    end
end

function Shop:drawBuyConfirm()
    Draw.setColor(Game:getSoulColor())
    Draw.draw(self.heart_sprite, 450, 320 + (self.current_selecting_choice * 30))

    Draw.setColor(COLORS.white)

    local lines = StringUtils.split(
        string.format(
            self.buy_confirmation_text,
            string.format(
                self.currency_text,
                self.items[self.current_selected_item].options["price"] or 0
            )
        ),
        "\n"
    )

    for i = 1, #lines do
        love.graphics.print(lines[i], 460, 420 - 160 + ((i - 1) * 30))
    end

    love.graphics.print("Yes", 480, 420 - 80)
    love.graphics.print("No", 480, 420 - 80 + 30)
end

function Shop:drawSellMenu()
    Draw.setColor(Game:getSoulColor())
    Draw.draw(self.heart_sprite, 50, 230 + (self.current_selecting_storage * 40))

    Draw.setColor(COLORS.white)
    love.graphics.setFont(self.font)

    for i, v in ipairs(self.sell_options) do
        love.graphics.print(v[1], 80, 220 + (i * 40))
    end

    love.graphics.print("Return", 80, 220 + ((#self.sell_options + 1) * 40))
end

---@param confirming boolean
function Shop:drawSellItems(confirming)
    local inventory = Game.inventory:getStorage(self.selected_storage)

    if inventory == nil then
        Draw.setColor(COLORS.ltgray)
        love.graphics.print("Invalid storage", 60, 260)
        return
    end

    -- Draw the soul
    Draw.setColor(Game:getSoulColor())
    Draw.draw(self.heart_sprite, 30, 230 + ((self.current_selected_item - self.item_offset) * 40))

    Draw.setColor(COLORS.white)

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

            local tocheck = self.current_selected_item

            if confirming and (Game.chapter <= 2) then
                -- DR bug -- if in the confirming menu, use the wrong variable
                -- TODO: Game.chapter usage!
                tocheck = self.current_selecting_choice
            end

            if i == tocheck then
                love.graphics.rectangle("fill", 372, 292 + draw_location, 9, 9)
            elseif inventory.sorted then
                love.graphics.rectangle("fill", 372 + 3, 292 + 3 + draw_location, 3, 3)
            end
        end

        -- Draw arrows
        if not confirming then
            local sine_off = math.sin((Kristal.getTime() * 30) / 6) * 3
            if self.item_offset + 4 < (max - 1) then
                Draw.draw(self.arrow_sprite, 370, 149 + sine_off + 291)
            end
            if self.item_offset > 0 then
                Draw.draw(self.arrow_sprite, 370, 14 - sine_off + 291 - 25, 0, 1, -1)
            end
        end
    end
end

function Shop:drawSellConfirm()
    local inventory = Game.inventory:getStorage(self.selected_storage)

    if inventory == nil then
        return
    end

    -- Draw the soul
    Draw.setColor(Game:getSoulColor())
    Draw.draw(self.heart_sprite, 30 + 420, 230 + 80 + 10 + (self.current_selecting_choice * 30))

    Draw.setColor(COLORS.white)

    local lines = StringUtils.split(
        string.format(
            self.sell_confirmation_text,
            string.format(
                self.currency_text,
                inventory[self.current_selected_item]:getSellPrice()
            )
        ),
        "\n"
    )

    for i = 1, #lines do
        love.graphics.print(lines[i], 60 + 400, 420 - 160 + ((i - 1) * 30))
    end

    love.graphics.print("Yes", 60 + 420, 420 - 80)
    love.graphics.print("No", 60 + 420, 420 - 80 + 30)
end

function Shop:drawTalkMenu()
    Draw.setColor(Game:getSoulColor())
    Draw.draw(self.heart_sprite, 50, 230 + (self.current_selected_item * 40))
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

function Shop:drawMoney()
    Draw.setColor(COLORS.white)
    love.graphics.setFont(self.font)
    love.graphics.print(string.format(self.currency_text, self:getMoney()), 440, 420)
end

function Shop:draw()
    self:drawBackground()

    super.draw(self)

    love.graphics.setFont(self.font)
    if self.state == "MAINMENU" then
        self:drawMainMenu()
        if not self:shouldHideMainMenuCurrency() then
            self:drawMoney()
        end
    elseif self.state == "BUYMENU" then
        self:drawBuyItems(true)
        self:drawItemDisplay()

        if not self.hide_storage_text then
            if Game:getConfig("newShopSpaceUI") then
                self:drawStorageDisplay()
            else
                self:drawOldStorageDisplay()
            end
        end
        self:drawMoney()
    elseif self.state == "BUYCONFIRM" then
        self:drawBuyItems(false)
        self:drawBuyConfirm()
        self:drawItemDisplay()

        if not self.hide_storage_text then
            if Game:getConfig("newShopSpaceUI") then
                self:drawStorageDisplay()
            else
                self:drawOldStorageDisplay()
            end
        end
        self:drawMoney()
    elseif self.state == "SELLMENU" then
        self:drawSellMenu()
        self:drawMoney()
    elseif self.state == "SELLCONFIRM" then
        self:drawSellItems(true)
        self:drawSellConfirm()
        self:drawMoney()
    elseif self.state == "SELLING" then
        self:drawSellItems(false)
        self:drawMoney()
    elseif self.state == "TALKMENU" then
        self:drawTalkMenu()
        self:drawMoney()
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
    love.graphics.setFont(self.plain_font)

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
    if self:isWorldHidden() then
        -- Draw a black backdrop
        Draw.setColor(0, 0, 0, 1)
        love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
    end
end

--- *(Override)* Returns whether the world should be hidden while in the shop.
---@return boolean Whether the world is hidden.
function Shop:isWorldHidden()
    return self.hide_world
end

--- *(Override)* Returns whether the shop should hide the currency while in the MAINMENU state.
---@return boolean Whether to hide the currency in the MAINMENU state.
function Shop:shouldHideMainMenuCurrency()
    return self.hide_main_menu_currency
end

---@param storage string The storage to sell from.
function Shop:enterSellMenu(storage)
    if not storage then
        self:setRightText(self.sell_no_storage_text)
    elseif not Game.inventory:getStorage(storage) then
        self:setRightText(self.sell_no_storage_text)
    elseif Game.inventory:getItemCount(storage, false) == 0 then
        self:setRightText(self.sell_no_storage_text)
    else
        self.selected_storage = storage
        self:setState("SELLING")
    end
end

--- Checks that the player meets the conditions to purchase an item, and then purchases it.
---@param current_item { item: Item, options: table }   The shop entry of the item being purchased.
function Shop:buyItem(current_item)
    if (current_item.options["price"] or 0) > self:getMoney() then
        -- Too expensive!
        self:setRightText(self.buy_too_expensive_text)
    else

        -- Add the item to the inventory
        local new_item = Registry.createItem(current_item.item.id)
        new_item:load(current_item.item:save())
        local main_storage_full = Game.inventory:isFull(Game.inventory:getDefaultStorage(new_item)["id"], false)
        if Game.inventory:addItem(new_item) then
            -- Successfully added the item, so...

            -- Decrement the stock
            if current_item.options["stock"] then
                current_item.options["stock"] = current_item.options["stock"] - 1
                self:setFlag(current_item.options["flag"], current_item.options["stock"])
            end

            -- Remove the money
            self:removeMoney(current_item.options["price"] or 0)

            -- Play the buy sound
            Assets.playSound("locker")

            -- Write the side text
            if main_storage_full then
                self:setRightText(self.buy_storage_text)
            else
                self:setRightText(self.buy_text)
            end
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
    self:addMoney(current_item:getSellPrice())
    Game.inventory:removeItem(current_item)

    Assets.playSound("locker")
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
