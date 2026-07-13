local CodeEditorPlugin, super = Class(EditorPlugin)

function CodeEditorPlugin:init(info)
    super.init(self, info)
    self.language_server_enabled = true
    self.language_server_path = ""
end

function CodeEditorPlugin:onInit(editor)
    local completion_popup = self:require("scripts.ui.codecompletion")
    local hover_popup = self:require("scripts.ui.codehover")
    local code_input = self:require("scripts.ui.codeinput", completion_popup, hover_popup)
    local code_editor_class = self:require("scripts.panels.codeeditor", code_input)
    local writable_document = self:require("scripts.documents.writablefiledocument")
    local lsp_client = self:require("scripts.lsp.client")
    local language_service_class = self:require("scripts.lsp.lualanguageservice", lsp_client, self)

    local settings_page = self:registerSettingsPage("language_server", "Language Server", {
        description = "Configure Lua Language Server support for the optional code editor."
    })
    self:registerSetting(settings_page, "enabled", {
        name = "Enable LuaLS",
        type = "boolean",
        default = true,
        set = function(value)
            self.language_server_enabled = value
            if self.language_service then self.language_service:setEnabled(value) end
        end
    })
    self:registerSetting(settings_page, "executable", {
        name = "LuaLS Executable",
        description = "Optional path to lua-language-server. Leave blank to search the managed tools folder and PATH.",
        type = "string",
        default = "",
        set = function(value)
            self.language_server_path = value
        end,
        on_changed = function()
            if self.language_service then self.language_service:restart() end
        end
    })

    self.language_service = language_service_class(editor, editor.project_workspace)
    self.code_editor = code_editor_class(editor, editor.project_workspace, self.language_service)
    local panel = self:registerPanel("code_editor", "File Editor", function()
        return self.code_editor
    end, {
        region = "center",
        visible = false,
        minimum_width = 480,
        minimum_height = 320,
        preferred_width = 800,
        preferred_height = 560,
        recoverable = true
    })

    local provider
    provider = self:registerDocumentProvider("source_editor", {
        priority = 100,
        supports_path = function(_, file_type, options)
            return file_type and file_type.id == "text" and options.read_only ~= true
        end,
        create_document = function(workspace, path, contents, _, options)
            return writable_document(workspace, path, contents, options)
        end,
        supports = function(document)
            return document.writable_code_document == true
        end,
        open = function(document, options)
            self.code_editor:openDocument(document, options)
            return editor:showDocumentProviderPanel(panel.panel, self.code_editor, self.code_editor.input)
        end,
        close = function(document)
            return self.code_editor:closeDocument(document)
        end,
        is_focused = function()
            local focused = editor.dockspace and editor.dockspace.focused_control
            while focused do
                if focused == self.code_editor then return true end
                focused = focused.parent
            end
            return false
        end,
        save_active = function()
            return self.code_editor:saveActiveDocument()
        end,
        can_save = function()
            return self.code_editor.active_document ~= nil
        end,
        save_all = function()
            for _, document in ipairs(self.code_editor.documents) do
                if document:isDirty() then
                    local saved, reason = document:save()
                    if not saved then
                        editor:addError("Could not save " .. document.relative_path, reason, "filesystem")
                        return false
                    end
                end
            end
            return true
        end,
        undo = function() return self.code_editor:undo() end,
        redo = function() return self.code_editor:redo() end,
        can_undo = function()
            local document = self.code_editor.active_document
            return document ~= nil and #document.undo_stack > 0
        end,
        can_redo = function()
            local document = self.code_editor.active_document
            return document ~= nil and #document.redo_stack > 0
        end,
        get_undo_label = function()
            local document = self.code_editor.active_document
            return document and #document.undo_stack > 0 and ("Edit " .. document.name) or nil
        end,
        get_redo_label = function()
            local document = self.code_editor.active_document
            return document and #document.redo_stack > 0 and ("Edit " .. document.name) or nil
        end,
        has_unsaved_changes = function()
            for _, document in ipairs(self.code_editor.documents) do
                if document:isDirty() then return true end
            end
            return false
        end,
        capture_session = function()
            local paths = {}
            for _, document in ipairs(self.code_editor.documents) do
                if document.persistent then table.insert(paths, document.relative_path) end
            end
            return {
                paths = paths,
                active = self.code_editor.active_document
                    and self.code_editor.active_document.persistent
                    and self.code_editor.active_document.relative_path or nil
            }
        end,
        restore_session = function(state)
            if type(state) ~= "table" then return end
            local restored = {}
            for _, path in ipairs(state.paths or {}) do
                local document = editor.project_workspace:openDocument(path)
                if document and document.document_provider_id == provider.id then
                    self.code_editor:openDocument(document, { focus = false })
                    restored[path] = document
                end
            end
            if state.active and restored[state.active] then
                self.code_editor:setActiveDocument(restored[state.active], false)
            end
        end,
        document_opened = function(document)
            self.language_service:openDocument(document)
        end,
        document_changed = function(document, options)
            self.language_service:changeDocument(document, options and options.change)
        end,
        document_saved = function(document)
            self.language_service:saveDocument(document)
        end,
        document_closed = function(document)
            self.language_service:closeDocument(document)
        end,
        document_refreshed = function(document)
            self.code_editor:refreshDocument(document)
        end,
        update = function()
            self.language_service:update()
        end,
        shutdown = function()
            self.language_service:shutdown(true)
        end
    })

    self:registerMenuItem("edit", "format_document", "Format Document", {
        on_activate = function() self.code_editor:formatActiveDocument() end,
        is_enabled = function() return self.code_editor.active_document ~= nil end
    })
    self:registerMenuItem("edit", "restart_luals", "Restart Lua Language Server", {
        on_activate = function() self.language_service:restart() end
    })
end

return CodeEditorPlugin
