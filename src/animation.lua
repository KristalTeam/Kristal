local Animation = Class{}

function Animation:init(src)
    if type(src) == "table" then
        self:parseData(src)
    elseif type(src) == "string" then
        local base = kristal.data.getAnimation(src)
        self.path = base.path
        self.current_state = base.current_state
        self.states = utils.copy(base.states, true)
        self.frames = utils.copy(base.frames, true)
    end
    self.current_frame = 1
    self.time_elapsed = 0
end

function Animation:play(state, reset)
    if self.states[state] ~= nil then
        if self.current_state ~= state then
            self.current_state = state
            self.current_frame = 1
            self.time_elapsed = 0
        elseif reset then
            self.current_frame = 1
            self.time_elapsed = 0
        end
    end
end

function Animation:getTexture()
    return self.frames[self.current_state][self.current_frame]
end

function Animation:getAnimation()
    return self.current_state
end

function Animation:getCurrentPath()
    return self.path .. self.states[self.current_state].path
end

function Animation:update(dt)
    local state = self.states[self.current_state]
    local frames = self.frames[self.current_state]
    self.time_elapsed = self.time_elapsed + dt
    local target_frame = math.floor(self.time_elapsed / state.delay)
    if state.loop then
        self.current_frame = (target_frame % #frames) + 1
    else
        self.current_frame = math.min(target_frame + 1, #frames)
    end
    if (target_frame + 1) > #frames and state["goto"] then
        self:play(state["goto"], true)
    end
end

function Animation:draw(...)
    love.graphics.draw(self.frames[self.current_state][self.current_frame], ...)
end

function Animation:parseData(data)
    self.path = data.path or ""
    self.current_state = data.default
    self.states = {}
    self.frames = {}

    for k,v in pairs(data.states or {}) do
        if not self.current then
            self.current = k
        end
        local new_state = utils.copy(v, true)
        new_state.path = new_state.path or ""
        new_state.delay = math.max(new_state.delay or 0, FRAMERATE)
        local frame_tex = {}
        local n = 0
        local n_max = 0
        local current_path = self.path .. new_state.path
        local zero_index = true
        while true do
            local texture = kristal.assets.getTexture(current_path.."_"..n) or kristal.assets.getTexture(current_path.."_0"..n)
                         or kristal.assets.getTexture(current_path..n) or kristal.assets.getTexture(current_path.."0"..n)
            if texture then
                frame_tex[n] = texture
                n_max = n
                n = n + 1
            else
                if n == 0 then
                    zero_index = false
                    n = n + 1
                else
                    if n == 1 and not zero_index then
                        n_max = 1
                        frame_tex[1] = kristal.assets.getTexture(current_path)
                    end
                    break
                end
            end
        end
        new_state.frames = new_state.frames or (n == n_max and tostring(n) or ((zero_index and "0" or "1").."-"..(n_max)))
        local frames = {}
        for _,s in ipairs(utils.split(new_state.frames, ",")) do
            local range = utils.split(s, "-")
            if #range == 2 then
                local a, b = tonumber(range[1]), tonumber(range[2])
                for i = a, b, (a > b and -1 or 1) do
                    table.insert(frames, frame_tex[i])
                end
            else
                table.insert(frames, frame_tex[tonumber(s)])
            end
        end
        self.states[k] = new_state
        self.frames[k] = frames
    end
end

return Animation