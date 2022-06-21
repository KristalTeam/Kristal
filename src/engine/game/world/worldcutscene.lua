local WorldCutscene, super = Class(Cutscene)

local function _true() return true end

function WorldCutscene:init(group, id, ...)
    local scene, args = self:parseFromGetter(Registry.getWorldCutscene, group, id, ...)

    self.textbox = nil
    self.textbox_actor = nil
    self.textbox_speaker = nil
    self.textbox_top = nil

    self.choicebox = nil
    self.choice = 0

    self.shopbox = nil

    self.moving_objects = {}

    Game.lock_movement = true
    Game.cutscene_active = true

    if Game:isLight() then
        if Game.world.menu and Game.world.menu.state == "ITEMMENU" then
            Game.world.menu:closeBox()
            Game.world.menu.state = "TEXT"
        end
    else
        Game.world:closeMenu()
    end

    super:init(self, scene, unpack(args))
end

function WorldCutscene:canEnd()
    if #self.moving_objects > 0 then
        return false
    end
    return Game.world.camera.pan_target == nil
end

function WorldCutscene:update()
    local new_moving = {}
    for _,object in ipairs(self.moving_objects) do
        if object.physics.move_target then
            table.insert(new_moving, object)
        end
    end
    self.moving_objects = new_moving

    super:update(self)
end

function WorldCutscene:onEnd()
    Game.lock_movement = false
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

    if Game:isLight() then
        if Game.world.menu and Game.world.menu.state == "TEXT" then
            Game.world:closeMenu()
        end
    end

    super:onEnd(self)
end

function WorldCutscene:getCharacter(id, index)
    return Game.world:getCharacter(id, index)
end

function WorldCutscene:getEvent(id)
    return Game.world.map:getEvent(id)
end

function WorldCutscene:getEvents(name)
    return Game.world.map:getEvents(name)
end

function WorldCutscene:getMarker(name)
    return Game.world.map:getMarker(name)
end

function WorldCutscene:enableMovement()
    Game.lock_movement = false
end

function WorldCutscene:disableMovement()
    Game.lock_movement = true
end

function WorldCutscene:detachFollowers()
    Game.world:detachFollowers()
end

local function waitForFollowers(self)
    for _,follower in ipairs(Game.world.followers) do
        if follower.returning then
            return false
        end
    end
    return true
end
function WorldCutscene:attachFollowers(return_speed)
    Game.world:attachFollowers(return_speed)
    return waitForFollowers
end
function WorldCutscene:attachFollowersImmediate()
    Game.world:attachFollowersImmediate()
    return _true
end

function WorldCutscene:alignFollowers(facing, x, y, dist)
    Game.world.player:alignFollowers(facing, x, y, dist)
end

function WorldCutscene:interpolateFollowers()
    Game.world.player:interpolateFollowers()
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
    if not dir then
        dir = chara or "down"
        chara = Game.world.player
    elseif type(chara) == "string" then
        chara = self:getCharacter(chara)
    end
    chara:setFacing(dir)
end

function WorldCutscene:walkTo(chara, x, y, time, facing, keep_facing, ease)
    if type(chara) == "string" then
        chara = self:getCharacter(chara)
    end
    local walked = false
    if chara:walkTo(x, y, time, facing, keep_facing, ease) then
        chara.physics.move_target.after = Utils.override(chara.physics.move_target.after, function(orig) orig() walked = true end)
        table.insert(self.moving_objects, chara)
        return function() return walked end
    else
        return _true
    end
end

function WorldCutscene:walkToSpeed(chara, x, y, speed, facing, keep_facing)
    if type(chara) == "string" then
        chara = self:getCharacter(chara)
    end
    local walked = false
    if chara:walkToSpeed(x, y, speed, facing, keep_facing) then
        chara.physics.move_target.after = Utils.override(chara.physics.move_target.after, function(orig) orig() walked = true end)
        table.insert(self.moving_objects, chara)
        return function() return walked end
    else
        return _true
    end
end

function WorldCutscene:walkPath(chara, path, options)
    if type(chara) == "string" then
        chara = self:getCharacter(chara)
    end

    local walked = false

    options = options or {}
    options.after = Utils.override(options.after, function(orig) orig() walked = true end)

    chara:walkPath(path, options)
    table.insert(self.moving_objects, chara)

    return function() return walked end
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

function WorldCutscene:slideTo(obj, x, y, time, ease)
    if type(obj) == "string" then
        obj = self:getCharacter(obj)
    end
    if type(x) == "string" then
        ease = time
        time = y
        x, y = Game.world.map:getMarker(x)
    end
    local slided = false
    if obj:slideTo(x, y, time, ease, function() slided = true end) then
        table.insert(self.moving_objects, obj)
        return function() return slided end
    else
        return _true
    end
end

function WorldCutscene:slideToSpeed(obj, x, y, speed)
    if type(obj) == "string" then
        obj = self:getCharacter(obj)
    end
    if type(x) == "string" then
        speed = y
        x, y = Game.world.map:getMarker(x)
    end
    local slided = false
    if obj:slideToSpeed(x, y, speed, function() slided = true end) then
        table.insert(self.moving_objects, obj)
        return function() return slided end
    else
        return _true
    end
end

function WorldCutscene:slidePath(obj, path, options)
    if type(obj) == "string" then
        obj = self:getCharacter(obj)
    end

    local slided = false

    options = options or {}
    local old_after = options.after
    options.after = function()
        if old_after then
            old_after()
        end
        slided = true
    end

    obj:slidePath(path, options)
    table.insert(self.moving_objects, obj)

    return function() return slided end
end

function WorldCutscene:jumpTo(chara, ...)
    if type(chara) == "string" then
        chara = self:getCharacter(chara)
    end
    chara:jumpTo(...)
    return function() return not chara.jumping end
end

function WorldCutscene:shakeCharacter(chara, x, y)
    if type(chara) == "string" then
        chara = self:getCharacter(chara)
    end
    chara:shake(x, y)
    return function() return chara.sprite.shake_x == 0 and chara.sprite.shake_y == 0 end
end

local function waitForCameraShake() return Game.world.camera.shake_x == 0 and Game.world.camera.shake_y == 0 end
function WorldCutscene:shakeCamera(x, y, friction)
    Game.world.camera:shake(x, y, friction)
    return waitForCameraShake
end

function WorldCutscene:detachCamera()
    Game.world:setCameraAttached(false)
end

function WorldCutscene:attachCamera(time)
    local tx, ty = Game.world.camera:getTargetPosition()
    return self:panTo(tx, ty, time or 0.8, "linear", function() Game.world:setCameraAttached(true) end)
end
function WorldCutscene:attachCameraImmediate()
    local tx, ty = Game.world.camera:getTargetPosition()
    Game.world:setCameraAttached(true)
    Game.world.camera:setPosition(tx, ty)
end

function WorldCutscene:setSpeaker(actor, talk)
    if isClass(actor) and actor:includes(Character) then
        if talk ~= false then
            self.textbox_speaker = actor.sprite
        end
        self.textbox_actor = actor.actor
    elseif type(actor) == "string" and talk ~= false then
        local chara = self:getCharacter(actor)
        if chara then
            self.textbox_speaker = chara.sprite
            self.textbox_actor = chara.actor
        else
            self.textbox_speaker = nil
            self.textbox_actor = actor
        end
    else
        self.textbox_speaker = nil
        self.textbox_actor = actor
    end
end

function WorldCutscene:setTextboxTop(top)
    self.textbox_top = top
end

local function waitForCameraPan(self) return Game.world.camera.pan_target == nil end
function WorldCutscene:panTo(...)
    local args = {...}
    local x, y = 0, 0
    local time = 1
    local ease = "linear"
    local after = nil
    if type(args[1]) == "number" then
        x, y = args[1], args[2]
        time = args[3] or time
        ease = args[4] or ease
        after = args[5]
    elseif type(args[1]) == "string" then
        local marker = Game.world.map.markers[args[1]]
        x, y = marker.center_x, marker.center_y
        time = args[2] or time
        ease = args[3] or ease
        after = args[4]
    elseif isClass(args[1]) and args[1]:includes(Character) then
        local chara = args[1]
        x, y = chara:getRelativePos(chara.width/2, chara.height/2)
        time = args[2] or time
        ease = args[3] or ease
        after = args[4]
    else
        x, y = Game.world:getCameraTarget()
    end
    local result = Game.world.camera:panTo(x, y, time, ease, after)
    if not result and after then
        after()
    end
    return waitForCameraPan
end

local function waitForMapTransition() return Game.world.state ~= "FADING" end
function WorldCutscene:mapTransition(...)
    Game.world:mapTransition(...)
    return waitForMapTransition
end

function WorldCutscene:loadMap(...)
    Game.world:loadMap(...)
end

function WorldCutscene:fadeOut(speed, options)
    options = options or {}

    local fader = options["global"] and Game.fader or Game.world.fader

    if speed then
        options["speed"] = speed
    end

    local fade_done = false

    fader:fadeOut(function() fade_done = true end, options)

    local wait_func = function() return fade_done end
    if options["wait"] ~= false then
        return self:wait(wait_func)
    else
        return wait_func
    end
end

function WorldCutscene:fadeIn(speed, options)
    options = options or {}

    local fader = options["global"] and Game.fader or Game.world.fader

    if speed then
        options["speed"] = speed
    end

    local fade_done = false

    fader:fadeIn(function() fade_done = true end, options)

    local wait_func = function() return fade_done end
    if options["wait"] then
        return self:wait(wait_func)
    else
        return wait_func
    end
end

local function waitForTextbox(self) return self.textbox:isDone() end
function WorldCutscene:text(text, portrait, actor, options)
    if type(actor) == "table" and not isClass(actor) then
        options = actor
        actor = nil
    end
    if type(portrait) == "table" then
        options = portrait
        portrait = nil
    end

    options = options or {}

    if self.textbox then
        self.textbox:remove()
    end

    if self.choicebox then
        self.choicebox:remove()
        self.choicebox = nil
    end

    local width, height = 529, 103
    if Game:isLight() then
        width, height = 530, 104
    end

    self.textbox = Textbox(56, 344, width, height)
    self.textbox.layer = WORLD_LAYERS["textbox"]
    Game.world:addChild(self.textbox)
    self.textbox:setParallax(0, 0)

    local speaker = self.textbox_speaker
    if not speaker and isClass(actor) and actor:includes(Character) then
        speaker = actor.sprite
    end

    if options["talk"] ~= false then
        self.textbox.text.talk_sprite = speaker
    end

    actor = actor or self.textbox_actor
    if isClass(actor) and actor:includes(Character) then
        actor = actor.actor
    end
    if actor then
        self.textbox:setActor(actor)
    end

    if options["top"] == nil and self.textbox_top == nil then
        local _, player_y = Game.world.player:localToScreenPos()
        options["top"] = player_y > 260
    end
    if options["top"] or (options["top"] == nil and self.textbox_top) then
       local bx, by = self.textbox:getBorder()
       self.textbox.y = by + 2
    end

    self.textbox.active = true
    self.textbox.visible = true
    self.textbox:setFace(portrait, options["x"], options["y"])

    if options["reactions"] then
        for id,react in pairs(options["reactions"]) do
            self.textbox:addReaction(id, react[1], react[2], react[3], react[4], react[5])
        end
    end

    if options["functions"] then
        for id,func in pairs(options["functions"]) do
            self.textbox:addFunction(id, func)
        end
    end

    if options["font"] then
        if type(options["font"]) == "table" then
            -- {font, size}
            self.textbox:setFont(options["font"][1], options["font"][2])
        else
            self.textbox:setFont(options["font"])
        end
    end

    if options["align"] then
        self.textbox:setAlign(options["align"])
    end

    self.textbox:setSkippable(options["skip"] or options["skip"] == nil)
    self.textbox:setAdvance(options["advance"] or options["advance"] == nil)
    self.textbox:setAuto(options["auto"])

    self.textbox:setText(text, function()
        self.textbox:remove()
        self:tryResume()
    end)

    local wait = options["wait"] or options["wait"] == nil
    if not self.textbox.text.can_advance then
        wait = options["wait"] -- By default, don't wait if the textbox can't advance
    end

    if wait then
        return self:wait(waitForTextbox)
    else
        return waitForTextbox, self.textbox
    end
end

function WorldCutscene:closeText()
    if self.textbox then
        self.textbox:remove()
        self.textbox = nil
    end
end

local function waitForChoicer(self) return self.choicebox.done, self.choicebox.selected_choice end
function WorldCutscene:choicer(choices, options)
    if self.textbox then
        self.textbox:remove()
        self.textbox = nil
    end

    if self.choicebox then self.choicebox:remove() end

    local width, height = 529, 103
    if Game:isLight() then
        width, height = 530, 104
    end

    self.choicebox = Choicebox(56, 344, width, height)
    self.choicebox.layer = WORLD_LAYERS["textbox"]
    Game.world:addChild(self.choicebox)
    self.choicebox:setParallax(0, 0)

    for _,choice in ipairs(choices) do
        self.choicebox:addChoice(choice)
    end

    options = options or {}
    if options["top"] == nil and self.textbox_top == nil then
        local _, player_y = Game.world.player:localToScreenPos()
        options["top"] = player_y > 260
    end
    if options["top"] or (options["top"] == nil and self.textbox_top) then
        local bx, by = self.choicebox:getBorder()
        self.choicebox.y = by + 2
    end

    self.choicebox.active = true
    self.choicebox.visible = true

    if options["wait"] or options["wait"] == nil then
        return self:wait(waitForChoicer)
    else
        return waitForChoicer, self.choicebox
    end
end

local function waitForEncounter(self) return Game.battle == nil end
function WorldCutscene:startEncounter(encounter, transition, enemy, options)
    options = options or {}
    transition = transition ~= false
    Game:encounter(encounter, transition, enemy)
    if options.on_start then
        if transition and (type(transition) == "boolean" or transition == "TRANSITION") then
            Game.battle.timer:script(function(wait)
                while Game.battle.state == "TRANSITION" do
                    wait()
                end
                options.on_start()
            end)
        else
            options.on_start()
        end
    end
    if options.wait == false then
        return waitForEncounter
    else
        self:wait(waitForEncounter)
    end
end

function WorldCutscene:showShop()
    if self.shopbox then self.shopbox:remove() end

    self.shopbox = Shopbox()
    self.shopbox.layer = WORLD_LAYERS["textbox"]
    Game.world:addChild(self.shopbox)
    self.shopbox:setParallax(0, 0)
end

function WorldCutscene:hideShop()
    if self.shopbox then
        self.shopbox:remove()
        self.shopbox = nil
    end
end

return WorldCutscene