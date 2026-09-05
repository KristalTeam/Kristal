---@class ConsoleOutputListener : LoggingOutputListener
local ConsoleOutputListener = Class(LoggingOutputListener)

function ConsoleOutputListener:init()
end

---@param message FormatString
function ConsoleOutputListener:receive(message)
    if Kristal.Console == nil then
        return
    end

    local message_table = message:getTable()
    local console_table = {}

    local last_color = nil
    for _, part in ipairs(message_table) do
        if not Utils.equal(part.color, last_color) then
            last_color = part.color
            table.insert(console_table, part.color)
        end

        table.insert(console_table, part.text)
    end

    Kristal.Console:push(console_table)
end

return ConsoleOutputListener
