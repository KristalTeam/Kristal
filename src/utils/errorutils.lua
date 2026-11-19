---@class ErrorUtils
local ErrorUtils = {}

function ErrorUtils.traceback(value, level)
    if type(value) == "table" then value = value.msg or value.critical or tostring(value) end
    local coroutine_traceback = COROUTINE_TRACEBACK
    COROUTINE_TRACEBACK = nil
    local traceback = debug.traceback(tostring(value), level or 2)
    if coroutine_traceback then
        traceback = traceback .. "\n\nCoroutine traceback:\n" .. coroutine_traceback
    end
    return traceback
end

return ErrorUtils
