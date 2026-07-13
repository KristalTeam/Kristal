---@class ProjectFileSystem
local ProjectFileSystem = {}

function ProjectFileSystem.normalizePath(path)
    path = tostring(path or ""):gsub("\\", "/"):gsub("/+", "/")
    if path == "" or path:sub(1, 1) == "/" or path:match("^%a:/") then
        return nil, "Project paths must be relative"
    end
    for segment in path:gmatch("[^/]+") do
        if segment == "." or segment == ".." then return nil, "Project path escapes the project" end
    end
    return path
end

local function quoteDirectory(path)
    if love.system.getOS() == "Windows" then
        if path:find('[%%!\"]') then return nil end
        return '"' .. path:gsub("/", "\\") .. '"'
    end
    return "'" .. path:gsub("'", "'\\''") .. "'"
end

function ProjectFileSystem.createDirectory(path)
    local quoted = quoteDirectory(path)
    if not quoted then return false, "Project directory contains unsupported shell characters" end
    local command = love.system.getOS() == "Windows"
        and ("mkdir " .. quoted .. " >NUL 2>NUL")
        or ("mkdir -p " .. quoted .. " >/dev/null 2>&1")
    os.execute(command)
    local probe = io.open(path .. "/.kristal_editor_write_probe", "wb")
    if not probe then return false, "Could not create project directory '" .. path .. "'" end
    probe:close()
    os.remove(path .. "/.kristal_editor_write_probe")
    return true
end

function ProjectFileSystem.getRealPath(path)
    local normalized, reason = ProjectFileSystem.normalizePath(path)
    if not normalized then return nil, reason end
    if not Mod or not Mod.info or not Mod.info.path then return nil, "No project is loaded" end
    local project_path = Mod.info.path:gsub("\\", "/"):gsub("/+$", "")
    if normalized ~= project_path and not StringUtils.startsWith(normalized, project_path .. "/") then
        return nil, "Path is outside the active project"
    end
    local real_root = love.filesystem.getRealDirectory(project_path)
    if not real_root then return nil, "Could not locate the active project on disk" end
    return real_root:gsub("\\", "/"):gsub("/+$", "") .. "/" .. normalized
end

function ProjectFileSystem.getProjectPath(path)
    local normalized, reason = ProjectFileSystem.normalizePath(path or "")
    if not normalized then return nil, reason end
    if not Mod or not Mod.info or not Mod.info.path then return nil, "No project is loaded" end
    local project_path = Mod.info.path:gsub("\\", "/"):gsub("/+$", "")
    if normalized == project_path or StringUtils.startsWith(normalized, project_path .. "/") then
        return normalized
    end
    return project_path .. "/" .. normalized
end

function ProjectFileSystem.getRealProjectRoot()
    if not Mod or not Mod.info or not Mod.info.path then return nil, "No project is loaded" end
    return ProjectFileSystem.getRealPath(Mod.info.path)
end

function ProjectFileSystem.readFile(path)
    local normalized, reason = ProjectFileSystem.normalizePath(path)
    if not normalized then return nil, reason end
    local real_path
    real_path, reason = ProjectFileSystem.getRealPath(normalized)
    if not real_path then return nil, reason end
    local file, open_error = io.open(real_path, "rb")
    if not file then return nil, open_error or ("Could not open '" .. normalized .. "'") end
    local contents = file:read("*a")
    local closed, close_error = file:close()
    if not closed then return nil, close_error end
    return contents
end

function ProjectFileSystem.getInfo(path)
    local normalized, reason = ProjectFileSystem.normalizePath(path)
    if not normalized then return nil, reason end
    local info = love.filesystem.getInfo(normalized)
    if not info then return nil, "Project path does not exist: " .. normalized end
    return info
end

function ProjectFileSystem.getDirectoryItems(path)
    local normalized, reason = ProjectFileSystem.normalizePath(path)
    if not normalized then return nil, reason end
    local info = love.filesystem.getInfo(normalized)
    if not info or info.type ~= "directory" then return nil, "Not a project directory: " .. normalized end
    local success, items = pcall(love.filesystem.getDirectoryItems, normalized)
    if not success then return nil, items end
    table.sort(items, function(a, b) return a:lower() < b:lower() end)
    return items
end

function ProjectFileSystem.createProjectDirectory(path)
    local real_path, reason = ProjectFileSystem.getRealPath(path)
    if not real_path then return false, reason end
    return ProjectFileSystem.createDirectory(real_path)
end

function ProjectFileSystem.rename(path, destination)
    local real_path, reason = ProjectFileSystem.getRealPath(path)
    if not real_path then return false, reason end
    local real_destination
    real_destination, reason = ProjectFileSystem.getRealPath(destination)
    if not real_destination then return false, reason end
    if love.filesystem.getInfo(destination) then return false, "Destination already exists" end
    local created
    created, reason = ProjectFileSystem.createDirectory(FileSystemUtils.getDirname(real_destination))
    if not created then return false, reason end
    local moved, move_error = os.rename(real_path, real_destination)
    if not moved then return false, move_error or "Could not rename project path" end
    return true
end

local function removeRecursive(virtual_path, real_path)
    local info = love.filesystem.getInfo(virtual_path)
    if not info then return true end
    if info.type == "directory" then
        for _, item in ipairs(love.filesystem.getDirectoryItems(virtual_path)) do
            local success, reason = removeRecursive(virtual_path .. "/" .. item, real_path .. "/" .. item)
            if not success then return false, reason end
        end
    end
    local removed, reason = os.remove(real_path)
    return removed ~= nil, reason
end

function ProjectFileSystem.remove(path)
    local normalized, reason = ProjectFileSystem.normalizePath(path)
    if not normalized then return false, reason end
    if Mod and Mod.info and normalized == Mod.info.path:gsub("\\", "/"):gsub("/+$", "") then
        return false, "The active project root cannot be removed"
    end
    local real_path
    real_path, reason = ProjectFileSystem.getRealPath(normalized)
    if not real_path then return false, reason end
    return removeRecursive(normalized, real_path)
end

function ProjectFileSystem.writeFile(path, contents)
    local real_path, reason = ProjectFileSystem.getRealPath(path)
    if not real_path then return false, reason end
    local created
    created, reason = ProjectFileSystem.createDirectory(FileSystemUtils.getDirname(real_path))
    if not created then return false, reason end

    local temporary = real_path .. ".kristal-tmp"
    local backup = real_path .. ".kristal-backup"
    local file, open_error = io.open(temporary, "wb")
    if not file then return false, open_error or ("Could not open '" .. temporary .. "'") end
    local written, write_error = file:write(contents)
    local closed, close_error = file:close()
    if not written or not closed then
        os.remove(temporary)
        return false, write_error or close_error or "Could not finish writing project file"
    end

    os.remove(backup)
    local existing = io.open(real_path, "rb")
    if existing then
        existing:close()
        local moved, move_error = os.rename(real_path, backup)
        if not moved then os.remove(temporary) return false, move_error end
    end
    local replaced, replace_error = os.rename(temporary, real_path)
    if not replaced then
        os.rename(backup, real_path)
        os.remove(temporary)
        return false, replace_error or "Could not replace project file"
    end
    os.remove(backup)
    return true
end

return ProjectFileSystem
