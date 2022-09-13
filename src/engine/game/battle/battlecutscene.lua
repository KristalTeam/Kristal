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

    super:init(self, scene, unpack(args))
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

    super:update(self)
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

function BattleCutscene:getEnemies(id)
    local result = {}
    for _,battler in ipairs(Game.battle.enemies) do
        if battler.id == id then
            table.insert(result, battler)
        end
    end
    return result
end

function BattleCutscene:getUser()
    return Game.battle.party[Game.battle:getCurrentAction().character_id]
end

function BattleCutscene:getTarget()
    return Game.battle:getCurrentAction().target
end

function BattleCutscene:resetSprites()
    for battler,_ in pairs(self.changed_sprite) do
        battler:toggleOverlay(false)
    end
    self.changed_sprite = {}
end

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

function BattleCutscene:shakeCharacter(chara, x, y)
    if type(chara) == "string" then
        chara = self:getCharacter(chara)
    end
    chara.sprite:shake(x, y)
    chara.overlay_sprite:shake(x, y)
    return function() return chara.sprite.shake_x == 0 and chara.sprite.shake_y == 0 end
end

local function cameraShakeCheck() return Game.battle.camera.shake_x == 0 and Game.battle.camera.shake_y == 0 end
function BattleCutscene:shakeCamera(x, y, friction)
    Game.battle:shakeCamera(x, y, friction)
    return cameraShakeCheck
end

function BattleCutscene:fadeOut(speed, options)
    options = options or {}

    local fader = Game.fader

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

function BattleCutscene:fadeIn(speed, options)
    options = options or {}

    local fader = Game.fader

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

function BattleCutscene:setSpeaker(actor)
    if isClass(actor) and (actor:includes(PartyBattler) or actor:includes(EnemyBattler)) then
        actor = actor.actor
    end
    self.textbox_actor = actor
end

local function waitForEncounterText() return Game.battle.battle_ui.encounter_text.text.text == "" end
function BattleCutscene:text(text, portrait, actor, options)
    if type(actor) == "table" then
        options = actor
        actor = nil
    end
    if type(portrait) == "table" then
        options = portrait
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

function BattleCutscene:battlerText(battlers, text, options)
    options = options or {}
    if type(battlers) == "string" then
        local enemy_id = battlers
        battlers = {}
        for _,battler in ipairs(Game.battle.enemies) do
            if battler.id == enemy_id then
                table.insert(battlers, battler)
            end
        end
    elseif isClass(battlers) then
        battlers = {battlers}
    end
    local wait = options["wait"] or options["wait"] == nil
    local bubbles = {}
    for _,enemy in ipairs(battlers) do
        local bubble
        if not options["x"] and not options["y"] then
            bubble = enemy:spawnSpeechBubble(text, options["right"], options["style"])
        else
            bubble = SpeechBubble(text, options["x"] or 0, options["y"] or 0, enemy, options["right"], options["style"])
            Game.battle:addChild(bubble)
        end
        bubble:setAdvance(options["advance"] or options["advance"] == nil)
        bubble:setAuto(options["auto"])
        if not bubble.text.can_advance then
            wait = options["wait"]
        end
        bubble:setCallback(function() bubble:remove() end)
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