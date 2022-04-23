local Script, super = Class(Event)

function Script:init(x, y, w, h, properties)
    super:init(self, x, y, w, h)

    properties = properties or {}

    self.solid = false

    self.cutscene = properties["cutscene"]
    self.script = properties["script"]

    self.set_flag = properties["setflag"]
    self.set_value = properties["setvalue"]

    self.once = properties["once"]
end

function Script:onAdd(parent)
    super:onAdd(self, parent)
    if self.once and self:getFlag("used_once", false) then
        self:remove()
    end
end

function Script:onEnter(chara)
    if chara.is_player then
        if self.script then
            Registry.getEventScript(self.script)(self, chara)
        end
        if self.cutscene then
            self.world:startCutscene(self.cutscene, self, chara)
        end
        if self.set_flag then
            Game:setFlag(self.set_flag, (self.set_value == nil and true) or self.set_value)
        end
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