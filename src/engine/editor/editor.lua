---@class Editor
---@field audio_controller EditorAudioController
---@field session_manager EditorSessionManager
---@field configuration EditorConfiguration
---@field document_manager EditorDocumentManager
---@field project_io EditorProjectIO
---@field ui_controller EditorUIController
---@field workspace_controller EditorWorkspaceController
---@field map_interaction EditorMapInteraction
---@field preview_controller EditorPreviewController
---@field editor_mode boolean
---@field owns_window_input boolean
---@field ui_scale number
---@field align_game_transition boolean
---@field music Music
---@field editing_music_started boolean?
---@field editor_music_enabled boolean?
---@field editor_music_override_player Music?
---@field editor_music_overrides table<any, table>?
---@field editor_music_override_sequence number?
---@field editor_music_fade_tokens table<Music, number>?
---@field active_editor_music_override table?
---@field source_state table?
---@field return_to_menu_on_exit boolean?
---@field pending_project_switch_id string?
---@field entry_transition EditorModeTransition?
---@field exit_transition EditorModeTransition?
---@field session_saved_for_exit boolean?
---@field pending_tile_editing_mode boolean?
---@field tile_editing_mode boolean
---@field show_tile_grid boolean
---@field game_faulted boolean
---@field game_fault_trace string?
---@field project_id string?
---@field map_id string?
---@field previous_window table?
---@field previous_mouse_cursor love.Cursor?
---@field previous_mouse_visible boolean?
---@field previous_lock_movement boolean?
---@field message_bar EditorMessageBar?
---@field workspace_registry EditorWorkspaceRegistry?
---@field active_workspace_id string?
---@field history EditorHistory?
---@field command_registry EditorCommandRegistry?
---@field document_providers EditorDocumentProviders?
---@field settings EditorSettingsRegistry?
---@field tool_registry EditorToolRegistry?
---@field file_type_registry EditorFileTypeRegistry?
---@field project_workspace EditorProjectWorkspace?
---@field dockspace EditorDockSpace?
---@field menu_bar EditorMenuBar?
---@field editor_cursor EditorCursor?
---@field default_layout table?
---@field suppress_panel_activation boolean?
---@field map_documents EditorMapDocument[]?
---@field active_document EditorMapDocument?
---@field standalone_preview_document EditorMapDocument?
---@field standalone_preview_map_id string?
---@field live_document EditorMapDocument?
---@field tileset_documents EditorTilesetDocument[]?
---@field active_tileset_document EditorTilesetDocument?
---@field active_tileset_id string?
---@field selected_tile number?
---@field selected_terrain_set table?
---@field selected_terrain_variant table?
---@field selected_terrain_id string?
---@field selected_terrain_variant_id number?
---@field brush_size number?
---@field active_editor_world EditorWorld?
---@field active_world_id string?
---@field map_browser EditorMapBrowser?
---@field world_browser EditorWorldBrowser?
---@field event_browser EditorEventBrowser?
---@field tileset_browser EditorTilesetBrowser?
---@field tile_palette EditorTilePalette?
---@field terrain_palette EditorTerrainPalette?
---@field tileset_editor EditorTilesetPanel?
---@field layers_browser EditorLayersPanel?
---@field properties_browser EditorPropertiesPanel?
---@field fx_browser EditorFXBrowser?
---@field toolbar EditorToolbar?
---@field diagnostics_browser EditorDiagnosticsPanel?
---@field console_browser EditorConsolePanel?
---@field settings_browser EditorSettingsPanel?
---@field file_browser EditorFileBrowser?
---@field source_viewer EditorSourceViewer?
---@field files_panel EditorPanel?
---@field maps_panel EditorPanel?
---@field worlds_panel EditorPanel?
---@field tilesets_browser_panel EditorPanel?
---@field events_panel EditorPanel?
---@field fx_panel EditorPanel?
---@field toolbar_panel EditorPanel?
---@field layers_panel EditorPanel?
---@field properties_panel EditorPanel?
---@field console_panel EditorPanel?
---@field tile_palette_panel EditorPanel?
---@field terrain_palette_panel EditorPanel?
---@field tileset_panel EditorPanel?
---@field source_viewer_panel EditorPanel?
---@field diagnostics_panel EditorPanel?
---@field settings_panel EditorPanel?
---@field game_panel EditorPanel?
---@field game_preview_panel EditorPanel?
---@field game_view EditorGameView?
---@field game_preview EditorGameView?
---@field game_preview_paused boolean?
---@field game_preview_snapshot table?
---@field game_preview_snapshot_document EditorMapDocument?
---@field game_preview_snapshot_save_id string?
---@field game_preview_movement_lock boolean?
---@field game_preview_lock_before_pause boolean?
---@field game_music_suspended_by_editor boolean?
---@field stale_runtime_maps table<string, boolean>?
---@field forwarded_mouse_buttons table<number, boolean>?
---@field object_selection_mouse_buttons table<number, boolean>?
---@field consumed_editor_keys table<string, boolean>?
---@field object_selection_cursor_x number?
---@field object_selection_cursor_y number?
---@field selected_event_id string?
---@field placement_event_id string?
---@field active_tool string?
---@field shape_mode string?
---@field selected_map_object table?
---@field selected_map_objects table[]?
---@field map_object_clipboard table[]?
---@field asset_drag table?
---@field project_file_drag table?
---@field drag_preview table?
---@field object_reference_drag table?
---@field object_link table?
---@field properties_target_owner any
---@field creation_dialog EditorCreationDialog?
---@field color_picker EditorColorPicker?
---@field path_picker EditorPathPicker?
---@field object_reference_picker EditorObjectReferencePicker?
---@field use_custom_cursors boolean
---@field use_deltarune_font boolean
local Editor = {
    editor_mode = true,
    owns_window_input = true
}

function Editor:init()
    self.audio_controller = EditorAudioController(self)
    self.session_manager = EditorSessionManager(self)
    self.configuration = EditorConfiguration(self)
    self.document_manager = EditorDocumentManager(self)
    self.project_io = EditorProjectIO(self)
    self.ui_controller = EditorUIController(self)
    self.workspace_controller = EditorWorkspaceController(self)
    self.map_interaction = EditorMapInteraction(self)
    self.preview_controller = EditorPreviewController(self)
    self.music = Music()
end

function Editor:getUIScale()
    return tonumber(self.ui_scale) or 1
end

function Editor:getUIDimensions()
    local scale = self:getUIScale()
    return love.graphics.getWidth() / scale, love.graphics.getHeight() / scale
end

function Editor:screenToUI(x, y)
    local scale = self:getUIScale()
    return x / scale, y / scale
end

function Editor:screenDeltaToUI(x, y)
    return self:screenToUI(x, y)
end

function Editor:getMousePosition()
    return self:screenToUI(love.mouse.getPosition())
end

function Editor:resetEditingMusic() return self.audio_controller:resetEditingMusic() end

function Editor:invalidateEditingMusicFade(music) return self.audio_controller:invalidateEditingMusicFade(music) end

function Editor:fadeEditingMusicOut(music, duration) return self.audio_controller:fadeEditingMusicOut(music, duration) end

function Editor:fadeEditingMusicIn(music, volume, duration) return self.audio_controller:fadeEditingMusicIn(music, volume, duration) end

function Editor:resumeEditingMusic(fade_time) return self.audio_controller:resumeEditingMusic(fade_time) end

function Editor:pauseEditingMusic(fade_time) return self.audio_controller:pauseEditingMusic(fade_time) end

function Editor:stopBaseEditingMusic() return self.audio_controller:stopBaseEditingMusic() end

function Editor:stopEditingMusic() return self.audio_controller:stopEditingMusic() end

function Editor:setEditorMusicOverride(owner, music, options) return self.audio_controller:setEditorMusicOverride(owner, music, options) end

function Editor:clearEditorMusicOverride(owner, options) return self.audio_controller:clearEditorMusicOverride(owner, options) end

function Editor:getActiveEditorMusicOverride() return self.audio_controller:getActiveEditorMusicOverride() end

function Editor:resumeEditorMusicOverride(request, fade_time) return self.audio_controller:resumeEditorMusicOverride(request, fade_time) end

function Editor:syncEditingMusic(options) return self.audio_controller:syncEditingMusic(options) end

function Editor:getSessionPath() return self.session_manager:getSessionPath() end

function Editor:loadSession() return self.session_manager:loadSession() end

function Editor:getNextDocumentPanelId() return self.document_manager:getNextDocumentPanelId() end

function Editor:createMapDocument(id, panel_id) return self.document_manager:createMapDocument(id, panel_id) end

function Editor:configureWorldDocument(document, source, primary_map_id) return self.document_manager:configureWorldDocument(document, source, primary_map_id) end

function Editor:restoreDocumentView(document, state) return self.session_manager:restoreDocumentView(document, state) end

function Editor:restoreGameViewState(document, state) return self.session_manager:restoreGameViewState(document, state) end

function Editor:captureGameViewState(document) return self.session_manager:captureGameViewState(document) end

function Editor:captureSession() return self.session_manager:captureSession() end

function Editor:saveSession() return self.session_manager:saveSession() end

function Editor:setupWindow(session) return self.ui_controller:setupWindow(session) end

function Editor:registerMenuBar() return self.configuration:registerMenuBar() end

function Editor:registerEditorTools() return self.configuration:registerEditorTools() end

function Editor:registerEditorSettings(session) return self.configuration:registerEditorSettings(session) end

function Editor:setupTilesetDocuments(session) return self.document_manager:setupTilesetDocuments(session) end

function Editor:setActiveTileset(document, options) return self.document_manager:setActiveTileset(document, options) end

function Editor:setSelectedTerrain(document, terrain, variant) return self.document_manager:setSelectedTerrain(document, terrain, variant) end

function Editor:setBrushSize(value) return self.document_manager:setBrushSize(value) end

function Editor:getBrushSize() return self.document_manager:getBrushSize() end

function Editor:getSelectedTerrain() return self.document_manager:getSelectedTerrain() end

function Editor:rebuildTerrain(scope) return self.document_manager:rebuildTerrain(scope) end

function Editor:setSelectedTile(tile) return self.document_manager:setSelectedTile(tile) end

function Editor:showTilesetEditor(document) return self.document_manager:showTilesetEditor(document) end

function Editor:setShapeMode(mode) return self.document_manager:setShapeMode(mode) end

function Editor:getShapeModes() return self.document_manager:getShapeModes() end

function Editor:setupMapDocuments(session) return self.document_manager:setupMapDocuments(session) end

function Editor:setupCodeDocuments(session) return self.document_manager:setupCodeDocuments(session) end

function Editor:setupPanels(session) return self.ui_controller:setupPanels(session) end

function Editor:restoreEntryState(session, options, context_document, restored_by_panel, game_center_x, game_center_y) return self.session_manager:restoreEntryState(session, options, context_document, restored_by_panel, game_center_x, game_center_y) end

function Editor:enter(previous, options)
    options = options or {}
    self:resetEditingMusic()
    self.source_state = options.source_state or previous
    self.return_to_menu_on_exit = options.return_to_menu == true
    self.pending_project_switch_id = nil
    self.entry_transition = options.entry_transition
    self.exit_transition = nil
    self.session_saved_for_exit = false
    self.pending_tile_editing_mode = nil
    self.tile_editing_mode = false
    self.show_tile_grid = false
    self.game_faulted = false
    self.game_fault_trace = nil
    self.game_preview_paused = true
    self.forwarded_mouse_buttons = {}
    self.object_selection_mouse_buttons = {}
    self.consumed_editor_keys = {}
    self.creation_dialog = nil
    self.color_picker = nil
    self.path_picker = nil
    self.object_reference_picker = nil
    self.asset_drag = nil
    self.project_file_drag = nil
    self.drag_preview = nil
    self.game_preview_snapshot = nil
    self.game_preview_snapshot_document = nil
    self.game_preview_snapshot_save_id = nil
    self.game_music_suspended_by_editor = false
    self.stale_runtime_maps = {}
    self.project_id = options.project_id or (Mod and Mod.info.id)
    self.map_id = options.map_id or (Game.world and Game.world.map and Game.world.map.id)
    self.message_bar = EditorMessageBar()
    self.workspace_registry = EditorWorkspaceRegistry(self)
    local workspaces_loaded, workspace_error = self.workspace_registry:load()
    if not workspaces_loaded then
        self:addWarning("Could not load saved editor workspaces: " .. tostring(workspace_error),
            nil, "editor_workspaces")
    end
    self.history = EditorHistory(self)
    self.command_registry = EditorCommandRegistry()
    self.document_providers = EditorDocumentProviders(self)
    self:registerEditorTools()
    local session = self:loadSession()
    self:registerEditorSettings(session)
    self:setupTilesetDocuments(session)
    self.show_tile_grid = session and session.tile_grid == true or false
    self.previous_lock_movement = Game.lock_movement
    self.game_preview_movement_lock = self.previous_lock_movement
    self.game_preview_lock_before_pause = nil
    Game.lock_movement = true

    local game_center_x, game_center_y = self:setupWindow(session)

    self.dockspace = EditorDockSpace(self)
    self.suppress_panel_activation = true
    self.map_documents = {}
    self.active_document = nil
    self.game_view = nil
    self.selected_map_object = nil
    self.selected_map_objects = {}
    self.map_object_clipboard = nil
    self.map_browser = EditorMapBrowser(self)
    self.file_type_registry = EditorFileTypeRegistry()
    self.project_workspace = EditorProjectWorkspace(self, self.file_type_registry)
    self.file_browser = EditorFileBrowser(self, self.project_workspace)
    self.source_viewer = EditorSourceViewer(self, self.project_workspace)
    self.document_providers:register("core_source_viewer",
        EditorSourceDocumentProvider(self, self.source_viewer))
    self.world_browser = EditorWorldBrowser(self)
    self.active_world_id = session and session.active_world_id or nil
    self.active_editor_world = self.active_world_id and Registry.getEditorWorld(self.active_world_id) or nil
    self.world_browser:refresh(self.active_world_id)
    self.event_browser = EditorEventBrowser(self)
    self.tileset_browser = EditorTilesetBrowser(self)
    self.tile_palette = EditorTilePalette(self)
    self.terrain_palette = EditorTerrainPalette(self)
    self.tileset_editor = EditorTilesetPanel(self)
    self.tile_palette.random_mode = session and session.tile_palette_random == true or false
    self.tile_palette.random_toggle:setValue(self.tile_palette.random_mode, true)
    self.tile_palette:setTilesetDocument(self.active_tileset_document)
    self.terrain_palette:setDocument(self.active_tileset_document)
    if self.active_tileset_document and session then
        for _, terrain in ipairs(self.active_tileset_document:getTerrainSets()) do
            if terrain.id == session.active_terrain_id then
                local variant = self.active_tileset_document:getTerrainVariant(
                    terrain, session.active_terrain_variant_id)
                if variant then self:setSelectedTerrain(self.active_tileset_document, terrain, variant) end
                break
            end
        end
    end
    self.layers_browser = EditorLayersPanel(self)
    self.properties_browser = EditorPropertiesPanel(self)
    self.fx_browser = EditorFXBrowser(self)
    self.toolbar = EditorToolbar(self)
    self.diagnostics_browser = EditorDiagnosticsPanel(self)
    self.console_browser = EditorConsolePanel(self)
    self.menu_bar = EditorMenuBar(self)
    self.editor_cursor = EditorCursor()
    self.editor_cursor:setCustomEnabled(self.use_custom_cursors)

    EditorPlugins:initialize(self)
    for id, data in pairs(Registry.map_data or {}) do
        local initialized, reason = EditorFormat.decodeMapExtensions(data, {
            map = data, map_id = id
        })
        if not initialized then
            self:addError("Could not initialize format extensions in map '"
                .. tostring(id) .. "'", reason, "map_extensions")
        end
    end
    for _, world in pairs(Registry.editor_worlds or {}) do
        local initialized, reason = world:initializeFormatExtensions()
        if not initialized then
            self:addError("Could not initialize format extensions in world '"
                .. tostring(world.id) .. "'", reason, "world_extensions")
        end
    end
    for _, document in ipairs(self.tileset_documents or {}) do
        local extensions_initialized, extension_reason = document:initializeFormatExtensions()
        if not extensions_initialized then
            self:addError("Could not initialize format extensions in tileset '"
                .. tostring(document.id) .. "'", extension_reason, "tileset_extensions")
        end
        local initialized, reason = document:initializeTerrainConditions()
        if not initialized then
            self:addError("Could not initialize terrain conditions in tileset '"
                .. tostring(document.id) .. "'", reason, "terrain_conditions")
        end
    end
    local context_document, restored_by_panel = self:setupMapDocuments(session)
    self.settings_browser = EditorSettingsPanel(self)
    self.event_browser:refresh()
    self.fx_browser:refresh()
    self:registerMenuBar()
    EditorPlugins:applyCommands(self)
    EditorPlugins:applyMenuBar(self)
    self:setupPanels(session)
    self:setupCodeDocuments(session)
    self:restoreEntryState(session, options, context_document, restored_by_panel,
        game_center_x, game_center_y)
    self:syncEditingMusic()
end

function Editor:leave()
    self:stopEditingMusic()
    self.music:remove()
    self.editor_music_override_player:remove()
    self:clearGameObjectSelection()
    if not self.session_saved_for_exit then self:saveSession() end
    if self.project_workspace then self.project_workspace:shutdown() end
    EditorPlugins:shutdown(self)
    if self.document_providers then self.document_providers:shutdown() end
    self.dockspace:setFocus(nil)
    local game_center_x, game_center_y
    if self.align_game_transition ~= false then
        game_center_x, game_center_y = self:getGameCanvasScreenCenter()
    end
    local window = self.previous_window
    if window then love.window.updateMode(window.width, window.height, window.flags) end
    Kristal.refreshWindowText()
    if window then
        local window_x, window_y = window.x, window.y
        if self.align_game_transition ~= false then
            local game_offset_x, game_offset_y = Kristal.getSideOffsets()
            local game_scale = Kristal.getGameScale()
            window_x = game_center_x - love.window.fromPixels(game_offset_x + (SCREEN_WIDTH * game_scale / 2))
            window_y = game_center_y - love.window.fromPixels(game_offset_y + (SCREEN_HEIGHT * game_scale / 2))
        end
        love.window.setPosition(MathUtils.round(window_x), MathUtils.round(window_y), window.display)
    end
    Kristal.setDesiredWindowTitleAndIcon()
    if self.previous_mouse_cursor then
        love.mouse.setCursor(self.previous_mouse_cursor)
    else
        love.mouse.setCursor()
    end
    Kristal.updateCursor()
    love.mouse.setVisible(self.previous_mouse_visible)
    Game.lock_movement = self.previous_lock_movement
    self.entry_transition = nil
    self.exit_transition = nil
    self.source_state = nil
    self.dockspace = nil
    self.menu_bar = nil
    self.editor_cursor = nil
    self.return_to_menu_on_exit = nil
    self.pending_project_switch_id = nil
    self.previous_mouse_cursor = nil
    self.message_bar = nil
    self.map_documents = nil
    self.active_document = nil
    self.world_browser = nil
    self.worlds_panel = nil
    self.active_editor_world = nil
    self.active_world_id = nil
    self.game_preview = nil
    self.stale_runtime_maps = nil
    self.game_view = nil
    self.game_panel = nil
    self.game_preview_panel = nil
    self.layers_browser = nil
    self.layers_panel = nil
    self.event_browser = nil
    self.events_panel = nil
    self.tileset_documents = nil
    self.active_tileset_document = nil
    self.active_tileset_id = nil
    self.selected_tile = nil
    self.selected_terrain_set = nil
    self.selected_terrain_variant = nil
    self.selected_terrain_id = nil
    self.selected_terrain_variant_id = nil
    self.tileset_browser = nil
    self.tilesets_browser_panel = nil
    self.tile_palette = nil
    self.tile_palette_panel = nil
    self.terrain_palette = nil
    self.terrain_palette_panel = nil
    self.tileset_editor = nil
    self.tileset_panel = nil
    self.fx_browser = nil
    self.fx_panel = nil
    self.toolbar = nil
    self.toolbar_panel = nil
    self.tool_registry = nil
    self.active_tool = nil
    self.selected_event_id = nil
    self.placement_event_id = nil
    self.diagnostics_browser = nil
    self.diagnostics_panel = nil
    self.console_browser = nil
    self.console_panel = nil
    self.settings_browser = nil
    self.settings_panel = nil
    self.settings = nil
    self.command_registry = nil
    self.file_browser = nil
    self.files_panel = nil
    self.source_viewer = nil
    self.source_viewer_panel = nil
    self.project_workspace = nil
    self.file_type_registry = nil
    self.document_providers = nil
    self.asset_drag = nil
    self.project_file_drag = nil
    self.drag_preview = nil
    self.object_reference_drag = nil
    self.object_link = nil
    self.selected_map_object = nil
    self.selected_map_objects = nil
    self.history = nil
    self.properties_browser = nil
    self.properties_panel = nil
    self.properties_target_owner = nil
    self.color_picker = nil
    self.path_picker = nil
    self.object_reference_picker = nil
    self.standalone_preview_document = nil
    self.standalone_preview_map_id = nil
    self.game_preview_paused = nil
    self.live_document = nil
    self.suppress_panel_activation = nil
    self.session_saved_for_exit = nil
    self.pending_tile_editing_mode = nil
    self.use_custom_cursors = nil
    self.use_deltarune_font = nil
    self.show_tile_grid = nil
    self.forwarded_mouse_buttons = nil
    self.object_selection_mouse_buttons = nil
    self.consumed_editor_keys = nil
    self.default_layout = nil
    self.workspace_registry = nil
    self.active_workspace_id = nil
    self.game_preview_snapshot = nil
    self.game_preview_snapshot_document = nil
    self.game_preview_snapshot_save_id = nil
    self.game_music_suspended_by_editor = nil
    self.editing_music_started = nil
    self.editor_music_enabled = nil
    self.editor_music_override_player = nil
    self.editor_music_overrides = nil
    self.editor_music_override_sequence = nil
    self.editor_music_fade_tokens = nil
    self.active_editor_music_override = nil
    self.game_preview_movement_lock = nil
    self.game_preview_lock_before_pause = nil
end

function Editor:setPropertiesTarget(target, owner) return self.ui_controller:setPropertiesTarget(target, owner) end

function Editor:clearPropertiesTarget(owner) return self.ui_controller:clearPropertiesTarget(owner) end

function Editor:setCustomCursorsEnabled(enabled) return self.ui_controller:setCustomCursorsEnabled(enabled) end

function Editor:setDeltaruneFontEnabled(enabled) return self.ui_controller:setDeltaruneFontEnabled(enabled) end

function Editor:setEditingMusicEnabled(enabled) return self.audio_controller:setEditingMusicEnabled(enabled) end

function Editor:addDiagnostic(severity, message, detail, source) return self.ui_controller:addDiagnostic(severity, message, detail, source) end

function Editor:addWarning(message, detail, source) return self.ui_controller:addWarning(message, detail, source) end

function Editor:addError(message, detail, source) return self.ui_controller:addError(message, detail, source) end

function Editor:clearDiagnostics(source) return self.ui_controller:clearDiagnostics(source) end

function Editor:isValidContentId(id) return self.project_io:isValidContentId(id) end

function Editor:renameWorldId(world, id) return self.project_io:renameWorldId(world, id) end

function Editor:getContentSavePath(kind, id) return self.project_io:getContentSavePath(kind, id) end

function Editor:getMapSavePath(id) return self.project_io:getMapSavePath(id) end

function Editor:getTilesetSavePath(document) return self.project_io:getTilesetSavePath(document) end

function Editor:getWorldSavePath(world) return self.project_io:getWorldSavePath(world) end

function Editor:commitFocusedTextInput() return self.project_io:commitFocusedTextInput() end

function Editor:saveMapDocumentToProject(document, options) return self.project_io:saveMapDocumentToProject(document, options) end

function Editor:saveTilesetDocumentToProject(document) return self.project_io:saveTilesetDocumentToProject(document) end

function Editor:saveWorldToProject(world) return self.project_io:saveWorldToProject(world) end

function Editor:saveWorldDocumentToProject(world) return self.project_io:saveWorldDocumentToProject(world) end

function Editor:saveAllDocuments() return self.project_io:saveAllDocuments() end

function Editor:saveActiveDocument() return self.project_io:saveActiveDocument() end

function Editor:createNewMap(id, name, options) return self.project_io:createNewMap(id, name, options) end

function Editor:showDiagnosticsPanel() return self.ui_controller:showDiagnosticsPanel() end

function Editor:toggleDiagnosticsPanel() return self.ui_controller:toggleDiagnosticsPanel() end

function Editor:showSettingsPanel() return self.ui_controller:showSettingsPanel() end

function Editor:setActiveTool(id) return self.map_interaction:setActiveTool(id) end

function Editor:cancelPolygonBuilds() return self.map_interaction:cancelPolygonBuilds() end

function Editor:cancelEventRegionDrags() return self.map_interaction:cancelEventRegionDrags() end

function Editor:beginHistoryTransaction(label, owners)
    return self.history and self.history:begin(label, owners)
end

function Editor:markHistoryChanged()
    return self.history and self.history:markChanged()
end

function Editor:setHistoryMetadata(key, value)
    return self.history and self.history:setTransactionMetadata(key, value)
end

function Editor:commitHistoryTransaction()
    return self.history and self.history:commit()
end

function Editor:cancelHistoryTransaction()
    if self.history then self.history:cancel() end
end

function Editor:performHistoryEdit(label, owners, callback)
    if not self.history then return callback() end
    return self.history:perform(label, owners, callback)
end

function Editor:pushHistoryCommand(label, command)
    return self.history and self.history:pushCommand(label, command) or false
end

function Editor:performHistoryCommand(label, command)
    if not self.history then return command.execute() end
    return self.history:performCommand(label, command)
end

function Editor:getSwitchableProjects() return self.workspace_controller:getSwitchableProjects() end

function Editor:hasSwitchableProjects() return self.workspace_controller:hasSwitchableProjects() end

function Editor:openProjectSwitcher() return self.workspace_controller:openProjectSwitcher() end

function Editor:beginProjectSwitch(id) return self.workspace_controller:beginProjectSwitch(id) end

function Editor:openCommandPalette() return self.workspace_controller:openCommandPalette() end

function Editor:getWorkspaceDisplayName(workspace) return self.workspace_controller:getWorkspaceDisplayName(workspace) end

function Editor:applyWorkspace(id) return self.workspace_controller:applyWorkspace(id) end

function Editor:openWorkspacePicker() return self.workspace_controller:openWorkspacePicker() end

function Editor:openSaveWorkspaceDialog() return self.workspace_controller:openSaveWorkspaceDialog() end

function Editor:openDeleteWorkspacePicker() return self.workspace_controller:openDeleteWorkspacePicker() end

function Editor:undo()
    local provider_result = self.document_providers:invokeFocused("undo")
    if provider_result ~= nil then return provider_result end
    return self.history and self.history:undo() or false
end

function Editor:redo()
    local provider_result = self.document_providers:invokeFocused("redo")
    if provider_result ~= nil then return provider_result end
    return self.history and self.history:redo() or false
end

function Editor:onHistoryChanged(owners, restored, command, direction)
    if restored then self:selectMapObjects({}) end
    if restored and command and direction and self.message_bar then
        local verb = direction == "undo" and "Undid" or "Redid"
        self.message_bar:setStatus(verb .. ": " .. tostring(command.label or "Edit"))
    end
    local explosions = command and command.metadata and command.metadata.explosions
    if restored and explosions then
        for _, explosion in ipairs(explosions) do
            local view = explosion.document and explosion.document.map_view
            if view then
                if direction == "undo" then
                    view:addUnexplosion(explosion.x, explosion.y)
                elseif direction == "redo" then
                    view:addExplosion(explosion.x, explosion.y)
                end
            end
        end
    end
    for _, owner in ipairs(owners or {}) do
        local editor_world = owner.world and owner.world.id
            and Registry.getEditorWorld(owner.world.id)
        local is_editor_world = owner.editor_world == true or editor_world ~= nil
        if is_editor_world then
            local world_was_active = self.active_world_id == owner.world.id
                or self.active_world_id == owner.previous_world_id
            if owner.previous_world_id and owner.previous_world_id ~= owner.world.id then
                Registry.editor_worlds[owner.previous_world_id] = nil
            end
            owner.previous_world_id = nil
            Registry.registerEditorWorld(owner.world.id, owner.world)
            if world_was_active then
                self.active_world_id = owner.world.id
                self.active_editor_world = owner.world
            end
            if self.world_browser then
                self.world_browser:refresh(owner.world.id)
                self.world_browser:refreshMaps(owner.world)
                if restored and world_was_active then
                    self.world_browser:selectWorld(owner.world)
                elseif self.properties_browser and self.properties_browser.target
                    and self.properties_browser.target.world_id == owner.world.id
                    and self.properties_browser.target.world_map_id then
                    local entry = owner.world.map_lookup[self.properties_browser.target.world_map_id]
                    if entry then self.world_browser:selectWorldMap(entry) end
                end
            end
        end
        if owner.panel then
            owner.panel.title = (is_editor_world and owner.world.name or owner.primary_map_id)
                .. (owner:isDirty() and " *" or "")
        end
        if restored and self.active_document == owner and self.layers_browser then
            self.layers_browser:setDocument(nil)
            self.layers_browser:setDocument(owner)
        end
        if owner == self.active_tileset_document then
            if self.tileset_panel then
                self.tileset_panel.title = "Tileset Editor" .. (owner:isDirty() and " *" or "")
            end
            if restored then
                self.tile_palette:setTilesetDocument(nil)
                self.tile_palette:setTilesetDocument(owner)
                self.terrain_palette:setDocument(nil)
                self.terrain_palette:setDocument(owner)
                self.tileset_editor:setDocument(owner, {
                    preserve_mode = true,
                    preserve_tile = true
                })
            end
        end
    end
    self:clearDiagnostics("unsaved_changes")
    local dirty = 0
    for _, document in ipairs(self.map_documents or {}) do
        if document:isDirty() then dirty = dirty + 1 end
    end
    for _, document in ipairs(self.tileset_documents or {}) do
        if document:isDirty() then dirty = dirty + 1 end
    end
    if dirty > 0 then
        self:addWarning(string.format("%d editor document%s contain unsaved changes",
            dirty, dirty == 1 and "" or "s"),
            "Use File > Save All or Ctrl+Shift+S to write the current editor state to the active project.",
            "unsaved_changes")
    end
end

function Editor:hasUnsavedChanges() return self.project_io:hasUnsavedChanges() end
function Editor:confirmUnsavedChanges(options) return self.project_io:confirmUnsavedChanges(options) end

function Editor:canUndo()
    local provider_result = self.document_providers:invokeFocused("canUndo")
    if provider_result ~= nil then return provider_result end
    return self.history and self.history:canUndo() or false
end

function Editor:canRedo()
    local provider_result = self.document_providers:invokeFocused("canRedo")
    if provider_result ~= nil then return provider_result end
    return self.history and self.history:canRedo() or false
end

function Editor:getUndoLabel()
    local provider_result = self.document_providers:invokeFocused("getUndoLabel")
    if provider_result ~= nil then return provider_result end
    return self.history and self.history:getUndoLabel() or nil
end

function Editor:getRedoLabel()
    local provider_result = self.document_providers:invokeFocused("getRedoLabel")
    if provider_result ~= nil then return provider_result end
    return self.history and self.history:getRedoLabel() or nil
end

function Editor:showDocumentProviderPanel(panel, control, focus) return self.document_manager:showDocumentProviderPanel(panel, control, focus) end

function Editor:openDocument(document, options) return self.document_manager:openDocument(document, options) end

function Editor:setPlacementEvent(id) return self.map_interaction:setPlacementEvent(id) end

function Editor:beginAssetDrag(kind, id, label) return self.map_interaction:beginAssetDrag(kind, id, label) end

function Editor:beginProjectFileDrag(data, icon) return self.map_interaction:beginProjectFileDrag(data, icon) end

function Editor:updateProjectFileDrag(x, y) return self.map_interaction:updateProjectFileDrag(x, y) end

function Editor:cancelProjectFileDrag() return self.map_interaction:cancelProjectFileDrag() end

function Editor:finishProjectFileDrag(x, y) return self.map_interaction:finishProjectFileDrag(x, y) end

function Editor:beginDragPreview(kind, label, icon, data) return self.map_interaction:beginDragPreview(kind, label, icon, data) end

function Editor:updateDragPreview(x, y) return self.map_interaction:updateDragPreview(x, y) end

function Editor:finishDragPreview() return self.map_interaction:finishDragPreview() end

function Editor:updateAssetDrag(x, y) return self.map_interaction:updateAssetDrag(x, y) end

function Editor:getMapViewAt(x, y) return self.map_interaction:getMapViewAt(x, y) end

function Editor:getMapObjectAtScreen(x, y) return self.map_interaction:getMapObjectAtScreen(x, y) end

function Editor:addMapToWorldAtScreen(id, x, y) return self.document_manager:addMapToWorldAtScreen(id, x, y) end

function Editor:removeMapFromWorld(world, map_id) return self.document_manager:removeMapFromWorld(world, map_id) end

function Editor:finishAssetDrag(x, y) return self.map_interaction:finishAssetDrag(x, y) end

function Editor:placeEvent(view, event_id, world_x, world_y) return self.map_interaction:placeEvent(view, event_id, world_x, world_y) end

function Editor:getMapObjectPropertiesTarget(selection) return self.map_interaction:getMapObjectPropertiesTarget(selection) end

function Editor:isMapObjectSelected(selection) return self.map_interaction:isMapObjectSelected(selection) end

function Editor:getSelectedMapObjects(document) return self.map_interaction:getSelectedMapObjects(document) end

function Editor:getMapObjectBatchPropertiesTarget(selections) return self.map_interaction:getMapObjectBatchPropertiesTarget(selections) end

function Editor:selectMapObjects(selections, primary) return self.map_interaction:selectMapObjects(selections, primary) end

function Editor:selectMapObject(selection, additive) return self.map_interaction:selectMapObject(selection, additive) end

function Editor:deleteSelectedMapObject(explode, history_label) return self.map_interaction:deleteSelectedMapObject(explode, history_label) end

function Editor:copySelectedMapObjects(silent) return self.map_interaction:copySelectedMapObjects(silent) end

function Editor:cutSelectedMapObjects() return self.map_interaction:cutSelectedMapObjects() end

function Editor:pasteMapObjects() return self.map_interaction:pasteMapObjects() end

function Editor:duplicateSelectedMapObject() return self.map_interaction:duplicateSelectedMapObject() end

function Editor:applyDrawFXToSelection(fx_id) return self.map_interaction:applyDrawFXToSelection(fx_id) end

function Editor:getDrawFXMenuItems() return self.map_interaction:getDrawFXMenuItems() end

function Editor:openMapObjectContext(selection, x, y) return self.map_interaction:openMapObjectContext(selection, x, y) end

function Editor:startObjectReferenceDrag(control) return self.map_interaction:startObjectReferenceDrag(control) end

function Editor:getObjectReferenceLabel(value) return self.map_interaction:getObjectReferenceLabel(value) end

function Editor:finishObjectReferenceDrag(x, y) return self.map_interaction:finishObjectReferenceDrag(x, y) end

function Editor:getObjectLinkProperties(selection) return self.map_interaction:getObjectLinkProperties(selection) end

function Editor:startObjectLink(selection, property) return self.map_interaction:startObjectLink(selection, property) end

function Editor:chooseObjectLink(selection, x, y) return self.map_interaction:chooseObjectLink(selection, x, y) end

function Editor:finishObjectLink(target) return self.map_interaction:finishObjectLink(target) end

function Editor:cancelObjectLink(silent) return self.map_interaction:cancelObjectLink(silent) end

function Editor:recordGameError(phase, trace) return self.preview_controller:recordGameError(phase, trace) end

function Editor:runGameCallback(phase, callback) return self.preview_controller:runGameCallback(phase, callback) end

function Editor:runGameDraw(phase, callback) return self.preview_controller:runGameDraw(phase, callback) end

function Editor:getGameCanvasScreenCenter() return self.ui_controller:getGameCanvasScreenCenter() end

function Editor:positionGameCanvasAtScreen(screen_x, screen_y) return self.ui_controller:positionGameCanvasAtScreen(screen_x, screen_y) end

function Editor:centerWindow(display, desktop_width, desktop_height) return self.ui_controller:centerWindow(display, desktop_width, desktop_height) end

function Editor:update()
    if self.document_providers then self.document_providers:broadcast("update") end
    local preview_owner = self:getGamePreviewOwnerPanel()
    if self.live_document and preview_owner
        and not self.dockspace:isPanelDisplayed(preview_owner)
        and not self.game_preview_paused then
        self:setGamePreviewPaused(true)
    end
    if self.live_document and not self.game_preview_paused and not self.exit_transition
        and self.source_state and self.source_state.update and not self.game_faulted then
        self:runGameCallback("update", function() self.source_state:update() end)
    end
    local ui_width, ui_height = self:getUIDimensions()
    self.menu_bar:setBounds(0, 0, ui_width)
    self.message_bar:setBounds(0, ui_height - EditorMessageBar.HEIGHT, ui_width)
    self.dockspace:setBounds(0, EditorMenuBar.HEIGHT, ui_width,
        ui_height - EditorMenuBar.HEIGHT - EditorMessageBar.HEIGHT)
    self.dockspace:update(DT)
    if self.creation_dialog then self.creation_dialog:update(DT) end
    if self.color_picker then self.color_picker:update(DT) end
    if self.path_picker then self.path_picker:update(DT) end
    if self.object_reference_picker then self.object_reference_picker:update(DT) end

    if self.entry_transition then
        self.entry_transition:update(DT)
        if self.entry_transition:isComplete() then
            self.entry_transition = nil
            if self.pending_tile_editing_mode then
                self.pending_tile_editing_mode = nil
                self:setTileEditingMode(true)
            end
        end
    elseif self.exit_transition then
        self.exit_transition:update(DT)
    end

end

function Editor:drawGame()
    if self.live_document and self.source_state and self.source_state.draw and not self.game_faulted then
        self:runGameDraw("draw", function() self.source_state:draw() end)
    end
    local transition = self.entry_transition or self.exit_transition
    if transition then transition:draw() end
end

function Editor:drawEditor(canvas)
    love.graphics.origin()
    love.graphics.clear(0.055, 0.055, 0.065, 1)
    self.game_preview:setCanvas(canvas)
    love.graphics.push()
    love.graphics.scale(self:getUIScale())
    self.dockspace:draw()
    if self.drag_preview then
        local x, y = self:getMousePosition()
        local font = EditorFont.get(16)
        love.graphics.setFont(font)
        local preview = self.drag_preview
        if preview.event then
            love.graphics.push()
            love.graphics.translate(x + 18, y + 28)
            preview.event:draw(0.55)
            preview.event:drawBounds(0.55)
            love.graphics.pop()
        end
        local label = preview.label or tostring(preview.data or "")
        local icon = preview.icon and Assets.getTexture(preview.icon)
        local icon_width = icon and icon:getWidth() + 6 or 0
        local width = font:getWidth(label) + icon_width + 16
        Draw.setColor(0.10, 0.16, 0.24, 0.68)
        love.graphics.rectangle("fill", x + 14, y + 14, width, 28)
        Draw.setColor(0.45, 0.72, 1, 0.72)
        love.graphics.rectangle("line", x + 14.5, y + 14.5, width - 1, 27)
        local text_x = x + 22
        if icon then
            Draw.setColor(1, 1, 1, 0.58)
            Draw.draw(icon, text_x, y + 14 + math.floor((28 - icon:getHeight()) / 2))
            text_x = text_x + icon_width
        end
        Draw.setColor(0.92, 0.92, 0.95, 0.72)
        love.graphics.print(label, text_x, y + 19)
    end
    self.message_bar:draw()
    self.menu_bar:draw()
    if self.creation_dialog then self.creation_dialog:draw() end
    if self.color_picker then self.color_picker:draw() end
    if self.path_picker then self.path_picker:draw() end
    if self.object_reference_picker then self.object_reference_picker:draw() end
    love.graphics.pop()
    local mouse_x, mouse_y = self:getMousePosition()
    self.editor_cursor:setType(self:getCursorType(mouse_x, mouse_y))
end

function Editor:getCursorType(x, y)
    if self.entry_transition or self.exit_transition then return "cannot" end
    if self.object_reference_picker then return self.object_reference_picker:getCursorType(x, y) end
    if self.path_picker then return self.path_picker:getCursorType(x, y) end
    if self.color_picker then return self.color_picker:getCursorType(x, y) end
    if self.creation_dialog then return self.creation_dialog:getCursorType(x, y) end
    if self.message_bar:containsPoint(x, y) then return "select" end
    local menu_cursor = self.menu_bar:getCursorType(x, y)
    if menu_cursor ~= "default" then return menu_cursor end
    return self.dockspace:getCursorType(x, y)
end

function Editor:openCreationDialog(options) return self.ui_controller:openCreationDialog(options) end

function Editor:closeCreationDialog(created) return self.ui_controller:closeCreationDialog(created) end

function Editor:openColorPicker(value, on_apply) return self.ui_controller:openColorPicker(value, on_apply) end

function Editor:closeColorPicker(applied) return self.ui_controller:closeColorPicker(applied) end

function Editor:openPathPicker(value, items, options) return self.ui_controller:openPathPicker(value, items, options) end

function Editor:closePathPicker(applied) return self.ui_controller:closePathPicker(applied) end

function Editor:openObjectReferencePicker(value, options) return self.ui_controller:openObjectReferencePicker(value, options) end

function Editor:closeObjectReferencePicker(applied) return self.ui_controller:closeObjectReferencePicker(applied) end

function Editor:setTileEditingMode(enabled) return self.preview_controller:setTileEditingMode(enabled) end

function Editor:detachGamePreview() return self.preview_controller:detachGamePreview() end

function Editor:isStandaloneGamePreviewEnabled() return self.preview_controller:isStandaloneGamePreviewEnabled() end

function Editor:getGamePreviewOwnerPanel() return self.preview_controller:getGamePreviewOwnerPanel() end

function Editor:setGamePreviewPaused(paused) return self.preview_controller:setGamePreviewPaused(paused) end

function Editor:toggleGamePreviewPaused() return self.preview_controller:toggleGamePreviewPaused() end

function Editor:setStandaloneGamePreviewMap(id, options) return self.preview_controller:setStandaloneGamePreviewMap(id, options) end

function Editor:setStandaloneGamePreviewEnabled(enabled) return self.preview_controller:setStandaloneGamePreviewEnabled(enabled) end

function Editor:closeGamePreviewFromGameMenu() return self.preview_controller:closeGamePreviewFromGameMenu() end

function Editor:captureGamePreviewSnapshot(document) return self.preview_controller:captureGamePreviewSnapshot(document) end

function Editor:restoreGamePreviewSnapshot() return self.preview_controller:restoreGamePreviewSnapshot() end

function Editor:getGamePreviewMusic() return self.preview_controller:getGamePreviewMusic() end

function Editor:suspendGamePreviewAudio(stop_sounds) return self.preview_controller:suspendGamePreviewAudio(stop_sounds) end

function Editor:resumeGamePreviewAudio() return self.preview_controller:resumeGamePreviewAudio() end

function Editor:clearForwardedGameMouse() return self.preview_controller:clearForwardedGameMouse() end

function Editor:applyGameViewState(document) return self.preview_controller:applyGameViewState(document) end

function Editor:loadRuntimeMap(id) return self.document_manager:loadRuntimeMap(id) end

function Editor:openMap(id) return self.document_manager:openMap(id) end

function Editor:findMapDocument(id) return self.document_manager:findMapDocument(id) end

function Editor:findWorldDocument(id) return self.document_manager:findWorldDocument(id) end

function Editor:openWorld(world) return self.document_manager:openWorld(world) end

function Editor:activateMapDocument(document, options) return self.document_manager:activateMapDocument(document, options) end

function Editor:showGamePreview(options) return self.preview_controller:showGamePreview(options) end

function Editor:openMapTab(id, dock_target) return self.document_manager:openMapTab(id, dock_target) end

function Editor:isMapTabDropTarget(x, y) return self.document_manager:isMapTabDropTarget(x, y) end

function Editor:getMapPanelDropTarget(x, y) return self.document_manager:getMapPanelDropTarget(x, y) end

function Editor:addMapToView(id, x, y, document) return self.document_manager:addMapToView(id, x, y, document) end

function Editor:addMapToWorld(world, map_id) return self.document_manager:addMapToWorld(world, map_id) end

function Editor:removeMapFromView(id, document) return self.document_manager:removeMapFromView(id, document) end

function Editor:removeMapDocument(document) return self.document_manager:removeMapDocument(document) end

function Editor:isGamePreviewMounted() return self.preview_controller:isGamePreviewMounted() end


function Editor:isGamePreviewInputActive() return self.preview_controller:isGamePreviewInputActive() end

function Editor:canForwardGameKeyboardInput() return self.preview_controller:canForwardGameKeyboardInput() end

function Editor:canUseGameDebugInput() return self.preview_controller:canUseGameDebugInput() end

function Editor:isGameDebugOverlayActive() return self.preview_controller:isGameDebugOverlayActive() end

function Editor:handleGameDebugKeyPressed(key, is_repeat) return self.preview_controller:handleGameDebugKeyPressed(key, is_repeat) end

function Editor:getGamePreviewPosition(x, y, allow_outside) return self.preview_controller:getGamePreviewPosition(x, y, allow_outside) end

function Editor:getGameInputPosition(x, y, allow_outside) return self.preview_controller:getGameInputPosition(x, y, allow_outside) end

function Editor:activateGameObjectSelection() return self.preview_controller:activateGameObjectSelection() end

function Editor:clearGameObjectSelection() return self.preview_controller:clearGameObjectSelection() end

function Editor:getGameObjectPropertiesTarget(object) return self.preview_controller:getGameObjectPropertiesTarget(object) end

function Editor:isGameObjectSelectionActive() return self.preview_controller:isGameObjectSelectionActive() end

function Editor:updateGameObjectSelectionCursor(x, y) return self.preview_controller:updateGameObjectSelectionCursor(x, y) end

function Editor:getGameObjectAtCursor() return self.preview_controller:getGameObjectAtCursor() end

function Editor:handleGameObjectSelectionMousePressed(x, y, button, istouch, presses) return self.preview_controller:handleGameObjectSelectionMousePressed(x, y, button, istouch, presses) end

function Editor:handleGameObjectSelectionMouseReleased(x, y, button, istouch, presses) return self.preview_controller:handleGameObjectSelectionMouseReleased(x, y, button, istouch, presses) end

function Editor:hasForwardedMouseButton() return self.preview_controller:hasForwardedMouseButton() end

function Editor:forwardGameKeyPressed(key, is_repeat) return self.preview_controller:forwardGameKeyPressed(key, is_repeat) end

function Editor:forwardGameKeyReleased(key) return self.preview_controller:forwardGameKeyReleased(key) end

function Editor:forwardGameTextInput(text) return self.preview_controller:forwardGameTextInput(text) end

function Editor:forwardGameMousePressed(x, y, button, istouch, presses) return self.preview_controller:forwardGameMousePressed(x, y, button, istouch, presses) end

function Editor:forwardGameMouseMoved(x, y, dx, dy, istouch) return self.preview_controller:forwardGameMouseMoved(x, y, dx, dy, istouch) end

function Editor:forwardGameMouseReleased(x, y, button, istouch, presses) return self.preview_controller:forwardGameMouseReleased(x, y, button, istouch, presses) end

function Editor:onKeyPressed(key, is_repeat)
    if self.entry_transition or self.exit_transition then return true end
    if self.object_reference_picker then
        return self.object_reference_picker:onKeyPressed(key, is_repeat)
    end
    if self.path_picker then return self.path_picker:onKeyPressed(key, is_repeat) end
    if self.color_picker then return self.color_picker:onKeyPressed(key, is_repeat) end
    if self.creation_dialog then return self.creation_dialog:onKeyPressed(key, is_repeat) end
    if self.dockspace.context_menu and self.dockspace.context_menu.searchable then
        return self.dockspace:onKeyPressed(key, is_repeat) ~= false
    end
    if self.settings_browser and self.settings_browser:isCapturingKeybind() then
        return self.dockspace:onKeyPressed(key, is_repeat) ~= false
    end
    if self:handleGameDebugKeyPressed(key, is_repeat) then return true end
    if not is_repeat and Input.is("editor_command_palette", key) then
        self.consumed_editor_keys[key] = true
        Input.clear("editor_command_palette")
        return self:openCommandPalette()
    end
    if self.menu_bar:onKeyPressed(key) then return true end
    local focused = self.dockspace.focused_control
    local editing_text = focused and focused.accepts_text_input
    if Input.ctrl() and not is_repeat and (key == "c" or key == "x" or key == "v") then
        self.consumed_editor_keys[key] = true
        if self.dockspace:onKeyPressed(key, is_repeat) then return true end
        if focused and (focused.accepts_text_input or focused.accepts_clipboard_input) then return true end
        if key == "c" then return self:copySelectedMapObjects() end
        if key == "x" then return self:cutSelectedMapObjects() end
        return self:pasteMapObjects()
    end
    if Input.ctrl() and not is_repeat and key == "s" then
        if Input.shift() then return self:saveAllDocuments() end
        return self:saveActiveDocument()
    end
    if Input.ctrl() and not is_repeat
        and not editing_text then
        if key == "z" then return Input.shift() and self:redo() or self:undo() end
        if key == "y" then return self:redo() end
    end
    if not is_repeat and not editing_text and self.tile_editing_mode then
        if Input.is("editor_delete", key) then
            self.consumed_editor_keys[key] = true
            Input.clear("editor_delete")
            local view = self.active_document and self.active_document.map_view
            local object_selection = self.active_document
                and self:getSelectedMapObjects(self.active_document) or {}
            if #object_selection > 0 or not (view and view:deleteTileSelection()) then
                self:deleteSelectedMapObject(false)
            end
            return true
        end
        for _, tool in ipairs(self.tool_registry:getAll()) do
            if tool.keybind and Input.is(tool.keybind, key) then
                self.consumed_editor_keys[key] = true
                Input.clear(tool.keybind)
                self:setActiveTool(tool.id)
                return true
            end
        end
    end
    if key == "escape" and (self.asset_drag or self.project_file_drag
        or self.object_reference_drag or self.object_link or self.drag_preview) then
        local cancelled_link = self:cancelObjectLink()
        self.asset_drag, self.project_file_drag = nil, nil
        self.object_reference_drag, self.drag_preview = nil, nil
        if not cancelled_link and self.message_bar then self.message_bar:setStatus("Drag cancelled") end
        return true
    end
    if key == "escape" and self.placement_event_id
        and not editing_text then
        self:setActiveTool("select")
        return true
    end
    if key == "space" and not is_repeat and self.live_document
        and not editing_text then
        self.consumed_editor_keys[key] = true
        self:toggleGamePreviewPaused()
        return true
    end
    if key == "g" and not is_repeat
        and not editing_text then
        self.consumed_editor_keys[key] = true
        self.show_tile_grid = not self.show_tile_grid
        return true
    end
    if Input.is("editor_view", key) and not is_repeat and not editing_text then
        self.consumed_editor_keys[key] = true
        Input.clear("editor_view")
        self:setTileEditingMode(not self.tile_editing_mode)
        return true
    end
    if Input.is("editor", key) and not is_repeat then
        self.consumed_editor_keys[key] = true
        Input.clear("editor")
        Kristal.exitEditor()
        return true
    end
    if self.dockspace:onKeyPressed(key, is_repeat) then return true end
    if editing_text then return true end
    return self:forwardGameKeyPressed(key, is_repeat)
end

function Editor:beginExitTransition()
    if self.entry_transition or self.exit_transition then return false end
    local message = "Save your changes before leaving the editor?"
    if self.pending_project_switch_id then
        local project = Kristal.Mods.getMod(self.pending_project_switch_id)
        local name = project and (project.name or project.id) or self.pending_project_switch_id
        message = "Save your changes before switching to '" .. tostring(name) .. "'?"
    end
    if not self:confirmUnsavedChanges({ message = message }) then return false end
    self:cancelPolygonBuilds()
    self:cancelEventRegionDrags()
    self:saveSession()
    self.session_saved_for_exit = true
    if self.live_document then
        if self.game_preview_paused then
            self.game_preview_movement_lock = self.game_preview_lock_before_pause == true
        else
            self.game_preview_movement_lock = Game.lock_movement
        end
    end
    self:stopEditingMusic()
    self:suspendGamePreviewAudio(true)
    Game.lock_movement = true
    self.exit_transition = EditorModeTransition("exit", function(transition)
        self:finishExitTransition(transition)
    end)
    return true
end

function Editor:finishExitTransition(transition)
    if Kristal.getState() ~= self then return end
    local snapshot = self.game_preview_snapshot and TableUtils.copy(self.game_preview_snapshot, true)
    local snapshot_save_id = self.game_preview_snapshot_save_id
    local resume_game_music = self.game_music_suspended_by_editor == true
    local game_lock_movement = self.game_preview_movement_lock
    local return_to_menu = self.return_to_menu_on_exit == true
    local switch_project_id = self.pending_project_switch_id
    self.game_preview_snapshot = nil
    self.game_preview_snapshot_document = nil
    self.game_preview_snapshot_save_id = nil
    self.game_music_suspended_by_editor = false
    self.exit_transition = nil
    Kristal.popState()
    Kristal.pushState("EditorTransition", "exit_tail", {
        transition = transition,
        game_snapshot = snapshot,
        game_snapshot_save_id = snapshot_save_id,
        resume_game_music = resume_game_music,
        game_lock_movement = game_lock_movement,
        return_to_menu = return_to_menu,
        switch_project_id = switch_project_id
    })
end

function Editor:onKeyReleased(key)
    if self.entry_transition or self.exit_transition then return true end
    if self.object_reference_picker then return self.object_reference_picker:onKeyReleased(key) end
    if self.path_picker then return self.path_picker:onKeyReleased(key) end
    if self.color_picker then return self.color_picker:onKeyReleased(key) end
    if self.creation_dialog then return self.creation_dialog:onKeyReleased(key) end
    if self:isGameDebugOverlayActive() and self:canUseGameDebugInput() then
        self:runGameCallback("debug menu input", function()
            Kristal.DebugSystem:onKeyReleased(key)
        end)
        return true
    end
    if self.consumed_editor_keys[key] then
        self.consumed_editor_keys[key] = nil
        return true
    end
    if self.dockspace:onKeyReleased(key) then return true end
    return self:forwardGameKeyReleased(key)
end

function Editor:onTextInput(text)
    if self.entry_transition or self.exit_transition then return true end
    if self.object_reference_picker then return self.object_reference_picker:onTextInput(text) end
    if self.path_picker then return self.path_picker:onTextInput(text) end
    if self.color_picker then return self.color_picker:onTextInput(text) end
    if self.creation_dialog then return self.creation_dialog:onTextInput(text) end
    if self.dockspace:onTextInput(text) then return true end
    return self:forwardGameTextInput(text)
end

function Editor:onMousePressed(x, y, button, istouch, presses)
    if self.entry_transition or self.exit_transition then return true end
    x, y = self:screenToUI(x, y)
    if self.object_reference_picker then
        return self.object_reference_picker:onMousePressed(x, y, button, istouch, presses)
    end
    if self.path_picker then return self.path_picker:onMousePressed(x, y, button, istouch, presses) end
    if self.color_picker then return self.color_picker:onMousePressed(x, y, button, istouch, presses) end
    if self.creation_dialog then return self.creation_dialog:onMousePressed(x, y, button, istouch, presses) end
    if self.message_bar:containsPoint(x, y) then
        if button == 1 then self:toggleDiagnosticsPanel() end
        return true
    end
    if self.menu_bar:onMousePressed(x, y, button) then return true end
    if self.dockspace:onMousePressed(x, y, button, presses) then return true end
    if self:handleGameObjectSelectionMousePressed(x, y, button, istouch, presses) then return true end
    return self:forwardGameMousePressed(x, y, button, istouch, presses)
end

function Editor:onMouseMoved(x, y, dx, dy, istouch)
    if self.entry_transition or self.exit_transition then return true end
    x, y = self:screenToUI(x, y)
    dx, dy = self:screenDeltaToUI(dx, dy)
    if self.object_reference_picker then
        return self.object_reference_picker:onMouseMoved(x, y, dx, dy, istouch)
    end
    if self.path_picker then return self.path_picker:onMouseMoved(x, y, dx, dy, istouch) end
    if self.color_picker then return self.color_picker:onMouseMoved(x, y, dx, dy, istouch) end
    if self.creation_dialog then return self.creation_dialog:onMouseMoved(x, y, dx, dy, istouch) end
    self:updateGameObjectSelectionCursor(x, y)
    if self.dockspace:onMouseMoved(x, y, dx, dy) then return true end
    local debug_system = Kristal.DebugSystem
    if self:isGameObjectSelectionActive()
        and (debug_system.grabbing or debug_system.context and debug_system.context.grabbing) then
        return true
    end
    return self:forwardGameMouseMoved(x, y, dx, dy, istouch)
end

function Editor:onMouseReleased(x, y, button, istouch, presses)
    if self.entry_transition or self.exit_transition then return true end
    x, y = self:screenToUI(x, y)
    if self.object_reference_picker then
        return self.object_reference_picker:onMouseReleased(x, y, button, istouch, presses)
    end
    if self.path_picker then return self.path_picker:onMouseReleased(x, y, button, istouch, presses) end
    if self.color_picker then return self.color_picker:onMouseReleased(x, y, button, istouch, presses) end
    if self.creation_dialog then return self.creation_dialog:onMouseReleased(x, y, button, istouch, presses) end
    if self.dockspace:onMouseReleased(x, y, button, presses) then return true end
    if self:handleGameObjectSelectionMouseReleased(x, y, button, istouch, presses) then return true end
    return self:forwardGameMouseReleased(x, y, button, istouch, presses)
end

function Editor:onWheelMoved(x, y)
    if self.entry_transition or self.exit_transition then return true end
    if self.object_reference_picker then return self.object_reference_picker:onWheelMoved(x, y) end
    if self.path_picker then return self.path_picker:onWheelMoved(x, y) end
    if self.color_picker then return self.color_picker:onWheelMoved(x, y) end
    if self.creation_dialog then return self.creation_dialog:onWheelMoved(x, y) end
    if self:isGameDebugOverlayActive() and self:canUseGameDebugInput() then
        self:runGameCallback("debug menu input", function()
            Kristal.DebugSystem:onWheelMoved(x, y)
        end)
        return true
    end
    local mouse_x, mouse_y = self:getMousePosition()
    if self.message_bar:containsPoint(mouse_x, mouse_y) then return true end
    return self.dockspace:onWheelMoved(x, y)
end

function Editor:captureLayout() return self.ui_controller:captureLayout() end

function Editor:getDefaultPanelLayout() return self.ui_controller:getDefaultPanelLayout() end

function Editor:resetPanelLayout() return self.ui_controller:resetPanelLayout() end

function Editor:restoreLayout(layout) return self.ui_controller:restoreLayout(layout) end

return Editor
