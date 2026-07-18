--- Provides map and tile data while a terrain rule is evaluated.
---@class TerrainRuleContext : Class
---@field center any
---@field get_tags any
---@field get_terrain any
---@field get_tile_id string?
---@field layer_id string?
---@field map_id string?
---@field rule table
---@field seed number
---@field terrain table
---@field tileset Tileset?
---@field transform any
---@field x number
---@field y number
---@overload fun(options: table): TerrainRuleContext
local TerrainRuleContext = Class()

function TerrainRuleContext:init(options)
    options = options or {}
    self.map_id = options.map_id
    self.layer_id = options.layer_id
    self.x = options.x or 0
    self.y = options.y or 0
    self.center = options.center or 0
    self.terrain = options.terrain
    self.tileset = options.tileset
    self.rule = options.rule
    self.transform = options.transform or "identity"
    self.get_terrain = options.get_terrain or function() return 0 end
    self.get_tile_id = options.get_tile_id or function() return nil end
    self.get_tags = options.get_tags or function() return {} end
    self.seed = tonumber(options.seed) or 0
end

function TerrainRuleContext:transformOffset(x, y)
    return Registry.terrain_rules:transformOffset(x, y, self.transform)
end

function TerrainRuleContext:get(x, y)
    x, y = tonumber(x) or 0, tonumber(y) or 0
    local terrain = self.get_terrain(x, y) or 0
    local tile_id = self.get_tile_id(x, y)
    local tags, tag_set = self.get_tags(x, y, terrain, tile_id) or {}, {}
    for _, tag in ipairs(tags) do tag_set[tag] = true end
    return { terrain = terrain, tile_id = tile_id, tags = tags, tag_set = tag_set }
end

function TerrainRuleContext:isEmpty(x, y)
    return self:get(x, y).terrain == 0
end

function TerrainRuleContext:isTerrain(x, y, terrain)
    if terrain == "same" then terrain = self.center end
    return self:get(x, y).terrain == terrain
end

function TerrainRuleContext:hasTag(x, y, tag)
    return self:get(x, y).tag_set[tag] == true
end

function TerrainRuleContext:countTag(tag, radius)
    radius = math.max(0, math.floor(tonumber(radius) or 1))
    local count = 0
    for y = -radius, radius do
        for x = -radius, radius do
            if (x ~= 0 or y ~= 0) and self:hasTag(x, y, tag) then count = count + 1 end
        end
    end
    return count
end

function TerrainRuleContext:noise(key)
    local value = tostring(key or "") .. ":" .. self.x .. ":" .. self.y .. ":" .. self.seed
    local hash = 2166136261
    for index = 1, #value do
        hash = bit.bxor(hash, value:byte(index))
        hash = bit.tobit(hash * 16777619)
    end
    return (bit.band(hash, 0x7FFFFFFF) % 104729) / 104729
end

return TerrainRuleContext
