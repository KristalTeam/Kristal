---@class CodeEditorPlugin : EditorPlugin
---@overload fun(info: table): CodeEditorPlugin
---@field code_editor any
---@field language_server_enabled boolean
---@field language_server_path string
---@field language_service LuaLanguageService?
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
    local source_provider = self:require("scripts.providers.sourceeditorprovider")
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

    self:registerDocumentProvider("source_editor",
        source_provider(self, editor, panel, writable_document))

    self:registerMenuItem("edit", "format_document", "Format Document", {
        on_activate = function() self.code_editor:formatActiveDocument() end,
        is_enabled = function() return self.code_editor.active_document ~= nil end
    })
    self:registerMenuItem("edit", "restart_luals", "Restart Lua Language Server", {
        on_activate = function() self.language_service:restart() end
    })
end

return CodeEditorPlugin
