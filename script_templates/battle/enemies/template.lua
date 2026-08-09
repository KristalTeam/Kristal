---@class TemplateEnemy : EnemyBattler
local enemy, super = Class(EnemyBattler, "test_enemy")

function enemy:init(actor, use_overlay)
    super.init(self, actor, use_overlay)

    self.name = "New Enemy"
    self.max_health = 100
    self.health = self.max_health
    self.attack = 1
    self.defense = 0
    self.money = 0
    self.experience = 0
    self.tired = false
    self.mercy = 0
    self.spare_points = 0

    self.exit_on_defeat = true
    self.auto_spare = false
    self.can_freeze = true
    self.selectable = true
    self.disable_mercy = false

    self.check = "A new enemy."
    self.text = {}
    self.low_health_text = nil
    self.tired_text = nil
    self.spareable_text = nil
    self.tired_percentage = 0.5
    self.low_health_percentage = 0.5

    self.dmg_sprites = {}
    self.dmg_sprite_offset = {0, 0}

    self.dialogue_bubble = nil
    self.dialogue_offset = {0, 0}
    self.dialogue = {}
    self.waves = {}

    self.acts = {
        {
            name = "Check",
            description = Game:getConfig("checkActDescription") and "Useless\nanalysis" or "",
            party = {}
        }
    }

    self.comment = ""
    self.icons = {}
    self.graze_tension = 1.6
end

-- Function overrides go here

return enemy
