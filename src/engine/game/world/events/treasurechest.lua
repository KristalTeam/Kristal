local TreasureChest, super = Class(Event, "chest")

function TreasureChest:init(x, y, properties)
    super:init(self, x, y)

    properties = properties or {}

    self:setOrigin(0.5, 0.5)
    self:setScale(2)

    self.sprite = Sprite("world/events/treasure_chest")
    self:addChild(self.sprite)

    self:setSize(self.sprite:getSize())
    self:setHitbox(0, 8, 20, 12)

    self.item = properties["item"]
    self.money = properties["money"]

    self.solid = true
end

function TreasureChest:getDebugInformation()
    local info = super:getDebugInformation(self)
    if self.item then
        table.insert(info, "Item: " .. self.item)
    end
    if self.money then
        if not Game:isLight() then
            table.insert(info, "Money: D$ " .. self.money)
        else
            table.insert(info, "Gold: " .. self.money)
        end
    end
    table.insert(info, "Opened: " .. (self:getFlag("opened") and "True" or "False"))
    return info
end

function TreasureChest:onAdd(parent)
    super:onAdd(self, parent)

    if self:getFlag("opened") then
        self.sprite:setFrame(2)
    end
end

function TreasureChest:onInteract(player, dir)
    if self:getFlag("opened") then
        self.world:showText("* (The chest is empty.)")
    else
        Assets.playSound("locker")
        self.sprite:setFrame(2)
        self:setFlag("opened", true)

        local name, success, result_text
        if self.item then
            local item = self.item
            if type(self.item) == "string" then
                item = Registry.createItem(self.item)
            end
            success, result_text = Game.inventory:tryGiveItem(item)
            name = item:getName()
        elseif self.money then
            name = self.money.." Dark Dollars"
            success = true
            result_text = "* ([color:yellow]"..name.."[color:reset] was added to your [color:yellow]MONEY HOLE[color:reset].)"
            Game.money = Game.money + self.money
        end

        if name then
            self.world:showText({
                "* (You opened the treasure\nchest.)[wait:5]\n* (Inside was [color:yellow]"..name.."[color:reset].)",
                result_text
            }, function()
                if not success then
                    self.sprite:setFrame(1)
                    self:setFlag("opened", false)
                end
            end)
        else
            self.world:showText("* (The chest is empty.)")
        end
    end
end

return TreasureChest