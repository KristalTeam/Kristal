---@class EditorHistory : Class
---@overload fun(editor: table): EditorHistory
local EditorHistory = Class()

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

function EditorHistory:begin(label, owners)
    if self.transaction then return false end
    owners = normalizeOwners(owners)
    if #owners == 0 then return false end
    local transaction = { label = label or "Edit", owners = owners, before = {}, before_revisions = {}, changed = false }
    for _, owner in ipairs(owners) do
        transaction.before[owner] = owner:captureHistoryState()
        transaction.before_revisions[owner] = owner.history_revision or 0
    end
    self.transaction = transaction
    return true
end

function EditorHistory:markChanged()
    if not self.transaction then return false end
    self.transaction.changed = true
    return true
end

function EditorHistory:setTransactionMetadata(key, value)
    if not self.transaction then return false end
    self.transaction.metadata = self.transaction.metadata or {}
    self.transaction.metadata[key] = value
    return true
end

function EditorHistory:cancel()
    self.transaction = nil
end

function EditorHistory:commit()
    local transaction = self.transaction
    self.transaction = nil
    if not transaction or not transaction.changed then return false end
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
    if not self:begin(label, owners) then return callback() end
    local results = { callback() }
    if results[1] == false or results[1] == nil then
        self:cancel()
    else
        self:markChanged()
        self:commit()
    end
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

function EditorHistory:undo()
    if not self:canUndo() then return false end
    local command = self.commands[self.index]
    restore(command, command.before, command.before_revisions)
    self.index = self.index - 1
    self.editor:onHistoryChanged(command.owners, true, command, "undo")
    return true
end

function EditorHistory:redo()
    if not self:canRedo() then return false end
    local command = self.commands[self.index + 1]
    restore(command, command.after, command.after_revisions)
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
