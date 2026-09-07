---@class ConsoleOutputListener : LoggingOutputListener
local ConsoleOutputListener = Class(LoggingOutputListener)

function ConsoleOutputListener:init()
end

function ConsoleOutputListener:outputTableToConsoleTable(tbl)
    local console_table = {}

    local last_color = nil
    for _, part in ipairs(tbl) do
        if not Utils.equal(part.color, last_color) then
            last_color = part.color
            table.insert(console_table, part.color)
        end

        table.insert(console_table, part.text)
    end

    return console_table
end

function ConsoleOutputListener:receive(data)
    if Kristal.Console == nil then
        return
    end

    Kristal.Console:push(self:outputTableToConsoleTable(data.full_message:getTable()))

    if data.announce then
        Kristal.Console:announce(self:outputTableToConsoleTable(data.prefix:add(" "):add(data.content):getTable()))
    end
end

return ConsoleOutputListener
