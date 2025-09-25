local fs = require("src.engine.pack.fsutils")
local path = fs.path

local Pack = {}

Pack.tasks = {}

local SYSTEM = love.system.getOS()
local MAJOR, MINOR = love.getVersion()

function Pack:error(modID, err)
    self.tasks[modID].status = "terminated"
    self.tasks[modID].err = err
end

function Pack:log(modID, msg)
    table.insert(self.tasks[modID].log, msg)
end

function Pack:readLog(modID)
    if #self.tasks[modID].log == 0 then
        return nil
    end
    return table.remove(self.tasks[modID].log, 1)
end

function Pack:status(modID, status)
    self.tasks[modID].status = status
end

function Pack:package(modID, opts)
    if self.tasks[modID] ~= nil then
        if self.tasks[modID].status ~= "terminated" then
            return false
        end
    end
    self.tasks[modID] = {
        log = {},
        err = nil,
        status = "prepare",
        info = nil,
        opts = opts or {
            autoStart = true
        },
        outChan = nil
    }

    if SYSTEM ~= "Windows" then
        self:error(modID, "Unsupported system. Sorry!")
        return
    end
    local modInfo = Kristal.Mods.getMod(modID)
    if modInfo == nil then
        self:error(modID, "This mod does not exist.")
        return
    end
    self.tasks[modID].info = modInfo
    self:log(modID, "Packaging " .. modID)

    local wd = path("pack", modID)

    self:log(modID, "Creating skeleton...")
    local ok = love.filesystem.createDirectory(wd)
    if not ok then
        self:error(modID, "Could not create mod directory")
        return
    end

    ok = love.filesystem.createDirectory(path(wd, "love"))
    if not ok then
        self:error(modID, "Could not create LOVE engine directory")
        return
    end

    ok = love.filesystem.createDirectory(path(wd, "kristal"))
    if not ok then
        self:error(modID, "Could not create Kristal engine directory")
        return
    end

    local loveVersion = tostring(MAJOR) .. "." .. tostring(MINOR)
    local loveLink
    if SYSTEM == "Windows" then
        loveLink = "https://github.com/love2d/love/releases/download/" ..
        loveVersion .. "/love-" .. loveVersion .. "-win64.zip"
    else
        self:error(modID, "Unsupported system, sorry!")
        return
    end
    if loveLink == nil then
        self:error(modID, "Unsupported system, sorry!")
        return
    end
    self:log(modID, "Fetching LOVE engine...")
    Kristal.fetch(loveLink, {
        headers = {
            ["Accept"] = "application/zip"
        },
        callback = function (s, body, headers)
            if s < 200 or s > 299 then
                self:error(modID, "Could not download LOVE, status: " .. tostring(s))
                return
            end

            if body == nil then
                self:error(modID, "No body came")
                return
            end
            local ok, err = love.filesystem.write(path(wd, "love.zip"), body)
            if not ok then
                self:error(modID, "Could not open file, err: " .. err)
                return
            end
            self:status(modID, "fetchDone")
        end
    })
    return true
end

function Pack:update()
    for modID, info in pairs(self.tasks) do
        if info.status == "fetchDone" then
            local t = love.thread.newThread("src/engine/pack/fspack.lua")
            local outChan = love.thread.newChannel()
            t:start(love.system.getOS(), info.info, info.opts, outChan)
            self.tasks[modID].status = "waitingEngine"
            self.tasks[modID].outChan = outChan
        elseif info.status == "waitingEngine" then
            local obj = info.outChan:pop()
            if obj ~= nil then
                if obj.t == "log" then
                    self:log(modID, obj.msg)
                elseif obj.t == "err" then
                    self:error(modID, obj.err)
                elseif obj.t == "success" then
                    self:log(modID, "Success!")
                    if (love.system.getOS() == "Windows") then
                        os.execute('start /B \"\" \"'..obj.open.."\"")
                    else
                        love.system.openURL("file://"..obj.open)
                    end
                    self.tasks[modID].status = "terminated"
                end
            end
        end
    end
end

function Pack:flushAllLogsToConsole()
    for modID, info in pairs(self.tasks) do
        for _ = #info.log, 1, -1 do
            Kristal.Console:log(self:readLog(modID))
        end
    end
end

return Pack
