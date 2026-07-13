---@class TemplateBullet : Bullet
local bullet, super = Class(Bullet, "test_bullet")

function bullet:init(x, y, texture)
    super.init(self, x, y, texture)

    -- Damage dealt on hit. Leave nil to use the attacker's default damage.
    self.damage = nil
    -- TP granted for grazing. Leave nil to use the attacker or engine default.
    self.tp = nil
    self.can_graze = true
    self.time_bonus = 1

    self.destroy_on_hit = true
    -- Frames of invulnerability granted after a hit.
    self.inv_frames = Game:getDefaultInvulnFrames()
    self.remove_offscreen = true
end

-- Function overrides go here

return bullet
