--- Savepoints allow the player to SAVE their game. \
--- `Savepoint` is an [`Event`](lua://Event.init) - naming an object `savepoint` on an `objects` layer in a map creates this object. \
--- See this object's Fields for the configurable properties on this object. The location displayed on the savefile is determined by the map's `name` property.
--- 
---@class Savepoint : Interactable
---
---@field marker        string  *[Property `marker`]* The name of the marker that the party should spawn at when a save from here is loaded
---@field simple_menu   boolean *[Property `simple`]* Whether this Savepoint uses the Simple (one slot, no storage/recruits) save menu
---@field text_once     boolean *[Prpoerty `text_once`]* Whether this Savepoint doesn't display its text on repeat interactions (Defaults to `false`)
---@field heals         boolean *[Property `heals`]* Whether this Savepoint heals the party when interacted with (Defaults to `true`)
---
---@field solid         boolean
---
---@field used          boolean
---
---@overload fun(...) : Savepoint
local Savepoint, super = Class(Interactable)

function Savepoint:init(x, y, properties)
    super.init(self, x, y, nil, properties)

    properties = properties or {}

    self.marker = properties["marker"]
    self.simple_menu = properties["simple"]
    self.text_once = properties["text_once"]
    self.heals = properties["heals"] ~= false

    self.solid = true

    self:setOrigin(0.5, 0.5)
    self:setSprite("world/events/savepoint", 1/6)

    self.used = false

    -- The hitbox is ALMOST half the size of the sprite, but not quite.
    -- It's 9 pixels tall, 10 pixels away from the top.
    -- So divide by 2, round, then multiply by 2 to get the right size for 2x.
    local width, height = self:getSize()
    self:setHitbox(0, math.ceil(height / 4) * 2, width, math.floor(height / 4) * 2)
end

function Savepoint:onInteract(player, dir)
    Assets.playSound("power")

    if self.text_once and self.used then
        self:onTextEnd()
        return
    end

    if self.text_once then
        self.used = true
    end

    super.onInteract(self, player, dir)
    return true
end

function Savepoint:onTextEnd()
    if not self.world then return end

    if self.heals then
        for _,party in pairs(Game.party_data) do
            party:heal(math.huge, false)
        end
    end

    if Game:isLight() then
        self.world:openMenu(LightSaveMenu(Game.save_id, self.marker))
    elseif self.simple_menu or (self.simple_menu == nil and Game:getConfig("smallSaveMenu")) then
        self.world:openMenu(SimpleSaveMenu(Game.save_id, self.marker))
    else
        self.world:openMenu(SaveMenu(self.marker))
    end
end

return Savepoint