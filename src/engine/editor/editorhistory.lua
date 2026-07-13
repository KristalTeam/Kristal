---@class EditorHistory : Class
---@overload fun(editor: table): EditorHistory
local EditorHistory = Class()

---@class EditorHistoryCallbackCommand
---@field owners? table|table[] Owners whose dirty revisions and editor UI should be updated.
---@field metadata? table
---@field execute? fun(): any Called when the command is initially performed.
---@field undo fun()
---@field redo? fun() Defaults to execute when the command is initially performed by history.

EditorHistory.DEFAULT_LIMIT = 500

function EditorHistory:init(editor, limit)
    self.editor = editor
    self.commands = {}
    self.index = 0
    self.serial = 0
    self.transaction = nil
    self.limit = math.max(1, math.floor(tonumber(limit) or self.DEFAULT_LIMIT))
end

function EditorHistory:getLimit()
    return self.limit
end

function EditorHistory:trimToLimit()
    while #self.commands > self.limit do
        table.remove(self.commands, 1)
        self.index = math.max(0, self.index - 1)
    end
end

function EditorHistory:setLimit(limit)
    limit = tonumber(limit)
    if not limit then return false end
    self.limit = math.max(1, math.floor(limit))
    self:trimToLimit()
    return true
end

local function normalizeOwners(owners)
    if owners and owners.captureHistoryState then owners = { owners } end
    local result, seen = {}, {}
    for _, owner in ipairs(owners or {}) do
        if owner and owner.captureHistoryState and not seen[owner] then
            seen[owner] = true
            table.insert(result, owner)
        end
    end
    return result
end

local function normalizeCommandOwners(owners)
    if owners == nil then return {} end
    assert(type(owners) == "table", "History command owners must be a table or list of tables")
    if next(owners) == nil then return {} end
    if owners and owners[1] == nil then owners = { owners } end
    local result, seen = {}, {}
    for _, owner in ipairs(owners or {}) do
        if owner and not seen[owner] then
            seen[owner] = true
            table.insert(result, owner)
        end
    end
    return result
end

local function removeAddedOwners(transaction, scope)
    for _, owner in ipairs(scope.added_owners) do
        transaction.owner_set[owner] = nil
        transaction.before[owner] = nil
        transaction.before_revisions[owner] = nil
        for index = #transaction.owners, 1, -1 do
            if transaction.owners[index] == owner then
                table.remove(transaction.owners, index)
                break
            end
        end
    end
end

local function addOwners(transaction, owners)
    local scope = transaction.scopes[#transaction.scopes]
    for _, owner in ipairs(owners) do
        if not transaction.owner_set[owner] then
            transaction.owner_set[owner] = true
            table.insert(transaction.owners, owner)
            table.insert(scope.added_owners, owner)
            transaction.before[owner] = owner:captureHistoryState()
            transaction.before_revisions[owner] = owner.history_revision or 0
        end
    end
end

function EditorHistory:begin(label, owners)
    owners = normalizeOwners(owners)
    if #owners == 0 then return false end
    if not self.transaction then
        self.transaction = {
            kind = "snapshot",
            label = label or "Edit",
            owners = {},
            owner_set = {},
            before = {},
            before_revisions = {},
            scopes = {}
        }
    end
    local transaction = self.transaction
    table.insert(transaction.scopes, {
        added_owners = {},
        changed = false,
        metadata = nil
    })
    addOwners(transaction, owners)
    return true
end

function EditorHistory:markChanged()
    if not self.transaction then return false end
    local scopes = self.transaction.scopes
    scopes[#scopes].changed = true
    return true
end

function EditorHistory:setTransactionMetadata(key, value)
    if not self.transaction then return false end
    local scopes = self.transaction.scopes
    local scope = scopes[#scopes]
    scope.metadata = scope.metadata or {}
    scope.metadata[key] = value
    return true
end

function EditorHistory:cancel()
    local transaction = self.transaction
    if not transaction then return false end
    local scope = table.remove(transaction.scopes)
    removeAddedOwners(transaction, scope)
    if #transaction.scopes == 0 then self.transaction = nil end
    return true
end

function EditorHistory:commit()
    local transaction = self.transaction
    if not transaction then return false end
    local scope = table.remove(transaction.scopes)
    if #transaction.scopes > 0 then
        if scope.changed then
            local parent = transaction.scopes[#transaction.scopes]
            parent.changed = true
            for _, owner in ipairs(scope.added_owners) do
                table.insert(parent.added_owners, owner)
            end
            if scope.metadata then
                parent.metadata = parent.metadata or {}
                for key, value in pairs(scope.metadata) do parent.metadata[key] = value end
            end
        else
            removeAddedOwners(transaction, scope)
        end
        return scope.changed
    end
    self.transaction = nil
    if not scope.changed then return false end
    transaction.metadata = scope.metadata
    transaction.scopes = nil
    transaction.owner_set = nil
    while #self.commands > self.index do table.remove(self.commands) end
    transaction.after, transaction.after_revisions = {}, {}
    for _, owner in ipairs(transaction.owners) do
        transaction.after[owner] = owner:captureHistoryState()
        self.serial = self.serial + 1
        transaction.after_revisions[owner] = self.serial
        owner.history_revision = self.serial
        if owner.saved_history_revision == nil then owner.saved_history_revision = 0 end
    end
    table.insert(self.commands, transaction)
    self.index = #self.commands
    self:trimToLimit()
    self.editor:onHistoryChanged(transaction.owners, false)
    return true
end

function EditorHistory:perform(label, owners, callback)
    if not self:begin(label, owners) then return false end
    local results = { callback() }
    if results[1] == false or results[1] == nil then
        self:cancel()
    else
        self:markChanged()
        self:commit()
    end
    return unpack(results)
end

local function appendCommand(history, command)
    while #history.commands > history.index do table.remove(history.commands) end
    command.before_revisions, command.after_revisions = {}, {}
    for _, owner in ipairs(command.owners) do
        command.before_revisions[owner] = owner.history_revision or 0
        history.serial = history.serial + 1
        command.after_revisions[owner] = history.serial
        owner.history_revision = history.serial
        if owner.saved_history_revision == nil then owner.saved_history_revision = 0 end
    end
    table.insert(history.commands, command)
    history.index = #history.commands
    history:trimToLimit()
    history.editor:onHistoryChanged(command.owners, false)
    return true
end

---@param label? string
---@param command EditorHistoryCallbackCommand
function EditorHistory:pushCommand(label, command)
    assert(type(command) == "table", "History commands must be tables")
    assert(type(command.undo) == "function", "History commands require an undo callback")
    assert(type(command.redo) == "function", "History commands require a redo callback")
    if self.transaction then return false end
    return appendCommand(self, {
        kind = "callbacks",
        label = label or command.label or "Edit",
        owners = normalizeCommandOwners(command.owners),
        metadata = command.metadata,
        undo = command.undo,
        redo = command.redo
    })
end

---@param label? string
---@param command EditorHistoryCallbackCommand
function EditorHistory:performCommand(label, command)
    assert(type(command) == "table", "History commands must be tables")
    assert(type(command.execute) == "function", "History commands require an execute callback")
    assert(type(command.undo) == "function", "History commands require an undo callback")
    if self.transaction then return false end
    local results = { command.execute() }
    if results[1] == false then return unpack(results) end
    self:pushCommand(label, {
        owners = command.owners,
        metadata = command.metadata,
        undo = command.undo,
        redo = command.redo or command.execute
    })
    return unpack(results)
end

function EditorHistory:canUndo()
    return self.transaction == nil and self.index > 0
end

function EditorHistory:canRedo()
    return self.transaction == nil and self.index < #self.commands
end

function EditorHistory:getUndoLabel()
    local command = self.commands[self.index]
    return command and command.label or nil
end

function EditorHistory:getRedoLabel()
    local command = self.commands[self.index + 1]
    return command and command.label or nil
end

local function restore(command, states, revisions)
    for _, owner in ipairs(command.owners) do
        owner:restoreHistoryState(states[owner])
        owner.history_revision = revisions[owner]
    end
end

local function setRevisions(command, revisions)
    for _, owner in ipairs(command.owners) do owner.history_revision = revisions[owner] end
end

function EditorHistory:undo()
    if not self:canUndo() then return false end
    local command = self.commands[self.index]
    if command.kind == "callbacks" then
        command.undo()
        setRevisions(command, command.before_revisions)
    else
        restore(command, command.before, command.before_revisions)
    end
    self.index = self.index - 1
    self.editor:onHistoryChanged(command.owners, true, command, "undo")
    return true
end

function EditorHistory:redo()
    if not self:canRedo() then return false end
    local command = self.commands[self.index + 1]
    if command.kind == "callbacks" then
        command.redo()
        setRevisions(command, command.after_revisions)
    else
        restore(command, command.after, command.after_revisions)
    end
    self.index = self.index + 1
    self.editor:onHistoryChanged(command.owners, true, command, "redo")
    return true
end

function EditorHistory:markSaved(owner)
    if not owner then return false end
    owner.saved_history_revision = owner.history_revision or 0
    self.editor:onHistoryChanged({ owner }, false)
    return true
end

function EditorHistory:isDirty(owner)
    return owner and (owner.history_revision or 0) ~= (owner.saved_history_revision or 0)
end

function EditorHistory:forgetOwner(owner)
    if self.transaction then
        for _, candidate in ipairs(self.transaction.owners) do
            if candidate == owner then self.transaction = nil break end
        end
    end
    for index = #self.commands, 1, -1 do
        local remove = false
        for _, candidate in ipairs(self.commands[index].owners) do
            if candidate == owner then remove = true break end
        end
        if remove then
            table.remove(self.commands, index)
            if index <= self.index then self.index = self.index - 1 end
        end
    end
end

return EditorHistory
