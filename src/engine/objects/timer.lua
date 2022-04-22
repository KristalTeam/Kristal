local Timer, super = Class(Object)

function Timer:init(active)
    super:init(self)

    self.timer = LibTimer.new()

    if active ~= nil then
        self.active = active
    end
end

function Timer:after(delay, func)
    return self.timer:after(delay, func)
end

function Timer:script(func)
    return self.timer:script(func)
end

function Timer:every(delay, func, count)
    return self.timer:every(delay, func, count)
end

function Timer:everyInstant(delay, func, count)
    func()
    return self.timer:every(delay, func, count)
end

function Timer:during(delay, func, after)
    return self.timer:during(delay, func, after)
end

function Timer:tween(duration, subject, target, method, after, ...)
    return self.timer:tween(duration, subject, target, method, after, ...)
end

function Timer:cancel(handle)
    return self.timer:cancel(handle)
end

function Timer:clear()
    return self.timer:clear()
end

function Timer:update()
    self.timer:update()

    super:update(self)
end

return Timer