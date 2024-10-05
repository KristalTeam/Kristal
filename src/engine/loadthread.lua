---@diagnostic disable: lowercase-global
require("love.image")
require("love.sound")

json = require("src.lib.json")

verbose = false

--[[if love.filesystem.getInfo("mods/example/_GENERATED_FROM_MOD_TEMPLATE") then
    love.filesystem.mount("mod_template/assets", "mods/example/assets")
    love.filesystem.mount("mod_template/scripts", "mods/example/scripts")
end]]

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
    for _, v in ipairs({ ... }) do
        if path:sub(- #v - 1):lower() == "." .. v then
            return path:sub(1, - #v - 2), v
        end
    end
end

function combinePath(baseDir, subDir, path)
    local s = subDir
    if baseDir ~= "" then
        s = baseDir .. "/" .. s
    end
    if path ~= "" then
        s = s .. "/" .. path
    end
    if s:sub(-1, -1) == "/" then
        s = s:sub(1, -2)
    end
    return s
end

function resetData()
    data = {
        mods = {},
        failed_mods = {},
        assets = {
            texture = {},
            texture_data = {},
            frame_ids = {},
            frames = {},
            fonts = {},
            font_data = {},
            font_bmfont_data = {},
            font_image_data = {},
            font_settings = {},
            sounds = {},
            sound_data = {},
            music = {},
            videos = {},
            bubble_settings = {},
        }
    }

    path_loaded = {
        ["mods"] = {},

        ["sprites"] = {},
        ["fonts"] = {},
        ["sounds"] = {},
        ["music"] = {},
        ["videos"] = {},
        ["bubbles"] = {},
    }

    tileset_image_data = {}
end

local loaders = {

    -- Mod Loader

    ["mods"] = { "mods", function (base_dir, path, full_path)
        local zip_id = checkExtension(path, "zip")
        if zip_id then
            local mounted_path = full_path
            full_path = combinePath(base_dir, "mods", zip_id)
            path = zip_id
            love.filesystem.mount(mounted_path, full_path)
        end
        if love.filesystem.getInfo(full_path .. "/mod.json") then
            local ok, mod = pcall(json.decode, love.filesystem.read(full_path .. "/mod.json"))

            if love.filesystem.getInfo(full_path .. "/_GENERATED_FROM_MOD_TEMPLATE") then
                full_path = "mod_template"
            end

            if not ok then
                table.insert(data.failed_mods, {
                    path = path,
                    error = mod,
                    file = "mod.json"
                })
                print("[WARNING] Mod \"" .. path .. "\" has an invalid mod.json!")
                return
            end

            mod.id = mod.id or path
            mod.folder = path
            mod.path = full_path

            if love.filesystem.getInfo(full_path .. "/preview.lua") then
                mod.preview_script_path = full_path .. "/preview.lua"
            end

            if love.filesystem.getInfo(full_path .. "/bg.png") then
                pcall(function () mod.preview_data = { love.image.newImageData(full_path .. "/bg.png") } end)
                -- To check if the image loaded successfully, check if pcall returned true and mod.preview_data != nil
                -- Same goes for all the other assignments I changed
            end

            if love.filesystem.getInfo(full_path .. "/icon.png") then
                pcall(function () mod.icon_data = { love.image.newImageData(full_path .. "/icon.png") } end)
            end

            if love.filesystem.getInfo(full_path .. "/window_icon.png") then
                pcall(function () mod.window_icon_data = love.image.newImageData(full_path .. "/window_icon.png") end)
            end

            if love.filesystem.getInfo(full_path .. "/logo.png") then
                pcall(function () mod.logo_data = love.image.newImageData(full_path .. "/logo.png") end)
            end

            local music_extensions = { "mp3", "ogg", "wav" }
            for _, ext in ipairs(music_extensions) do
                if love.filesystem.getInfo(full_path .. "/preview." .. ext) then
                    mod.preview_music_path = full_path .. "/preview." .. ext
                    break
                end
            end

            if love.filesystem.getInfo(full_path .. "/preview") then
                for _, file in ipairs(love.filesystem.getDirectoryItems(full_path .. "/preview")) do
                    if file == "preview.lua" then
                        mod.preview_script_path = full_path .. "/preview/preview.lua"
                    elseif file == "preview.ogg" or file == "preview.mp3" or file == "preview.wav" then
                        mod.preview_music_path = full_path .. "/preview/" .. file
                    elseif file:sub(-4) == ".png" then
                        local img_name = file:sub(1, -4)
                        local img_num
                        for i = -3, -1 do
                            img_num = tonumber(img_name:sub(i))
                            if img_num then
                                img_name = img_name:sub(1, i - 1)
                                break
                            end
                        end
                        if file:sub(1, 2) == "bg" then
                            mod.preview_data = mod.preview_data or {}
                            if img_num then
                                pcall(function ()
                                    mod.preview_data[img_num] = love.image.newImageData(full_path ..
                                        "/preview/" .. file)
                                end)
                            else
                                -- A very hacky fix, don't know enough to make a better one
                                local imageData = nil
                                -- Only insert if the creation of ImageData actually succeeded
                                if pcall(function () imageData = love.image.newImageData(full_path .. "/preview/" .. file) end) and imageData then
                                    table.insert(mod.preview_data, 1,
                                                 love.image.newImageData(full_path .. "/preview/" .. file))
                                end
                            end
                        elseif file:sub(1, 4) == "icon" then
                            mod.icon_data = mod.icon_data or {}
                            if img_num then
                                pcall(function ()
                                    mod.icon_data[img_num] = love.image.newImageData(full_path ..
                                        "/preview/" .. file)
                                end)
                            else
                                local imageData = nil
                                if (pcall(function ()
                                    imageData = love.image.newImageData(full_path .. "/preview/" ..
                                        file)
                                end)) and imageData then
                                    table.insert(mod.icon_data, 1, love.image.newImageData(full_path .. "/preview/" ..
                                        file))
                                end
                            end
                        elseif file:sub(1, 4) == "logo" then
                            pcall(function () mod.logo_data = love.image.newImageData(full_path .. "/preview/" .. file) end)
                        end
                    end
                end
            end

            mod.libs = mod.libs or {}

            if love.filesystem.getInfo(full_path .. "/libraries") then
                for _, lib_path in ipairs(love.filesystem.getDirectoryItems(full_path .. "/libraries")) do
                    local lib_full_path = full_path .. "/libraries/" .. lib_path
                    local lib_zip_id = checkExtension(lib_path, "zip")
                    if lib_zip_id then
                        local mounted_path = lib_full_path
                        lib_full_path = full_path .. "/libraries/" .. lib_zip_id
                        lib_path = lib_zip_id
                        love.filesystem.mount(mounted_path, lib_full_path)
                    end

                    local lib = {}

                    ok = true

                    if love.filesystem.getInfo(lib_full_path .. "/lib.json") then
                        ok, lib = pcall(json.decode, love.filesystem.read(lib_full_path .. "/lib.json"))
                    end

                    if not ok then
                        table.insert(data.failed_mods, {
                            path = path,
                            error = lib,
                            file = "lib.json"
                        })
                        print("[WARNING] Mod \"" .. path .. "\" has a library with an invalid lib.json!")
                        return
                    end

                    lib.id = lib.id or lib_path
                    lib.folder = lib_path
                    lib.path = lib_full_path

                    mod.libs[lib.id] = lib
                end
            end

            -- Fail mod loading if library dependencies are unfulfilled
            for _, lib in pairs(mod.libs) do
                for _, dependency in ipairs(lib["dependencies"] or {}) do
                    if not mod.libs[dependency] then
                        local error = "Library '" .. lib.id .. "' depends on library '" .. dependency .. "' but it could not be found."
                        table.insert(data.failed_mods, {
                            path = path,
                            error = error,
                            file = "lib.json"
                        })
                        print("[WARNING] Issue loading mod \"" .. path .. "\" - " .. error)
                        return
                    end
                end
            end

            data.mods[mod.id] = mod
        end
    end },

    -- Asset Loaders

    ["sprites"] = { "assets/sprites", function (base_dir, path, full_path)
        local id = checkExtension(path, "png", "jpg")
        if id then
            local ok = pcall(function () data.assets.texture_data[id] = love.image.newImageData(full_path) end)
            if not ok then
                error("Image \"" .. path .. "\" is invalid or corrupted!")
            end
            for i = 3, 1, -1 do
                local num = tonumber(id:sub(-i))
                local bad_index = (num ~= num) or --NaN check
                                  (num == 1/0) or
                                  (num == -1/0)
                if num and (not bad_index) then
                    local frame_name = id:sub(1, -i - 1)
                    if frame_name:sub(-1, -1) == "_" then
                        frame_name = frame_name:sub(1, -2)
                    end
                    data.assets.frame_ids[frame_name] = data.assets.frame_ids[frame_name] or {}
                    data.assets.frame_ids[frame_name][num] = id
                    break
                end
            end
        end
    end },
    ["fonts"] = { "assets/fonts", function (base_dir, path, full_path)
        local id = checkExtension(path, "ttf")
        if id then
            pcall(function () data.assets.font_data[id] = love.filesystem.newFileData(full_path) end)
        end
        id = checkExtension(path, "fnt")
        if id then
            pcall(function () data.assets.font_bmfont_data[id] = full_path end)
        end
        id = checkExtension(path, "png")
        if id then
            pcall(function () data.assets.font_image_data[id] = love.image.newImageData(full_path) end)
        end
        id = checkExtension(path, "json")
        if id then
            local ok, loaded_data = pcall(json.decode, love.filesystem.read(full_path))
            if not ok then
                error("Font \"" .. path .. "\" has an invalid json file!")
            end
            data.assets.font_settings[id] = loaded_data
        end
    end },
    ["sounds"] = { "assets/sounds", function (base_dir, path, full_path)
        local id = checkExtension(path, "wav", "ogg")
        if id then
            pcall(function () data.assets.sound_data[id] = love.sound.newSoundData(full_path) end)
        end
    end },
    ["music"] = { "assets/music", function (base_dir, path, full_path)
        local id = checkExtension(path, "mp3", "wav", "ogg",
            -- TRACKER FORMATS
            "mod", "s3m", "xm", "it", "669", "amf", "ams", "dbm", "dmf", "dsm", "far",
            "mdl", "med", "mtm", "okt", "ptm", "stm", "ult", "umx", "mt2", "psm",
            -- COMPRESSED TRACKER FORMATS
            "mdz", "s3z", "xmz", "itz", "zip",
            "mdr", "s3r", "xmr", "itr", "rar",
            "mdgz", "s3gz", "xmgz", "itgz", "gz"
        )
        if id then
            data.assets.music[id] = full_path
        end
    end },
    ["videos"] = { "assets/videos", function (base_dir, path, full_path)
        local id = checkExtension(path, "ogg", "ogv")
        if id then
            data.assets.videos[id] = full_path
        end
        if checkExtension(path, "mp4", "mov", "wmv", "flv", "avi", "webm", "mkv") then
            error("\"" .. path .. "\" unsupported - must use Ogg Theora videos.")
        end
    end },
    ["bubbles"] = { "assets/bubbles", function (base_dir, path, full_path)
        local id = checkExtension(path, "json")
        if id then
            local ok, loaded_data = pcall(json.decode, love.filesystem.read(full_path))
            if not ok then
                error("Bubble \"" .. path .. "\" has an invalid json file!")
            end
            data.assets.bubble_settings[id] = loaded_data
        end
    end },
}

function loadPath(baseDir, loader, path, pre)
    if path_loaded[loader][path] then return end

    if verbose then
        out_channel:push({ status = "loading", loader = loader, path = path })
    end

    path_loaded[loader][path] = true

    if path:sub(-1, -1) == "*" then
        local dirs = path:split("/")
        local parent_path = ""
        for i = 1, #dirs - 1 do
            parent_path = parent_path .. (i > 1 and "/" or "") .. dirs[i]
        end
        loadPath(baseDir, loader, parent_path, dirs[#dirs]:sub(1, -2))
        return
    end

    local full_path = combinePath(baseDir, loaders[loader][1], path)
    local info = love.filesystem.getInfo(full_path)
    if info then
        if info.type == "directory" and (loader ~= "mods" or path == "") then
            local files = love.filesystem.getDirectoryItems(full_path)
            for _, file in ipairs(files) do
                if not pre or pre == "" or file:sub(1, #pre) == pre then
                    local new_path = (path == "" or path:sub(-1, -1) == "/") and (path .. file) or (path .. "/" .. file)
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
    if msg == "verbose" then
        verbose = true
    elseif msg == "stop" then
        break
    else
        local key = msg.key or 0
        local baseDir = msg.dir or ""
        local loader = msg.loader
        local paths = msg.paths or { "" }
        if type(msg.paths) == "string" then
            paths = { msg.paths }
        end

        if loader == "all" then
            for k, _ in pairs(loaders) do
                -- dont load mods when we load with "all"
                if k ~= "mods" then
                    for _, path in ipairs(paths) do
                        loadPath(baseDir, k, path)
                    end
                end
            end
        else
            for _, path in ipairs(paths) do
                loadPath(baseDir, loader, path)
            end
        end

        out_channel:push({ key = key, status = "finished", data = data })
        resetData()
    end
end
