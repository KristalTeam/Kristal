---@class EditorMapBrowser : EditorControl
---@overload fun(editor: table): EditorMapBrowser
local EditorMapBrowser, super = Class(EditorControl)

local function uniqueName(parent, base)
    local used = {}
    for _, child in ipairs(parent.children) do used[child.name:lower()] = true end
    if not used[base:lower()] then return base end
    local index = 2
    while used[(base .. " " .. index):lower()] do index = index + 1 end
    return base .. " " .. index
end

local function nodeRegistryId(node)
    local parts = {}
    local current = node
    while current and not current.root do
        table.insert(parts, 1, EditorFormat.slugId(current.name, current.type))
        current = current.parent
    end
    return table.concat(parts, "/")
end

function EditorMapBrowser:init(editor)
    super.init(self, 0, 0, 240, 400)
    self.editor = editor
    self.search = self:addChild(EditorSearchBar({
        placeholder = "Search maps...",
        on_changed = function(value) self.tree:setFilter(value) end
    }))
    self.new_map_button = self:addChild(EditorButton("New Map", function() self:createMap() end))
    self.new_folder_button = self:addChild(EditorButton("New Folder", function() self:createFolder() end))
    self.tree = self:addChild(EditorTreeList({
        on_select = function(node) self:selectNode(node) end,
        on_activate = function(node) self:activateNode(node) end,
        on_rename = function(node) self:renamedNode(node) end,
        on_drag_start = function(node)
            self.editor:beginDragPreview(node.type, node.name,
                node.type == "folder" and "editor/ui/folder" or "editor/ui/layer/default", node.registry_id)
        end,
        on_drag_outside = function(node, tree, x, y) self:dropOutside(node, tree, x, y) end,
        on_drag_move = function(node, tree, x, y)
            local gx, gy = tree:getGlobalPosition()
            self.editor:updateDragPreview(gx + x, gy + y)
            self:updateDockPreview(node, tree, x, y)
        end,
        on_drag_end = function()
            self.editor.dockspace.dock_preview = nil
            self.editor:finishDragPreview()
        end,
        on_context_menu = function(node, tree, x, y) self:openNodeContextMenu(node, tree, x, y) end,
        on_request_focus = function(control) self.editor.dockspace:setFocus(control) end
    }))
    self.list = self.tree
    self:refresh()
end

function EditorMapBrowser:selectNode(node)
    if not node then
        self.editor:clearPropertiesTarget(self)
        return
    end
    node.editor_properties = node.editor_properties or {}
    node.editor_property_types = node.editor_property_types or {}
    local data = node.registry_id and Registry.getMapData(node.registry_id)
    if data then
        data.properties = data.properties or {}
        data.__editor_property_types = data.__editor_property_types or {}
    end
    local property_values = data and data.properties or node.editor_properties
    local property_types = data and data.__editor_property_types or node.editor_property_types
    local property_set = EditorPropertySet(property_values, property_types)
    if node.type == "map" then
        property_set:registerProperty("name", "string")
        property_set:registerProperty("music", "string")
        property_set:registerProperty("keepmusic", "boolean", { name = "Keep Music" })
        property_set:registerProperty("light", "boolean")
        property_set:registerProperty("border", "string")
    end
    local reader_class = node.registry_id and Registry.getMapReader(node.registry_id)
    local fields = {
        {
            label = "Name",
            get = function() return node.name end,
            set = function() return false end,
            readonly = true
        }
    }
    if node.registry_id then
        table.insert(fields, {
            label = "Path",
            get = function() return node.registry_id end,
            set = function() return false end,
            readonly = true
        })
        table.insert(fields, {
            label = "Format",
            get = function() return reader_class and reader_class.LEGACY_FORMAT and "Legacy Tiled" or "Editor" end,
            set = function() return false end,
            readonly = true
        })
    end
    self.editor:setPropertiesTarget({
        title = node.type == "folder" and "Folder" or "Map",
        fields = fields,
        properties = data and data.properties or node.editor_properties,
        property_types = data and data.__editor_property_types or node.editor_property_types,
        property_set = property_set
    }, self)
end

function EditorMapBrowser:renamedNode(node, old_name)
    if node.type == "map" and node.virtual then
        local id = nodeRegistryId(node)
        local document, reason = self.editor:createNewMap(id, node.name)
        if not document then
            node.name = old_name
            self.editor:addError("Could not create map '" .. id .. "'", reason, "editor_save")
        else
            node.registry_id = id
            node.virtual = false
            self:refresh()
            return
        end
    end
    self:selectNode(node)
end

function EditorMapBrowser:updateDockPreview(node, tree, x, y)
    if node.type ~= "map" or not node.registry_id then
        self.editor.dockspace.dock_preview = nil
        return
    end
    local tree_x, tree_y = tree:getGlobalPosition()
    self.editor.dockspace.dock_preview = self.editor:getMapPanelDropTarget(tree_x + x, tree_y + y)
end

function EditorMapBrowser:getRegisteredMapIds()
    local ids, seen = {}, {}
    for id in pairs(Registry.map_data or {}) do
        seen[id] = true
        table.insert(ids, id)
    end
    for id in pairs(Registry.maps or {}) do
        if not seen[id] then table.insert(ids, id) end
    end
    table.sort(ids)
    return ids
end

function EditorMapBrowser:refresh()
    self.tree:clear()
    local folders = { [""] = self.tree.root }
    local maps = {}
    for _, id in ipairs(self:getRegisteredMapIds()) do
        local parts = StringUtils.split(id, "/", true)
        local parent, path = self.tree.root, ""
        for index = 1, #parts - 1 do
            local name = parts[index]
            path = path == "" and name or (path .. "/" .. name)
            if not folders[path] then
                folders[path] = self.tree:createFolder(parent, name, { virtual = false })
            end
            parent = folders[path]
        end
        local reader_class = Registry.getMapReader(id)
        local legacy_format = reader_class and reader_class.LEGACY_FORMAT == true
        local node = self.tree:createMap(parent, parts[#parts] or id, {
            registry_id = id,
            virtual = false,
            badge_text = legacy_format and "*" or nil,
            badge_color = legacy_format and { 1, 0.82, 0.16, 1 } or nil
        })
        maps[id] = node
    end
    self.tree:sort()
    local current_id = Game.world and Game.world.map and Game.world.map.id
    if current_id and maps[current_id] then self.tree:selectNode(maps[current_id]) end
end

function EditorMapBrowser:createFolder(parent)
    parent = parent or self.tree:getInsertionParent()
    local node = self.tree:createFolder(parent, uniqueName(parent, "New Folder"), { virtual = true })
    self.tree:beginRename(node)
    return node
end

function EditorMapBrowser:createMap(parent)
    parent = parent or self.tree:getInsertionParent()
    local prefix = parent and not parent.root and nodeRegistryId(parent) or ""
    local id = prefix ~= "" and (prefix .. "/new_map") or "new_map"
    local index, candidate = 1, id
    while Registry.getMap(candidate) or Registry.getMapData(candidate) do
        index = index + 1
        candidate = id .. "_" .. index
    end
    local template = Registry.getEditorTemplate("core:map")
    return self.editor:openCreationDialog({
        title = "Create Map", templates = { template },
        context = { parent = parent, defaults = { id = candidate,
            name = StringUtils.titleCase((candidate:match("([^/]+)$") or candidate):gsub("[_%-]", " ")) } },
        on_create = function(values)
            if prefix ~= "" and not values.id:find("/", 1, true) then values.id = prefix .. "/" .. values.id end
            local color = ColorUtils.tryHexToRGB(values.background_color)
            if not color then return false, "Background must be a hex RGB or RGBA color" end
            local document, reason = self.editor:createNewMap(values.id, values.name, {
                width = values.width, height = values.height,
                grid_width = values.grid_width, grid_height = values.grid_height,
                background_color = color
            })
            if not document then return false, reason end
            self:refresh()
            return true
        end
    })
end

function EditorMapBrowser:openNodeContextMenu(node, tree, x, y)
    local parent = node and (node.type == "folder" and node or node.parent) or tree.root
    local items = {}
    if node and node.type == "map" and node.registry_id then
        table.insert(items, { label = "Open", action = function() self:activateNode(node) end })
        local document = self.editor:findMapDocument(node.registry_id)
        if document then
            table.insert(items, {
                label = "Save",
                action = function() self.editor:saveMapDocumentToProject(document) end
            })
        end
    end
    if not node or node.type == "folder" then
        table.insert(items, { label = "New Map", action = function() self:createMap(parent) end })
        table.insert(items, { label = "New Folder", action = function() self:createFolder(parent) end })
    end
    if node then
        if node.type == "folder" then
            table.insert(items, {
                label = node.expanded and "Collapse" or "Expand",
                action = function() tree:toggleFolder(node) end
            })
        end
        table.insert(items, { label = "Rename", action = function() tree:beginRename(node) end })
        if node.virtual then
            table.insert(items, { label = "Remove", action = function() tree:removeNode(node) end })
        end
    end
    local global_x, global_y = tree:getGlobalPosition()
    self.editor.dockspace:openContextMenu(items, global_x + x, global_y + y, tree)
end

function EditorMapBrowser:activateNode(node)
    if not node or node.type ~= "map" then return false end
    if node.registry_id then return self.editor:openMap(node.registry_id) end
    return true
end

function EditorMapBrowser:dropOutside(node, tree, x, y)
    if node.type ~= "map" or not node.registry_id then return false end
    local tree_x, tree_y = tree:getGlobalPosition()
    if self.editor:addMapToWorldAtScreen(node.registry_id, tree_x + x, tree_y + y) then return true end
    local target = self.editor:getMapPanelDropTarget(tree_x + x, tree_y + y)
    if target then return self.editor:openMapTab(node.registry_id, target) end
    return false
end

function EditorMapBrowser:update(dt)
    local padding, gap = 8, 8
    local content_width = math.max(0, self.width - padding * 2)
    local button_width = math.max(0, (content_width - gap) / 2)
    self.search:setBounds(padding, padding, content_width, 28)
    self.new_map_button:setBounds(padding, 44, button_width, 28)
    self.new_folder_button:setBounds(padding + button_width + gap, 44, button_width, 28)
    self.tree:setBounds(padding, 80, content_width, math.max(0, self.height - 88))
    super.update(self, dt)
end

return EditorMapBrowser
