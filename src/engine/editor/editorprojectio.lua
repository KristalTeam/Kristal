--- Loads and saves project data used by the editor.
---@class EditorProjectIO : Class
---@field editor Editor
---@overload fun(editor: Editor): EditorProjectIO
local EditorProjectIO = Class()

function EditorProjectIO:init(editor)
    self.editor = editor
end

---@param kind string
---@param id any
---@return boolean valid
---@return string? reason
function EditorProjectIO.validateContentId(kind, id)
    if type(id) ~= "string" or id == "" then return false, "ID is required" end
    if id:find("\\", 1, true) then return false, "IDs must use forward slashes" end
    if not id:match("^[%w_%-/]+$") then
        return false, "IDs may only contain letters, numbers, underscores, dashes, and slashes"
    end
    if id:sub(1, 1) == "/" or id:sub(-1) == "/" then
        return false, "IDs cannot start or end with a slash"
    end
    if id:find("//", 1, true) then return false, "IDs cannot contain empty path segments" end
    for segment in id:gmatch("[^/]+") do
        if segment == "." or segment == ".." then
            return false, "IDs cannot contain relative path segments"
        end
    end
    return true
end

function EditorProjectIO:isValidContentId(id, kind)
    return EditorProjectIO.validateContentId(kind or "content", id)
end

function EditorProjectIO:renameWorldId(world, id)
    local editor = self.editor
    id = tostring(id or ""):match("^%s*(.-)%s*$")
    if not world or id == world.id then return world ~= nil end
    local valid, reason = EditorProjectIO.validateContentId("world", id)
    if not valid then
        editor:addWarning("Invalid world ID '" .. id .. "'", reason, "world_id")
        return false
    end
    local existing = Registry.getEditorWorld(id)
    if existing and existing ~= world then
        editor:addWarning("A world with ID '" .. id .. "' already exists", nil, "world_id")
        return false
    end
    local old_id = world.id
    local document = editor:findWorldDocument(old_id)
    Registry.editor_worlds[old_id] = nil
    world.id = id
    world.data = world.data or {}
    world.data.id = id
    if document then
        document.editor_world = true
        document.world.id = id
    end
    Registry.registerEditorWorld(id, world)
    editor.active_world_id = id
    editor.active_editor_world = world
    editor:clearDiagnostics("world_id")
    if editor.world_browser then editor.world_browser:refresh(id) end
    return true
end

function EditorProjectIO:getContentSavePath(kind, id)
    local valid, reason = EditorProjectIO.validateContentId(kind, id)
    if not valid then
        return nil, "Invalid " .. kind .. " id '" .. tostring(id) .. "': " .. reason
    end
    local directory = kind == "map" and Registry.paths.maps
        or kind == "tileset" and Registry.paths.tilesets
        or kind == "world" and EditorFormat.WORLD_DIRECTORY
    if not directory then return nil, "Unknown editor content kind '" .. tostring(kind) .. "'" end
    return Mod.info.path .. "/scripts/" .. directory .. "/" .. id .. ".json"
end

function EditorProjectIO:getMapSavePath(id)
    local self = self.editor
    local data = Registry.getMapData(id)
    local reader = Registry.getMapReader(id)
    local path = data and data.full_path
    if reader and not reader.LEGACY_FORMAT and type(path) == "string"
        and path:sub(-#EditorFormat.MAP_EXTENSION) == EditorFormat.MAP_EXTENSION
        and (path == Mod.info.path or StringUtils.startsWith(path, Mod.info.path .. "/")) then
        return path
    end
    return self:getContentSavePath("map", id)
end

function EditorProjectIO:getTilesetSavePath(document)
    local self = self.editor
    local tileset = document and document.tileset
    local reader = tileset and tileset.reader
    local path = document and document.data and document.data.full_path
        or tileset and tileset.path
    if reader and not reader.LEGACY_FORMAT and type(path) == "string"
        and path:sub(-#EditorFormat.TILESET_EXTENSION) == EditorFormat.TILESET_EXTENSION
        and (path == Mod.info.path or StringUtils.startsWith(path, Mod.info.path .. "/")) then
        return path
    end
    return self:getContentSavePath("tileset", document.id)
end

function EditorProjectIO:getWorldSavePath(world)
    local self = self.editor
    local path = world and world.data and world.data.full_path
    if type(path) == "string"
        and path:sub(-#EditorFormat.WORLD_EXTENSION) == EditorFormat.WORLD_EXTENSION
        and (path == Mod.info.path or StringUtils.startsWith(path, Mod.info.path .. "/")) then
        return path
    end
    return self:getContentSavePath("world", world.id)
end

function EditorProjectIO:commitFocusedTextInput()
    local self = self.editor
    local control = self.dockspace and self.dockspace.focused_control
    if not control or not control.accepts_text_input then return true end
    if control.pending_submit and control.submitValue
        and control:submitValue() == false then return false end
    self.dockspace:setFocus(nil)
    return true
end

function EditorProjectIO:saveMapDocumentToProject(document, options)
    local self = self.editor
    if not document then return false end
    if not self:commitFocusedTextInput() then return false end
    options = options or {}
    local selected_references = {}
    local selected_primary
    for index, selection in ipairs(self:getSelectedMapObjects(document)) do
        selected_references[index] = {
            map_id = selection.map_id,
            object_id = selection.object_id or document:getObjectId(selection.data)
        }
        if selection == self.selected_map_object then selected_primary = index end
    end
    local layer_properties_active = self.properties_target_owner == self.layers_browser
    local map_properties_active = self.properties_target_owner == self.map_browser
    local ids, seen = {}, {}
    local function add(id)
        if id and not seen[id] then seen[id] = true table.insert(ids, id) end
    end
    add(document.primary_map_id)
    for id in pairs(document.editable_layers or {}) do add(id) end
    table.sort(ids)

    local prepared = {}
    for _, id in ipairs(ids) do
        local data, reason = EditorFormatDocument.buildMapData(document, id)
        if not data then
            self:addError("Could not prepare map '" .. id .. "' for saving", reason, "editor_save")
            return false
        end
        local encoded
        encoded, reason = EditorFormat.encodeMap(data)
        if not encoded then
            self:addError("Could not encode map '" .. id .. "'", reason, "editor_save")
            return false
        end
        local path
        path, reason = self:getMapSavePath(id)
        if not path then
            self:addError("Could not choose a save path for map '" .. id .. "'", reason, "editor_save")
            return false
        end
        local decoded
        decoded, reason = EditorFormat.decodeMap(encoded, path)
        if not decoded then
            self:addError("Saved map '" .. id .. "' did not pass its own decoder", reason, "editor_save")
            return false
        end
        decoded.id, decoded.full_path = id, path
        table.insert(prepared, { id = id, path = path, encoded = encoded, data = decoded })
    end

    for _, entry in ipairs(prepared) do
        local success, reason = ProjectFileSystem.writeFile(entry.path, entry.encoded)
        if not success then
            self:addError("Could not save map '" .. entry.id .. "'", reason, "editor_save")
            return false
        end
    end
    for _, entry in ipairs(prepared) do
        Registry.registerMapData(entry.id, entry.data, EditorMapReader)
        document:adoptSavedMapData(entry.id, entry.data)
        for _, candidate in ipairs(self.map_documents or {}) do
            if candidate ~= document and candidate.map_lookup[entry.id] then
                candidate:invalidatePreview(entry.id)
            end
        end
        if self.standalone_preview_document
            and self.standalone_preview_document ~= document
            and self.standalone_preview_document.map_lookup[entry.id] then
            self.standalone_preview_document:adoptSavedMapData(entry.id, entry.data)
        end
        self.stale_runtime_maps[entry.id] = true
    end
    if not options.defer_mark_saved then self.history:markSaved(document) end
    self:clearDiagnostics("editor_save")
    if self.map_browser then self.map_browser:refresh({ silent = not map_properties_active }) end
    if self.layers_browser and self.active_document == document then
        local map_id = self.layers_browser.map_id or document.primary_map_id
        self.layers_browser:refreshList(document:getSelectedLayer(map_id), not layer_properties_active)
    end
    if #selected_references > 0 then
        local selections = {}
        local primary
        for index, reference in ipairs(selected_references) do
            local selection = document:resolveObjectReference(reference)
            if selection then
                selection.view = document.map_view
                table.insert(selections, selection)
                if index == selected_primary then primary = selection end
            end
        end
        self:selectMapObjects(selections, primary or selections[1])
    end
    return true
end

function EditorProjectIO:saveTilesetDocumentToProject(document)
    local self = self.editor
    if not document then return false end
    if not self:commitFocusedTextInput() then return false end
    local view_state = self.tileset_editor
        and self.tileset_editor.document == document
        and self.tileset_editor:captureViewState() or nil
    local selected_terrain_index, selected_variant_index
    if self.active_tileset_document == document then
        local _, selected_terrain, selected_variant = self:getSelectedTerrain()
        for terrain_index, terrain in ipairs(document:getTerrainSets()) do
            if terrain == selected_terrain then
                selected_terrain_index = terrain_index
                for variant_index, variant in ipairs(terrain.terrain_variants or {}) do
                    if variant == selected_variant then
                        selected_variant_index = variant_index
                        break
                    end
                end
                break
            end
        end
    end
    local data, reason = EditorFormatDocument.buildTilesetData(document)
    if not data then
        self:addError("Could not prepare tileset '" .. document.id .. "' for saving", reason, "editor_save")
        return false
    end
    local encoded
    encoded, reason = EditorFormat.encodeTileset(data)
    if not encoded then
        self:addError("Could not encode tileset '" .. document.id .. "'", reason, "editor_save")
        return false
    end
    local path
    path, reason = self:getTilesetSavePath(document)
    if not path then
        self:addError("Could not choose a save path for tileset '" .. document.id .. "'", reason, "editor_save")
        return false
    end
    local decoded
    decoded, reason = EditorFormat.decodeTileset(encoded, path)
    if not decoded then
        self:addError("Saved tileset '" .. document.id .. "' did not pass its own decoder", reason, "editor_save")
        return false
    end
    decoded.id, decoded.full_path = document.id, path
    local success
    success, reason = ProjectFileSystem.writeFile(path, encoded)
    if not success then
        self:addError("Could not save tileset '" .. document.id .. "'", reason, "editor_save")
        return false
    end
    local tileset_success, tileset = pcall(Tileset, decoded, path, FileSystemUtils.getDirname(path))
    if not tileset_success then
        self:addError("Tileset '" .. document.id .. "' was saved but could not be reloaded",
            tostring(tileset), "editor_save")
        return false
    end
    Registry.registerTileset(document.id, tileset)
    document:adoptSavedData(decoded, tileset)
    self.history:markSaved(document)
    self:clearDiagnostics("editor_save")
    self:setActiveTileset(document, { refresh = true, view_state = view_state })
    local selected_terrain = selected_terrain_index
        and document:getTerrainSets()[selected_terrain_index]
    local selected_variant = selected_terrain and selected_variant_index
        and selected_terrain.terrain_variants[selected_variant_index]
    if selected_variant then
        self:setSelectedTerrain(document, selected_terrain, selected_variant)
    end
    if self.tileset_browser then self.tileset_browser:refresh(document.id) end
    return true
end

function EditorProjectIO:saveWorldToProject(world)
    local self = self.editor
    if not world then return false end
    if not self:commitFocusedTextInput() then return false end
    local document = self:findWorldDocument(world.id)
    if document then world = document.world end
    local data = EditorFormatDocument.buildWorldData(world)
    local encoded, reason = EditorFormat.encodeWorld(data)
    if not encoded then
        self:addError("Could not encode world '" .. tostring(world.id) .. "'", reason, "editor_save")
        return false
    end
    local path
    path, reason = self:getWorldSavePath(world)
    if not path then
        self:addError("Could not choose a save path for world '" .. tostring(world.id) .. "'", reason, "editor_save")
        return false
    end
    local decoded
    decoded, reason = EditorFormat.decodeWorld(encoded, path)
    if not decoded then
        self:addError("Saved world '" .. tostring(world.id) .. "' did not pass its own decoder",
            reason, "editor_save")
        return false
    end
    local success
    success, reason = ProjectFileSystem.writeFile(path, encoded)
    if not success then
        self:addError("Could not save world '" .. tostring(world.id) .. "'", reason, "editor_save")
        return false
    end
    decoded.id, decoded.full_path = world.id, path
    world.data = decoded
    world.name = decoded.name or world.name
    world.virtual = false
    Registry.registerEditorWorld(world.id, world)
    self:clearDiagnostics("editor_save")
    if self.world_browser then self.world_browser:refresh(world.id) end
    if self.message_bar then self.message_bar:setStatus("Saved world: " .. tostring(world.name or world.id)) end
    return true
end

function EditorProjectIO:saveWorldDocumentToProject(world)
    local self = self.editor
    if not world then return false end
    local document = self:findWorldDocument(world.id)
    if document then
        world = document.world
        if not self:saveMapDocumentToProject(document, { defer_mark_saved = true }) then return false end
    end
    if not self:saveWorldToProject(world) then return false end
    if document then self.history:markSaved(document) end
    return true
end

function EditorProjectIO:saveAllDocuments()
    local self = self.editor
    for _, document in ipairs(self.map_documents or {}) do
        if document:isDirty() then
            local saved = document.editor_world
                and self:saveWorldDocumentToProject(document.world)
                or self:saveMapDocumentToProject(document)
            if not saved then return false end
        end
    end
    for _, document in ipairs(self.tileset_documents or {}) do
        if document:isDirty() and not self:saveTilesetDocumentToProject(document) then return false end
    end
    for _, provider in ipairs(self.document_providers:getAll()) do
        if provider:saveAll() == false then return false end
    end
    return true
end

function EditorProjectIO:saveActiveDocument()
    local self = self.editor
    local provider_result = self.document_providers:invokeFocused("saveActive")
    if provider_result ~= nil then return provider_result end
    local focused = self.dockspace and self.dockspace.focused_control
    while focused do
        if focused == self.world_browser then
            return self:saveWorldDocumentToProject(self.active_editor_world)
        end
        if focused == self.tileset_editor or focused == self.tile_palette
            or focused == self.terrain_palette or focused == self.tileset_browser then
            return self:saveTilesetDocumentToProject(self.active_tileset_document)
        end
        focused = focused.parent
    end
    if self.active_document and self.active_document.editor_world then
        return self:saveWorldDocumentToProject(self.active_document.world)
    end
    return self:saveMapDocumentToProject(self.active_document)
end

function EditorProjectIO:createNewMap(id, name, options)
    local editor = self.editor
    options = options or {}
    local valid, reason = EditorProjectIO.validateContentId("map", id)
    if not valid then return nil, "Invalid map id: " .. reason end
    if Registry.hasMap(id) then return nil, "A map with that id already exists" end
    local data = {
        version = EditorFormat.MAP_FORMAT_VERSION,
        kristal_version = tostring(Kristal.Version),
        id = id,
        name = name or StringUtils.titleCase(id:gsub("[/_]", " ")),
        width = options.width or 16,
        height = options.height or 12,
        grid_width = options.grid_width or 40,
        grid_height = options.grid_height or 40,
        background_color = TableUtils.copy(options.background_color or { 0, 0, 0, 0 }, true),
        layers = {},
        properties = {},
        __editor_property_types = {},
        __map_reader = EditorMapReader
    }
    Registry.registerMapData(id, data, EditorMapReader)
    local document = editor:createMapDocument(id)
    if not document then return nil, "Could not create an editor document" end
    if options.default_layers then
        document:createEditableLayer("tile", id, nil, { name = "Tiles" })
        document:createEditableLayer("collision", id, nil, { name = "Collision" })
        document:createEditableLayer("objects", id, nil, {
            name = "Markers",
            color = { 0.49, 0, 1, 1 }
        })
        document:createEditableLayer("objects", id, nil, {
            name = "Objects",
            properties = { spawn = true }
        })
    end
    editor.history.serial = editor.history.serial + 1
    document.history_revision = editor.history.serial
    editor:activateMapDocument(document)
    editor:onHistoryChanged({ document }, false)
    return document
end

function EditorProjectIO:hasUnsavedChanges()
    local self = self.editor
    for _, document in ipairs(self.map_documents or {}) do
        if document:isDirty() then return true end
    end
    for _, document in ipairs(self.tileset_documents or {}) do
        if document:isDirty() then return true end
    end
    if self.document_providers:any("hasUnsavedChanges") then return true end
    return false
end

---@param options? {message?: string, save?: function, save_label?: string, dirty?: boolean}

function EditorProjectIO:confirmUnsavedChanges(options)
    local self = self.editor
    options = options or {}
    local dirty = options.dirty
    if dirty == nil then dirty = self:hasUnsavedChanges() end
    if not dirty then return true end

    local buttons = {
        options.save_label or "Save All",
        "Discard",
        "Cancel",
        enterbutton = 1,
        escapebutton = 3
    }
    local pressed = love.window.showMessageBox(
        "Unsaved Changes",
        options.message or "Save your changes before leaving the editor?",
        buttons,
        "warning",
        true
    )
    if pressed == 1 then
        local save = options.save or function() return self:saveAllDocuments() end
        return save() == true
    end
    return pressed == 2
end

return EditorProjectIO
