---@diagnostic disable: lowercase-global
local SYSTEM, INFO_OBJ, OPTS, OUT_CHAN = ...
local zip = require("src.lib.zip")

local function status(msg)
    OUT_CHAN:push({t = "log", msg = msg})
end

local function error(err)
    OUT_CHAN:push({t = "err", err = err})
end

local function copy(from, to)
    local contents = love.filesystem.read(from)
    return love.filesystem.write(to, contents)
end

local function recursiveCopy(folder, to, excludePattern)
    excludePattern = excludePattern or {}

	local filesTable = love.filesystem.getDirectoryItems(folder)
	for _,v in ipairs(filesTable) do
		local file = folder.."/"..v
        local saveFile = to.."/"..v
        local realDir = love.filesystem.getRealDirectory(file).."/"..file
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
                    print("Copying file "..file.." to "..saveFile)
                    local ok, err = copy(file, saveFile)
                    if not ok then
                        print("Error: "..err)
                    end
                elseif info.type == "directory" then
                    print("Traversing "..file)
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
-- 		local file = folder.."/"..v
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
    local filesFolder = love.filesystem.getDirectoryItems("lovezip/"..outerFolder)
    for _, f in ipairs(filesFolder) do
        local fullPath = "lovezip/"..outerFolder.."/"..f
        love.filesystem.write(saveIn.."/"..f, tostring(love.filesystem.read(fullPath)))
    end
	love.filesystem.unmount(file)
end

local function fuseFiles(file1, file2, out)
    local f1 = love.filesystem.read(file1)
    local f2 = love.filesystem.read(file2)
    return love.filesystem.write(out, f1..f2)
end

local modID = INFO_OBJ.id
local workingDirectory = "pack/"..modID

status("Extracting LOVE zip...")
err = extractZIP(workingDirectory.."/love.zip", workingDirectory.."/love")
if err ~= nil then
    error(err)
    return
end

local engineDir = workingDirectory.."/kristal"

status("Copying engine files...")
recursiveCopy("", engineDir, {"^"..love.filesystem.getSaveDirectory()})

status("Copying mod...")
love.filesystem.createDirectory(engineDir.."/mods/"..modID)
recursiveCopy(INFO_OBJ.path, engineDir.."/mods/"..modID)

status("Setting up engine...")
local vend = love.filesystem.read(engineDir.."/src/engine/vendcust.lua")
vend = vend:gsub("TARGET_MOD = nil", 'TARGET_MOD = "'..modID..'"')
if OPTS.autoStart then
    vend = vend:gsub("AUTO_MOD_START = false", "AUTO_MOD_START = true")
end
love.filesystem.write(engineDir.."/src/engine/vendcust.lua", vend)

local conf = love.filesystem.read(engineDir.."/conf.lua")
conf = conf:gsub('t.identity = "kristal"', 't.identity = "'..modID..'"')
conf = conf:gsub('t.window.title = "Kristal"', 't.window.title = "'..INFO_OBJ.name..'"')
love.filesystem.write(engineDir.."/conf.lua", conf)

status("Creating exe...")
local realModPath = love.filesystem.getRealDirectory(workingDirectory).."/"..workingDirectory.."/archive.zip"
zip:compressToArchive(engineDir, workingDirectory, "archive.zip")
os.rename(realModPath, realModPath:gsub("archive.zip", "archive.love"))

local outputDir = workingDirectory.."/out"
love.filesystem.createDirectory(outputDir)

fuseFiles(workingDirectory.."/love/love.exe", workingDirectory.."/archive.love", outputDir.."/"..modID..".exe")
recursiveCopy(workingDirectory.."/love", outputDir, {".ico$", "readme.txt", "changes.txt", ".exe$"})

status("Packing up...")
zip:compressToArchive(workingDirectory.."/out", workingDirectory, modID..".zip")

-- status("Cleaning up...")
-- love.filesystem.remove(workingDirectory.."/love.zip")
-- love.filesystem.remove(workingDirectory.."/archive.zip")
-- recursiveDel(workingDirectory.."/out")
-- recursiveDel(workingDirectory.."/kristal")
-- recursiveDel(workingDirectory.."/love")
-- love.filesystem.remove(workingDirectory.."/out")
-- love.filesystem.remove(workingDirectory.."/kristal")
-- love.filesystem.remove(workingDirectory.."/love")

local realWorkingDir = love.filesystem.getRealDirectory(workingDirectory).."/"..workingDirectory
OUT_CHAN:push({t = "success", open = realWorkingDir})