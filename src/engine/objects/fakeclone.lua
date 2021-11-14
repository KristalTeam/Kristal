local FakeClone, super = Class(Object)

function FakeClone:init(ref, x, y)
    super:init(self, x, y)

    self.ref = ref

    self.auto_remove = true
end

function FakeClone:update(dt)
    if self.auto_remove and not self.ref.stage then
        self:remove()
        return
    end

    self.visible = self.ref.visible

    super:update(self, dt)
end

function FakeClone:preDraw()
    self.last_ref_x = self.ref.x
    self.last_ref_y = self.ref.y

    self.ref.x = 0
    self.ref.y = 0

    super:preDraw(self)

    self.ref:preDraw(self)
end

function FakeClone:draw()
    self.visible = false
    self.ref:draw()
    self.visible = true

    super:draw(self)
end

function FakeClone:postDraw()
    self.ref:postDraw()

    super:postDraw(self)

    self.ref.x = self.last_ref_x
    self.ref.y = self.last_ref_y
end

return FakeClone