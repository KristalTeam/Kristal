---@class EditorWorkspaceController : Class
---@field editor Editor
---@overload fun(editor: Editor): EditorWorkspaceController
local EditorWorkspaceController = Class()

function EditorWorkspaceController:init(editor)
    self.editor = editor
end

function EditorWorkspaceController:getSwitchableProjects()
    local self = self.editor
    local projects = {}
    for _, project in ipairs(Kristal.Mods.getMods()) do
        if project.id ~= self.project_id and project.hidden ~= true then
            table.insert(projects, project)
        end
    end
    table.sort(projects, function(first, second)
        local first_name = tostring(first.name or first.id):lower()
        local second_name = tostring(second.name or second.id):lower()
        if first_name ~= second_name then return first_name < second_name end
        return tostring(first.id) < tostring(second.id)
    end)
    return projects
end

function EditorWorkspaceController:hasSwitchableProjects()
    local self = self.editor
    return #self:getSwitchableProjects() > 0
end

function EditorWorkspaceController:openProjectSwitcher()
    local self = self.editor
    local items = {}
    for _, project in ipairs(self:getSwitchableProjects()) do
        local selected = project
        local name = tostring(selected.name or selected.id)
        local label = name == selected.id and name or (name .. " [" .. selected.id .. "]")
        table.insert(items, {
            label = label,
            search_text = table.concat({ name, tostring(selected.id), tostring(selected.path or "") }, " "),
            action = function() self:beginProjectSwitch(selected.id) end
        })
    end
    if #items == 0 then return false end
    self.menu_bar.open_menu = nil
    local width = math.min(620, math.max(360, self.dockspace.width - 24))
    local x = self.dockspace.x + math.floor((self.dockspace.width - width) / 2)
    return self.dockspace:openContextMenu(items, x, self.dockspace.y + 18, self, {
        searchable = true,
        maximum_rows = 14,
        width = width,
        placeholder = "Search projects..."
    })
end

function EditorWorkspaceController:beginProjectSwitch(id)
    local self = self.editor
    if type(id) ~= "string" or id == "" or id == self.project_id
        or not Kristal.Mods.getMod(id) then return false end
    self.pending_project_switch_id = id
    local started = self:beginExitTransition()
    if not started then self.pending_project_switch_id = nil end
    return started
end

function EditorWorkspaceController:openCommandPalette()
    local self = self.editor
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

function EditorWorkspaceController:getWorkspaceDisplayName(workspace)
    local self = self.editor
    if workspace.user then return workspace.name .. " (Saved)" end
    if workspace.owner then
        local plugin_name = workspace.owner.info and workspace.owner.info.name or workspace.owner.id
        return workspace.name .. " (" .. tostring(plugin_name) .. ")"
    end
    return workspace.name
end

function EditorWorkspaceController:applyWorkspace(id)
    local self = self.editor
    local workspace = self.workspace_registry and self.workspace_registry:get(id)
    if not workspace then return false end
    local layout, reason = self.workspace_registry:resolveLayout(workspace)
    if not layout then
        self:addWarning("Could not load workspace '" .. tostring(workspace.name) .. "': "
            .. tostring(reason), nil, "editor_workspace")
        return false
    end
    local success, message = xpcall(function() self:restoreLayout(layout) end, ErrorUtils.traceback)
    if not success then
        self:addWarning("Could not apply workspace '" .. tostring(workspace.name) .. "'",
            message, "editor_workspace")
        return false
    end
    self.active_workspace_id = id
    self.message_bar:setStatus("Workspace: " .. workspace.name)
    return true
end

function EditorWorkspaceController:openWorkspacePicker()
    local self = self.editor
    if not self.workspace_registry then return false end
    local workspaces = self.workspace_registry:getAll()
    table.sort(workspaces, function(a, b)
        local a_group = a.core and 1 or a.user and 2 or 3
        local b_group = b.core and 1 or b.user and 2 or 3
        if a_group ~= b_group then return a_group < b_group end
        return a.name:lower() < b.name:lower()
    end)
    local items = {}
    for _, registered in ipairs(workspaces) do
        local workspace = registered
        local label = self:getWorkspaceDisplayName(workspace)
        table.insert(items, {
            label = label,
            search_text = table.concat({ workspace.name, label, workspace.id }, " "),
            checked = workspace.id == self.active_workspace_id,
            action = function() self:applyWorkspace(workspace.id) end
        })
    end
    if #items == 0 then return false end
    self.menu_bar.open_menu = nil
    local width = math.min(520, math.max(320, self.dockspace.width - 24))
    local x = self.dockspace.x + math.floor((self.dockspace.width - width) / 2)
    return self.dockspace:openContextMenu(items, x, self.dockspace.y + 18, self, {
        searchable = true,
        maximum_rows = 14,
        width = width,
        placeholder = "Search workspaces..."
    })
end

function EditorWorkspaceController:openSaveWorkspaceDialog()
    local self = self.editor
    if not self.workspace_registry then return false end
    local active = self.workspace_registry:get(self.active_workspace_id)
    local default_name = active and active.user and active.name or "Workspace"
    return self:openCreationDialog({
        title = "Save Current Workspace",
        create_label = "Save",
        templates = { {
            id = "workspace",
            category = "Workspace",
            name = "Workspace",
            variables = { {
                id = "name", name = "Name", type = "string", code_name = false
            } }
        } },
        context = { defaults = { name = default_name } },
        on_create = function(values)
            local name = StringUtils.trim(tostring(values.name or ""))
            if name == "" then return false, "Workspace name cannot be empty" end
            local existing = self.workspace_registry:findUserByName(name)
            if existing then
                local pressed = love.window.showMessageBox(
                    "Overwrite Workspace",
                    "Replace the saved workspace '" .. existing.name .. "' with the current layout?",
                    { "Overwrite", "Cancel", enterbutton = 1, escapebutton = 2 },
                    "warning",
                    true
                )
                if pressed ~= 1 then return false, "Choose another name or cancel" end
            end
            local workspace, reason = self.workspace_registry:saveCurrent(name)
            if not workspace then return false, reason end
            self.active_workspace_id = workspace.id
            return true
        end
    })
end

function EditorWorkspaceController:openDeleteWorkspacePicker()
    local self = self.editor
    if not self.workspace_registry then return false end
    local workspaces = self.workspace_registry:getUserWorkspaces()
    table.sort(workspaces, function(a, b) return a.name:lower() < b.name:lower() end)
    local items = {}
    for _, registered in ipairs(workspaces) do
        local workspace = registered
        table.insert(items, {
            label = workspace.name,
            search_text = workspace.name .. " " .. workspace.id,
            action = function()
                local pressed = love.window.showMessageBox(
                    "Delete Workspace",
                    "Delete the saved workspace '" .. workspace.name .. "'?",
                    { "Delete", "Cancel", enterbutton = 2, escapebutton = 2 },
                    "warning",
                    true
                )
                if pressed ~= 1 then return end
                local deleted, reason = self.workspace_registry:deleteUser(workspace.id)
                if not deleted then
                    self:addWarning("Could not delete workspace '" .. workspace.name .. "': "
                        .. tostring(reason), nil, "editor_workspace")
                    return
                end
                if self.active_workspace_id == workspace.id then self.active_workspace_id = nil end
                self.message_bar:setStatus("Deleted workspace: " .. workspace.name)
            end
        })
    end
    if #items == 0 then return false end
    self.menu_bar.open_menu = nil
    local width = math.min(460, math.max(300, self.dockspace.width - 24))
    local x = self.dockspace.x + math.floor((self.dockspace.width - width) / 2)
    return self.dockspace:openContextMenu(items, x, self.dockspace.y + 18, self, {
        searchable = true,
        maximum_rows = 12,
        width = width,
        placeholder = "Search saved workspaces..."
    })
end

return EditorWorkspaceController

