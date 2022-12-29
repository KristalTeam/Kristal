---@class Timer : Object
---@overload fun(...) : Timer
local Timer, super = Class(Object)

function Timer:init(active)
    super.init(self)

    self.timer = LibTimer.new()

    if active ~= nil then
        self.active = active
    end
end

function Timer:pause(handle)
    self.timer:pause(handle)
end

function Timer:unpause(handle)
    self.timer:unpause(handle)
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
    if not count or count > 1 then
        return self.timer:every(delay, func, (count or math.huge) - 1)
    end
    return {}
end

function Timer:during(delay, func, after)
    return self.timer:during(delay, func, after)
end

function Timer:tween(duration, subject, target, method, after, ...)
    return self.timer:tween(duration, subject, target, method, after, ...)
end

function Timer:doWhile(condition, func, after)
    return self.timer:during(math.huge, function()
        if not condition() then
            if after then after() end
            return false
        end
        func()
    end)
end

function Timer:afterCond(condition, func)
    return self:doWhile(function() return not condition() end, function() end, func)
end

function Timer:approach(time, from, to, callback, easing, after)
    local t = 0
    callback(from)
    return self:during(math.huge, function()
        t = t + DT
        local value = Utils.ease(from, to, t / time, easing or "linear")
        callback(value)
        if t >= time then
            if after then after() end
            return false
        end
    end)
end

function Timer:cancel(handle)
    return self.timer:cancel(handle)
end

function Timer:clear()
    return self.timer:clear()
end

function Timer:update()
    self.timer:update()

    super.update(self)
end

return Timer