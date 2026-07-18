--- Registers terrain rules and selects tiles from them.
---@class TerrainRuleRegistry : Class
---@field condition_order table
---@field condition_types table
---@field decoded_conditions table
---@field parameter_sets table
---@field predicate_order table
---@field predicates table
---@field script_cache table
---@overload fun(): TerrainRuleRegistry
local TerrainRuleRegistry = Class()

local TRANSFORMS = {
    identity = function(x, y) return x, y end,
    rotate_90 = function(x, y) return -y, x end,
    rotate_180 = function(x, y) return -x, -y end,
    rotate_270 = function(x, y) return y, -x end,
    flip_x = function(x, y) return -x, y end,
    flip_y = function(x, y) return x, -y end
}

local OUTPUT_FLAGS = {
    identity = {}, rotate_90 = { rotate = true },
    rotate_180 = { flip_x = true, flip_y = true },
    rotate_270 = { flip_x = true, flip_y = true, rotate = true },
    flip_x = { flip_x = true }, flip_y = { flip_y = true }
}

local function compare(value, operator, expected)
    if operator == ">" then return value > expected end
    if operator == ">=" then return value >= expected end
    if operator == "<" then return value < expected end
    if operator == "<=" then return value <= expected end
    if operator == "!=" then return value ~= expected end
    return value == expected
end

local function parameterValues(entries)
    local result = {}
    for _, entry in ipairs(entries or {}) do result[entry.name] = entry.value end
    return result
end

function TerrainRuleRegistry:init()
    self.condition_types = {}
    self.condition_order = {}
    self.predicates = {}
    self.predicate_order = {}
    self.script_cache = {}
    self.parameter_sets = setmetatable({}, { __mode = "k" })
    self.decoded_conditions = setmetatable({}, { __mode = "k" })
    self:registerBuiltins()
end

function TerrainRuleRegistry:markConditionDecoded(condition)
    self.decoded_conditions[condition] = true
end

function TerrainRuleRegistry:isConditionDecoded(condition)
    return self.decoded_conditions[condition] == true
end

function TerrainRuleRegistry:setParameterSet(condition, property_set)
    self.parameter_sets[condition] = property_set
    return property_set
end

function TerrainRuleRegistry:getParameterSet(condition)
    if self.parameter_sets[condition] then return self.parameter_sets[condition] end
    local property_set = EditorPropertySet.fromEntries(condition.parameters or {})
    if property_set then self.parameter_sets[condition] = property_set end
    return property_set
end

function TerrainRuleRegistry:getParameterValues(condition)
    local property_set = self:getParameterSet(condition)
    local values = property_set and TableUtils.copy(property_set.values, true)
        or parameterValues(condition.parameters)
    local predicate = condition.type == "predicate" and self:getPredicate(condition.predicate) or nil
    for _, parameter in ipairs(predicate and predicate.parameters or {}) do
        if values[parameter.id] == nil then
            values[parameter.id] = Registry.editor_properties:getDefault(parameter.type, parameter)
        end
    end
    return values
end

function TerrainRuleRegistry:registerConditionType(id, definition)
    assert(type(id) == "string" and id ~= "", "Terrain condition types require an id")
    assert(type(definition) == "table" and type(definition.evaluate) == "function",
        "Terrain condition types require an evaluate callback")
    local entry = TableUtils.copy(definition, true)
    entry.id = id
    entry.name = entry.name or StringUtils.titleCase(id:gsub("[:/_]", " "))
    entry.fields = entry.fields or {}
    if not self.condition_types[id] then table.insert(self.condition_order, id) end
    self.condition_types[id] = entry
    return entry
end

function TerrainRuleRegistry:unregisterConditionType(id, expected)
    if expected and self.condition_types[id] ~= expected then return false end
    self.condition_types[id] = nil
    TableUtils.removeValue(self.condition_order, id)
    return true
end

function TerrainRuleRegistry:getConditionType(id)
    return self.condition_types[id]
end

function TerrainRuleRegistry:getConditionTypes()
    local result = {}
    for _, id in ipairs(self.condition_order) do
        if self.condition_types[id] then table.insert(result, self.condition_types[id]) end
    end
    return result
end

function TerrainRuleRegistry:registerPredicate(id, definition)
    assert(type(id) == "string" and id ~= "", "Terrain predicates require an id")
    if type(definition) == "function" then definition = { evaluate = definition } end
    assert(type(definition) == "table" and type(definition.evaluate) == "function",
        "Terrain predicates require an evaluate callback")
    local entry = TableUtils.copy(definition, true)
    entry.id = id
    entry.name = entry.name or StringUtils.titleCase(id:gsub("[:/_]", " "))
    entry.parameters = entry.parameters or {}
    if not self.predicates[id] then table.insert(self.predicate_order, id) end
    self.predicates[id] = entry
    return entry
end

function TerrainRuleRegistry:unregisterPredicate(id, expected)
    if expected and self.predicates[id] ~= expected then return false end
    self.predicates[id] = nil
    TableUtils.removeValue(self.predicate_order, id)
    return true
end

function TerrainRuleRegistry:getPredicate(id)
    return self.predicates[id]
end

function TerrainRuleRegistry:getPredicates()
    local result = {}
    for _, id in ipairs(self.predicate_order) do
        if self.predicates[id] then table.insert(result, self.predicates[id]) end
    end
    return result
end

function TerrainRuleRegistry:transformOffset(x, y, transform)
    return (TRANSFORMS[transform] or TRANSFORMS.identity)(x, y)
end

function TerrainRuleRegistry:transformCondition(condition, transform)
    local definition = self:getConditionType(condition.type)
    if definition and definition.transform then return definition.transform(condition, transform, self) end
    local result = TableUtils.copy(condition, true)
    if type(result.x) == "number" and type(result.y) == "number" then
        result.x, result.y = self:transformOffset(result.x, result.y, transform)
    end
    return result
end

function TerrainRuleRegistry:getDependencies(condition)
    local definition = self:getConditionType(condition.type)
    if not definition then
        local radius = math.max(0, math.floor(tonumber(condition.influence_radius) or 1))
        return self:radiusDependencies(radius)
    end
    if definition.get_dependencies then
        return definition.get_dependencies(condition, self) or {}
    end
    if type(condition.x) == "number" and type(condition.y) == "number" then
        return { { condition.x, condition.y } }
    end
    return {}
end

function TerrainRuleRegistry:radiusDependencies(radius)
    local result = {}
    radius = math.max(0, math.floor(tonumber(radius) or 0))
    for y = -radius, radius do
        for x = -radius, radius do
            if x ~= 0 or y ~= 0 then table.insert(result, { x, y }) end
        end
    end
    return result
end

function TerrainRuleRegistry:compileScript(source)
    source = tostring(source or "")
    local cached = self.script_cache[source]
    if cached then return cached.fn, cached.error end
    local chunk, message = loadstring("return " .. source, "terrain_rule_predicate")
    if chunk then
        local environment = {
            math = math, string = string, table = table,
            pairs = pairs, ipairs = ipairs, next = next, select = select,
            type = type, tostring = tostring, tonumber = tonumber, unpack = unpack,
            assert = assert, error = error
        }
        setfenv(chunk, environment)
        local success, result = pcall(chunk)
        if success and type(result) == "function" then
            setfenv(result, environment)
            self.script_cache[source] = { fn = result }
            return result
        end
        message = success and "Terrain script must be an anonymous function" or tostring(result)
    end
    self.script_cache[source] = { error = message }
    return nil, message
end

function TerrainRuleRegistry:evaluateCondition(condition, context, rule, terrain)
    local definition = self:getConditionType(condition.type)
    if not definition then return false, 0, "Unknown condition type '" .. tostring(condition.type) .. "'", true end
    local success, matched, score, reason = pcall(definition.evaluate,
        condition, context, rule, terrain, self)
    if not success then return false, 0, tostring(matched), true end
    if type(matched) == "number" then return true, matched, score, false, true end
    return matched == true, tonumber(score) or 0, reason, definition.hard == true, false
end

function TerrainRuleRegistry:evaluateRule(rule, terrain, context, transform)
    local score, failed = 0, false
    context.transform = transform or "identity"
    for _, source in ipairs(rule.conditions or {}) do
        local condition = self:transformCondition(source, transform)
        local matched, amount, reason, hard, scored = self:evaluateCondition(condition, context, rule, terrain)
        if matched then
            score = score + (scored and amount or 4)
        elseif hard then
            return nil, reason
        else
            failed = true
            score = score - 8
        end
    end
    if failed and (terrain.fallback_mode or "closest") == "strict" then
        return nil, "one or more declarative conditions did not match"
    end
    return score
end

function TerrainRuleRegistry:getOutputFlags(rule, transform)
    local transformed = OUTPUT_FLAGS[transform] or OUTPUT_FLAGS.identity
    return {
        flip_x = (rule.flip_x == true) ~= (transformed.flip_x == true),
        flip_y = (rule.flip_y == true) ~= (transformed.flip_y == true),
        rotate = (rule.rotate == true) ~= (transformed.rotate == true)
    }
end

function TerrainRuleRegistry:registerBuiltins()
    local directional = {
        { id = "x", type = "integer", default = 0 },
        { id = "y", type = "integer", default = -1 }
    }
    self:registerConditionType("terrain", {
        name = "Terrain at Offset", fields = directional,
        evaluate = function(condition, context)
            local expected = condition.terrain
            if expected == "same" then expected = context.center end
            local matched = context:isTerrain(condition.x, condition.y, expected or 0)
            if condition.operator == "not" then matched = not matched end
            return matched
        end
    })
    self:registerConditionType("tag", {
        name = "Tag at Offset", fields = directional,
        evaluate = function(condition, context)
            local matched = context:hasTag(condition.x, condition.y, condition.tag)
            if condition.operator == "not_has" then matched = not matched end
            return matched
        end
    })
    self:registerConditionType("count", {
        name = "Neighborhood Count",
        get_dependencies = function(condition, registry)
            return registry:radiusDependencies(condition.radius or 1)
        end,
        evaluate = function(condition, context)
            local radius = math.max(0, math.floor(tonumber(condition.radius) or 1))
            local count = 0
            for y = -radius, radius do
                for x = -radius, radius do
                    if x ~= 0 or y ~= 0 then
                        local matched
                        if condition.subject == "tag" then
                            matched = context:hasTag(x, y, condition.tag)
                        elseif condition.subject == "occupied" then
                            matched = not context:isEmpty(x, y)
                        else
                            local expected = condition.terrain == "same" and context.center or condition.terrain
                            matched = context:isTerrain(x, y, expected or 0)
                        end
                        if matched then count = count + 1 end
                    end
                end
            end
            return compare(count, condition.operator or ">=", tonumber(condition.count) or 1)
        end
    })
    self:registerConditionType("predicate", {
        name = "Registered Predicate", hard = true,
        get_dependencies = function(condition, registry)
            local predicate = registry:getPredicate(condition.predicate)
            if predicate and predicate.dependencies then
                return type(predicate.dependencies) == "function"
                    and predicate.dependencies(condition) or predicate.dependencies
            end
            return registry:radiusDependencies(condition.influence_radius
                or predicate and predicate.influence_radius or 1)
        end,
        evaluate = function(condition, context, rule, terrain, registry)
            local predicate = registry:getPredicate(condition.predicate)
            if not predicate then return false, 0, "Unknown terrain predicate '" .. tostring(condition.predicate) .. "'" end
            local result, reason = predicate.evaluate(context,
                registry:getParameterValues(condition), condition, rule, terrain)
            if type(result) == "number" then return result end
            return result == true, 0, reason
        end
    })
    self:registerConditionType("script", {
        name = "Inline Script", hard = true,
        get_dependencies = function(condition, registry)
            return registry:radiusDependencies(condition.influence_radius or 1)
        end,
        evaluate = function(condition, context, rule, terrain, registry)
            local callback, reason = registry:compileScript(condition.source)
            if not callback then return false, 0, reason end
            local success, result = pcall(callback, context,
                registry:getParameterValues(condition), condition, rule, terrain)
            if not success then return false, 0, result end
            if type(result) == "number" then return result end
            return result == true
        end
    })
end

return TerrainRuleRegistry
