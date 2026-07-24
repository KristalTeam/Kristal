---@class ActorDataDocumentProvider : EditorDocumentProvider
---@overload fun(plugin: ActorEditorPlugin, editor: Editor): ActorDataDocumentProvider
---@field plugin EditorPlugin
local ActorDataDocumentProvider, super = Class(EditorDocumentProvider)

function ActorDataDocumentProvider:init(plugin, editor)
    super.init(self, editor, { priority = 80 })
    self.plugin = plugin
end

function ActorDataDocumentProvider:open()
    return false
end

function ActorDataDocumentProvider:isFocused()
    local focused = self.editor.dockspace and self.editor.dockspace.focused_control
    while focused do
        if focused == self.plugin.actor_editor or focused == self.plugin.party_editor then return true end
        focused = focused.parent
    end
    return false
end

function ActorDataDocumentProvider:getFocusedEditor()
    local focused = self.editor.dockspace and self.editor.dockspace.focused_control
    while focused do
        if focused == self.plugin.actor_editor then return self.plugin.actor_editor end
        if focused == self.plugin.party_editor then return self.plugin.party_editor end
        focused = focused.parent
    end
end

function ActorDataDocumentProvider:saveActive()
    local active = self:getFocusedEditor()
    return active and active:saveSelected() or nil
end

function ActorDataDocumentProvider:canSave()
    local active = self:getFocusedEditor()
    return active and active.model ~= nil or false
end

function ActorDataDocumentProvider:saveAll()
    if self.plugin.actor_editor and not self.plugin.actor_editor:saveAll() then return false end
    if self.plugin.party_editor and not self.plugin.party_editor:saveAll() then return false end
    return true
end

function ActorDataDocumentProvider:hasUnsavedChanges()
    return self.plugin.actor_editor and self.plugin.actor_editor:isDirty()
        or self.plugin.party_editor and self.plugin.party_editor:isDirty()
        or false
end

function ActorDataDocumentProvider:captureSession()
    return {
        actor = self.plugin.actor_editor and {
            id = self.plugin.actor_editor.selected_id,
            animation = self.plugin.actor_editor.selected_animation,
            mode = self.plugin.actor_editor.mode,
            direction = self.plugin.actor_editor.direction
        } or nil,
        party = self.plugin.party_editor and {
            id = self.plugin.party_editor.selected_id,
            chapter = self.plugin.party_editor.selected_chapter,
            mode = self.plugin.party_editor.mode
        } or nil
    }
end

function ActorDataDocumentProvider:restoreSession(state)
    if type(state) ~= "table" then return end
    if state.actor and self.plugin.actor_editor then
        self.plugin.actor_editor:selectEntryById(state.actor.id)
        self.plugin.actor_editor.selected_animation = state.actor.animation
        self.plugin.actor_editor.direction = state.actor.direction or "down"
        self.plugin.actor_editor:setMode(state.actor.mode or "animation")
    end
    if state.party and self.plugin.party_editor then
        self.plugin.party_editor:selectEntryById(state.party.id)
        self.plugin.party_editor.selected_chapter = state.party.chapter
        self.plugin.party_editor:setMode(state.party.mode or "base")
    end
end

return ActorDataDocumentProvider
