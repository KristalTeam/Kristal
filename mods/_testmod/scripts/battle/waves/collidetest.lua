---@class CollideTest : Wave
---@overload fun(...) : CollideTest
local CollideTest, super = Class(Wave)

function CollideTest:init()
    super.init(self)

    self.time = -1
end

function CollideTest:onStart()
    local x, y = Game.battle.arena:getCenter()
    local checker = CollisionCheck(x, y)

    checker.collider = ColliderGroup(checker, {
        CircleCollider(checker, 0, 0, 32, {inside = true}),
        CircleCollider(checker, 0, 0, 32, {invert = true})
    }, {invert = true})

    Game.battle:addChild(checker)
    table.insert(self.objects, checker)
end

return CollideTest
