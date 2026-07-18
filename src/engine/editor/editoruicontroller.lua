---@class EditorUIController : Class
---@field editor Editor
---@overload fun(editor: Editor): EditorUIController
local EditorUIController = Class()

function EditorUIController:init(editor)
    self.editor = editor
end

local EDITOR_DEFAULT_WIDTH = 1280
local EDITOR_DEFAULT_HEIGHT = 800

local function fromPixels(value)
    return love.window.fromPixels and love.window.fromPixels(value) or value
end

local function toPixels(value)
    return love.window.toPixels and love.window.toPixels(value) or value
end

function EditorUIController:setupWindow(session)
    local self = self.editor
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

function EditorUIController:setupPanels(session)
    local self = self.editor
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
        minimum_width = 420,
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
    self.terrain_palette_panel = self.dockspace:registerPanel(EditorPanel(
        "terrain_palette", "Terrain Palette", self.terrain_palette, {
            minimum_width = 280,
            minimum_height = 150,
            preferred_height = 240,
            recoverable = true
        }), self.properties_panel.stack)
    self.properties_panel.stack:setActivePanel(self.properties_panel)
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
    self.workspace_registry:register("core:default", {
        name = "Default",
        layout = function(editor) return editor:getDefaultPanelLayout() end,
        core = true
    })
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
        if restored and (session.version or 1) < 6 and self.properties_panel.stack then
            local was_active = self.terrain_palette_panel.stack
                and self.terrain_palette_panel.stack:getActivePanel() == self.terrain_palette_panel
            if self.terrain_palette_panel.visible then
                self.dockspace:dockPanel(self.terrain_palette_panel, self.properties_panel.stack)
                if not was_active then
                    self.properties_panel.stack:setActivePanel(self.properties_panel)
                end
            else
                self.terrain_palette_panel.last_region = self.properties_panel.stack.id
            end
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
    else
        self.active_workspace_id = "core:default"
    end
end

function EditorUIController:setPropertiesTarget(target, owner)
    local self = self.editor
    self.properties_target_owner = owner
    if self.properties_browser then self.properties_browser:setTarget(target) end
end

function EditorUIController:clearPropertiesTarget(owner)
    local self = self.editor
    if owner and self.properties_target_owner ~= owner then return false end
    self.properties_target_owner = nil
    if self.properties_browser then self.properties_browser:setTarget(nil) end
    return true
end

function EditorUIController:setCustomCursorsEnabled(enabled)
    local self = self.editor
    enabled = enabled ~= false
    if self.settings and self.settings:getSetting("appearance.custom_cursors") then
        return self.settings:setValue("appearance.custom_cursors", enabled)
    end
    self.use_custom_cursors = enabled
    if self.editor_cursor then self.editor_cursor:setCustomEnabled(enabled) end
end

function EditorUIController:setDeltaruneFontEnabled(enabled)
    local self = self.editor
    enabled = enabled ~= false
    if self.settings and self.settings:getSetting("appearance.font") then
        return self.settings:setValue("appearance.font", enabled and "deltarune" or "default")
    end
    self.use_deltarune_font = enabled
end

function EditorUIController:addDiagnostic(severity, message, detail, source)
    local self = self.editor
    return self.message_bar:add(severity, message, detail, source)
end

function EditorUIController:addWarning(message, detail, source)
    local self = self.editor
    return self.message_bar:addWarning(message, detail, source)
end

function EditorUIController:addError(message, detail, source)
    local self = self.editor
    return self.message_bar:addError(message, detail, source)
end

function EditorUIController:clearDiagnostics(source)
    local self = self.editor
    self.message_bar:clear(source)
end


function EditorUIController:showDiagnosticsPanel()
    local self = self.editor
    if not self.diagnostics_panel then return false end
    if not self.diagnostics_panel.visible then
        self.dockspace:setPanelVisible(self.diagnostics_panel, true, "bottom")
    end
    if self.diagnostics_panel.stack then self.diagnostics_panel.stack:setActivePanel(self.diagnostics_panel) end
    self.dockspace:setFocus(self.diagnostics_browser)
    return true
end

function EditorUIController:toggleDiagnosticsPanel()
    local self = self.editor
    if not self.diagnostics_panel then return false end
    if self.dockspace:isPanelDisplayed(self.diagnostics_panel) then
        self.dockspace:setPanelVisible(self.diagnostics_panel, false)
        return true
    end
    return self:showDiagnosticsPanel()
end

function EditorUIController:showSettingsPanel()
    local self = self.editor
    if not self.settings_panel then return false end
    if not self.settings_panel.visible then
        self.dockspace:setPanelVisible(self.settings_panel, true, "center")
    end
    if self.settings_panel.stack then self.settings_panel.stack:setActivePanel(self.settings_panel) end
    self.dockspace:setFocus(self.settings_browser.pages)
    return true
end

function EditorUIController:getGameCanvasScreenCenter()
    local self = self.editor
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

function EditorUIController:positionGameCanvasAtScreen(screen_x, screen_y)
    local self = self.editor
    local window_x, window_y = love.window.getPosition()
    local game_x, game_y = self.game_preview:getGlobalPosition()
    local ui_scale = self:getUIScale()
    local canvas_x = toPixels(screen_x - window_x) / ui_scale
        - game_x - SCREEN_WIDTH * self.game_preview.view_zoom / 2
    local canvas_y = toPixels(screen_y - window_y) / ui_scale
        - game_y - SCREEN_HEIGHT * self.game_preview.view_zoom / 2
    self.game_preview:setCanvasPosition(canvas_x, canvas_y)
end

function EditorUIController:centerWindow(display, desktop_width, desktop_height)
    local self = self.editor
    local window_width, window_height = love.window.getMode()
    local desktop_window_width = fromPixels(desktop_width)
    local desktop_window_height = fromPixels(desktop_height)
    love.window.setPosition(
        MathUtils.round((desktop_window_width - window_width) / 2),
        MathUtils.round((desktop_window_height - window_height) / 2),
        display
    )
end

function EditorUIController:openCreationDialog(options)
    local self = self.editor
    if self.creation_dialog then self:closeCreationDialog(false) end
    if self.path_picker then self:closePathPicker(false) end
    if self.object_reference_picker then self:closeObjectReferencePicker(false) end
    self.dockspace.context_menu = nil
    self.dockspace:setFocus(nil)
    self.creation_dialog = EditorCreationDialog(self, options or {})
    self.creation_dialog:update(0)
    return self.creation_dialog
end

function EditorUIController:closeCreationDialog(created)
    local self = self.editor
    local dialog = self.creation_dialog
    if not dialog then return false end
    dialog:setFocus(nil)
    self.creation_dialog = nil
    if self.message_bar and created then self.message_bar:setStatus("Created " .. (dialog.template.name or "item"), 4) end
    return true
end

function EditorUIController:openColorPicker(value, on_apply)
    local self = self.editor
    if self.color_picker then self:closeColorPicker(false) end
    if self.path_picker then self:closePathPicker(false) end
    if self.object_reference_picker then self:closeObjectReferencePicker(false) end
    self.dockspace.context_menu = nil
    self.dockspace:setFocus(nil)
    self.color_picker = EditorColorPicker(self, value, on_apply)
    self.color_picker:update(0)
    return self.color_picker
end

function EditorUIController:closeColorPicker(applied)
    local self = self.editor
    local picker = self.color_picker
    if not picker then return false end
    picker:setFocus(nil)
    self.color_picker = nil
    if applied and self.message_bar then self.message_bar:setStatus("Color applied", 3) end
    return true
end

function EditorUIController:openPathPicker(value, items, options)
    local self = self.editor
    if self.path_picker then self:closePathPicker(false) end
    if self.color_picker then self:closeColorPicker(false) end
    if self.object_reference_picker then self:closeObjectReferencePicker(false) end
    self.dockspace.context_menu = nil
    self.dockspace:setFocus(nil)
    self.path_picker = EditorPathPicker(self, value, items, options)
    self.path_picker:update(0)
    return self.path_picker
end

function EditorUIController:closePathPicker(applied)
    local self = self.editor
    local picker = self.path_picker
    if not picker then return false end
    picker:setFocus(nil)
    self.path_picker = nil
    if applied and self.message_bar then self.message_bar:setStatus("Path applied", 3) end
    return true
end

function EditorUIController:openObjectReferencePicker(value, options)
    local self = self.editor
    if self.object_reference_picker then self:closeObjectReferencePicker(false) end
    if self.color_picker then self:closeColorPicker(false) end
    if self.path_picker then self:closePathPicker(false) end
    self.dockspace.context_menu = nil
    self.dockspace:setFocus(nil)
    self.object_reference_picker = EditorObjectReferencePicker(self, value, options)
    self.object_reference_picker:update(0)
    return self.object_reference_picker
end

function EditorUIController:closeObjectReferencePicker(applied)
    local self = self.editor
    local picker = self.object_reference_picker
    if not picker then return false end
    picker:setFocus(nil)
    self.object_reference_picker = nil
    if applied and self.message_bar then self.message_bar:setStatus("Object reference applied", 3) end
    return true
end

function EditorUIController:captureLayout()
    local self = self.editor
    return self.dockspace:captureLayout()
end

function EditorUIController:getDefaultPanelLayout()
    local self = self.editor
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
    return layout
end

function EditorUIController:resetPanelLayout()
    local self = self.editor
    local layout = self:getDefaultPanelLayout()
    if not layout then return false end
    self:restoreLayout(layout)
    self.active_workspace_id = "core:default"
    return true
end

function EditorUIController:restoreLayout(layout)
    local self = self.editor
    self.dockspace:restoreLayout(layout)
end

return EditorUIController

