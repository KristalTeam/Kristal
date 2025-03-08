--- A region in the Overworld which hides followers of the player when the player steps into it. \
--- `HideParty` is an [`Event`](lua://Event.init) - naming an object `hideparty` on an `objects` layer in a map creates this object. \
--- See this object's Fields for the configurable properties on this object.
--- 
---@class HideParty : Event
---
---@field alphas table<Follower, number>
---@field target_alpha number *[Property `alpha`]* The target alpha of followers in this region (Defaults to `0`)
---
---@overload fun(...) : HideParty
local HideParty, super = Class(Event)

function HideParty:init(x, y, shape, alpha)
    super.init(self, x, y, shape)

    self.alphas = {}
    self.target_alpha = alpha or 0
end

function HideParty:onEnter(chara)
    if chara.is_player then
        local id = self:getUniqueID().."_alpha"
        for _,follower in ipairs(self.world.followers) do
            self.alphas[follower] = follower.sprite.alpha
            local mask = follower:addFX(AlphaFX(1), id)
            self.world.timer:tween(10/30, mask, {alpha = self.target_alpha})
        end
    end
end

function HideParty:onExit(chara)
    if chara.is_player then
        local id = self:getUniqueID().."_alpha"
        for follower,alpha in pairs(self.alphas) do
            local mask = follower:getFX(id)
            if mask then
                self.world.timer:tween(10/30, mask, {alpha = alpha}, "linear", function()
                    follower:removeFX(mask)
                end)
            end
        end
        self.alphas = {}
    end
end

return HideParty