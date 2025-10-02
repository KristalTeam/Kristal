local lib = {}

local msg_suffix = libRequire("speeb", "reqtest")

function lib:init()
    print("Loaded speeb library" .. msg_suffix)
end

return lib
