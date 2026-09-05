---@class LoggingOutputListener : Class
local LoggingOutputListener = Class()

function LoggingOutputListener:init()
end

---@param message FormatString
function LoggingOutputListener:receive(message)
    error("LoggingOutputListener:receive must be implemented by subclasses")
end

return LoggingOutputListener
