local TestShop, super = Class(Shop,  "test")

function TestShop:init()
    super.init(self)

    self:registerItem("cell_phone", {stock = 10, color = {1, 0.8, 1, 1}, price = -14, description = "*\n|_\n(O)    Sell phoe\n|#|\n'-'", name="Pone"})
    self:registerItem("tensionbit")
    self:registerItem("manual")
    self:registerItem("amber_card", {bonuses = {defense = math.huge}})

    self:registerTalk("Example Talk 1")
    self:registerTalk("Example Talk 2")
    self:registerTalk("Example Talk 3")
    self:registerTalk("Example Talk 4")

    self:registerTalkAfter("Example Talk 5", 1)
    self:registerTalkAfter("Example Talk 6", 3)

    --[[self.shopkeeper:setActor("shopkeepers/seam")
    self.shopkeeper.sprite:setPosition(-24, 12)
    self.shopkeeper.slide = true

    self.background = "ui/shop/bg_seam"]]

    self.background = nil
end

function TestShop:startTalk(talk)
    if talk == "Example Talk 1" then
        self:startDialogue({"* Example Talk 1"})
    elseif talk == "Example Talk 2" then
        if not self:getFlag("talk_example2", false) then
            self:setFlag("talk_example2", true)
            self:startDialogue({"* Example Talk 2"})
        else
            self:startDialogue({"* Repeated Example Talk 2"})
        end
    elseif talk == "Example Talk 2" then self:startDialogue({"* Example Talk 2"})
    elseif talk == "Example Talk 3" then self:startDialogue({"* Example Talk 3"})
    elseif talk == "Example Talk 4" then self:startDialogue({"* Example Talk 4"})
    elseif talk == "Example Talk 5" then self:startDialogue({"* Example Talk 5"})
    elseif talk == "Example Talk 6" then self:startDialogue({"* Example Talk 6"})
    end
end

return TestShop