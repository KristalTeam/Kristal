---@meta

--- A class with its state managed with [`StateManager`](lua://StateManager.init).
---
---@class StateManagedClass : Class
---
---@field state string # The current state.
local StateManagedClass = {}

--- *(Override)* Called before the state is changed through [`StateManager:setState`](lua://StateManager.setState).
---
---@param old string # The current state, from before the change.
---@param new string # The state from after the change.
---@return boolean? # If `true` is returned, the rest of the `setState` process except the updating of [`self.state`](lua://StateManagedClass.state) will be skipped.
function StateManagedClass:beforeStateChange(old, new) end

--- *(Override)* Called after the state is changed through [`StateManager:setState`](lua://StateManager.setState).
---
---@param old string # The state from before the change.
---@param new string # The current state, from after the change.
---@param ... any # Arguments for the new state.
function StateManagedClass:onStateChange(old, new, ...) end
