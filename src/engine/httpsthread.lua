local major, _, _, _ = love.getVersion()

if major >= 12 then
    ---@diagnostic disable-next-line: lowercase-global
    https = require("https")
    HTTPS_AVAILABLE = true
else
    ---@diagnostic disable-next-line: lowercase-global, different-requires
    https = require("src.lib.https")
end

-- Channels for thread communications
local in_channel = love.thread.getChannel("https_in")
local out_channel = love.thread.getChannel("https_out")

-- Thread loop
while true do
    local msg = in_channel:demand()
    if msg == "stop" then
        break
    else
        local key = msg.key or 0
        local url = msg.url
        local method = msg.method or "get"
        local headers = msg.headers or {}
        local data = msg.data or nil

        local response, body, out_headers = https.request(url, {
            method = method,
            data = data,
            headers = headers
        })

        out_channel:push({
            key = key,
            response = response,
            body = body,
            headers = out_headers
        })
    end
end
