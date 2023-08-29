---@class CyberTrashCan : Event
---@overload fun(...) : CyberTrashCan
local CyberTrashCan, super = Class(Event, "cybertrash")

function CyberTrashCan:init(x, y, properties)
    super.init(self, x, y)

    properties = properties or {}

    self:setOrigin(0.5, 1)
    self:setScale(2)

    self.sprite = Sprite("world/events/cyber_trash")
    self:addChild(self.sprite)

    self:setSize(self.sprite:getSize())
    self:setHitbox(5, 23, 22, 15)

    self.item = properties["item"]
    self.money = properties["money"]

    self.set_flag = properties["setflag"]
    self.set_value = properties["setvalue"]

    self.solid = true
end

function CyberTrashCan:getDebugInfo()
    local info = super.getDebugInfo(self)
    if self.item then
        table.insert(info, "Item: " .. self.item)
    end
    if self.money then
        if not Game:isLight() then
            table.insert(info, "Money: " .. Game:getConfig("darkCurrencyShort") .. " " .. self.money)
        else
            table.insert(info, Game:getConfig("lightCurrency").. ": " .. Game:getConfig("lightCurrencyShort") .. " " .. self.money)
        end
    end
    table.insert(info, "Opened: " .. (self:getFlag("opened") and "True" or "False"))
    return info
end

function CyberTrashCan:onAdd(parent)
    super.onAdd(self, parent)

    if self:getFlag("opened") then
        self.sprite:setFrame(2)
    end
end

function CyberTrashCan:onInteract(player, dir)
    if self:getFlag("opened") then
        self.world:showText({
            "* (You dug through the trash...)",
            "* (And found trash!)",
        })
    else
        Assets.playSound("impact")
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
            name = self.money.." "..Game:getConfig("darkCurrency")
            success = true
            result_text = "* ([color:yellow]"..name.."[color:reset] was added to your [color:yellow]MONEY HOLE[color:reset].)"
            Game.money = Game.money + self.money
        end

        if name then
            if self.item then
                self.world:showText({
                    "* (You dug through the trash...)",
                    "* (And found a "..name.."!)",
                    result_text,
                }, function()
                    if not success then
                        self:setFlag("opened", false)
                    end
                end)
            else
                self.world:showText({
                    "* (You dug through the trash...)",
                    "* (And found $"..self.money.."!)",
                    result_text,
                })
            end
        else
            self.world:showText({
                "* (You dug through the trash...)",
                "* (And found trash!)",
            })
            success = true
        end

        if success and self.set_flag then
            Game:setFlag(self.set_flag, (self.set_value == nil and true) or self.set_value)
        end
    end

    return true
end

return CyberTrashCan