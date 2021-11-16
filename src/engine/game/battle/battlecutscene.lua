local BattleCutscene, super = Class(Cutscene)

local function _true() return true end

function BattleCutscene:init(group, id, ...)
    local scene, args = self:parseFromGetter(Registry.getBattleCutscene, group, id, ...)

    self.move_targets = {}
    self.waiting_for_text = nil
    self.waiting_for_enemy_text = nil

    self.last_battle_state = Game.battle.state
    Game.battle:setState("CUTSCENE")

    super:init(self, scene, unpack(args))
end

function BattleCutscene:update(dt)
    if self.ended then return end

    local done_moving = {}
    for battler,target in pairs(self.move_targets) do
        if battler.x == target[1] and battler.y == target[2] then
            table.insert(done_moving, battler)
        end
        local tx = Utils.approach(battler.x, target[2], target[4] * DTMULT)
        local ty = Utils.approach(battler.y, target[3], target[4] * DTMULT)
        battler:setPosition(tx, ty)
    end
    for _,v in ipairs(done_moving) do
        self.move_targets[v] = nil
    end

    super:update(self, dt)
end

function BattleCutscene:onEnd()
    Game.battle.battle_ui.encounter_text:setActor(nil)
    Game.battle.battle_ui.encounter_text:setFace(nil)
    Game.battle.battle_ui.encounter_text.auto_advance = false

    for _,battler in ipairs(Game.battle.party) do
        battler:toggleOverlay(false)
    end
    for _,battler in ipairs(Game.battle.enemies) do
        battler:toggleOverlay(false)
    end

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
    for _,battler in ipairs(Game.battle.party) do
        battler:toggleOverlay(false)
    end
    for _,battler in ipairs(Game.battle.enemies) do
        battler:toggleOverlay(false)
    end
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
end

function BattleCutscene:setAnimation(chara, anim)
    if type(chara) == "string" then
        chara = self:getCharacter(chara)
    end
    local done = false
    chara:toggleOverlay(true)
    chara.overlay_sprite:setAnimation(anim, function() done = true end)
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

function BattleCutscene:shakeCharacter(chara, x, y)
    if type(chara) == "string" then
        chara = self:getCharacter(chara)
    end
    chara.sprite:shake(x, y)
    chara.overlay_sprite:shake(x, y)
    return function() return chara.sprite.shake_x == 0 and chara.sprite.shake_y == 0 end
end

local function cameraShakeCheck() return Game.battle.shake == 0 end
function BattleCutscene:shakeCamera(shake)
    Game.battle.shake = shake
    return cameraShakeCheck
end

function BattleCutscene:setSpeaker(actor)
    if isClass(actor) and (actor:includes(PartyBattler) or actor:includes(EnemyBattler)) then
        actor = actor.actor
    end
    self.textbox_actor = actor
end

local function waitForEncounterText() return Game.battle.battle_ui.encounter_text:getText() == "" end
function BattleCutscene:text(text, portrait, actor, options)
    if type(actor) == "table" then
        options = actor
        actor = nil
    end

    options = options or {}

    actor = actor or self.textbox_actor

    Game.battle.battle_ui.encounter_text:setActor(actor)
    Game.battle.battle_ui.encounter_text:setFace(portrait, options["x"], options["y"])
    Game.battle.battle_ui.encounter_text:setText(text)

    Game.battle.battle_ui.encounter_text.can_advance = options["advance"] or options["advance"] == nil
    Game.battle.battle_ui.encounter_text.auto_advance = options["auto"] or false

    local wait = options["wait"] or options["wait"] == nil
    if not Game.battle.battle_ui.encounter_text.can_advance then
        wait = options["wait"] -- By default, don't wait if the textbox can't advance
    end

    if wait then
        self.waiting_for_text = Game.battle.battle_ui.encounter_text
        return self:pause()
    else
        return waitForEncounterText
    end
end

function BattleCutscene:enemyText(enemies, text, options)
    options = options or {}
    if type(enemies) == "string" then
        enemies = {}
        for _,battler in ipairs(Game.party.enemies) do
            table.insert(enemies, battler)
        end
    elseif isClass(enemies) then
        enemies = {enemies}
    end
    local wait = options["wait"] or options["wait"] == nil
    local textboxes = {}
    for _,enemy in ipairs(enemies) do
        local textbox = Game.battle:spawnEnemyTextbox(enemy, text)
        textbox.can_advance = options["advance"] or options["advance"] == nil
        textbox.auto_advance = options["auto"] or false
        if not textbox.can_advance then
            wait = options["wait"]
        end
        table.insert(textboxes, textbox)
    end
    if wait then
        self.waiting_for_enemy_text = textboxes
        return self:pause()
    else
        return function()
            for _,textbox in ipairs(textboxes) do
                if not textbox.done then
                    return false
                end
            end
            return true
        end, textboxes
    end
end

return BattleCutscene