local fs = require("src.engine.pack.fsutils")
local path = fs.path

local Pack = {}

Pack.tasks = {}
Pack.logs = {}

Pack.compileMatrix = {
    -- This determines which systems support which targets
    Windows = {"Windows"},
    Linux = {"Windows"}
}

function Pack:error(modID, err)
    table.insert(self.logs, {
        issuer = modID,
        t = "error",
        msg = err
    })
    self.tasks[modID] = nil
end

function Pack:log(modID, msg)
    table.insert(self.logs, {
        issuer = modID,
        t = "info",
        msg = msg
    })
end

--- Fetch the latest log from the stack
--- @param modID string
--- @return table|nil
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
        return false
    end
    self.tasks[modID] = {
        status = "prepare",
        info = nil,
        opts = opts or {
            autoStart = true,
            target = "Windows"
        },
        outChan = nil
    }

    local target = self.tasks[modID].opts.target
    local system = love.system.getOS()

    if self.compileMatrix[system] ~= nil then
        local availableTarget = false
        for _, t in ipairs(self.compileMatrix[system]) do
            if t == target then
                availableTarget = true
            end
        end
        if availableTarget == false then
            self:error(modID, system.." -> "..target.." is not supported yet. Sorry!")
            return
        end
    else
        self:error(modID, "Your system is not in the list of supported ones. Sorry!")
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

    ok = love.filesystem.createDirectory(path(wd, "out"))
    if not ok then
        self:error(modID, "Could not create output directory")
        return
    end


    local major, minor = love.getVersion()
    local loveVersion = tostring(major) .. "." .. tostring(minor)
    local loveLink
    if target == "Windows" then
        loveLink = "https://github.com/love2d/love/releases/download/" ..
        loveVersion .. "/love-" .. loveVersion .. "-win64.zip"
    else
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
            self:status(modID, "waitingEngine")
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
                    self.tasks[modID] = nil
                end
            end
        end
    end
end

function Pack:flushAllLogsToConsole()
    while #self.logs > 0 do
        local log = table.remove(self.logs, 1)
        if log.t == "info" then
            Kristal.Console:log("["..log.issuer.."] "..log.msg)
        elseif log.t == "error" then
            Kristal.Console:error("["..log.issuer.."] "..log.msg)
        end
    end
end

return Pack
