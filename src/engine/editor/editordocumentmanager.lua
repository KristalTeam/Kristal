---@class EditorDocumentManager : Class
---@field editor Editor
---@overload fun(editor: Editor): EditorDocumentManager
local EditorDocumentManager = Class()

function EditorDocumentManager:init(editor)
    self.editor = editor
end

function EditorDocumentManager:getNextDocumentPanelId()
    local self = self.editor
    local index = 1
    while self.dockspace.panels["map_document:" .. index] do index = index + 1 end
    return "map_document:" .. index
end

function EditorDocumentManager:createMapDocument(id, panel_id)
    local self = self.editor
    if not Registry.hasMap(id) then return nil end
    if type(panel_id) ~= "string" or not panel_id:match("^map_document:%d+$")
        or self.dockspace.panels[panel_id] then
        panel_id = self:getNextDocumentPanelId()
    end
    local document = EditorMapDocument(self, id)
    local map_view = EditorMapView(self, document)
    local panel = EditorPanel(panel_id, id, map_view, {
        minimum_width = SCREEN_WIDTH,
        minimum_height = SCREEN_HEIGHT + 28,
        preferred_width = SCREEN_WIDTH,
        preferred_height = SCREEN_HEIGHT + 28,
        on_remove = function()
            self:removeMapDocument(document)
        end,
        on_activate = function()
            if not self.suppress_panel_activation then
                self:activateMapDocument(document, { select_panel = false })
            end
        end
    })
    panel.map_document = document
    panel.map_view = map_view
    document.panel = panel
    document.map_view = map_view
    document.game_view = map_view
    document.game_view_state = nil
    table.insert(self.map_documents, document)
    self.dockspace:registerPanel(panel, "center")
    return document
end

function EditorDocumentManager:configureWorldDocument(document, source, primary_map_id)
    local self = self.editor
    if not document or not source then return false end
    local world = EditorWorld(source.id)
    world.name = source.name or source.id
    world.data = TableUtils.copy(source.data or {}, true)
    world:initializeFormatExtensions()
    world.properties = TableUtils.copy(source.properties or {}, true)
    world.__editor_property_types = TableUtils.copy(source.__editor_property_types or {}, true)
    world.virtual = source.virtual
    for _, entry in ipairs(source.maps or {}) do
        world:addMap(entry.id, entry.x, entry.y, {
            explicit_companion = entry.explicit_companion ~= false
        })
    end
    local primary = primary_map_id or source.primary_map_id
        or (world.maps[1] and world.maps[1].id)
    if not primary or not world.map_lookup[primary] then return false end
    world.primary_map_id = primary
    for _, entry in ipairs(world.maps) do entry.primary = entry.id == primary end
    document.world = world
    document.editor_world = true
    document.primary_map_id = primary
    document.maps = world.maps
    document.map_lookup = world.map_lookup
    if document.map_view then document.map_view.active_map_id = primary end
    if document.panel then
        document.panel.title = (world.name or world.id) .. (document:isDirty() and " *" or "")
    end
    return true
end

function EditorDocumentManager:setupTilesetDocuments(session)
    local self = self.editor
    self.tileset_documents = {}
    local ids = {}
    for id in pairs(Registry.tilesets or {}) do table.insert(ids, id) end
    table.sort(ids)
    for _, id in ipairs(ids) do
        table.insert(self.tileset_documents, EditorTilesetDocument(self, id, Registry.getTileset(id)))
    end
    local desired = session and session.active_tileset_id
    self.active_tileset_document = nil
    for _, document in ipairs(self.tileset_documents) do
        if document.id == desired then self.active_tileset_document = document break end
    end
    self.active_tileset_document = self.active_tileset_document or self.tileset_documents[1]
    self.active_tileset_id = self.active_tileset_document and self.active_tileset_document.id or nil
end

function EditorDocumentManager:setActiveTileset(document, options)
    local self = self.editor
    options = options or {}
    if type(document) == "string" then
        for _, candidate in ipairs(self.tileset_documents or {}) do
            if candidate.id == document then document = candidate break end
        end
    end
    if not document or not document.data then return false end
    local changed_document = self.active_tileset_document ~= document
    self.active_tileset_document = document
    self.active_tileset_id = document.id
    self.selected_terrain_set = nil
    self.selected_terrain_variant = nil
    if changed_document then
        self.selected_terrain_id = nil
        self.selected_terrain_variant_id = nil
    end
    if self.tileset_panel then
        self.tileset_panel.title = "Tileset Editor" .. (document:isDirty() and " *" or "")
    end
    if self.tile_palette then self.tile_palette:setTilesetDocument(document) end
    if self.terrain_palette then
        self.terrain_palette:setDocument(document, options.refresh == true)
    end
    if self.tileset_editor and self.tileset_panel and self.tileset_panel.visible then
        self.tileset_editor:setDocument(document, {
            preserve_mode = not changed_document,
            preserve_tile = not changed_document,
            preserve_selection = not changed_document and options.view_state == nil,
            view_state = options.view_state
        })
    end
    return true
end

function EditorDocumentManager:setSelectedTerrain(document, terrain, variant)
    local self = self.editor
    if not document or not terrain or not variant
        or not TableUtils.contains(document:getTerrainSets(), terrain)
        or not TableUtils.contains(terrain.terrain_variants or {}, variant) then return false end
    if self.active_tileset_document ~= document then self:setActiveTileset(document) end
    self.selected_terrain_set = terrain
    self.selected_terrain_variant = variant
    self.selected_terrain_id = terrain.id
    self.selected_terrain_variant_id = variant.id
    self:clearDiagnostics("tile_editing")
    self:clearDiagnostics("terrain_editing")
    if self.terrain_palette and self.terrain_palette.document == document then
        self.terrain_palette:selectCurrent()
    end
    if self.tileset_editor and self.tileset_editor.document == document then
        self.tileset_editor:rebuildTerrainRuleLookup()
    end
    return true
end

function EditorDocumentManager:setBrushSize(value)
    local self = self.editor
    value = MathUtils.clamp(MathUtils.round(tonumber(value) or 1), 1, 32)
    self.brush_size = value
    if self.toolbar then self.toolbar:setBrushSize(value) end
    return true
end

function EditorDocumentManager:getBrushSize()
    local self = self.editor
    return MathUtils.clamp(MathUtils.round(tonumber(self.brush_size) or 1), 1, 32)
end

function EditorDocumentManager:getSelectedTerrain()
    local self = self.editor
    local document = self.active_tileset_document
    if not document then return nil end
    local selected_terrain = self.selected_terrain_set
    local selected_variant = self.selected_terrain_variant
    if selected_terrain and selected_variant
        and TableUtils.contains(document:getTerrainSets(), selected_terrain)
        and TableUtils.contains(selected_terrain.terrain_variants or {}, selected_variant) then
        self.selected_terrain_id = selected_terrain.id
        self.selected_terrain_variant_id = selected_variant.id
        return document, selected_terrain, selected_variant
    end
    for _, terrain in ipairs(document:getTerrainSets()) do
        if terrain.id == self.selected_terrain_id then
            local variant = document:getTerrainVariant(terrain, self.selected_terrain_variant_id)
            if variant then
                self.selected_terrain_set = terrain
                self.selected_terrain_variant = variant
                return document, terrain, variant
            end
        end
    end
    local selected_item = self.terrain_palette and self.terrain_palette.document == document
        and self.terrain_palette.list:getSelectedItem() or nil
    local selected_data = selected_item and selected_item.data
    if selected_data then
        local terrain = selected_data.terrain
        local variant = selected_data.variant
            or terrain and terrain.terrain_variants and terrain.terrain_variants[1]
        if terrain and variant then
            self.selected_terrain_set = terrain
            self.selected_terrain_variant = variant
            self.selected_terrain_id = terrain.id
            self.selected_terrain_variant_id = variant.id
            return document, terrain, variant
        end
    end
    for _, terrain in ipairs(document:getTerrainSets()) do
        local variant = terrain.terrain_variants and terrain.terrain_variants[1]
        if variant then
            self.selected_terrain_set = terrain
            self.selected_terrain_variant = variant
            self.selected_terrain_id = terrain.id
            self.selected_terrain_variant_id = variant.id
            return document, terrain, variant
        end
    end
    self.selected_terrain_set = nil
    self.selected_terrain_variant = nil
    self.selected_terrain_id = nil
    self.selected_terrain_variant_id = nil
    return document
end

function EditorDocumentManager:rebuildTerrain(scope)
    local self = self.editor
    local document = self.active_document
    local view = document and document.map_view
    if not view then return false end
    local map_id = view.active_map_id or document.primary_map_id
    local layers = {}
    if scope == "map" then
        for _, layer in ipairs(document:getAllEditableLayers(map_id)) do
            local layer_type = Registry.getLayerType(layer._editor_type_id)
            if layer_type and layer_type.kind == "tile" then table.insert(layers, layer) end
        end
    else
        local layer = document:getSelectedTileLayer(map_id)
        if layer then table.insert(layers, layer) end
    end
    if #layers == 0 then
        self:addWarning("Select a tile layer before rebuilding terrain", nil, "terrain_routing")
        return false
    end
    self:beginHistoryTransaction(scope == "map" and "Rebuild Map Terrain"
        or "Rebuild Layer Terrain", document)
    local changed = false
    for _, layer in ipairs(layers) do
        local layer_changed, reason = view:rebuildTerrain(map_id, nil, layer)
        changed = changed or layer_changed
        if reason then
            self:cancelHistoryTransaction()
            self:addWarning(reason, nil, "terrain_routing")
            return false
        end
    end
    if changed then
        self:markHistoryChanged()
        self:commitHistoryTransaction()
    else
        self:cancelHistoryTransaction()
    end
    return changed
end

function EditorDocumentManager:setSelectedTile(tile)
    local self = self.editor
    self.selected_tile = tile
    if self.tile_palette then self.tile_palette:setSelectedTile(tile) end
    if self.tileset_editor then self.tileset_editor:setTile(tile) end
end

function EditorDocumentManager:showTilesetEditor(document)
    local self = self.editor
    if document then self:setActiveTileset(document) end
    if not self.tileset_panel then return false end
    if not self.tileset_panel.visible then self.dockspace:setPanelVisible(self.tileset_panel, true, "center") end
    self.tileset_editor:setDocument(self.active_tileset_document, {
        preserve_mode = true,
        preserve_tile = true,
        preserve_selection = true
    })
    if self.selected_tile then self.tileset_editor:setTile(self.selected_tile) end
    if self.tileset_panel.stack then self.tileset_panel.stack:setActivePanel(self.tileset_panel) end
    self.dockspace:setFocus(self.tileset_editor)
    return true
end

function EditorDocumentManager:setShapeMode(mode)
    local self = self.editor
    local modes = {
        point = true, line = true, rectangle = true, ellipse = true,
        polygon = true, polyline = true
    }
    if not modes[mode] then return false end
    if self.shape_mode ~= mode then self:cancelPolygonBuilds() end
    self.shape_mode = mode
    self:setActiveTool("shape")
    return true
end

function EditorDocumentManager:getShapeModes()
    local self = self.editor
    return {
        { id = "point", name = "Point", icon = "editor/ui/tool/shape_point" },
        { id = "line", name = "Line", icon = "editor/ui/tool/shape_line" },
        { id = "rectangle", name = "Rectangle", icon = "editor/ui/tool/shape_rect" },
        { id = "ellipse", name = "Ellipse", icon = "editor/ui/tool/shape_ellipse" },
        { id = "polygon", name = "Polygon", icon = "editor/ui/tool/shape_poly" },
        { id = "polyline", name = "Polyline", icon = "editor/ui/tool/shape_polyline" }
    }
end

function EditorDocumentManager:setupMapDocuments(session)
    local self = self.editor
    local restored_by_panel = {}
    local saved_documents = session and type(session.documents) == "table" and session.documents or {}
    for _, saved_document in ipairs(saved_documents) do
        local registered_world = type(saved_document) == "table"
            and type(saved_document.world_id) == "string"
            and Registry.getEditorWorld(saved_document.world_id) or nil
        local is_world = type(saved_document) == "table"
            and (saved_document.editor_world == true
                or (saved_document.editor_world == nil and registered_world ~= nil))
        local existing
        if is_world then
            existing = self:findWorldDocument(saved_document.world_id)
        elseif type(saved_document) == "table" then
            existing = self:findMapDocument(saved_document.primary_map_id)
        end
        if type(saved_document) == "table" and Registry.hasMap(saved_document.primary_map_id) and not existing then
            local document = self:createMapDocument(saved_document.primary_map_id, saved_document.panel_id)
            if document then
                if is_world and registered_world then
                    self:configureWorldDocument(document, registered_world)
                elseif type(saved_document.world_id) == "string" then
                    document.world.id = saved_document.world_id
                    document.editor_world = is_world
                end
                if type(saved_document.primary_position) == "table" then
                    document:setMapPosition(saved_document.primary_map_id,
                        saved_document.primary_position.x, saved_document.primary_position.y)
                end
                restored_by_panel[document.panel.id] = document
                local saved_maps = type(saved_document.maps) == "table" and saved_document.maps or {}
                for _, saved_map in ipairs(saved_maps) do
                    if type(saved_map) == "table" and saved_map.id ~= document.primary_map_id
                        and Registry.hasMap(saved_map.id) then
                        document:addMap(saved_map.id,
                            type(saved_map.x) == "number" and saved_map.x or 0,
                            type(saved_map.y) == "number" and saved_map.y or 0)
                    end
                end
                if is_world and not registered_world then
                    document.editor_world = true
                    document.panel.title = saved_document.world_id or document.panel.title
                end
                self:restoreDocumentView(document, saved_document.view)
                self:restoreGameViewState(document, saved_document.game_view)
            end
        end
    end

    local context_document = self:findMapDocument(self.map_id)
    if not context_document and Registry.hasMap(self.map_id) then
        context_document = self:createMapDocument(self.map_id)
    end
    if #self.map_documents == 0 then error("Editor session has no valid map document") end

    self.game_preview = EditorGameView(self, context_document or self.map_documents[1])
    self.game_view = self.game_preview
    self.live_document = nil
    self.standalone_preview_map_id = session and Registry.hasMap(session.standalone_preview_map_id)
        and session.standalone_preview_map_id
        or (context_document or self.map_documents[1]).primary_map_id
    self.standalone_preview_document = EditorMapDocument(self, self.standalone_preview_map_id)
    if session and session.game_preview_view and context_document and not context_document.game_view_state then
        self:restoreGameViewState(context_document, session.game_preview_view)
    end
    return context_document, restored_by_panel
end

function EditorDocumentManager:setupCodeDocuments(session)
    local self = self.editor
    self.document_providers:restoreSession(session and session.document_providers or {})
end

function EditorDocumentManager:showDocumentProviderPanel(panel, control, focus)
    local self = self.editor
    if not panel then return false end
    if not panel.visible then self.dockspace:setPanelVisible(panel, true, "center") end
    if panel.stack then panel.stack:setActivePanel(panel) end
    self.dockspace:setFocus(focus or control)
    return true
end

function EditorDocumentManager:openDocument(document, options)
    local self = self.editor
    if not document then return false end
    local opened, reason = self.document_providers:open(document, options)
    if opened == false and reason then self:addError("Could not open " .. document.name, reason, "filesystem") end
    return opened
end

function EditorDocumentManager:addMapToWorldAtScreen(id, x, y)
    local self = self.editor
    local view = self:getMapViewAt(x, y)
    if not view then return false end
    local local_x, local_y = view:toLocal(x, y)
    local world_x, world_y = view:getMapCoordinates(local_x, local_y)
    local primary = view.document:getPrimaryMap()
    if not Input.ctrl() then
        local tile_width, tile_height = primary.tile_width or 40, primary.tile_height or 40
        world_x = MathUtils.round(world_x / tile_width) * tile_width
        world_y = MathUtils.round(world_y / tile_height) * tile_height
    end
    self:beginHistoryTransaction("Add Map to World", view.document)
    local entry = view.document:addMap(id, world_x, world_y, { explicit_companion = true })
    if entry then
        view.document.world.id = view.document.world.id or ("session:" .. view.document.primary_map_id)
        self:markHistoryChanged()
        self:commitHistoryTransaction()
        if self.world_browser and Registry.getEditorWorld(view.document.world.id) then
            Registry.registerEditorWorld(view.document.world.id, view.document.world)
            self.world_browser:refreshMaps(view.document.world)
        end
        return true
    end
    self:cancelHistoryTransaction()
    return false
end

function EditorDocumentManager:removeMapFromWorld(world, map_id)
    local self = self.editor
    if not world or not world.map_lookup[map_id] then return false end
    local document = self:findWorldDocument(world.id)
    if document and #document.maps <= 1 then
        self:addWarning("An open world must contain at least one map",
            "Add another map to the world view before removing this one.", "world_edit")
        return false
    end
    local function remove()
        if document and document.primary_map_id == map_id then
            local replacement
            for _, entry in ipairs(document.maps) do
                if entry.id ~= map_id then replacement = entry break end
            end
            if not replacement then return false end
            document.primary_map_id = replacement.id
            document.world.primary_map_id = replacement.id
            replacement.primary = true
        end
        local target = document and document.world or world
        if not target:removeMap(map_id, true) then return false end
        if document then
            document.maps, document.map_lookup = target.maps, target.map_lookup
        end
        return true
    end
    local removed
    if document then
        removed = self:performHistoryEdit("Remove Map from World", document, remove)
    else
        removed = remove()
    end
    if not removed then return false end
    local current = document and document.world or world
    Registry.registerEditorWorld(current.id, current)
    self.active_editor_world = current
    self.active_world_id = current.id
    self:clearDiagnostics("world_edit")
    return true
end

function EditorDocumentManager:loadRuntimeMap(id)
    local self = self.editor
    if not id or not Registry.getMap(id) and not Registry.getMapData(id) then return false end
    if not Game.world then return false end
    Game.state = "OVERWORLD"
    Game.world:loadMap(id)
    self.map_id = id
    self.stale_runtime_maps[id] = nil
    return true
end

function EditorDocumentManager:openMap(id)
    local self = self.editor
    if not Registry.hasMap(id) then return false end
    local document = self:findMapDocument(id)
    if not document then document = self:createMapDocument(id) end
    return document and self:activateMapDocument(document) or false
end

function EditorDocumentManager:findMapDocument(id)
    local self = self.editor
    for _, document in ipairs(self.map_documents or {}) do
        if not document.editor_world and document.primary_map_id == id then return document end
    end
end

function EditorDocumentManager:findWorldDocument(id)
    local self = self.editor
    for _, document in ipairs(self.map_documents or {}) do
        if document.editor_world and document.world and document.world.id == id then return document end
    end
end

function EditorDocumentManager:openWorld(world)
    local self = self.editor
    if type(world) == "string" then world = Registry.getEditorWorld(world) end
    if not world then return false end
    local document = self:findWorldDocument(world.id)
    if document then return self:activateMapDocument(document) end
    local first = world.maps and world.maps[1]
    if not first then
        self:addWarning("World '" .. tostring(world.name or world.id) .. "' has no maps to open",
            "Create the world while a map document is active, or add a map before opening it.", "world_open")
        return false
    end
    document = self:createMapDocument(first.id)
    if not document then
        self:addError("Could not open world '" .. tostring(world.name or world.id) .. "'",
            "Its first map '" .. tostring(first.id) .. "' is unavailable.", "world_open")
        return false
    end
    if not self:configureWorldDocument(document, world, first.id) then
        self.dockspace:unregisterPanel(document.panel)
        for index, candidate in ipairs(self.map_documents) do
            if candidate == document then table.remove(self.map_documents, index) break end
        end
        self:addError("Could not open world '" .. tostring(world.name or world.id) .. "'",
            "Its view origin map is unavailable.", "world_open")
        return false
    end
    local opened_world = document.world
    Registry.registerEditorWorld(opened_world.id, opened_world)
    if self.world_browser then
        self.world_browser:refresh(opened_world.id)
        self.world_browser:selectWorld(opened_world)
    end
    self:clearDiagnostics("world_open")
    return self:activateMapDocument(document)
end

function EditorDocumentManager:activateMapDocument(document, options)
    local self = self.editor
    options = options or {}
    if not document then return false end
    if self.active_document and self.active_document ~= document then
        self:cancelPolygonBuilds()
        self:cancelEventRegionDrags()
    end
    if document.panel and not document.panel.visible then
        self.dockspace:setPanelVisible(document.panel, true, document.panel.last_region or "center")
    end
    self.active_document = document
    if self.layers_browser then self.layers_browser:setDocument(document) end
    if options.select_panel ~= false and document.panel and document.panel.stack then
        document.panel.stack:setActivePanel(document.panel)
    end
    if options.set_mode ~= false and not self.tile_editing_mode
        and not self:isStandaloneGamePreviewEnabled() then
        return self:showGamePreview({ document = document, select_panel = false })
    end
    return true
end

function EditorDocumentManager:openMapTab(id, dock_target)
    local self = self.editor
    if not id or not Registry.getMap(id) and not Registry.getMapData(id) then return false end
    if dock_target and dock_target.standalone_game_preview then
        return self:setStandaloneGamePreviewMap(id)
    end
    local document = self:findMapDocument(id)
    if not document then
        document = self:createMapDocument(id)
        if not document then return false end
    end
    if dock_target and dock_target.stack then
        self.dockspace:dockPanel(document.panel, dock_target.stack, dock_target.tab_index)
    end
    return self:activateMapDocument(document)
end

function EditorDocumentManager:isMapTabDropTarget(x, y)
    local self = self.editor
    return self:getMapPanelDropTarget(x, y) ~= nil
end

function EditorDocumentManager:getMapPanelDropTarget(x, y)
    local self = self.editor
    if self:isStandaloneGamePreviewEnabled() then
        local rect = self.dockspace:getPanelRect(self.game_preview_panel)
        if self.dockspace:isPanelDisplayed(self.game_preview_panel)
            and rect and x >= rect.x and y >= rect.y
            and x < rect.x + rect.width and y < rect.y + rect.height then
            return { standalone_game_preview = true, rect = rect }
        end
    end
    return self.dockspace:getMapPanelDropTarget(x, y)
end

function EditorDocumentManager:addMapToView(id, x, y, document)
    local self = self.editor
    document = document or self.active_document
    return document and document:addMap(id, x, y) or nil
end

function EditorDocumentManager:addMapToWorld(world, map_id)
    local self = self.editor
    if not world or not map_id or world:hasMap(map_id) then return false end
    if not Registry.getMap(map_id) and not Registry.getMapData(map_id) then return false end
    if #(world.maps or {}) == 0 then
        if not world:addMap(map_id, 0, 0, { explicit_companion = true }) then return false end
        Registry.registerEditorWorld(world.id, world)
        self.active_editor_world = world
        self.active_world_id = world.id
        return self:openWorld(world)
    end
    if not self:openWorld(world) then return false end
    local document = self:findWorldDocument(world.id)
    if not document then return false end
    world = document.world
    local _, min_y, max_x = world:getBounds()
    local added = self:performHistoryEdit("Add Map to World", document, function()
        return world:addMap(map_id, max_x, min_y, { explicit_companion = true }) ~= nil
    end)
    if not added then return false end
    Registry.registerEditorWorld(world.id, world)
    self.active_editor_world = world
    self.active_world_id = world.id
    if self.world_browser then self.world_browser:refreshMaps(world) end
    if document.map_view then document.map_view:focusMap(map_id) end
    return true
end

function EditorDocumentManager:removeMapFromView(id, document)
    local self = self.editor
    document = document or self.active_document
    return document and document:removeMap(id) or false
end

function EditorDocumentManager:removeMapDocument(document)
    local self = self.editor
    local remove_index
    for index, candidate in ipairs(self.map_documents) do
        if candidate == document then remove_index = index break end
    end
    if not remove_index then return false end
    if document:isDirty() then
        local name = document.editor_world and document.world
            and (document.world.name or document.world.id)
            or document.primary_map_id or document.panel.title
        if not self:confirmUnsavedChanges({
            dirty = true,
            save_label = "Save",
            message = "Save changes to '" .. tostring(name) .. "' before closing it?",
            save = function()
                if document.editor_world then
                    return self:saveWorldDocumentToProject(document.world)
                end
                return self:saveMapDocumentToProject(document)
            end
        }) then return false end
    end
    if self.live_document == document then self:detachGamePreview() end
    if self.history then self.history:forgetOwner(document) end
    self.dockspace:unregisterPanel(document.panel)
    table.remove(self.map_documents, remove_index)
    if self.active_document == document then
        self.active_document = nil
        local replacement = self.map_documents[remove_index] or self.map_documents[remove_index - 1]
        if replacement then
            self:activateMapDocument(replacement)
        else
            self.game_panel = nil
            if self.layers_browser then self.layers_browser:setDocument(nil) end
            self.dockspace:setFocus(nil)
        end
    end
    self:onHistoryChanged({}, false)
    return true
end

return EditorDocumentManager
