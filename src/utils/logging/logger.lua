--- The logger class, which is responsible for logging messages to the built-in console, stdout, and other outputs.
---@class Logger : Class
---
---@field private name string The name of the logger.
---@field private name_format ConsoleFormatting The formatting to use for the logger's name.
---@field private listeners LoggingOutputListener[] The output listeners that will receive the logger's messages.
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

--- Print a formatted message, using the logger's name and prefixes.
---@param prefix string
---@param prefix_formatting ConsoleFormatting
---@param message FormatString|string
---@param announce boolean
function Logger:outputMessage(prefix, prefix_formatting, message, announce)
    local formatted_name = self:getFormattedName()
    local formatted_prefix = self:getPrefix(prefix, prefix_formatting)

    local full_message = formatted_name:add(" "):add(formatted_prefix):add(" "):add(message)

    for _, listener in ipairs(self:getOutputListeners()) do
        listener:receive({
            full_message = full_message,
            content = message,
            logger_name = formatted_name,
            prefix = formatted_prefix,
            prefix_string = prefix,
            announce = announce
        })
    end
end

--- Display a debug message.
---@param ... any # The message(s) to log.
function Logger:debug(...)
    self:outputMessage("DEBUG", ConsoleFormats.BLUE, Logging.dump({ ... }, ConsoleFormats.GRAY), false)
end

--- Display an informational message.
---@param ... any # The message(s) to log.
function Logger:info(...)
    self:outputMessage("INFO", ConsoleFormats.GREEN, Logging.dump({ ... }), false)
end

--- Display a warning message.
---@param ... any # The message(s) to log.
function Logger:warn(...)
    self:outputMessage("WARN", ConsoleFormats.YELLOW, Logging.dump({ ... }), false)
end

--- Display an error message.
---@param ... any # The message(s) to log.
function Logger:error(...)
    self:outputMessage("ERROR", ConsoleFormats.RED, Logging.dump({ ... }), false)
end

--- Display a fatal error message.
---@param ... any # The message(s) to log.
function Logger:fatal(...)
    self:outputMessage("FATAL", ConsoleFormats.FATAL, Logging.dump({ ... }), false)
end

--- Display a debug message, and announce it.
---@param ... any # The message(s) to log.
function Logger:debugNotify(...)
    self:outputMessage("DEBUG", ConsoleFormats.BLUE, Logging.dump({ ... }, ConsoleFormats.GRAY), true)
end

--- Display an informational message, and announce it.
---@param ... any # The message(s) to log.
function Logger:infoNotify(...)
    self:outputMessage("INFO", ConsoleFormats.GREEN, Logging.dump({ ... }), true)
end

--- Display a warning message, and announce it.
---@param ... any # The message(s) to log.
function Logger:warnNotify(...)
    self:outputMessage("WARN", ConsoleFormats.YELLOW, Logging.dump({ ... }), true)
end

--- Display an error message, and announce it.
---@param ... any # The message(s) to log.
function Logger:errorNotify(...)
    self:outputMessage("ERROR", ConsoleFormats.RED, Logging.dump({ ... }), true)
end

--- Display a fatal error message, and announce it.
---@param ... any # The message(s) to log.
function Logger:fatalNotify(...)
    self:outputMessage("FATAL", ConsoleFormats.FATAL, Logging.dump({ ... }), true)
end

return Logger
