---@class ErrorUtils
local ErrorUtils = {}

function ErrorUtils.traceback(value, level)
    if type(value) == "table" then value = value.msg or value.critical or tostring(value) end
    return debug.traceback(tostring(value), level or 2)
end

return ErrorUtils
