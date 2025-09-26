---@diagnostic disable: lowercase-global
local SYSTEM, INFO_OBJ, OPTS, OUT_CHAN = ...
local zip = require("src.lib.zip")
local fs = require("src.engine.pack.fsutils")
local path = fs.path

local MODID = INFO_OBJ.id
local paths = fs.modPaths(MODID)
local LOVEDIR = path(paths.build, "love")
love.filesystem.createDirectory(LOVEDIR)
local ENGINEDIR = path(paths.build, "kristal")

local function status(msg)
    OUT_CHAN:push({ t = "log", msg = msg })
end

local function error(err)
    OUT_CHAN:push({ t = "err", err = err })
end

local function copy(from, to)
    local contents = love.filesystem.read(from)
    return love.filesystem.write(to, contents)
end

local function recursiveCopy(folder, to, excludePattern)
    excludePattern = excludePattern or {}

    local filesTable = love.filesystem.getDirectoryItems(folder)
    for _, v in ipairs(filesTable) do
        local file = path(folder, v)
        local saveFile = path(to, v)
        local realDir = path(love.filesystem.getRealDirectory(file), file)
        local exclude = false
        for _, pat in ipairs(excludePattern) do
            if realDir:find(pat) ~= nil then
                exclude = true
            end
        end
        if exclude == false then
            local info = love.filesystem.getInfo(file)
            if info then
                if info.type == "file" then
                    print("Copying file " .. file .. " to " .. saveFile)
                    local ok, err = copy(file, saveFile)
                    if not ok then
                        print("Error: " .. err)
                    end
                elseif info.type == "directory" then
                    print("Traversing " .. file)
                    love.filesystem.createDirectory(saveFile)
                    recursiveCopy(file, saveFile, excludePattern)
                end
            end
        end
    end
end

-- local function recursiveDel(folder)
-- 	local filesTable = love.filesystem.getDirectoryItems(folder)
-- 	for _,v in ipairs(filesTable) do
-- 		local file = path(folder, v)
--         local info = love.filesystem.getInfo(file)
--         if info then
--             if info.type == "file" then
--                 print("Removing "..file)
--                 love.filesystem.remove(file)
--             elseif info.type == "directory" then
--                 print("Traversing "..file)
--                 recursiveDel(file)
--                 love.filesystem.remove(file)
--             end
--         end
-- 	end
-- end

local function extractZIP(file, saveIn)
    local ok = love.filesystem.mount(file, "lovezip")
    if not ok then
        return "Could not mount the file"
    end
    local outerFolder = love.filesystem.getDirectoryItems("lovezip")
    outerFolder = outerFolder[1]
    local filesFolder = love.filesystem.getDirectoryItems(path("lovezip", outerFolder))
    for _, f in ipairs(filesFolder) do
        local fullPath = path("lovezip", outerFolder, f)
        love.filesystem.write(path(saveIn, f), tostring(love.filesystem.read(fullPath)))
    end
    love.filesystem.unmount(file)
end

local function fuseFiles(file1, file2, out)
    local f1 = love.filesystem.read(file1)
    local f2 = love.filesystem.read(file2)
    return love.filesystem.write(out, f1 .. f2)
end

local function createExe()
    local outDir = path(paths.build, "win")
    love.filesystem.createDirectory(outDir)

    fuseFiles(
        path(LOVEDIR, "love.exe"),
        path(paths.build, "game.love"),
        path(outDir, MODID .. ".exe")
    )
    recursiveCopy(LOVEDIR, outDir, { ".ico$", "readme.txt", "changes.txt", ".exe$" })

    status("Packing up...")
    zip:compressToArchive(outDir, paths.dist, MODID .. "-win.zip")
end

status("Extracting LOVE zip...")
err = extractZIP(path(paths.build, "love.zip"), LOVEDIR)
if err ~= nil then
    error(err)
    return
end

status("Copying engine files...")
recursiveCopy("", ENGINEDIR, { "^" .. love.filesystem.getSaveDirectory() })

status("Copying mod...")
love.filesystem.createDirectory(path(ENGINEDIR, "mods", MODID))
recursiveCopy(INFO_OBJ.path, path(ENGINEDIR, "mods", MODID))

status("Setting up engine...")
local vendPath = path(ENGINEDIR, "src", "engine", "vendcust.lua")
local vend = love.filesystem.read(vendPath)
vend = vend:gsub("TARGET_MOD = nil", 'TARGET_MOD = "' .. MODID .. '"')
if OPTS.autoStart then
    vend = vend:gsub("AUTO_MOD_START = false", "AUTO_MOD_START = true")
end
love.filesystem.write(vendPath, vend)

local confPath = path(ENGINEDIR, "conf.lua")
local conf = love.filesystem.read(confPath)
conf = conf:gsub('t.identity = "kristal"', 't.identity = "' .. MODID .. '"')
conf = conf:gsub('t.window.title = "Kristal"', 't.window.title = "' .. INFO_OBJ.name .. '"')
love.filesystem.write(confPath, conf)

local realWD = love.filesystem.getRealDirectory(paths.build)
zip:compressToArchive(ENGINEDIR, paths.build, "game.zip")

local realModPath = path(realWD, paths.build, "game.zip")
os.rename(realModPath, realModPath:gsub("game.zip", "game.love"))

if OPTS.target == "Windows" then
    createExe()
end

local realWorkingDir = path(love.filesystem.getRealDirectory(paths.build), paths.build)
OUT_CHAN:push({ t = "success", open = realWorkingDir })
