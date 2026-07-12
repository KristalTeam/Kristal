---@class EditorSearchBar : EditorTextInput
---@overload fun(options?: table): EditorSearchBar
local EditorSearchBar, super = Class(EditorTextInput)

function EditorSearchBar:init(options)
    options = options or {}
    options.placeholder = options.placeholder or "Search..."
    super.init(self, options)
end

return EditorSearchBar
