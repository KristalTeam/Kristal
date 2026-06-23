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
    self.background_speed = 5/30

    self.shopkeeper:setActor("shopkeepers/amelia")
    self.shopkeeper.sprite:setPosition(0, 8)
    self.shopkeeper.slide = true

    self:registerItem("tensionbit")

    self:registerTalk("About Yourself")
    self:registerTalk("About Wall Guardian")
    self:registerTalk("Cheese Key")

    self:registerTalkAfter("Cheese?", 1)
    self:registerTalkAfter("Picture Frame", 2, "talk_2", 1)
    self:registerTalkAfter("Together", 2, "talk_2", 2)
end

function MouseHole:postInit()
    super.postInit(self)
    self.shopkeeper:setLayer(SHOP_LAYERS["above_boxes"])
end

function MouseHole:startTalk(talk)
    if talk == "About Yourself" then
        self:startDialogue({
            "[emote:idle]* Oh, there's not much to say about little old me.",
            "[emote:left]* I'm just a humble shopkeeper,[wait:5] is all.\n[wait:5]* Small business passed down through the generations,[wait:5] and I just happen to be the one running it now.",
            "[emote:explaining]* I mean, [wait:5]I really like seeing everything that passes through my shop.\n[wait:5]* There's always interesting things from outsiders!",
            "[emote:happy]* Some of the regulars even bring me a little snack from time to time.\n[wait:5]* It's really nice."
        })
    elseif talk == "Cheese?" then
        self:startDialogue({
            "[emote:idle]* You wanna talk about...[wait:5] cheese?",
            "[emote:left]* I mean, what is there to even say about it?\n[wait:5]* It's,[wait:5] well,[wait:5] just cheese.\n[wait:5]* The perfect food.",
            "[emote:explaining]* Wh-[wait:5]no, [wait:5]I'm not addicted, [wait:5]I can stop any time I want, [wait:5]alright?"
        })
    elseif talk == "About Wall Guardian" then
        self:setFlag("talk_2", 1)
        self:startDialogue({
            "[emote:left]* Wallie? [wait:5]He's a good friend of mine.",
            "* He's been here for...[wait:5] well,[wait:5] as long as I can remember.\n[wait:5]* He even showed me around when I first got here.",
            "[emote:idle]* Saying things like,[wait:5] \"Wall Here. No Wall over There.\"",
            "* He was a lot more helpful than it sounds,[wait:5] believe me."
        })
    elseif talk == "Picture Frame" then
        self:setFlag("talk_2", 2)
        self:startDialogue({
            "[emote:left]* Oh, [wait:5]that...?\n[wait:5]* I keep forgetting I put that there.",
            "[emote:idle]* Pay no attention to it,[wait:5] it's just..."
        })
    elseif talk == "Together" then
        self:startDialogue({
            "[emote:left]* U-us? [wait:5]No, [wait:5]we're not... [wait:5]I-I mean, [wait:5]I don't have much goin' for me.",
            "[emote:happy]* That's all!!"
        })
    elseif talk == "Cheese Key" then
        self:startDialogue({
            "[emote:idle]* Oh,[wait:5] why the shop's locked behind a key?",
            "[emote:left]* Well, [wait:5]we can't have just anyone coming in,[wait:5] cause we've had some nasty visitors in the past.",
            "[emote:idle]* That's why we give trusted customers a key to the shop.",
            "[emote:idle]* The littlest ones can come in without it,[wait:5] though.",
            "[emote:left]* I don't wanna turn anyone away,[wait:5]\nbut it's a system we've had for some time now.",
            "[emote:left]* The fact that you found one,[wait:5] though...",
            "[emote:idle]* Well,[wait:5] the fact you tried so hard to get in,[wait:5] I guess that means you can be trusted.",
            "[emote:happy]* Plus,[wait:5] I wanna see what you've got."
        })
    end
end

return MouseHole
