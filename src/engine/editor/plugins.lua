---@class EditorPlugins
---@field directory string
---@field debug_directory string
---@field plugins table<string, EditorPlugin>
---@field plugin_order EditorPlugin[]
---@field panel_definitions table[]
---@field menu_definitions table[]
---@field command_definitions table[]
---@field file_context_providers table[]
---@field event_initializers table[]
---@field editor Editor?
local EditorPlugins = {
    directory = "editor/plugins",
    debug_directory = "plugins",
    plugins = {},
    plugin_order = {},
    panel_definitions = {},
    menu_definitions = {},
    command_definitions = {},
    file_context_providers = {},
    event_initializers = {},
    editor = nil
}

local NIL_RESULT = {}
local function normalizeScriptPath(path)
    path = tostring(path or ""):gsub("\\", "/"):gsub("%.lua$", "")
    return path:gsub("%.", "/"):gsub("^/+", "")
end

local function namespaced(plugin, kind, id)
    return string.format("plugin:%s:%s:%s", plugin.id, kind, id)
end

function EditorPlugin:trackRegistration(cleanup)
    table.insert(self.registration_cleanups, cleanup)
end

function EditorPlugin:require(path, ...)
    path = normalizeScriptPath(path)
    local cached = self.loaded_scripts[path]
    if cached ~= nil then return cached ~= NIL_RESULT and cached or nil end
    local chunk = self.info.script_chunks[path] or self.info.script_chunks[path .. "/init"]
    if not chunk then error(string.format("Plugin '%s' has no script '%s'", self.id, path), 2) end
    if self.loading_scripts[path] then
        error(string.format("Plugin '%s' has a circular require for '%s'", self.id, path), 2)
    end

    self.loading_scripts[path] = true
    local arguments = { ... }
    local success, result
    HookSystem.withOwner(self, function()
        success, result = xpcall(function() return chunk(unpack(arguments)) end, ErrorUtils.traceback)
    end)
    self.loading_scripts[path] = nil
    if not success then error(result, 2) end
    self.loaded_scripts[path] = result == nil and NIL_RESULT or result
    return result
end

function EditorPlugin:loadHooks()
    local paths = {}
    for path in pairs(self.info.script_chunks) do
        if StringUtils.startsWith(path, "scripts/hooks/") then table.insert(paths, path) end
    end
    table.sort(paths)
    for _, path in ipairs(paths) do self:require(path) end
end

function EditorPlugin:registerSettingsPage(id, title, options)
    assert(type(id) == "string" and id ~= "", "Plugin settings pages require an id")
    assert(not self.settings_pages[id], "Duplicate plugin settings page id: " .. id)
    local page_id = namespaced(self, "settings_page", id)
    options = TableUtils.copy(options or {}, true)
    options.owner = self
    local page = EditorPlugins.editor.settings:registerPage(page_id, title or id, options)
    self.settings_pages[id] = page
    return page
end

function EditorPlugin:registerSetting(page, id, definition)
    if type(id) == "table" and definition == nil then
        definition, id, page = id, page, nil
    end
    assert(type(id) == "string" and id ~= "", "Plugin settings require an id")
    if page == nil then
        page = self.settings_pages.default or self:registerSettingsPage("default", self.info.name or self.id)
    elseif type(page) == "string" then
        page = self.settings_pages[page] or self:registerSettingsPage(page, page)
    end
    assert(type(page) == "table" and page.id, "Plugin settings require a settings page")
    local setting_id = namespaced(self, "setting", id)
    definition = TableUtils.copy(definition or {}, true)
    definition.owner = self
    return EditorPlugins.editor.settings:registerSetting(page.id, setting_id, definition)
end

function EditorPlugin:registerPropertyType(id, definition)
    local type_id = namespaced(self, "property_type", id)
    local registered = Registry.registerEditorPropertyType(type_id, definition)
    self:trackRegistration(function()
        if Registry.editor_properties.types[type_id] == registered then
            Registry.editor_properties.types[type_id] = nil
            TableUtils.removeValue(Registry.editor_properties.type_order, type_id)
        end
    end)
    return type_id
end

function EditorPlugin:registerFileType(id, definition)
    assert(type(id) == "string" and id ~= "", "Plugin file types require an id")
    local editor = assert(EditorPlugins.editor, "Plugin file types require an active editor")
    local type_id = namespaced(self, "file_type", id)
    local registered = editor.file_type_registry:register(type_id, definition)
    registered.owner = self
    self:trackRegistration(function()
        if editor.file_type_registry then
            editor.file_type_registry:unregister(type_id, registered)
        end
    end)
    return registered
end

function EditorPlugin:registerFileContextProvider(id, provider)
    assert(type(id) == "string" and id ~= "", "Plugin file context providers require an id")
    assert(type(provider) == "function", "Plugin file context providers require a callback")
    local definition = {
        plugin = self,
        id = namespaced(self, "file_context", id),
        provider = provider
    }
    table.insert(EditorPlugins.file_context_providers, definition)
    self:trackRegistration(function()
        TableUtils.removeValue(EditorPlugins.file_context_providers, definition)
    end)
    return definition
end

function EditorPlugin:registerFormatExtension(scope, id, definition)
    assert(scope == "map" or scope == "tileset" or scope == "world",
        "Editor format extension scope must be map, tileset, or world")
    local extension_id = namespaced(self, scope .. "_format", id)
    local registered = Registry.editor_format_extensions:registerExtension(
        scope, extension_id, definition)
    registered.owner = self
    self:trackRegistration(function()
        Registry.editor_format_extensions:unregisterExtension(scope, extension_id, registered)
    end)
    local initialized, reason = EditorPlugins:initializeFormatExtensions(scope)
    if not initialized then error(reason, 2) end
    return extension_id
end

function EditorPlugin:registerMapFormatExtension(id, definition)
    return self:registerFormatExtension("map", id, definition)
end

function EditorPlugin:registerTilesetFormatExtension(id, definition)
    return self:registerFormatExtension("tileset", id, definition)
end

function EditorPlugin:registerWorldFormatExtension(id, definition)
    return self:registerFormatExtension("world", id, definition)
end

function EditorPlugin:registerLayerKind(id, definition)
    local kind_id = namespaced(self, "layer_kind", id)
    local registered = Registry.registerLayerKind(kind_id, definition)
    self:trackRegistration(function()
        if Registry.layer_types.kinds[kind_id] == registered then
            Registry.layer_types.kinds[kind_id] = nil
            TableUtils.removeValue(Registry.layer_types.kind_order, kind_id)
        end
    end)
    return kind_id
end

function EditorPlugin:registerLayerType(id, definition)
    local type_id = namespaced(self, "layer_type", id)
    definition = TableUtils.copy(definition or {}, true)
    if definition.kind and not Registry.getLayerKind(definition.kind) then
        local plugin_kind = namespaced(self, "layer_kind", definition.kind)
        if Registry.getLayerKind(plugin_kind) then definition.kind = plugin_kind end
    end
    local registered = Registry.registerLayerType(type_id, definition)
    self:trackRegistration(function()
        if Registry.layer_types.types[type_id] == registered then
            Registry.layer_types.types[type_id] = nil
            TableUtils.removeValue(Registry.layer_types.order, type_id)
        end
    end)
    return type_id
end

function EditorPlugin:registerEditorEventProperty(event_id, id, property_type, options)
    return self:registerEditorEventInitializer(event_id, function(event)
        event:registerProperty(id, property_type, options)
    end)
end

function EditorPlugin:registerEditorEventInitializer(event_id, initializer)
    assert(type(initializer) == "function", "EditorEvent initializers must be functions")
    EditorPlugins.event_initializers[event_id] = EditorPlugins.event_initializers[event_id] or {}
    table.insert(EditorPlugins.event_initializers[event_id], initializer)
    self:trackRegistration(function()
        local initializers = EditorPlugins.event_initializers[event_id]
        if not initializers then return end
        TableUtils.removeValue(initializers, initializer)
        if #initializers == 0 then EditorPlugins.event_initializers[event_id] = nil end
    end)
    return initializer
end

function EditorPlugin:registerEditorEvent(id, event, options)
    if type(event) == "string" then event = self:require(event) end
    options = options or {}
    local event_id = id
    local previous = Registry.getEditorEvent(event_id)
    assert(not previous or options.replace == true,
        "Editor event '" .. tostring(event_id) .. "' is already registered; pass replace = true to override it")
    local previous_id = event.id
    Registry.registerEditorEvent(event_id, event)
    self:trackRegistration(function()
        if Registry.editor_events[event_id] == event then Registry.editor_events[event_id] = previous end
        if event.id == event_id then event.id = previous_id end
    end)
    return event_id
end

function EditorPlugin:registerEditorDrawFX(id, definition)
    local fx_id = namespaced(self, "draw_fx", id)
    local registered = Registry.registerEditorDrawFX(fx_id, definition)
    self:trackRegistration(function()
        if Registry.editor_draw_fx[fx_id] == registered then Registry.editor_draw_fx[fx_id] = nil end
    end)
    return fx_id
end

function EditorPlugin:registerPanel(id, title, content_factory, options)
    assert(type(id) == "string" and id ~= "", "Plugin panels require an id")
    assert(not self.panels[id], "Duplicate plugin panel id: " .. id)
    assert(type(content_factory) == "function", "Plugin panels require a content factory")
    options = TableUtils.copy(options or {}, true)
    local definition = {
        plugin = self,
        id = id,
        panel_id = namespaced(self, "panel", id),
        title = title or id,
        content_factory = content_factory,
        options = options,
        region = options.region or "right"
    }
    self.panels[id] = definition
    table.insert(EditorPlugins.panel_definitions, definition)
    self:trackRegistration(function()
        self.panels[id] = nil
        TableUtils.removeValue(EditorPlugins.panel_definitions, definition)
    end)
    return definition
end

---@param id string
---@param name string|table
---@param layout? table|fun(editor: Editor, workspace: table): table
---@param options? table
function EditorPlugin:registerWorkspace(id, name, layout, options)
    assert(type(id) == "string" and id ~= "", "Plugin workspaces require an id")
    assert(not self.workspaces[id], "Duplicate plugin workspace id: " .. id)
    if type(name) == "table" and layout == nil then
        options = name
        name = options.name
        layout = options.layout or options.get_layout
    end
    options = TableUtils.copy(options or {}, false)
    local workspace_id = namespaced(self, "workspace", id)
    options.name = name or options.name or id
    options.layout = layout or options.layout or options.get_layout
    options.owner = self
    local workspace = EditorPlugins.editor.workspace_registry:register(workspace_id, options)
    self.workspaces[id] = workspace
    self:trackRegistration(function()
        self.workspaces[id] = nil
        local editor = EditorPlugins.editor
        if editor and editor.workspace_registry then
            editor.workspace_registry:remove(workspace_id, workspace)
        end
    end)
    return workspace
end

---@param music string|false Music id, or false to silence editor music
---@param options? {volume?: number, pitch?: number, looping?: boolean, fade?: number}
function EditorPlugin:setEditorMusicOverride(music, options)
    local editor = assert(EditorPlugins.editor, "Editor music is unavailable outside editor mode")
    if not self.editor_music_cleanup_registered then
        self.editor_music_cleanup_registered = true
        self:trackRegistration(function()
            local active_editor = EditorPlugins.editor
            if active_editor then active_editor:clearEditorMusicOverride(self, { fade = 0 }) end
            self.editor_music_cleanup_registered = nil
        end)
    end
    return editor:setEditorMusicOverride(self, music, options)
end

---@param options? {fade?: number}
function EditorPlugin:clearEditorMusicOverride(options)
    local editor = EditorPlugins.editor
    return editor and editor:clearEditorMusicOverride(self, options) or false
end

function EditorPlugin:registerMenuItem(menu_id, id, label, options)
    assert(type(menu_id) == "string" and menu_id ~= "", "Plugin menu items require a menu id")
    assert(type(id) == "string" and id ~= "", "Plugin menu items require an id")
    local definition = {
        kind = "item", plugin = self, menu_id = menu_id,
        id = namespaced(self, "menu", id), label = label or id, options = options or {}
    }
    table.insert(EditorPlugins.menu_definitions, definition)
    self:trackRegistration(function() TableUtils.removeValue(EditorPlugins.menu_definitions, definition) end)
    return definition
end

function EditorPlugin:registerMenuToggle(menu_id, id, label, get_checked, set_checked)
    assert(type(get_checked) == "function" and type(set_checked) == "function",
        "Plugin menu toggles require getter and setter callbacks")
    local definition = {
        kind = "toggle", plugin = self, menu_id = menu_id,
        id = namespaced(self, "menu", id), label = label or id,
        get_checked = get_checked, set_checked = set_checked
    }
    table.insert(EditorPlugins.menu_definitions, definition)
    self:trackRegistration(function() TableUtils.removeValue(EditorPlugins.menu_definitions, definition) end)
    return definition
end

function EditorPlugin:registerMenuProvider(menu_id, id, provider)
    assert(type(provider) == "function", "Plugin menu providers require a callback")
    local definition = {
        kind = "provider", plugin = self, menu_id = menu_id,
        id = namespaced(self, "menu", id), provider = provider
    }
    table.insert(EditorPlugins.menu_definitions, definition)
    self:trackRegistration(function() TableUtils.removeValue(EditorPlugins.menu_definitions, definition) end)
    return definition
end

function EditorPlugin:registerTerrainConditionType(id, definition)
    local type_id = namespaced(self, "terrain_condition", id)
    local registered = Registry.registerTerrainConditionType(type_id, definition)
    self:trackRegistration(function()
        if Registry.terrain_rules then
            Registry.terrain_rules:unregisterConditionType(type_id, registered)
        end
    end)
    return type_id
end

function EditorPlugin:registerTerrainPredicate(id, definition)
    local predicate_id = namespaced(self, "terrain_predicate", id)
    local registered = Registry.registerTerrainPredicate(predicate_id, definition)
    self:trackRegistration(function()
        if Registry.terrain_rules then
            Registry.terrain_rules:unregisterPredicate(predicate_id, registered)
        end
    end)
    return predicate_id
end

function EditorPlugin:registerTemplate(id, definition)
    assert(type(id) == "string" and id ~= "", "Plugin templates require an id")
    local template_id = namespaced(self, "template", id)
    local registered = Registry.registerEditorTemplate(template_id, definition)
    registered.owner = self
    self:trackRegistration(function()
        if Registry.editor_templates[template_id] == registered then
            Registry.editor_templates[template_id] = nil
            TableUtils.removeValue(Registry.editor_template_order, registered)
        end
    end)
    return template_id
end

function EditorPlugin:registerCommand(id, label, options)
    assert(type(id) == "string" and id ~= "", "Plugin commands require an id")
    options = options or {}
    assert(type(options.action) == "function", "Plugin commands require an action")
    local definition = {
        plugin = self,
        id = namespaced(self, "command", id),
        name = label or id,
        category = options.category or self.info.name or self.id,
        keywords = options.keywords,
        is_enabled = options.is_enabled,
        get_checked = options.get_checked,
        action = options.action
    }
    table.insert(EditorPlugins.command_definitions, definition)
    self:trackRegistration(function()
        TableUtils.removeValue(EditorPlugins.command_definitions, definition)
        local editor = EditorPlugins.editor
        if editor and editor.command_registry then editor.command_registry:unregister(definition.id) end
    end)
    return definition
end

---@param id string
---@param provider EditorDocumentProvider
function EditorPlugin:registerDocumentProvider(id, provider)
    assert(type(id) == "string" and id ~= "", "Plugin document providers require an id")
    local provider_id = namespaced(self, "document_provider", id)
    provider = EditorPlugins.editor.document_providers:register(provider_id, provider)
    self:trackRegistration(function()
        local editor = EditorPlugins.editor
        if editor and editor.document_providers then editor.document_providers:unregister(provider_id) end
    end)
    return provider
end

function EditorPlugins:reset()
    self.plugins = {}
    self.plugin_order = {}
    self.panel_definitions = {}
    self.menu_definitions = {}
    self.command_definitions = {}
    self.file_context_providers = {}
    self.event_initializers = {}
end

function EditorPlugins:getFileContextMenuItems(data, context)
    local items = {}
    for _, definition in ipairs(self.file_context_providers) do
        if not definition.plugin.disabled then
            local success, provided = xpcall(function()
                return definition.provider(data, context)
            end, ErrorUtils.traceback)
            if not success then
                self:report(self.editor,
                    "Could not build file context menu from plugin: " .. definition.plugin.id, provided)
            elseif type(provided) == "table" and provided.label then
                table.insert(items, provided)
            elseif type(provided) == "table" then
                for _, item in ipairs(provided) do
                    if type(item) == "table" and item.label then table.insert(items, item) end
                end
            end
        end
    end
    return items
end

function EditorPlugins:initializeEditorEvent(event)
    for _, initializer in ipairs(self.event_initializers[event.id] or {}) do initializer(event) end
end

function EditorPlugins:clearPluginHooks(plugin)
    HookSystem.clearOwnedHooks(function(owner)
        return owner == plugin or plugin == nil and owner.__editor_plugin == true
    end)
end

function EditorPlugins:clearPluginRegistrations(plugin)
    if not plugin or plugin.registrations_cleared then return end
    plugin.registrations_cleared = true
    for index = #plugin.registration_cleanups, 1, -1 do
        local success, message = xpcall(plugin.registration_cleanups[index], ErrorUtils.traceback)
        if not success and self.editor then
            self:report(self.editor, "Could not clean up editor plugin registration: " .. plugin.id, message)
        end
    end
    plugin.registration_cleanups = {}
end

function EditorPlugins:disablePlugin(plugin)
    if not plugin or plugin.disabled then return end
    plugin.disabled = true
    self:clearPluginHooks(plugin)
    if self.editor and self.editor.settings then self.editor.settings:removeOwner(plugin) end
    self:clearPluginRegistrations(plugin)
    plugin.settings_pages = {}
    plugin.workspaces = {}
end

function EditorPlugins:report(editor, message, detail)
    editor:addWarning(message, detail, "editor_plugin")
    print(message .. (detail and ("\n" .. detail) or ""))
end

function EditorPlugins:loadPlugin(editor, directory, folder, source)
    local path = directory .. "/" .. folder
    local info_path = path .. "/plugin.json"
    if not love.filesystem.getInfo(info_path, "file") then return nil end

    local success, info = pcall(function() return JSON.decode(love.filesystem.read(info_path)) end)
    if not success or type(info) ~= "table" then
        self:report(editor, "Could not load editor plugin metadata: " .. folder,
            success and "plugin.json must contain a JSON object" or tostring(info))
        return nil
    end
    if type(info.id) ~= "string" or info.id == "" then
        self:report(editor, "Could not load editor plugin: " .. folder, "plugin.json requires a non-empty id")
        return nil
    end
    for _, field in ipairs({ "dependencies", "optionalDependencies" }) do
        if info[field] ~= nil and type(info[field]) ~= "table" then
            self:report(editor, "Could not load editor plugin: " .. info.id,
                "plugin.json field '" .. field .. "' must be an array")
            return nil
        end
        for _, dependency in ipairs(info[field] or {}) do
            if type(dependency) ~= "string" or dependency == "" then
                self:report(editor, "Could not load editor plugin: " .. info.id,
                    "plugin.json field '" .. field .. "' contains an invalid plugin id")
                return nil
            end
        end
    end
    if self.plugins[info.id] then
        if source == "user" and self.plugins[info.id].info.source == "debug" then return nil end
        self:report(editor, "Duplicate editor plugin id: " .. info.id, path)
        return nil
    end

    info.path = path
    info.source = source
    info.script_chunks = {}
    for _, script_path in ipairs(FileSystemUtils.getFilesRecursive(path, ".lua")) do
        local chunk, load_error = love.filesystem.load(path .. "/" .. script_path .. ".lua")
        if not chunk then
            self:report(editor, string.format("Could not load script '%s' from editor plugin '%s'",
                script_path, info.id), load_error)
            return nil
        end
        info.script_chunks[script_path] = chunk
    end

    local plugin = EditorPlugin(info)
    self.plugins[plugin.id] = plugin
    table.insert(self.plugin_order, plugin)

    return plugin
end

function EditorPlugins:sortPlugins(editor)
    local state, sorted = {}, {}
    local function visit(plugin, dependency_of)
        if state[plugin] == "done" then return not plugin.disabled end
        if state[plugin] == "visiting" then
            self:disablePlugin(plugin)
            self:report(editor, "Circular editor plugin dependency: " .. plugin.id,
                dependency_of and ("Required by " .. dependency_of.id) or nil)
            return false
        end
        state[plugin] = "visiting"
        for _, dependency_id in ipairs(plugin.info.dependencies or {}) do
            local dependency = self.plugins[dependency_id]
            if not dependency then
                self:disablePlugin(plugin)
                self:report(editor, "Missing editor plugin dependency for " .. plugin.id, dependency_id)
                state[plugin] = "done"
                return false
            end
            if not visit(dependency, plugin) then
                self:disablePlugin(plugin)
                self:report(editor, "Editor plugin dependency failed for " .. plugin.id, dependency_id)
                state[plugin] = "done"
                return false
            end
        end
        for _, dependency_id in ipairs(plugin.info.optionalDependencies or {}) do
            local dependency = self.plugins[dependency_id]
            if dependency then visit(dependency, plugin) end
        end
        state[plugin] = "done"
        if not plugin.disabled then table.insert(sorted, plugin) end
        return not plugin.disabled
    end
    local discovered = TableUtils.copy(self.plugin_order)
    for _, plugin in ipairs(discovered) do visit(plugin) end
    for _, plugin in ipairs(discovered) do
        if plugin.disabled then table.insert(sorted, plugin) end
    end
    return sorted
end

function EditorPlugins:initializePluginScript(plugin)
    if not plugin.info.script_chunks.plugin then
        return false, "plugin.lua must return an EditorPlugin class"
    end
    local loaded, result = xpcall(function()
        local plugin_class = plugin:require("plugin")
        assert(isClass(plugin_class) and plugin_class:includes(EditorPlugin),
            "plugin.lua must return a class extending EditorPlugin")
        local instance = plugin_class(plugin.info)
        assert(instance.id == plugin.id, "EditorPlugin constructor changed the plugin id")
        instance.loaded_scripts = plugin.loaded_scripts
        instance.loading_scripts = plugin.loading_scripts
        return instance
    end, ErrorUtils.traceback)
    if not loaded then return false, result end
    self:clearPluginHooks(plugin)
    return true, result
end

function EditorPlugins:initializeFormatExtensions(scope)
    local editor = self.editor
    if not editor then return true end
    if scope == "map" then
        for id, data in pairs(Registry.map_data or {}) do
            local success, reason = EditorFormat.decodeMapExtensions(data, {
                editor = editor, map = data, map_id = id
            })
            if not success then return false, reason end
        end
    elseif scope == "tileset" then
        for _, document in ipairs(editor.tileset_documents or {}) do
            local success, reason = document:initializeFormatExtensions()
            if not success then return false, reason end
        end
    elseif scope == "world" then
        for _, world in pairs(Registry.editor_worlds or {}) do
            local success, reason = world:initializeFormatExtensions()
            if not success then return false, reason end
        end
    end
    return true
end

function EditorPlugins:scanDirectory(editor, directory, source)
    if not love.filesystem.getInfo(directory, "directory") then return end
    local folders = love.filesystem.getDirectoryItems(directory)
    table.sort(folders)
    for _, folder in ipairs(folders) do
        local info = love.filesystem.getInfo(directory .. "/" .. folder)
        if info and info.type == "directory" then self:loadPlugin(editor, directory, folder, source) end
    end
end

function EditorPlugins:initialize(editor)
    for _, plugin in ipairs(self.plugin_order) do self:disablePlugin(plugin) end
    self:clearPluginHooks()
    self:reset()
    self.editor = editor
    love.filesystem.createDirectory(self.directory)
    self:scanDirectory(editor, self.debug_directory, "debug")
    self:scanDirectory(editor, self.directory, "user")
    self.plugin_order = self:sortPlugins(editor)

    for index, plugin in ipairs(self.plugin_order) do
        if not plugin.disabled then
            local script_loaded, instance_or_message = self:initializePluginScript(plugin)
            if not script_loaded then
                self:disablePlugin(plugin)
                self:report(editor, "Could not initialize editor plugin script: " .. plugin.id, instance_or_message)
            else
                plugin = instance_or_message
                self.plugin_order[index] = plugin
                self.plugins[plugin.id] = plugin
            end
        end
        local hooks_loaded, hooks_message = true
        if not plugin.disabled then
            hooks_loaded, hooks_message = xpcall(function() plugin:loadHooks() end, ErrorUtils.traceback)
        end
        if not hooks_loaded then
            self:disablePlugin(plugin)
            self:report(editor, "Editor plugin hooks failed: " .. plugin.id, hooks_message)
        end
        local init = plugin.onInit
        if init and not plugin.disabled then
            local success, message = xpcall(function()
                HookSystem.withOwner(plugin, function() init(plugin, editor) end)
            end, ErrorUtils.traceback)
            if not success then
                self:disablePlugin(plugin)
                self:report(editor, "Editor plugin init failed: " .. plugin.id, message)
            end
        end
    end
end

function EditorPlugins:applyMenuBar(editor)
    for _, definition in ipairs(self.menu_definitions) do
        if not definition.plugin.disabled then
            local success, message = xpcall(function()
                if definition.kind == "toggle" then
                    editor.menu_bar:registerToggle(definition.menu_id, definition.id, definition.label,
                        definition.get_checked, definition.set_checked)
                elseif definition.kind == "provider" then
                    editor.menu_bar:registerProvider(definition.menu_id, definition.id, definition.provider)
                else
                    editor.menu_bar:registerItem(definition.menu_id, definition.id, definition.label,
                        definition.options)
                end
            end, ErrorUtils.traceback)
            if not success then
                self:report(editor, "Could not register menu extension from plugin: " .. definition.plugin.id, message)
            end
        end
    end
end

function EditorPlugins:applyCommands(editor)
    for _, definition in ipairs(self.command_definitions) do
        if not definition.plugin.disabled then
            local success, message = xpcall(function()
                editor.command_registry:register(definition.id, definition)
            end, ErrorUtils.traceback)
            if not success then
                self:report(editor, "Could not register command from plugin: " .. definition.plugin.id, message)
            end
        end
    end
end

function EditorPlugins:createPanels(editor)
    for _, definition in ipairs(self.panel_definitions) do
        if not definition.plugin.disabled then
            local success, content = xpcall(function()
                return definition.content_factory(editor, definition.plugin)
            end, ErrorUtils.traceback)
            if success and isClass(content) and content:includes(EditorControl) then
                local options = TableUtils.copy(definition.options, true)
                options.region = nil
                if options.recoverable == nil then options.recoverable = true end
                local panel = EditorPanel(definition.panel_id, definition.title, content, options)
                panel.editor_plugin = definition.plugin
                panel.editor_plugin_id = definition.id
                editor.dockspace:registerPanel(panel, definition.region)
                definition.panel = panel
            else
                self:report(editor, "Could not create panel from editor plugin: " .. definition.plugin.id,
                    success and ("Panel '" .. definition.id .. "' did not return an EditorControl") or content)
            end
        end
    end
end

function EditorPlugins:getPlugin(id)
    return self.plugins[id]
end

function EditorPlugins:require(plugin_id, path, ...)
    local plugin = assert(self.plugins[plugin_id], "Unknown editor plugin: " .. tostring(plugin_id))
    return plugin:require(path, ...)
end

function EditorPlugins:getPlugins()
    return self.plugin_order
end

function EditorPlugins:shutdown(editor)
    for _, plugin in ipairs(self.plugin_order) do self:disablePlugin(plugin) end
    self:clearPluginHooks()
    if self.editor == editor then self.editor = nil end
end

return EditorPlugins
