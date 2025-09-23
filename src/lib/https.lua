local ffi = require "ffi"

local name = "https.so"

if ffi.os == "Windows" then
    name = "https-" .. ffi.arch .. ".dll"
elseif ffi.os == "OSX" then
    name = "https-mac.so"
end

local search_paths = {"", "lib/"}

local ok, module
for _, search_path in ipairs(search_paths) do
    ok, module = pcall(package.loadlib, search_path .. name, "luaopen_https")

    if not module then
        ok = false
    end

    if ok then
        break
    end
end

HTTPS_AVAILABLE = ok

if not ok then
    return
end

return module()