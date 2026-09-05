---@type boolean
local success

---@type ffilib?
local FFI

success, FFI = pcall(require, "ffi")
if not success then
    FFI = nil
end

local BIT = require("bit")

---@class Logging
local Logging = {}

---@type Logger
Logging.INSTANCE = nil

Logging.UNKNOWN_ARGUMENT = nil

---
--- Initialize the logging system.
---
function Logging.init(colors_arg)
    Logging.use_colors = false

    if colors_arg == nil then
        Logging.checkColorSupport()
    else
        local arg_value = colors_arg[1]

        if arg_value == "enable" then
            Logging.setColorSupport(true)
        elseif arg_value == "disable" then
            Logging.setColorSupport(false)
        elseif arg_value == "default" or colors_arg == nil then
            Logging.checkColorSupport()
        else
            Logging.UNKNOWN_ARGUMENT = arg_value
            Logging.checkColorSupport()
        end
    end

    Logging.LISTENERS = {}
end

function Logging.registerListener(listener)
    assert(isClass(listener) and listener:includes(LoggingOutputListener), "Listener must be a LoggingOutputListener")

    table.insert(Logging.LISTENERS, listener)
end

function Logging.getOutputListeners()
    return Logging.LISTENERS
end

function Logging.registerDefaultListeners()
    Logging.registerListener(StandardOutputListener())
end

---@internal
function Logging.createSystemLogger()
    -- Create the logger!
    Logging.INSTANCE = Logger("System", ConsoleFormats.CYAN)

    Logging.info(
        "Logging system initialized on platform: "
            .. FormatString(
                (FFI ~= nil) and FFI.os or "Unknown",
                ConsoleFormats.BLUE
            )
    )

    if Logging.UNKNOWN_ARGUMENT ~= nil then
        Logging.warn(
            "Unknown argument to " .. FormatString("--ansi-colors", ConsoleFormats.YELLOW) .. ": "
                .. FormatString(Logging.UNKNOWN_ARGUMENT, ConsoleFormats.GRAY) .. ". Assuming default behavior."
        )
    end
end

--- Checks if the environment supports ANSI colors, and enable color support if it does.
---
--- If we're on Windows, using `conhost`, it will attempt to enable color support by setting the console mode.
---
--- We only need the 8-color palette for now, but this may be expanded in the future.
---
--- (Why is color support so weird...)
---@internal
function Logging.checkColorSupport()
    -- Check if the environment supports colors.

    if os.getenv("NO_COLOR") ~= nil then
        -- NO_COLOR is set, so let's turn off our color system.
        Logging.setColorSupport(false)
        return
    end

    if os.getenv("FORCE_COLOR") ~= nil then
        -- FORCE_COLOR is set, so let's forcibly turn on our color system.
        Logging.setColorSupport(true)
        return
    end

    -- TODO:
    -- Unix might want to check `isatty`. If we're outputting to a file, we should turn off colors!
    -- Windows might want to check `_isatty` for the same reason.
    -- Of course, since we're already doing kernel32 console API bindings, maybe we use those instead to check!
    -- We should abstract the kernel32 stuff into a separate module, since we'll need to use it here.

    -- Now, for environment variable checking...

    if os.getenv("TERM") == "dumb" then
        -- If TERM is set to "dumb", we don't have color support.
        Logging.setColorSupport(false)
        return
    end

    -- A list of known terminals with color support.
    local known_terminals = {
        "vscode",
        "iTerm.app",
        "Apple_Terminal",
        "Hyper",
        "WezTerm",
        "Alacritty",
        "Terminus",
        "xterm-kitty"
    }

    if os.getenv("WT_PROFILE_ID") ~= nil or                                  -- Windows Terminal
        os.getenv("ANSICON") ~= nil or                                       -- ANSICON
        os.getenv("CMDER_ROOT") ~= nil or                                    -- Cmder
        os.getenv("ConEmuANSI") == "ON" or                                   -- ConEmu
        os.getenv("COLORTERM") ~= nil or                                     -- COLORTERM is set
        os.getenv("TERM") ~= nil or                                          -- TERM is set (and not "dumb")
        TableUtils.contains(known_terminals, os.getenv("TERM_PROGRAM")) then -- TERM_PROGRAM is set to a known app
        -- If we're running in a terminal that already supports ANSI colors, we don't need to do anything special.

        Logging.setColorSupport(true)
        return
    end

    if FFI == nil then
        -- We don't have FFI whatsoever... just bail, or else these checks will become 100x more complicated
        Logging.setColorSupport(false)
        return
    end

    -- Can't rely on the environment variables it seems

    if FFI.os == "Windows" then
        -- We're on Windows. Try to enable colors if possible (for `conhost`)
        Logging.enableWindowsANSI()
        return
    else
        -- Well, we tried a bunch of environment variables, and nothing worked.
        Logging.setColorSupport(false)
        return
    end
end

---@internal
function Logging.setColorSupport(enabled)
    Logging.use_colors = enabled
end

--- Returns whether colors are supported in this environment.
---@return boolean supported # The environment's color support status.
function Logging.getColorSupport()
    return Logging.use_colors
end

--- This function attempts to enable ANSI color support for the attached console.
---
--- If it fails, color support is disabled.
---@internal
function Logging.enableWindowsANSI()
    assert(FFI ~= nil, "enableWindowsANSI called without FFI support")
    assert(FFI.os == "Windows", "enableWindowsANSI called on non-Windows platform \"" .. FFI.os .. "\"")

    FFI.cdef(
        [[
        typedef void* HANDLE;
        typedef unsigned long DWORD;
        typedef int BOOL;

        HANDLE __stdcall GetStdHandle(DWORD nStdHandle);
        BOOL __stdcall SetConsoleMode(HANDLE hConsoleHandle, DWORD dwMode);
    ]]
    )

    local STD_INPUT_HANDLE = 0xFFFFFFF6
    local STD_OUTPUT_HANDLE = 0xFFFFFFF5
    local STD_ERROR_HANDLE = 0xFFFFFFF4

    local ENABLE_PROCESSED_OUTPUT = 0x0001
    local ENABLE_WRAP_AT_EOL_OUTPUT = 0x0002
    local ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x0004
    local DISABLE_NEWLINE_AUTO_RETURN = 0x0008
    local ENABLE_LVB_GRID_WORLDWIDE = 0x0010

    local INVALID_HANDLE_VALUE = FFI.cast("HANDLE", -1)

    local kernel32 = FFI.load("kernel32")

    local handle = kernel32.GetStdHandle(STD_OUTPUT_HANDLE)

    if handle == INVALID_HANDLE_VALUE then
        -- Couldn't get the output handle!
        Logging.setColorSupport(false)
        return
    end

    -- Set the flags for the console output.
    local console_mode_success = kernel32.SetConsoleMode(
        handle,
        BIT.bor(
            ENABLE_PROCESSED_OUTPUT,
            ENABLE_WRAP_AT_EOL_OUTPUT,
            ENABLE_VIRTUAL_TERMINAL_PROCESSING
        )
    )

    if console_mode_success == 0 then
        -- We didn't successfully set the console mode, we won't support colors.
        Logging.setColorSupport(false)
    else
        -- Non-zero, seems like we succeeded?
        Logging.setColorSupport(true)
    end
end

--- Dumps a table of values to a string.
---
--- Solely used for logging -- if you need to dump a table, use [`TableUtils.dump`](lua://TableUtils.dump) instead.
---
--- As it's meant for logging, each value is separated by four spaces.
---@param values any[] # The values to dump.
---@param formatting ConsoleFormatting? # The formatting to use.
---@return FormatString # The dumped values as a formatted string.
---@internal
function Logging.dump(values, formatting)
    local output = FormatString(nil, formatting)
    local indent = false

    for _, value in ipairs(values) do
        if indent then
            output = output:add(FormatString("    ", formatting))
        end

        indent = true

        if type(value) == "string" then
            -- If it's a string, we can just use it directly.
            output = output:add(FormatString(value, formatting))
        elseif isClass(value) and value:includes(FormatString) then
            -- If it's already a FormatString, we can just add it directly.
            output = output:add(value)
        else
            output = output:add(FormatString(TableUtils.dump(value), formatting))
        end
    end

    return output
end

--- Display a debug message.
---@param ... any # The message(s) to log.
function Logging.debug(...)
    Logging.INSTANCE:debug(...)
end

--- Display an informational message.
---@param ... any # The message(s) to log.
function Logging.info(...)
    Logging.INSTANCE:info(...)
end

--- Display a warning message.
---@param ... any # The message(s) to log.
function Logging.warn(...)
    Logging.INSTANCE:warn(...)
end

--- Display an error message.
---@param ... any # The message(s) to log.
function Logging.error(...)
    Logging.INSTANCE:error(...)
end

--- Display a fatal error message.
---@param ... any # The message(s) to log.
function Logging.fatal(...)
    Logging.INSTANCE:fatal(...)
end

return Logging
