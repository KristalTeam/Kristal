local BattleScene = {}
local self = BattleScene

function BattleScene.start(cutscene, post_func)
    if self.current_coroutine and coroutine.status(self.current_coroutine) ~= "dead" then
        error("Attempt to start a cutscene while already in a cutscene .   dumbass ,,")
        self.current_coroutine = nil
    end

    local func = nil

    if type(cutscene) == "string" then
        func = Mod.info.script_chunks["scripts/battle/cutscenes/" .. cutscene]
        if not func then
            error("Attempt to load cutscene \"" .. cutscene .. "\", but it wasn't found. Dumbass")
        end
    elseif type(cutscene) == "function" then
        func = cutscene
    else
        error("Attempt to start cutscene with argument of type " .. type(cutscene))
    end

    self.delay_timer = 0

    --[[if self.choicebox then
        self.choicebox:remove()
    end
    self.choicebox = nil
    self.choice = 0]]

    self.move_targets = {}

    self.last_battle_state = Game.battle.state
    self.post_func = post_func

    self.current_coroutine = coroutine.create(func)

    Game.battle:setState("BATTLESCENE")
    self.resume()
end

function BattleScene.isActive()
    return self.current_coroutine ~= nil
end

function BattleScene.wait(seconds)
    print("waiting "..seconds)
    if self.current_coroutine then
        self.delay_timer = seconds
        coroutine.yield()
    end
end

function BattleScene.pause()
    if self.current_coroutine then
        coroutine.yield()
    end
end

function BattleScene.resume()
    if self.current_coroutine then
        local ok, msg = coroutine.resume(self.current_coroutine)
        if not ok then
            error(msg)
        end
    end
end

-- Main update function of the module
function BattleScene.update(dt)
    if self.current_coroutine then
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

        if coroutine.status(self.current_coroutine) == "dead" then
            Game.battle.battle_ui.encounter_text:setActor(nil)
            Game.battle.battle_ui.encounter_text:setFace(nil)
            Game.battle.battle_ui.encounter_text.auto_advance = false

            for _,battler in ipairs(Game.battle.party) do
                battler:toggleOverlay(false)
            end
            for _,battler in ipairs(Game.battle.enemies) do
                battler:toggleOverlay(false)
            end

            self.current_coroutine = nil

            if self.post_func then
                self.post_func(Game.battle)
            else
                Game.battle:setState(self.last_battle_state, "BATTLESCENE")
            end
            return
        end

        if coroutine.status(self.current_coroutine) == "suspended" then
            if self.delay_timer > 0 then
                self.delay_timer = self.delay_timer - dt
                if self.delay_timer <= 0 then
                    self.resume()
                end
            end
        end
    end
end

function BattleScene.getCharacter(id)
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

function BattleScene.getEnemies(id)
    local result = {}
    for _,battler in ipairs(Game.battle.enemies) do
        if battler.id == id then
            table.insert(result, battler)
        end
    end
    return result
end

function BattleScene.getUser()
    return Game.battle.party[Game.battle:getCurrentAction().character_id]
end

function BattleScene.getTarget()
    return Game.battle:getCurrentAction().target
end

function BattleScene.resetSprites()
    for _,battler in ipairs(Game.battle.party) do
        battler:toggleOverlay(false)
    end
    for _,battler in ipairs(Game.battle.enemies) do
        battler:toggleOverlay(false)
    end
end

function BattleScene.setSprite(chara, sprite, speed)
    if type(chara) == "string" then
        chara = self.getCharacter(chara)
    end
    chara:toggleOverlay(true)
    chara.overlay_sprite:setSprite(sprite)
    if speed then
        chara.overlay_sprite:play(speed, true)
    end
end

function BattleScene.setAnimation(chara, anim)
    if type(chara) == "string" then
        chara = self.getCharacter(chara)
    end
    chara:toggleOverlay(true)
    chara.overlay_sprite:setAnimation(anim)
end

function BattleScene.moveTo(chara, x, y, speed)
    if type(chara) == "string" then
        chara = self.getCharacter(chara)
    end
    if chara.x ~= x or chara.y ~= y then
        self.move_targets[chara] = {x, y, speed or 4}
    end
end

function BattleScene.shakeCharacter(chara, x, y)
    if type(chara) == "string" then
        chara = self.getCharacter(chara)
    end
    chara.sprite:shake(x, y)
    chara.overlay_sprite:shake(x, y)
end

function BattleScene.shakeCamera(shake)
    Game.battle.shake = shake
end

function BattleScene.setSpeaker(actor)
    if isClass(actor) and (actor:includes(PartyBattler) or actor:includes(EnemyBattler)) then
        actor = actor.actor
    end
    self.textbox_actor = actor
end

function BattleScene.text(text, portrait, actor, options)
    if type(actor) == "table" then
        options = actor
        actor = nil
    end

    options = options or {}

    actor = actor or self.textbox_actor

    Game.battle.battle_ui.encounter_text:setActor(actor)
    Game.battle.battle_ui.encounter_text:setFace(portrait, options["x"], options["y"])
    Game.battle.battle_ui.encounter_text:setText(text)
    Game.battle.battle_ui.encounter_text.auto_advance = options["auto"] or false

    if self.current_coroutine then
        coroutine.yield()
    end
end

function BattleScene.enemyText(enemies, text)
    if type(enemies) == "string" then
        enemies = {}
        for _,battler in ipairs(Game.party.enemies) do
            table.insert(enemies, battler)
        end
    elseif isClass(enemies) then
        enemies = {enemies}
    end
    for _,enemy in ipairs(enemies) do
        Game.battle:spawnEnemyTextbox(enemy, text)
    end
    if self.current_coroutine then
        coroutine.yield()
    end
end

return BattleScene