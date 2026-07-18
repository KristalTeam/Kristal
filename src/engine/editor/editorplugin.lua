--- A plugin is essentially an editor library.\
--- They can be used to hook, modify, or create new functionality within the editor.\
--- All plugins extend from this class- unlike projects/libraries, they are not raw tables.
---@class EditorPlugin : Class
---@field __editor_plugin boolean
---@field id string?
---@field info any
---@field loaded_scripts table
---@field loading_scripts table
---@field panels table
---@field registration_cleanups table
---@field settings_pages table
---@field workspaces table
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
