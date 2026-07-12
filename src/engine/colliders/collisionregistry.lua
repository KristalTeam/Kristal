---@alias CollisionRegistry.CollisionTest fun(a: Collider, b: Collider): boolean

---@class CollisionRegistry
---@field private types string[]
---@field private type_registered table<string, boolean>
---@field private class_of table<string, Collider>
---@field private collision_tests table<string, table<string, CollisionRegistry.CollisionTest>>
---@field private inner_collision_tests table<string, table<string, CollisionRegistry.CollisionTest>>
local CollisionRegistry = {}

CollisionRegistry.RECTANGLE = "rectangle"
CollisionRegistry.LINE = "line"
CollisionRegistry.CIRCLE = "circle"
CollisionRegistry.POINT = "point"
CollisionRegistry.POLYGON = "polygon"
CollisionRegistry.GROUP = "group"

function CollisionRegistry.refresh()
    CollisionRegistry.types = {}
    CollisionRegistry.type_registered = {}
    CollisionRegistry.class_of = {}
    CollisionRegistry.collision_tests = {}
    CollisionRegistry.inner_collision_tests = {}

    CollisionRegistry.registerDefaultTypes()
    Kristal.callEvent(KRISTAL_EVENT.registerColliderTypes)

    CollisionRegistry.registerDefaultCollisions()
    CollisionRegistry.registerDefaultInnerCollisions()
    Kristal.callEvent(KRISTAL_EVENT.registerCollisions)

    CollisionRegistry.validateCollisions()
end

function CollisionRegistry.getTypes()
    return TableUtils.copy(CollisionRegistry.types)
end

function CollisionRegistry.registerDefaultTypes()
    CollisionRegistry.registerType(CollisionRegistry.RECTANGLE, Hitbox)
    CollisionRegistry.registerType(CollisionRegistry.LINE, LineCollider)
    CollisionRegistry.registerType(CollisionRegistry.CIRCLE, CircleCollider)
    CollisionRegistry.registerType(CollisionRegistry.POINT, PointCollider)
    CollisionRegistry.registerType(CollisionRegistry.POLYGON, PolygonCollider)
    CollisionRegistry.registerType(CollisionRegistry.GROUP, ColliderGroup)
end

function CollisionRegistry.registerDefaultCollisions()
    -- Hitbox Collisions
    CollisionRegistry.register(CollisionRegistry.RECTANGLE, CollisionRegistry.RECTANGLE, KristalCollisions.rectRect)
    CollisionRegistry.register(CollisionRegistry.RECTANGLE, CollisionRegistry.LINE, KristalCollisions.rectLine, true)
    CollisionRegistry.register(CollisionRegistry.RECTANGLE, CollisionRegistry.CIRCLE, KristalCollisions.rectCircle, true)
    CollisionRegistry.register(CollisionRegistry.RECTANGLE, CollisionRegistry.POINT, KristalCollisions.rectPoint, true)

    -- LineCollider Collisions
    CollisionRegistry.register(CollisionRegistry.LINE, CollisionRegistry.LINE, KristalCollisions.lineLine)
    CollisionRegistry.register(CollisionRegistry.LINE, CollisionRegistry.CIRCLE, KristalCollisions.lineCircle, true)
    CollisionRegistry.register(CollisionRegistry.LINE, CollisionRegistry.POINT, KristalCollisions.linePoint, true)

    -- CircleCollider Collisions
    CollisionRegistry.register(CollisionRegistry.CIRCLE, CollisionRegistry.CIRCLE, KristalCollisions.circleCircle)
    CollisionRegistry.register(CollisionRegistry.CIRCLE, CollisionRegistry.POINT, KristalCollisions.circlePoint, true)

    -- PointCollider Collisions
    CollisionRegistry.register(CollisionRegistry.POINT, CollisionRegistry.POINT, KristalCollisions.pointPoint)

    -- PolygonCollider Collisions
    CollisionRegistry.register(CollisionRegistry.POLYGON, CollisionRegistry.RECTANGLE, KristalCollisions.polygonRect, true)
    CollisionRegistry.register(CollisionRegistry.POLYGON, CollisionRegistry.LINE, KristalCollisions.polygonLine, true)
    CollisionRegistry.register(CollisionRegistry.POLYGON, CollisionRegistry.CIRCLE, KristalCollisions.polygonCircle, true)
    CollisionRegistry.register(CollisionRegistry.POLYGON, CollisionRegistry.POINT, KristalCollisions.polygonPoint, true)
    CollisionRegistry.register(CollisionRegistry.POLYGON, CollisionRegistry.POLYGON, KristalCollisions.polygonPolygon)

    -- ColliderGroup Collisions
    for _, type_id in ipairs(CollisionRegistry.getTypes()) do
        CollisionRegistry.register(CollisionRegistry.GROUP, type_id, KristalCollisions.groupAny, true)
    end
end

function CollisionRegistry.registerDefaultInnerCollisions()
    -- Hitbox Collisions
    CollisionRegistry.registerInner(CollisionRegistry.RECTANGLE, CollisionRegistry.RECTANGLE, KristalCollisions.rectRectInner)
    CollisionRegistry.registerInner(CollisionRegistry.RECTANGLE, CollisionRegistry.LINE, KristalCollisions.rectLineInner)
    CollisionRegistry.registerInner(CollisionRegistry.RECTANGLE, CollisionRegistry.CIRCLE, KristalCollisions.rectCircleInner)
    CollisionRegistry.registerInner(CollisionRegistry.RECTANGLE, CollisionRegistry.POINT, KristalCollisions.rectPointInner)
    CollisionRegistry.registerInner(CollisionRegistry.RECTANGLE, CollisionRegistry.POLYGON, KristalCollisions.rectPolygonInner)

    -- LineCollider Collisions
    CollisionRegistry.registerInner(CollisionRegistry.LINE, CollisionRegistry.RECTANGLE, KristalCollisions.lineRectInner)
    CollisionRegistry.registerInner(CollisionRegistry.LINE, CollisionRegistry.LINE, KristalCollisions.lineLineInner)
    CollisionRegistry.registerInner(CollisionRegistry.LINE, CollisionRegistry.CIRCLE, KristalCollisions.lineCircleInner)
    CollisionRegistry.registerInner(CollisionRegistry.LINE, CollisionRegistry.POINT, KristalCollisions.linePointInner)
    CollisionRegistry.registerInner(CollisionRegistry.LINE, CollisionRegistry.POLYGON, KristalCollisions.linePolygonInner)

    -- CircleCollider Collisions
    CollisionRegistry.registerInner(CollisionRegistry.CIRCLE, CollisionRegistry.RECTANGLE, KristalCollisions.circleRectInner)
    CollisionRegistry.registerInner(CollisionRegistry.CIRCLE, CollisionRegistry.LINE, KristalCollisions.circleLineInner)
    CollisionRegistry.registerInner(CollisionRegistry.CIRCLE, CollisionRegistry.CIRCLE, KristalCollisions.circleCircleInner)
    CollisionRegistry.registerInner(CollisionRegistry.CIRCLE, CollisionRegistry.POINT, KristalCollisions.circlePointInner)
    CollisionRegistry.registerInner(CollisionRegistry.CIRCLE, CollisionRegistry.POLYGON, KristalCollisions.circlePolygonInner)

    -- PointCollider Collisions
    CollisionRegistry.registerInner(CollisionRegistry.POINT, CollisionRegistry.RECTANGLE, KristalCollisions.pointRectInner)
    CollisionRegistry.registerInner(CollisionRegistry.POINT, CollisionRegistry.LINE, KristalCollisions.pointLineInner)
    CollisionRegistry.registerInner(CollisionRegistry.POINT, CollisionRegistry.CIRCLE, KristalCollisions.pointCircleInner)
    CollisionRegistry.registerInner(CollisionRegistry.POINT, CollisionRegistry.POINT, KristalCollisions.pointPointInner)
    CollisionRegistry.registerInner(CollisionRegistry.POINT, CollisionRegistry.POLYGON, KristalCollisions.pointPolygonInner)

    -- PolygonCollider Collisions
    CollisionRegistry.registerInner(CollisionRegistry.POLYGON, CollisionRegistry.RECTANGLE, KristalCollisions.polygonRectInner)
    CollisionRegistry.registerInner(CollisionRegistry.POLYGON, CollisionRegistry.LINE, KristalCollisions.polygonLineInner)
    CollisionRegistry.registerInner(CollisionRegistry.POLYGON, CollisionRegistry.CIRCLE, KristalCollisions.polygonCircleInner)
    CollisionRegistry.registerInner(CollisionRegistry.POLYGON, CollisionRegistry.POINT, KristalCollisions.polygonPointInner)
    CollisionRegistry.registerInner(CollisionRegistry.POLYGON, CollisionRegistry.POLYGON, KristalCollisions.polygonPolygonInner)

    -- ColliderGroup Collisions
    for _, type_id in ipairs(CollisionRegistry.getTypes()) do
        CollisionRegistry.registerInner(CollisionRegistry.GROUP, type_id, KristalCollisions.groupAny, true)
    end
end

--- Validates collision matches between all registered collider types.
---@private
function CollisionRegistry.validateCollisions()
    for _, type_a in ipairs(CollisionRegistry.types) do
        for _, type_b in ipairs(CollisionRegistry.types) do
            local test = CollisionRegistry.collision_tests[type_a][type_b]
            if test == nil then
                Kristal.Console:warn("Missing collision test for: " .. type_a .. " vs " .. type_b)
            end

            local inner_test = CollisionRegistry.inner_collision_tests[type_a][type_b]
            if inner_test == nil then
                Kristal.Console:warn("Missing inner collision test for: " .. type_a .. " vs " .. type_b)
            end
        end
    end
end

--- Registers a new collider type.
---@generic T : Collider
---@param id string # The unique identifier for the collider type.
---@param class T? # The class associated with the collider type.
function CollisionRegistry.registerType(id, class)
    if CollisionRegistry.type_registered[id] then
        error("Already registered collider type: " .. id)
    end

    table.insert(CollisionRegistry.types, id)
    CollisionRegistry.type_registered[id] = true
    CollisionRegistry.class_of[id] = class

    CollisionRegistry.collision_tests[id] = {}
    CollisionRegistry.inner_collision_tests[id] = {}
end

--- Registers a collision test between two collider types.
---@param type_a string # The first collider type.
---@param type_b string # The second collider type.
---@param test CollisionRegistry.CollisionTest # The collision test function.
---@param symmetrical boolean? # Whether to register the collision test symmetrically.
function CollisionRegistry.register(type_a, type_b, test, symmetrical)
    if not CollisionRegistry.type_registered[type_a] then
        error("Collider type not registered: " .. type_a)
    end
    if not CollisionRegistry.type_registered[type_b] then
        error("Collider type not registered: " .. type_b)
    end

    CollisionRegistry.collision_tests[type_a][type_b] = test

    if symmetrical and type_a ~= type_b then
        CollisionRegistry.collision_tests[type_b][type_a] = function(a, b) return test(b, a) end
    end
end

--- Registers an inner collision test between two collider types.
---@param type_a string # The first collider type.
---@param type_b string # The second collider type.
---@param test CollisionRegistry.CollisionTest # The collision test function.
---@param symmetrical boolean? # Whether to register the inner collision test symmetrically.
function CollisionRegistry.registerInner(type_a, type_b, test, symmetrical)
    if not CollisionRegistry.type_registered[type_a] then
        error("Collider type not registered: " .. type_a)
    end
    if not CollisionRegistry.type_registered[type_b] then
        error("Collider type not registered: " .. type_b)
    end

    CollisionRegistry.inner_collision_tests[type_a][type_b] = test

    if symmetrical and type_a ~= type_b then
        CollisionRegistry.inner_collision_tests[type_b][type_a] = function(a, b) return test(b, a) end
    end
end

--- Checks for a collision between two colliders.
---@param a Collider # The first collider.
---@param b Collider # The second collider.
---@return boolean collided # Whether the colliders are colliding.
function CollisionRegistry.testCollision(a, b)
    -- Return false if either collider is not collidable
    if not a:isCollidable() or not b:isCollidable() then
        return false
    end

    -- Redirect to inner collision test if either collider is marked as "inner"
    if a:isInner() then
        if b:isInner() then
            -- Colliders cannot be inside of eachother
            return false
        end

        return CollisionRegistry.testInnerCollision(a, b)
    elseif b:isInner() then
        return CollisionRegistry.testInnerCollision(b, a)
    end

    local type_a = a:getColliderType()
    local type_b = b:getColliderType()

    local test = CollisionRegistry.collision_tests[type_a][type_b]

    if test == nil then
        -- Collision test not registered between these two collider types
        -- The registry validation warns about this earlier, so we'll just return false
        return false
    end

    local result = test(a, b)

    if a:isInverted() ~= b:isInverted() then
        return not result
    else
        return result
    end
end

--- Checks if the second collider is inside the first collider. Not intended to be called directly.
---@protected
---@param a Collider # The first collider.
---@param b Collider # The second collider.
---@return boolean inside # Whether the second collider is inside the first collider.
function CollisionRegistry.testInnerCollision(a, b)
    local type_a = a:getColliderType()
    local type_b = b:getColliderType()

    local test = CollisionRegistry.inner_collision_tests[type_a][type_b]

    if test == nil then
        error("No inner collision test registered between \"" .. type_a .. "\" and \"" .. type_b .. "\"")
    end

    local result = test(a, b)

    if a:isInverted() ~= b:isInverted() then
        return not result
    else
        return result
    end
end

return CollisionRegistry
