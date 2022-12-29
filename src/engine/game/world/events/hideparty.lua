---@class HideParty : Event
---@overload fun(...) : HideParty
local HideParty, super = Class(Event)

function HideParty:init(x, y, w, h, alpha)
    super.init(self, x, y, w, h)

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