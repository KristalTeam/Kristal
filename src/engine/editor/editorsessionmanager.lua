---@class EditorSessionManager : Class
---@field editor Editor
---@overload fun(editor: Editor): EditorSessionManager
local EditorSessionManager = Class()

function EditorSessionManager:init(editor)
    self.editor = editor
end

local EDITOR_SESSION_VERSION = 6
local EDITOR_SESSION_DIRECTORY = "editor"

local function safeProjectId(id)
    return tostring(id or "unknown"):gsub("[^%w%._%-]", "_")
end

function EditorSessionManager:getSessionPath()
    local self = self.editor
    return EDITOR_SESSION_DIRECTORY .. "/" .. safeProjectId(self.project_id) .. ".json"
end

function EditorSessionManager:loadSession()
    local self = self.editor
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

function EditorSessionManager:restoreDocumentView(document, state)
    local self = self.editor
    if type(state) ~= "table" then return end
    local view = document.game_view
    if type(state.zoom) == "number" then
        view.view_zoom = MathUtils.clamp(state.zoom, view.minimum_zoom, view.maximum_zoom)
    end
    if type(state.canvas_x) == "number" and type(state.canvas_y) == "number" then
        view:setCanvasPosition(state.canvas_x, state.canvas_y)
    end
end

function EditorSessionManager:restoreGameViewState(document, state)
    local self = self.editor
    if type(state) ~= "table" then return end
    document.game_view_state = {
        canvas_x = type(state.canvas_x) == "number" and state.canvas_x or nil,
        canvas_y = type(state.canvas_y) == "number" and state.canvas_y or nil,
        zoom = type(state.zoom) == "number" and state.zoom or nil
    }
end

function EditorSessionManager:captureGameViewState(document)
    local self = self.editor
    if self.live_document == document and self.game_preview then
        return {
            canvas_x = self.game_preview.canvas_x,
            canvas_y = self.game_preview.canvas_y,
            zoom = self.game_preview.view_zoom
        }
    end
    return document.game_view_state and TableUtils.copy(document.game_view_state, true) or nil
end

function EditorSessionManager:captureSession()
    local self = self.editor
    local session = {
        version = EDITOR_SESSION_VERSION,
        project_id = self.project_id,
        tile_editing_mode = self.tile_editing_mode,
        tile_grid = self.show_tile_grid,
        standalone_preview_enabled = self:isStandaloneGamePreviewEnabled(),
        standalone_preview_map_id = self.standalone_preview_map_id,
        active_tileset_id = self.active_tileset_id,
        active_terrain_id = self.selected_terrain_id,
        active_terrain_variant_id = self.selected_terrain_variant_id,
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

function EditorSessionManager:saveSession()
    local self = self.editor
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

function EditorSessionManager:restoreEntryState(session, options, context_document, restored_by_panel, game_center_x, game_center_y)
    local self = self.editor
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
    if self.align_game_transition ~= false and not options.restore_active_document then
        self:positionGameCanvasAtScreen(game_center_x, game_center_y)
    end
    if self.game_preview_panel.visible then self:setStandaloneGamePreviewEnabled(true) end
end

return EditorSessionManager

