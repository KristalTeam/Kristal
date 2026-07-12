---@class EditorWorldBrowser : EditorControl
---@overload fun(editor: table): EditorWorldBrowser
local EditorWorldBrowser, super = Class(EditorControl)

function EditorWorldBrowser:init(editor)
    super.init(self, 0, 0, 260, 320)
    self.editor = editor
    self.search = self:addChild(EditorSearchBar({
        placeholder = "Search worlds...",
        on_changed = function(value) self.list:setFilter(value) end
    }))
    self.new_button = self:addChild(EditorButton("New World", function() self:createWorld() end))
    self.edit_button = self:addChild(EditorButton("Edit", function() self:editSelectedWorld() end))
    self.save_button = self:addChild(EditorButton("Save", function() self:saveSelectedWorld() end))
    self.add_map_button = self:addChild(EditorButton("Add Map...", function() self:openAddMapMenu() end))
    self.list = self:addChild(EditorItemList({
        on_select = function(item) self:selectWorld(item and item.data) end,
        on_activate = function(item) if item then editor:openWorld(item.data) end end,
        on_rename = function(item, _, name) self:renameWorld(item.data, name) end,
        on_context_menu = function(item, list, x, y) self:openContextMenu(item, list, x, y) end,
        on_request_focus = function(control) editor.dockspace:setFocus(control) end
    }))
    self.maps_list = self:addChild(EditorItemList({
        on_select = function(item) if item then self:selectWorldMap(item.data) end end,
        on_activate = function(item) if item then self:focusMap(item.data.id) end end,
        on_context_menu = function(item, list, x, y) self:openMapContextMenu(item, list, x, y) end,
        on_request_focus = function(control) editor.dockspace:setFocus(control) end
    }))
    self:refresh()
end

function EditorWorldBrowser:selectWorldMap(entry)
    local world = self.editor.active_editor_world
    if not world or not entry then return false end
    local document = self.editor:findWorldDocument(world.id)
    if document and document.map_view then document.map_view.selected_world_map_id = entry.id end
    self.editor:setPropertiesTarget({
        title = "World Map: " .. entry.id,
        world_id = world.id,
        world_map_id = entry.id,
        history_owner = document,
        fields = {
            { label = "Map", readonly = true, get = function() return entry.id end,
                set = function() return false end },
            EditorPropertyFields.number(entry, "X", "x"),
            EditorPropertyFields.number(entry, "Y", "y")
        },
        on_changed = function()
            local current = document and document.world or world
            Registry.registerEditorWorld(current.id, current)
            self.editor.active_editor_world = current
        end
    }, self)
    return true
end

function EditorWorldBrowser:refresh(selected_id)
    local items = {}
    for id, world in pairs(Registry.editor_worlds or {}) do
        table.insert(items, {
            id = id, label = world.name or id, data = world,
            icon = "editor/ui/layer/default"
        })
    end
    table.sort(items, function(a, b) return a.label:lower() < b.label:lower() end)
    self.list:setItems(items)
    for index, item in ipairs(self.list.filtered_items) do
        if item.id == (selected_id or self.editor.active_world_id) then
            self.list:select(index)
            break
        end
    end
end

function EditorWorldBrowser:selectWorld(world)
    self.editor.active_editor_world = world
    self.editor.active_world_id = world and world.id or nil
    if not world then
        self.maps_list:setItems({})
        self.editor:clearPropertiesTarget(self)
        return
    end
    self:refreshMaps(world)
    world.properties = world.properties or {}
    world.__editor_property_types = world.__editor_property_types or {}
    local property_set = EditorPropertySet(world.properties, world.__editor_property_types)
    local document = self.editor:findWorldDocument(world.id)
    self.editor:setPropertiesTarget({
        title = "World: " .. (world.name or world.id),
        history_owner = document,
        property_set = property_set,
        properties = world.properties,
        property_types = world.__editor_property_types,
        fields = {
            { label = "Name", get = function() return world.name or world.id end,
                set = function(value) world.name = value return true end },
            { label = "ID", get = function() return world.id end,
                set = function(value) return self.editor:renameWorldId(world, value) end },
            { label = "Maps", readonly = true, get = function() return #(world.maps or {}) end,
                set = function() return false end }
        },
        on_changed = function() self:refresh(world.id) end
    }, self)
end

function EditorWorldBrowser:openAddMapMenu()
    local world = self.editor.active_editor_world
    if not world then return false end
    local ids, seen = {}, {}
    for id in pairs(Registry.map_data or {}) do
        seen[id] = true
        table.insert(ids, id)
    end
    for id in pairs(Registry.maps or {}) do
        if not seen[id] then table.insert(ids, id) end
    end
    table.sort(ids)
    local items = {}
    for _, id in ipairs(ids) do
        if not world:hasMap(id) then
            local map_id = id
            table.insert(items, {
                label = map_id,
                action = function()
                    if self.editor:addMapToWorld(world, map_id) then
                        local current = Registry.getEditorWorld(world.id) or world
                        self.editor.active_editor_world = current
                        self:refreshMaps(current)
                        self:selectWorld(current)
                    end
                end
            })
        end
    end
    if #items == 0 then items[1] = { label = "No maps available", enabled = false } end
    local x, y = self.add_map_button:getGlobalPosition()
    self.editor.dockspace:openContextMenu(items, x, y + self.add_map_button.height, self.add_map_button)
    return true
end

function EditorWorldBrowser:refreshMaps(world)
    world = world or self.editor.active_editor_world
    local items = {}
    local document = world and self.editor:findWorldDocument(world.id)
    for _, entry in ipairs(world and world.maps or {}) do
        local primary = document and document.primary_map_id == entry.id
        table.insert(items, {
            id = entry.id,
            label = entry.id .. (primary and "  (view origin)" or ""),
            data = entry,
            icon = "editor/ui/layer/default"
        })
    end
    table.sort(items, function(a, b) return a.id:lower() < b.id:lower() end)
    self.maps_list:setItems(items)
end

function EditorWorldBrowser:createWorld()
    local index, id = 1, "new_world"
    while Registry.getEditorWorld(id) do
        index = index + 1
        id = "new_world_" .. index
    end
    local world = EditorWorld(id)
    world.name = "New World"
    world.virtual = true
    local document = self.editor.active_document
    if document and document.primary_map_id then
        world:addMap(document.primary_map_id, 0, 0, { explicit_companion = true })
    end
    Registry.registerEditorWorld(id, world)
    self:refresh(id)
    self:selectWorld(world)
    if self.editor:openWorld(world) then
        local opened = self.editor:findWorldDocument(id)
        if opened then
            self.editor.history.serial = self.editor.history.serial + 1
            opened.history_revision = self.editor.history.serial
            self.editor:onHistoryChanged({ opened }, false)
        end
    end
    return world
end

function EditorWorldBrowser:editSelectedWorld()
    local world = self.editor.active_editor_world
    return world and self.editor:openWorld(world) or false
end

function EditorWorldBrowser:saveSelectedWorld()
    local world = self.editor.active_editor_world
    return world and self.editor:saveWorldDocumentToProject(world) or false
end

function EditorWorldBrowser:focusMap(map_id)
    local world = self.editor.active_editor_world
    if not world or not self.editor:openWorld(world) then return false end
    local document = self.editor:findWorldDocument(world.id)
    if not document or not document.map_view then return false end
    local entry = document.map_lookup[map_id]
    if entry then self:selectWorldMap(entry) end
    document.map_view:focusMap(map_id)
    return true
end

function EditorWorldBrowser:removeMap(map_id)
    local world = self.editor.active_editor_world
    if not world then return false end
    if not self.editor:removeMapFromWorld(world, map_id) then return false end
    self:refreshMaps(world)
    self:selectWorld(world)
    return true
end

function EditorWorldBrowser:openMapContextMenu(item, list, x, y)
    if not item then return false end
    local items = {
        { label = "Focus in World Editor", action = function() self:focusMap(item.data.id) end },
        { label = "Remove from World", action = function() self:removeMap(item.data.id) end }
    }
    local gx, gy = list:getGlobalPosition()
    self.editor.dockspace:openContextMenu(items, gx + x, gy + y, list)
    return true
end

function EditorWorldBrowser:renameWorld(world, name)
    if not world then return false end
    local document = self.editor:findWorldDocument(world.id)
    local function rename()
        world.name = name
        if document then
            document.world.name = name
            document.panel.title = name .. (document:isDirty() and " *" or "")
        end
        return true
    end
    if document then self.editor:performHistoryEdit("Rename World", document, rename) else rename() end
    self:refresh(world.id)
    self:selectWorld(world)
    return true
end

function EditorWorldBrowser:openContextMenu(item, list, x, y)
    local items = { { label = "New World", action = function() self:createWorld() end } }
    if item then
        table.insert(items, { label = "Open", action = function() self.editor:openWorld(item.data) end })
        table.insert(items, { label = "Save", action = function()
            self.editor:saveWorldDocumentToProject(item.data)
        end })
        table.insert(items, { label = "Rename", action = function() list:beginRename(item) end })
        if item.data.virtual then
            table.insert(items, { label = "Remove", action = function()
                Registry.editor_worlds[item.data.id] = nil
                self:refresh()
            end })
        end
    end
    local gx, gy = list:getGlobalPosition()
    self.editor.dockspace:openContextMenu(items, gx + x, gy + y, list)
end

function EditorWorldBrowser:update(dt)
    local padding, gap = 8, 6
    local width = math.max(0, self.width - padding * 2)
    self.search:setBounds(padding, padding, width, 28)
    local button_width = math.max(40, (width - gap * 2) / 3)
    self.new_button:setBounds(padding, 44, button_width, 28)
    self.edit_button:setBounds(padding + button_width + gap, 44, button_width, 28)
    self.save_button:setBounds(padding + (button_width + gap) * 2, 44, button_width, 28)
    self.edit_button.enabled = self.editor.active_editor_world ~= nil
        and #(self.editor.active_editor_world.maps or {}) > 0
    self.save_button.enabled = self.editor.active_editor_world ~= nil

    local available = math.max(0, self.height - 108)
    local world_height = math.max(60, math.floor(available * 0.46))
    self.list:setBounds(padding, 80, width, world_height)
    local maps_y = 80 + world_height + 24
    self.add_map_button:setBounds(math.max(padding, self.width - padding - 92), maps_y - 22, 92, 20)
    self.add_map_button.enabled = self.editor.active_editor_world ~= nil
    self.maps_list:setBounds(padding, maps_y, width, math.max(0, self.height - maps_y - 28))
    super.update(self, dt)
end

function EditorWorldBrowser:drawSelf()
    Draw.setColor(0.08, 0.08, 0.09, 1)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    local font = EditorFont.get(14)
    love.graphics.setFont(font)
    Draw.setColor(0.68, 0.68, 0.72, 1)
    love.graphics.print("World Maps", 8, self.maps_list.y - 19)
    Draw.setColor(0.50, 0.50, 0.54, 1)
    love.graphics.print("Drop Maps to add; drag map borders to position", 8, self.height - 20)
end

return EditorWorldBrowser
