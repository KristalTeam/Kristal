---@class EditorLSPClient : Class
---@field handlers function?
---@field next_id number
---@field pending table
---@field sender function?
---@overload fun(sender: function, handlers?: table): EditorLSPClient
local EditorLSPClient = Class()

function EditorLSPClient:init(sender, handlers)
    self.sender = sender
    self.handlers = handlers or {}
    self.next_id = 1
    self.pending = {}
end

function EditorLSPClient:send(message)
    local success, encoded = pcall(JSON.encode, message)
    if not success then return false, encoded end
    return self.sender(encoded)
end

function EditorLSPClient:notify(method, params)
    return self:send(JSON.object({ jsonrpc = "2.0", method = method,
        params = params == nil and JSON.object({}) or params }))
end

function EditorLSPClient:request(method, params, callback)
    local id = self.next_id
    self.next_id = id + 1
    self.pending[id] = { method = method, callback = callback }
    local sent, reason = self:send(JSON.object({ jsonrpc = "2.0", id = id, method = method,
        params = params == nil and JSON.object({}) or params }))
    if sent == false then self.pending[id] = nil return nil, reason end
    return id
end

function EditorLSPClient:respond(id, result, response_error)
    local message = JSON.object({ jsonrpc = "2.0", id = id })
    if response_error then message.error = response_error else message.result = result or JSON.null end
    return self:send(message)
end

function EditorLSPClient:receive(encoded)
    local success, message = pcall(JSON.decode, encoded)
    if not success or type(message) ~= "table" then
        if self.handlers.protocolError then self.handlers.protocolError(tostring(message)) end
        return false
    end
    if message.id ~= nil and message.method == nil then
        local pending = self.pending[message.id]
        self.pending[message.id] = nil
        if pending and pending.callback then pending.callback(message.result, message.error, message) end
        return true
    end
    if message.method then
        local handler = self.handlers[message.method]
        if handler then
            local result, response_error = handler(message.params or {}, message)
            if message.id ~= nil then self:respond(message.id, result, response_error) end
        elseif message.id ~= nil then
            self:respond(message.id, nil, { code = -32601, message = "Method not supported: " .. message.method })
        end
        return true
    end
    return false
end

return EditorLSPClient
