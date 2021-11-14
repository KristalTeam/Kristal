local Cutscene = {}
local self = Cutscene

function Cutscene.start(cutscene)
    if self.current_coroutine and coroutine.status(self.current_coroutine) ~= "dead" then
        error("Attempt to start a cutscene while already in a cutscene .   dumbass ,,")
        self.current_coroutine = nil
    end

    local func = nil

    if type(cutscene) == "string" then
        func = Mod.info.script_chunks["scripts/world/cutscenes/" .. cutscene]
        if not func then
            error("Attempt to load cutscene \"" .. cutscene .. "\", but it wasn't found. Dumbass")
        end
    elseif type(cutscene) == "function" then
        func = cutscene
    else
        error("Attempt to start cutscene with argument of type " .. type(cutscene))
    end

    self.delay_timer = 0

    if self.textbox then
        self.textbox:remove()
    end
    self.textbox = nil
    self.textbox_actor = nil

    if self.choicebox then
        self.choicebox:remove()
    end
    self.choicebox = nil

    self.move_targets = {}

    self.camera_target = nil
    self.camera_start = nil
    self.camera_move_time = 0
    self.camera_move_timer = 0
    self.camera_move_after = nil

    self.current_coroutine = coroutine.create(func)
    Game.lock_input = true
    Game.cutscene_active = true
    --[[Overworld.cutscene_active = true
    Overworld.lock_player_input = true
    Overworld.can_open_menu = false]]

    self.choice = 0

    self.resume()
end

function Cutscene.isActive()
    return self.current_coroutine ~= nil
end

function Cutscene.wait(seconds)
    if self.current_coroutine then
        self.delay_timer = seconds
        coroutine.yield()
    end
end

function Cutscene.pause()
    if self.current_coroutine then
        coroutine.yield()
    end
end

function Cutscene.resume()
    if self.current_coroutine then
        local ok, msg = coroutine.resume(self.current_coroutine)
        if not ok then
            error(msg)
        end
    end
end

-- Main update function of the module
function Cutscene.update(dt)
    if self.current_coroutine then
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
                chara:moveTo(tx, ty)
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

        if coroutine.status(self.current_coroutine) == "dead" and not self.camera_target then
            -- TODO: ALLOW THE PLAYER TO OPEN THE MENU  OR SOMETHING

            Game.lock_input = false
            Game.cutscene_active = false

            if self.textbox then
                self.textbox:remove()
                self.textbox = nil
            end

            if self.choicebox then
                self.choicebox:remove()
                self.choicebox = nil
            end

            self.current_coroutine = nil
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

function Cutscene.getCharacter(id, index)
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

function Cutscene.detachFollowers()
    for _,follower in ipairs(Game.followers) do
        follower.following = false
    end
end

function Cutscene.attachFollowers(return_speed, facing)
    for _,follower in ipairs(Game.followers) do
        follower.following = true

        return_speed = return_speed or 6
        if return_speed ~= true and return_speed > 0 then
            local tx, ty = follower:getTargetPosition()
            self.walkTo(follower, tx, ty, return_speed, facing)
        end
    end
end

function Cutscene.alignFollowers(facing, x, y)
    Game.world.player:alignFollowers(facing, x, y)
end

function Cutscene.keepFollowerPositions()
    Game.world.player:keepFollowerPositions()
end

function Cutscene.resetSprites()
    Game.world.player:resetSprite()
    for _,follower in ipairs(Game.world.followers) do
        follower:resetSprite()
    end
end

function Cutscene.look(chara, dir)
    if type(chara) == "string" then
        chara = self.getCharacter(chara)
    end
    chara:setFacing(dir)
end

function Cutscene.walkTo(chara, x, y, speed, facing)
    if type(chara) == "string" then
        chara = self.getCharacter(chara)
    end
    local ex, ey = chara:getExactPosition()
    if ex ~= x or ey ~= y then
        self.move_targets[chara] = {true, x, y, speed or 4, facing}
    end
end

function Cutscene.setSprite(chara, sprite, speed)
    if type(chara) == "string" then
        chara = self.getCharacter(chara)
    end
    chara:setSprite(sprite)
    if speed then
        chara:play(speed, true)
    end
end

function Cutscene.setAnimation(chara, anim)
    if type(chara) == "string" then
        chara = self.getCharacter(chara)
    end
    chara:setAnimation(anim)
end

function Cutscene.spin(chara, speed)
    if type(chara) == "string" then
        chara = self.getCharacter(chara)
    end
    chara:spin(speed)
end

function Cutscene.slideTo(chara, x, y, speed)
    if type(chara) == "string" then
        chara = self.getCharacter(chara)
    end
    local ex, ey = chara:getExactPosition()
    if ex ~= x or ey ~= y then
        self.move_targets[chara] = {false, x, y, speed or 4}
    end
end

function Cutscene.shakeCharacter(chara, x, y)
    if type(chara) == "string" then
        chara = self.getCharacter(chara)
    end
    chara:shake(x, y)
end

function Cutscene.shakeCamera(x, y)
    Game.world.shake_x = x or 0
    Game.world.shake_y = y or x or 0
end

function Cutscene.detachCamera()
    Game.world.camera_attached = false
end

function Cutscene.attachCamera(time)
    local tx, ty = Game.world:getCameraTarget()
    self.panTo(tx, ty, time or 0.8, function() Game.world.camera_attached = true end)
end

function Cutscene.setSpeaker(actor)
    if isClass(actor) and actor:includes(Character) then
        actor = actor.actor
    end
    self.textbox_actor = actor
end

function Cutscene.panTo(...)
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
end

function Cutscene.text(text, portrait, actor, options)
    if type(actor) == "table" then
        options = actor
        actor = nil
    end

    if self.textbox then
        self.textbox:remove()
    end

    if self.choicebox then
        self.choicebox:remove()
        self.choicebox = nil
    end


    self.textbox = Textbox(56, 344, 529, 103)
    self.textbox.layer = 1
    Game.stage:addChild(self.textbox)

    actor = actor or self.textbox_actor
    if actor then
        self.textbox:setActor(actor)
    end

    options = options or {}
    if options["top"] then
       local bx, by = self.textbox:getBorder()
       self.textbox.y = by
    end

    self.textbox.active = true
    self.textbox.visible = true
    self.textbox:setFace(portrait, options["x"], options["y"])
    self.textbox:setText(text)

    self.auto_advance = options["auto"]

    if self.current_coroutine then
        coroutine.yield()
    end
end

function Cutscene.choicer(choices, options)
    if self.textbox then
        self.textbox:remove()
        self.textbox = nil
    end

    if self.choicebox then self.choicebox:remove() end

    self.choicebox = Choicebox(56, 344, 529, 103)
    self.choicebox.layer = 1
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

    if self.current_coroutine then
        coroutine.yield()
    end
end

--[[

function Cutscenes:SpawnTextbox(text,portrait,options)
    self.delay_from_textbox = true
    local top = true
    if options and options["top"] ~= nil then
        top = options["top"]
    else
        top = Overworld.player.y - Misc.cameraY < 230
    end
    OverworldTextbox.SetText(text,top,portrait,options)
    coroutine.yield()
end]]


return Cutscene