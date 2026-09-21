--- The settings for a CoinBowl.
---@class CoinBowlSettings
---@field value number The amount of money this coin is worth. Defaults to 5.
---@field accurate_hitbox boolean Whether or not the hitbox of this coinbowl is accurate (top-left 20x20) or the full size (full 40x40). Defaults to true.

--- A CoinBowl is an object which gives the player money when they collide with it, intended for use in climbing areas.
--- 
--- They belong to the Church dark world in Chapter 4, and represent church collection plates. (Meaning, be careful to use it elsewhere...!)
---
--- `CoinBowl` is an [`Event`](lua://Event.init) - naming an object `coinbowl` on an `objects` layer in a map creates this object.
---
---@class CoinBowl : Event
---
---@field value number The amount of money this coin is worth. Defaults to 5.
---@field accurate_hitbox boolean Whether or not the hitbox of this coinbowl is accurate (top-left 20x20) or the full size (full 40x40). Defaults to true.
---@field siner number A value used to animate the coin.
---@field bowl_frame number The current frame of the bowl's animation.
---@field timer Timer
---
---@overload fun(...) : CoinBowl
local CoinBowl, super = Class(Event)

---@param x number?
---@param y number?
---@param settings CoinBowlSettings?
function CoinBowl:init(x, y, settings)
    settings = settings or {}
    super.init(self, x, y, { 40, 40 })

    self.value = settings.value or 5

    local accurate_hitbox = settings.accurate_hitbox
    if accurate_hitbox == nil then
        accurate_hitbox = true
    end

    if accurate_hitbox then
        self:setHitbox(0, 0, 20, 20)
    end

    self.siner = MathUtils.random(999)
    self.bowl_frame = 0

    self.state = "IDLE"

    self.timer = self:addChild(Timer())
end

function CoinBowl:getDebugInfo()
    local info = super.getDebugInfo(self)

    table.insert(info, "Value: " .. tostring(self.value))

    return info
end

--- Plays the coin collection sound.
function CoinBowl:playCoinSound()
    if self.value > 5 then
        Assets.playSound("coin", 0.7, 1.15)
        self.timer:after(2 / 30, function()
            Assets.playSound("coin", 0.4, 1.15 * 0.75)
        end)
    else
        Assets.playSound("coin", 0.7, 1.4)
    end
end

--- Adds the money from this coin bowl to the player's total.
--- 
--- This does no clamping in any way; A negative value can be used to remove money from the player, and it can go below 0.
function CoinBowl:addMoney()
    Game.money = Game.money + self.value
end

--- Plays the bowl spin sounds.
function CoinBowl:playBowlSound()
    local delaytime = 6
    local decay = 0.2
    local volume = 1
    Assets.playSound("leaf_dodge", volume, 1.5)
    for i = 1, 3 do
        self.timer:after((1 + (delaytime * i) + 1 + ((i - 1) * 2)) / 30, function()
            Assets.playSound("leaf_dodge", volume - (i * 0.2), 1.5 - (decay * i))
        end)
    end
end

--- Spin the coin bowl, playing the sound and animation.
function CoinBowl:spinBowl()
    self:playBowlSound()
    self:playBowlAnimation()
end

--- Plays the bowl's spinning animation.
function CoinBowl:playBowlAnimation()
    self.timer:tween(40 / 30, self, { bowl_frame = 15 }, "out-quad")

    self.timer:after(40 / 30, function()
        self.bowl_frame = 15
    end)
end

--- Collects the coin. This plays the sound, adds the money, spins the bowl, and spawns the coin text.
function CoinBowl:collectCoin()
    self:playCoinSound()
    self:addMoney()
    self:spinBowl()

    self.state = "COLLECTED"

    self:spawnCoinText()
end

--- Spawns the text that shows how much money was collected from this coin bowl.
function CoinBowl:spawnCoinText()
    local world_x, world_y = self:getRelativePos(20, 20, Game.world)

    -- Silly DR bug: The $ doesn't exist in the font, so nothing shows up
    local text = Game.world:addChild(Text(string.format("+%s$", self.value), world_x, world_y, {
        font = "goldnumbers",
        auto_size = true
    }))

    text:setOrigin(0.5)
    text:setPhysics({
        speed_y = -4,
        friction = 0.25
    })

    if Game.world.player ~= nil then
        text:setLayer(Game.world.player.layer + 1)
    end

    self.timer:after(1, function()
        text:remove()
    end)
end

function CoinBowl:onCollide(char)
    if char.is_player and self.state == "IDLE" then
        self:collectCoin()
    end
end

function CoinBowl:update()
    super.update(self)

    self.siner = self.siner + DTMULT
end

--- Draws the coin in the bowl.
function CoinBowl:drawCoin()
    local sprite

    if self.value > 5 then
        sprite = Assets.getFramesOrTexture("world/events/coinbowl/gold_coin")
    else
        sprite = Assets.getFramesOrTexture("world/events/coinbowl/silver_coin")
    end

    local texture = sprite[math.floor((self.siner / 4) % #sprite) + 1]

    local texture_x = 20 - (math.floor(texture:getWidth() / 2) * 2)
    local texture_y = 20 - (math.floor(texture:getHeight() / 2) * 2) + math.sin(self.siner / 20) * 4
    Draw.draw(texture, texture_x, texture_y, 0, 2)
end

--- Draws the bowl itself.
function CoinBowl:drawBowl()
    love.graphics.setColor(ColorUtils.mergeColor(COLORS.white, COLORS.gray, self.bowl_frame / 15))

    local sinamt = math.sin(self.siner / 20) * 6 * MathUtils.clamp(1 - (self.bowl_frame / 7), 0, 1)

    local sprite = Assets.getFramesOrTexture("world/events/coinbowl/bowl")
    local texture = sprite[math.floor(self.bowl_frame % #sprite) + 1]
    Draw.draw(texture, 0, -sinamt, 0, 2, 2)

    love.graphics.setColor(COLORS.white)
end

function CoinBowl:draw()
    self:drawBowl()

    if self.state == "IDLE" then
        self:drawCoin()
    end

    super.draw(self)
end

return CoinBowl
