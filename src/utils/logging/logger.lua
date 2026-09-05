--- The logger class, which is responsible for logging messages to the built-in console, stdout, and other outputs.
---@class Logger : Class
---
---@field private name string The name of the logger.
---@field private name_format ConsoleFormatting The formatting to use for the logger's name.
---@overload fun(name: string, name_format: ConsoleFormatting) : Logger
local Logger = Class()

---@param name string The name of the logger.
function Logger:init(name, name_format)
    assert(type(name) == "string", "Logger name must be a string")

    self.name = name
    self.name_format = name_format or ConsoleFormats.DEFAULT

    self.listeners = Logging.getOutputListeners()
end

function Logger:getOutputListeners()
    return self.listeners
end

---@param input string
---@param formatting ConsoleFormatting?
---@return FormatString
function Logger:getPrefix(input, formatting)
    return FormatString(string.format("[%s]", input), formatting)
end

---@return FormatString
function Logger:getFormattedName()
    return self:getPrefix(self.name, self.name_format)
end

--- Construct a formatted message, using the logger's name and prefixes.
---@param prefix string
---@param prefix_formatting ConsoleFormatting
---@param message FormatString|string
---@param formatting ConsoleFormatting?
---@return FormatString
function Logger:getWithPrefixes(prefix, prefix_formatting, message, formatting)
    local formatted_message = nil

    if isClass(message) and message:includes(FormatString) then
        formatted_message = message
    else
        formatted_message = FormatString(message, formatting)
    end

    return self:getFormattedName()
        :add(" ")
        :add(self:getPrefix(prefix, prefix_formatting))
        :add(" ")
        :add(formatted_message)
end

--- Print a formatted message, using the logger's name and prefixes.
---@param prefix string
---@param prefix_formatting ConsoleFormatting
---@param message FormatString|string
---@param formatting ConsoleFormatting?
function Logger:outputMessage(prefix, prefix_formatting, message, formatting)
    local string = self:getWithPrefixes(prefix, prefix_formatting, message, formatting)

    for _, listener in ipairs(self:getOutputListeners()) do
        listener:receive(string)
    end
end

--- Display a debug message.
---@param ... any # The message(s) to log.
function Logger:debug(...)
    self:outputMessage("DEBUG", ConsoleFormats.BLUE, Logging.dump({ ... }, ConsoleFormats.GRAY))
end

--- Display an informational message.
---@param ... any # The message(s) to log.
function Logger:info(...)
    self:outputMessage("INFO", ConsoleFormats.GREEN, Logging.dump({ ... }))
end

--- Display a warning message.
---@param ... any # The message(s) to log.
function Logger:warn(...)
    self:outputMessage("WARN", ConsoleFormats.YELLOW, Logging.dump({ ... }))
end

--- Display an error message.
---@param ... any # The message(s) to log.
function Logger:error(...)
    self:outputMessage("ERROR", ConsoleFormats.RED, Logging.dump({ ... }))
end

--- Display a fatal error message.
---@param ... any # The message(s) to log.
function Logger:fatal(...)
    self:outputMessage("FATAL", ConsoleFormats.FATAL, Logging.dump({ ... }))
end

return Logger
