local ffi = require "ffi"

local name = "https.so"

if ffi.os == "Windows" then
    name = "https-" .. ffi.arch .. ".dll"
elseif ffi.os == "OSX" then
    name = "https-mac.so"
end

local search_paths = { "", (love.filesystem.getRealDirectory("lib/") or "") .. "/lib/" }

local ok, module
for _, search_path in ipairs(search_paths) do
    local path = search_path .. name
    ok, module = pcall(package.loadlib, path, "luaopen_https")

    if not module then
        ok = false
    end

    if ok then
        HTTPS_INFO = "Found at \"" .. path .. "\""
        break
    end
end

HTTPS_AVAILABLE = ok

if not ok then
    print("HTTPS module unavailable! Print HTTPS_INFO for more information")

    HTTPS_INFO = "Missing, tried:\n"
    for _, search_path in ipairs(search_paths) do
        HTTPS_INFO = HTTPS_INFO .. "  - " .. search_path .. name .. "\n"
    end
    HTTPS_INFO = HTTPS_INFO .. "HTTPS module not loaded"
    return
end

return module()
