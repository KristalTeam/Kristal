local MouseHole, super = Class(Shop)

function MouseHole:init()
    super.init(self)
    self.encounter_text = "* Welcome to the Mouse Hole.\n[wait:5]* How can I help ya?"
    self.shop_text = "* Thanks for visiting my little old place."
    self.leaving_text = "* Come back any time!"
    self.buy_menu_text = "Here's\nwhat I got."
    self.buy_confirmation_text = "Buy it for\n%s ?"
    self.buy_refuse_text = "That's too bad."
    self.buy_text = "Pleasure doin business with ya!"
    self.buy_storage_text = "I put that in your storage for ya!"
    self.buy_too_expensive_text = "Not\nenough\nmoney."
    self.buy_no_space_text = "You're\ncarrying\ntoo much."
    self.sell_no_price_text = "Don't think I'd have much use for that."
    self.sell_menu_text = "I'll take that off ya!"
    self.sell_nothing_text = "Nothin' there."
    self.sell_confirmation_text = "Sell it for\n%s ?"
    self.sell_refuse_text = "Maybe next time?"
    -- Shown when you sell something
    self.sell_text = "Pleasure doin business with ya!"
    -- Shown when you have nothing in a storage
    self.sell_no_storage_text = "Nothin' there."
    -- Shown when you enter the talk menu.
    self.talk_text = "Sure, I\ngot time!"

    self.sell_options_text = {}
    self.sell_options_text["items"]   = "Let's see what ya got."
    self.sell_options_text["weapons"] = "Let's see what ya got."
    self.sell_options_text["armors"]  = "Let's see what ya got."
    self.sell_options_text["storage"] = "Let's see what ya got."

    self.background = "shops/mousehole_background"

    self.shopkeeper:setActor("shopkeepers/amelia")
    self.shopkeeper.sprite:setPosition(0, 8)
    self.shopkeeper.slide = true

    self:registerItem("tensionbit")

    self:registerTalk("About Yourself")
    self:registerTalk("About Wall Guardian")

    self:registerTalkAfter("Cheese?", 1)
    self:registerTalkAfter("Picture Frame", 2, "talk_2", 1)
    self:registerTalkAfter("Together", 2, "talk_2", 2)
end

function MouseHole:postInit()
    super.postInit(self)
    self.background_sprite:play(5/30, true)
    self.shopkeeper:setLayer(SHOP_LAYERS["above_boxes"])
end

function MouseHole:startTalk(talk)
    if talk == "About Yourself" then
        self:startDialogue({"[emote:idle]* I don't know where to start...\n[wait:5]* I'm just a shopkeeper here in the ridge.", "[emote:explaining]* I mean, [wait:5]I really like seeing everything that passes through my shop.\n[wait:5]* There's always such interesting things from outsiders!", "[emote:happy]* Plus, sometimes they bring a little bit of cheese as a gift!"})
    elseif talk == "Cheese?" then
        self:startDialogue({"[emote:left]* I, [wait:5]um, [wait:5]really like cheese.\n[wait:5]* It's just the perfect food.", "[emote:explaining]* Wh-[wait:5]no, [wait:5]I'm not addicted, [wait:5]I can stop any time I want, [wait:5]alright?"})
    elseif talk == "About Wall Guardian" then
        self:setFlag("talk_2", 1)
        self:startDialogue({"[emote:left]* Wallie? [wait:5]He's a good friend of mine.\n[wait:5]* He's been here for as long as I can remember, [wait:5]even showed me around when I first got here."})
    elseif talk == "Picture Frame" then
        self:setFlag("talk_2", 2)
        self:startDialogue({"[emote:left]* Oh, [wait:5]ehehe...\n[wait:5]* I keep forgetting I put that there.", "[emote:idle]* Pay no attention to it,[wait:5] it's just..."})
    elseif talk == "Together" then
        self:startDialogue({"[emote:left]* U-us? [wait:5]No, [wait:5]we're not... [wait:5]I-I mean, [wait:5]there's not much goin' for me.", "[emote:happy]* That's all!!"})
    end
end

return MouseHole