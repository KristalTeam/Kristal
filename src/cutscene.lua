local Cutscene = {}
local self = Cutscene


self.current_coroutine = nil
self.delay_timer = 0
self.delay_from_textbox = false

function Cutscene:start(cutscene)
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

    self.current_coroutine = coroutine.create(func)
    --[[Overworld.cutscene_active = true
    Overworld.lock_player_input = true
    Overworld.can_open_menu = false]]
    coroutine.resume(self.current_coroutine)
end

function Cutscene:wait(seconds)
    if self.current_coroutine then
        self.delay_timer = seconds
        coroutine.yield()
    end
end

function Cutscene:pause()
    if self.current_coroutine then
        coroutine.yield()
    end
end

function Cutscene:resume()
    if self.current_coroutine then
        coroutine.resume(self.current_coroutine)
    end
end

-- Main update function of the module
function Cutscene:update(dt)
    if self.current_coroutine then
        if coroutine.status(self.current_coroutine) == "dead" then

            -- TODO: UNSET CUTSCENE VARIABLE
            -- TODO: UNLOCK PLAYER INPUT
            -- TODO: ALLOW THE PLAYER TO OPEN THE MENU  OR SOMETHING

            self.current_coroutine = nil
            return
        end

        if coroutine.status(self.current_coroutine) == "suspended" then
            if self.delay_timer > 0 then
                self.delay_timer = self.delay_timer - dt
                if self.delay_timer <= 0 then
                    coroutine.resume(self.current_coroutine)
                end
            end
        end
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