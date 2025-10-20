---@class FileSystemUtils
local FileSystemUtils = {}

---
--- Returns a table of file names within the specified directory, checking subfolders as well.
---
---@param dir string       # The file path to check, relative to the LÖVE Kristal directory.
---@param ext? string      # If specified, only files with the specified extension will be returned, and the extension will be stripped. (eg. `"png"` will only return .png files)
---@return string[] result # The table of file names.
---
function FileSystemUtils.getFilesRecursive(dir, ext)
    local result = {}

    -- Get all files and folders within the specified directory
    local paths = love.filesystem.getDirectoryItems(dir)
    for _, path in ipairs(paths) do
        local info = love.filesystem.getInfo(dir .. "/" .. path)

        if info.type == "directory" then
            -- If the path is a folder, recursively get all files within that folder
            local inners = FileSystemUtils.getFilesRecursive(dir .. "/" .. path, ext)
            for _, inner in ipairs(inners) do
                -- Append the current folder path to files from the subfolder
                table.insert(result, path .. "/" .. inner)
            end
        elseif not ext or path:sub(-#ext) == ext then
            -- If the path is a file, add it to the result table.
            -- If an extension is specified, only add files with that extension,
            -- and remove the extension from the file name.
            table.insert(result, ext and path:sub(1, -#ext - 1) or path)
        end
    end

    return result
end

-- TODO: Merge with getFilesRecursive?
function FileSystemUtils.findFiles(folder, base, path)
    -- getDirectoryItems but recursive.
    -- The base argument is solely to remove stuff.
    -- The path is what we should append to the start of the file name.

    local base_folder = base or (folder .. "/")
    local path = path or ""
    local files = {}
    for _, f in ipairs(love.filesystem.getDirectoryItems(folder)) do
        local info = love.filesystem.getInfo(folder .. "/" .. f)
        if info.type == "directory" then
            table.insert(files, path .. (f:gsub(base_folder, "", 1)))
            local new_path = path .. f .. "/"
            for _, ff in ipairs(FileSystemUtils.findFiles(folder .. "/" .. f, base_folder, new_path)) do
                table.insert(files, (ff:gsub(base_folder, "", 1)))
            end
        else
            table.insert(files, ((folder .. "/" .. f):gsub(base_folder, "", 1)))
        end
    end
    return files
end

---@param path string
---@return string dirname
---@see https://stackoverflow.com/a/12191225
function FileSystemUtils.getDirname(path)
    ---@type string
    local dirname, _, _ = string.match(path, "(.-)([^/]-%.?([^%./]*))$")
    local trailing_slashes = dirname:find("/+$", 2)
    if trailing_slashes then dirname = dirname:sub(1, trailing_slashes - 1) end
    return dirname
end

return FileSystemUtils
