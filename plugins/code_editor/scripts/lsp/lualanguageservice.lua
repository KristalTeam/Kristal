---@class LuaLanguageService : Class
---@field channel_prefix string
---@field client EditorLSPClient
---@field editor Editor
---@field enabled boolean
---@field executable string?
---@field input love.Channel
---@field last_error string?
---@field last_log string?
---@field library_roots table
---@field open_documents table
---@field output love.Channel
---@field plugin EditorPlugin
---@field position_encoding string
---@field server_capabilities table
---@field shutting_down boolean
---@field status string?
---@field stderr string
---@field thread love.Thread?
---@field workspace EditorProjectWorkspace
---@overload fun(editor: Editor, workspace: EditorProjectWorkspace): LuaLanguageService
local LuaLanguageService = Class()
local EditorLSPClient, plugin = ...

local function pathToUri(path)
    path = path:gsub("\\", "/")
    if path:match("^%a:/") then path = "/" .. path end
    path = path:gsub("([^%w%-%._~/:])", function(character)
        return string.format("%%%02X", character:byte())
    end)
    return "file://" .. path
end

local function uriToPath(uri)
    local path = tostring(uri or ""):gsub("^file://", "")
    path = path:gsub("%%(%x%x)", function(hex) return string.char(tonumber(hex, 16)) end)
    if love.system.getOS() == "Windows" then
        path = path:gsub("^/(%a:/)", "%1"):gsub("/", "\\")
    end
    return path
end

local function isFile(path)
    local file = io.open(path, "rb")
    if not file then return false end
    file:close()
    return true
end

local function executableFromPath(name)
    local separator = love.system.getOS() == "Windows" and ";" or ":"
    local suffixes = love.system.getOS() == "Windows" and { ".exe", ".cmd", ".bat", "" } or { "" }
    for directory in tostring(os.getenv("PATH") or ""):gmatch("[^" .. separator .. "]+") do
        directory = directory:gsub('^"', ""):gsub('"$', "")
        for _, suffix in ipairs(suffixes) do
            local path = directory:gsub("[\\/]+$", "") .. "/" .. name .. suffix
            if isFile(path) then return path end
        end
    end
end

local function encodedCharacter(line_text, byte_character, encoding)
    if encoding ~= "utf-16" then return byte_character end
    local prefix = line_text:sub(1, byte_character)
    local units = 0
    for _, codepoint in utf8.codes(prefix) do units = units + (codepoint > 0xFFFF and 2 or 1) end
    return units
end

local function locationRange(location)
    return location.targetSelectionRange or location.targetRange or location.range
end

local function formatDiagnosticMessage(diagnostic)
    local message = tostring(diagnostic.message or "Lua problem")
    local code = type(diagnostic.code) == "string" and diagnostic.code or ""
    if code == "miss-sep-in-table" then
        return "Expected `,` or `;` between table entries."
    elseif code == "miss-end" then
        return "Expected a matching `end`."
    elseif code == "miss-name" then
        return "Expected a name."
    elseif code == "miss-exp" then
        return "Expected an expression."
    elseif code == "miss-field" then
        return "Expected a field."
    elseif code == "miss-method" then
        return "Expected a method name."
    elseif code == "miss-symbol" then
        local symbol = message:match("`([^`]+)`")
        return symbol and ("Expected `" .. symbol .. "`.") or "Expected another symbol here."
    end
    message = message:gsub("^Missed? symbol", "Expected")
        :gsub("^Missed? corresponding", "Expected matching")
        :gsub("^Missed? ", "Expected ")
        :gsub("^Should use", "Use")
        :gsub("%s+([%.,])", "%1")
    return message
end

function LuaLanguageService:init(editor, workspace)
    self.editor = editor
    self.workspace = workspace
    self.plugin = plugin
    self.enabled = plugin.language_server_enabled ~= false
    self.status = self.enabled and "stopped" or "disabled"
    self.server_capabilities = {}
    self.position_encoding = "utf-16"
    self.open_documents = {}
    self.stderr = ""
    self.shutting_down = false
    if self.enabled then self:start() end
end

function LuaLanguageService:findExecutable()
    local configured = StringUtils.trim(self.plugin.language_server_path or "")
    if configured ~= "" then
        if isFile(configured) then return configured end
        return nil, "Configured LuaLS executable does not exist: " .. configured
    end
    local managed = love.filesystem.getSaveDirectory():gsub("\\", "/")
        .. "/editor/tools/luals/current/bin/lua-language-server"
    if love.system.getOS() == "Windows" then managed = managed .. ".exe" end
    if isFile(managed) then return managed end
    local discovered = executableFromPath("lua-language-server")
    if discovered then return discovered end
    return nil, "LuaLS was not found. Set its executable path in Editor Settings > Language Server."
end

function LuaLanguageService:start()
    if not self.enabled or self.thread then return false end
    local executable, reason = self:findExecutable()
    if not executable then
        self.status = "unavailable"
        self.last_error = reason
        self.editor:addWarning("Lua Language Server is unavailable", reason, "luals")
        return false
    end
    love.filesystem.createDirectory("editor/luals/logs")
    self.executable = executable
    self.channel_prefix = "editor_lsp_" .. tostring(love.timer.getTime()):gsub("%D", "")
    self.input = love.thread.getChannel(self.channel_prefix .. ":input")
    self.output = love.thread.getChannel(self.channel_prefix .. ":output")
    self.input:clear() self.output:clear()
    local args = {
        "--logpath=" .. love.filesystem.getSaveDirectory():gsub("\\", "/") .. "/editor/luals/logs",
        "--loglevel=warn"
    }
    local transport_path = self.plugin.info.path .. "/scripts/lsp/transportthread.lua"
    self.thread = love.thread.newThread(transport_path)
    self.thread:start(self.channel_prefix, executable, JSON.encode(args), self.workspace.real_root,
        self.plugin.info.path)
    self.client = EditorLSPClient(function(encoded)
        if not self.input then return false end
        self.input:push("send\n" .. encoded)
        return true
    end, self:createHandlers())
    self.status = "starting"
    self.shutting_down = false
    return true
end

function LuaLanguageService:createHandlers()
    return {
        ["textDocument/publishDiagnostics"] = function(params) self:publishDiagnostics(params) end,
        ["window/logMessage"] = function(params) self:logMessage(params) end,
        ["window/showMessage"] = function(params) self:showMessage(params) end,
        ["workspace/configuration"] = function(params) return self:configurationResponse(params) end,
        ["window/workDoneProgress/create"] = function() return JSON.null end,
        ["client/registerCapability"] = function() return JSON.null end,
        ["client/unregisterCapability"] = function() return JSON.null end,
        protocolError = function(message)
            self.editor:addError("LuaLS protocol error", message, "luals")
        end
    }
end

function LuaLanguageService:getSettings()
    local engine_root = love.filesystem.getRealDirectory("main.lua")
    local libraries = {}
    if engine_root then
        engine_root = engine_root:gsub("\\", "/"):gsub("/+$", "")
        if isFile(engine_root .. "/main.lua") then
            table.insert(libraries, engine_root)
        end
    end
    local executable = tostring(self.executable or ""):gsub("\\", "/")
    local server_root = executable:match("^(.*)/bin/[^/]+$")
    local love_library = server_root and (server_root .. "/meta/3rd/love2d/library") or nil
    if love_library and isFile(love_library .. "/love.lua") then
        table.insert(libraries, love_library)
    end
    self.library_roots = libraries
    return {
        Lua = {
            runtime = {
                version = "LuaJIT",
                builtin = { utf8 = "enable" },
                special = {
                    ["love.filesystem.load"] = "loadfile",
                    modRequire = "require",
                    libRequire = "require",
                    pluginRequire = "require"
                }
            },
            workspace = {
                library = libraries,
                ignoreDir = {
                    "/.github/", "/.vscode/", "/assets/", "/build/", "/configs/",
                    "/data/", "/data_templates/", "/docs/", "/lib/", "/mod_template/",
                    "/mods/", "/output/", "/conf.lua", "/luadoc_meta/.buildDocs.lua"
                },
                checkThirdParty = "Disable"
            },
            diagnostics = {
                workspaceEvent = "OnChange",
                disable = { "duplicate-set-field", "need-check-nil", "assign-type-mismatch" }
            },
            type = { weakUnionCheck = true, weakNilCheck = true },
            telemetry = { enable = false }
        }
    }
end

function LuaLanguageService:configurationResponse(params)
    local settings = self:getSettings()
    local result = {}
    for _, item in ipairs(params.items or {}) do
        local value = settings
        for part in tostring(item.section or ""):gmatch("[^%.]+") do value = type(value) == "table" and value[part] end
        table.insert(result, value or JSON.null)
    end
    return result
end

function LuaLanguageService:initialize()
    self.status = "initializing"
    local root_uri = pathToUri(self.workspace.real_root)
    self.client:request("initialize", {
        clientInfo = { name = "Kristal Editor", version = tostring(Kristal.Version) },
        rootUri = root_uri,
        workspaceFolders = { { uri = root_uri, name = tostring(Mod.info.name or Mod.info.id) } },
        capabilities = {
            general = { positionEncodings = { "utf-8", "utf-16" } },
            workspace = { configuration = true, workspaceFolders = true, applyEdit = true },
            textDocument = {
                synchronization = { dynamicRegistration = true, didSave = true },
                publishDiagnostics = { relatedInformation = true, versionSupport = true },
                completion = {
                    contextSupport = true,
                    completionItem = {
                        documentationFormat = { "markdown", "plaintext" },
                        snippetSupport = false,
                        insertReplaceSupport = true
                    }
                },
                hover = { contentFormat = { "markdown", "plaintext" } },
                definition = { linkSupport = true },
                references = JSON.object({}), rename = { prepareSupport = true },
                formatting = JSON.object({})
            }
        }
    }, function(result, response_error)
        if response_error then
            self.status = "error"
            self.editor:addError("LuaLS initialization failed", response_error.message, "luals")
            return
        end
        self.server_capabilities = result and result.capabilities or {}
        self.position_encoding = self.server_capabilities.positionEncoding or "utf-16"
        self.client:notify("initialized", JSON.object({}))
        self.client:notify("workspace/didChangeConfiguration", { settings = self:getSettings() })
        self.status = "ready"
        self.editor:clearDiagnostics("luals")
        for _, document in ipairs(self.workspace.document_order) do self:openDocument(document, true) end
    end)
end

function LuaLanguageService:getProtocolPosition(document, position)
    local line_index = MathUtils.clamp(position and position.line or 1, 1, document.buffer:getLineCount())
    local line = document.buffer:getLine(line_index)
    local column = MathUtils.clamp(position and position.column or 1, 1, #line + 1)
    return {
        line = line_index - 1,
        character = encodedCharacter(line, column - 1, self.position_encoding)
    }
end

function LuaLanguageService:requestAtPosition(method, document, position, params, callback)
    if self.status ~= "ready" or not document or document.language_id ~= "lua" or not document.lsp_open then
        if callback then callback(nil, { message = "LuaLS is not ready for this document" }) end
        return nil
    end
    params = params or {}
    params.textDocument = { uri = pathToUri(document.real_path) }
    params.position = self:getProtocolPosition(document, position)
    local request, reason = self.client:request(method, params, function(result, response_error)
        if callback then callback(result, response_error) end
    end)
    if not request and callback then callback(nil, { message = tostring(reason or "Could not send request") }) end
    return request
end

function LuaLanguageService:requestCompletion(document, position, context, callback)
    return self:requestAtPosition("textDocument/completion", document, position, {
        context = context or { triggerKind = 1 }
    }, callback)
end

function LuaLanguageService:requestHover(document, position, callback)
    return self:requestAtPosition("textDocument/hover", document, position, nil, callback)
end

function LuaLanguageService:normalizeLocations(result, options)
    options = options or {}
    if result == nil or result == JSON.null then return {} end
    local locations = (result.uri or result.targetUri) and { result } or result
    if type(locations) ~= "table" then return {} end
    local normalized, seen, main_locations = {}, {}, {}
    local function addLocation(uri, path, range, destination)
        local key_path = path:gsub("\\", "/")
        if love.system.getOS() == "Windows" then key_path = key_path:lower() end
        local key = key_path .. ":" .. tostring(range.start.line or 0)
        if not options.redirect_engine_main then
            key = key .. ":" .. tostring(range.start.character or 0)
        end
        if seen[key] then return end
        seen[key] = true
        table.insert(destination, {
            uri = uri,
            path = path,
            range = range,
            label = self.workspace:getDisplayPath(path) .. ":" .. tostring((range.start.line or 0) + 1)
                .. ":" .. tostring((range.start.character or 0) + 1)
        })
    end
    for _, location in ipairs(locations) do
        local uri = location.targetUri or location.uri
        local range = locationRange(location)
        if type(uri) == "string" and type(range) == "table" and type(range.start) == "table" then
            local path = uriToPath(uri)
            local redirected_path, redirected_range
            if options.redirect_engine_main then
                redirected_path, redirected_range = self.workspace:resolveEngineMainDefinition(path, range)
            end
            if redirected_path or (options.redirect_engine_main and self.workspace:isEngineMainPath(path)) then
                table.insert(main_locations, {
                    uri = uri, path = path, range = range,
                    redirected_path = redirected_path, redirected_range = redirected_range
                })
            else
                addLocation(uri, path, range, normalized)
            end
        end
    end
    if #normalized > 0 or not options.redirect_engine_main then return normalized end

    for _, location in ipairs(main_locations) do
        local path, range = location.redirected_path, location.redirected_range
        if not path then path, range = self.workspace:resolveEngineMainDefinition(location.path, location.range) end
        if path then addLocation(pathToUri(path), path, range, normalized) end
    end
    if #normalized == 0 then
        for _, location in ipairs(main_locations) do
            addLocation(location.uri, location.path, location.range, normalized)
        end
    end
    return normalized
end

function LuaLanguageService:requestDefinition(document, position, callback)
    return self:requestAtPosition("textDocument/definition", document, position, nil,
        function(result, response_error)
            callback(self:normalizeLocations(result, { redirect_engine_main = true }), response_error)
        end)
end

function LuaLanguageService:requestReferences(document, position, callback)
    return self:requestAtPosition("textDocument/references", document, position, {
        context = { includeDeclaration = true }
    }, function(result, response_error)
        callback(self:normalizeLocations(result), response_error)
    end)
end

function LuaLanguageService:requestFormatting(document, options, callback)
    if self.status ~= "ready" or not document or document.language_id ~= "lua" or not document.lsp_open then
        if callback then callback(nil, { message = "LuaLS is not ready for this document" }) end
        return nil
    end
    local request, reason = self.client:request("textDocument/formatting", {
        textDocument = { uri = pathToUri(document.real_path) },
        options = options or { tabSize = 4, insertSpaces = true }
    }, function(result, response_error)
        if callback then callback(result, response_error) end
    end)
    if not request and callback then callback(nil, { message = tostring(reason or "Could not send request") }) end
    return request
end

function LuaLanguageService:openDocument(document, force)
    if document.language_id ~= "lua" then return false end
    self.open_documents[document.path] = document
    if self.status ~= "ready" or (document.lsp_open and not force) then return true end
    document.lsp_open = true
    self.client:notify("textDocument/didOpen", { textDocument = {
        uri = pathToUri(document.real_path), languageId = document.language_id,
        version = document.version, text = document:getText()
    } })
    return true
end

function LuaLanguageService:changeDocument(document, change)
    if document.language_id ~= "lua" or self.status ~= "ready" or not document.lsp_open then return false end
    local content_change = { text = change and change.text or document:getText() }
    if change and change.range then
        content_change.range = {
            start = {
                line = change.range.start.line,
                character = encodedCharacter(change.start_line_text or "",
                    change.range.start.character, self.position_encoding)
            },
            ["end"] = {
                line = change.range["end"].line,
                character = encodedCharacter(change.end_line_text or "",
                    change.range["end"].character, self.position_encoding)
            }
        }
    end
    self.client:notify("textDocument/didChange", {
        textDocument = { uri = pathToUri(document.real_path), version = document.version },
        contentChanges = { content_change }
    })
    return true
end

function LuaLanguageService:saveDocument(document)
    if document.language_id ~= "lua" or self.status ~= "ready" or not document.lsp_open then return false end
    self.client:notify("textDocument/didSave", {
        textDocument = { uri = pathToUri(document.real_path) }, text = document:getText()
    })
    return true
end

function LuaLanguageService:closeDocument(document)
    self.open_documents[document.path] = nil
    if document.lsp_open and self.status == "ready" then
        self.client:notify("textDocument/didClose", { textDocument = { uri = pathToUri(document.real_path) } })
    end
    document.lsp_open = nil
    return true
end

function LuaLanguageService:findDocumentByUri(uri)
    local function normalize(path)
        path = path:gsub("\\", "/")
        return love.system.getOS() == "Windows" and path:lower() or path
    end
    local path = normalize(uriToPath(uri))
    for _, document in ipairs(self.workspace.document_order) do
        if normalize(document.real_path) == path then return document end
    end
end

function LuaLanguageService:publishDiagnostics(params)
    local document = self:findDocumentByUri(params.uri)
    if not document then return end
    document.diagnostic_encoding = self.position_encoding
    document:setDiagnostics(params.diagnostics or {})
    local source = "luals:" .. document.path
    self.editor:clearDiagnostics(source)
    for _, diagnostic in ipairs(document.diagnostics) do
        if not diagnostic.severity or diagnostic.severity <= 2 then
            local severity = diagnostic.severity == 1 and "error" or "warning"
            local entry = self.editor:addDiagnostic(severity,
                document.relative_path .. ": " .. formatDiagnosticMessage(diagnostic),
                diagnostic.code and ("LuaLS " .. tostring(diagnostic.code)) or nil, source)
            entry.action = function()
                local start = diagnostic.range and diagnostic.range.start or {}
                self.editor:openDocument(document, {
                    line = start.line or 0,
                    character = start.character or 0,
                    encoding = self.position_encoding
                })
            end
        end
    end
end

function LuaLanguageService:logMessage(params)
    self.last_log = tostring(params.message or "")
end

function LuaLanguageService:showMessage(params)
    local message = tostring(params.message or "LuaLS message")
    if params.type == 1 then self.editor:addError(message, nil, "luals")
    elseif params.type == 2 then self.editor:addWarning(message, nil, "luals")
    elseif self.editor.message_bar then self.editor.message_bar:setStatus(message, 5) end
end

function LuaLanguageService:update()
    if not self.output then return end
    while true do
        local packet = self.output:pop()
        if not packet then break end
        local kind, value = packet:match("^([^\n]+)\n(.*)$")
        if kind == "ready" then
            self:initialize()
        elseif kind == "message" then
            self.client:receive(value)
        elseif kind == "stderr" then
            self.stderr = (self.stderr .. value):sub(-16000)
        elseif kind == "error" then
            self.status, self.last_error = "error", value
            self.editor:addError("Lua Language Server failed", value, "luals")
        elseif kind == "exit" then
            self.status = self.shutting_down and "stopped" or "error"
            self.last_error = value .. (self.stderr ~= "" and ("\n" .. self.stderr) or "")
            self.thread, self.input, self.output = nil, nil, nil
            if not self.shutting_down then
                self.editor:addError("Lua Language Server exited unexpectedly", self.last_error, "luals")
            end
            break
        end
    end
end

function LuaLanguageService:restart()
    self:shutdown(true)
    self.thread, self.input, self.output = nil, nil, nil
    for _, document in ipairs(self.workspace.document_order) do document.lsp_open = nil end
    self.status = self.enabled and "stopped" or "disabled"
    if self.enabled then return self:start() end
    return true
end

function LuaLanguageService:setEnabled(enabled)
    self.enabled = enabled == true
    if self.enabled then return self:restart() end
    self:shutdown(true)
    self.status = "disabled"
    return true
end

function LuaLanguageService:shutdown(force)
    if not self.thread then return true end
    self.shutting_down = true
    if self.status == "ready" and not force then
        self.client:request("shutdown", JSON.null, function()
            self.client:notify("exit", JSON.null)
        end)
    else
        self.input:push("stop")
    end
    if force then self.input:push("stop") end
    return true
end

function LuaLanguageService:getStatusText()
    local labels = {
        disabled = "LuaLS disabled", stopped = "LuaLS stopped", starting = "LuaLS starting...",
        initializing = "LuaLS initializing...", ready = "LuaLS ready", unavailable = "LuaLS unavailable",
        error = "LuaLS error"
    }
    return labels[self.status] or ("LuaLS " .. tostring(self.status))
end

return LuaLanguageService
