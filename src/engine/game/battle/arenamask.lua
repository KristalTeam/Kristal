--- A special object used by [`Arena`](lua://Arena.init) to mask certain objects to only show inside the arena.
---
---@class ArenaMask : Object
---@overload fun(layer?:number, x?:number, y?:number, arena?:Arena) : ArenaMask
local ArenaMask, super = Class(Object)

---@param layer?    number
---@param x?        number
---@param y?        number
---@param arena?    Arena
function ArenaMask:init(layer, x, y, arena)
    super.init(self, x, y)

    self.layer = layer or Utils.lerp(BATTLE_LAYERS["below_bullets"], BATTLE_LAYERS["bullets"], 0.5)
    self.arena = arena

    self.mask_fx = MaskFX(function() return self.arena or Game.battle.arena end)
    self:addFX(self.mask_fx)
end

function ArenaMask:fullDraw(...)
    self.mask_fx.active = #self.children > 0

    super.fullDraw(self, ...)
end

return ArenaMask