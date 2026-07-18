--- Registers the built-in menus, tools, settings, commands, etc.
---@class EditorConfiguration : Class
---@field editor Editor
---@overload fun(editor: Editor): EditorConfiguration
local EditorConfiguration = Class()

function EditorConfiguration:init(editor)
    self.editor = editor
    self.menu_bar = self.editor.menu_bar
    self.tool_registry = self.editor.tool_registry
end

function EditorConfiguration:registerMenuBar()
    local editor = self.editor
    editor.menu_bar:registerItem("file", "save_active", "Save Active Document (Ctrl+S)", {
        is_enabled = function()
            local provider = editor.document_providers:getFocused()
            if provider then return provider:canSave() ~= false end
            return editor.active_document ~= nil or editor.active_tileset_document ~= nil
        end,
        on_activate = function() editor:saveActiveDocument() end
    })
    editor.menu_bar:registerItem("file", "save_tileset", "Save Active Tileset", {
        is_enabled = function() return editor.active_tileset_document ~= nil end,
        on_activate = function() editor:saveTilesetDocumentToProject(editor.active_tileset_document) end
    })
    editor.menu_bar:registerItem("file", "save_world", "Save Selected World", {
        is_enabled = function() return editor.active_editor_world ~= nil end,
        on_activate = function() editor:saveWorldDocumentToProject(editor.active_editor_world) end
    })
    editor.menu_bar:registerItem("file", "save_all", "Save All (Ctrl+Shift+S)", {
        is_enabled = function() return editor:hasUnsavedChanges() end,
        on_activate = function() editor:saveAllDocuments() end
    })
    editor.menu_bar:registerItem("file", "switch_project", "Switch Project...", {
        is_enabled = function() return editor:hasSwitchableProjects() end,
        on_activate = function() editor:openProjectSwitcher() end
    })
    editor.menu_bar:registerItem("file", "exit_editor",
        editor.return_to_menu_on_exit and "Return to Main Menu" or "Return to Game", {
            on_activate = function() Kristal.exitEditor() end
        })
    editor.menu_bar:registerItem("edit", "undo", "Undo", {
        is_enabled = function() return editor:canUndo() end,
        on_activate = function() editor:undo() end
    })
    editor.menu_bar:registerItem("edit", "redo", "Redo", {
        is_enabled = function() return editor:canRedo() end,
        on_activate = function() editor:redo() end
    })
    editor.menu_bar:registerItem("edit", "settings", "Editor Settings...", {
        on_activate = function() editor:showSettingsPanel() end
    })
    editor.menu_bar:registerItem("edit", "rebuild_terrain_layer", "Rebuild Terrain in Layer", {
        is_enabled = function()
            local _, terrain = editor:getSelectedTerrain()
            return editor.active_document and editor.active_document.map_view and terrain ~= nil
        end,
        on_activate = function() editor:rebuildTerrain("layer") end
    })
    editor.menu_bar:registerItem("edit", "rebuild_terrain_map", "Rebuild Terrain in Map", {
        is_enabled = function()
            local _, terrain = editor:getSelectedTerrain()
            return editor.active_document and editor.active_document.map_view and terrain ~= nil
        end,
        on_activate = function() editor:rebuildTerrain("map") end
    })
    editor.menu_bar:registerToggle("edit", "tile_editing", "Map Editing View (Tab)",
        function() return editor.tile_editing_mode end,
        function(enabled) editor:setTileEditingMode(enabled) end)
    editor.menu_bar:registerToggle("view", "custom_cursors", "Use Custom Cursors",
        function() return editor.use_custom_cursors end,
        function(enabled) editor:setCustomCursorsEnabled(enabled) end)
    editor.menu_bar:registerToggle("view", "deltarune_font", "Use Deltarune Font",
        function() return editor.use_deltarune_font end,
        function(enabled) editor:setDeltaruneFontEnabled(enabled) end)
    editor.menu_bar:registerToggle("view", "editor_music", "Editor Music",
        function() return editor.editor_music_enabled end,
        function(enabled) editor:setEditingMusicEnabled(enabled) end)
    editor.menu_bar:registerToggle("view", "tile_grid", "Tile Grid (G)",
        function() return editor.show_tile_grid end,
        function(enabled) editor.show_tile_grid = enabled == true end)
    editor.menu_bar:registerItem("view", "command_palette", "Command Palette (Ctrl+Shift+P)", {
        on_activate = function() editor:openCommandPalette() end
    })
    editor.menu_bar:registerItem("workspaces", "switch", "Switch Workspace...", {
        on_activate = function() editor:openWorkspacePicker() end
    })
    editor.menu_bar:registerItem("workspaces", "save", "Save Current Workspace...", {
        on_activate = function() editor:openSaveWorkspaceDialog() end
    })
    editor.menu_bar:registerItem("workspaces", "delete", "Delete Saved Workspace...", {
        is_enabled = function()
            return editor.workspace_registry and #editor.workspace_registry:getUserWorkspaces() > 0
        end,
        on_activate = function() editor:openDeleteWorkspacePicker() end
    })
    editor.menu_bar:registerItem("workspaces", "reset", "Reset to Default", {
        on_activate = function() editor:resetPanelLayout() end
    })
    editor.menu_bar:registerProvider("window", "panels", function()
        local items = {}
        for _, panel in ipairs(editor.dockspace.panel_order) do
            local current_panel = panel
            if current_panel.recoverable then
                table.insert(items, {
                    id = current_panel.id,
                    label = current_panel.title,
                    get_checked = function() return current_panel.visible end,
                    on_activate = function()
                        editor.dockspace:setPanelVisible(current_panel, not current_panel.visible)
                    end
                })
            end
        end
        return items
    end)
end

function EditorConfiguration:registerEditorTools()
    local editor = self.editor
    editor.tool_registry = EditorToolRegistry()
    editor.tool_registry:register("select", {
        name = "Select", icon = "editor/ui/tool/select", keybind = "editor_tool_select"
    })
    editor.tool_registry:register("world_select", {
        name = "World Select", short_name = "World", icon = "editor/ui/tool/world",
        keybind = "editor_tool_world_select"
    })
    editor.tool_registry:register("object", {
        name = "Add Object", short_name = "Object", icon = "editor/ui/tool/shape_point",
        keybind = "editor_tool_object"
    })
    editor.tool_registry:register("shape", {
        name = "Shape", icon = "editor/ui/tool/shape_rect", keybind = "editor_tool_shape"
    })
    editor.tool_registry:register("tile_brush", {
        name = "Tile Brush", short_name = "Brush", icon = "editor/ui/tool/brush",
        keybind = "editor_tool_tile_brush", toolbar_group = "tile_brush"
    })
    editor.tool_registry:register("tile_brush_line", {
        name = "Tile Line", short_name = "Line", icon = "editor/ui/tool/brush_line",
        keybind = "editor_tool_tile_brush_line", toolbar_group = "tile_brush"
    })
    editor.tool_registry:register("tile_brush_round", {
        name = "Round Tile Brush", short_name = "Round", icon = "editor/ui/tool/brush_round",
        keybind = "editor_tool_tile_brush_round", toolbar_group = "tile_brush"
    })
    editor.tool_registry:register("tile_shape_rect", {
        name = "Filled Tile Rectangle", short_name = "Rectangle", icon = "editor/ui/tool/tile_shape_rect",
        keybind = "editor_tool_tile_shape_rect", toolbar_group = "tile_shape"
    })
    editor.tool_registry:register("tile_shape_ellipse", {
        name = "Filled Tile Ellipse", short_name = "Ellipse", icon = "editor/ui/tool/tile_shape_ellipse",
        keybind = "editor_tool_tile_shape_ellipse", toolbar_group = "tile_shape"
    })
    editor.tool_registry:register("tile_select_rect", {
        name = "Rectangular Tile Select", short_name = "Tile Select", icon = "editor/ui/tool/tile_select_rect",
        keybind = "editor_tool_tile_select_rect", toolbar_group = "tile_select"
    })
    editor.tool_registry:register("tile_select_wand", {
        name = "Connected Tile Select", short_name = "Wand", icon = "editor/ui/tool/tile_select_wand",
        keybind = "editor_tool_tile_select_wand", toolbar_group = "tile_select"
    })
    editor.tool_registry:register("tile_select_same", {
        name = "Select Same Tiles", short_name = "Same Tiles", icon = "editor/ui/tool/tile_select_same",
        keybind = "editor_tool_tile_select_same", toolbar_group = "tile_select"
    })
    editor.tool_registry:register("tile_stamp", {
        name = "Capture Tile Stamp", short_name = "Stamp", icon = "editor/ui/tool/tile_stamp",
        keybind = "editor_tool_tile_stamp"
    })
    editor.tool_registry:register("terrain_brush", {
        name = "Terrain Brush", short_name = "Terrain", icon = "editor/ui/tool/brush_terrain",
        keybind = "editor_tool_terrain_brush"
    })
    editor.tool_registry:register("tile_fill", {
        name = "Tile Fill", short_name = "Fill", icon = "editor/ui/tool/bucket",
        keybind = "editor_tool_tile_fill"
    })
    editor.tool_registry:register("eraser", {
        name = "Eraser", icon = "editor/ui/tool/eraser", keybind = "editor_tool_eraser"
    })
    editor.tool_registry:register("link", {
        name = "Link Objects", short_name = "Link", icon = "editor/ui/tool/link",
        keybind = "editor_tool_link"
    })
    editor.active_tool = "select"
    editor.selected_event_id = nil
    editor.shape_mode = "rectangle"
    for _, registered in ipairs(editor.tool_registry:getAll()) do
        local tool = registered
        editor.command_registry:register("tool:" .. tool.id, {
            name = tool.name .. " Tool",
            category = "Tools",
            keywords = { tool.id, tool.short_name or "" },
            is_enabled = function() return editor.tile_editing_mode and editor.active_document ~= nil end,
            get_checked = function() return editor.active_tool == tool.id end,
            action = function() editor:setActiveTool(tool.id) end
        })
    end
end

function EditorConfiguration:registerEditorSettings(session)
    local editor = self.editor
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
    if stored["editing.brush_size"] == nil and stored["editing.terrain_brush_size"] ~= nil then
        stored["editing.brush_size"] = stored["editing.terrain_brush_size"]
    end
    stored["editing.terrain_brush_size"] = nil

    editor.settings = EditorSettingsRegistry(editor, stored)
    editor.settings:registerPage("appearance", "Appearance")
    editor.settings:registerSetting("appearance", "appearance.font", {
        name = "Editor Font", type = "choice", default = "deltarune",
        choices = { { value = "deltarune", label = "Deltarune" }, { value = "default", label = "System Default" } },
        set = function(value, editor) editor.use_deltarune_font = value == "deltarune" end
    })
    editor.settings:registerSetting("appearance", "appearance.ui_scale", {
        name = "UI Scale", type = "number", default = 1, minimum = 0.5, maximum = 2,
        description = "Adjust the scale of the editor's UI- note, the font may look odd on non-integer scaling.",
        set = function(value, editor) editor.ui_scale = value end
    })
    editor.settings:registerSetting("appearance", "appearance.custom_cursors", {
        name = "Use Custom Cursors", type = "boolean", default = true,
        set = function(value, editor)
            editor.use_custom_cursors = value
            if editor.editor_cursor then editor.editor_cursor:setCustomEnabled(value) end
        end
    })
    editor.settings:registerSetting("appearance", "appearance.darken_unselected", {
        name = "Darken Unselected Layers", type = "boolean", default = true,
        set = function(value, editor)
            editor.darken_unselected_layers = value
            if editor.layers_browser and editor.layers_browser.darken_toggle then
                editor.layers_browser.darken_toggle:setValue(value, true)
            end
        end
    })
    editor.settings:registerSetting("appearance", "appearance.editor_music", {
        name = "Editor Music", type = "boolean", default = true,
        set = function(value, editor)
            editor.editor_music_enabled = value
            if editor.music then editor:syncEditingMusic() end
        end
    })
    editor.settings:registerSetting("appearance", "appearance.align_game_transition", {
        name = "Align Game on Enter/Exit", type = "boolean", default = true,
        description = "Keep the game canvas at the same screen position while entering or leaving the editor.",
        set = function(value, editor) editor.align_game_transition = value end
    })

    editor.settings:registerPage("editing", "Editing")
    editor.settings:registerSetting("editing", "editing.history_limit", {
        name = "Undo History Limit", type = "integer", default = EditorHistory.DEFAULT_LIMIT,
        minimum = 1, maximum = 10000,
        description = "Maximum completed edit commands retained in memory.",
        get = function(editor) return editor.history:getLimit() end,
        set = function(value, editor) return editor.history:setLimit(value) end
    })
    editor.settings:registerSetting("editing", "editing.brush_size", {
        name = "Brush Size", type = "integer", default = 1,
        minimum = 1, maximum = 32,
        description = "Tile diameter used by tile and terrain brushes.",
        set = function(value, editor) return editor:setBrushSize(value) end
    })

    editor.settings:registerPage("keybinds", "Keybinds")
    local function keybind(id, name, alias)
        editor.settings:registerSetting("keybinds", id, {
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
    for _, tool in ipairs(editor.tool_registry:getAll()) do
        if tool.keybind then
            keybind("keybinds.tool_" .. tool.id, tool.name .. " Tool", tool.keybind)
        end
    end
end

return EditorConfiguration
