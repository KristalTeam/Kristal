local prefix, executable, encoded_args, cwd, plugin_path = ...
local input = love.thread.getChannel(prefix .. ":input")
local output = love.thread.getChannel(prefix .. ":output")

local function emit(kind, value)
    output:push(kind .. "\n" .. tostring(value or ""))
end

local function run()
    local JSON = require("src.lib.json")
    local loader_chunk, chunk_error = love.filesystem.load(plugin_path .. "/scripts/lsp/luv.lua")
    if not loader_chunk then emit("error", "Could not load luv loader:\n" .. tostring(chunk_error)) return end
    local uv, load_error = loader_chunk().load(plugin_path)
    if not uv then emit("error", "Could not load luv:\n" .. tostring(load_error)) return end
    local args = JSON.decode(encoded_args)
    local stdin, stdout, stderr = uv.new_pipe(false), uv.new_pipe(false), uv.new_pipe(false)
    local handle
    local buffer = ""
    local stopping = false

    local function close(target)
        if target and not target:is_closing() then target:close() end
    end

    local function parseMessages()
        while true do
            local header_end = buffer:find("\r\n\r\n", 1, true)
            if not header_end then return end
            local header = buffer:sub(1, header_end - 1)
            local length = tonumber(header:match("[Cc]ontent%-[Ll]ength:%s*(%d+)"))
            if not length then
                buffer = buffer:sub(header_end + 4)
                emit("error", "LuaLS sent an invalid LSP header: " .. header)
            elseif #buffer < header_end + 3 + length then
                return
            else
                local body_start = header_end + 4
                emit("message", buffer:sub(body_start, body_start + length - 1))
                buffer = buffer:sub(body_start + length)
            end
        end
    end

    local spawn_error
    handle = uv.spawn(executable, {
        args = args,
        cwd = cwd,
        stdio = { stdin, stdout, stderr },
        hide = true
    }, function(code, signal)
        emit("exit", tostring(code) .. ":" .. tostring(signal))
        close(stdin) close(stdout) close(stderr) close(handle)
        uv.stop()
    end)
    if not handle then
        spawn_error = "Could not start LuaLS executable: " .. tostring(executable)
        emit("error", spawn_error)
        close(stdin) close(stdout) close(stderr)
        return
    end

    stdout:read_start(function(err, data)
        if err then emit("error", err) end
        if data then buffer = buffer .. data parseMessages() end
    end)
    stderr:read_start(function(err, data)
        if err then emit("error", err) end
        if data and data ~= "" then emit("stderr", data) end
    end)

    local timer = uv.new_timer()
    timer:start(0, 10, function()
        while true do
            local command = input:pop()
            if not command then break end
            if command == "stop" then
                stopping = true
                if handle and not handle:is_closing() then handle:kill("sigterm") end
                break
            end
            local body = command:match("^send\n(.*)$")
            if body then
                stdin:write("Content-Length: " .. #body .. "\r\n\r\n" .. body)
            end
        end
        if stopping then timer:stop() close(timer) end
    end)
    emit("ready")
    uv.run()
end

local success, message = xpcall(run, debug.traceback)
if not success then emit("error", message) end
