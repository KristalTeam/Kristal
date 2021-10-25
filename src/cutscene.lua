local Cutscene = {}
local self = Cutscene

function Cutscene.start(cutscene)
    if self.current_coroutine and coroutine.status(self.current_coroutine) ~= "dead" then
        error("Attempt to start a cutscene while already in a cutscene .   dumbass ,,")
        self.current_coroutine = nil
    end

    local func = nil

    if type(cutscene) == "string" then
        func = MOD.script_chunks["cutscenes/" .. cutscene]
        if not func then
            error("Attempt to load cutscene \"" .. cutscene .. "\", but it wasn't found. Dumbass")
        end
    elseif type(cutscene) == "function" then
        func = cutscene
    end

    self.delay_timer = 0
    self.delay_from_textbox = false

    if self.textbox then
        self.textbox:remove()
    end
    self.textbox = nil
    self.textbox_immediate = false

    self.current_coroutine = coroutine.create(func)
    Game.lock_input = true
    Game.cutscene_active = true
    --[[Overworld.cutscene_active = true
    Overworld.lock_player_input = true
    Overworld.can_open_menu = false]]
    coroutine.resume(self.current_coroutine)
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
        coroutine.resume(self.current_coroutine)
    end
end

function Cutscene.keypressed(key)
    if key == "z" then
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
        if coroutine.status(self.current_coroutine) == "dead" then

            -- TODO: UNSET CUTSCENE VARIABLE
            -- TODO: UNLOCK PLAYER INPUT
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
                coroutine.resume(self.current_coroutine)
            end
            if self.textbox_immediate and not self.textbox:isTyping() then
                self.textbox.active = false
                self.textbox.visible = false
                self.delay_from_textbox = false
            end
        end
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
    self.textbox:setFace(portrait)
    self.textbox:setText(text)

    self.textbox_immediate = options["auto"]
    self.delay_from_textbox = true
    coroutine.yield()
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