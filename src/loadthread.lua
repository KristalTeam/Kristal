require("love.image")

json = require("src.lib.json")

function string.split(str, sep, remove_empty)
    local t = {}
    local i = 1
    local s = ""
    while i <= #str do
        if str:sub(i, i + (#sep - 1)) == sep then
            if not remove_empty or s ~= "" then
                table.insert(t, s)
            end
            s = ""
            i = i + (#sep - 1)
        else
            s = s .. str:sub(i, i)
        end
        i = i + 1
    end
    if not remove_empty or s ~= "" then
        table.insert(t, s)
    end
    return t
end

function checkExtension(path, ...)
    for _,v in ipairs({...}) do
        if path:sub(-#v - 1):lower() == "."..v then
            return path:sub(1, -#v - 2), v
        end
    end
end

function combinePath(baseDir, subDir, path)
    local s = subDir
    if baseDir ~= "" then
        s = baseDir.."/"..s
    end
    if path ~= "" then
        s = s.."/"..path
    end
    if s:sub(-1, -1) == "/" then
        s = s:sub(1, -2)
    end
    return s
end

function resetData()
    data = {
        mods = {},
        assets = {
            texture = {},
            texture_data = {},
            frame_ids = {},
            frames = {},
            fonts = {}
        },
        data = {
            animations = {}
        }
    }

    path_loaded = {
        ["mods"] = {},
    
        ["sprites"] = {},
        ["fonts"] = {},
    
        ["animations"] = {}
    }
end

local loaders = {

    -- Mod Loader

    ["mods"] = {"mods", function(baseDir, path, full_path)
        if love.filesystem.getInfo(full_path.."/mod.json") then
            local mod = json.decode(love.filesystem.read(full_path.."/mod.json"))

            mod.id = mod.id or path
            mod.full_path = full_path

            if mod.preview then
                if type(mod.preview) == "string" then
                    mod.preview_data = {love.image.newImageData(full_path.."/"..mod.preview)}
                else
                    mod.preview_data = {}
                    for _,preview_path in ipairs(mod.preview) do
                        table.insert(mod.preview_data, love.image.newImageData(full_path.."/"..preview_path))
                    end
                end
            end

            data.mods[mod.id] = mod
        end
    end},

    -- Asset Loaders

    ["sprites"] = {"assets/sprites", function(baseDir, path, full_path)
        local id = checkExtension(path, "png", "jpg")
        if id then
            data.assets.texture_data[id] = love.image.newImageData(full_path)
            for i = 1,3 do
                local num = tonumber(id:sub(-i))
                if num then
                    local frame_name = id:sub(1, -i - 1)
                    if frame_name:sub(-1, -1) == "_" then
                        frame_name = frame_name:sub(1, -2)
                    end
                    data.assets.frame_ids[frame_name] = data.assets.frame_ids[frame_name] or {}
                    data.assets.frame_ids[frame_name][num] = id
                end
            end
        end
    end},
    ["fonts"] = {"assets/fonts", function(baseDir, path, full_path)
        local id = checkExtension(path, "ttf")
        if id then
            data.assets.fonts[id] = full_path
        end
    end},

    -- Data Loaders

    ["animations"] = {"data/animations", function(baseDir, path, full_path)
        if checkExtension(path, "json") then
            local json_str = love.filesystem.read(full_path)
            local animations = json.decode(json_str)
            for k,v in pairs(animations) do
                data.data.animations[k] = v
            end
        end
    end}
}

function loadPath(baseDir, loader, path, pre)
    if path_loaded[loader][path] then return end

    path_loaded[loader][path] = true

    if path:sub(-1, -1) == "*" then
        local dirs = path:split("/")
        local parent_path = ""
        for i = 1,#dirs-1 do
            parent_path = parent_path..(i > 1 and "/" or "")..dirs[i]
        end
        loadPath(baseDir, loader, parent_path, dirs[#dirs]:sub(1, -2))
        return
    end

    local full_path = combinePath(baseDir, loaders[loader][1], path)
    local info = love.filesystem.getInfo(full_path)
    if info then
        if info.type == "directory" and (loader ~= "mods" or path == "") then
            local files = love.filesystem.getDirectoryItems(full_path)
            for _,file in ipairs(files) do
                if not pre or pre == "" or file:sub(1, #pre) == pre then
                    local new_path = (path == "" or path:sub(-1, -1) == "/") and (path..file) or (path.."/"..file)
                    loadPath(baseDir, loader, new_path)
                end
            end
        else
            loaders[loader][2](baseDir, path, combinePath(baseDir, loaders[loader][1], path))
        end
    end
end

-- Channels for thread communications
in_channel = love.thread.getChannel("load_in")
out_channel = love.thread.getChannel("load_out")

-- Reset data once first
resetData()

-- Thread loop
while true do
    local msg = in_channel:demand()
    if msg == "stop" then
        break
    else
        local key = msg.key or 0
        local baseDir = msg.dir or ""
        local loader = msg.loader
        local paths = msg.paths or {""}
        if type(msg.paths) == "string" then
            paths = {msg.paths}
        end

        if loader == "all" then
            for k,_ in pairs(loaders) do
                -- dont load mods when we load with "all"
                if k ~= "mods" then
                    for _,path in ipairs(paths) do
                        loadPath(baseDir, k, path)
                    end
                end
            end
        else
            for _,path in ipairs(paths) do
                loadPath(baseDir, loader, path)
            end
        end

        out_channel:push({key = key, data = data})
        resetData()
    end
end