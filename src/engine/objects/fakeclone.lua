---@class FakeClone : Object
---@overload fun(...) : FakeClone
local FakeClone, super = Class(Object)

function FakeClone:init(ref, x, y, copy_transform)
    super.init(self, x, y, ref and ref.width, ref and ref.height)

    self.ref = ref

    self.copy_transform = copy_transform ~= false

    self.auto_remove = true
end

function FakeClone:getDebugRectangle()
    return self.ref:getDebugRectangle()
end

function FakeClone:update()
    if self.auto_remove and not self.ref.stage then
        self:remove()
        return
    end

    self.visible = self.ref.visible

    super.update(self)
end

function FakeClone:applyTransformTo(transform)
    super.applyTransformTo(self, transform)

    if self.copy_transform then
        local last_ref_x, last_ref_y = self.ref.x, self.ref.y
        self.ref.x, self.ref.y = 0, 0
        self.ref:applyTransformTo(transform)
        self.ref.x, self.ref.y = last_ref_x, last_ref_y
    end
end

function FakeClone:draw()
    self.visible = false
    self.ref:fullDraw(false, true)
    self.visible = true

    super.draw(self)
end

function FakeClone:canDeepCopyKey(key)
    return super.canDeepCopyKey(self, key) and key ~= "ref"
end

return FakeClone