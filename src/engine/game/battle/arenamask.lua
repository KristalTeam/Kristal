---@class ArenaMask : Object
---@overload fun(...) : ArenaMask
local ArenaMask, super = Class(Object)

function ArenaMask:init(layer, x, y, arena)
    super:init(self, x, y)

    self.layer = layer or Utils.lerp(BATTLE_LAYERS["below_bullets"], BATTLE_LAYERS["bullets"], 0.5)
    self.arena = arena

    self.mask_fx = MaskFX(function() return self.arena or Game.battle.arena end)
    self:addFX(self.mask_fx)
end

function ArenaMask:fullDraw(...)
    self.mask_fx.active = #self.children > 0

    super:fullDraw(self, ...)
end

return ArenaMask