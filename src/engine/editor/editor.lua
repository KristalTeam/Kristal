local EDITOR_DEFAULT_WIDTH = 1280
local EDITOR_DEFAULT_HEIGHT = 800
local EDITOR_SESSION_VERSION = 5
local EDITOR_SESSION_DIRECTORY = "editor"
local EDITOR_MUSIC = "edit"
local EDITOR_MUSIC_VOLUME = 0.5
local EDITOR_MUSIC_FADE_TIME = 1

---@class Editor
local Editor = {
    editor_mode = true,
    owns_window_input = true
}

local function fromPixels(value)
    return love.window.fromPixels and love.window.fromPixels(value) or value
end

local function toPixels(value)
    return love.window.toPixels and love.window.toPixels(value) or value
end

local function hasMap(id)
    return id and (Registry.getMap(id) or Registry.getMapData(id))
end

local function safeProjectId(id)
    return tostring(id or "unknown"):gsub("[^%w%._%-]", "_")
end

function Editor:init()
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

function Editor:resetEditingMusic()
    if self.music then self.music:remove() end
    self.music = Music()
    self.editing_music_started = false
end

function Editor:resumeEditingMusic()
    if not self.editing_music_started then
        self.music:play(EDITOR_MUSIC, 0)
        if not self.music.source then return false end
        self.music:fade(EDITOR_MUSIC_VOLUME, EDITOR_MUSIC_FADE_TIME)
        self.editing_music_started = true
    elseif self.music:canResume() then
        self.music:resume()
    end
    return true
end

function Editor:pauseEditingMusic()
    if self.music:isPlaying() then self.music:pause() end
end

function Editor:stopEditingMusic()
    self.music:stop()
    self.editing_music_started = false
end

function Editor:syncEditingMusic()
    if self.editor_music_enabled == false then
        self:stopEditingMusic()
        return
    end
    local preview_running = self.live_document ~= nil
        and not self.game_preview_paused
        and not self.game_faulted
        and not self.exit_transition
    if preview_running then
        self:pauseEditingMusic()
    else
        self:resumeEditingMusic()
    end
end

function Editor:getSessionPath()
    return EDITOR_SESSION_DIRECTORY .. "/" .. safeProjectId(self.project_id) .. ".json"
end

function Editor:loadSession()
    local path = self:getSessionPath()
    if not love.filesystem.getInfo(path) then return nil end
    local success, result = pcall(function()
        return JSON.decode(love.filesystem.read(path))
    end)
    if not success or type(result) ~= "table" then
        local message = success and "expected a JSON object" or tostring(result)
        self:addWarning("Could not restore the editor session: " .. message, nil, "editor_session")
        return nil
    end
    if type(result.version) == "number" and result.version > EDITOR_SESSION_VERSION then
        self:addWarning("Editor session was created by a newer format and was not restored",
            nil, "editor_session")
        return nil
    end
    return result
end

function Editor:getNextDocumentPanelId()
    local index = 1
    while self.dockspace.panels["map_document:" .. index] do index = index + 1 end
    return "map_document:" .. index
end

function Editor:createMapDocument(id, panel_id)
    if not hasMap(id) then return nil end
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

function Editor:configureWorldDocument(document, source, primary_map_id)
    if not document or not source then return false end
    local world = EditorWorld(source.id)
    world.name = source.name or source.id
    world.data = TableUtils.copy(source.data or {}, true)
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

function Editor:restoreDocumentView(document, state)
    if type(state) ~= "table" then return end
    local view = document.game_view
    if type(state.zoom) == "number" then
        view.view_zoom = MathUtils.clamp(state.zoom, view.minimum_zoom, view.maximum_zoom)
    end
    if type(state.canvas_x) == "number" and type(state.canvas_y) == "number" then
        view:setCanvasPosition(state.canvas_x, state.canvas_y)
    end
end

function Editor:restoreGameViewState(document, state)
    if type(state) ~= "table" then return end
    document.game_view_state = {
        canvas_x = type(state.canvas_x) == "number" and state.canvas_x or nil,
        canvas_y = type(state.canvas_y) == "number" and state.canvas_y or nil,
        zoom = type(state.zoom) == "number" and state.zoom or nil
    }
end

function Editor:captureGameViewState(document)
    if self.live_document == document and self.game_preview then
        return {
            canvas_x = self.game_preview.canvas_x,
            canvas_y = self.game_preview.canvas_y,
            zoom = self.game_preview.view_zoom
        }
    end
    return document.game_view_state and TableUtils.copy(document.game_view_state, true) or nil
end

function Editor:captureSession()
    local session = {
        version = EDITOR_SESSION_VERSION,
        project_id = self.project_id,
        tile_editing_mode = self.tile_editing_mode,
        tile_grid = self.show_tile_grid,
        standalone_preview_enabled = self:isStandaloneGamePreviewEnabled(),
        standalone_preview_map_id = self.standalone_preview_map_id,
        active_tileset_id = self.active_tileset_id,
        active_world_id = self.active_world_id,
        tile_palette_random = self.tile_palette and self.tile_palette.random_mode or false,
        active_panel_id = self.active_document and self.active_document.panel.id,
        preferences = {
            custom_cursors = self.use_custom_cursors,
            deltarune_font = self.use_deltarune_font,
            editor_music = self.editor_music_enabled,
            darken_unselected_layers = self.darken_unselected_layers
        },
        settings = self.settings and self.settings:getStoredValues() or {},
        document_providers = self.document_providers and self.document_providers:captureSession() or {},
        documents = {},
        layout = self:captureLayout(),
        window = { width = love.graphics.getWidth(), height = love.graphics.getHeight() }
    }
    for _, document in ipairs(self.map_documents or {}) do
        local view = document.game_view
        local saved_document = {
            panel_id = document.panel.id,
            primary_map_id = document.primary_map_id,
            editor_world = document.editor_world == true,
            world_id = document.world and document.world.id,
            primary_position = document:getPrimaryMap() and {
                x = document:getPrimaryMap().x,
                y = document:getPrimaryMap().y
            } or nil,
            maps = {},
            view = {
                canvas_x = view.canvas_x,
                canvas_y = view.canvas_y,
                zoom = view.view_zoom
            },
            game_view = self:captureGameViewState(document)
        }
        local primary = document:getPrimaryMap()
        for _, entry in ipairs(document.maps) do
            if entry ~= primary and entry.explicit_companion then
                table.insert(saved_document.maps, { id = entry.id, x = entry.x, y = entry.y })
            end
        end
        table.insert(session.documents, saved_document)
    end
    return session
end

function Editor:saveSession()
    if not self.dockspace or not self.map_documents or not self.project_id then return false end
    local success, encoded = pcall(JSON.encode, self:captureSession())
    if not success then
        print("Could not encode editor session: " .. tostring(encoded))
        return false
    end
    love.filesystem.createDirectory(EDITOR_SESSION_DIRECTORY)
    local written, message = love.filesystem.write(self:getSessionPath(), encoded)
    if not written then
        print("Could not save editor session: " .. tostring(message))
        return false
    end
    return true
end

function Editor:setupWindow(session)
    local width, height, flags = love.window.getMode()
    local window_x, window_y, display = love.window.getPosition()
    local game_offset_x, game_offset_y = Kristal.getSideOffsets()
    local game_scale = Kristal.getGameScale()
    local game_center_x = window_x + fromPixels(game_offset_x + (SCREEN_WIDTH * game_scale / 2))
    local game_center_y = window_y + fromPixels(game_offset_y + (SCREEN_HEIGHT * game_scale / 2))
    self.previous_window = {
        width = width,
        height = height,
        x = window_x,
        y = window_y,
        display = display,
        flags = TableUtils.copy(flags, true)
    }
    self.previous_mouse_visible = love.mouse.isVisible()
    self.previous_mouse_cursor = love.mouse.getCursor()

    local desktop_width, desktop_height = love.window.getDesktopDimensions(flags.display or 1)
    local current_width = flags.fullscreen and 0 or love.graphics.getWidth()
    local current_height = flags.fullscreen and 0 or love.graphics.getHeight()
    local saved_width = session and type(session.window) == "table" and session.window.width
    local saved_height = session and type(session.window) == "table" and session.window.height
    local requested_width = type(saved_width) == "number" and saved_width or math.max(current_width, EDITOR_DEFAULT_WIDTH)
    local requested_height = type(saved_height) == "number" and saved_height or math.max(current_height, EDITOR_DEFAULT_HEIGHT)
    local ui_scale = self:getUIScale()
    local minimum_width = MathUtils.round((SCREEN_WIDTH + 570) * ui_scale)
    local minimum_height = MathUtils.round(
        (SCREEN_HEIGHT + EditorMenuBar.HEIGHT + EditorMessageBar.HEIGHT + 100) * ui_scale)
    local editor_width = math.min(desktop_width, math.max(minimum_width, requested_width))
    local editor_height = math.min(desktop_height,
        math.max(minimum_height, requested_height))
    local editor_flags = TableUtils.copy(flags, true)
    editor_flags.fullscreen = false
    editor_flags.resizable = true
    editor_flags.minwidth = math.min(editor_width, minimum_width)
    editor_flags.minheight = math.min(editor_height, minimum_height)
    love.window.updateMode(fromPixels(editor_width), fromPixels(editor_height), editor_flags)
    self:centerWindow(display, desktop_width, desktop_height)
    Kristal.refreshWindowText()
    love.mouse.setVisible(true)
    love.window.setTitle((Mod and Mod.info.name or "Kristal") .. " - Editor")
    return game_center_x, game_center_y
end

function Editor:registerMenuBar()
    self.menu_bar:registerItem("file", "save_active", "Save Active Document (Ctrl+S)", {
        is_enabled = function()
            local provider = self.document_providers:getFocused()
            if provider then return provider:canSave() ~= false end
            return self.active_document ~= nil or self.active_tileset_document ~= nil
        end,
        on_activate = function() self:saveActiveDocument() end
    })
    self.menu_bar:registerItem("file", "save_tileset", "Save Active Tileset", {
        is_enabled = function() return self.active_tileset_document ~= nil end,
        on_activate = function() self:saveTilesetDocumentToProject(self.active_tileset_document) end
    })
    self.menu_bar:registerItem("file", "save_world", "Save Selected World", {
        is_enabled = function() return self.active_editor_world ~= nil end,
        on_activate = function() self:saveWorldDocumentToProject(self.active_editor_world) end
    })
    self.menu_bar:registerItem("file", "save_all", "Save All (Ctrl+Shift+S)", {
        is_enabled = function() return self:hasUnsavedChanges() end,
        on_activate = function() self:saveAllDocuments() end
    })
    self.menu_bar:registerItem("file", "exit_editor",
        self.return_to_menu_on_exit and "Return to Main Menu" or "Return to Game", {
            on_activate = function() Kristal.exitEditor() end
        })
    self.menu_bar:registerItem("edit", "undo", "Undo", {
        is_enabled = function() return self:canUndo() end,
        on_activate = function() self:undo() end
    })
    self.menu_bar:registerItem("edit", "redo", "Redo", {
        is_enabled = function() return self:canRedo() end,
        on_activate = function() self:redo() end
    })
    self.menu_bar:registerItem("edit", "settings", "Editor Settings...", {
        on_activate = function() self:showSettingsPanel() end
    })
    self.menu_bar:registerToggle("edit", "tile_editing", "Map Editing View (Tab)",
        function() return self.tile_editing_mode end,
        function(enabled) self:setTileEditingMode(enabled) end)
    self.menu_bar:registerToggle("view", "custom_cursors", "Use Custom Cursors",
        function() return self.use_custom_cursors end,
        function(enabled) self:setCustomCursorsEnabled(enabled) end)
    self.menu_bar:registerToggle("view", "deltarune_font", "Use Deltarune Font",
        function() return self.use_deltarune_font end,
        function(enabled) self:setDeltaruneFontEnabled(enabled) end)
    self.menu_bar:registerToggle("view", "editor_music", "Editor Music",
        function() return self.editor_music_enabled end,
        function(enabled) self:setEditingMusicEnabled(enabled) end)
    self.menu_bar:registerToggle("view", "tile_grid", "Tile Grid (G)",
        function() return self.show_tile_grid end,
        function(enabled) self.show_tile_grid = enabled == true end)
    self.menu_bar:registerItem("view", "command_palette", "Command Palette (Ctrl+Shift+P)", {
        on_activate = function() self:openCommandPalette() end
    })
    self.menu_bar:registerItem("view", "reset_layout", "Reset to Default", {
        on_activate = function() self:resetPanelLayout() end
    })
    self.menu_bar:registerProvider("window", "panels", function()
        local items = {}
        for _, panel in ipairs(self.dockspace.panel_order) do
            local current_panel = panel
            if current_panel.recoverable then
                table.insert(items, {
                    id = current_panel.id,
                    label = current_panel.title,
                    get_checked = function() return current_panel.visible end,
                    on_activate = function()
                        self.dockspace:setPanelVisible(current_panel, not current_panel.visible)
                    end
                })
            end
        end
        return items
    end)
end

function Editor:registerEditorTools()
    self.tool_registry = EditorToolRegistry()
    self.tool_registry:register("select", {
        name = "Select", icon = "editor/ui/tool/select", keybind = "editor_tool_select"
    })
    self.tool_registry:register("world_select", {
        name = "World Select", short_name = "World", icon = "editor/ui/tool/world",
        keybind = "editor_tool_world_select"
    })
    self.tool_registry:register("object", {
        name = "Add Object", short_name = "Object", icon = "editor/ui/tool/shape_point",
        keybind = "editor_tool_object"
    })
    self.tool_registry:register("shape", {
        name = "Shape", icon = "editor/ui/tool/shape_rect", keybind = "editor_tool_shape"
    })
    self.tool_registry:register("tile_brush", {
        name = "Tile Brush", short_name = "Brush", icon = "editor/ui/tool/brush",
        keybind = "editor_tool_tile_brush"
    })
    self.tool_registry:register("tile_fill", {
        name = "Tile Fill", short_name = "Fill", icon = "editor/ui/tool/bucket",
        keybind = "editor_tool_tile_fill"
    })
    self.tool_registry:register("eraser", {
        name = "Eraser", icon = "editor/ui/tool/eraser", keybind = "editor_tool_eraser"
    })
    self.tool_registry:register("link", {
        name = "Link Objects", short_name = "Link", icon = "editor/ui/tool/link",
        keybind = "editor_tool_link"
    })
    self.active_tool = "select"
    self.selected_event_id = nil
    self.shape_mode = "rectangle"
    for _, registered in ipairs(self.tool_registry:getAll()) do
        local tool = registered
        self.command_registry:register("tool:" .. tool.id, {
            name = tool.name .. " Tool",
            category = "Tools",
            keywords = { tool.id, tool.short_name or "" },
            is_enabled = function() return self.tile_editing_mode and self.active_document ~= nil end,
            get_checked = function() return self.active_tool == tool.id end,
            action = function() self:setActiveTool(tool.id) end
        })
    end
end

function Editor:registerEditorSettings(session)
    local stored = TableUtils.copy(session and session.settings or {}, true)
    local legacy = session and session.preferences or {}
    if stored["appearance.custom_cursors"] == nil and legacy.custom_cursors ~= nil then
        stored["appearance.custom_cursors"] = legacy.custom_cursors
    end
    if stored["appearance.font"] == nil and legacy.deltarune_font ~= nil then
        stored["appearance.font"] = legacy.deltarune_font ~= false and "deltarune" or "default"
    end
    if stored["appearance.editor_music"] == nil and legacy.editor_music ~= nil then
        stored["appearance.editor_music"] = legacy.editor_music
    end
    if stored["appearance.darken_unselected"] == nil and legacy.darken_unselected_layers ~= nil then
        stored["appearance.darken_unselected"] = legacy.darken_unselected_layers
    end
    if stored["appearance.ui_scale"] == nil and stored["appearance.font_scale"] ~= nil then
        stored["appearance.ui_scale"] = stored["appearance.font_scale"]
    end
    stored["appearance.font_scale"] = nil

    self.settings = EditorSettingsRegistry(self, stored)
    self.settings:registerPage("appearance", "Appearance")
    self.settings:registerSetting("appearance", "appearance.font", {
        name = "Editor Font", type = "choice", default = "deltarune",
        choices = { { value = "deltarune", label = "Deltarune" }, { value = "default", label = "System Default" } },
        set = function(value, editor) editor.use_deltarune_font = value == "deltarune" end
    })
    self.settings:registerSetting("appearance", "appearance.ui_scale", {
        name = "UI Scale", type = "number", default = 1, minimum = 0.5, maximum = 2,
        description = "Adjust the scale of the editor's UI- note, the font may look odd on non-integer scaling.",
        set = function(value, editor) editor.ui_scale = value end
    })
    self.settings:registerSetting("appearance", "appearance.custom_cursors", {
        name = "Use Custom Cursors", type = "boolean", default = true,
        set = function(value, editor)
            editor.use_custom_cursors = value
            if editor.editor_cursor then editor.editor_cursor:setCustomEnabled(value) end
        end
    })
    self.settings:registerSetting("appearance", "appearance.darken_unselected", {
        name = "Darken Unselected Layers", type = "boolean", default = true,
        set = function(value, editor)
            editor.darken_unselected_layers = value
            if editor.layers_browser and editor.layers_browser.darken_toggle then
                editor.layers_browser.darken_toggle:setValue(value, true)
            end
        end
    })
    self.settings:registerSetting("appearance", "appearance.editor_music", {
        name = "Editor Music", type = "boolean", default = true,
        set = function(value, editor)
            editor.editor_music_enabled = value
            if editor.music then editor:syncEditingMusic() end
        end
    })

    self.settings:registerPage("editing", "Editing")
    self.settings:registerSetting("editing", "editing.history_limit", {
        name = "Undo History Limit", type = "integer", default = EditorHistory.DEFAULT_LIMIT,
        minimum = 1, maximum = 10000,
        description = "Maximum completed edit commands retained in memory.",
        get = function(editor) return editor.history:getLimit() end,
        set = function(value, editor) return editor.history:setLimit(value) end
    })

    self.settings:registerPage("keybinds", "Keybinds")
    local function keybind(id, name, alias)
        self.settings:registerSetting("keybinds", id, {
            name = name, type = "keybind", persistent = false, apply_initial = false,
            get = function() return Input.getPrimaryBind(alias, false) end,
            set = function(value)
                if not Input.setBind(alias, 1, value, false) then return false end
                Input.saveBinds()
                return true
            end
        })
    end
    keybind("keybinds.toggle_editor", "Toggle Editor", "editor")
    keybind("keybinds.toggle_map_view", "Toggle Map/Game View", "editor_view")
    keybind("keybinds.command_palette", "Command Palette", "editor_command_palette")
    keybind("keybinds.delete_selection", "Delete Selection", "editor_delete")
    for _, tool in ipairs(self.tool_registry:getAll()) do
        if tool.keybind then
            keybind("keybinds.tool_" .. tool.id, tool.name .. " Tool", tool.keybind)
        end
    end
end

function Editor:setupTilesetDocuments(session)
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

function Editor:setActiveTileset(document)
    if type(document) == "string" then
        for _, candidate in ipairs(self.tileset_documents or {}) do
            if candidate.id == document then document = candidate break end
        end
    end
    if not document or not document.data then return false end
    self.active_tileset_document = document
    self.active_tileset_id = document.id
    if self.tileset_panel then
        self.tileset_panel.title = "Tileset Editor" .. (document:isDirty() and " *" or "")
    end
    if self.tile_palette then self.tile_palette:setTilesetDocument(document) end
    if self.tileset_editor and self.tileset_panel and self.tileset_panel.visible then
        self.tileset_editor:setDocument(document)
    end
    return true
end

function Editor:setSelectedTile(tile)
    self.selected_tile = tile
    if self.tile_palette then self.tile_palette:setSelectedTile(tile) end
    if self.tileset_editor then self.tileset_editor:setTile(tile) end
end

function Editor:showTilesetEditor(document)
    if document then self:setActiveTileset(document) end
    if not self.tileset_panel then return false end
    if not self.tileset_panel.visible then self.dockspace:setPanelVisible(self.tileset_panel, true, "center") end
    self.tileset_editor:setDocument(self.active_tileset_document)
    if self.selected_tile then self.tileset_editor:setTile(self.selected_tile) end
    if self.tileset_panel.stack then self.tileset_panel.stack:setActivePanel(self.tileset_panel) end
    self.dockspace:setFocus(self.tileset_editor)
    return true
end

function Editor:setShapeMode(mode)
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

function Editor:getShapeModes()
    return {
        { id = "point", name = "Point", icon = "editor/ui/tool/shape_point" },
        { id = "line", name = "Line", icon = "editor/ui/tool/shape_line" },
        { id = "rectangle", name = "Rectangle", icon = "editor/ui/tool/shape_rect" },
        { id = "ellipse", name = "Ellipse", icon = "editor/ui/tool/shape_ellipse" },
        { id = "polygon", name = "Polygon", icon = "editor/ui/tool/shape_poly" },
        { id = "polyline", name = "Polyline", icon = "editor/ui/tool/shape_polyline" }
    }
end

function Editor:setupMapDocuments(session)
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
        if type(saved_document) == "table" and hasMap(saved_document.primary_map_id) and not existing then
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
                        and hasMap(saved_map.id) then
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
    if not context_document and hasMap(self.map_id) then
        context_document = self:createMapDocument(self.map_id)
    end
    if #self.map_documents == 0 then error("Editor session has no valid map document") end

    self.game_preview = EditorGameView(self, context_document or self.map_documents[1])
    self.game_view = self.game_preview
    self.live_document = nil
    self.standalone_preview_map_id = session and hasMap(session.standalone_preview_map_id)
        and session.standalone_preview_map_id
        or (context_document or self.map_documents[1]).primary_map_id
    self.standalone_preview_document = EditorMapDocument(self, self.standalone_preview_map_id)
    if session and session.game_preview_view and context_document and not context_document.game_view_state then
        self:restoreGameViewState(context_document, session.game_preview_view)
    end
    return context_document, restored_by_panel
end

function Editor:setupCodeDocuments(session)
    self.document_providers:restoreSession(session and session.document_providers or {})
end

function Editor:setupPanels(session)
    self.files_panel = self.dockspace:registerPanel(EditorPanel(
        "project_files", "Files", self.file_browser, {
            minimum_width = 200, preferred_width = 280, recoverable = true
        }), "left")
    self.maps_panel = self.dockspace:registerPanel(EditorPanel("maps", "Maps", self.map_browser, {
        minimum_width = 180,
        preferred_width = 260,
        recoverable = true
    }), self.files_panel.stack)
    self.worlds_panel = self.dockspace:registerPanel(EditorPanel(
        "worlds", "Worlds", self.world_browser, {
            minimum_width = 180, preferred_width = 260, recoverable = true
        }), self.maps_panel.stack)
    self.tilesets_browser_panel = self.dockspace:registerPanel(EditorPanel(
        "tilesets_browser", "Tilesets", self.tileset_browser, {
            minimum_width = 180, preferred_width = 260, recoverable = true
        }), self.maps_panel.stack)
    self.maps_panel.stack:setActivePanel(self.maps_panel)
    self.events_panel = self.dockspace:registerPanel(EditorPanel("events", "Events", self.event_browser, {
        minimum_width = 180,
        minimum_height = 160,
        preferred_width = 260,
        preferred_height = 300,
        recoverable = true
    }), "left")
    self.dockspace:dockPanelSplit(self.events_panel, self.maps_panel.stack, "bottom")
    self.fx_panel = self.dockspace:registerPanel(EditorPanel("draw_fx", "DrawFX", self.fx_browser, {
        minimum_width = 200,
        minimum_height = 180,
        preferred_width = 280,
        preferred_height = 300,
        recoverable = true
    }), self.events_panel.stack)
    self.events_panel.stack:setActivePanel(self.events_panel)
    self.toolbar_panel = self.dockspace:registerPanel(EditorPanel("toolbar", "Tools", self.toolbar, {
        minimum_width = 360,
        minimum_height = 36,
        preferred_height = 72,
        recoverable = true
    }), "top")
    self.layers_panel = self.dockspace:registerPanel(EditorPanel("layers", "Layers", self.layers_browser, {
        minimum_width = 220,
        minimum_height = 360,
        preferred_width = 300,
        recoverable = true
    }), "right")
    self.properties_panel = self.dockspace:registerPanel(EditorPanel(
        "properties", "Properties", self.properties_browser, {
            minimum_width = 220,
            minimum_height = 180,
            preferred_width = 300,
            preferred_height = 300,
            recoverable = true
        }), "right")
    self.dockspace:dockPanelSplit(self.properties_panel, self.layers_panel.stack, "bottom")
    self.console_panel = self.dockspace:registerPanel(EditorPanel("console", "Console", self.console_browser, {
        minimum_width = 360,
        minimum_height = 140,
        preferred_height = 260,
        recoverable = true
    }), "bottom")
    self.tile_palette_panel = self.dockspace:registerPanel(EditorPanel(
        "tile_palette", "Tile Palette", self.tile_palette, {
            minimum_width = 360,
            minimum_height = 150,
            preferred_height = 240,
            recoverable = true
        }), self.console_panel.stack)
    self.console_panel.stack:setActivePanel(self.console_panel)
    self.tileset_panel = self.dockspace:registerPanel(EditorPanel(
        "tileset_editor", "Tileset Editor", self.tileset_editor, {
            visible = false,
            minimum_width = 440,
            minimum_height = 300,
            preferred_width = 760,
            preferred_height = 520,
            recoverable = true
        }), "center")
    self.source_viewer_panel = self.dockspace:registerPanel(EditorPanel(
        "source_viewer", "Source Viewer", self.source_viewer, {
            visible = false,
            minimum_width = 480,
            minimum_height = 320,
            preferred_width = 800,
            preferred_height = 560,
            recoverable = true
        }), "center")
    self.diagnostics_panel = self.dockspace:registerPanel(EditorPanel(
        "diagnostics", "Warnings and Errors", self.diagnostics_browser, {
            visible = false,
            minimum_width = 360,
            minimum_height = 140,
            preferred_height = 260,
            recoverable = true
        }), "bottom")
    self.settings_panel = self.dockspace:registerPanel(EditorPanel("settings", "Editor Settings",
        self.settings_browser, {
            visible = false,
            minimum_width = 520,
            minimum_height = 360,
            preferred_width = 760,
            preferred_height = 540,
            recoverable = true
        }), "center")
    self.game_preview_panel = self.dockspace:registerPanel(EditorPanel(
        "game_preview", "Game Preview", self.game_preview, {
            visible = true,
            minimum_width = 320,
            minimum_height = 240,
            preferred_width = SCREEN_WIDTH,
            preferred_height = SCREEN_HEIGHT + 28,
            recoverable = true,
            on_activate = function()
                if self.game_preview_panel.visible then self.dockspace:setFocus(self.game_preview) end
            end,
            on_visibility_changed = function(_, visible)
                self:setStandaloneGamePreviewEnabled(visible)
            end
        }), "center")
    EditorPlugins:createPanels(self)
    self.dockspace.sizes.left = 260
    self.dockspace.sizes.right = 300
    self.dockspace.sizes.top = 72
    self.dockspace.sizes.bottom = 260
    self.dockspace.minimum_center_width = SCREEN_WIDTH
    self.dockspace.minimum_center_height = SCREEN_HEIGHT + 28
    local ui_width, ui_height = self:getUIDimensions()
    self.menu_bar:setBounds(0, 0, ui_width)
    self.message_bar:setBounds(0, ui_height - EditorMessageBar.HEIGHT, ui_width)
    self.dockspace:setBounds(0, EditorMenuBar.HEIGHT, ui_width,
        ui_height - EditorMenuBar.HEIGHT - EditorMessageBar.HEIGHT)

    self.default_layout = self:captureLayout()
    if session and type(session.layout) == "table" then
        local had_properties_panel = session.layout.panels and session.layout.panels.properties
        local had_events_panel = session.layout.panels and session.layout.panels.events
        local had_tilesets_browser = session.layout.panels and session.layout.panels.tilesets_browser
        local saved_layout = TableUtils.copy(session.layout, true)
        if saved_layout.panels and saved_layout.panels.game_preview then
            saved_layout.panels.game_preview.visible = session.standalone_preview_enabled ~= false
        end
        local restored, message = pcall(function() self:restoreLayout(saved_layout) end)
        if not restored then
            self:restoreLayout(self.default_layout)
            self:addWarning("Could not restore the editor panel layout: " .. tostring(message),
                nil, "editor_session")
        elseif not had_properties_panel then
            self.dockspace:dockPanelSplit(self.properties_panel, self.layers_panel.stack, "bottom")
        end
        if restored and not had_events_panel and self.maps_panel.stack then
            self.dockspace:dockPanelSplit(self.events_panel, self.maps_panel.stack, "bottom")
        end
        if restored and not had_tilesets_browser and self.maps_panel.stack then
            self.maps_panel.stack:setActivePanel(self.maps_panel)
        end
        if restored and (session.version or 1) < 2 then
            if not self.fx_panel.visible then self.dockspace:setPanelVisible(self.fx_panel, true, "left") end
            self.dockspace:dockPanel(self.fx_panel, self.events_panel.stack)
            self.events_panel.stack:setActivePanel(self.events_panel)
            if not self.console_panel.visible then
                self.dockspace:setPanelVisible(self.console_panel, true, "bottom")
            end
            local bottom_stack = self.tile_palette_panel.stack or self.console_panel.stack
            bottom_stack:addPanel(self.console_panel, 1)
            bottom_stack:setActivePanel(self.console_panel)
            self.dockspace:layout()
        end
    end
end

function Editor:restoreEntryState(session, options, context_document, restored_by_panel, game_center_x, game_center_y)
    local active_document
    if options.restore_active_document and session then
        active_document = restored_by_panel[session.active_panel_id]
    end
    active_document = active_document or context_document or self.map_documents[1]
    local desired_tile_mode = options.game_preview ~= true
    self.suppress_panel_activation = false
    self:activateMapDocument(active_document, { select_panel = false, set_mode = false })
    if self.entry_transition and desired_tile_mode then
        self.pending_tile_editing_mode = true
        self:setTileEditingMode(false)
    else
        self:setTileEditingMode(desired_tile_mode)
    end
    if not options.restore_active_document then
        self:positionGameCanvasAtScreen(game_center_x, game_center_y)
    end
    if self.game_preview_panel.visible then self:setStandaloneGamePreviewEnabled(true) end
end

function Editor:enter(previous, options)
    options = options or {}
    self:resetEditingMusic()
    self.source_state = options.source_state or previous
    self.return_to_menu_on_exit = options.return_to_menu == true
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
    self.game_preview_snapshot = nil
    self.game_preview_snapshot_document = nil
    self.game_preview_snapshot_save_id = nil
    self.game_music_suspended_by_editor = false
    self.stale_runtime_maps = {}
    self.project_id = options.project_id or (Mod and Mod.info.id)
    self.map_id = options.map_id or (Game.world and Game.world.map and Game.world.map.id)
    self.message_bar = EditorMessageBar()
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
    self.tileset_editor = EditorTilesetPanel(self)
    self.tile_palette.random_mode = session and session.tile_palette_random == true or false
    self.tile_palette.random_toggle:setValue(self.tile_palette.random_mode, true)
    self.tile_palette:setTilesetDocument(self.active_tileset_document)
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
    self:clearGameObjectSelection()
    if not self.session_saved_for_exit then self:saveSession() end
    if self.project_workspace then self.project_workspace:shutdown() end
    EditorPlugins:shutdown(self)
    if self.document_providers then self.document_providers:shutdown() end
    self.dockspace:setFocus(nil)
    local game_center_x, game_center_y = self:getGameCanvasScreenCenter()
    local window = self.previous_window
    if window then love.window.updateMode(window.width, window.height, window.flags) end
    Kristal.refreshWindowText()
    local game_offset_x, game_offset_y = Kristal.getSideOffsets()
    local game_scale = Kristal.getGameScale()
    local window_x = game_center_x - fromPixels(game_offset_x + (SCREEN_WIDTH * game_scale / 2))
    local window_y = game_center_y - fromPixels(game_offset_y + (SCREEN_HEIGHT * game_scale / 2))
    love.window.setPosition(MathUtils.round(window_x), MathUtils.round(window_y), window and window.display)
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
    self.tileset_browser = nil
    self.tilesets_browser_panel = nil
    self.tile_palette = nil
    self.tile_palette_panel = nil
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
    self.placement_tile = nil
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
    self.drag_preview = nil
    self.object_reference_drag = nil
    self.object_link = nil
    self.selected_map_object = nil
    self.selected_map_objects = nil
    self.history = nil
    self.properties_browser = nil
    self.properties_panel = nil
    self.properties_target_owner = nil
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
    self.game_preview_snapshot = nil
    self.game_preview_snapshot_document = nil
    self.game_preview_snapshot_save_id = nil
    self.game_music_suspended_by_editor = nil
    self.editing_music_started = nil
    self.editor_music_enabled = nil
    self.game_preview_movement_lock = nil
    self.game_preview_lock_before_pause = nil
end

function Editor:setPropertiesTarget(target, owner)
    self.properties_target_owner = owner
    if self.properties_browser then self.properties_browser:setTarget(target) end
end

function Editor:clearPropertiesTarget(owner)
    if owner and self.properties_target_owner ~= owner then return false end
    self.properties_target_owner = nil
    if self.properties_browser then self.properties_browser:setTarget(nil) end
    return true
end

function Editor:setCustomCursorsEnabled(enabled)
    enabled = enabled ~= false
    if self.settings and self.settings:getSetting("appearance.custom_cursors") then
        return self.settings:setValue("appearance.custom_cursors", enabled)
    end
    self.use_custom_cursors = enabled
    if self.editor_cursor then self.editor_cursor:setCustomEnabled(enabled) end
end

function Editor:setDeltaruneFontEnabled(enabled)
    enabled = enabled ~= false
    if self.settings and self.settings:getSetting("appearance.font") then
        return self.settings:setValue("appearance.font", enabled and "deltarune" or "default")
    end
    self.use_deltarune_font = enabled
end

function Editor:setEditingMusicEnabled(enabled)
    enabled = enabled ~= false
    if self.settings and self.settings:getSetting("appearance.editor_music") then
        return self.settings:setValue("appearance.editor_music", enabled)
    end
    self.editor_music_enabled = enabled
    self:syncEditingMusic()
end

function Editor:addDiagnostic(severity, message, detail, source)
    return self.message_bar:add(severity, message, detail, source)
end

function Editor:addWarning(message, detail, source)
    return self.message_bar:addWarning(message, detail, source)
end

function Editor:addError(message, detail, source)
    return self.message_bar:addError(message, detail, source)
end

function Editor:clearDiagnostics(source)
    self.message_bar:clear(source)
end

local function validContentId(id)
    if type(id) ~= "string" or id == "" or id:sub(1, 1) == "/" then return false end
    for segment in id:gmatch("[^/]+") do
        if segment == "." or segment == ".." or segment:find("[\\:*?\"<>|]") then return false end
    end
    return true
end

function Editor:isValidContentId(id)
    return validContentId(id)
end

function Editor:renameWorldId(world, id)
    id = tostring(id or ""):match("^%s*(.-)%s*$")
    if not world or id == world.id then return world ~= nil end
    if not validContentId(id) then
        self:addWarning("Invalid world ID '" .. id .. "'", nil, "world_id")
        return false
    end
    local existing = Registry.getEditorWorld(id)
    if existing and existing ~= world then
        self:addWarning("A world with ID '" .. id .. "' already exists", nil, "world_id")
        return false
    end
    local old_id = world.id
    local document = self:findWorldDocument(old_id)
    Registry.editor_worlds[old_id] = nil
    world.id = id
    world.data = world.data or {}
    world.data.id = id
    if document then
        document.editor_world = true
        document.world.id = id
    end
    Registry.registerEditorWorld(id, world)
    self.active_world_id = id
    self.active_editor_world = world
    self:clearDiagnostics("world_id")
    if self.world_browser then self.world_browser:refresh(id) end
    return true
end

function Editor:getContentSavePath(kind, id)
    if not validContentId(id) then return nil, "Invalid " .. kind .. " id '" .. tostring(id) .. "'" end
    local directory = kind == "map" and Registry.paths.maps
        or kind == "tileset" and Registry.paths.tilesets
        or kind == "world" and EditorFormat.WORLD_DIRECTORY
    if not directory then return nil, "Unknown editor content kind '" .. tostring(kind) .. "'" end
    return Mod.info.path .. "/scripts/" .. directory .. "/" .. id .. ".json"
end

function Editor:getMapSavePath(id)
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

function Editor:getTilesetSavePath(document)
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

function Editor:getWorldSavePath(world)
    local path = world and world.data and world.data.full_path
    if type(path) == "string"
        and path:sub(-#EditorFormat.WORLD_EXTENSION) == EditorFormat.WORLD_EXTENSION
        and (path == Mod.info.path or StringUtils.startsWith(path, Mod.info.path .. "/")) then
        return path
    end
    return self:getContentSavePath("world", world.id)
end

function Editor:saveMapDocumentToProject(document, options)
    if not document then return false end
    options = options or {}
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
    self:clearDiagnostics("unsaved_exit")
    self.discard_changes_confirmed = false
    self:selectMapObjects({})
    if self.layers_browser and self.active_document == document then
        self.layers_browser:setDocument(nil)
        self.layers_browser:setDocument(document)
    end
    if self.map_browser then self.map_browser:refresh() end
    return true
end

function Editor:saveTilesetDocumentToProject(document)
    if not document then return false end
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
    self:clearDiagnostics("unsaved_exit")
    self.discard_changes_confirmed = false
    self:setActiveTileset(document)
    if self.tileset_browser then self.tileset_browser:refresh(document.id) end
    if self.tileset_editor and self.active_tileset_document == document then
        self.tileset_editor:setDocument(document)
    end
    return true
end

function Editor:saveWorldToProject(world)
    if not world then return false end
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

function Editor:saveWorldDocumentToProject(world)
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

function Editor:saveAllDocuments()
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

function Editor:saveActiveDocument()
    local provider_result = self.document_providers:invokeFocused("saveActive")
    if provider_result ~= nil then return provider_result end
    local focused = self.dockspace and self.dockspace.focused_control
    while focused do
        if focused == self.world_browser then
            return self:saveWorldDocumentToProject(self.active_editor_world)
        end
        if focused == self.tileset_editor or focused == self.tile_palette or focused == self.tileset_browser then
            return self:saveTilesetDocumentToProject(self.active_tileset_document)
        end
        focused = focused.parent
    end
    if self.active_document and self.active_document.editor_world then
        return self:saveWorldDocumentToProject(self.active_document.world)
    end
    return self:saveMapDocumentToProject(self.active_document)
end

function Editor:createNewMap(id, name, options)
    options = options or {}
    if not validContentId(id) then return nil, "Invalid map id" end
    if hasMap(id) then return nil, "A map with that id already exists" end
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
    local document = self:createMapDocument(id)
    if not document then return nil, "Could not create an editor document" end
    self.history.serial = self.history.serial + 1
    document.history_revision = self.history.serial
    self:activateMapDocument(document)
    self:onHistoryChanged({ document }, false)
    return document
end

function Editor:showDiagnosticsPanel()
    if not self.diagnostics_panel then return false end
    if not self.diagnostics_panel.visible then
        self.dockspace:setPanelVisible(self.diagnostics_panel, true, "bottom")
    end
    if self.diagnostics_panel.stack then self.diagnostics_panel.stack:setActivePanel(self.diagnostics_panel) end
    self.dockspace:setFocus(self.diagnostics_browser)
    return true
end

function Editor:toggleDiagnosticsPanel()
    if not self.diagnostics_panel then return false end
    if self.dockspace:isPanelDisplayed(self.diagnostics_panel) then
        self.dockspace:setPanelVisible(self.diagnostics_panel, false)
        return true
    end
    return self:showDiagnosticsPanel()
end

function Editor:showSettingsPanel()
    if not self.settings_panel then return false end
    if not self.settings_panel.visible then
        self.dockspace:setPanelVisible(self.settings_panel, true, "center")
    end
    if self.settings_panel.stack then self.settings_panel.stack:setActivePanel(self.settings_panel) end
    self.dockspace:setFocus(self.settings_browser.pages)
    return true
end

function Editor:setActiveTool(id)
    if not self.tool_registry:get(id) then return false end
    if id ~= "shape" then self:cancelPolygonBuilds() end
    if id ~= "object" then self:cancelEventRegionDrags() end
    if id ~= "link" then self:cancelObjectLink(true) end
    self.active_tool = id
    if id ~= "object" then self.placement_tile = nil end
    self.placement_event_id = id == "object" and not self.placement_tile and self.selected_event_id or nil
    return true
end

function Editor:cancelPolygonBuilds()
    local cancelled = false
    for _, document in ipairs(self.map_documents or {}) do
        if document.map_view and document.map_view.polygon_build then
            document.map_view:cancelPolygon()
            cancelled = true
        end
    end
    return cancelled
end

function Editor:cancelEventRegionDrags()
    local cancelled = false
    for _, document in ipairs(self.map_documents or {}) do
        if document.map_view and document.map_view.event_region_drag then
            document.map_view:cancelEventRegion()
            cancelled = true
        end
        if document.map_view and document.map_view.event_paint_stroke then
            document.map_view:cancelEventPaint()
            cancelled = true
        end
    end
    return cancelled
end

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

function Editor:openCommandPalette()
    local items = {}
    for _, registered in ipairs(self.command_registry:getAll()) do
        local command = registered
        local category = tostring(command.category or "Command")
        local name = tostring(command.name or command.id)
        local keywords = command.keywords
        if type(keywords) == "table" then keywords = table.concat(keywords, " ") end
        table.insert(items, {
            label = category .. ": " .. name,
            search_text = table.concat({ name, category, tostring(command.id or ""), tostring(keywords or "") }, " "),
            is_enabled = command.is_enabled,
            get_checked = command.get_checked,
            action = function()
                if not command.is_enabled or command.is_enabled() ~= false then command.action() end
            end
        })
    end
    if #items == 0 then return false end
    self.menu_bar.open_menu = nil
    local width = math.min(620, math.max(320, self.dockspace.width - 24))
    local x = self.dockspace.x + math.floor((self.dockspace.width - width) / 2)
    return self.dockspace:openContextMenu(items, x, self.dockspace.y + 18, self, {
        searchable = true,
        maximum_rows = 14,
        width = width,
        placeholder = "Type a command..."
    })
end

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
    self.discard_changes_confirmed = false
    self:clearDiagnostics("unsaved_exit")
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
        owner.discard_close_confirmed = false
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
                self.tileset_editor:setDocument(owner)
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

function Editor:hasUnsavedChanges()
    for _, document in ipairs(self.map_documents or {}) do
        if document:isDirty() then return true end
    end
    for _, document in ipairs(self.tileset_documents or {}) do
        if document:isDirty() then return true end
    end
    if self.document_providers:any("hasUnsavedChanges") then return true end
    return false
end

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

function Editor:showDocumentProviderPanel(panel, control, focus)
    if not panel then return false end
    if not panel.visible then self.dockspace:setPanelVisible(panel, true, "center") end
    if panel.stack then panel.stack:setActivePanel(panel) end
    self.dockspace:setFocus(focus or control)
    return true
end

function Editor:openDocument(document, options)
    if not document then return false end
    local opened, reason = self.document_providers:open(document, options)
    if opened == false and reason then self:addError("Could not open " .. document.name, reason, "filesystem") end
    return opened
end

function Editor:setPlacementEvent(id)
    if not Registry.getEditorEvent(id) then return false end
    self:cancelPolygonBuilds()
    self:cancelEventRegionDrags()
    self.selected_event_id = id
    self.placement_event_id = id
    self.placement_tile = nil
    self.active_tool = "object"
    return true
end

function Editor:setPlacementTile(tileset_id, tile_id)
    if not Registry.getTileset(tileset_id) or tile_id == nil then return false end
    self:cancelPolygonBuilds()
    self:cancelEventRegionDrags()
    self.placement_event_id = nil
    self.placement_tile = { tileset = tileset_id, tile_id = tile_id }
    self.active_tool = "object"
    if self.message_bar then
        self.message_bar:setStatus("Tile Object: click an object layer to place tile "
            .. tostring(tile_id) .. " (Ctrl for free placement)", 3600)
    end
    return true
end

function Editor:beginAssetDrag(kind, id, label)
    self.asset_drag = { kind = kind, id = id, label = label or id }
    local icon
    if kind == "drawfx" then icon = "editor/ui/tool/brush" end
    self:beginDragPreview(kind, label or id, icon, id)
    return true
end

function Editor:beginDragPreview(kind, label, icon, data)
    self.drag_preview = { kind = kind, label = label, icon = icon, data = data }
    if kind == "event" then
        local event_class = Registry.getEditorEvent(data)
        local point = event_class and event_class.placement_shape == "point"
        local shape = point and "point" or "rectangle"
        local success, event = pcall(Registry.createEditorEvent, data, {
            x = point and 0 or -20, y = point and 0 or -20, shape = shape,
            width = point and 0 or 40, height = point and 0 or 40,
            properties = {}
        }, {})
        if success then self.drag_preview.event = event end
    end
    return true
end

function Editor:updateDragPreview(x, y)
    if not self.drag_preview then return false end
    self.drag_preview.x, self.drag_preview.y = x, y
    return true
end

function Editor:finishDragPreview()
    self.drag_preview = nil
end

function Editor:updateAssetDrag(x, y)
    if not self.asset_drag then return false end
    self.asset_drag.x, self.asset_drag.y = x, y
    self:updateDragPreview(x, y)
    return true
end

function Editor:getMapViewAt(x, y)
    for _, document in ipairs(self.map_documents or {}) do
        local panel = document.panel
        if panel and panel.content == document.map_view and self.dockspace:isPanelDisplayed(panel)
            and document.map_view:containsPoint(x, y) then
            return document.map_view
        end
    end
end

function Editor:getMapObjectAtScreen(x, y)
    local view = self:getMapViewAt(x, y)
    if not view then return nil end
    local local_x, local_y = view:toLocal(x, y)
    local world_x, world_y = view:getMapCoordinates(local_x, local_y)
    return view.document:findObjectAt(world_x, world_y, { all_layers = true }), view, world_x, world_y
end

function Editor:addMapToWorldAtScreen(id, x, y)
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

function Editor:removeMapFromWorld(world, map_id)
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

function Editor:finishAssetDrag(x, y)
    local drag = self.asset_drag
    self.asset_drag = nil
    self:finishDragPreview()
    if not drag then return false end
    local selection, view, world_x, world_y = self:getMapObjectAtScreen(x, y)
    if drag.kind == "drawfx" then
        if not selection then
            self:addWarning("Drop DrawFX onto an event or shape", nil, "drawfx_drop")
            return false
        end
        self:selectMapObject(selection)
        return self:applyDrawFXToSelection(drag.id)
    elseif drag.kind == "event" and view then
        local event_class = Registry.getEditorEvent(drag.id)
        if event_class and event_class.placement_shape == "region" then
            return self:setPlacementEvent(drag.id)
        end
        return self:placeEvent(view, drag.id, world_x, world_y)
    end
    return false
end

function Editor:placeEvent(view, event_id, world_x, world_y)
    self:beginHistoryTransaction("Place Event", view.document)
    local object, layer_or_reason, map_id = view.document:addEditorObject(event_id, nil, world_x, world_y)
    if not object then
        self:cancelHistoryTransaction()
        self:addWarning(layer_or_reason, nil, "event_placement")
        return false
    end
    self:clearDiagnostics("event_placement")
    local selection = view.document:getObjectSelection(map_id, layer_or_reason, object)
    selection.view = view
    self:selectMapObject(selection)
    self:markHistoryChanged()
    self:commitHistoryTransaction()
    self:setActiveTool("select")
    return true
end

function Editor:placeTileObject(view, tileset_id, tile_id, world_x, world_y)
    self:beginHistoryTransaction("Place Tile Object", view.document)
    local object, layer_or_reason, map_id = view.document:addTileObject(
        tileset_id, tile_id, nil, world_x, world_y)
    if not object then
        self:cancelHistoryTransaction()
        self:addWarning(layer_or_reason, nil, "tile_object_placement")
        return false
    end
    self:clearDiagnostics("tile_object_placement")
    local selection = view.document:getObjectSelection(map_id, layer_or_reason, object)
    selection.view = view
    self:selectMapObject(selection)
    self:markHistoryChanged()
    self:commitHistoryTransaction()
    return true
end

function Editor:getMapObjectPropertiesTarget(selection)
    local data = selection.data
    data.properties = data.properties or {}
    data.__editor_property_types = data.__editor_property_types or {}
    local event_id = selection.document:getEditorObjectType(data, selection.map_id)
    local layer_type = Registry.getLayerType(selection.layer._editor_type_id)
    local editor_event = Registry.createEditorEvent(event_id, data, {
        depth = selection.layer._editor_depth_override or 0,
        layer_uid = selection.layer._editor_uid,
        layer = selection.layer,
        layer_type = layer_type,
        layer_color = Registry.layer_types:getLayerColor(selection.layer, layer_type),
        map_id = selection.map_id,
        map_data = Registry.getMapData(selection.map_id)
    })
    data.__editor_fx = data.__editor_fx or {}
    local fx_sections = {}
    for index, assignment in ipairs(data.__editor_fx) do
        if type(assignment) == "string" then
            assignment = { id = assignment, properties = {}, __editor_property_types = {} }
            data.__editor_fx[index] = assignment
        end
        local definition = Registry.getEditorDrawFX(assignment.id)
        if definition then
            local current_assignment = assignment
            local fx = Registry.createEditorDrawFX(assignment.id, assignment)
            table.insert(fx_sections, {
                title = fx:getName(),
                property_set = fx.property_set,
                on_changed = function() selection.document:invalidatePreview(selection.map_id) end,
                on_remove = function()
                    self:performHistoryEdit("Remove DrawFX", selection.document, function()
                        return TableUtils.removeValue(data.__editor_fx, current_assignment) ~= nil
                    end)
                    self:setPropertiesTarget(self:getMapObjectPropertiesTarget(selection), self)
                end
            })
        end
    end
    local function numberField(label, key)
        return EditorPropertyFields.number(data, label, key, {
            on_set = function() selection.document:invalidatePreview(selection.map_id) end
        })
    end
    local function valueField(label, key)
        return EditorPropertyFields.value(data, label, key, {
            on_set = function() selection.document:invalidatePreview(selection.map_id) end
        })
    end
    local tile_object = data.gid or data.tileset and data.tile_id ~= nil
    local name_field = valueField("Name", "name")
    name_field.compact = true
    local type_field = valueField("Type", "type")
    type_field.compact = true
    type_field.rebuild_target = function()
        return self:getMapObjectPropertiesTarget(selection)
    end
    local fields = {
        name_field, type_field,
        numberField("X", "x"), numberField("Y", "y")
    }
    if tile_object then
        local tileset_choices = {}
        for id in pairs(Registry.tilesets or {}) do table.insert(tileset_choices, id) end
        table.sort(tileset_choices)
        table.insert(fields, {
            label = "Tileset", compact = true,
            get = function() return data.tileset or "" end,
            set = function(value) data.tileset = value ~= "" and value or nil return true end,
            choices = tileset_choices
        })
        table.insert(fields, numberField("Tile ID", "tile_id"))
        table.insert(fields, {
            label = "Flip X", compact = true,
            get = function() return data.flip_x == true end,
            set = function(value) data.flip_x = value == true return true end,
            choices = { { value = false, label = "No" }, { value = true, label = "Yes" } }
        })
        table.insert(fields, {
            label = "Flip Y", compact = true,
            get = function() return data.flip_y == true end,
            set = function(value) data.flip_y = value == true return true end,
            choices = { { value = false, label = "No" }, { value = true, label = "Yes" } }
        })
    else
        table.insert(fields, {
            label = "Shape",
            get = function() return selection.document:getObjectShape(selection) end,
            set = function(shape) return selection.document:setObjectShape(selection, shape) end,
            choices = {
                { value = "point", label = "Point" },
                { value = "rectangle", label = "Rectangle" },
                { value = "ellipse", label = "Ellipse" },
                { value = "line", label = "Line" },
                { value = "polygon", label = "Polygon" },
                { value = "polyline", label = "Polyline" }
            },
            rebuild = true
        })
    end
    table.insert(fields, numberField("Width", "width"))
    table.insert(fields, numberField("Height", "height"))
    if not tile_object and editor_event.scaling_mode == "scale" then
        table.insert(fields, numberField("Scale X", "scale_x"))
        table.insert(fields, numberField("Scale Y", "scale_y"))
    end
    table.insert(fields, numberField("Rotation", "rotation"))
    table.insert(fields, {
        label = "DrawFX",
        get = function()
            local ids = {}
            for _, assignment in ipairs(data.__editor_fx or {}) do
                table.insert(ids, type(assignment) == "table" and assignment.id or assignment)
            end
            return table.concat(ids, ", ")
        end,
        set = function() return false end,
        readonly = true
    })
    return {
        title = tile_object and "Tile Object"
            or event_id and (StringUtils.titleCase(tostring(event_id):gsub("[/_]", " "))) or "Map Object",
        history_owner = selection.document,
        fields = fields,
        properties = data.properties,
        property_types = data.__editor_property_types,
        property_set = editor_event.property_set,
        fx_sections = fx_sections,
        on_changed = function() selection.document:invalidatePreview(selection.map_id) end
    }
end

function Editor:isMapObjectSelected(selection)
    if not selection then return false end
    for _, candidate in ipairs(self.selected_map_objects or {}) do
        if candidate.document == selection.document and candidate.data == selection.data then return true end
    end
    return false
end

function Editor:getSelectedMapObjects(document)
    local result = {}
    for _, selection in ipairs(self.selected_map_objects or {}) do
        if not document or selection.document == document then table.insert(result, selection) end
    end
    return result
end

function Editor:getMapObjectBatchPropertiesTarget(selections)
    local function sharedValue(key)
        local value = selections[1] and (selections[1].data[key] or 0) or 0
        for index = 2, #selections do
            if (selections[index].data[key] or 0) ~= value then return "" end
        end
        return value
    end
    local function batchNumberField(label, key)
        return {
            label = label,
            compact = true,
            placeholder = "Mixed",
            get = function() return sharedValue(key) end,
            set = function(value)
                local number = tonumber(value)
                if not number then return false end
                local invalidated = {}
                for _, selection in ipairs(selections) do
                    selection.data[key] = number
                    invalidated[selection.map_id] = selection.document
                end
                for map_id, document in pairs(invalidated) do document:invalidatePreview(map_id) end
                return true
            end
        }
    end
    return {
        title = tostring(#selections) .. " Objects",
        history_owner = selections[1] and selections[1].document,
        fields = { batchNumberField("Rotation", "rotation") }
    }
end

function Editor:selectMapObjects(selections, primary)
    local unique, result = {}, {}
    for _, selection in ipairs(selections or {}) do
        local key = selection.document and tostring(selection.document) .. ":" .. tostring(selection.data)
        if selection.data and not unique[key] then
            unique[key] = true
            table.insert(result, selection)
        end
    end
    if primary then
        for index, selection in ipairs(result) do
            if selection.document == primary.document and selection.data == primary.data then
                table.remove(result, index)
                table.insert(result, 1, selection)
                break
            end
        end
    end
    self.selected_map_objects = result
    self.selected_map_object = result[1]
    if self.selected_map_object then
        local selection = self.selected_map_object
        selection.document:setSelectedLayer(selection.layer._editor_uid, selection.map_id)
        if self.layers_browser and self.active_document == selection.document then
            self.layers_browser:focusLayer(selection.document, selection.map_id, selection.layer)
        end
    end
    if #result == 1 then
        self:setPropertiesTarget(self:getMapObjectPropertiesTarget(result[1]), self)
    elseif #result > 1 then
        self:setPropertiesTarget(self:getMapObjectBatchPropertiesTarget(result), self)
    else
        self:clearPropertiesTarget(self)
    end
    return #result > 0
end

function Editor:selectMapObject(selection, additive)
    if not additive then return self:selectMapObjects(selection and { selection } or {}, selection) end
    local selections = self:getSelectedMapObjects()
    local found
    for index, candidate in ipairs(selections) do
        if candidate.document == selection.document and candidate.data == selection.data then
            table.remove(selections, index)
            found = true
            break
        end
    end
    if not found then table.insert(selections, selection) end
    return self:selectMapObjects(selections, found and nil or selection)
end

function Editor:deleteSelectedMapObject(explode, history_label)
    local selections = self:getSelectedMapObjects()
    if #selections == 0 then return false end
    local owners = {}
    for _, selection in ipairs(selections) do table.insert(owners, selection.document) end
    self:beginHistoryTransaction(history_label or (explode and "Explode Objects" or "Delete Objects"), owners)
    local removed = false
    local explosions = {}
    for _, selection in ipairs(selections) do
        if explode and selection.view then
            local x, y = selection.document:getObjectWorldCenter(selection)
            selection.view:addExplosion(x, y)
            table.insert(explosions, { document = selection.document, x = x, y = y })
        end
        removed = selection.document:removeEditorObject(selection) or removed
    end
    if removed then
        if #explosions > 0 then self:setHistoryMetadata("explosions", explosions) end
        self:markHistoryChanged()
        self:commitHistoryTransaction()
        self:selectMapObjects({})
    else
        self:cancelHistoryTransaction()
    end
    return removed
end

function Editor:copySelectedMapObjects(silent)
    local selected = self:getSelectedMapObjects()
    if #selected == 0 then return false end
    local objects = {}
    for _, selection in ipairs(selected) do
        table.insert(objects, {
            data = TableUtils.copy(selection.data, true),
            document = selection.document,
            map_id = selection.map_id
        })
    end
    self.map_object_clipboard = { objects = objects, paste_count = 0, cut = false }
    if not silent and self.message_bar then
        self.message_bar:setStatus(string.format("Copied %d object%s", #objects, #objects == 1 and "" or "s"))
    end
    return true
end

function Editor:cutSelectedMapObjects()
    local count = #(self.selected_map_objects or {})
    if not self:copySelectedMapObjects(true) then return false end
    if not self:deleteSelectedMapObject(false, "Cut Objects") then return false end
    self.map_object_clipboard.cut = true
    if self.message_bar then
        self.message_bar:setStatus(string.format("Cut %d object%s", count, count == 1 and "" or "s"))
    end
    return true
end

function Editor:pasteMapObjects()
    local clipboard = self.map_object_clipboard
    local document = self.active_document
    if not clipboard or not clipboard.objects or #clipboard.objects == 0 or not document then return false end
    local view = document.map_view
    local map_id = view and view.active_map_id or document.primary_map_id
    if not document.map_lookup[map_id] then map_id = document.primary_map_id end
    local layer = document:getSelectedObjectLayer(map_id)
    if not layer then
        if self.message_bar then self.message_bar:setStatus("Select an object layer before pasting") end
        return false
    end
    local first_cut_paste = clipboard.cut == true
    if first_cut_paste then
        clipboard.cut = false
        clipboard.paste_count = 0
    else
        clipboard.paste_count = (clipboard.paste_count or 0) + 1
    end
    local grid_width, grid_height = document:getTileLayerCellSize(nil, map_id)
    local offset_x = grid_width * (clipboard.paste_count or 0)
    local offset_y = grid_height * (clipboard.paste_count or 0)
    self:beginHistoryTransaction("Paste Objects", document)
    local pasted = {}
    layer.objects = layer.objects or {}
    for _, stored in ipairs(clipboard.objects) do
        local object = TableUtils.copy(stored.data, true)
        local preserve_id = first_cut_paste and stored.document == document and stored.map_id == map_id
        if not preserve_id then object.id = nil end
        object._editor_uid = nil
        object.x = (object.x or 0) + offset_x
        object.y = (object.y or 0) + offset_y
        document:getObjectId(object)
        table.insert(layer.objects, object)
        local selection = document:getObjectSelection(map_id, layer, object)
        selection.view = view
        table.insert(pasted, selection)
    end
    if #pasted == 0 then
        self:cancelHistoryTransaction()
        return false
    end
    document:invalidatePreview(map_id)
    self:markHistoryChanged()
    self:commitHistoryTransaction()
    self:selectMapObjects(pasted, pasted[1])
    if self.message_bar then
        self.message_bar:setStatus(string.format("Pasted %d object%s", #pasted, #pasted == 1 and "" or "s"))
    end
    return true
end

function Editor:duplicateSelectedMapObject()
    local selected = self:getSelectedMapObjects()
    local owners = {}
    for _, selection in ipairs(selected) do table.insert(owners, selection.document) end
    self:beginHistoryTransaction("Duplicate Objects", owners)
    local duplicates = {}
    for _, selection in ipairs(selected) do
        local object, layer = selection.document:duplicateEditorObject(selection)
        if object then
            local duplicate = selection.document:getObjectSelection(selection.map_id, layer, object)
            duplicate.view = selection.view
            table.insert(duplicates, duplicate)
        end
    end
    if #duplicates == 0 then self:cancelHistoryTransaction() return false end
    self:markHistoryChanged()
    self:commitHistoryTransaction()
    self:selectMapObjects(duplicates, duplicates[1])
    return true
end

function Editor:applyDrawFXToSelection(fx_id)
    local selection = self.selected_map_object
    if not selection then return false end
    self:beginHistoryTransaction("Add DrawFX", selection.document)
    if not selection.document:addObjectFX(selection, fx_id) then
        self:cancelHistoryTransaction()
        return false
    end
    self:markHistoryChanged()
    self:commitHistoryTransaction()
    self:setPropertiesTarget(self:getMapObjectPropertiesTarget(selection), self)
    return true
end

function Editor:getDrawFXMenuItems()
    local items = {}
    for _, definition in ipairs(Registry.getEditorDrawFXAll()) do
        local fx_id = definition.id
        table.insert(items, {
            label = definition.name,
            action = function() self:applyDrawFXToSelection(fx_id) end
        })
    end
    return items
end

function Editor:openMapObjectContext(selection, x, y)
    if not self:isMapObjectSelected(selection) then self:selectMapObject(selection) end
    return self.dockspace:openContextMenu({
        { label = "Properties", action = function()
            self.dockspace:setPanelVisible(self.properties_panel, true, self.properties_panel.last_region or "right")
            if self.properties_panel.stack then self.properties_panel.stack:setActivePanel(self.properties_panel) end
        end },
        { label = "Duplicate", action = function() self:duplicateSelectedMapObject() end },
        { label = "Add DrawFX", children = self:getDrawFXMenuItems() },
        { label = "Delete", action = function() self:deleteSelectedMapObject(false) end },
        { label = "Explode", action = function() self:deleteSelectedMapObject(true) end }
    }, x, y, selection.view)
end

function Editor:startObjectReferenceDrag(control)
    if not self.selected_map_object then
        self:addWarning("Select the source object before linking an object-reference property",
            nil, "object_reference")
        return false
    end
    self.object_reference_drag = { control = control, source = self.selected_map_object }
    if self.message_bar then
        self.message_bar:setStatus("Linking object reference: drop onto a target object (Esc to cancel)", 3600)
    end
    return true
end

function Editor:getObjectReferenceLabel(value)
    local source = self.selected_map_object
    local reference = EditorObjectReference.from(value, source and source.map_id)
    local object_name
    for _, document in ipairs(self.map_documents or {}) do
        local selection = document:resolveObjectReference(reference)
        if selection then
            object_name = selection.data.name
            if object_name ~= nil and object_name ~= "" then break end
        end
    end
    if (object_name == nil or object_name == "") and reference.map_id then
        local data = Registry.getMapData(reference.map_id)
        if data then
            MapUtils.walkObjects(data.layers, function(object)
                if object_name == nil and tostring(object.id) == tostring(reference.object_id)
                    and object.name ~= nil and object.name ~= "" then
                    object_name = object.name
                end
            end)
        end
    end
    return reference:getLabel(object_name)
end

function Editor:finishObjectReferenceDrag(x, y)
    local drag = self.object_reference_drag
    self.object_reference_drag = nil
    if not drag then return nil end
    local selection = self:getMapObjectAtScreen(x, y)
    if not selection then
        self:addWarning("Drop the reference link onto an event or shape", nil, "object_reference")
        return nil
    end
    self:clearDiagnostics("object_reference")
    if self.message_bar then self.message_bar:setStatus("Linked object reference") end
    return drag.source.document:createObjectReference(selection)
end

function Editor:getObjectLinkProperties(selection)
    if not selection or not selection.data then return {} end
    local data = selection.data
    data.properties = data.properties or {}
    data.__editor_property_types = data.__editor_property_types or {}
    local event_id = selection.document:getEditorObjectType(data, selection.map_id)
    local success, event = pcall(Registry.createEditorEvent, event_id, data, {
        map_id = selection.map_id
    })
    if not success or not event then return {} end
    local result = {}
    for _, definition in ipairs(event.property_set:getProperties()) do
        if (definition.type == "object_reference" or definition.type == "marker_reference")
            and not definition.unavailable then
            table.insert(result, {
                id = definition.id,
                name = definition.name or StringUtils.titleCase(definition.id:gsub("_", " ")),
                definition = definition,
                property_set = event.property_set
            })
        end
    end
    return result
end

function Editor:startObjectLink(selection, property)
    self.object_link = {
        source = selection,
        property_id = property.id,
        property_name = property.name,
        property_set = property.property_set
    }
    self:selectMapObject(selection)
    self:clearDiagnostics("object_link")
    if self.message_bar then
        self.message_bar:setStatus("Linking " .. property.name .. ": click a target object (Esc to cancel)", 3600)
    end
    return true
end

function Editor:chooseObjectLink(selection, x, y)
    local properties = self:getObjectLinkProperties(selection)
    if #properties == 0 then
        self:addWarning("This object has no object-reference properties to link", nil, "object_link")
        return false
    end
    if #properties == 1 then return self:startObjectLink(selection, properties[1]) end
    local items = {}
    for _, property in ipairs(properties) do
        local choice = property
        table.insert(items, {
            label = choice.name,
            action = function() self:startObjectLink(selection, choice) end
        })
    end
    self:selectMapObject(selection)
    if self.message_bar then self.message_bar:setStatus("Choose which reference property to link") end
    return self.dockspace:openContextMenu(items, x, y, selection.view)
end

function Editor:finishObjectLink(target)
    local link = self.object_link
    if not link then return false end
    if not target then
        if self.message_bar then
            self.message_bar:setStatus("Linking " .. link.property_name .. ": click a target object (Esc to cancel)", 3600)
        end
        return true
    end
    if target.document == link.source.document and target.data == link.source.data then
        if self.message_bar then self.message_bar:setStatus("The source cannot link to itself", 2.5) end
        return true
    end
    local reference = link.source.document:createObjectReference(target)
    local changed = self:performHistoryEdit("Link " .. link.property_name, link.source.document, function()
        if not link.property_set:setValue(link.property_id, reference) then return false end
        link.source.document:invalidatePreview(link.source.map_id)
        return true
    end)
    if not changed then return false end
    self.object_link = nil
    self:selectMapObject(link.source)
    self:clearDiagnostics("object_link")
    if self.message_bar then self.message_bar:setStatus("Linked " .. link.property_name) end
    return true
end

function Editor:cancelObjectLink(silent)
    if not self.object_link then return false end
    self.object_link = nil
    if not silent and self.message_bar then self.message_bar:setStatus("Object link cancelled") end
    return true
end

function Editor:recordGameError(phase, trace)
    if self.game_faulted then return end
    self.game_faulted = true
    self.game_fault_trace = trace
    Game.lock_movement = true
    local summary = trace:match("([^\n]+)") or "Unknown game error"
    self:addError(string.format("Game preview %s failed; preview paused: %s", phase, summary), trace, "game")
    print(string.format("Editor caught a game preview %s error:\n%s", phase, trace))
    self:syncEditingMusic()
end

function Editor:runGameCallback(phase, callback)
    if self.game_faulted then return false end
    local success, result = xpcall(callback, ErrorUtils.traceback)
    if not success then
        self:recordGameError(phase, result)
        return false
    end
    return true, result
end

function Editor:runGameDraw(phase, callback)
    if self.game_faulted then return false end

    local original_canvas = love.graphics.getCanvas()
    local original_scale_x, original_scale_y = CURRENT_SCALE_X, CURRENT_SCALE_Y
    local draw_state = {
        canvas_stack = TableUtils.copy(Draw._canvas_stack),
        scissor_stack = TableUtils.copy(Draw._scissor_stack),
        shader_stack = TableUtils.copy(Draw._shader_stack),
        locked_canvas = TableUtils.copy(Draw._locked_canvas),
        locked_canvas_stack = TableUtils.copy(Draw._locked_canvas_stack)
    }
    local original_push, original_pop = love.graphics.push, love.graphics.pop
    local graphics_depth = 0

    original_push("all")
    graphics_depth = 1
    love.graphics.push = function(...)
        original_push(...)
        graphics_depth = graphics_depth + 1
    end
    love.graphics.pop = function(...)
        original_pop(...)
        graphics_depth = graphics_depth - 1
    end

    local success, result = xpcall(callback, ErrorUtils.traceback)
    love.graphics.push, love.graphics.pop = original_push, original_pop

    local draw_stacks_balanced = #Draw._canvas_stack == #draw_state.canvas_stack
        and #Draw._shader_stack == #draw_state.shader_stack
        and #Draw._locked_canvas_stack == #draw_state.locked_canvas_stack
    if success and (graphics_depth ~= 1 or not draw_stacks_balanced) then
        success = false
        result = ErrorUtils.traceback(string.format(
            "Game preview draw left graphics state unbalanced (graphics %d, canvas %d/%d, scissor %d/%d, shader %d/%d, locks %d/%d)",
            graphics_depth, #Draw._canvas_stack, #draw_state.canvas_stack,
            #Draw._scissor_stack, #draw_state.scissor_stack,
            #Draw._shader_stack, #draw_state.shader_stack,
            #Draw._locked_canvas_stack, #draw_state.locked_canvas_stack))
    end

    while graphics_depth > 0 do
        local popped = pcall(original_pop)
        if not popped then break end
        graphics_depth = graphics_depth - 1
    end

    if not success then
        Draw._canvas_stack = draw_state.canvas_stack
        Draw._scissor_stack = draw_state.scissor_stack
        Draw._shader_stack = draw_state.shader_stack
        Draw._locked_canvas = draw_state.locked_canvas
        Draw._locked_canvas_stack = draw_state.locked_canvas_stack
        Draw.setCanvas(original_canvas)
        CURRENT_SCALE_X, CURRENT_SCALE_Y = original_scale_x, original_scale_y
        self:recordGameError(phase, result)
        return false
    end
    return true, result
end

function Editor:getGameCanvasScreenCenter()
    if not self.game_preview then
        local window_x, window_y = love.window.getPosition()
        local width, height = love.graphics.getDimensions()
        return window_x + fromPixels(width / 2), window_y + fromPixels(height / 2)
    end
    local window_x, window_y = love.window.getPosition()
    local game_x, game_y = self.game_preview:getGlobalPosition()
    local canvas_center_x, canvas_center_y = self.game_preview:getCanvasDisplayCenter()
    local ui_scale = self:getUIScale()
    return window_x + fromPixels((game_x + canvas_center_x) * ui_scale),
        window_y + fromPixels((game_y + canvas_center_y) * ui_scale)
end

function Editor:positionGameCanvasAtScreen(screen_x, screen_y)
    local window_x, window_y = love.window.getPosition()
    local game_x, game_y = self.game_preview:getGlobalPosition()
    local ui_scale = self:getUIScale()
    local canvas_x = toPixels(screen_x - window_x) / ui_scale
        - game_x - SCREEN_WIDTH * self.game_preview.view_zoom / 2
    local canvas_y = toPixels(screen_y - window_y) / ui_scale
        - game_y - SCREEN_HEIGHT * self.game_preview.view_zoom / 2
    self.game_preview:setCanvasPosition(canvas_x, canvas_y)
end

function Editor:centerWindow(display, desktop_width, desktop_height)
    local window_width, window_height = love.window.getMode()
    local desktop_window_width = fromPixels(desktop_width)
    local desktop_window_height = fromPixels(desktop_height)
    love.window.setPosition(
        MathUtils.round((desktop_window_width - window_width) / 2),
        MathUtils.round((desktop_window_height - window_height) / 2),
        display
    )
end

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
    love.graphics.pop()
    local mouse_x, mouse_y = self:getMousePosition()
    self.editor_cursor:setType(self:getCursorType(mouse_x, mouse_y))
end

function Editor:getCursorType(x, y)
    if self.entry_transition or self.exit_transition then return "cannot" end
    if self.creation_dialog then return self.creation_dialog:getCursorType(x, y) end
    if self.message_bar:containsPoint(x, y) then return "select" end
    local menu_cursor = self.menu_bar:getCursorType(x, y)
    if menu_cursor ~= "default" then return menu_cursor end
    return self.dockspace:getCursorType(x, y)
end

function Editor:openCreationDialog(options)
    if self.creation_dialog then self:closeCreationDialog(false) end
    self.dockspace.context_menu = nil
    self.dockspace:setFocus(nil)
    self.creation_dialog = EditorCreationDialog(self, options or {})
    self.creation_dialog:update(0)
    return self.creation_dialog
end

function Editor:closeCreationDialog(created)
    local dialog = self.creation_dialog
    if not dialog then return false end
    dialog:setFocus(nil)
    self.creation_dialog = nil
    if self.message_bar and created then self.message_bar:setStatus("Created " .. (dialog.template.name or "item"), 4) end
    return true
end

function Editor:setTileEditingMode(enabled)
    if enabled then
        if not self.active_document then return false end
        self.tile_editing_mode = true
        if self:isStandaloneGamePreviewEnabled() then
            local panel = self.active_document.panel
            panel:setContent(self.active_document.map_view)
            if panel.stack then panel.stack:setActivePanel(panel) end
            self.dockspace:setFocus(self.active_document.map_view)
            return true
        end
        self:detachGamePreview()
        self:suspendGamePreviewAudio()
        local panel = self.active_document.panel
        if panel and not panel.visible then
            self.dockspace:setPanelVisible(panel, true, panel.last_region or "center")
        end
        if panel and panel.stack then panel.stack:setActivePanel(panel) end
        self.dockspace:setFocus(self.active_document.map_view)
        return true
    end
    local previous_mode = self.tile_editing_mode
    self.tile_editing_mode = false
    local success = self:showGamePreview({ reload_runtime = true })
    if not success then self.tile_editing_mode = previous_mode end
    return success
end

function Editor:detachGamePreview()
    local document = self.live_document
    if not document then return false end
    if self.game_preview_paused then
        self.game_preview_movement_lock = self.game_preview_lock_before_pause == true
    else
        self.game_preview_movement_lock = Game.lock_movement
    end
    self.game_preview_lock_before_pause = nil
    self:clearGameObjectSelection()
    document.game_view_state = self:captureGameViewState(document)
    self:suspendGamePreviewAudio(true)
    if document.panel and document.panel.content == self.game_preview then
        document.panel:setContent(document.map_view)
    end
    self.live_document = nil
    self.game_panel = nil
    Game.lock_movement = true
    self.dockspace:layout()
    self:syncEditingMusic()
    return true
end

function Editor:isStandaloneGamePreviewEnabled()
    return self.game_preview_panel and self.game_preview_panel.visible == true
end

function Editor:getGamePreviewOwnerPanel()
    if self:isStandaloneGamePreviewEnabled() then return self.game_preview_panel end
    return self.live_document and self.live_document.panel or nil
end

function Editor:setGamePreviewPaused(paused)
    if not self.live_document then return false end
    paused = paused == true
    local owner = self:getGamePreviewOwnerPanel()
    if not paused and owner and not self.dockspace:isPanelDisplayed(owner) then return false end
    if paused == self.game_preview_paused then return true end
    if paused then
        self.game_preview_lock_before_pause = Game.lock_movement
        self.game_preview_movement_lock = Game.lock_movement
    end
    self.game_preview_paused = paused
    self:clearForwardedGameMouse()
    if self.game_preview_paused then
        self:suspendGamePreviewAudio(true)
    else
        self:resumeGamePreviewAudio()
    end
    if self.game_preview_paused then
        Game.lock_movement = true
    else
        Game.lock_movement = self.game_preview_lock_before_pause == true
        self.game_preview_movement_lock = Game.lock_movement
        self.game_preview_lock_before_pause = nil
    end
    self:syncEditingMusic()
    return true
end

function Editor:toggleGamePreviewPaused()
    return self:setGamePreviewPaused(not self.game_preview_paused)
end

function Editor:setStandaloneGamePreviewMap(id, options)
    options = options or {}
    if not self:isStandaloneGamePreviewEnabled() or not hasMap(id) then return false end
    if self.game_panel == self.game_preview_panel and self.live_document == self.standalone_preview_document
        and self.standalone_preview_map_id == id and not self.stale_runtime_maps[id]
        and not options.reload_runtime then
        self.dockspace:setFocus(self.game_preview)
        return true
    end
    local was_paused = self.game_preview_paused
    if self.live_document then self:detachGamePreview() end
    if not self:restoreGamePreviewSnapshot() then return false end
    self.standalone_preview_map_id = id
    self.standalone_preview_document = EditorMapDocument(self, id)
    self.game_preview:setDocument(self.standalone_preview_document)
    self.game_preview.canvas_positioned = false
    if (options.reload_runtime or id ~= self.map_id or self.stale_runtime_maps[id])
        and not self:loadRuntimeMap(id) then return false end
    if not self:captureGamePreviewSnapshot(self.standalone_preview_document) then return false end
    self.game_preview_panel:setContent(self.game_preview)
    self.live_document = self.standalone_preview_document
    self.game_panel = self.game_preview_panel
    self:activateGameObjectSelection()
    self.game_preview_paused = was_paused
    if was_paused then
        self.game_preview_lock_before_pause = self.game_preview_movement_lock
        self:suspendGamePreviewAudio()
    else
        self:resumeGamePreviewAudio()
    end
    Game.lock_movement = was_paused and true or self.game_preview_movement_lock
    self.dockspace:layout()
    self.dockspace:setFocus(self.game_preview)
    self:syncEditingMusic()
    return true
end

function Editor:setStandaloneGamePreviewEnabled(enabled)
    if enabled then
        local id = self.standalone_preview_map_id
            or (self.active_document and self.active_document.primary_map_id)
        if not id then return false end
        return self:setStandaloneGamePreviewMap(id)
    end
    if self.game_panel == self.game_preview_panel then self:detachGamePreview() end
    if not self.tile_editing_mode and self.active_document then
        return self:showGamePreview({ document = self.active_document, ignore_standalone = true })
    end
    return true
end

function Editor:closeGamePreviewFromGameMenu()
    if not self:isGamePreviewMounted() then return false end
    local owner = self:getGamePreviewOwnerPanel()
    local standalone = owner == self.game_preview_panel

    self:setGamePreviewPaused(true)
    self.tile_editing_mode = true
    self:detachGamePreview()
    self:suspendGamePreviewAudio(true)

    if standalone and self.game_preview_panel.visible then
        self.dockspace:setPanelVisible(self.game_preview_panel, false)
    end
    if self.active_document and self.active_document.panel then
        local panel = self.active_document.panel
        panel:setContent(self.active_document.map_view)
        if panel.stack then panel.stack:setActivePanel(panel) end
        self.dockspace:setFocus(self.active_document.map_view)
    end

    self:syncEditingMusic()
    return true
end

function Editor:captureGamePreviewSnapshot(document)
    if self.game_preview_snapshot and self.game_preview_snapshot_document == document then return true end
    local success, snapshot = self:runGameCallback("snapshot", function()
        local player = Game.world and Game.world.player
        local position = player and { player.x, player.y } or nil
        local data = Game:save(position)
        if player then data.spawn_facing = player:getFacing() end
        return TableUtils.copy(data, true)
    end)
    if not success then return false end
    self.game_preview_snapshot = snapshot
    self.game_preview_snapshot_document = document
    self.game_preview_snapshot_save_id = Game.save_id
    return true
end

function Editor:restoreGamePreviewSnapshot()
    local snapshot = self.game_preview_snapshot
    if not snapshot then return true end
    self:clearForwardedGameMouse()
    local save_id = self.game_preview_snapshot_save_id
    self.game_preview_snapshot = nil
    self.game_preview_snapshot_document = nil
    self.game_preview_snapshot_save_id = nil
    local success = self:runGameCallback("reset", function()
        Game:load(TableUtils.copy(snapshot, true), save_id, false)
    end)
    if success then
        self.map_id = snapshot.room_id
        self.game_music_suspended_by_editor = false
    end
    return success
end

function Editor:getGamePreviewMusic()
    local success, music = pcall(function() return Game:getActiveMusic() end)
    if success then return music end
end

function Editor:suspendGamePreviewAudio(stop_sounds)
    if stop_sounds then Assets.stopAllSounds() end
    local music = self:getGamePreviewMusic()
    if music and music:isPlaying() then
        music:pause()
        self.game_music_suspended_by_editor = true
    end
end

function Editor:resumeGamePreviewAudio()
    if not self.game_music_suspended_by_editor then return end
    local music = self:getGamePreviewMusic()
    if music and music:canResume() then music:resume() end
    self.game_music_suspended_by_editor = false
end

function Editor:clearForwardedGameMouse()
    for button, forwarded in pairs(self.forwarded_mouse_buttons or {}) do
        if forwarded then Input.onMouseReleased(0, 0, button, false, 0) end
    end
    self.forwarded_mouse_buttons = {}
end

function Editor:applyGameViewState(document)
    local state = document.game_view_state
    if state and type(state.zoom) == "number" then
        self.game_preview.view_zoom = MathUtils.clamp(state.zoom,
            self.game_preview.minimum_zoom, self.game_preview.maximum_zoom)
    else
        self.game_preview.view_zoom = 1
    end
    if state and type(state.canvas_x) == "number" and type(state.canvas_y) == "number" then
        self.game_preview:setCanvasPosition(state.canvas_x, state.canvas_y)
    else
        self.game_preview.canvas_positioned = false
    end
end

function Editor:loadRuntimeMap(id)
    if not id or not Registry.getMap(id) and not Registry.getMapData(id) then return false end
    if not Game.world then return false end
    Game.state = "OVERWORLD"
    Game.world:loadMap(id)
    self.map_id = id
    self.stale_runtime_maps[id] = nil
    return true
end

function Editor:openMap(id)
    if not hasMap(id) then return false end
    local document = self:findMapDocument(id)
    if not document then document = self:createMapDocument(id) end
    return document and self:activateMapDocument(document) or false
end

function Editor:findMapDocument(id)
    for _, document in ipairs(self.map_documents or {}) do
        if not document.editor_world and document.primary_map_id == id then return document end
    end
end

function Editor:findWorldDocument(id)
    for _, document in ipairs(self.map_documents or {}) do
        if document.editor_world and document.world and document.world.id == id then return document end
    end
end

function Editor:openWorld(world)
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

function Editor:activateMapDocument(document, options)
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

function Editor:showGamePreview(options)
    options = options or {}
    if self:isStandaloneGamePreviewEnabled() and not options.ignore_standalone then
        local id = self.standalone_preview_map_id
            or (self.active_document and self.active_document.primary_map_id)
        if self.game_panel ~= self.game_preview_panel or self.stale_runtime_maps[id]
            or options.reload_runtime then
            return self:setStandaloneGamePreviewMap(id, options)
        end
        self.dockspace:setFocus(self.game_preview)
        return true
    end
    local document = options.document or self.active_document
    if not document then return false end
    local was_paused = self.game_preview_paused ~= false
    if self.live_document ~= document then
        self:detachGamePreview()
        if not self:restoreGamePreviewSnapshot() then return false end
        self:applyGameViewState(document)
    end
    self.active_document = document
    self.game_preview:setDocument(document)
    if (options.reload_runtime or document.primary_map_id ~= self.map_id
        or self.stale_runtime_maps[document.primary_map_id])
        and not self:loadRuntimeMap(document.primary_map_id) then
        return false
    end
    if not self:captureGamePreviewSnapshot(document) then return false end
    self.tile_editing_mode = false
    self.game_preview_paused = was_paused
    if was_paused then self:suspendGamePreviewAudio() else self:resumeGamePreviewAudio() end
    Game.lock_movement = was_paused and true or self.game_preview_movement_lock
    local panel = document.panel
    if not panel.visible then
        self.dockspace:setPanelVisible(panel, true, panel.last_region or "center")
    end
    panel:setContent(self.game_preview)
    self.live_document = document
    self.game_panel = panel
    self:activateGameObjectSelection()
    self.dockspace:layout()
    if options.select_panel ~= false and panel.stack then panel.stack:setActivePanel(panel) end
    self.dockspace:setFocus(self.game_preview)
    self:syncEditingMusic()
    return true
end

function Editor:openMapTab(id, dock_target)
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
        self.dockspace:dockPanel(document.panel, dock_target.stack)
    end
    return self:activateMapDocument(document)
end

function Editor:isMapTabDropTarget(x, y)
    return self:getMapPanelDropTarget(x, y) ~= nil
end

function Editor:getMapPanelDropTarget(x, y)
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

function Editor:addMapToView(id, x, y, document)
    document = document or self.active_document
    return document and document:addMap(id, x, y) or nil
end

function Editor:addMapToWorld(world, map_id)
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

function Editor:removeMapFromView(id, document)
    document = document or self.active_document
    return document and document:removeMap(id) or false
end

function Editor:removeMapDocument(document)
    local remove_index
    for index, candidate in ipairs(self.map_documents) do
        if candidate == document then remove_index = index break end
    end
    if not remove_index then return false end
    if document:isDirty() and not document.discard_close_confirmed then
        document.discard_close_confirmed = true
        self:addWarning("Closing this map tab would discard unsaved changes",
            "Use File > Save Active Document first, or close the tab again to discard its current working changes.",
            "unsaved_close:" .. document.panel.id)
        return false
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

function Editor:isGamePreviewMounted()
    local owner = self:getGamePreviewOwnerPanel()
    return not self.game_faulted
        and (self:isStandaloneGamePreviewEnabled() or not self.tile_editing_mode)
        and self.live_document ~= nil
        and self.game_preview ~= nil
        and owner ~= nil
        and owner.content == self.game_preview
        and self.source_state ~= nil
end


function Editor:isGamePreviewInputActive()
    local owner = self:getGamePreviewOwnerPanel()
    return not self.game_preview_paused and self:isGamePreviewMounted()
        and self.dockspace:isPanelDisplayed(owner)
end

function Editor:canForwardGameKeyboardInput()
    if not self:isGamePreviewInputActive() then return false end
    local focused = self.dockspace.focused_control
    return not (focused and focused.accepts_text_input)
end

function Editor:getGamePreviewPosition(x, y, allow_outside)
    if not self:isGamePreviewMounted() then return nil end
    local owner = self:getGamePreviewOwnerPanel()
    if not self.dockspace:isPanelDisplayed(owner) then return nil end
    local view_x, view_y = self.game_preview:getGlobalPosition()
    local zoom = self.game_preview.view_zoom
    local game_x = (x - view_x - self.game_preview.canvas_x) / zoom
    local game_y = (y - view_y - self.game_preview.canvas_y) / zoom
    if not allow_outside
        and (game_x < 0 or game_y < 0 or game_x >= SCREEN_WIDTH or game_y >= SCREEN_HEIGHT) then
        return nil
    end
    return math.floor(game_x), math.floor(game_y)
end

function Editor:getGameInputPosition(x, y, allow_outside)
    if not self:isGamePreviewInputActive() then return nil end
    return self:getGamePreviewPosition(x, y, allow_outside)
end

function Editor:activateGameObjectSelection()
    local debug_system = Kristal.DebugSystem
    if not debug_system then return false end
    debug_system:setSelectionEnvironment(self,
        function() return Game.stage end,
        function() return self.object_selection_cursor_x or 0, self.object_selection_cursor_y or 0 end)
    local mouse_x, mouse_y = self:getMousePosition()
    self:updateGameObjectSelectionCursor(mouse_x, mouse_y)
    return true
end

function Editor:clearGameObjectSelection()
    local debug_system = Kristal.DebugSystem
    if not debug_system or debug_system.selection_environment_owner ~= self then return false end
    if debug_system.context then debug_system.context:close() end
    debug_system:unselectObject()
    self:clearPropertiesTarget(self)
    debug_system:clearSelectionEnvironment(self)
    self.object_selection_cursor_x = nil
    self.object_selection_cursor_y = nil
    self.object_selection_mouse_buttons = {}
    return true
end

function Editor:getGameObjectPropertiesTarget(object)
    local function numberField(label, key)
        return EditorPropertyFields.number(object, label, key, {
            on_invalid = function()
                self:addWarning(label .. " must be a number", nil, "object_property")
            end,
            on_set = function(value)
                if object.data then object.data[key] = value end
                self:clearDiagnostics("object_property")
            end
        })
    end
    local data = object.data
    if data then
        data.properties = data.properties or {}
    else
        object.editor_properties = object.editor_properties or {}
        object.editor_property_types = object.editor_property_types or {}
    end
    if data then data.__editor_property_types = data.__editor_property_types or {} end
    local event_id
    if data then
        event_id = data.type
        local map = Game.world and Game.world.map
        if map and map.reader:isLegacyFormat() and (event_id == nil or event_id == "") then
            event_id = data.class
            if event_id == nil or event_id == "" then event_id = data.name end
        end
    end
    local property_set
    if event_id then
        local success, editor_event = pcall(Registry.createEditorEvent, event_id, data, {})
        if success and editor_event then property_set = editor_event.property_set end
    end
    property_set = property_set or EditorPropertySet(
        data and data.properties or object.editor_properties,
        data and data.__editor_property_types or object.editor_property_types)
    return {
        title = ClassUtils.getClassName(object) or "Game Object",
        fields = {
            numberField("X", "x"),
            numberField("Y", "y"),
            numberField("Width", "width"),
            numberField("Height", "height"),
            numberField("Layer", "layer")
        },
        properties = data and data.properties or object.editor_properties,
        property_types = data and data.__editor_property_types or object.editor_property_types,
        property_set = property_set,
        on_changed = function()
            self:addWarning("Game object property changes affect only the current preview",
                nil, "object_property_preview")
        end
    }
end

function Editor:isGameObjectSelectionActive()
    return Kristal.DebugSystem
        and Kristal.DebugSystem.selection_environment_owner == self
        and self:isGamePreviewMounted()
end

function Editor:updateGameObjectSelectionCursor(x, y)
    if not self:isGameObjectSelectionActive() then return false end
    local game_x, game_y = self:getGamePreviewPosition(x, y, true)
    if not game_x then return false end
    self.object_selection_cursor_x = game_x
    self.object_selection_cursor_y = game_y
    return true
end

function Editor:getGameObjectAtCursor()
    if not self:isGameObjectSelectionActive() then return nil end
    local x, y = self.object_selection_cursor_x, self.object_selection_cursor_y
    if not x then return nil end
    return Kristal.DebugSystem:detectObject(x, y)
end

function Editor:handleGameObjectSelectionMousePressed(x, y, button, istouch, presses)
    if button ~= 1 and button ~= 2 or not self:isGameObjectSelectionActive() then return false end
    self:updateGameObjectSelectionCursor(x, y)
    local debug_system = Kristal.DebugSystem
    local game_x, game_y = self:getGamePreviewPosition(x, y, true)
    if not game_x then return false end

    if debug_system.context
        and debug_system.context:onMousePressed(game_x, game_y, button, istouch, presses) then
        self.object_selection_mouse_buttons[button] = true
        return true
    end

    local object = debug_system:detectObject(game_x, game_y)
    if object then
        debug_system:selectObject(object)
        self:setPropertiesTarget(self:getGameObjectPropertiesTarget(object), self)
        if button == 1 then
            debug_system.grabbing = true
            local screen_x, screen_y = object:getScreenPos()
            debug_system.grab_offset_x = game_x - screen_x
            debug_system.grab_offset_y = game_y - screen_y
        else
            debug_system:openObjectContext(object)
        end
    else
        debug_system:unselectObject()
        self:clearPropertiesTarget(self)
    end
    self.object_selection_mouse_buttons[button] = true
    return true
end

function Editor:handleGameObjectSelectionMouseReleased(x, y, button, istouch, presses)
    if button ~= 1 and button ~= 2 or not self:isGameObjectSelectionActive() then return false end
    if not self.object_selection_mouse_buttons[button] then return false end
    self.object_selection_mouse_buttons[button] = nil
    self:updateGameObjectSelectionCursor(x, y)
    local debug_system = Kristal.DebugSystem
    local game_x, game_y = self:getGamePreviewPosition(x, y, true)
    if game_x then debug_system:onMouseReleased(game_x, game_y, button, istouch, presses) end
    return true
end

function Editor:hasForwardedMouseButton()
    for _, forwarded in pairs(self.forwarded_mouse_buttons) do
        if forwarded then return true end
    end
    return false
end

function Editor:forwardGameKeyPressed(key, is_repeat)
    if not self:canForwardGameKeyboardInput() or not self.source_state.onKeyPressed then return false end
    self:runGameCallback("input", function() self.source_state:onKeyPressed(key, is_repeat) end)
    return true
end

function Editor:forwardGameKeyReleased(key)
    if not self:canForwardGameKeyboardInput() or not self.source_state.onKeyReleased then return false end
    self:runGameCallback("input", function() self.source_state:onKeyReleased(key) end)
    return true
end

function Editor:forwardGameTextInput(text)
    if not self:canForwardGameKeyboardInput() then return false end
    self:runGameCallback("text input", function()
        if self.source_state.onTextInput then self.source_state:onTextInput(text) end
        TextInput.onTextInput(text)
        Kristal.callEvent(KRISTAL_EVENT.onTextInput, text)
    end)
    return true
end

function Editor:forwardGameMousePressed(x, y, button, istouch, presses)
    local game_x, game_y = self:getGameInputPosition(x, y)
    if not game_x then return false end
    self.forwarded_mouse_buttons[button] = true
    self:runGameCallback("mouse input", function()
        Input.onMousePressed(game_x, game_y, button, istouch, presses)
        Kristal.callEvent(KRISTAL_EVENT.onMousePressed, game_x, game_y, button, istouch, presses)
    end)
    return true
end

function Editor:forwardGameMouseMoved(x, y, dx, dy, istouch)
    local game_x, game_y = self:getGameInputPosition(x, y, self:hasForwardedMouseButton())
    if not game_x then return false end
    local zoom = self.game_preview.view_zoom
    local game_dx, game_dy = MathUtils.round(dx / zoom), MathUtils.round(dy / zoom)
    self:runGameCallback("mouse input", function()
        Input.onMouseMoved(game_x, game_y, game_dx, game_dy, istouch)
        Kristal.callEvent(KRISTAL_EVENT.onMouseMoved, game_x, game_y, game_dx, game_dy, istouch)
    end)
    return true
end

function Editor:forwardGameMouseReleased(x, y, button, istouch, presses)
    if not self.forwarded_mouse_buttons[button] then return false end
    local game_x, game_y = self:getGameInputPosition(x, y, true)
    self.forwarded_mouse_buttons[button] = nil
    if not game_x then return false end
    self:runGameCallback("mouse input", function()
        Input.onMouseReleased(game_x, game_y, button, istouch, presses)
        Kristal.callEvent(KRISTAL_EVENT.onMouseReleased, game_x, game_y, button, istouch, presses)
    end)
    return true
end

function Editor:onKeyPressed(key, is_repeat)
    if self.entry_transition or self.exit_transition then return true end
    if self.creation_dialog then return self.creation_dialog:onKeyPressed(key, is_repeat) end
    if self.dockspace.context_menu and self.dockspace.context_menu.searchable then
        return self.dockspace:onKeyPressed(key, is_repeat) ~= false
    end
    if self.settings_browser and self.settings_browser:isCapturingKeybind() then
        return self.dockspace:onKeyPressed(key, is_repeat) ~= false
    end
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
    if Input.ctrl() and not is_repeat
        and not editing_text then
        if key == "s" then
            if Input.shift() then return self:saveAllDocuments() end
            return self:saveActiveDocument()
        end
        if key == "z" then return Input.shift() and self:redo() or self:undo() end
        if key == "y" then return self:redo() end
    end
    if not is_repeat and not editing_text and self.tile_editing_mode then
        if Input.is("editor_delete", key) then
            self.consumed_editor_keys[key] = true
            Input.clear("editor_delete")
            self:deleteSelectedMapObject(false)
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
    if key == "escape" and (self.asset_drag or self.object_reference_drag or self.object_link or self.drag_preview) then
        local cancelled_link = self:cancelObjectLink()
        self.asset_drag, self.object_reference_drag, self.drag_preview = nil, nil, nil
        if not cancelled_link and self.message_bar then self.message_bar:setStatus("Drag cancelled") end
        return true
    end
    if key == "escape" and (self.placement_event_id or self.placement_tile)
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
    if self:hasUnsavedChanges() and not self.discard_changes_confirmed then
        self.discard_changes_confirmed = true
        self:addWarning("Unsaved editor changes have not been written",
            "Use File > Save All to write them, or trigger exit again to discard the current working changes.",
            "unsaved_exit")
        return false
    end
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
        return_to_menu = return_to_menu
    })
end

function Editor:onKeyReleased(key)
    if self.entry_transition or self.exit_transition then return true end
    if self.creation_dialog then return self.creation_dialog:onKeyReleased(key) end
    if self.consumed_editor_keys[key] then
        self.consumed_editor_keys[key] = nil
        return true
    end
    if self.dockspace:onKeyReleased(key) then return true end
    return self:forwardGameKeyReleased(key)
end

function Editor:onTextInput(text)
    if self.entry_transition or self.exit_transition then return true end
    if self.creation_dialog then return self.creation_dialog:onTextInput(text) end
    if self.dockspace:onTextInput(text) then return true end
    return self:forwardGameTextInput(text)
end

function Editor:onMousePressed(x, y, button, istouch, presses)
    if self.entry_transition or self.exit_transition then return true end
    x, y = self:screenToUI(x, y)
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
    if self.creation_dialog then return self.creation_dialog:onMouseReleased(x, y, button, istouch, presses) end
    if self.dockspace:onMouseReleased(x, y, button, presses) then return true end
    if self:handleGameObjectSelectionMouseReleased(x, y, button, istouch, presses) then return true end
    return self:forwardGameMouseReleased(x, y, button, istouch, presses)
end

function Editor:onWheelMoved(x, y)
    if self.entry_transition or self.exit_transition then return true end
    if self.creation_dialog then return self.creation_dialog:onWheelMoved(x, y) end
    local mouse_x, mouse_y = self:getMousePosition()
    if self.message_bar:containsPoint(mouse_x, mouse_y) then return true end
    return self.dockspace:onWheelMoved(x, y)
end

function Editor:captureLayout()
    return self.dockspace:captureLayout()
end

function Editor:resetPanelLayout()
    if not self.default_layout then return false end
    local layout = TableUtils.copy(self.default_layout, true)
    local center = layout.regions.center
    center.stacks = center.stacks or {}
    if not center.stacks[1] then
        center.stacks[1] = { id = "center", panels = {} }
    end
    local center_stack = center.stacks[1]
    layout.panels = layout.panels or {}
    for _, document in ipairs(self.map_documents or {}) do
        local panel = document.panel
        if not layout.panels[panel.id] then
            layout.panels[panel.id] = { visible = true, last_region = "center" }
            table.insert(center_stack.panels, panel.id)
        end
    end
    if self.active_document then center_stack.active = self.active_document.panel.id end
    self:restoreLayout(layout)
    return true
end

function Editor:restoreLayout(layout)
    self.dockspace:restoreLayout(layout)
end

return Editor
