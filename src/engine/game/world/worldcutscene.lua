local WorldCutscene, super = Class(Cutscene)

local function _true() return true end

function WorldCutscene:init(group, id, ...)
    local scene, args = self:parseFromGetter(Registry.getWorldCutscene, group, id, ...)

    self.textbox = nil
    self.textbox_actor = nil

    self.choicebox = nil
    self.choice = 0

    self.waiting_for_text = nil

    self.move_targets = {}

    self.camera_target = nil
    self.camera_start = nil
    self.camera_move_time = 0
    self.camera_move_timer = 0
    self.camera_move_after = nil

    Game.lock_input = true
    Game.cutscene_active = true

    Game.world:closeMenu()

    super:init(self, scene, unpack(args))
end

function WorldCutscene:canEnd()
    for _,_ in pairs(self.move_targets) do
        return false
    end
    return not self.camera_target
end

function WorldCutscene:update(dt)
    local done_moving = {}
    for chara,target in pairs(self.move_targets) do
        local ex, ey = chara:getExactPosition()
        if ex == target[2] and ey == target[3] then
            table.insert(done_moving, chara)
            if target[5] then
                chara:setFacing(target[5])
            end
        end
        local tx = Utils.approach(ex, target[2], target[4] * DTMULT)
        local ty = Utils.approach(ey, target[3], target[4] * DTMULT)
        if target[1] then
            chara:moveTo(tx, ty, target[6])
        else
            chara:setExactPosition(tx, ty)
        end
    end
    for _,v in ipairs(done_moving) do
        self.move_targets[v] = nil
    end

    if self.camera_target then
        self.camera_move_timer = Utils.approach(self.camera_move_timer, self.camera_move_time, dt)
        Game.world.camera.x = Utils.lerp(self.camera_start[1], self.camera_target[1], self.camera_move_timer / self.camera_move_time)
        Game.world.camera.y = Utils.lerp(self.camera_start[2], self.camera_target[2], self.camera_move_timer / self.camera_move_time)
        Game.world:updateCamera()
        if self.camera_move_timer == self.camera_move_time then
            self.camera_target = nil

            if self.camera_move_after then
                self.camera_move_after()
            end
        end
    end

    super:update(self, dt)
end

function WorldCutscene:onEnd()
    Game.lock_input = false
    Game.cutscene_active = false

    if Game.world.cutscene == self then
        Game.world.cutscene = nil
    end

    if self.textbox then
        self.textbox:remove()
    end

    if self.choicebox then
        self.choicebox:remove()
    end

    super:onEnd(self)
end

function WorldCutscene:getCharacter(id, index)
    local i = 0
    for _,chara in ipairs(Game.stage:getObjects(Character)) do
        if chara.actor.id == id then
            i = i + 1
            if not index or index == i then
                return chara
            end
        end
    end
end

function WorldCutscene:getMarker(name)
    return Game.world.map:getMarker(name)
end

function WorldCutscene:detachFollowers()
    for _,follower in ipairs(Game.world.followers) do
        follower.following = false
    end
end

local function waitForFollowers(self)
    for _,follower in ipairs(Game.world.followers) do
        if self.move_targets[follower] then return false end
    end
    return true
end
function WorldCutscene:attachFollowers(return_speed, facing)
    for _,follower in ipairs(Game.world.followers) do
        follower.following = true

        follower:updateIndex()

        return_speed = return_speed or 6
        if return_speed > 0 then
            local tx, ty = follower:getTargetPosition()
            self:walkTo(follower, tx, ty, return_speed, facing)
        end
    end
    return waitForFollowers
end
function WorldCutscene:attachFollowersImmediate()
    for _,follower in ipairs(Game.world.followers) do
        follower.following = true

        follower:updateIndex()

        local tx, ty = follower:getTargetPosition()
        follower:setExactPosition(tx, ty)
    end
    return _true
end

function WorldCutscene:alignFollowers(facing, x, y, dist)
    Game.world.player:alignFollowers(facing, x, y, dist)
end

function WorldCutscene:keepFollowerPositions()
    Game.world.player:keepFollowerPositions()
end

function WorldCutscene:resetSprites()
    Game.world.player:resetSprite()
    for _,follower in ipairs(Game.world.followers) do
        follower:resetSprite()
    end
end

function WorldCutscene:spawnNPC(actor, x, y, properties)
    return Game.world:spawnNPC(actor, x, y, properties)
end

function WorldCutscene:look(chara, dir)
    if type(chara) == "string" then
        chara = self:getCharacter(chara)
    end
    chara:setFacing(dir)
end

function WorldCutscene:walkTo(chara, x, y, speed, facing, keep_facing)
    if type(chara) == "string" then
        chara = self:getCharacter(chara)
    end
    local ex, ey = chara:getExactPosition()
    if ex ~= x or ey ~= y then
        if facing and keep_facing then
            chara:setFacing(facing)
        end
        self.move_targets[chara] = {true, x, y, speed or 4, facing, keep_facing}
        return function() return self.move_targets[chara] == nil end
    elseif facing and chara.facing ~= facing then
        chara:setFacing(facing)
    end
    return _true
end

function WorldCutscene:setSprite(chara, sprite, speed)
    if type(chara) == "string" then
        chara = self:getCharacter(chara)
    end
    chara:setSprite(sprite)
    if speed then
        chara:play(speed, true)
    end
end

function WorldCutscene:setAnimation(chara, anim)
    if type(chara) == "string" then
        chara = self:getCharacter(chara)
    end
    local done = false
    chara:setAnimation(anim, function() done = true end)
    return function() return done end
end

function WorldCutscene:resetSprite(chara)
    if type(chara) == "string" then
        chara = self:getCharacter(chara)
    end
    chara:resetSprite()
end

function WorldCutscene:spin(chara, speed)
    if type(chara) == "string" then
        chara = self:getCharacter(chara)
    end
    chara:spin(speed)
end

function WorldCutscene:slideTo(chara, x, y, speed)
    if type(chara) == "string" then
        chara = self:getCharacter(chara)
    end
    local ex, ey = chara:getExactPosition()
    if ex ~= x or ey ~= y then
        self.move_targets[chara] = {false, x, y, speed or 4}
        return function() return self.move_targets[chara] == nil end
    end
    return _true
end

function WorldCutscene:shakeCharacter(chara, x, y)
    if type(chara) == "string" then
        chara = self:getCharacter(chara)
    end
    chara:shake(x, y)
    return function() return chara.sprite.shake_x == 0 and chara.sprite.shake_y == 0 end
end

local function waitForCameraShake() return Game.world.shake_x == 0 and Game.world.shake_y == 0 end
function WorldCutscene:shakeCamera(x, y)
    Game.world.shake_x = x or 0
    Game.world.shake_y = y or x or 0
    return waitForCameraShake
end

function WorldCutscene:detachCamera()
    Game.world.camera_attached = false
end

function WorldCutscene:attachCamera(time)
    local tx, ty = Game.world:getCameraTarget()
    return self:panTo(tx, ty, time or 0.8, function() Game.world.camera_attached = true end)
end
function WorldCutscene:attachCameraImmediate()
    local tx, ty = Game.world:getCameraTarget()
    Game.world.camera_attached = true
    Game.world.camera.x = tx
    Game.world.camera.y = ty
    Game.world:updateCamera()
end

function WorldCutscene:setSpeaker(actor)
    if isClass(actor) and actor:includes(Character) then
        actor = actor.actor
    end
    self.textbox_actor = actor
end

local function waitForCameraPan(self) return self.camera_target == nil end
function WorldCutscene:panTo(...)
    local args = {...}
    local time = 1
    local after = nil
    if type(args[1]) == "number" then
        self.camera_target = {args[1], args[2]}
        time = args[3] or time
        after = args[4]
    elseif type(args[1]) == "string" then
        local marker = Game.world.markers[args[1]]
        self.camera_target = {marker.center_x, marker.center_y}
        time = args[2] or time
        after = args[3]
    elseif isClass(args[1]) and args[1]:includes(Character) then
        local chara = args[1]
        self.camera_target = {chara:getRelativePos(chara.width/2, chara.height/2)}
        time = args[2] or time
        after = args[3]
    else
        self.camera_target = {Game.world:getCameraTarget()}
    end
    self.camera_start = {Game.world.camera.x, Game.world.camera.y}
    self.camera_move_time = time or 0.8
    self.camera_move_timer = 0
    self.camera_move_after = after
    return waitForCameraPan
end

local function waitForMapTransition() return Game.world.state ~= "TRANSITION_OUT" end
function WorldCutscene:transition(...)
    Game.world:transition(...)
    return waitForMapTransition
end

function WorldCutscene:transitionImmediate(...)
    Game.world:transitionImmediate(...)
    return _true
end

local function waitForTextbox(self) return self.textbox.done end
function WorldCutscene:text(text, portrait, actor, options)
    if type(actor) == "table" then
        options = actor
        actor = nil
    end
    if type(portrait) == "table" then
        options = portrait
        portrait = nil
    end

    if self.textbox then
        self.textbox:remove()
    end

    if self.choicebox then
        self.choicebox:remove()
        self.choicebox = nil
    end


    self.textbox = Textbox(56, 344, 529, 103)
    self.textbox.layer = Game.world.layers["ui"]
    Game.stage:addChild(self.textbox)

    actor = actor or self.textbox_actor
    if actor then
        self.textbox:setActor(actor)
    end

    -- TODO: change textbox position depending on player position
    options = options or {}
    if options["top"] then
       local bx, by = self.textbox:getBorder()
       self.textbox.y = by
    end

    self.textbox.active = true
    self.textbox.visible = true
    self.textbox:setFace(portrait, options["x"], options["y"])

    if options["reactions"] then
        for id,react in pairs(options["reactions"]) do
            self.textbox:addReaction(id, react[1], react[2], react[3], react[4], react[5])
        end
    end

    self.textbox:setText(text)

    self.textbox.can_advance = options["advance"] or options["advance"] == nil
    self.textbox.auto_advance = options["auto"]

    local wait = options["wait"] or options["wait"] == nil
    if not self.textbox.can_advance then
        wait = options["wait"] -- By default, don't wait if the textbox can't advance
    end

    if wait then
        self.waiting_for_text = self.textbox
        return self:pause()
    else
        return waitForTextbox, self.textbox
    end
end

local function waitForChoicer(self) return self.choicebox.done, self.choicebox.current_choice end
function WorldCutscene:choicer(choices, options)
    if self.textbox then
        self.textbox:remove()
        self.textbox = nil
    end

    if self.choicebox then self.choicebox:remove() end

    self.choicebox = Choicebox(56, 344, 529, 103)
    self.choicebox.layer = Game.world.layers["ui"]
    Game.stage:addChild(self.choicebox)

    for _,choice in ipairs(choices) do
        self.choicebox:addChoice(choice)
    end

    options = options or {}
    if options["top"] then
       local bx, by = self.choicebox:getBorder()
       self.choicebox.y = by
    end

    self.choicebox.active = true
    self.choicebox.visible = true

    if options["wait"] or options["wait"] == nil then
        self.waiting_for_text = self.choicebox
        return self:pause()
    else
        return waitForChoicer, self.choicebox
    end
end

function WorldCutscene:startEncounter(encounter, transition, enemy)
    Game:encounter(encounter, transition, enemy)
    self:wait(function() return Game.battle == nil end)
end

return WorldCutscene