--- Finds editor-format files. Maps/Worlds/Tilesets by default.
---@class EditorFormatDiscovery
local EditorFormatDiscovery = {}

local function getContentDirectories(relative_path)
    local result = {}
    local function add(path)
        if love.filesystem.getInfo(path, "directory") then table.insert(result, path) end
    end
    add(relative_path)
    add("scripts/" .. relative_path)
    if Mod then
        for _, library in Kristal.iterLibraries() do
            if library.info and library.info.path then add(library.info.path .. "/scripts/" .. relative_path) end
        end
        add(Mod.info.path .. "/scripts/" .. relative_path)
    end
    return result
end

local function discover(relative_path, extension, decoder, callback)
    for _, directory in ipairs(getContentDirectories(relative_path)) do
        for _, relative in ipairs(FileSystemUtils.getFilesRecursive(directory, extension)) do
            local path = directory .. "/" .. relative .. extension
            local source, read_error = love.filesystem.read(path)
            if not source then error(string.format("Could not read '%s': %s", path, tostring(read_error)), 2) end
            local data, reason = decoder(source, path)
            if not data then error(reason, 2) end
            callback(data, relative, path)
        end
    end
end

function EditorFormatDiscovery.registerMaps(registry)
    discover(registry.paths.maps, EditorFormat.MAP_EXTENSION, EditorFormat.decodeMap,
        function(data, relative, path)
            data.id = data.id or relative
            data.full_path = path
            registry.registerMapData(data.id, data, EditorMapReader)
        end)
end

function EditorFormatDiscovery.registerTilesets(registry)
    discover(registry.paths.tilesets, EditorFormat.TILESET_EXTENSION, EditorFormat.decodeTileset,
        function(data, relative, path)
            data.id = data.id or relative
            data.full_path = path
            data.__tileset_reader = EditorTilesetReader
            registry.registerTileset(data.id, Tileset(data, path, FileSystemUtils.getDirname(path)))
        end)
end

function EditorFormatDiscovery.registerWorlds(registry)
    discover(EditorFormat.WORLD_DIRECTORY, EditorFormat.WORLD_EXTENSION, EditorFormat.decodeWorld,
        function(data, relative, path)
            data.id = data.id or relative
            data.full_path = path
            local world = EditorWorld(data.id)
            world.name = data.name or data.id
            world.data = data
            world.properties = data.properties or {}
            world.__editor_property_types = data.__editor_property_types or {}
            for _, map in ipairs(data.maps or {}) do
                world:addMap(map.map, map.x, map.y, { explicit_companion = true })
            end
            registry.registerEditorWorld(data.id, world)
        end)
end

return EditorFormatDiscovery
