---@class StandardOutputListener : LoggingOutputListener
local StandardOutputListener = Class(LoggingOutputListener)

function StandardOutputListener:init()
end

function StandardOutputListener:receive(data)
    print(data.full_message:getANSIString())
end

return StandardOutputListener
