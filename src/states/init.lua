local states = {}

local state_stack = {}

function states.switch(state, ...)
    if type(state) == "string" then
        state = kristal.states[state]
    end
    if #state_stack > 0 then
        state_stack[#state_stack] = state
    elseif state then
        table.insert(state_stack, state)
    end
    return lib.gamestate.switch(state, ...)
end

function states.push(state, ...)
    if type(state) == "string" then
        state = kristal.states[state]
    end
    table.insert(state_stack, state)
    return lib.gamestate.push(state, ...)
end

function states.pop(...)
    table.remove(state_stack, #state_stack)
    if #state_stack > 0 then
        return lib.gamestate.pop(...)
    else
        return lib.gamestate.switch({})
    end
end

function states.is(state)
    if type(state) == "string" then
        state = kristal.states[state]
    end
    return state_stack[#state_stack] == state
end

function states.current()
    return state_stack[#state_stack]
end

function states.peek()
    return state_stack[#state_stack - 1]
end

return states