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

--- Pauses a specific timer indefinitely. It can be unpaused with `Timer:unpause(handle)`.
---@param handle table  The handle of the timer to pause.
function Timer:pause(handle)
    self.timer:pause(handle)
end

---Resumes a timer previously paused with `Timer:pause(handle)`.
---@param handle table  The handle of the timer to resume.
function Timer:unpause(handle)
    self.timer:unpause(handle)
end

--- Runs a function after a given amount of time has passed.
---@param delay number  The time, in seconds, to wait before executing the function.
---@param func  fun()   The function to execute.
---@return table handle
function Timer:after(delay, func)
    return self.timer:after(delay, func)
end

--- Runs a function as a coroutine.
---@param func fun(wait: fun(seconds: number))  The function to execute. The `wait` parameter of this function can be called to pause the coroutine of this script.
---@return table handle
function Timer:script(func)
    return self.timer:script(func)
end

--- Runs a function at fixed intervals.
---@param delay     number          The time between calls to the function, in seconds.
---@param func      fun():boolean?  The function to execute. If this returns `false`, it will stop this timer.
---@param count?    number          The total number of times the function will run, if provided.
---@return table handle
function Timer:every(delay, func, count)
    return self.timer:every(delay, func, count)
end

--- Runs a function at fixed intervals, as well as once instantly.
---@param delay     number          The time between calls to the function, in seconds.
---@param func      fun():boolean?  The function to execute. If this returns `false`, it will stop this timer.
---@param count?    number          The total number of times the function will run, if provided.
---@return table handle
function Timer:everyInstant(delay, func, count)
    func()
    if not count or count > 1 then
        return self.timer:every(delay, func, (count or math.huge) - 1)
    end
    return {}
end

--- Runs a function every frame for a given interval.
---@param delay     number          The time to run this function for, in seconds.
---@param func      fun(): boolean? The function to execute. If this returns `false`, it will stop this timer early.
---@param after?    fun()           A function to execute when this timer finishes.
---@return table handle
function Timer:during(delay, func, after)
    return self.timer:during(delay, func, after)
end

--- Performs in-betweening (tweening) of a value on an object from its current value to another.
---@param duration  number      The time the tween will take place over, in seconds.
---@param subject   table       The object to be tweened.
---@param target    {key: string, value: number}[]  A table containing the keys in the `subject` table that should be tweened, and their target values.
---@param method?   easetype    The easing method to use, defaults to `linear`.
---@param after?    fun()       A function to run once the tween has finished.
---@param ...       unknown     Additional arguments to the tweening function.
---@return table handle
function Timer:tween(duration, subject, target, method, after, ...)
    return self.timer:tween(duration, subject, target, method, after, ...)
end

--- Runs a function every frame while a given condition is `true`.
---@param condition fun():boolean   The condition function. Should return the value of the condition to check.
---@param func      fun()           The function to execute.
---@param after?    fun()           A function to execute when the condition stops being `true`.
---@return table handle
function Timer:doWhile(condition, func, after)
    return self.timer:during(math.huge, function()
        if not condition() then
            if after then after() end
            return false
        end
        func()
    end)
end

--- Runs a function once a given condition is met.
---@param condition fun(): boolean  The condition function. Should return the value of the condition to check.
---@param func      fun()           The function to execute once the condition is `true`.
---@return table handle
function Timer:afterCond(condition, func)
    return self:doWhile(function() return not condition() end, function() end, func)
end

--- Tweens from one number to another over a period of time.
---@param time      number              The time it will take to complete the tween, measured in seconds.
---@param from      number              The starting value.
---@param to        number              The target value.
---@param callback  fun(value: number)  A function that gets called every frame during the tween. The current value of the tween is passed in as an argument to this function.
---@param easing?   easetype            The easing type to use.
---@param after?    fun()               A callback to run when the tween is finished.
---@return table handle
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

--- Cancels a timer completely.
---@param handle table  The handle of the timer to cancel.
function Timer:cancel(handle)
    return self.timer:cancel(handle)
end

--- Resets this timer, removing all attached handles.
function Timer:clear()
    return self.timer:clear()
end

function Timer:update()
    self.timer:update()

    super.update(self)
end

return Timer