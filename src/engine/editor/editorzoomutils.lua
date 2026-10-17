---@class EditorZoomUtils
---@field PERCENT_LEVELS number[]
local EditorZoomUtils = {}

EditorZoomUtils.PERCENT_LEVELS = {}
for percent = 10, 50, 5 do table.insert(EditorZoomUtils.PERCENT_LEVELS, percent) end
for percent = 60, 200, 10 do table.insert(EditorZoomUtils.PERCENT_LEVELS, percent) end
for percent = 225, 400, 25 do table.insert(EditorZoomUtils.PERCENT_LEVELS, percent) end

---@param current number
---@param direction number
---@param minimum number
---@param maximum number
---@return number
function EditorZoomUtils.step(current, direction, minimum, maximum)
    local current_percent = current * 100
    local steps = math.max(1, MathUtils.round(math.abs(direction)))
    if direction > 0 then
        for index, percent in ipairs(EditorZoomUtils.PERCENT_LEVELS) do
            if percent > current_percent + 0.0001 then
                percent = EditorZoomUtils.PERCENT_LEVELS[math.min(#EditorZoomUtils.PERCENT_LEVELS,
                    index + steps - 1)]
                return MathUtils.clamp(percent / 100, minimum, maximum)
            end
        end
        return maximum
    elseif direction < 0 then
        for index = #EditorZoomUtils.PERCENT_LEVELS, 1, -1 do
            local percent = EditorZoomUtils.PERCENT_LEVELS[index]
            if percent < current_percent - 0.0001 then
                percent = EditorZoomUtils.PERCENT_LEVELS[math.max(1, index - steps + 1)]
                return MathUtils.clamp(percent / 100, minimum, maximum)
            end
        end
        return minimum
    end
    return current
end

return EditorZoomUtils
