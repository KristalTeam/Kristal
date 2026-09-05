---@class StandardOutputListener : LoggingOutputListener
local StandardOutputListener = Class(LoggingOutputListener)

function StandardOutputListener:init()
end

---@param message FormatString
function StandardOutputListener:receive(message)
    print(message:getANSIString())
end

return StandardOutputListener
