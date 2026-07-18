---@class ActorEditorPlugin : EditorPlugin
---@overload fun(info: table): ActorEditorPlugin
---@field actor_editor ActorEditor
---@field actor_panel_definition any
---@field editor Editor
---@field party_editor PartyMemberEditor
---@field party_panel_definition any
local ActorEditorPlugin, super = Class(EditorPlugin)

function ActorEditorPlugin:init(info)
    super.init(self, info)
end

function ActorEditorPlugin:showPanel(definition)
    local panel = definition and definition.panel
    if not panel then return false end
    self.editor.dockspace:setPanelVisible(panel, true, panel.last_region or "center")
    if panel.stack then panel.stack:setActivePanel(panel) end
    self.editor.dockspace:setFocus(panel.content)
    return true
end

function ActorEditorPlugin:openActor(id)
    if not self:showPanel(self.actor_panel_definition) then return false end
    return self.actor_editor:selectEntryById(id)
end

function ActorEditorPlugin:openPartyMember(id)
    if not self:showPanel(self.party_panel_definition) then return false end
    return self.party_editor:selectEntryById(id)
end

function ActorEditorPlugin:openDataFile(kind, path)
    local control = kind == "actor" and self.actor_editor or self.party_editor
    local definition = kind == "actor" and self.actor_panel_definition or self.party_panel_definition
    if not control or not definition then return false end

    control:refreshEntries(true)
    local normalized = tostring(path or ""):gsub("\\", "/")
    for _, entry in ipairs(control.entries or {}) do
        if tostring(entry.path or ""):gsub("\\", "/") == normalized then
            self:showPanel(definition)
            return control:selectEntry(entry)
        end
    end

    self.editor:addWarning("Could not open data file in the visual editor",
        "The file is not registered as a " .. (kind == "actor" and "Kristal actor." or "party member."),
        "actor_editor")
    return false
end

function ActorEditorPlugin:onInit(editor)
    self.editor = editor
    local DataModel = self:require("scripts.datamodel")
    local ActorPreview = self:require("scripts.controls.actorpreview")
    local ActorEditor = self:require("scripts.panels.actoreditor", DataModel, ActorPreview)
    local PartyMemberEditor = self:require("scripts.panels.partymembereditor", DataModel)
    local DocumentProvider = self:require("scripts.documentprovider")

    self.actor_panel_definition = self:registerPanel("actors", "Actor Editor", function()
        self.actor_editor = ActorEditor(editor, self)
        return self.actor_editor
    end, {
        region = "center",
        visible = false,
        minimum_width = 720,
        minimum_height = 560,
        preferred_width = 980,
        preferred_height = 680,
        recoverable = true
    })

    self.party_panel_definition = self:registerPanel("party_members", "Party Member Editor", function()
        self.party_editor = PartyMemberEditor(editor, self)
        return self.party_editor
    end, {
        region = "center",
        visible = false,
        minimum_width = 720,
        minimum_height = 560,
        preferred_width = 980,
        preferred_height = 680,
        recoverable = true
    })

    self:registerDocumentProvider("actor_data", DocumentProvider(self, editor))

    self:registerFileContextProvider("actor_data", function(data)
        if not data or data.type ~= "file" then return nil end
        local relative = tostring(data.relative_path or ""):gsub("\\", "/"):lower()
        if relative:match("^scripts/data/actors/.+%.lua$") then
            return {
                label = "Open in Actor Editor",
                action = function() self:openDataFile("actor", data.path) end
            }
        elseif relative:match("^scripts/data/party/.+%.lua$") then
            return {
                label = "Open in Party Member Editor",
                action = function() self:openDataFile("party", data.path) end
            }
        end
    end)

    self:registerMenuItem("file", "save_actor_data", "Save Actor / Party Member", {
        is_enabled = function()
            return self.actor_editor and self.actor_editor:isVisibleAndDirty()
                or self.party_editor and self.party_editor:isVisibleAndDirty()
        end,
        on_activate = function()
            if self.actor_editor and self.actor_editor:isVisibleAndDirty() then
                self.actor_editor:saveSelected()
            elseif self.party_editor and self.party_editor:isVisibleAndDirty() then
                self.party_editor:saveSelected()
            end
        end
    })

    self:registerCommand("open_actor_editor", "Open Actor Editor", {
        category = "Editor",
        keywords = { "actor", "sprite", "animation", "offset", "hitbox" },
        action = function() self:showPanel(self.actor_panel_definition) end
    })
    self:registerCommand("open_party_member_editor", "Open Party Member Editor", {
        category = "Editor",
        keywords = { "party", "character", "stats", "chapter" },
        action = function() self:showPanel(self.party_panel_definition) end
    })
end

return ActorEditorPlugin
