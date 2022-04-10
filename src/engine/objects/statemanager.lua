local StateManager, super = Class(Object)

function StateManager:init(default_state, master, update_master_state)
    self.default_state = default_state
    self.master = master

    self.state = self.default_state

    -- If true, sets self.master.state and updates state if a change in self.master.state is detected
    self.update_master_state = update_master_state

    if self.update_master_state then
        self.master.state = self.state
    end

    self.state_events = {}
    self.state_initialized = {}

    self.has_state = {}

    self.on_state_change = nil

    self.routine = nil
    self.routine_wait = 0
end

function StateManager:addState(state, events)
    for event,func in pairs(events or {}) do
        self.state_events[event] = self.state_events[event] or {}
        self.state_events[event][state] = func
    end
    self.has_state[state] = true
end

function StateManager:removeState(state)
    for _,state_callbacks in pairs(self.state_events or {}) do
        state_callbacks[state] = nil
    end
    self.has_state[state] = nil
end

function StateManager:hasState(state)
    return self.has_state[state] or false
end

function StateManager:addEvent(event, state_callbacks)
    Utils.merge(self.state_events[event], state_callbacks or {})
end

function StateManager:removeEvent(event)
    self.state_events[event] = nil
end

function StateManager:hasEvent(event, state)
    return self.state_events[event] and self.state_events[event][state or self.state]
end

function StateManager:callOn(state, event, ...)
    local state_callbacks = self.state_events[event]
    if state_callbacks and state_callbacks[state] then
        local func = state_callbacks[state]
        if self.master then
            return func(self.master, ...)
        else
            return func(...)
        end
    end
end

function StateManager:call(event)
    self:callOn(self.state, event)
end

function StateManager:doIf(...)
    local args = {...}
    if #args == 1 and type(args[1]) == "table" then
        if args[1][self.state] then
            args[1][self.state](self.master)
        end
    else
        for i = 1, #args, 2 do
            if self.state == args[i] then
                args[i+1](self.master)
                break
            end
        end
    end
end

function StateManager:hook(state, event, func)
    self.state_events[event] = self.state_events[event] or {}
    if self.state_events[event][state] then
        local old_func = self.state_events[event][state]
        self.state_events[event][state] = function(...)
            func(old_func, ...)
        end
    else
        local nil_func = function() end
        self.state_events[event][state] = function(...) func(nil_func, ...) end
    end
end

function StateManager:setState(state)
    if state == self.state then return end

    if self.master and self.master.beforeStateChange then
        local result = self.master:beforeStateChange(self.state, state)
        if result then
            if self.update_master_state and self.master.state ~= state then
                self.master.state = state
            end
            return
        end
    end

    if self.update_master_state then
        self.master.state = state
    end

    local last_state = self.state
    self:call("leave", state)
    self.state = state
    if not self.state_initialized[self.state] then
        self:call("init")
        self.state_initialized[self.state] = true
    end
    self:call("enter", last_state)
    if self.on_state_change then
        self.on_state_change(last_state, state)
    end
    if self.master and self.master.onStateChange then
        self.master:onStateChange(last_state, state)
    end

    self.routine_wait = 0
    if self:hasEvent("coroutine") then
        local function wait(time)
            self.routine_wait =  time
            coroutine.yield()
        end
        self.routine = coroutine.create(function() self:call("coroutine", wait) end)
    else
        self.routine = nil
    end
end

function StateManager:update(dt)
    if self.update_master_state and self.state ~= self.master.state then
        self:setState(self.master.state)
    end

    if self.routine and coroutine.status(self.routine) == "suspended" then
        self.routine_wait = Utils.approach(self.routine_wait, 0, dt)
        if self.routine_wait == 0 then
            coroutine.resume(self.routine)
        end
    end
    if self.routine and coroutine.status(self.routine) == "dead" then
        self.routine = nil
    end

    self:call("update", dt)
end

function StateManager:draw()
    self:call("draw")
end

return StateManager