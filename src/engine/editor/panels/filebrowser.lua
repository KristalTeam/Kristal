---@class EditorFileBrowser : EditorControl
---@field editor Editor
---@field new_file_button EditorButton
---@field new_folder_button EditorButton
---@field search EditorSearchBar
---@field tree EditorTreeList
---@field workspace EditorProjectWorkspace
---@overload fun(editor: Editor, workspace: EditorProjectWorkspace): EditorFileBrowser
local EditorFileBrowser, super = Class(EditorControl)

function EditorFileBrowser:openExternal(url, label)
    local opened = love.system.openURL(url)
    if opened == false then
        self.editor:addWarning("Could not " .. label, "No application accepted " .. url, "filesystem")
        return false
    end
    return true
end

local DIRECTORY_ICON_ROOT = "editor/ui/filesystem/directory/"
local FILE_ICON_ROOT = "editor/ui/filesystem/file/"
local IMAGE_EXTENSIONS = { png = true, jpg = true, jpeg = true, bmp = true, tga = true, webp = true }
local AUDIO_EXTENSIONS = { ogg = true, mp3 = true, wav = true, flac = true }
local SHADER_EXTENSIONS = { glsl = true, frag = true, vert = true }

local function existingIcon(path, fallback)
    return Assets.getTexture(path) and path or fallback
end

local function getDirectoryIcon(data)
    local relative = tostring(data.relative_path or ""):lower():gsub("\\", "/")
    local semantic_path = relative:gsub("^libraries/[^/]+/", "")
    if semantic_path ~= "" then
        local semantic = existingIcon(DIRECTORY_ICON_ROOT .. semantic_path)
        if semantic then return semantic end
    end
    return DIRECTORY_ICON_ROOT .. "generic"
end

local function getFileIcon(data)
    local relative = tostring(data.relative_path or ""):lower():gsub("\\", "/")
    local path = "/" .. relative
    local name = relative:match("([^/]+)$") or relative
    local extension = name:match("%.([^%.]+)$")

    if name == "mod.lua" or name == "lib.lua" or name == "plugin.lua" then
        return FILE_ICON_ROOT .. "project_lua"
    elseif name == "mod.json" or name == "lib.json" or name == "plugin.json" then
        return FILE_ICON_ROOT .. "project_json"
    elseif extension == "tmx" or extension == "tsx"
        or (extension and StringUtils.contains(extension, "tiled")) then
        return FILE_ICON_ROOT .. "tiled"
    elseif path:find("/scripts/world/maps/", 1, true) then
        return FILE_ICON_ROOT .. "world/map"
    elseif path:find("/scripts/world/tilesets/", 1, true) then
        return FILE_ICON_ROOT .. "world/tileset"
    elseif path:find("/scripts/world/worlds/", 1, true) then
        return FILE_ICON_ROOT .. "world/world"
    elseif path:find("/scripts/world/events/", 1, true) then
        return FILE_ICON_ROOT .. "world/event"
    elseif path:find("/scripts/battle/bullets/", 1, true) then
        return FILE_ICON_ROOT .. "battle/bullet"
    elseif path:find("/scripts/battle/encounters/", 1, true) then
        return FILE_ICON_ROOT .. "battle/encounter"
    elseif path:find("/scripts/battle/enemies/", 1, true) then
        return FILE_ICON_ROOT .. "battle/enemy"
    elseif path:find("/scripts/battle/waves/", 1, true) then
        return FILE_ICON_ROOT .. "battle/wave"
    elseif path:find("/scripts/", 1, true) and path:find("/cutscenes/", 1, true) then
        return FILE_ICON_ROOT .. "cutscene"
    elseif path:find("/scripts/globals/", 1, true) then
        return FILE_ICON_ROOT .. "global"
    elseif path:find("/scripts/objects/", 1, true) then
        return FILE_ICON_ROOT .. "object"
    elseif path:find("/scripts/data/actors/", 1, true) then
        return FILE_ICON_ROOT .. "data/actor"
    elseif path:find("/scripts/data/items/", 1, true) then
        return FILE_ICON_ROOT .. "data/item"
    elseif path:find("/scripts/data/party/", 1, true) then
        return FILE_ICON_ROOT .. "data/party"
    elseif path:find("/scripts/data/spells/", 1, true) then
        return FILE_ICON_ROOT .. "data/spell"
    elseif path:find("/scripts/hooks/", 1, true) then
        return FILE_ICON_ROOT .. "hook"
    elseif path:find("/scripts/shops/", 1, true) then
        return FILE_ICON_ROOT .. "shop"
    elseif path:find("/assets/bubbles/", 1, true) then
        return FILE_ICON_ROOT .. "asset/bubble"
    elseif path:find("/assets/music/", 1, true) then
        return FILE_ICON_ROOT .. "asset/music"
    elseif path:find("/assets/sounds/", 1, true) then
        return FILE_ICON_ROOT .. "asset/sound"
    elseif path:find("/assets/shaders/", 1, true) then
        return FILE_ICON_ROOT .. "asset/shader"
    elseif path:find("/assets/sprites/", 1, true) then
        return FILE_ICON_ROOT .. "asset/image"
    elseif IMAGE_EXTENSIONS[extension] then
        return FILE_ICON_ROOT .. "asset/image"
    elseif AUDIO_EXTENSIONS[extension] then
        return FILE_ICON_ROOT .. "asset/music"
    elseif SHADER_EXTENSIONS[extension] then
        return FILE_ICON_ROOT .. "asset/shader"
    elseif extension == "lua" then
        return FILE_ICON_ROOT .. "generic_lua"
    elseif extension == "json" then
        return FILE_ICON_ROOT .. "generic_json"
    end
    return FILE_ICON_ROOT .. "generic"
end

function EditorFileBrowser:init(editor, workspace)
    super.init(self, 0, 0, 260, 400)
    self.editor = editor
    self.workspace = workspace
    self.search = self:addChild(EditorSearchBar({
        placeholder = "Search project files...",
        on_changed = function(value) self.tree:setFilter(value) end
    }))
    self.new_file_button = self:addChild(EditorButton("New File", function() self:createFile() end))
    self.new_folder_button = self:addChild(EditorButton("New Folder", function() self:createFolder() end))
    self.tree = self:addChild(EditorTreeList({
        on_activate = function(node) self:activateNode(node) end,
        on_rename = function(node, old_name) self:renameNode(node, old_name) end,
        on_move = function(node, old_parent) self:moveNode(node, old_parent) end,
        on_drag_start = function(node)
            if node.data and node.data.type == "file" then
                self.editor:beginProjectFileDrag(node.data, getFileIcon(node.data))
            end
        end,
        on_drag_move = function(_, tree, x, y)
            local global_x, global_y = tree:getGlobalPosition()
            self.editor:updateProjectFileDrag(global_x + x, global_y + y)
        end,
        on_drag_outside = function(_, tree, x, y)
            local global_x, global_y = tree:getGlobalPosition()
            self.editor:finishProjectFileDrag(global_x + x, global_y + y)
        end,
        on_drag_end = function() self.editor:cancelProjectFileDrag() end,
        on_context_menu = function(node, tree, x, y) self:openContextMenu(node, tree, x, y) end,
        on_request_focus = function(control) self.editor.dockspace:setFocus(control) end,
        icon_scale = 1
    }))
    self:refresh()
end

function EditorFileBrowser:addWorkspaceNode(parent, data)
    local node
    if data.type == "directory" then
        node = self.tree:createFolder(parent, data.name, {
            expanded = data.relative_path == "",
            icon = getDirectoryIcon(data),
            renameable = data.relative_path ~= "",
            draggable = data.relative_path ~= ""
        })
        node.data = data
        for _, child in ipairs(data.children or {}) do self:addWorkspaceNode(node, child) end
    else
        node = self.tree:newNode("file", data.name, { data = data, icon = getFileIcon(data) })
        node.parent = parent
        table.insert(parent.children, node)
    end
    return node
end

function EditorFileBrowser:refresh(select_path, previous_path)
    local expanded = {}
    local selected_path = self.tree.selected_node and self.tree.selected_node.data
        and self.tree.selected_node.data.path or nil
    local scroll_row = self.tree.scroll_row
    local function capture(node)
        if node.children and node.data then expanded[node.data.path] = node.expanded == true end
        for _, child in ipairs(node.children or {}) do capture(child) end
    end
    capture(self.tree.root)
    self.tree:clear()
    local root, reason = self.workspace:scan()
    if not root then
        self.editor:addError("Could not scan project files", reason, "filesystem")
        return false
    end
    -- Show the project itself as the single root entry.
    local project = self:addWorkspaceNode(self.tree.root, root)
    local nodes = {}
    local function statePath(path)
        if previous_path and select_path
            and (path == select_path or StringUtils.startsWith(path, select_path .. "/")) then
            return previous_path .. path:sub(#select_path + 1)
        end
        return path
    end
    local function index(node)
        if node.data then nodes[node.data.path] = node end
        if node.children and node.data then
            node.expanded = node.data.path == self.workspace.virtual_root
                or expanded[statePath(node.data.path)] == true
        end
        for _, child in ipairs(node.children or {}) do index(child) end
    end
    index(project)
    self.tree:refreshVisibleNodes()
    self.tree.scroll_row = scroll_row
    self.tree:clampScroll()
    local selected = nodes[select_path or selected_path]
    if selected then
        if select_path then
            local parent = selected.parent
            while parent and parent ~= self.tree.root do
                parent.expanded = true
                parent = parent.parent
            end
            self.tree:refreshVisibleNodes()
        end
        self.tree:selectNode(selected)
    end
    return true
end

function EditorFileBrowser:activateNode(node)
    if not node or not node.data then return false end
    if node.data.type == "directory" then return self.tree:toggleFolder(node) end
    local document, reason, reason_kind = self.workspace:openDocument(node.data.path)
    if not document then
        if reason_kind == "unsupported" and self.editor.message_bar then
            self.editor.message_bar:setStatus(reason, 5)
        else
            self.editor:addError("Could not open " .. node.data.name, reason, "filesystem")
        end
        return false
    end
    self.editor:openDocument(document)
    return true
end

function EditorFileBrowser:openInVSCode(node)
    local real_path = node and node.data and ProjectFileSystem.getRealPath(node.data.path)
    if not real_path then return false end
    return self:openExternal("vscode://file/" .. FileSystemUtils.encodeURLPath(real_path):gsub("^/", ""),
        "open " .. node.name .. " in VS Code")
end

function EditorFileBrowser:openInFileExplorer(node)
    if not node or not node.data then return false end
    local path = node.data.type == "directory" and node.data.path or FileSystemUtils.getDirname(node.data.path)
    local real_path = ProjectFileSystem.getRealPath(path)
    if not real_path then return false end
    return self:openExternal(FileSystemUtils.toFileURL(real_path), "open the containing folder")
end

function EditorFileBrowser:getInsertionDirectory()
    local node = self.tree.selected_node
    if node and node.data then
        return node.data.type == "directory" and node.data.path or FileSystemUtils.getDirname(node.data.path)
    end
    return self.workspace.virtual_root
end

function EditorFileBrowser:getUniquePath(directory, base)
    local path = FileSystemUtils.join(directory, base)
    if not love.filesystem.getInfo(path) then return path end
    local stem, extension = base:match("^(.*)(%.[^.]*)$")
    stem, extension = stem or base, extension or ""
    local index = 2
    repeat
        path = FileSystemUtils.join(directory, stem .. " " .. index .. extension)
        index = index + 1
    until not love.filesystem.getInfo(path)
    return path
end

function EditorFileBrowser:createFile()
    local directory = self:getInsertionDirectory()
    local root = self.workspace.virtual_root
    local templates = Registry.getEditorTemplates("file")
    return self.editor:openCreationDialog({
        title = "Create File", templates = templates, initial_template_id = "core:file_empty",
        context = { directory = directory, root = root },
        fields = {
            {
                id = "directory", name = "Folder", type = "string",
                default = function(_, context, definition)
                    if context.directory == context.root and definition.suggested_directory then
                        return FileSystemUtils.join(context.root, definition.suggested_directory)
                    end
                    return context.directory
                end
            },
            {
                id = "file_name", name = "File Name", type = "string",
                validate = function(value)
                    return not value:find("[/\\]"), "File name cannot contain a path separator"
                end,
                default = function(values, _, definition)
                    local suggestion = definition.suggested_filename or "new.lua"
                    if type(suggestion) == "function" then suggestion = suggestion(values, definition) end
                    return suggestion
                end
            }
        },
        on_create = function(values, definition)
            local normalized_directory = values.directory:gsub("\\", "/"):gsub("/+$", "")
            if normalized_directory ~= root and not StringUtils.startsWith(normalized_directory, root .. "/") then
                return false, "Folder must be inside the current project"
            end
            local path = FileSystemUtils.join(normalized_directory, values.file_name)
            if love.filesystem.getInfo(path) then return false, "A file with that name already exists" end
            local source, reason = EditorTemplateRegistry.render(definition, values, {
                editor = self.editor, workspace = self.workspace, path = path
            })
            if source == nil then return false, reason end
            local written
            written, reason = ProjectFileSystem.writeFile(path, source)
            if not written then return false, reason end
            self:refresh(path)
            return true
        end
    })
end

function EditorFileBrowser:createFolder()
    local path = self:getUniquePath(self:getInsertionDirectory(), "New Folder")
    local created, reason = ProjectFileSystem.createProjectDirectory(path)
    if not created then
        self.editor:addError("Could not create folder", reason, "filesystem")
        return false
    end
    self:refresh(path)
    self.tree:beginRename()
    return true
end

function EditorFileBrowser:renameNode(node, old_name)
    if not node.data then return false end
    if node.data.path == self.workspace.virtual_root then
        node.name = old_name
        return false
    end
    local old_path = node.data.path
    local destination = FileSystemUtils.join(FileSystemUtils.getDirname(old_path), node.name)
    local moved, reason = self.workspace:rename(old_path, destination)
    if not moved then
        node.name = old_name
        self.editor:addError("Could not rename " .. old_name, reason, "filesystem")
        self:refresh(old_path)
        return false
    end
    self:refresh(destination, old_path)
    return true
end

function EditorFileBrowser:moveNode(node, old_parent)
    if not node.data or not old_parent or not old_parent.data then return self:refresh() end
    if node.data.path == self.workspace.virtual_root then return self:refresh(node.data.path) end
    local destination_parent = node.parent and node.parent.data and node.parent.data.path
    if not destination_parent then return self:refresh(node.data.path) end
    local destination = FileSystemUtils.join(destination_parent, node.name)
    if destination == node.data.path then return true end
    local moved, reason = self.workspace:rename(node.data.path, destination)
    if not moved then self.editor:addError("Could not move " .. node.name, reason, "filesystem") end
    self:refresh(moved and destination or node.data.path, moved and node.data.path or nil)
    return moved
end

function EditorFileBrowser:deleteNode(node)
    if not node or not node.data then return false end
    local removed, reason = self.workspace:remove(node.data.path)
    if not removed then
        self.editor:addError("Could not delete " .. node.name, reason, "filesystem")
        return false
    end
    self:refresh()
    return true
end

function EditorFileBrowser:openContextMenu(node, tree, x, y)
    if not node or not node.data then return false end
    local items = {}
    if node.data.type == "file" then
        table.insert(items, { label = "Open", action = function() self:activateNode(node) end })
        for _, item in ipairs(EditorPlugins:getFileContextMenuItems(node.data, {
            browser = self,
            node = node,
            tree = tree
        })) do
            table.insert(items, item)
        end
        table.insert(items, { label = "Open in VS Code", action = function() self:openInVSCode(node) end })
    end
    table.insert(items, { label = node.data.type == "directory" and "Open in File Explorer"
        or "Show in File Explorer", action = function() self:openInFileExplorer(node) end })
    table.insert(items, { label = "New File...", action = function()
        tree:selectNode(node)
        self:createFile()
    end })
    if node.data.type == "directory" then
        table.insert(items, { label = "New Folder", action = function()
            tree:selectNode(node)
            self:createFolder()
        end })
    end
    if node.data.path ~= self.workspace.virtual_root then
        table.insert(items, { label = "Rename", action = function() tree:beginRename(node) end })
        table.insert(items, { label = "Delete", action = function() self:deleteNode(node) end })
    end
    if #items == 0 then return false end
    local gx, gy = tree:getGlobalPosition()
    self.editor.dockspace:openContextMenu(items, gx + x, gy + y, tree)
    return true
end

function EditorFileBrowser:update(dt)
    self.search:setBounds(6, 6, math.max(0, self.width - 12), 28)
    local button_width = math.max(0, (self.width - 18) / 2)
    self.new_file_button:setBounds(6, 40, button_width, 28)
    self.new_folder_button:setBounds(12 + button_width, 40, button_width, 28)
    self.tree:setBounds(0, 74, self.width, math.max(0, self.height - 74))
    super.update(self, dt)
end

return EditorFileBrowser
