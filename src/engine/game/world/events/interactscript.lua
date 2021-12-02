local InteractScript, super = Class(Event)

function InteractScript:init(script, x, y, w, h)
    super:init(self, x, y, w, h)

    self.solid = false

    self.script = script
end

function InteractScript:onInteract(player, dir)
    self.world:startCutscene(self.script, self, player, dir)
    return true
end

return InteractScript