---@class EditorPlugin : Class
---@overload fun(info: table): EditorPlugin
local EditorPlugin = Class()

function EditorPlugin:init(info)
    assert(type(info) == "table", "EditorPlugin requires plugin metadata")
    self.id = assert(info.id, "EditorPlugin metadata requires an id")
    self.info = info
    self.panels = {}
    self.workspaces = {}
    self.settings_pages = {}
    self.loaded_scripts = {}
    self.loading_scripts = {}
    self.registration_cleanups = {}
    self.__editor_plugin = true
end

return EditorPlugin
