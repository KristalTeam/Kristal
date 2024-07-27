--- The cutscene class for cutscenes playing in the world, their scripts should be located in `scripts/world/cutscenes`. \
--- These cutscene scripts will receive a WorldCutscene as their first argument.
---
---@class WorldCutscene : Cutscene
---
---@field textbox           Textbox     The current Textbox object, if it is active.
---@field textbox_actor     Actor       The current speaker in the cutscene. 
---@field textbox_speaker   ActorSprite The ActorSprite of the current speaker.  
---@field textbox_top       boolean     Whether the textbox should display at the top of the screen instead of the bottom.
---
---@field choicebox Choicebox   The current choicer object, if it is active.
---@field choice    number      The index of the player's last selected choice.
---
---@field textchoicebox TextChoicebox   The current text choicer (choicer with additional text prompt) object, if it is active.
---@field shopbox       Shopbox         The current mini shop UI object, if it is active.
---
---@field world World   Reference to Game.world
---
---@overload fun(...) : WorldCutscene
local WorldCutscene, super = Class(Cutscene)

local function _true() return true end

function WorldCutscene:init(world, group, id, ...)
    local scene, args = self:parseFromGetter(Registry.getWorldCutscene, group, id, ...)

    self.textbox = nil
    self.textbox_actor = nil
    self.textbox_speaker = nil
    self.textbox_top = nil

    self.choicebox = nil
    self.choice = 0

    self.textchoicebox = nil

    self.shopbox = nil

    self.moving_objects = {}

    self.world = world

    Game.lock_movement = true

    if Game:isLight() then
        if self.world.menu and self.world.menu.state == "ITEMMENU" then
            self.world.menu:closeBox()
            self.world.menu.state = "TEXT"
        end
    else
        self.world:closeMenu()
    end

    super.init(self, scene, unpack(args))
end

function WorldCutscene:canEnd()
    if #self.moving_objects > 0 then
        return false
    end
    return self.world.camera.pan_target == nil
end

function WorldCutscene:update()
    local new_moving = {}
    for _,object in ipairs(self.moving_objects) do
        if object.stage and object.physics.move_target then
            table.insert(new_moving, object)
        end
    end
    self.moving_objects = new_moving

    super.update(self)
end

function WorldCutscene:onEnd()
    Game.lock_movement = false

    if self.world.cutscene == self then
        self.world.cutscene = nil
    end

    self:closeText()

    if Game:isLight() then
        if self.world.menu and self.world.menu.state == "TEXT" then
            self.world:closeMenu()
        end
    end

    super.onEnd(self)
end

--- Gets a specific character currently present in the world.
---@param id        string  The actor id of the character to search for.
---@param index?    number  The character's index, if they have multiple instances in the world. (Defaults to 1)
---@return Character|nil chara The character instance, or `nil` if it was not found.
function WorldCutscene:getCharacter(id, index)
    return self.world:getCharacter(id, index)
end

--- Gets a specific event present in the current map.
---@param id string|number  The unique numerical id of an event OR the text id of an event type to get the first instance of.
---@return Event event The event instnace, or `nil` if it was not found. 
function WorldCutscene:getEvent(id)
    return self.world.map:getEvent(id)
end

--- Gets a list of all instances of one type of event in the current map.
---@param name string The text id of the event to search for.
---@return table events A table containing every instance of the event in the current map.
function WorldCutscene:getEvents(name)
    return self.world.map:getEvents(name)
end

--- Gets a specific marker from the current map.
---@param name string The name of the marker to search for.
---@return number x The x-coordinate of the marker's center.
---@return number y The y-coordinate of the marker's center.
function WorldCutscene:getMarker(name)
    return self.world.map:getMarker(name)
end

--- Unlocks the player's movement. \
--- Happens automatically at the end of cutscenes.
function WorldCutscene:enableMovement()
    Game.lock_movement = false
end

--- Locks the player's movement. \
--- Happens automatically at the start of cutscenes.
function WorldCutscene:disableMovement()
    Game.lock_movement = true
end

--- Disables following for all of the player's current followers.
function WorldCutscene:detachFollowers()
    self.world:detachFollowers()
end

local function waitForFollowers(self)
    for _,follower in ipairs(self.world.followers) do
        if follower.returning then
            return false
        end
    end
    return true
end
--- Enables following for all of the player's current followers and causes them to walk to their following positions.
---@param return_speed? number The walking speed of the followers while they return to the player.
---@return fun(self: WorldCutscene) : boolean finished A function that returns `true` once all followers have finished returning.
function WorldCutscene:attachFollowers(return_speed)
    self.world:attachFollowers(return_speed)
    return waitForFollowers
end
--- Enables following for all of the player's current followers, and immediately teleports them to their positions.
---@return fun() : boolean finished A function that returns `true` once all followers have finished returning.
function WorldCutscene:attachFollowersImmediate()
    self.world:attachFollowersImmediate()
    return _true
end

--- Aligns the player's followers' directions and positions.
---@param facing?   string  The direction every character should face (Defaults to player's direction)
---@param x?        number  The x-coordinate of the 'front' of the line. (Defaults to player's x-position)
---@param y?        number  The y-coordinate of the 'front' of the line. (Defaults to player's y-position)
---@param dist?     number  The distance between each follower.
function WorldCutscene:alignFollowers(facing, x, y, dist)
    self.world.player:alignFollowers(facing, x, y, dist)
end

--- Adds all followers' current positions to their movement history. \
--- If followers are added or moved by the cutscene, call this at the end to prevent them from warping. 
function WorldCutscene:interpolateFollowers()
    self.world.player:interpolateFollowers()
end

--- Resets the sprites of the player and all their followers to their defaults.
function WorldCutscene:resetSprites()
    self.world.player:resetSprite()
    for _,follower in ipairs(self.world.followers) do
        follower:resetSprite()
    end
end

--- Spawns a new NPC object in the world.
---@param actor         string|Actor    The actor to use for the new NPC, either an id string or an actor object.
---@param x             number          The x-coordinate to place the NPC at.
---@param y             number          The y-coordinate to place the NPC at.
---@param properties?   table           A table of additional properties for the new NPC. Supports all the same values as an `npc` map event.
---@return NPC npc The newly created npc.
function WorldCutscene:spawnNPC(actor, x, y, properties)
    return self.world:spawnNPC(actor, x, y, properties)
end

--- Makes a character look in a specific direction.
---@param chara?    Character|string    The Character or id of the character that should face down. (Defaults to the player)
---@param dir?      string              The direction the character should face. Must be either "up", "dowm", "left", or "right". (Defaults to "down")
function WorldCutscene:look(chara, dir)
    if not dir then
        ---@diagnostic disable-next-line: cast-local-type
        dir = chara or "down"
        chara = self.world.player
    elseif type(chara) == "string" then
        chara = self:getCharacter(chara)
    end
    chara:setFacing(dir)
end

--- Walks a character to a new `x` and `y` over `time` seconds.
---@overload fun(self: WorldCutscene, chara: Character|string, marker: string, time?: number, facing?: string, keep_facing?: boolean, after?: fun())
---@param chara         Character|string        The Character instance or id to make walk.
---@param x             number                  The new `x` value to approach.
---@param y             number                  The new `y` value to approach.
---@param marker        string                  A map marker whose position the character should approach.
---@param time?         number                  The amount of time, in seconds, that the walk should take. (Defaults to 1 second)
---@param facing?       string                  The direction the character should face when they finish their walk. If `keep_facing` is `true`, they will instead face way immediately.
---@param keep_facing?  boolean                 If `true`, the facing direction of the character will be preserved. Otherwise, they will face the direction they are walking. (Defaults to `false`)
---@param ease?         easetype                The easing to use for the character's walk motion.
---@param after?        fun(chara: Character)   A callback function that is run after the character has finished walking.
---@return fun(): boolean finished A function that returns `true` once the character has finished walking.
function WorldCutscene:walkTo(chara, x, y, time, facing, keep_facing, ease, after)
    if type(chara) == "string" then
        chara = self:getCharacter(chara)
    end
    local walked = false
    if chara:walkTo(x, y, time, facing, keep_facing, ease, after) then
        chara.physics.move_target.after = Utils.override(chara.physics.move_target.after, function(orig) orig() walked = true end)
        table.insert(self.moving_objects, chara)
        return function() return walked end
    else
        return _true
    end
end

--- Walks a character to a new `x` and `y` at `speed` pixels per frame.
---@overload fun(self: WorldCutscene, chara: Character|string, marker: string, speed?: number, facing?: string, keep_facing?: boolean, after?: fun())
---@param chara         Character|string        The Character instance or id to make walk.
---@param x             number                  The new `x` value to approach.
---@param y             number                  The new `y` value to approach.
---@param marker        string                  A map marker whose position the character should approach.
---@param speed?        number                  The amount that the character's `x` and `y` should approach the specified position, in pixels per frame at 30FPS. (Defaults to `4`)
---@param facing?       string                  The direction the character should face when they finish their walk. If `keep_facing` is `true`, they will instead face way immediately.
---@param keep_facing?  boolean                 If `true`, the facing direction of the character will be preserved. Otherwise, they will face the direction they are walking. (Defaults to `false`)
---@param after?        fun(chara: Character)   A callback function that is run after the character has finished walking.
---@return fun(): boolean finished A function that returns `true` once the character has finished walking.
function WorldCutscene:walkToSpeed(chara, x, y, speed, facing, keep_facing, after)
    if type(chara) == "string" then
        chara = self:getCharacter(chara)
    end
    local walked = false
    if chara:walkToSpeed(x, y, speed, facing, keep_facing, after) then
        chara.physics.move_target.after = Utils.override(chara.physics.move_target.after, function(orig) orig() walked = true end)
        table.insert(self.moving_objects, chara)
        return function() return walked end
    else
        return _true
    end
end

--- Walks a character along a path.
---@param chara     Character|string    The Character instance or id to make walk.
---@param path      string|table        The name of a path in the current map file, or a table defining several points (as additional tables) that constitute a path.
---@param options?  table               A table defining additional properties to control the walk.
---|"facing" # The direction the character should face when they finish their walk. If `keep_facing` is `true`, they will instead face way immediately.
---|"keep_facing" # If `true`, the facing direction of the character will be preserved. Otherwise, they will face the direction they are walking. (Defaults to `false`)
---| "time" # The amount of time, in seconds, that the object should take to travel along the full path.
---| "speed" # The speed at which the object should travel along the path, in pixels per frame at 30FPS.
---| "ease" # The ease type to use when travelling along the path. Unused if `speed` is specified instead of `time`. (Defaults to "linear")
---| "after" # A function that will be called when the end of the path is reached. Receives no arguments.
---| "relative" # Whether the path should be relative to the object's current position, or simply set its position directly.
---| "loop" # Whether the path should loop back to the first point when reaching the end, or if it should stop.
---| "reverse" # If true, reverse all of the points on the path.
---| "skip" # A number defining how many points of the path to skip.
---| "snap" # Whether the object's position should immediately "snap" to the first point, or if its initial position should be counted as a point on the path.
---@return fun() : boolean finished Returns `true` when the character has reached the end of the path.
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

--- Sets the sprite of a particular character.
---@param chara     string|Character    The Character or character id to change the sprite of.
---@param sprite?   string              The name of the sprite to be set.
---@param speed?    number              The time, in seconds, between frames for the sprite, if it has multiple frames. (Defaults to 1/30)
function WorldCutscene:setSprite(chara, sprite, speed)
    if type(chara) == "string" then
        chara = self:getCharacter(chara)
    end
    chara:setSprite(sprite)
    if speed then
        chara:play(speed, true)
    end
end

--- Sets the animation of a particular character. 
---@param chara string|Character        The Character or character id to change the animation of.
---@param anim? string                  The name of the animation to be set.
---@return fun() : boolean finished A function that returns `true` once the animation has finished.
function WorldCutscene:setAnimation(chara, anim)
    if type(chara) == "string" then
        chara = self:getCharacter(chara)
    end
    local done = false
    chara:setAnimation(anim, function() done = true end)
    return function() return done end
end

--- Resets the sprite of a specific character to its default.
---@param chara string|Character The Character or character id to reset the sprite of.
function WorldCutscene:resetSprite(chara)
    if type(chara) == "string" then
        chara = self:getCharacter(chara)
    end
    chara:resetSprite()
end

--- Causes a specific character to start spinning.
---@param chara string|Character    The Character of character id to spin.
---@param speed number              The spin speed to set on the character. Negative numbers = anticlockwise, positive numbers = clockwise. Higher value = slower spin.
function WorldCutscene:spin(chara, speed)
    if type(chara) == "string" then
        chara = self:getCharacter(chara)
    end
    chara:spin(speed)
end

--- Moves the object's `x` and `y` values to the new specified position over `time` seconds.
---@overload fun(self:WorldCutscene, obj:Object|string, marker:string, time?:number, ease?:string, after?:function) : finished: fun(): boolean
---@param obj    Object|string  The object instance or id of a character to slide.
---@param x      number         The new `x` value to approach.
---@param y      number         The new `y` value to approach.
---@param marker string         A map marker whose position the object should approach.
---@param time?  number         The amount of time, in seconds, that the slide should take. (Defaults to 1 second)
---@param ease?  easetype       The ease type to use when moving to the new position. (Defaults to "linear")
---@return fun() : boolean finished A function that returns `true` once the object has reached its destination.
function WorldCutscene:slideTo(obj, x, y, time, ease)
    if type(obj) == "string" then
        obj = self:getCharacter(obj)
    end
    if type(x) == "string" then
        ---@diagnostic disable-next-line: cast-local-type
        ease = time
        time = y
        x, y = self.world.map:getMarker(x)
    end
    local slided = false
    if obj:slideTo(x, y, time, ease, function() slided = true end) then
        table.insert(self.moving_objects, obj)
        return function() return slided end
    else
        return _true
    end
end

--- Moves the object's `x` and `y` values to the new specified position at a speed of `speed` pixels per frame.
---@overload fun(self:WorldCutscene, obj:Object|string, marker:string, speed?:number, ease?:string) : finished: fun(): boolean
---@param obj    Object|string      The object instance or id of a character to slide.
---@param x      number             The new `x` value to approach.
---@param y      number             The new `y` value to approach.
---@param marker string             A map marker whose position the object should approach.
---@param speed? number             The amount that the object's `x` and `y` should approach the specified position, in pixels per frame at 30FPS. (Defaults to `4`)
---@return fun() : boolean finished A function that returns `true` once the object has reached its destination.
function WorldCutscene:slideToSpeed(obj, x, y, speed)
    if type(obj) == "string" then
        obj = self:getCharacter(obj)
    end
    if type(x) == "string" then
        speed = y
        x, y = self.world.map:getMarker(x)
    end
    local slided = false
    if obj:slideToSpeed(x, y, speed, function() slided = true end) then
        table.insert(self.moving_objects, obj)
        return function() return slided end
    else
        return _true
    end
end

--- Slides an object along a path.
---@param obj       Object|string   The object instance or id of a character to slide.
---@param path      string|table    The name of a path in the current map file, or a table defining several points (as additional tables) that constitute a path.
---@param options?  table           A table defining additional properties that the slide should use.
---| "time" # The amount of time, in seconds, that the object should take to travel along the full path.
---| "speed" # The speed at which the object should travel along the path, in pixels per frame at 30FPS.
---| "ease" # The ease type to use when travelling along the path. Unused if `speed` is specified instead of `time`. (Defaults to "linear")
---| "after" # A function that will be called when the end of the path is reached. Receives no arguments.
---| "move_func" # A function called every frame while the object is travelling along the path. Receives `self` and the `x` and `y` offset from the previous frame as arguments.
---| "relative" # Whether the path should be relative to the object's current position, or simply set its position directly.
---| "loop" # Whether the path should loop back to the first point when reaching the end, or if it should stop.
---| "reverse" # If true, reverse all of the points on the path.
---| "skip" # A number defining how many points of the path to skip.
---| "snap" # Whether the object's position should immediately "snap" to the first point, or if its initial position should be counted as a point on the path.
---@return function finished Returns `true` when the object has reached the end of the path.
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

--- Moves a character to a new position with a jumping arc motion.
---@param chara     Character|string    The Character instance or id to make jump.
---@param ...       unknown             Additional arguments to pass to chara:jumpTo().
---@see Character.jumpTo for the arguments to set up a jump.
---@return function finished A function that returns `true once the character has completed their jump.
function WorldCutscene:jumpTo(chara, ...)
    if type(chara) == "string" then
        chara = self:getCharacter(chara)
    end
    chara:jumpTo(...)
    return function() return not chara.jumping end
end

--- Shakes a character by the specified `x`, `y`.
---@param chara     string|Character    The character being shaken. Accepts either a Character instance or the id of a character.
---@param x?        number              The amount of shake in the `x` direction. (Defaults to `4`)
---@param y?        number              The amount of shake in the `y` direction. (Defaults to `0`)
---@param friction? number              The amount that the shake should decrease by, per frame at 30FPS. (Defaults to `1`)
---@param delay?    number              The time it takes for the object to invert its shake direction, in seconds. (Defaults to `1/30`)
---@return fun() : boolean finished A function that returns `true` once the shake value has returned to 0.
function WorldCutscene:shakeCharacter(chara, x, y, friction, delay)
    if type(chara) == "string" then
        chara = self:getCharacter(chara)
    end
    chara:shake(x, y, friction, delay)
    return function() return chara.sprite.graphics.shake_x == 0 and chara.sprite.graphics.shake_y == 0 end
end

--- Shakes the camera by the specified `x`, `y`.
---@param x?        number      The amount of shake in the `x` direction. (Defaults to `4`)
---@param y?        number      The amount of shake in the `y` direction. (Defaults to `4`)
---@param friction? number      The amount that the shake should decrease by, per frame at 30FPS. (Defaults to `1`)
---@return fun() : boolean finished    A function that returns `true` once the shake value has returned to `0`.
function WorldCutscene:shakeCamera(x, y, friction)
    self.world.camera:shake(x, y, friction)
    return function() return self.world.camera.shake_x == 0 and self.world.camera.shake_y == 0 end
end

--- Creates an alert bubble above a character.
---@param chara     string|Character    The character or character id to trigger an alert bubble for.
---@param ...       unknown             Arguments to be passed to Character:alert().
---@return Sprite   alert_icon          The result alert icon created above the character's head.
---@return fun()    finished            A function that returns `true` once the alert icon has disappeared. \
---@see Character.alert for details on the arguments to pass to this function.
function WorldCutscene:alert(chara, ...)
    if type(chara) == "string" then
        chara = self:getCharacter(chara)
    end
    local function waitForAlertRemoval() return chara.alert_icon == nil or chara.alert_timer == 0 end
    return chara:alert(...), waitForAlertRemoval
end

--- Detaches the camera from the player character.
function WorldCutscene:detachCamera()
    self.world:setCameraAttached(false)
end

--- Smoothly pans the camera to the player and then attaches it.
---@param time? number The time, in seconds, that the camera will spend panning to the player's position. (Defaults to `0.8`)
---@return fun(self: WorldCutscene) finished A function that returns true once the camera panning is complete.
function WorldCutscene:attachCamera(time)
    local tx, ty = self.world.camera:getTargetPosition()
    return self:panTo(tx, ty, time or 0.8, "linear", function() self.world:setCameraAttached(true) end)
end
--- Attaches the camera to the player instantly.
function WorldCutscene:attachCameraImmediate()
    local tx, ty = self.world.camera:getTargetPosition()
    self.world:setCameraAttached(true)
    self.world.camera:setPosition(tx, ty)
end

--- Sets the current speaker for dialogue boxes in this cutscene.
---@param actor?    Character|string    The Character instance or character id to set as the speaker.
---@param talk?     boolean             If `false`, the actor of the textbox will be set, but not the speaking character in the world for talking animations.
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

--- Sets whether the textbox should appear at the top of the screen or the bottom.
---@param top boolean Whether the textbox should appear at the top of the screen.
function WorldCutscene:setTextboxTop(top)
    self.textbox_top = top
end

---@param self WorldCutscene
local function waitForCameraPan(self) return self.world.camera.pan_target == nil end

--- Pans tha camera to a new position over a given `time`.
---@overload fun(self: WorldCutscene, x: number, y: number, time?: number, ease?: easetype, after?: fun()) : fun(self: WorldCutscene)
---@overload fun(self: WorldCutscene, marker: string, time?: number, ease?: easetype, after?: fun()) : fun(self: WorldCutscene)
---@overload fun(self: WorldCutscene, chara: Character, time?: number, ease?: easetype, after?: fun()) : fun(self: WorldCutscene)
---@overload fun() : fun(self: WorldCutscene)
---@param x         number      The x-coordinate to pan the camera to.
---@param y         number      The y-coordinate to pan the camera to.
---@param marker    string      The name of a marker in the current map to pan the camera to.
---@param chara     Character   A Character instance in the current map to pan the camera to. (Does not attach the camera)
---@param time?     number      The time, in seconds, that the camera should spend panning to the target. Defaults to 1 second.
---@param ease?     easetype    The easing to use for the panning.
---@param after?    fun()       A function that is run once the camera reaches its panning target.
---@return fun(self: WorldCutscene) finished A function that returns true once the camera panning is complete.
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
        local marker = self.world.map.markers[args[1]]
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
        x, y = self.world:getCameraTarget():getPosition()
    end
    local result = self.world.camera:panTo(x, y, time, ease, after)
    if not result and after then
        after()
    end
    return waitForCameraPan
end

--- Pans the camer to a new position at a given `speed`.
---@overload fun(self: WorldCutscene, x: number, y: number, speed?: number, after?: fun()) : fun(self: WorldCutscene)
---@overload fun(self: WorldCutscene, marker: string, speed?: number, after?: fun()) : fun(self: WorldCutscene)
---@overload fun(self: WorldCutscene, chara: Character, speed?: number, after?: fun()) : fun(self: WorldCutscene)
---@overload fun() : fun(self: WorldCutscene)
---@param x         number      The x-coordinate to pan the camera to.
---@param y         number      The y-coordinate to pan the camera to.
---@param marker    string      The name of a marker in the current map to pan the camera to.
---@param chara     Character   A Character instance in the current map to pan the camera to. (Does not attach the camera)
---@param speed?    number      The speed, in pixels per frame at 30FPS, that the camera should move towards its target. Defaults to `4`.
---@param after?    fun()       A function that is run once the camera reaches its panning target.
function WorldCutscene:panToSpeed(...)
    local args = {...}
    local x, y = 0, 0
    local speed = 4
    local after = nil
    if type(args[1]) == "number" then
        x, y = args[1], args[2]
        speed = args[3] or speed
        after = args[4]
    elseif type(args[1]) == "string" then
        local marker = self.world.map.markers[args[1]]
        x, y = marker.center_x, marker.center_y
        speed = args[2] or speed
        after = args[3]
    elseif isClass(args[1]) and args[1]:includes(Character) then
        local chara = args[1]
        x, y = chara:getRelativePos(chara.width/2, chara.height/2)
        speed = args[2] or speed
        after = args[3]
    else
        x, y = self.world:getCameraTarget():getPosition()
    end
    local result = self.world.camera:panToSpeed(x, y, speed, after)
    if not result and after then
        after()
    end
    return waitForCameraPan
end

--- Loads a new map and starts the transition effects for world music, borders, and the screen as a whole.
---@overload fun(self: WorldCutscene, map: string, ...: any) : finished: fun(): boolean
---@param ... any   Additional arguments that will be passed into World:loadMap()
---@see World.loadMap for the arguments to pass into World:loadMap().
---@return fun() : boolean finished A function that returns true once the map transition has finished. \
function WorldCutscene:mapTransition(...)
    self.world:mapTransition(...)
    return function() return self.world.state ~= "FADING" end
end

--- Loads into a new map file.
---@overload fun(self: WorldCutscene, map: string, x: number, y: number, facing?: string, callback?: string, ...: any)
---@overload fun(self: WorldCutscene, map: string, marker?: string, facing?: string, callback?: string, ...: any)
---@param map       string      The name of the map file to load.
---@param x         number      The x-coordinate the player will spawn at in the new map.
---@param y         number      The y-coordinate the player will spawn at in the new map.
---@param marker?   string      The name of the marker the player will spawn at in the new map. Defaults to `"spawn"`
---@param facing?   string      The direction the party should be facing when they spawn in the new map.
---@param callback? fun()       A callback to run once the map has finished loading (Post Map:onEnter())
---@param ... unknown           Additional arguments that will be passed forward into Map:onEnter().
function WorldCutscene:loadMap(...)
    self.world:loadMap(...)
end

--- Fades the screen and music out.
---@param speed?    number       The speed to fade out at, in seconds. (Defaults to `0.25`)
---@param options?  table        A table defining additional properties to control the fade.
---| "global"   # Whether to use the global Game fader, instead of a fader specifically assigned to the current world. (Defaults to `false`)
---| "color"    # The color that should be faded to (Defaults to `COLORS.black`)
---| "alpha"    # The alpha to start at (Defaults to `0`)
---| "blocky"   # Whether to do a rough, 'blocky' fade. (Defaults to `false`)
---| "music"    # The speed to fade the music at, or whether to fade it at all (Defaults to fade speed)
---@return function finished    A function that returns true once the fade has finished.
function WorldCutscene:fadeOut(speed, options)
    options = options or {}

    local fader = options["global"] and Game.fader or self.world.fader

    if speed then
        options["speed"] = speed
    end

    local fade_done = false

    fader:fadeOut(function() fade_done = true end, options)

    return function() return fade_done end
end

--- Fades the screen and music back in after a fade out.
---@param speed?    number  The speed to fade in at, in seconds (Defaults to last fadeOut's speed.)
---@param options?  table   A table defining additional properties to control the fade.
---| "global"   # Whether to use the global Game fader, instead of a fader specifically assigned to the current world. (Defaults to `false`)
---| "color"    # The color that should be faded to (Defaults to last fadeOut's color)
---| "alpha"    # The alpha to start at (Defaults to `1`)
---| "blocky"   # Whether to do a rough, 'blocky' fade. (Defaults to `false`)
---| "music"    # The speed to fade the music at, or whether to fade it at all (Defaults to fade speed)
---@return function finished    A function that returns true once the fade has finished.
function WorldCutscene:fadeIn(speed, options)
    options = options or {}

    local fader = options["global"] and Game.fader or self.world.fader

    if speed then
        options["speed"] = speed
    end

    local fade_done = false

    fader:fadeIn(function() fade_done = true end, options)

    return function() return fade_done end
end

-- DOC Note: WorldCutscene:text() is a chunky function (for good reason) but
-- there's two optional properties - "functions" and "reactions", that are
-- woefully large (and honestly i just copied and tweaked the GitHub wiki 
-- descriptions) and they don't just appear here (see BattleCutscene:text())
-- we could do with somewhere dedicated to these two because it REALLY feels like
-- they aren't done justice here. Seeing their relation with text - it'd be nice
-- to move their explanations to a wiki page about text rather than being stuffed
-- up in these functions.

local function waitForTextbox(self) return not self.textbox or self.textbox:isDone() end
--- Creates a new textbox and starts typing the given `text` into it. \
--- Will pause the cutscene until the textbox is closed, unless otherwise specified via `options`.
---@overload fun(self: WorldCutscene, text: string, options?: table) : (finished:(fun():boolean), textbox: Textbox?)
---@overload fun(self: WorldCutscene, text: string, portrait?: string, options?: table) : (finished:(fun():boolean), textbox: Textbox?)
---@param text      string                      The text to be typed.
---@param portrait? string|nil                  The name of the character portrait to use for this textbox.
---@param actor?    Character|Actor|string|nil  The Character/Actor to be used for voice bytes and portraits, overriding the active cutscene speaker.
---@param options?  table                       A table definining additional properties to control the textbox.
---|"talk"      # If a `Character` instance is attached to the textbox, whether they should use their talk sprite in world. 
---|"top"       # Override for the default textbox position, defining whether the textbox should appear at the top of the screen.
---|"x"         # The x-offset of the dialgoue portrait.
---|"y"         # The y-offset of the dialogue portrait.
---|"reactions" # A table of tables that define "reaction" dialogues. Each table defines the dialogue, x and y position of the face, actor and face sprite, in that order. x and y can be strings as well, referring to existing positions; x can be left, leftmid, mid, middle, rightmid, or right, and y can be top, mid, middle, bottommid, and bottom. Must be used in combination with a react text command.
---|"functions" # A table defining additional functions that can be used in the text with the `func` text command. Each key, value pair will form the id to use with `func` and the function to be called, respectively.
---|"font"      # The font to be used for this text. Can optionally be defined as a table {font, size} to also set the text size.
---|"align"     # Sets the alignment of the text.
---|"skip"      # If false, the player will be unable to skip the textbox with the cancel key.
---|"advance"   # When `false`, the player cannot advance the textbox, and the cutscene will no longer suspend itself on the dialogue by default.
---|"auto"      # When `true`, the text will auto-advance after the last character has been typed.
---|"wait"      # Whether the cutscene should automatically suspend itself until the textbox advances. (Defaults to `true`, unless `advance` is false.)
---@return fun() : boolean  finished    A function that returns `true` once the textbox has closed. (Only use if `options["wait"]` is set to `false`.)
---@return Textbox?         textbox     The Textbox object that has been created. (Only use if `options["wait"]` is set to `false`.)
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

    self:closeText()

    local width, height = 529, 103
    if Game:isLight() then
        width, height = 530, 104
    end

    self.textbox = Textbox(56, 344, width, height)
    self.textbox.layer = WORLD_LAYERS["textbox"]
    self.world:addChild(self.textbox)
    self.textbox:setParallax(0, 0)

    if type(actor) == "string" then
        actor = self:getCharacter(actor) or actor
    end

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
        local _, player_y = self.world.player:localToScreenPos()
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

--- Closes the currently active textboxes, choicers and textchoicers, if they are open.
function WorldCutscene:closeText()
    if self.textbox then
        self.textbox:remove()
        self.textbox = nil
    end

    if self.choicebox then
        self.choicebox:remove()
        self.choicebox = nil
    end

    if self.textchoicebox then
        self.textchoicebox:remove()
        self.textchoicebox = nil
    end
end

local function waitForChoicer(self) return self.choicebox.done, self.choicebox.selected_choice end
--- Creates a choicer with the choices specified in `choices` for the player to select from.
---@param choices  table A table of strings specifying the choices the player can select. Maximum of four.
---@param options? table A table defining additional properties to control the choicer.
---|"top"       # Override for the default textbox position, defining whether the choicer should appear at the top of the screen.
---|"color"     # The main color to set all the choices to, or a table of main colors to set for different choices. (Defaults to `COLORS.white`)
---|"highlight" # The color to highlight the selected choice in, or a table of colors to highlight different choices in when selected. (Defaults to `COLORS.yellow`)
---|"wait"      # Whether the cutscene should automatically suspend itself until the player makes their choice. (Defaults to `true`)
---@return number|function selected The index of the selected item if the cutscene has been set to wait for the choicer, otherwise a boolean that states whether the player has made their choice.
---@return Choicebox? choicer The choicebox object for this choicer. Only returned if wait is `false`. 
function WorldCutscene:choicer(choices, options)
    self:closeText()

    local width, height = 529, 103
    if Game:isLight() then
        width, height = 530, 104
    end

    self.choicebox = Choicebox(56, 344, width, height, false, options)
    self.choicebox.layer = WORLD_LAYERS["textbox"]
    self.world:addChild(self.choicebox)
    self.choicebox:setParallax(0, 0)

    for _,choice in ipairs(choices) do
        self.choicebox:addChoice(choice)
    end

    options = options or {}
    if options["top"] == nil and self.textbox_top == nil then
        local _, player_y = self.world.player:localToScreenPos()
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

local function waitForTextChoicer(self) return not self.textchoicebox or self.textchoicebox:isDone(), self.textchoicebox.selected_choice end
--- Creates a Text Choicer - A textbox that includes both dialogue and a choicer.
---@param text      string                      The text to be typed.
---@param choices   table                       A table of strings specifying the choices the player can select.
---@param portrait? string|nil                  The name of the character portrait to use for this textbox.
---@param actor?    Character|Actor|string|nil  The Character/Actor to be used for voice bytes and portraits, overriding the active cutscene speaker.
---@param options?  table                       A table definining additional properties to control the textbox.
---|"talk"      # If a `Character` instance is attached to the textbox, whether they should use their talk sprite in world. 
---|"top"       # Override for the default textbox position, defining whether the textbox should appear at the top of the screen.
---|"x"         # The x-offset of the dialgoue portrait.
---|"y"         # The y-offset of the dialogue portrait.
---|"reactions" # A table of tables that define "reaction" dialogues. Each table defines the dialogue, x and y position of the face, actor and face sprite, in that order. x and y can be strings as well, referring to existing positions; x can be left, leftmid, mid, middle, rightmid, or right, and y can be top, mid, middle, bottommid, and bottom. Must be used in combination with a react text command.
---|"functions" # A table defining additional functions that can be used in the text with the `func` text command. Each key, value pair will form the id to use with `func` and the function to be called, respectively.
---|"font"      # The font to be used for this text. Can optionally be defined as a table {font, size} to also set the text size.
---|"align"     # Sets the alignment of the text.
---|"skip"      # If false, the player will be unable to skip the textbox with the cancel key.
---|"wait"      # Whether the cutscene should automatically suspend itself until the player selects a choice. (Defaults to `true`)
---@return fun() : boolean  finished    A function that returns `true` once the textbox has closed. (Only use if `options["wait"]` is set to `false`.)
---@return TextChoicebox    textbox     The TextboxChoicer object that has been created. (Only use if `options["wait"]` is set to `false`.)
function WorldCutscene:textChoicer(text, choices, portrait, actor, options)
    if type(actor) == "table" and not isClass(actor) then
        options = actor
        actor = nil
    end
    if type(portrait) == "table" then
        options = portrait
        portrait = nil
    end

    options = options or {}

    self:closeText()

    local width, height = 529, 103
    if Game:isLight() then
        width, height = 530, 104
    end

    self.textchoicebox = TextChoicebox(56, 344, width, height)
    self.textchoicebox.layer = WORLD_LAYERS["textbox"]
    self.world:addChild(self.textchoicebox)
    self.textchoicebox:setParallax(0, 0)

    for _,choice in ipairs(choices) do
        self.textchoicebox:addChoice(choice)
    end

    if type(actor) == "string" then
        actor = self:getCharacter(actor) or actor
    end

    local speaker = self.textbox_speaker
    if not speaker and isClass(actor) and actor:includes(Character) then
        speaker = actor.sprite
    end

    if options["talk"] ~= false then
        self.textchoicebox.text.talk_sprite = speaker
    end

    actor = actor or self.textbox_actor
    if isClass(actor) and actor:includes(Character) then
        actor = actor.actor
    end
    if actor then
        self.textchoicebox:setActor(actor)
    end

    if options["top"] == nil and self.textbox_top == nil then
        local _, player_y = self.world.player:localToScreenPos()
        options["top"] = player_y > 260
    end
    if options["top"] or (options["top"] == nil and self.textbox_top) then
       local bx, by = self.textchoicebox:getBorder()
       self.textchoicebox.y = by + 2
    end

    self.textchoicebox.active = true
    self.textchoicebox.visible = true
    self.textchoicebox:setFace(portrait, options["x"], options["y"])

    if options["reactions"] then
        for id,react in pairs(options["reactions"]) do
            self.textchoicebox:addReaction(id, react[1], react[2], react[3], react[4], react[5])
        end
    end

    if options["functions"] then
        for id,func in pairs(options["functions"]) do
            self.textchoicebox:addFunction(id, func)
        end
    end

    if options["font"] then
        if type(options["font"]) == "table" then
            -- {font, size}
            self.textchoicebox:setFont(options["font"][1], options["font"][2])
        else
            self.textchoicebox:setFont(options["font"])
        end
    end

    if options["align"] then
        self.textchoicebox:setAlign(options["align"])
    end

    self.textchoicebox:setSkippable(options["skip"] or options["skip"] == nil)

    self.textchoicebox:setText(text, function()
        self.textchoicebox:remove()
        self:tryResume()
    end)

    if options["wait"] or options["wait"] == nil then
        return self:wait(waitForTextChoicer)
    else
        return waitForTextChoicer, self.textchoicebox
    end
end

--- Starts an encounter within the current cutscene. \
--- The cutscene will resume at the end of the encounter, once the transition out from battle is complete.
---@param encounter     Encounter|string    The encounter id or instance to use for this battle.
---@param transition?   boolean|string      Whether to start in the transition state (Defaults to `true`). As a string, represents the state to start the battle in.
---@param enemy?        Character|table     An enemy instance or list of enemies as `Character`s in the world that will transition into the battle.
---@param options?      table               A table defining additional properties to control the encounter.
---|"on_start"  # A callback that is run when the battle starts (Exits the `"TRANSITION"` state). Runs immediately if the transition is skipped.
---|"wait"      # Whether the cutscene should be suspended until the encounter is complete. (Deftualts to `true`)
---@return fun()        finished    A function that returns `true` when the encounter has finished. (Only use if options.wait is set to `false`)
---@return Encounter?   encounter   The Encounter instance for the battle started by this function call. (Only use if options.wait is set to `false`)
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

    local battle_encounter = Game.battle.encounter
    local function waitForEncounter(self) return (Game.battle == nil), battle_encounter end

    if options.wait == false then
        return waitForEncounter, battle_encounter
    else
        return self:wait(waitForEncounter)
    end
end

--- Shows the mini shop UI.
function WorldCutscene:showShop()
    if self.shopbox then self.shopbox:remove() end

    self.shopbox = Shopbox()
    self.shopbox.layer = WORLD_LAYERS["textbox"]
    self.world:addChild(self.shopbox)
    self.shopbox:setParallax(0, 0)
end

--- Hides the mini shop UI.
function WorldCutscene:hideShop()
    if self.shopbox then
        self.shopbox:remove()
        self.shopbox = nil
    end
end

return WorldCutscene