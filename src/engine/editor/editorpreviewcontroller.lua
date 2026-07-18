--- Manages the sandboxed game preview and its state.
---@class EditorPreviewController : Class
---@field editor Editor
---@overload fun(editor: Editor): EditorPreviewController
local EditorPreviewController = Class()

function EditorPreviewController:init(editor)
    self.editor = editor
end

function EditorPreviewController:recordGameError(phase, trace)
    local self = self.editor
    if self.game_faulted then return end
    self.game_faulted = true
    self.game_fault_trace = trace
    Game.lock_movement = true
    local summary = trace:match("([^\n]+)") or "Unknown game error"
    self:addError(string.format("Game preview %s failed; preview paused: %s", phase, summary), trace, "game")
    print(string.format("Editor caught a game preview %s error:\n%s", phase, trace))
    self:syncEditingMusic()
end

function EditorPreviewController:runGameCallback(phase, callback)
    local self = self.editor
    if self.game_faulted then return false end
    local success, result = xpcall(callback, ErrorUtils.traceback)
    if not success then
        self:recordGameError(phase, result)
        return false
    end
    return true, result
end

function EditorPreviewController:runGameDraw(phase, callback)
    local self = self.editor
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

function EditorPreviewController:setTileEditingMode(enabled)
    local self = self.editor
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

function EditorPreviewController:detachGamePreview()
    local self = self.editor
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

function EditorPreviewController:isStandaloneGamePreviewEnabled()
    local self = self.editor
    return self.game_preview_panel and self.game_preview_panel.visible == true
end

function EditorPreviewController:getGamePreviewOwnerPanel()
    local self = self.editor
    if self:isStandaloneGamePreviewEnabled() then return self.game_preview_panel end
    return self.live_document and self.live_document.panel or nil
end

function EditorPreviewController:setGamePreviewPaused(paused)
    local self = self.editor
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

function EditorPreviewController:toggleGamePreviewPaused()
    local self = self.editor
    return self:setGamePreviewPaused(not self.game_preview_paused)
end

function EditorPreviewController:setStandaloneGamePreviewMap(id, options)
    local self = self.editor
    options = options or {}
    if not self:isStandaloneGamePreviewEnabled() or not Registry.hasMap(id) then return false end
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

function EditorPreviewController:setStandaloneGamePreviewEnabled(enabled)
    local self = self.editor
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

function EditorPreviewController:closeGamePreviewFromGameMenu()
    local self = self.editor
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

function EditorPreviewController:captureGamePreviewSnapshot(document)
    local self = self.editor
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

function EditorPreviewController:restoreGamePreviewSnapshot()
    local self = self.editor
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

function EditorPreviewController:getGamePreviewMusic()
    local self = self.editor
    local success, music = pcall(function() return Game:getActiveMusic() end)
    if success then return music end
end

function EditorPreviewController:suspendGamePreviewAudio(stop_sounds)
    local self = self.editor
    if stop_sounds then Assets.stopAllSounds() end
    local music = self:getGamePreviewMusic()
    if music and music:isPlaying() then
        music:pause()
        self.game_music_suspended_by_editor = true
    end
end

function EditorPreviewController:resumeGamePreviewAudio()
    local self = self.editor
    if not self.game_music_suspended_by_editor then return end
    local music = self:getGamePreviewMusic()
    if music and music:canResume() then music:resume() end
    self.game_music_suspended_by_editor = false
end

function EditorPreviewController:clearForwardedGameMouse()
    local self = self.editor
    for button, forwarded in pairs(self.forwarded_mouse_buttons or {}) do
        if forwarded then Input.onMouseReleased(0, 0, button, false, 0) end
    end
    self.forwarded_mouse_buttons = {}
end

function EditorPreviewController:applyGameViewState(document)
    local self = self.editor
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

function EditorPreviewController:showGamePreview(options)
    local self = self.editor
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

function EditorPreviewController:isGamePreviewMounted()
    local self = self.editor
    local owner = self:getGamePreviewOwnerPanel()
    return not self.game_faulted
        and (self:isStandaloneGamePreviewEnabled() or not self.tile_editing_mode)
        and self.live_document ~= nil
        and self.game_preview ~= nil
        and owner ~= nil
        and owner.content == self.game_preview
        and self.source_state ~= nil
end

function EditorPreviewController:isGamePreviewInputActive()
    local self = self.editor
    local owner = self:getGamePreviewOwnerPanel()
    return not self.game_preview_paused and self:isGamePreviewMounted()
        and self.dockspace:isPanelDisplayed(owner)
end

function EditorPreviewController:canForwardGameKeyboardInput()
    local self = self.editor
    if not self:isGamePreviewInputActive() then return false end
    local focused = self.dockspace.focused_control
    return not (focused and focused.accepts_text_input)
end

function EditorPreviewController:canUseGameDebugInput()
    local self = self.editor
    if not self:isGamePreviewMounted() then return false end
    local owner = self:getGamePreviewOwnerPanel()
    if not owner or not self.dockspace:isPanelDisplayed(owner) then return false end
    local focused = self.dockspace.focused_control
    return not (focused and focused.accepts_text_input)
end

function EditorPreviewController:isGameDebugOverlayActive()
    local self = self.editor
    return Kristal.DebugSystem and Kristal.DebugSystem.state ~= "IDLE"
end

function EditorPreviewController:handleGameDebugKeyPressed(key, is_repeat)
    local self = self.editor
    local debug_system = Kristal.DebugSystem
    if not debug_system or not self:canUseGameDebugInput() then return false end

    if Kristal.isDevMode() and not TextInput.active and Input.shouldProcess(key)
        and Input.is("debug_menu", key) then
        Input.clear("debug_menu")
        self:runGameCallback("debug menu input", function()
            if debug_system:isMenuOpen() then
                Assets.playSound("ui_move")
                debug_system:closeMenu()
            else
                debug_system:openMenu()
            end
        end)
        return true
    end

    if debug_system.state == "IDLE" then return false end
    self:runGameCallback("debug menu input", function()
        debug_system:onKeyPressed(key, is_repeat)
        if TextInput.active and not is_repeat then TextInput.onKeyPressed(key) end
    end)
    return true
end

function EditorPreviewController:getGamePreviewPosition(x, y, allow_outside)
    local self = self.editor
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

function EditorPreviewController:getGameInputPosition(x, y, allow_outside)
    local self = self.editor
    if not self:isGamePreviewInputActive() then return nil end
    return self:getGamePreviewPosition(x, y, allow_outside)
end

function EditorPreviewController:activateGameObjectSelection()
    local self = self.editor
    local debug_system = Kristal.DebugSystem
    if not debug_system then return false end
    debug_system:setSelectionEnvironment(self,
        function() return Game.stage end,
        function() return self.object_selection_cursor_x or 0, self.object_selection_cursor_y or 0 end)
    local mouse_x, mouse_y = self:getMousePosition()
    self:updateGameObjectSelectionCursor(mouse_x, mouse_y)
    return true
end

function EditorPreviewController:clearGameObjectSelection()
    local self = self.editor
    local debug_system = Kristal.DebugSystem
    if not debug_system or debug_system.selection_environment_owner ~= self then return false end
    if debug_system.state ~= "IDLE" then debug_system:closeMenu() end
    if debug_system.context then debug_system.context:close() end
    debug_system:unselectObject()
    self:clearPropertiesTarget(self)
    debug_system:clearSelectionEnvironment(self)
    self.object_selection_cursor_x = nil
    self.object_selection_cursor_y = nil
    self.object_selection_mouse_buttons = {}
    return true
end

function EditorPreviewController:getGameObjectPropertiesTarget(object)
    local self = self.editor
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

function EditorPreviewController:isGameObjectSelectionActive()
    local self = self.editor
    return Kristal.DebugSystem
        and Kristal.DebugSystem.selection_environment_owner == self
        and self:isGamePreviewMounted()
end

function EditorPreviewController:updateGameObjectSelectionCursor(x, y)
    local self = self.editor
    if not self:isGameObjectSelectionActive() then return false end
    local game_x, game_y = self:getGamePreviewPosition(x, y, true)
    if not game_x then return false end
    self.object_selection_cursor_x = game_x
    self.object_selection_cursor_y = game_y
    return true
end

function EditorPreviewController:getGameObjectAtCursor()
    local self = self.editor
    if not self:isGameObjectSelectionActive() then return nil end
    local x, y = self.object_selection_cursor_x, self.object_selection_cursor_y
    if not x then return nil end
    return Kristal.DebugSystem:detectObject(x, y)
end

function EditorPreviewController:handleGameObjectSelectionMousePressed(x, y, button, istouch, presses)
    local self = self.editor
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

function EditorPreviewController:handleGameObjectSelectionMouseReleased(x, y, button, istouch, presses)
    local self = self.editor
    if button ~= 1 and button ~= 2 or not self:isGameObjectSelectionActive() then return false end
    if not self.object_selection_mouse_buttons[button] then return false end
    self.object_selection_mouse_buttons[button] = nil
    self:updateGameObjectSelectionCursor(x, y)
    local debug_system = Kristal.DebugSystem
    local game_x, game_y = self:getGamePreviewPosition(x, y, true)
    if game_x then debug_system:onMouseReleased(game_x, game_y, button, istouch, presses) end
    return true
end

function EditorPreviewController:hasForwardedMouseButton()
    local self = self.editor
    for _, forwarded in pairs(self.forwarded_mouse_buttons) do
        if forwarded then return true end
    end
    return false
end

function EditorPreviewController:forwardGameKeyPressed(key, is_repeat)
    local self = self.editor
    if not self:canForwardGameKeyboardInput() or not self.source_state.onKeyPressed then return false end
    self:runGameCallback("input", function() self.source_state:onKeyPressed(key, is_repeat) end)
    return true
end

function EditorPreviewController:forwardGameKeyReleased(key)
    local self = self.editor
    if not self:canForwardGameKeyboardInput() or not self.source_state.onKeyReleased then return false end
    self:runGameCallback("input", function() self.source_state:onKeyReleased(key) end)
    return true
end

function EditorPreviewController:forwardGameTextInput(text)
    local self = self.editor
    local debug_input = self:isGameDebugOverlayActive() and self:canUseGameDebugInput()
    if not self:canForwardGameKeyboardInput() and not debug_input then return false end
    self:runGameCallback("text input", function()
        if not OVERLAY_OPEN and self.source_state.onTextInput then self.source_state:onTextInput(text) end
        TextInput.onTextInput(text)
        Kristal.callEvent(KRISTAL_EVENT.onTextInput, text)
    end)
    return true
end

function EditorPreviewController:forwardGameMousePressed(x, y, button, istouch, presses)
    local self = self.editor
    local game_x, game_y = self:getGameInputPosition(x, y)
    if not game_x then return false end
    self.forwarded_mouse_buttons[button] = true
    self:runGameCallback("mouse input", function()
        Input.onMousePressed(game_x, game_y, button, istouch, presses)
        Kristal.callEvent(KRISTAL_EVENT.onMousePressed, game_x, game_y, button, istouch, presses)
    end)
    return true
end

function EditorPreviewController:forwardGameMouseMoved(x, y, dx, dy, istouch)
    local self = self.editor
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

function EditorPreviewController:forwardGameMouseReleased(x, y, button, istouch, presses)
    local self = self.editor
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

return EditorPreviewController
