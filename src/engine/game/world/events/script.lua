local Script, super = Class(Event)

function Script:init(script, x, y, w, h, once)
    super:init(self, x, y, w, h)

    self.solid = false

    self.script = script
    self.once = once
end

function Script:onAdd(parent)
    super:onAdd(self, parent)
    if self.once and self:getFlag("used_once", false) then
        self:remove()
    end
end

function Script:onEnter(chara)
    if chara.is_player then
        self.world:startCutscene(self.script, self, chara)
        self:setFlag("used_once", true)
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