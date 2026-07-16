---@class EditorTilesetDocument : EditorDocument
---@overload fun(editor: table, id: string, tileset?: Tileset, data?: table): EditorTilesetDocument
local EditorTilesetDocument, super = Class(EditorDocument)

local function findTileData(data, id)
    for _, tile in ipairs(data.tiles or {}) do if tile.id == id then return tile end end
    local tile = { id = id, properties = {}, __editor_property_types = {} }
    data.tiles = data.tiles or {}
    table.insert(data.tiles, tile)
    return tile
end

function EditorTilesetDocument:init(editor, id, tileset, data)
    super.init(self, editor)
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
    self.data.terrain_tags = self.data.terrain_tags or {}
    self.data.__editor_property_types = self.data.__editor_property_types or {}
    self.property_set = EditorPropertySet(self.data.properties, self.data.__editor_property_types)
    self.virtual = tileset == nil
    self.tile_documents = {}
    self:initializeFormatExtensions()
    self:initializeTerrainConditions()
end

function EditorTilesetDocument:initializeFormatExtensions(force)
    return EditorFormat.decodeTilesetExtensions(self.data, {
        document = self, tileset = self.data, tileset_id = self.id
    }, force)
end

function EditorTilesetDocument:getFormatExtensionData(id, default)
    self.data.extensions = self.data.extensions or {}
    local value = self.data.extensions[id]
    if value == nil and default ~= nil then
        value = type(default) == "table" and TableUtils.copy(default, true) or default
        self.data.extensions[id] = value
    end
    return value
end

function EditorTilesetDocument:setFormatExtensionData(id, value)
    assert(type(id) == "string" and id ~= "", "Tileset format extension data requires an id")
    self.data.extensions = self.data.extensions or {}
    self.data.extensions[id] = value
    return value
end

function EditorTilesetDocument:initializeTerrainConditions()
    for _, terrain in ipairs(self:getTerrainSets()) do
        for _, rule in ipairs(terrain.terrain_tiles or {}) do
            for index, condition in ipairs(rule.conditions or {}) do
                if not Registry.terrain_rules:isConditionDecoded(condition) then
                    local definition = Registry.getTerrainConditionType(condition.type)
                    if definition then
                        if definition.decode then
                            local success, decoded, reason = pcall(definition.decode, condition, {
                                tileset = self.data, terrain = terrain, rule = rule,
                                document = self
                            })
                            if not success then return false, decoded end
                            if not decoded then return false, reason or "Could not decode terrain condition" end
                            rule.conditions[index] = decoded
                            condition = decoded
                        end
                        if condition.parameters then
                            local parameter_set, reason = EditorPropertySet.fromEntries(condition.parameters, {
                                tileset = self.data, terrain = terrain, rule = rule,
                                document = self
                            })
                            if not parameter_set then return false, reason end
                            Registry.terrain_rules:setParameterSet(condition, parameter_set)
                        end
                        Registry.terrain_rules:markConditionDecoded(condition)
                    end
                end
            end
        end
    end
    return true
end

function EditorTilesetDocument:captureHistoryState()
    return { data = TableUtils.copy(self.data, true) }
end

function EditorTilesetDocument:restoreHistoryState(state)
    if not state then return false end
    self.data = TableUtils.copy(state.data, true)
    self.data.properties = self.data.properties or {}
    self.data.terrain_tags = self.data.terrain_tags or {}
    self.data.__editor_property_types = self.data.__editor_property_types or {}
    self.property_set = EditorPropertySet(self.data.properties, self.data.__editor_property_types)
    self.tile_documents = {}
    if self.tileset then self.tileset.data = self.data end
    return true
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
    self.data.terrain_tags = self.data.terrain_tags or {}
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

function EditorTilesetDocument:addCollisionShape(tile, shape_type, values)
    if not tile then return nil end
    local shapes = self:getCollisionShapes(tile)
    local width = self.data.tile_width or 40
    local height = self.data.tile_height or 40
    shape_type = shape_type or "rectangle"
    local shape = {
        x = width * 0.25, y = height * 0.25,
        width = width * 0.5, height = height * 0.5,
        rotation = 0, shape = shape_type, properties = {}
    }
    if shape_type == "point" then
        shape.width, shape.height = 0, 0
    elseif shape_type == "line" then
        shape.height = 0
        shape.polyline = { { x = 0, y = 0 }, { x = shape.width, y = 0 } }
    elseif shape_type == "polygon" then
        shape.polygon = {
            { x = shape.width * 0.5, y = 0 },
            { x = shape.width, y = shape.height }, { x = 0, y = shape.height }
        }
    elseif shape_type == "polyline" then
        shape.polyline = {
            { x = 0, y = shape.height }, { x = shape.width * 0.5, y = 0 },
            { x = shape.width, y = shape.height }
        }
    end
    for key, value in pairs(values or {}) do shape[key] = value end
    table.insert(shapes, shape)
    return shape
end

function EditorTilesetDocument:getExistingTileData(id)
    for _, tile in ipairs(self.data.tiles or {}) do
        if tile.id == id then return tile end
    end
end

function EditorTilesetDocument:getExistingCollisionShapes(id)
    local tile = self:getExistingTileData(id)
    return tile and ((tile.objectgroup and tile.objectgroup.objects) or tile.collision) or {}
end

function EditorTilesetDocument:getExistingAnimationFrames(id)
    local tile = self:getExistingTileData(id)
    return tile and (tile.animation or tile.frames) or {}
end

function EditorTilesetDocument:setCollisionShapeType(shape, shape_type)
    if not shape then return false end
    local supported = {
        point = true, line = true, rectangle = true,
        ellipse = true, polygon = true, polyline = true
    }
    if not supported[shape_type] then return false end
    local width = math.max(1, tonumber(shape.width) or (self.data.tile_width or 40) * 0.5)
    local height = math.max(1, tonumber(shape.height) or (self.data.tile_height or 40) * 0.5)
    shape.shape, shape.point, shape.ellipse = shape_type, nil, nil
    shape.polygon, shape.polyline, shape.shape_data = nil, nil, nil
    if shape_type == "point" then
        shape.width, shape.height = 0, 0
    elseif shape_type == "line" then
        shape.width, shape.height = width, 0
        shape.polyline = { { x = 0, y = 0 }, { x = width, y = 0 } }
    elseif shape_type == "polygon" then
        shape.width, shape.height = width, height
        shape.polygon = {
            { x = width * 0.5, y = 0 }, { x = width, y = height }, { x = 0, y = height }
        }
    elseif shape_type == "polyline" then
        shape.width, shape.height = width, height
        shape.polyline = {
            { x = 0, y = height }, { x = width * 0.5, y = 0 }, { x = width, y = height }
        }
    else
        shape.width, shape.height = width, height
    end
    return true
end

function EditorTilesetDocument:getAnimationFrames(tile)
    if not tile then return {} end
    tile.source.animation = tile.source.animation or {}
    return tile.source.animation
end

function EditorTilesetDocument:addAnimationFrame(tile, tile_id)
    if not tile then return nil end
    tile_id = tonumber(tile_id == nil and tile.id or tile_id)
    if not tile_id or tile_id < 0 or tile_id % 1 ~= 0
        or tile_id >= self:getTileCount() then return nil end
    local frame = { tileid = tile_id, duration = 100 }
    table.insert(self:getAnimationFrames(tile), frame)
    return frame
end

function EditorTilesetDocument:setAnimationFrameTile(frame, tile_id)
    tile_id = tonumber(tile_id)
    if not frame or not tile_id or tile_id < 0 or tile_id % 1 ~= 0
        or tile_id >= self:getTileCount() then return false end
    frame.tileid = tile_id
    frame.tile_id = nil
    return true
end

function EditorTilesetDocument:setAnimationFrameDuration(frame, duration)
    duration = tonumber(duration)
    if not frame or not duration or duration <= 0 then return false end
    frame.duration = duration
    return true
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
        fallback_mode = "closest",
        properties = {}, terrain_variants = {}, terrain_tiles = {} }
    table.insert(self:getTerrainSets(), set)
    return set
end

function EditorTilesetDocument:getTerrainTags()
    self.data.terrain_tags = self.data.terrain_tags or {}
    return self.data.terrain_tags
end

function EditorTilesetDocument:getTerrainTag(id)
    for _, tag in ipairs(self:getTerrainTags()) do if tag.id == id then return tag end end
end

function EditorTilesetDocument:addTerrainTag(name)
    local used = {}
    for _, tag in ipairs(self:getTerrainTags()) do used[tag.id] = true end
    name = name or "New Terrain Tag"
    local tag = {
        id = EditorFormat.uniqueSlug(name, used, "terrain_tag"),
        name = name,
        color = "#ffffff"
    }
    table.insert(self:getTerrainTags(), tag)
    return tag
end

function EditorTilesetDocument:setTerrainTagId(tag, value)
    if not tag then return false end
    local old_id = tag.id
    local id = EditorFormat.slugId(value, old_id or "terrain_tag")
    local existing = self:getTerrainTag(id)
    if existing and existing ~= tag then return false end
    tag.id = id
    if old_id == id then return true end
    for _, tile in ipairs(self.data.tiles or {}) do
        for index, candidate in ipairs(tile.tags or {}) do
            if candidate == old_id then tile.tags[index] = id end
        end
    end
    for _, terrain in ipairs(self:getTerrainSets()) do
        for _, variant in ipairs(terrain.terrain_variants or {}) do
            for index, candidate in ipairs(variant.tags or {}) do
                if candidate == old_id then variant.tags[index] = id end
            end
        end
        for _, rule in ipairs(terrain.terrain_tiles or {}) do
            for _, condition in ipairs(rule.conditions or {}) do
                if condition.tag == old_id then condition.tag = id end
            end
        end
    end
    return true
end

function EditorTilesetDocument:removeTerrainTag(tag)
    if not tag or not TableUtils.removeValue(self:getTerrainTags(), tag) then return false end
    for _, tile in ipairs(self.data.tiles or {}) do
        for index = #(tile.tags or {}), 1, -1 do
            if tile.tags[index] == tag.id then table.remove(tile.tags, index) end
        end
    end
    for _, terrain in ipairs(self:getTerrainSets()) do
        for _, variant in ipairs(terrain.terrain_variants or {}) do
            for index = #(variant.tags or {}), 1, -1 do
                if variant.tags[index] == tag.id then table.remove(variant.tags, index) end
            end
        end
        for _, rule in ipairs(terrain.terrain_tiles or {}) do
            for index = #(rule.conditions or {}), 1, -1 do
                if rule.conditions[index].tag == tag.id then table.remove(rule.conditions, index) end
            end
        end
    end
    return true
end

function EditorTilesetDocument:addTerrainVariant(terrain)
    if not terrain then return nil end
    terrain.terrain_variants = terrain.terrain_variants or {}
    local used, next_id = {}, 1
    for _, variant in ipairs(terrain.terrain_variants) do
        local id = tonumber(variant.id)
        if id then
            used[id] = true
            next_id = math.max(next_id, id + 1)
        end
    end
    while used[next_id] do next_id = next_id + 1 end
    local variant = {
        id = next_id,
        name = "Terrain " .. next_id,
        color = "#ffffff",
        probability = 1,
        tags = {},
        properties = {}
    }
    table.insert(terrain.terrain_variants, variant)
    return variant
end

function EditorTilesetDocument:addTerrainTile(terrain, variant, tile_id)
    if not terrain or not variant or tile_id == nil then return nil end
    terrain.terrain_tiles = terrain.terrain_tiles or {}
    for _, existing in ipairs(terrain.terrain_tiles) do
        if existing.tile_id == tile_id and existing.terrain ~= variant.id then
            return nil, "A tile can only identify one center terrain within a terrain set"
        end
    end
    local rule = {
        tile_id = tile_id,
        terrain = variant.id,
        conditions = {},
        transforms = { "identity" },
        enabled = true,
        priority = 0,
        probability = 1
    }
    table.insert(terrain.terrain_tiles, rule)
    return rule
end

function EditorTilesetDocument:setTerrainTileVariant(terrain, rule, variant_id)
    for _, existing in ipairs(terrain and terrain.terrain_tiles or {}) do
        if existing ~= rule and existing.tile_id == rule.tile_id
            and existing.terrain ~= variant_id then return false end
    end
    rule.terrain = variant_id
    return true
end

function EditorTilesetDocument:setTerrainTileId(terrain, rule, tile_id)
    tile_id = tonumber(tile_id)
    if not tile_id or tile_id < 0 or tile_id % 1 ~= 0 or tile_id >= self:getTileCount() then
        return false
    end
    for _, existing in ipairs(terrain and terrain.terrain_tiles or {}) do
        if existing ~= rule and existing.tile_id == tile_id
            and existing.terrain ~= rule.terrain then return false end
    end
    rule.tile_id = tile_id
    return true
end

function EditorTilesetDocument:getTerrainVariant(terrain, id)
    for _, variant in ipairs(terrain and terrain.terrain_variants or {}) do
        if variant.id == id then return variant end
    end
end

function EditorTilesetDocument:getTerrainConditionAt(rule, x, y, condition_type)
    for _, condition in ipairs(rule and rule.conditions or {}) do
        if condition.type == (condition_type or "terrain")
            and condition.x == x and condition.y == y then return condition end
    end
end

function EditorTilesetDocument:setTerrainNeighbor(rule, x, y, terrain_id, match)
    rule.conditions = rule.conditions or {}
    local neighbor = self:getTerrainConditionAt(rule, x, y, "terrain")
    if terrain_id == nil then
        if neighbor then TableUtils.removeValue(rule.conditions, neighbor) end
        return true
    end
    if neighbor then
        neighbor.terrain = terrain_id
        neighbor.operator = match ~= "is" and match or nil
    else
        table.insert(rule.conditions, {
            type = "terrain", x = x, y = y, terrain = terrain_id,
            operator = match ~= "is" and match or nil
        })
    end
    return true
end


function EditorTilesetDocument:addTerrainCondition(rule, condition_type)
    local definition = Registry.getTerrainConditionType(condition_type)
    if not rule or not definition then return nil end
    local condition = { type = condition_type }
    for _, field in ipairs(definition.fields or {}) do
        if field.default ~= nil then
            condition[field.id] = type(field.default) == "table"
                and TableUtils.copy(field.default, true) or field.default
        end
    end
    if condition_type == "terrain" then
        condition.x, condition.y, condition.terrain, condition.operator = 0, -1, "same", "is"
    elseif condition_type == "tag" then
        condition.x, condition.y, condition.operator = 0, -1, "has"
        condition.tag = self:getTerrainTags()[1] and self:getTerrainTags()[1].id or ""
    elseif condition_type == "count" then
        condition.subject, condition.terrain = "terrain", "same"
        condition.radius, condition.operator, condition.count = 1, ">=", 1
    elseif condition_type == "predicate" then
        local predicate = Registry.getTerrainPredicates()[1]
        condition.predicate = predicate and predicate.id or ""
        condition.parameters = {}
        condition.influence_radius = predicate and predicate.influence_radius or 1
    elseif condition_type == "script" then
        condition.source = "function(context, parameters)\n    return true\nend"
        condition.parameters, condition.influence_radius = {}, 1
    end
    rule.conditions = rule.conditions or {}
    table.insert(rule.conditions, condition)
    return condition
end

function EditorTilesetDocument:getTerrainVariantTags(terrain, terrain_id)
    local variant = self:getTerrainVariant(terrain, terrain_id)
    return variant and variant.tags or {}
end

function EditorTilesetDocument:getTileTags(tile_id)
    for _, tile in ipairs(self.data.tiles or {}) do
        if tile.id == tile_id then return tile.tags or {} end
    end
    return {}
end

function EditorTilesetDocument:getTerrainCellTags(terrain, terrain_id, tile_id)
    local result, seen = {}, {}
    for _, tags in ipairs({ self:getTerrainVariantTags(terrain, terrain_id), self:getTileTags(tile_id) }) do
        for _, tag in ipairs(tags or {}) do
            if not seen[tag] then seen[tag] = true table.insert(result, tag) end
        end
    end
    return result
end

function EditorTilesetDocument:getTerrainAtTile(terrain, tile_id)
    for _, rule in ipairs(terrain and terrain.terrain_tiles or {}) do
        if rule.tile_id == tile_id and rule.terrain ~= nil then return rule.terrain end
    end
    return 0
end

function EditorTilesetDocument:getTerrainAffectedOffsets(terrain)
    local offsets, seen = { { 0, 0 } }, { ["0:0"] = true }
    for _, rule in ipairs(terrain and terrain.terrain_tiles or {}) do
        for _, transform in ipairs(rule.transforms or { "identity" }) do
            for _, condition in ipairs(rule.conditions or {}) do
                for _, dependency in ipairs(Registry.terrain_rules:getDependencies(condition)) do
                    local dependency_x, dependency_y = Registry.terrain_rules:transformOffset(
                        dependency[1], dependency[2], transform)
                    local x, y = -dependency_x, -dependency_y
                    local key = x .. ":" .. y
                    if not seen[key] then
                        seen[key] = true
                        table.insert(offsets, { x, y })
                    end
                end
            end
        end
    end
    return offsets
end

function EditorTilesetDocument:chooseTerrainTile(terrain, terrain_id, context, seed)
    local best_priority, best_score, best_specificity = -math.huge, -math.huge, -math.huge
    local candidates, first_reason = {}, nil
    context.debug = { candidates = {}, rejected = {} }
    for _, rule in ipairs(terrain and terrain.terrain_tiles or {}) do
        if rule.terrain == terrain_id and rule.enabled ~= false then
            for _, transform in ipairs(rule.transforms or { "identity" }) do
                context.rule = rule
                local score, reason = Registry.terrain_rules:evaluateRule(rule, terrain, context, transform)
                first_reason = first_reason or reason
                if score then
                    table.insert(context.debug.candidates, {
                        tile_id = rule.tile_id, transform = transform, score = score
                    })
                    local priority = tonumber(rule.priority) or 0
                    local specificity = #(rule.conditions or {})
                    local better = priority > best_priority
                        or priority == best_priority and score > best_score
                        or priority == best_priority and score == best_score
                            and specificity > best_specificity
                    if better then
                        best_priority, best_score, best_specificity = priority, score, specificity
                        candidates = { { rule = rule, transform = transform } }
                    elseif priority == best_priority and score == best_score
                        and specificity == best_specificity then
                        table.insert(candidates, { rule = rule, transform = transform })
                    end
                else
                    table.insert(context.debug.rejected, {
                        tile_id = rule.tile_id, transform = transform,
                        reason = reason or "did not match"
                    })
                end
            end
        end
    end
    if #candidates == 0 then return nil, first_reason end
    local total = 0
    for _, candidate in ipairs(candidates) do
        total = total + math.max(0, tonumber(candidate.rule.probability)
            or self:getTileProbability(candidate.rule.tile_id) or 1)
    end
    local selected = candidates[1]
    local unit = math.abs(tonumber(seed) or context.seed or 0) % 104729 / 104729
    local choice = unit * total
    local running = 0
    if total > 0 then
        for _, candidate in ipairs(candidates) do
            running = running + math.max(0, tonumber(candidate.rule.probability)
                or self:getTileProbability(candidate.rule.tile_id) or 1)
            if choice <= running then selected = candidate break end
        end
    end
    local flags = Registry.terrain_rules:getOutputFlags(selected.rule, selected.transform)
    return {
        rule = selected.rule, tile_id = selected.rule.tile_id,
        flip_x = flags.flip_x, flip_y = flags.flip_y, rotate = flags.rotate,
        transform = selected.transform, score = best_score
    }
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
            { label = "Image", control = "path", path_kind = "asset",
                asset_categories = { "sprites" },
                extensions = { "png", "jpg", "jpeg", "bmp", "tga", "webp" },
                get = function() return data.image or "" end,
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
            { label = "Terrain Tags", get = function() return table.concat(source.tags or {}, ", ") end,
                set = function(value)
                    local tags, seen = {}, {}
                    for id in tostring(value or ""):gmatch("[^,%s]+") do
                        if self:getTerrainTag(id) and not seen[id] then
                            seen[id] = true
                            table.insert(tags, id)
                        end
                    end
                    source.tags = tags
                    return true
                end },
            { label = "Image", readonly = self.data.image ~= nil,
                control = "path", path_kind = "asset",
                asset_categories = { "sprites" },
                extensions = { "png", "jpg", "jpeg", "bmp", "tga", "webp" },
                get = function() return source.image or (self.data.image and "Tileset image" or "") end,
                set = function(value) if self.data.image ~= nil then return false end source.image = value return true end }
        }
    }
end

return EditorTilesetDocument
