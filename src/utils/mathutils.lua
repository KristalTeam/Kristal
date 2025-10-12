---@class MathUtils
local MathUtils = {}

---
--- Checks if a number is an integer.
---
--- @param value number # The number to check.
--- @return boolean is_integer # Whether the value is an integer or not.
---
function MathUtils.isInteger(value)
    return (math.floor(value) == value)
end

---
--- Rounds a number down to the nearest multiple of a specified number.
---
---@param value number   # The value to round.
---@param to number      # The multiple to round down to.
---@return number result # The rounded value.
---
function MathUtils.floorToMultiple(value, to)
    if to == 0 then
        return 0
    end

    return math.floor(value / to) * to
end

---
--- Rounds a number up to the nearest multiple of a specified number.
---
---@param value number   # The value to round.
---@param to number      # The multiple to round down to.
---@return number result # The rounded value.
---
function MathUtils.ceilToMultiple(value, to)
    if to == 0 then
        return 0
    end

    return math.ceil(value / to) * to
end

---
--- Rounds the specified value to the nearest integer.
---
---@param value number   # The value to round.
---@return number result # The rounded value.
---
function MathUtils.round(value)
    return math.floor(value + 0.5)
end

---
--- Rounds the specified value to the nearest multiple of a specified number.
---
---@param value number   # The value to round.
---@param to number      # The multiple to round down to.
---@return number result # The rounded value.
---
function MathUtils.roundToMultiple(value, to)
    if to == 0 then
        return 0
    end

    return math.floor((value + (to / 2)) / to) * to
end

---
--- Rounds the specified value to the nearest integer towards zero.
---
---@param value number   # The value to round.
---@return number result # The rounded value.
---
function MathUtils.roundToZero(value)
    if value == 0 then return 0 end
    if value > 0 then return math.floor(value) end
    if value < 0 then return math.ceil(value) end
    return 0 / 0 -- return NaN
end

---
--- Rounds the specified value to the nearest integer away from zero.
---
---@param value number   # The value to round.
---@return number result # The rounded value.
---
function MathUtils.roundFromZero(value)
    if value == 0 then return 0 end
    if value > 0 then return math.ceil(value) end
    if value < 0 then return math.floor(value) end
    return 0 / 0 -- return NaN
end

---
--- Clamps the specified values between 2 bounds.
---
---@param val number     # The value to limit.
---@param min number     # The minimum bound.
---@param max number     # The maximum bound.
---@return number result # The clamped result.
---
function MathUtils.clamp(val, min, max)
    return math.max(min, math.min(max, val))
end

---
--- Returns the polarity of the specified value: -1 if it's negative, 1 if it's positive, and 0 otherwise.
---
---@param num number   # The value to check.
---@return number sign # The sign of the value.
---
function MathUtils.sign(num)
    return num > 0 and 1 or (num < 0 and -1 or 0)
end

---
--- Moves the specified value towards a target value by a specified amount, without exceeding the target. \
--- If the target is less than the value, then the amount will be subtracted from the value instead to approach it.
---
---@param val number     # The initial value.
---@param target number  # The target value to approach.
---@param amount number  # The amount the initial value should approach the target by.
---@return number result # The new value. If the value would have passed the target value, it will instead be set to the target.
---
function MathUtils.approach(val, target, amount)
    if target < val then
        return math.max(target, val - amount)
    elseif target > val then
        return math.min(target, val + amount)
    end
    return target
end

---
--- Moves the specified angle towards a target angle by a specified amount, properly accounting for wrapping around. \
--- Will always approach in the direction with the shorter distance.
---
---@param val number     # The initial angle.
---@param target number  # The target angle to approach.
---@param amount number  # The amount the initial angle should approach the target by.
---@return number result # The new angle. If the angle would have passed the target angle, it will instead be set to the target.
---
function MathUtils.approachAngle(val, target, amount)
    local to = val + MathUtils.angleDiff(target, val)
    return MathUtils.approach(val, to, amount)
end

---
--- Returns a value between two numbers, determined by a percentage from 0 to 1.
---
---@param from   number  # The start value of the range.
---@param to     number  # The end value of the range.
---@param factor number  # The percentage (from 0 to 1) that determines the point on the specified range.
---@return number result # The new value from the range.
---
function MathUtils.lerp(from, to, factor)
    assert(type(from) == "number", "MathUtils.lerp: Expected number \"from\", got " .. type(from))
    assert(type(to) == "number", "MathUtils.lerp: Expected number \"to\", got " .. type(to))
    assert(type(factor) == "number", "MathUtils.lerp: Expected number \"factor\", got " .. type(factor))
    return from + (to - from) * factor
end

---
--- Lerps between two coordinates.
---
---@param x1 number     # The horizontal position of the first point.
---@param y1 number     # The vertical position of the first point.
---@param x2 number     # The horizontal position of the second point.
---@param y2 number     # The vertical position of the second point.
---@param t number      # The percentage (from 0 to 1) that determines the new point on the specified range between the specified points.
---@return number new_x # The horizontal position of the new point.
---@return number new_y # The vertical position of the new point.
---
function MathUtils.lerpPoint(x1, y1, x2, y2, t)
    return MathUtils.lerp(x1, x2, t), MathUtils.lerp(y1, y2, t)
end

---
--- Maps a value between a specified range to its equivalent position in a new range. \
--- Does not automatically clamp.
---
---@param val number     # The initial value in the initial range.
---@param min_a number   # The start value of the initial range.
---@param max_a number   # The end value of the initial range.
---@param min_b number   # The start value of the new range.
---@param max_b number   # The end value of the new range.
---@return number result # The value within the new range.
---
function MathUtils.rangeMap(val, min_a, max_a, min_b, max_b)
    if min_a > max_a then
        -- Swap min and max
        min_a, max_a = max_a, min_a
        min_b, max_b = max_b, min_b
    end
    local t = (val - min_a) / (max_a - min_a)
    return MathUtils.lerp(min_b, max_b, t)
end

---
--- Returns a randomly generated decimal value between the lower bound (inclusive) and the upper bound (exclusive). \
--- If no upper bound is entered, it will be 1. \
--- If no lower bound is entered, it will be 0.
---
---@param upper? number # The upper bound.
---@param lower? number # The lower bound.
---@overload fun() : number
---@overload fun(upper: number) : number
---@overload fun(lower: number, upper: number) : number
---@return number value  # The new random value.
function MathUtils.random(lower, upper)
    if not lower then
        if not upper then
            return love.math.random()
        end
        error("Expected lower bound, got nil")
    end

    if not upper then
        return love.math.random() * lower -- Actually "upper" in this path! Lua needs overloads.
    else
        return love.math.random() * (upper - lower) + lower
    end
end

---
--- Returns a randomly generated integer value between the lower bound (inclusive) and the upper bound (exclusive). \
--- If no lower bound is entered, it will be 0.
---
---@param upper integer # The upper bound.
---@param lower? integer # The lower bound.
---@overload fun(upper: integer) : integer
---@overload fun(lower: integer, upper: integer) : integer
---@return integer value  # The new random value.
function MathUtils.randomInt(lower, upper)
    assert(lower ~= nil, "Expected bound, got nil")

    return math.floor(MathUtils.random(lower, upper))
end

---
--- Returns the angle from one point to another.
---
---@param x1 number  # The horizontal position of the first point.
---@param y1 number  # The vertical position of the first point.
---@param x2 number  # The horizontal position of the second point.
---@param y2 number  # The vertical position of the second point.
---@return number angle # The angle from the first point to the second point.
---
function MathUtils.angle(x1, y1, x2, y2)
    return math.atan2(y2 - y1, x2 - x1)
end

---
--- Returns the distance between two angles, properly accounting for wrapping around.
---
---@param a number     # The first angle to compare.
---@param b number     # The second angle to compare.
---@return number diff # The difference between the two angles.
---
function MathUtils.angleDiff(a, b)
    return ((a - b) + math.pi) % (math.pi * 2) - math.pi
end

---
--- Returns the distance between two points.
---
---@param x1 number    # The horizontal position of the first point.
---@param y1 number    # The vertical position of the first point.
---@param x2 number    # The horizontal position of the second point.
---@param y2 number    # The vertical position of the second point.
---@return number dist # The linear distance from the first point to the second point.
---
function MathUtils.dist(x1, y1, x2, y2)
    local dx, dy = x1 - x2, y1 - y2
    return math.sqrt((dx * dx) + (dy * dy))
end

---
--- Limits the absolute value of a number between two positive numbers, then sets it to its original sign.
---
---@param value number   # The value to limit.
---@param min number     # The minimum bound. If the absolute value of the specified value is less than this number, it is set to it.
---@param max number     # The maximum bound. If the absolute value of the specified value is greater than this number, it is set to it.
---@return number result # The new limited number.
---
function MathUtils.absClamp(value, min, max)
    local sign = value < 0 and -1 or 1
    return math.max(min, math.min(max, math.abs(value))) * sign
end

---
--- Returns the number closer to zero.
---
---@param a number       # The first number to compare.
---@param b number       # The second number to compare.
---@return number result # The specified number that was closer to zero than the other.
---
function MathUtils.absMin(a, b)
    return math.abs(b) < math.abs(a) and b or a
end

---
--- Returns the number further from zero.
---
---@param a number       # The first number to compare.
---@param b number       # The second number to compare.
---@return number result # The specified number that was further from zero than the other.
---
function MathUtils.absMax(a, b)
    return math.abs(b) > math.abs(a) and b or a
end

---
--- Limits the specified value to be between 2 bounds, wrapping around if it exceeds it.
---
---@param val number # The value to wrap.
---@param min number # The minimum bound, inclusive.
---@param max number # The maximum bound, exclusive.
---@return number result # The new wrapped number.
---@overload fun(val: integer, min: integer, max: integer): integer
function MathUtils.wrap(val, min, max)
    return (val - min) % (max - min) + min
end

---
--- Similar to `MathUtils.wrap`, intended to be used for wrapping a table index.
---
---@param val integer     # The value to wrap.
---@param length integer  # The length of the table to wrap the index around.
---@return integer result # The new wrapped index.
---@see MathUtils.wrap
function MathUtils.wrapIndex(val, length)
    return MathUtils.wrap(val, 1, length + 1)
end

--- Checks if the value is NaN (Not a Number)
---@param v any
---@return boolean
function MathUtils.isNaN(v)
    return v ~= v
end

--- XOR (eXclusive OR) logic operation
---@param ... any [conditions]
---@return boolean
function MathUtils.xor(...)
    local counter = 0
    for _, value in ipairs({ ... }) do
        if value then
            counter = counter + 1
        end
    end
    return counter % 2 == 1
end

return MathUtils
