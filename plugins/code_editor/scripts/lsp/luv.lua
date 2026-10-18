local LuvLoader = { available = false, module = nil, dependency = nil, error = nil }

local function nativeFiles(ffi)
    if ffi.os == "Windows" then
        return "luv-windows-" .. ffi.arch .. ".dll"
    elseif ffi.os == "OSX" then
        return "luv-macos-" .. ffi.arch .. ".so", "libuv-macos-" .. ffi.arch .. ".dylib"
    elseif ffi.os == "Linux" then
        return "luv-linux-" .. ffi.arch .. ".so", "libuv-linux-" .. ffi.arch .. ".so.1"
    end
end

function LuvLoader.load(plugin_path)
    if LuvLoader.module then return LuvLoader.module end
    local loaded, module = pcall(require, "luv")
    if loaded and type(module) == "table" then
        LuvLoader.available, LuvLoader.module = true, module
        return module
    end
    local ffi = require("ffi")
    local name, dependency_name = nativeFiles(ffi)
    if not name then return nil, "No bundled luv build supports " .. tostring(ffi.os) end
    local virtual_path = tostring(plugin_path or ""):gsub("\\", "/"):gsub("/+$", "")
        .. "/lib/" .. name
    local source_root = love.filesystem.getRealDirectory(virtual_path)
    local search_paths = { "" }
    if source_root then
        table.insert(search_paths, source_root:gsub("\\", "/"):gsub("/+$", "")
            .. "/" .. virtual_path:match("^/*(.*)$"):gsub("/[^/]+$", "/"))
    end
    local errors = {}
    for _, search_path in ipairs(search_paths) do
        local path = search_path .. name
        if dependency_name then
            local dependency_path = search_path .. dependency_name
            local dependency_loaded, dependency = pcall(ffi.load, dependency_path, true)
            if dependency_loaded then
                LuvLoader.dependency = dependency
            else
                table.insert(errors, dependency_path .. ": " .. tostring(dependency))
            end
        end
        local ok, loader = pcall(package.loadlib, path, "luaopen_luv")
        if ok and loader then
            local initialized, result = pcall(loader)
            if initialized and type(result) == "table" then
                LuvLoader.available, LuvLoader.module = true, result
                return result
            end
            table.insert(errors, path .. ": " .. tostring(result))
        else
            table.insert(errors, path .. ": " .. tostring(loader))
        end
    end
    LuvLoader.error = table.concat(errors, "\n")
    return nil, LuvLoader.error
end

return LuvLoader
