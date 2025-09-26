---@diagnostic disable: lowercase-global
local SYSTEM, INFO_OBJ, OPTS, OUT_CHAN = ...
local zip = require("src.lib.zip")
local fs = require("src.engine.pack.fsutils")
local path = fs.path

local MODID = INFO_OBJ.id
local paths = fs.modPaths(MODID)
local ENGINEDIR = path(paths.build, "kristal")

local function status(msg)
    OUT_CHAN:push({ t = "log", msg = msg })
end

local function error(err)
    OUT_CHAN:push({ t = "err", err = err })
end

local function createExe()
    status("Extracting LOVE zip...")
    err = fs.extractZIP(path(paths.build, "love.zip"), paths.build)
    if err ~= nil then
        error(err)
        return
    end

    local loveDir = path(paths.build, "love-11.5-win64") -- hardcoded for now, will change when caching is implemented

    local outDir = path(paths.build, "win")
    love.filesystem.createDirectory(outDir)

    fs.fuseFiles(
        path(loveDir, "love.exe"),
        path(paths.build, "game.love"),
        path(outDir, MODID .. ".exe")
    )
    fs.recursiveCopy(loveDir, outDir, { ".ico$", "readme.txt", "changes.txt", ".exe$" })

    status("Packing up...")
    zip:compressToArchive(outDir, paths.dist, MODID .. "-win.zip")
end

status("Copying engine files...")
fs.recursiveCopy("", ENGINEDIR, { "^" .. love.filesystem.getSaveDirectory() })

status("Copying mod...")
love.filesystem.createDirectory(path(ENGINEDIR, "mods", MODID))
fs.recursiveCopy(INFO_OBJ.path, path(ENGINEDIR, "mods", MODID))

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
