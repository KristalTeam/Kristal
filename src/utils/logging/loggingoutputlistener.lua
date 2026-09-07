---@class LoggingOutputData
---@field full_message FormatString # The full message, including prefixes.
---@field content FormatString # The content of the log message.
---@field prefix FormatString # The prefix of the log message.
---@field announce boolean # Whether the message should be announced.

---@class LoggingOutputListener : Class
local LoggingOutputListener = Class()

function LoggingOutputListener:init()
end

function LoggingOutputListener:receive(data)
    error("LoggingOutputListener:receive must be implemented by subclasses")
end

return LoggingOutputListener
