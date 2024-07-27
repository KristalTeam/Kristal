--- The cutscene class for cutscenes running in battles, their scripts should be located in `scripts/battle/cutscenes/`. \
--- These cutscene scripts will receive a BattleCutscene as their first argument.
---
---@class BattleCutscene : Cutscene
---@overload fun(...) : BattleCutscene
local BattleCutscene, super = Class(Cutscene)

local function _true() return true end

function BattleCutscene:init(group, id, ...)
    local scene, args = self:parseFromGetter(Registry.getBattleCutscene, group, id, ...)

    self.changed_sprite = {}
    self.move_targets = {}
    self.waiting_for_text = nil
    self.waiting_for_enemy_text = nil

    self.last_battle_state = Game.battle.state
    Game.battle:setState("CUTSCENE")

    super.init(self, scene, unpack(args))
end

function BattleCutscene:update()
    if self.ended then return end

    local done_moving = {}
    for battler,target in pairs(self.move_targets) do
        if battler.x == target[1] and battler.y == target[2] then
            table.insert(done_moving, battler)
        end
        local tx = Utils.approach(battler.x, target[1], target[3] * DTMULT)
        local ty = Utils.approach(battler.y, target[2], target[3] * DTMULT)
        battler:setPosition(tx, ty)
    end
    for _,v in ipairs(done_moving) do
        self.move_targets[v] = nil
    end

    super.update(self)
end

function BattleCutscene:onEnd()
    if Game.battle.cutscene == self then
        Game.battle.cutscene = nil
    end

    if Game.battle.battle_ui then
        Game.battle.battle_ui:clearEncounterText()

        Game.battle.battle_ui.encounter_text.active = true
        Game.battle.battle_ui.encounter_text.visible = true

        Game.battle.battle_ui.choice_box:clearChoices()
        Game.battle.battle_ui.choice_box.active = false
        Game.battle.battle_ui.choice_box.visible = false
    end

    self:resetSprites()

    self.move_targets = {}

    if self.finished_callback then
        self.finished_callback(self)
    else
        Game.battle:setState(self.last_battle_state, "CUTSCENE")
    end
end

--- Gets the first instance of a specific party or enemy character in the current battle.
---@param id string The character id to search for.
---@return PartyBattler|EnemyBattler|nil battler The PartyBattler/EnemyBattler instance of the character if they exist, otherwise `nil`.
function BattleCutscene:getCharacter(id)
    for _,battler in ipairs(Game.battle.party) do
        if battler.chara.id == id then
            return battler
        end
    end
    for _,battler in ipairs(Game.battle.enemies) do
        if battler.id == id then
            return battler
        end
    end
end

--- Gets all enemies with the specified id in the current battle.
---@param id string The enemy id to search for.
---@return table enemies A table containing all matched EnemyBattler instances.
function BattleCutscene:getEnemies(id)
    local result = {}
    for _,battler in ipairs(Game.battle.enemies) do
        if battler.id == id then
            table.insert(result, battler)
        end
    end
    return result
end

--- Gets the character that is performing the current action.
---@return PartyBattler battler The PartyBattler performing the current action.
function BattleCutscene:getUser()
    return Game.battle.party[Game.battle:getCurrentAction().character_id]
end

--- Gets the character being targetted of the current action.
---@return Battler target The target Battler of the current action.
function BattleCutscene:getTarget()
    return Game.battle:getCurrentAction().target
end

--- Resets the sprites of characters who have had their sprites changed in this cutscene. \
--- Called in BattleCutscene:onEnd() automatically.
function BattleCutscene:resetSprites()
    for battler,_ in pairs(self.changed_sprite) do
        battler:toggleOverlay(false)
    end
    self.changed_sprite = {}
end

--- Sets the sprite of a particular character. \
--- The change lasts until the end of the cutscene or until the sprite is changed again.
---@param chara     string|Battler  The character to change the sprite of. Accepts either a Battler instance or an id to search for.
---@param sprite?   string          The name of the sprite to be set.
---@param speed?    number          The time, in seconds, between frames for the sprite, if it has multiple frames. (Defaults to 1/30)
function BattleCutscene:setSprite(chara, sprite, speed)
    if type(chara) == "string" then
        chara = self:getCharacter(chara)
    end
    chara:toggleOverlay(true)
    chara.overlay_sprite:setSprite(sprite)
    if speed then
        chara.overlay_sprite:play(speed, true)
    end
    self.changed_sprite[chara] = true
end

--- Sets the animation of a particular character. \
--- The change lasts until the end of the cutscene or until the animation is changed again.
---@param chara string|Battler  The character to change the sprite of. Accepts either a Battler instance or an id to search for.
---@param anim? string          The name of the animation to be set.
---@return fun() : boolean finished A function that returns `true` once the animation has finished.
function BattleCutscene:setAnimation(chara, anim)
    if type(chara) == "string" then
        chara = self:getCharacter(chara)
    end
    local done = false
    chara:toggleOverlay(true)
    chara.overlay_sprite:setAnimation(anim, function() done = true end)
    self.changed_sprite[chara] = true
    return function() return done end
end

--- *(Deprecated)* Linearly moves a character to a new position (`x`, `y`) over time at a rate of `speed` pixels per frame.
---@param chara     string|Battler  The character being moved. Accepts either a Battler instance or an id to search for.
---@param x         number          The new x-coordinate to approach.
---@param y         number          The new y-coordinate to approach.
---@param speed?    number          The amount the character's `x` and `y` should approach their new position by every frame, in pixels per frame at 30FPS. (Defaults to `4`)
---@return fun() : boolean finished A function that returns `true` once the movement has finished.
---@deprecated use :slideToSpeed() instead.
function BattleCutscene:moveTo(chara, x, y, speed)
    if type(chara) == "string" then
        chara = self:getCharacter(chara)
    end
    if chara.x ~= x or chara.y ~= y then
        self.move_targets[chara] = {x, y, speed or 4}

        return function() return self.move_targets[chara] == nil end
    end
    return _true
end

--- Moves a character to a new position (`x`, `y`) over `time` seconds. \ 
--- Supports easing.
---@param obj   string|Battler  The character being moved. Accepts either a Battler instance or an id to search for.
---@param x     number          The new x-coordinate to approach.
---@param y     number          The new y-coordinate to approach.
---@param time? number          The amount of time, in seconds, that the slide should take. (Defaults to 1 second)
---@param ease? easetype        The ease type to use when moving position. (Defaults to "linear")
---@return fun() : boolean finished A function that returns `true` once the movement is finished.
function BattleCutscene:slideTo(obj, x, y, time, ease)
    if type(obj) == "string" then
        obj = self:getCharacter(obj)
    end
    local slided = false
    if obj:slideTo(x, y, time, ease, function() slided = true end) then
        return function() return slided end
    else
        return _true
    end
end

--- Linearly moves a character to a new position (`x`, `y`) over time at a rate of `speed` pixels per frame.
---@param obj       string|Battler The character being moved. Accepts either a Battler instance or an id to search for.
---@param x         number The new x-coordinate to approach.
---@param y         number The new y-coordinate to approach.
---@param speed?    number The amount the character's `x` and `y` should approach their new position by every frame, in pixels per frame at 30FPS. (Defaults to `4`)
---@return fun() : boolean finished A function that returns `true` once the movement has finished.
function BattleCutscene:slideToSpeed(obj, x, y, speed)
    if type(obj) == "string" then
        obj = self:getCharacter(obj)
    end
    local slided = false
    if obj:slideToSpeed(x, y, speed, function() slided = true end) then
        return function() return slided end
    else
        return _true
    end
end

--- Shakes a character by the specified `x`, `y`.
---@param chara     string|Battler  The character being shaken. Accepts either a Battler instance or an id to search for.
---@param x?        number          The amount of shake in the `x` direction. (Defaults to `4`)
---@param y?        number          The amount of shake in the `y` direction. (Defaults to `0`)
---@param friction? number          The amount that the shake should decrease by, per frame at 30FPS. (Defaults to `1`)
---@param delay?    number          The time it takes for the object to invert its shake direction, in seconds. (Defaults to `1/30`)
---@return fun() : boolean finished A function that returns `true` once the shake value has returned to 0.
function BattleCutscene:shakeCharacter(chara, x, y, friction, delay)
    if type(chara) == "string" then
        chara = self:getCharacter(chara)
    end
    chara.sprite:shake(x, y, friction, delay)
    chara.overlay_sprite:shake(x, y, friction, delay)
    return function() return chara.sprite.graphics.shake_x == 0 and chara.sprite.graphics.shake_y == 0 end
end

local function cameraShakeCheck() return Game.battle.camera.shake_x == 0 and Game.battle.camera.shake_y == 0 end
--- Shakes the camera by the specified `x`, `y`.
---@param x?        number      The amount of shake in the `x` direction. (Defaults to `4`)
---@param y?        number      The amount of shake in the `y` direction. (Defaults to `4`)
---@param friction? number      The amount that the shake should decrease by, per frame at 30FPS. (Defaults to `1`)
---@return fun() : boolean finished    A function that returns `true` once the shake value has returned to `0`.
function BattleCutscene:shakeCamera(x, y, friction)
    Game.battle:shakeCamera(x, y, friction)
    return cameraShakeCheck
end

--- Creates an alert bubble above a character.
---@param chara     string|Battler  The character being shaken. Accepts either a Battler instance or an id to search for.
---@param ...       unknown         Arguments to be passed to Battler:alert().
---@return Sprite   alert_icon      The result alert icon created above the character's head.
---@return fun() : boolean finished        A function that returns `true` once the alert icon has disappeared. \
---@see Battler.alert for details on the arguments to pass to this function.
function BattleCutscene:alert(chara, ...)
    if type(chara) == "string" then
        chara = self:getCharacter(chara)
    end
    local function waitForAlertRemoval() return chara.alert_icon == nil or chara.alert_timer == 0 end
    return chara:alert(...), waitForAlertRemoval
end

--- Fades the screen and music out.
---@param speed?    number       The speed to fade out at, in seconds. (Defaults to `0.25`)
---@param options?  table        A table defining additional properties to control the fade.
---| "color"    # The color that should be faded to (Defaults to `COLORS.black`)
---| "alpha"    # The alpha to start at (Defaults to `0`)
---| "blocky"   # Whether to do a rough, 'blocky' fade. (Defaults to `false`)
---| "music"    # The speed to fade the music at, or whether to fade it at all (Defaults to fade speed)
---@return fun() : boolean finished    A function that returns true once the fade has finished.
function BattleCutscene:fadeOut(speed, options)
    options = options or {}

    local fader = Game.fader

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
---| "color"    # The color that should be faded to (Defaults to last fadeOut's color)
---| "alpha"    # The alpha to start at (Defaults to `1`)
---| "blocky"   # Whether to do a rough, 'blocky' fade. (Defaults to `false`)
---| "music"    # The speed to fade the music at, or whether to fade it at all (Defaults to fade speed)
---@return fun() : boolean finished    A function that returns true once the fade has finished.
function BattleCutscene:fadeIn(speed, options)
    options = options or {}

    local fader = Game.fader

    if speed then
        options["speed"] = speed
    end

    local fade_done = false

    fader:fadeIn(function() fade_done = true end, options)

    return function() return fade_done end
end

--- Sets the active speaker for the encountertext box.
---@param actor? PartyBattler|EnemyBattler|Actor|nil The character or actor to set as the speaker. `nil` resets the speaker to nothing.
function BattleCutscene:setSpeaker(actor)
    if isClass(actor) and (actor:includes(PartyBattler) or actor:includes(EnemyBattler)) then
        actor = actor.actor
    end
    self.textbox_actor = actor
end

local function waitForEncounterText() return Game.battle.battle_ui.encounter_text.text.text == "" end
--- Types text on the encounter text box, and suspends the cutscene until the player progresses the dialogue. \
--- When passing arguments to this function, the options table can be passed as the second or third argument to forgo specifying `portrait` or `actor`.
---@overload fun(self: BattleCutscene, text: string, options?: table): finished: fun(): boolean
---@overload fun(self: BattleCutscene, text: string, portrait: string, options?: table): finished: fun(): boolean
---@param text      string  The text to be typed.
---@param portrait? string  The character portrait to be used.
---@param actor?    Actor   The actor to use for voice bytes and dialogue portraits, overriding the active cutscene speaker.
---@param options?  table   A table defining additional properties to control the text.
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
---@return fun() finished A function that returns `true` when the textbox has been advanced. (Only use if `options["wait"]` is set to `false`.)
function BattleCutscene:text(text, portrait, actor, options)
    if type(actor) == "table" then
        options = actor
        ---@diagnostic disable-next-line: cast-local-type
        actor = nil
    end
    if type(portrait) == "table" then
        options = portrait
        ---@diagnostic disable-next-line: cast-local-type
        portrait = nil
    end

    options = options or {}

    actor = actor or self.textbox_actor

    Game.battle.battle_ui.encounter_text:setActor(actor)
    Game.battle.battle_ui.encounter_text:setFace(portrait, options["x"], options["y"])

    Game.battle.battle_ui.encounter_text:resetReactions()
    if options["reactions"] then
        for id,react in pairs(options["reactions"]) do
            Game.battle.battle_ui.encounter_text:addReaction(id, react[1], react[2], react[3], react[4], react[5])
        end
    end

    Game.battle.battle_ui.encounter_text:resetFunctions()
    if options["functions"] then
        for id,func in pairs(options["functions"]) do
            Game.battle.battle_ui.encounter_text:addFunction(id, func)
        end
    end

    if options["font"] then
        if type(options["font"]) == "table" then
            -- {font, size}
            Game.battle.battle_ui.encounter_text:setFont(options["font"][1], options["font"][2])
        else
            Game.battle.battle_ui.encounter_text:setFont(options["font"])
        end
    else
        Game.battle.battle_ui.encounter_text:setFont()
    end

    Game.battle.battle_ui.encounter_text:setAlign(options["align"])

    Game.battle.battle_ui.encounter_text:setSkippable(options["skip"] or options["skip"] == nil)
    Game.battle.battle_ui.encounter_text:setAdvance(options["advance"] or options["advance"] == nil)
    Game.battle.battle_ui.encounter_text:setAuto(options["auto"])

    Game.battle.battle_ui.encounter_text:setText(text, function()
        Game.battle.battle_ui:clearEncounterText()
        self:tryResume()
    end)

    local wait = options["wait"] or options["wait"] == nil
    if not Game.battle.battle_ui.encounter_text.text.can_advance then
        wait = options["wait"] -- By default, don't wait if the textbox can't advance
    end

    if wait then
        return self:wait(waitForEncounterText)
    else
        return waitForEncounterText
    end
end

--- Creates a text bubble for one or more battlers.
---@param battlers  string|Battler  A battler id, or a Battler instance. If multiple battlers share the same id, specifying one will create a bubble for each of them.
---@param text      string          The text that will appear in the speech bubble.
---@param options?  table           A table defining additional properties to control the text.
---|"wait"          # Whether the cutscene should automatically suspend itself until the bubbles have finished. (Defaults to `true`)
---|"x"             # The x-offset of the speech bubble. (Defaults to `0`)
---|"y"             # The y-offset of the speech bubble. (Defaults to `0`)
---|"advance"       # Whether the bubble can be manually advanced by the player. (Defaults to `true`)
---|"auto"          # Whether the bubble will auto-advance after it has typed the last character. (Defaults to `false`)
---|"after"         # A callback to add to the bubble, that will be run when it finishes.
---|"line_callback" # Sets the line_callback of the text.
---@return any      finished        If the cutscene is not automatically waiting, a boolean that reflects whether all the dialogue bubbles have finished.
---@return table?   bubbles         A table of all bubbles created by this function call.
function BattleCutscene:battlerText(battlers, text, options)
    options = options or {}
    if type(battlers) == "string" then
        local id = battlers
        battlers = {}
        for _,battler in ipairs(Game.battle.enemies) do
            if battler.id == id then
                table.insert(battlers, battler)
            end
        end
        for _,battler in ipairs(Game.battle.party) do
            if battler.chara.id == id then
                table.insert(battlers, battler)
            end
        end
    elseif isClass(battlers) then
        battlers = {battlers}
    end
    local wait = options["wait"] or options["wait"] == nil
    local bubbles = {}
    for _,battler in ipairs(battlers) do
        local bubble
        if not options["x"] and not options["y"] then
            bubble = battler:spawnSpeechBubble(text, options)
        else
            bubble = SpeechBubble(text, options["x"] or 0, options["y"] or 0, options, battler)
            Game.battle:addChild(bubble)
        end
        bubble:setAdvance(options["advance"] or options["advance"] == nil)
        bubble:setAuto(options["auto"])
        if not bubble.text.can_advance then
            wait = options["wait"]
        end
        bubble:setCallback(function()
            bubble:remove()
            local after = options["after"]
            if after then after() end
        end)
        if options["line_callback"] then
            bubble:setLineCallback(options["line_callback"])
        end
        table.insert(bubbles, bubble)
    end
    local wait_func = function()
        for _,bubble in ipairs(bubbles) do
            if not bubble:isDone() then
                return false
            end
        end
        return true
    end
    if wait then
        return self:wait(wait_func)
    else
        return wait_func, bubbles
    end
end

local function waitForChoicer() return Game.battle.battle_ui.choice_box.done, Game.battle.battle_ui.choice_box.selected_choice end
--- Creates a choicer with the choices specified in `choices` for the player to select from.
---@param choices  table A table of strings specifying the choices the player can select. Maximum of four.
---@param options? table A table defining additional properties to control the choicer.
---|"color"     # The main color to set all the choices to, or a table of main colors to set for different choices. (Defaults to `COLORS.white`)
---|"highlight" # The color to highlight the selected choice in, or a table of colors to highlight different choices in when selected. (Defaults to `COLORS.yellow`)
---|"wait"      # Whether the cutscene should automatically suspend itself until the player makes their choice. (Defaults to `true`)
---@return number|function selected The index of the selected item if the cutscene has been set to wait for the choicer, otherwise a boolean that states whether the player has made their choice.
---@return Choicebox? choicer The choicebox object for this choicer. Only returned if wait is `false`. 
function BattleCutscene:choicer(choices, options)
    options = options or {}

    Game.battle.battle_ui.choice_box.active = true
    Game.battle.battle_ui.choice_box.visible = true
    Game.battle.battle_ui.encounter_text.active = false
    Game.battle.battle_ui.encounter_text.visible = false

    Game.battle.battle_ui.choice_box.done = false

    Game.battle.battle_ui.choice_box:clearChoices()
    for _,choice in ipairs(choices) do
        Game.battle.battle_ui.choice_box:addChoice(choice)
    end
    Game.battle.battle_ui.choice_box:setColors(options["color"], options["highlight"])

    if options["wait"] or options["wait"] == nil then
        return self:wait(waitForChoicer)
    else
        return waitForChoicer, Game.battle.battle_ui.choice_box
    end
end

--- Clears the active choicebox and current encounter text, and removes all battler bubbles.
function BattleCutscene:closeText()
    local choice_box = Game.battle.battle_ui.choice_box
    local text = Game.battle.battle_ui.encounter_text
    if choice_box.active then
        choice_box:clearChoices()
        choice_box.active = false
        choice_box.visible = false
        text.active = true
        text.visible = true
    end
    for _,battler in ipairs(Utils.mergeMultiple(Game.battle.party, Game.battle:getActiveEnemies())) do
        if battler.bubble then
            battler:onBubbleRemove(battler.bubble)
            battler.bubble:remove()
            battler.bubble = nil
        end
    end
    Game.battle.battle_ui:clearEncounterText()
end

return BattleCutscene