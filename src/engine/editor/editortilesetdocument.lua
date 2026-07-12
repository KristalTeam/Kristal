---@class EditorTilesetDocument : Class
---@overload fun(editor: table, id: string, tileset?: Tileset, data?: table): EditorTilesetDocument
local EditorTilesetDocument = Class()

local function findTileData(data, id)
    for _, tile in ipairs(data.tiles or {}) do if tile.id == id then return tile end end
    local tile = { id = id, properties = {}, __editor_property_types = {} }
    data.tiles = data.tiles or {}
    table.insert(data.tiles, tile)
    return tile
end

function EditorTilesetDocument:init(editor, id, tileset, data)
    self.editor = editor
    self.id = id
    self.tileset = tileset
    self.data = data or tileset and tileset.data
    if tileset and tileset.reader and tileset.reader.LEGACY_FORMAT then
        local converted, reason = EditorTilesetReader.convertLegacyData(self.data)
        if not converted then error(reason, 2) end
        self.data = converted
    end
    self.data = self.data or {
        name = id, tile_width = 40, tile_height = 40, tile_count = 0, tile_columns = 1,
        properties = {}, tiles = {}, terrains = {}
    }
    self.data.properties = self.data.properties or {}
    self.data.__editor_property_types = self.data.__editor_property_types or {}
    self.property_set = EditorPropertySet(self.data.properties, self.data.__editor_property_types)
    self.virtual = tileset == nil
    self.tile_documents = {}
    self.history_revision = 0
    self.saved_history_revision = 0
end

function EditorTilesetDocument:captureHistoryState()
    return { data = TableUtils.copy(self.data, true) }
end

function EditorTilesetDocument:restoreHistoryState(state)
    if not state then return false end
    self.data = TableUtils.copy(state.data, true)
    self.data.properties = self.data.properties or {}
    self.data.__editor_property_types = self.data.__editor_property_types or {}
    self.property_set = EditorPropertySet(self.data.properties, self.data.__editor_property_types)
    self.tile_documents = {}
    if self.tileset then self.tileset.data = self.data end
    return true
end

function EditorTilesetDocument:isDirty()
    return (self.history_revision or 0) ~= (self.saved_history_revision or 0)
end

function EditorTilesetDocument:getFormatContext()
    return EditorFormatDocument.getTilesetContext(self)
end

function EditorTilesetDocument:buildEditorFormatData(options)
    return EditorFormatDocument.buildTilesetData(self, options)
end

function EditorTilesetDocument:save(path, options)
    return EditorFormatDocument.saveTileset(self, path, options)
end

function EditorTilesetDocument:adoptSavedData(data, tileset)
    self.data = data
    self.tileset = tileset
    self.virtual = false
    self.data.properties = self.data.properties or {}
    self.data.__editor_property_types = self.data.__editor_property_types or {}
    self.property_set = EditorPropertySet(self.data.properties, self.data.__editor_property_types)
    self.tile_documents = {}
end

function EditorTilesetDocument:getName()
    return self.data.name or self.id
end

function EditorTilesetDocument:getTileCount()
    return self.data.tile_count or self.tileset and self.tileset.id_count or 0
end

function EditorTilesetDocument:getColumns()
    return math.max(1, self.data.tile_columns or self.tileset and self.tileset.columns or 1)
end

function EditorTilesetDocument:getPaletteTileSize()
    local width = tonumber(self.data.tile_width)
        or (self.tileset and self.tileset.tile_width)
        or 40
    local height = tonumber(self.data.tile_height)
        or (self.tileset and self.tileset.tile_height)
        or 40
    return math.max(1, width), math.max(1, height)
end

function EditorTilesetDocument:getTile(id)
    if id == nil or id < 0 or id >= self:getTileCount() then return nil end
    if self.tile_documents[id] then return self.tile_documents[id] end
    local source = findTileData(self.data, id)
    source.properties = source.properties or {}
    source.__editor_property_types = source.__editor_property_types or {}
    local tile = {
        id = id,
        source = source,
        property_set = EditorPropertySet(source.properties, source.__editor_property_types),
        document = self
    }
    self.tile_documents[id] = tile
    return tile
end

function EditorTilesetDocument:getTileProbability(id)
    local tile = self:getTile(id)
    return tile and tonumber(tile.source.probability) or 1
end

function EditorTilesetDocument:getCollisionShapes(tile)
    if not tile then return {} end
    tile.source.objectgroup = tile.source.objectgroup or { objects = {} }
    tile.source.objectgroup.objects = tile.source.objectgroup.objects or {}
    return tile.source.objectgroup.objects
end

function EditorTilesetDocument:addCollisionShape(tile)
    local shapes = self:getCollisionShapes(tile)
    local width = self.data.tile_width or 40
    local height = self.data.tile_height or 40
    local shape = { x = 0, y = 0, width = width, height = height, shape = "rectangle", properties = {} }
    table.insert(shapes, shape)
    return shape
end

function EditorTilesetDocument:getAnimationFrames(tile)
    if not tile then return {} end
    tile.source.animation = tile.source.animation or {}
    return tile.source.animation
end

function EditorTilesetDocument:addAnimationFrame(tile, tile_id)
    local frame = { tileid = tile_id or tile.id, duration = 100 }
    table.insert(self:getAnimationFrames(tile), frame)
    return frame
end

function EditorTilesetDocument:getTerrainSets()
    self.data.terrains = self.data.terrains or {}
    return self.data.terrains
end

function EditorTilesetDocument:addTerrainSet()
    local used = {}
    for _, terrain in ipairs(self:getTerrainSets()) do
        if terrain.id then used[tostring(terrain.id)] = true end
    end
    local name = "New Terrain Set"
    local set = { id = EditorFormat.uniqueSlug(name, used, "terrain"), name = name,
        type = "mixed", properties = {}, terrain_variants = {}, terrain_tiles = {} }
    table.insert(self:getTerrainSets(), set)
    return set
end

function EditorTilesetDocument:getPropertiesTarget()
    local data = self.data
    local function numberField(label, key, readonly)
        return EditorPropertyFields.number(data, label, key, { readonly = readonly })
    end
    local function offsetField(label, key)
        return EditorPropertyFields.number(data, label, key)
    end
    return {
        title = "Tileset: " .. self:getName(),
        history_owner = self,
        property_set = self.property_set,
        properties = data.properties,
        property_types = data.__editor_property_types,
        fields = {
            { label = "Name", get = function() return data.name or self.id end,
                set = function(value) data.name = value return true end },
            { label = "Type", readonly = true,
                get = function() return data.image and "Tileset Image" or "Collection of Images" end,
                set = function() return false end },
            { label = "Image", get = function() return data.image or "" end,
                set = function(value) data.image = value ~= "" and value or nil return true end },
            numberField("Tile Width", "tile_width"), numberField("Tile Height", "tile_height"),
            numberField("Tile Count", "tile_count"), numberField("Columns", "tile_columns"),
            numberField("Margin", "margin"), numberField("Spacing", "spacing"),
            EditorPropertyFields.choice(data, "Object Alignment", "alignment", {
                { value = "unspecified", label = "Unspecified" },
                { value = "topleft", label = "Top Left" }, { value = "top", label = "Top" },
                { value = "topright", label = "Top Right" }, { value = "left", label = "Left" },
                { value = "center", label = "Center" }, { value = "right", label = "Right" },
                { value = "bottomleft", label = "Bottom Left" },
                { value = "bottom", label = "Bottom" },
                { value = "bottomright", label = "Bottom Right" }
            }, { default = "unspecified" }),
            offsetField("Drawing Offset X", "tile_offset_x"),
            offsetField("Drawing Offset Y", "tile_offset_y"),
            EditorPropertyFields.choice(data, "Tile Render Size", "render_size",
                { "tile", "grid" }, { default = "tile" }),
            EditorPropertyFields.choice(data, "Fill Mode", "fill_mode",
                { "stretch", "preserve-aspect-fit" }, { default = "stretch" })
        }
    }
end

function EditorTilesetDocument:getTilePropertiesTarget(tile)
    if not tile then return nil end
    local source = tile.source
    return {
        title = string.format("Tile %d", tile.id),
        history_owner = self,
        property_set = tile.property_set,
        properties = source.properties,
        property_types = source.__editor_property_types,
        fields = {
            { label = "ID", readonly = true, get = function() return tile.id end, set = function() return false end },
            { label = "Type", get = function() return source.type or "" end,
                set = function(value) source.type = value return true end },
            { label = "Probability", get = function() return source.probability or 1 end,
                set = function(value) local number = tonumber(value) if not number then return false end source.probability = number return true end },
            { label = "Width", readonly = true, compact = true,
                get = function() return source.width or self.data.tile_width or 0 end, set = function() return false end },
            { label = "Height", readonly = true, compact = true,
                get = function() return source.height or self.data.tile_height or 0 end, set = function() return false end },
            { label = "Terrain", get = function()
                    return type(source.terrain) == "table" and table.concat(source.terrain, ",") or source.terrain or ""
                end,
                set = function(value) source.terrain = value return true end },
            { label = "Image", readonly = self.data.image ~= nil,
                get = function() return source.image or (self.data.image and "Tileset image" or "") end,
                set = function(value) if self.data.image ~= nil then return false end source.image = value return true end }
        }
    }
end

return EditorTilesetDocument
