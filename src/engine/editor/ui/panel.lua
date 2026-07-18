---@class EditorPanel : Class
---@field content EditorControl?
---@field fixed_content_height number?
---@field fixed_content_width number?
---@field floating table?
---@field id string
---@field minimum_height number
---@field minimum_width number
---@field on_activate function?
---@field on_remove function?
---@field on_visibility_changed function?
---@field preferred_height number
---@field preferred_width number
---@field recoverable boolean
---@field stack EditorDockStack?
---@field title string
---@field visible boolean
---@overload fun(id: string, title: string, content?: EditorControl, options?: table): EditorPanel
local EditorPanel = Class()

function EditorPanel:init(id, title, content, options)
    options = options or {}
    assert(type(id) == "string" and id ~= "", "Editor panels require a stable id")
    self.id = id
    self.title = title or id
    self.content = content
    self.visible = options.visible ~= false
    self.minimum_width = options.minimum_width or 120
    self.minimum_height = options.minimum_height or 80
    self.preferred_width = options.preferred_width or 260
    self.preferred_height = options.preferred_height or 220
    self.fixed_content_width = options.fixed_content_width
    self.fixed_content_height = options.fixed_content_height
    self.on_activate = options.on_activate
    self.on_visibility_changed = options.on_visibility_changed
    self.recoverable = options.recoverable == true
    self.on_remove = options.on_remove
    self.stack = nil
    self.floating = nil
end

function EditorPanel:setContent(content)
    self.content = content
end

return EditorPanel
