local Cutscene, super = Class()

function Cutscene:init(func, ...)
    self.wait_timer = 0
    self.wait_func = nil

    self.paused = false
    self.ended = false

    self.coroutine = coroutine.create(func)

    self.finished_callback = nil

    self:resume(self, ...)
end

function Cutscene:parseFromGetter(getter, cutscene, id, ...)
    self.getter = getter
    if type(cutscene) == "function" then
        return cutscene, {id, ...}
    elseif type(cutscene) == "string" then
        local dotsplit = Utils.split(cutscene, ".")
        if #dotsplit > 1 then
            local scene = getter(dotsplit[1], dotsplit[2])

            if scene then
                return scene, {id, ...}
            else
                error("No cutscene found: "..cutscene)
            end
        else
            local scene, grouped = getter(cutscene, id)
            if scene then
                if grouped then
                    return scene, {...}
                else
                    return scene, {id, ...}
                end
            else
                if type(id) == "string" then
                    error("No cutscene found: "..cutscene.."."..id)
                else
                    error("No cutscene found: "..cutscene)
                end
            end
        end
    end
end

function Cutscene:after(func)
    if self.ended then
        func(self)
        return
    end
    if self.finished_callback then
        local old = self.finished_callback
        self.finished_callback = function(...)
            old(...)
            func(...)
        end
    else
        self.finished_callback = func
    end
    return self
end

function Cutscene:canResume()
    if self.wait_timer > 0 or self.paused then
        return false
    end
    if self.wait_func then
        return self.wait_func(self)
    end
    return true
end

function Cutscene:canEnd()
    return true
end

function Cutscene:update(dt)
    if self.ended then return end

    self.wait_timer = Utils.approach(self.wait_timer, 0, dt)

    if coroutine.status(self.coroutine) == "suspended" then
        local result = {self:canResume()}
        if result[1] then
            table.remove(result, 1)
            self:resume(result)
        end
    elseif coroutine.status(self.coroutine) == "dead" and self:canEnd() then
        self:endCutscene()
    end
end

function Cutscene:onEnd()
    if self.finished_callback then
        self.finished_callback(self)
    end
end

function Cutscene:wait(seconds)
    if type(seconds) == "function" then
        self.wait_func = seconds
    else
        self.wait_timer = seconds or 0
    end
    return coroutine.yield()
end

function Cutscene:pause()
    self.paused = true
    return coroutine.yield()
end

function Cutscene:resume(...)
    self.paused = false
    self.wait_func = nil
    local ok, msg = coroutine.resume(self.coroutine, ...)
    if not ok then
        error(msg)
    end
end

function Cutscene:endCutscene()
    self.ended = true
    self:onEnd()
end

function Cutscene:gotoCutscene(func, ...)
    if self.getter then
        local new_func, args = self:parseFromGetter(self.getter, func, ...)
        return new_func(self, unpack(args))
    else
        return func(self, ...)
    end
end

return Cutscene