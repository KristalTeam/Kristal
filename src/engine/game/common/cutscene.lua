--- The underlying class for cutscene types in Kristal. \
--- See WorldCutscene, BattleCutscene, or LegendCutscene for the available functions when creating the respective cutscene types.
---
---@class Cutscene : Class
---@overload fun(...) : Cutscene
local Cutscene, super = Class()

function Cutscene:init(func, ...)
    self.wait_timer = 0
    self.wait_func = nil

    self.paused = false
    self.ended = false

    self.coroutine = coroutine.create(func)

    self.finished_callback = nil
    self.replaced_callback = false

    self.during_stack = {}

    self:resume(self, ...)
end

function Cutscene:parseFromGetter(getter, cutscene, id, ...)
    self.getter = getter
    if type(cutscene) == "function" then
        self.id = "<function>"
        return cutscene, {id, ...}
    elseif type(cutscene) == "string" then
        local dotsplit = Utils.split(cutscene, ".")
        if #dotsplit > 1 then
            local scene = getter(dotsplit[1], dotsplit[2])

            if scene then
                self.id = cutscene
                return scene, {id, ...}
            else
                error("No cutscene found: "..cutscene)
            end
        else
            local scene, grouped = getter(cutscene, id)
            if scene then
                if grouped then
                    self.id = cutscene.."."..id
                    return scene, {...}
                else
                    self.id = cutscene
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
    else
        error("Attempt to start nil cutscene")
    end
end

--- Adds a new callback to this cutscene.
---@param func      function    The callback function to set or append to this cutscene.
---@param replace   boolean     Whether or not to overwrite all previously defined callbacks on this function.
---@return Cutscene? self
function Cutscene:after(func, replace)
    if self.ended then
        if func and (replace or not self.replaced_callback) then
            func(self)
            if replace then
                self.replaced_callback = true
            end
        end
        return
    end
    if self.finished_callback and not replace then
        local old = self.finished_callback
        self.finished_callback = function(...)
            old(...)
            func(...)
        end
    else
        self.finished_callback = func
        if replace then
            self.replaced_callback = true
        end
    end
    return self
end

function Cutscene:during(func, replace)
    if self.ended then return end
    if replace then
        self.during_stack = {}
    end
    table.insert(self.during_stack, func)
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

--- *(Called internally)* *(Override)* Checks whether the cutscene is currently in a state to be ended.
---@return boolean can_end Whether the cutscene is able to be ended.
function Cutscene:canEnd()
    return true
end

function Cutscene:update()
    if self.ended then return end

    self.wait_timer = Utils.approach(self.wait_timer, 0, DT)

    if #self.during_stack > 0 and not self.paused then
        local to_remove = {}
        for _,func in ipairs(self.during_stack) do
            local result = func()
            if result == false then
                table.insert(to_remove, func)
            end
        end
        for _,v in ipairs(to_remove) do
            Utils.removeFromTable(self.during_stack, v)
        end
    end

    -- Check ended again, incase the cutscene is ended in a during callback
    if self.ended then return end

    if coroutine.status(self.coroutine) == "suspended" then
        self:tryResume()
    elseif coroutine.status(self.coroutine) == "dead" and self:canEnd() then
        self:endCutscene()
    end
end

--- *(Called internally)* Internal callback for when cutscenes end. \
--- Also responsible for calling user defined callbacks from Cutscene:after()
function Cutscene:onEnd()
    if self.finished_callback then
        self:finished_callback()
    end
end

--- Temporarily suspends execution of the cutscene script.
---@param seconds? function|number When a `number`, waits this number of seconds before continuing. When a `function`, waits until this function returns `true`. (Defaults to 0)
---@return any
function Cutscene:wait(seconds)
    if type(seconds) == "function" then
        self.wait_func = seconds
    else
        self.wait_timer = seconds or 0
    end
    return coroutine.yield()
end

--- Indefinitely pausees the cutscene.
---@return any
function Cutscene:pause()
    self.paused = true
    return coroutine.yield()
end

function Cutscene:tryResume()
    local result, a,b,c,d,e,f = self:canResume()
    if result then
        self:resume(a,b,c,d,e,f)
        return true
    end
    return false
end

--- Resumes the cutscene if it had been previously paused.
---@param ... unknown
function Cutscene:resume(...)
    self.paused = false
    self.wait_func = nil
    local ok, msg = coroutine.resume(self.coroutine, ...)
    if not ok then
        error(msg)
    end
end

--- Ends the cutscene.
function Cutscene:endCutscene()
    self.ended = true
    self:onEnd()
end

--- Starts executing a new cutscene script specified by `func`.
---@param func function     The new cutscene script.
---@param ... unknown       Additional arguments to pass to the new cutscene.
---@return unknown
function Cutscene:gotoCutscene(func, ...)
    if self.getter then
        local new_func, args = self:parseFromGetter(self.getter, func, ...)
        return new_func(self, unpack(args))
    else
        return func(self, ...)
    end
end

function Cutscene:playSound(sound, volume, pitch)
    local src = Assets.playSound(sound, volume, pitch)
    return function()
        if not Utils.containsValue(Assets.sound_instances[sound], src) then
            return true
        end
    end
end

return Cutscene