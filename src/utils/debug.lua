---@class Debug
---@field LOGGER Logger
---@field ONCE_TRIGGERS table<string, boolean>
local Debug = {}

function Debug.init()
    Debug.LOGGER = Logger("Debug", ConsoleFormats.MAGENTA)
    Debug.ONCE_TRIGGERS = {}
end

function Debug.reset()
    Debug.ONCE_TRIGGERS = {}
end

---@return boolean
function Debug.once(id)
    if Debug.ONCE_TRIGGERS[id] then
        return false
    end

    Debug.ONCE_TRIGGERS[id] = true

    return true
end

return Debug
