local Script, super = Class(Event)

function Script:init(script, x, y, w, h)
    super:init(self, x, y, w, h)

    self.solid = false

    self.script = script
end

function Script:onEnter(chara)
    if chara.is_player then
        self.world:startCutscene(self.script, self, chara)
        self:remove()
        return true
    end
end

function Script:draw()
    super:draw(self)
    if DEBUG_RENDER then
        self.collider:draw(0, 1, 1)
    end
end

return Script