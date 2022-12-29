---@class Callback : Object
---@overload fun(...) : Callback
local Callback, super = Class(Object)

function Callback:init(o)
    super.init(self)
    o = o or {}
    self.update_func_before = o["update_before"]
    self.update_func_after = o["update_after"] or o["update"]
    self.draw_func_before = o["draw_before"]
    self.draw_func_after = o["draw_after"] or o["draw"]
end

function Callback:update()
    if self.update_func_before then
        self:update_func_before()
    end
    super.update(self)
    if self.update_func_after then
        self:update_func_after()
    end
end

function Callback:draw()
    if self.draw_func_before then
        self:draw_func_before()
    end
    super.draw(self)
    if self.draw_func_after then
        self:draw_func_after()
    end
end

function Callback:setUpdate(func, before)
    if before then
        self.update_func_before = func
    else
        self.update_func_after = func
    end
end

function Callback:setDraw(func, before)
    if before then
        self.draw_func_before = func
    else
        self.draw_func_after = func
    end
end

return Callback