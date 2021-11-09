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
    self.delay_from_textbox = false

    if self.textbox then
        self.textbox:remove()
    end
    self.textbox = nil
    self.textbox_immediate = false
    self.move_targets = {}

    self.current_coroutine = coroutine.create(func)
    Game.lock_input = true
    Game.cutscene_active = true
    --[[Overworld.cutscene_active = true
    Overworld.lock_player_input = true
    Overworld.can_open_menu = false]]
    self.resume()
end

function Cutscene.wait(seconds)
    print("waiting "..seconds)
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

function Cutscene.keypressed(key)
    if Input.isConfirm(key) then
        if self.delay_from_textbox and not self.textbox:isTyping() then
            self.textbox.active = false
            self.textbox.visible = false
            self.delay_from_textbox = false
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

        if coroutine.status(self.current_coroutine) == "dead" then
            -- TODO: ALLOW THE PLAYER TO OPEN THE MENU  OR SOMETHING

            Game.lock_input = false
            Game.cutscene_active = false

            if self.textbox then
                self.textbox:remove()
            end

            self.current_coroutine = nil
            return
        end

        if coroutine.status(self.current_coroutine) == "suspended" then
            if self.delay_timer > 0 then
                self.delay_timer = self.delay_timer - dt
            end
            if self.delay_timer <= 0 and not self.delay_from_textbox then
                self.resume()
            end
            if self.textbox_immediate and not self.textbox:isTyping() then
                self.textbox.active = false
                self.textbox.visible = false
                self.delay_from_textbox = false
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

function Cutscene.attachFollowers(dont_return)
    for _,follower in ipairs(Game.followers) do
        follower.following = true
        follower.returning = not dont_return
    end
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

function Cutscene.walkTo(chara, x, y, speed)
    if type(chara) == "string" then
        chara = self.getCharacter(chara)
    end
    local ex, ey = chara:getExactPosition()
    if ex ~= x or ey ~= y then
        self.move_targets[chara] = {true, x, y, speed or 4}
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

function Cutscene.slideTo(chara, x, y, speed)
    if type(chara) == "string" then
        chara = self.getCharacter(chara)
    end
    local ex, ey = chara:getExactPosition()
    if ex ~= x or ey ~= y then
        self.move_targets[chara] = {false, x, y, speed or 4}
    end
end

function Cutscene.text(text, portrait, options)
    if not self.textbox then
        self.textbox = Textbox(56, 344, 529, 103)
        self.textbox.layer = 1
        Game.stage:addChild(self.textbox)
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

    self.textbox_immediate = options["auto"]
    self.delay_from_textbox = true

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