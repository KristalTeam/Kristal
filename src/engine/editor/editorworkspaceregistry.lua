---@class EditorWorkspaceRegistry : Class
---@overload fun(editor: Editor): EditorWorkspaceRegistry
local EditorWorkspaceRegistry = Class()

EditorWorkspaceRegistry.VERSION = 1
EditorWorkspaceRegistry.PATH = "editor/workspaces.json"

local function workspaceSlug(name)
    local id = StringUtils.trim(tostring(name or "")):lower()
        :gsub("[^%w%._%-]+", "_"):gsub("^_+", ""):gsub("_+$", "")
    return id ~= "" and id or "workspace"
end

function EditorWorkspaceRegistry:init(editor)
    self.editor = editor
    self.workspaces = {}
    self.order = {}
    self.user_order = {}
end

function EditorWorkspaceRegistry:register(id, definition)
    assert(type(id) == "string" and id ~= "", "Editor workspaces require an id")
    assert(type(definition) == "table", "Editor workspaces require a definition")
    local layout = definition.layout or definition.get_layout
    assert(type(layout) == "table" or type(layout) == "function",
        "Editor workspaces require a layout table or callback")
    assert(not self.workspaces[id], "Duplicate editor workspace id: " .. id)

    local workspace = TableUtils.copy(definition, false)
    workspace.id = id
    workspace.name = workspace.name or StringUtils.titleCase(id:gsub("[_%-]", " "))
    workspace.layout = layout
    workspace.get_layout = nil
    self.workspaces[id] = workspace
    table.insert(self.order, id)
    if workspace.user then table.insert(self.user_order, id) end
    return workspace
end

function EditorWorkspaceRegistry:remove(id, workspace)
    local registered = self.workspaces[id]
    if not registered or workspace and registered ~= workspace then return false end
    self.workspaces[id] = nil
    TableUtils.removeValue(self.order, id)
    TableUtils.removeValue(self.user_order, id)
    return true
end

function EditorWorkspaceRegistry:get(id)
    return self.workspaces[id]
end

function EditorWorkspaceRegistry:getAll()
    local result = {}
    for _, id in ipairs(self.order) do
        local workspace = self.workspaces[id]
        if workspace then table.insert(result, workspace) end
    end
    return result
end

function EditorWorkspaceRegistry:getUserWorkspaces()
    local result = {}
    for _, id in ipairs(self.user_order) do
        local workspace = self.workspaces[id]
        if workspace then table.insert(result, workspace) end
    end
    return result
end

function EditorWorkspaceRegistry:resolveLayout(workspace)
    if type(workspace) == "string" then workspace = self:get(workspace) end
    if not workspace then return nil, "Unknown editor workspace" end
    local success, layout = pcall(function()
        if type(workspace.layout) == "function" then
            return workspace.layout(self.editor, workspace)
        end
        return workspace.layout
    end)
    if not success then return nil, tostring(layout) end
    if type(layout) ~= "table" then
        return nil, "Workspace '" .. tostring(workspace.name) .. "' did not provide a layout"
    end
    return TableUtils.copy(layout, true)
end

function EditorWorkspaceRegistry:findUserByName(name)
    local normalized = StringUtils.trim(tostring(name or "")):lower()
    for _, workspace in ipairs(self:getUserWorkspaces()) do
        if workspace.name:lower() == normalized then return workspace end
    end
end

function EditorWorkspaceRegistry:saveCurrent(name)
    name = StringUtils.trim(tostring(name or ""))
    if name == "" then return nil, "Workspace name cannot be empty" end
    local existing = self:findUserByName(name)
    local id = existing and existing.id or ("user:" .. workspaceSlug(name))
    local suffix = 2
    while self.workspaces[id] and not (existing and self.workspaces[id] == existing) do
        id = "user:" .. workspaceSlug(name) .. "_" .. suffix
        suffix = suffix + 1
    end
    if existing then self:remove(existing.id, existing) end
    local workspace = self:register(id, {
        name = name,
        layout = self.editor:captureLayout(),
        user = true
    })
    local saved, reason = self:save()
    if not saved then
        self:remove(id, workspace)
        if existing then
            self:register(existing.id, existing)
        end
        return nil, reason
    end
    return workspace
end

function EditorWorkspaceRegistry:deleteUser(id)
    local workspace = self.workspaces[id]
    if not workspace or not workspace.user then return false, "Unknown saved workspace" end
    self:remove(id, workspace)
    local saved, reason = self:save()
    if not saved then
        self:register(id, workspace)
        return false, reason
    end
    return true
end

function EditorWorkspaceRegistry:load()
    if not love.filesystem.getInfo(self.PATH, "file") then return true end
    local success, data = pcall(function()
        return JSON.decode(love.filesystem.read(self.PATH))
    end)
    if not success then return false, tostring(data) end
    if type(data) ~= "table" or type(data.workspaces) ~= "table" then
        return false, "Expected a workspace collection"
    end
    if type(data.version) == "number" and data.version > self.VERSION then
        return false, "Workspace collection was created by a newer editor version"
    end
    for _, saved in ipairs(data.workspaces) do
        if type(saved) == "table" and type(saved.id) == "string"
            and type(saved.name) == "string" and type(saved.layout) == "table" then
            local id = "user:" .. workspaceSlug(saved.id)
            if not self.workspaces[id] then
                self:register(id, {
                    name = saved.name,
                    layout = saved.layout,
                    user = true
                })
            end
        end
    end
    return true
end

function EditorWorkspaceRegistry:save()
    local data = { version = self.VERSION, workspaces = {} }
    for _, workspace in ipairs(self:getUserWorkspaces()) do
        table.insert(data.workspaces, {
            id = workspace.id:gsub("^user:", ""),
            name = workspace.name,
            layout = workspace.layout
        })
    end
    local success, encoded = pcall(JSON.encode, data)
    if not success then return false, tostring(encoded) end
    love.filesystem.createDirectory("editor")
    local written, reason = love.filesystem.write(self.PATH, encoded)
    if not written then return false, tostring(reason) end
    return true
end

return EditorWorkspaceRegistry
