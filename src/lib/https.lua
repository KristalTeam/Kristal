local ffi = require "ffi"

if ffi.os == "Windows" then
    package.cpath = package.cpath .. ";./lib/?-" .. ffi.arch .. ".dll"
    package.cpath = package.cpath .. ";./?-" .. ffi.arch .. ".dll"
elseif ffi.os == "OSX" then
    package.cpath = package.cpath .. ";./lib/?-mac.so"
    package.cpath = package.cpath .. ";./?-mac.so"
else
    package.cpath = package.cpath .. ";./lib/?.so"
    --package.cpath = package.cpath .. ";./?.so"
end

local ok, module = pcall(require, "https")

HTTPS_AVAILABLE = ok

if not ok then
    return
end

return module