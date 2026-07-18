--- Edits one project or asset path.
---@class EditorPathInput : EditorControl
---@field editor Editor
---@field input EditorTextInput
---@field inputs table
---@field on_submit function?
---@field options table
---@field path_kind string
---@field picker_button EditorButton
---@field preferred_height number
---@field value string
---@overload fun(editor: Editor, value?: string, options?: table): EditorPathInput
local EditorPathInput, super = Class(EditorControl)

local function normalizePath(path)
    return tostring(path or ""):gsub("\\", "/"):gsub("^%./", "")
end

local function extension(path)
    return path:match("%.([^%./]+)$")
end

local function contains(options, value)
    if not options then return true end
    for _, candidate in ipairs(options) do
        if tostring(candidate):lower():gsub("^%.", "") == tostring(value or ""):lower() then return true end
    end
    return false
end

local function intersects(options, candidates)
    if not options then return true end
    for _, candidate in ipairs(candidates) do
        if contains(options, candidate) then return true end
    end
    return false
end

function EditorPathInput:init(editor, value, options)
    options = TableUtils.copy(options or {}, true)
    super.init(self, 0, 0, options.width or 180, 28)
    self.editor = editor
    self.options = options
    self.path_kind = options.path_kind or "asset"
    self.on_submit = options.on_submit
    self.value = normalizePath(value)
    self.input = self:addChild(EditorTextInput({
        editor = editor,
        placeholder = options.placeholder or (self.path_kind == "script" and "Script path" or "Asset path"),
        on_submit = function(input) return self:submitValue(input) end
    }))
    self.picker_button = self:addChild(EditorButton("...", function() self:openPicker() end))
    self.inputs = { self.input }
    self.input:setValue(self.value, true)
    self.preferred_height = 28
end

function EditorPathInput:setValue(value, silent)
    self.value = normalizePath(value)
    self.input:setValue(self.value, silent == true)
    return true
end

function EditorPathInput:submitValue(value)
    value = normalizePath(value)
    if self.on_submit and self.on_submit(value, self) == false then return false end
    self:setValue(value, true)
    return true
end

function EditorPathInput:getProjectRelativePath(data)
    if type(data) ~= "table" or data.type ~= "file" then return nil end
    local path = normalizePath(data.relative_path)
    local root = normalizePath(self.options.path_root):gsub("/+$", "")
    local kind_root = self.path_kind == "script" and "scripts" or "assets"
    if self.path_kind == "asset" and self.options.asset_categories then
        local accepted_category = false
        for _, category in ipairs(self.options.asset_categories) do
            local category_root = "assets/" .. tostring(category)
            if path == category_root or StringUtils.startsWith(path, category_root .. "/") then
                accepted_category = true
                break
            end
        end
        if not accepted_category then return nil end
    end
    if root ~= "" then
        if path ~= root and not StringUtils.startsWith(path, root .. "/") then return nil end
        path = path == root and "" or path:sub(#root + 2)
    elseif path ~= kind_root and not StringUtils.startsWith(path, kind_root .. "/") then
        return nil
    end
    if not contains(self.options.extensions, extension(path)) then return nil end
    if self.options.strip_extension then path = path:gsub("%.[^%./]+$", "") end
    return path
end

function EditorPathInput:canAcceptProjectFile(data)
    return self:getProjectRelativePath(data) ~= nil
end

function EditorPathInput:acceptProjectFileDrop(data)
    local value = self:getProjectRelativePath(data)
    if value == nil then return false end
    local accepted = self:submitValue(value)
    if accepted and self.editor and self.editor.dockspace then
        self.editor.dockspace:setFocus(self.input)
    end
    return accepted
end

local function appendRegistryItems(items, seen, source)
    for id in pairs(source or {}) do
        id = tostring(id)
        if not seen[id] then
            seen[id] = true
            table.insert(items, { id = id, label = id, data = id })
        end
    end
end

local function appendScriptRegistryItems(items, seen, source)
    for id, value in pairs(source or {}) do
        if type(value) == "table" then
            for child_id in pairs(value) do
                local combined = tostring(id) .. "." .. tostring(child_id)
                if not seen[combined] then
                    seen[combined] = true
                    table.insert(items, { id = combined, label = combined, data = combined })
                end
            end
        else
            appendRegistryItems(items, seen, { [id] = value })
        end
    end
end

function EditorPathInput:getPickerItems()
    local items, seen = {}, {}
    local choices = type(self.options.choices) == "function"
        and self.options.choices(self.options, self) or self.options.choices
    for _, choice in ipairs(type(choices) == "table" and choices or {}) do
        local value = EditorChoiceUtils.getValue(choice)
        if value ~= nil and not seen[value] then
            seen[value] = true
            table.insert(items, {
                id = value,
                label = EditorChoiceUtils.getLabel(choice),
                data = value
            })
        end
    end

    local registries = self.options.registry
    if type(registries) == "string" then registries = { registries } end
    for _, registry in ipairs(registries or {}) do
        appendScriptRegistryItems(items, seen, Registry[registry])
    end

    local asset_registries = self.options.asset_registry
    if type(asset_registries) == "string" then asset_registries = { asset_registries } end
    for _, registry in ipairs(asset_registries or {}) do
        appendRegistryItems(items, seen, Assets.data and Assets.data[registry])
    end

    if self.path_kind == "asset" and not asset_registries then
        local categories = {
            { id = "sprites", root = "assets/sprites", registries = { "texture", "frames" },
                extensions = { "png", "jpg", "jpeg", "bmp", "tga", "webp" } },
            { id = "sounds", root = "assets/sounds", registries = { "sound_data" },
                extensions = { "ogg", "wav", "mp3", "flac" } },
            { id = "music", root = "assets/music", registries = { "music" },
                extensions = { "ogg", "wav", "mp3", "flac" } },
            { id = "shaders", root = "assets/shaders",
                registries = { "shader_paths" }, extensions = { "glsl" } },
            { id = "fonts", root = "assets/fonts",
                registries = { "fonts" }, extensions = { "ttf", "fnt", "png" } },
            { id = "videos", root = "assets/videos",
                registries = { "videos" }, extensions = { "ogg", "ogv" } },
            { id = "bubbles", root = "assets/bubbles",
                registries = { "bubble_settings" }, extensions = { "json" } }
        }
        local path_root = normalizePath(self.options.path_root):gsub("/+$", "")
        for _, category in ipairs(categories) do
            if contains(self.options.asset_categories, category.id)
                and intersects(self.options.extensions, category.extensions) then
                for _, registry in ipairs(category.registries) do
                    for id in pairs(Assets.data and Assets.data[registry] or {}) do
                        local value = path_root == category.root and tostring(id)
                            or category.root .. "/" .. tostring(id)
                        if not seen[value] then
                            seen[value] = true
                            table.insert(items, { id = value, label = value, data = value })
                        end
                    end
                end
            end
        end
    end

    if self.editor and self.editor.project_workspace then
        local root = self.editor.project_workspace:scan()
        local function add(node)
            if node.type == "file" then
                local value = self:getProjectRelativePath(node)
                if value ~= nil and not seen[value] then
                    seen[value] = true
                    table.insert(items, { id = value, label = value, data = value })
                end
            end
            for _, child in ipairs(node.children or {}) do add(child) end
        end
        if root then add(root) end
    end
    table.sort(items, function(a, b) return a.label:lower() < b.label:lower() end)
    return items
end

function EditorPathInput:openPicker()
    if not self.editor then return false end
    return self.editor:openPathPicker(self.value, self:getPickerItems(), {
        title = self.options.picker_title
            or (self.path_kind == "script" and "Choose Script" or "Choose Asset"),
        on_apply = function(value) return self:submitValue(value) end
    }) ~= nil
end

function EditorPathInput:update(dt)
    local button_width = math.min(34, self.width)
    self.input:setBounds(0, 0, math.max(0, self.width - button_width - 5), self.height)
    self.picker_button:setBounds(math.max(0, self.width - button_width), 0, button_width, self.height)
    super.update(self, dt)
end

function EditorPathInput:draw()
    super.draw(self)
    if not self.visible then return end
    local drag = self.editor and self.editor.project_file_drag
    if drag and self:canAcceptProjectFile(drag.data) then
        love.graphics.push()
        love.graphics.translate(self.x, self.y)
        Draw.setColor(0.45, 0.72, 1, 0.75)
        love.graphics.rectangle("line", 0.5, 0.5, self.width - 1, self.height - 1)
        love.graphics.pop()
    end
end

return EditorPathInput
