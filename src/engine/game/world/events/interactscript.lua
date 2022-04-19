local InteractScript, super = Class(Event)

function InteractScript:init(script, x, y, w, h, once)
    super:init(self, x, y, w, h)

    self.solid = false

    self.script = script
    self.once = once
end

function InteractScript:onAdd(parent)
    super:onAdd(self, parent)
    if self.once and self:getFlag("used_once", false) then
        self:remove()
    end
end

function InteractScript:onInteract(player, dir)
    self.world:startCutscene(self.script, self, player, dir)
    self:setFlag("used_once", true)
    if self.once then
        self:remove()
    end
    return true
end

return InteractScript