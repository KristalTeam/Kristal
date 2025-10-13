---@diagnostic disable: lowercase-global
local LOVE_VERSION, MOD_INFO, BUILD_OPTS, OUT_CHAN = ...
local zip = require("src.lib.zip")
local fs = require("src.engine.pack.fsutils")
local path = fs.path

local MODID = MOD_INFO.id
local paths = fs.modPaths(MODID)
local ENGINEDIR = path(paths.build, "kristal")

local function status(msg)
    OUT_CHAN:push({ t = "log", msg = msg })
end

local function error(err)
    OUT_CHAN:push({ t = "err", err = err })
end

local function createExe()
    status("Creating exe...")
    local outDir = path(paths.build, "win")
    love.filesystem.createDirectory(outDir)

    local archiveNames = fs.archiveNames(LOVE_VERSION)
    local loveSource = path(paths.cache, LOVE_VERSION, archiveNames[BUILD_OPTS.target].name)

    fs.fuseFiles(
        path(loveSource, "love.exe"),
        path(paths.build, "game.love"),
        path(outDir, MODID .. ".exe")
    )
    fs.recursiveCopy(loveSource, outDir, { ".ico$", "readme.txt", "changes.txt", ".exe$" })

    status("Packing up...")
    zip:compressToArchive(outDir, paths.dist, MODID .. "-win.zip")
end

status("Copying engine files...")
local packIgnoreFile = love.filesystem.read(".packignore")
local packIgnore = {}
for s in string.gmatch(packIgnoreFile, "([^\n]+)") do
    local source = love.filesystem.getSource()
    table.insert(packIgnore, "^"..path(source, s))
end
table.insert(packIgnore, "^" .. love.filesystem.getSaveDirectory())
fs.recursiveCopy("", ENGINEDIR, packIgnore)

status("Copying mod...")
love.filesystem.createDirectory(path(ENGINEDIR, "mods", MODID))
fs.recursiveCopy(MOD_INFO.path, path(ENGINEDIR, "mods", MODID))

status("Setting up engine...")
local vendPath = path(ENGINEDIR, "src", "engine", "vendcust.lua")
local vend = love.filesystem.read(vendPath)
vend = vend:gsub("TARGET_MOD = nil", 'TARGET_MOD = "' .. MODID .. '"')
if BUILD_OPTS.autoStart then
    vend = vend:gsub("AUTO_MOD_START = false", "AUTO_MOD_START = true")
end
love.filesystem.write(vendPath, vend)

local confPath = path(ENGINEDIR, "conf.lua")
local conf = love.filesystem.read(confPath)
conf = conf:gsub('t.identity = "kristal"', 't.identity = "' .. MODID .. '"')
conf = conf:gsub('t.window.title = "Kristal"', 't.window.title = "' .. MOD_INFO.name .. '"')
love.filesystem.write(confPath, conf)

local realWD = love.filesystem.getRealDirectory(paths.build)
zip:compressToArchive(ENGINEDIR, paths.build, "game.zip")

local realModPath = path(realWD, paths.build, "game.zip")
os.rename(realModPath, realModPath:gsub("game.zip", "game.love"))

if BUILD_OPTS.target == "Windows" then
    createExe()
end

local realWorkingDir = path(love.filesystem.getRealDirectory(paths.build), paths.build)
OUT_CHAN:push({ t = "success", open = realWorkingDir })
