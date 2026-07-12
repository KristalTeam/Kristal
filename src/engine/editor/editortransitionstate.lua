local EditorTransitionState = {
    owns_window_input = true
}

function EditorTransitionState:init() end

function EditorTransitionState:enter(previous, mode, options)
    self.source_state = previous
    self.mode = mode
    self.options = options or {}
    self.previous_lock_movement = Game.lock_movement
    Game.lock_movement = true

    if mode == "enter" then
        self.transition = EditorModeTransition("enter", function(transition)
            local editor_options = TableUtils.copy(self.options, true)
            editor_options.source_state = self.source_state
            editor_options.entry_transition = transition
            self.transition = nil
            Kristal.setState("Editor", editor_options)
        end)
    elseif mode == "exit_tail" then
        self.transition = assert(self.options.transition, "Exit transition tail requires a transition")
        self.transition.on_complete = function()
            if self.options.return_to_menu then
                Kristal.returnToMenu()
                return
            end
            if self.options.game_snapshot then
                Game:load(TableUtils.copy(self.options.game_snapshot, true),
                    self.options.game_snapshot_save_id, false)
            elseif self.options.resume_game_music then
                local music = Game:getActiveMusic()
                if music and music:canResume() then music:resume() end
            end
            Kristal.popState()
        end
    else
        error("Unknown editor transition state mode: " .. tostring(mode))
    end
end

function EditorTransitionState:leave()
    if self.mode == "exit_tail" and type(self.options.game_lock_movement) == "boolean" then
        Game.lock_movement = self.options.game_lock_movement
    else
        Game.lock_movement = self.previous_lock_movement
    end
    self.source_state = nil
    self.transition = nil
end

function EditorTransitionState:update()
    if self.mode == "enter" and self.source_state and self.source_state.update then
        self.source_state:update()
    end
    if self.transition then self.transition:update(DT) end
end

function EditorTransitionState:draw()
    if self.mode == "exit_tail" and self.options.return_to_menu then
        Draw.setColor(0.03, 0.03, 0.035, 1)
        love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
        Draw.setColor(0.82, 0.82, 0.86, 1)
        love.graphics.setFont(Assets.getFont("main"))
        love.graphics.printf("Returning to Main Menu...", 0,
            math.floor((SCREEN_HEIGHT - love.graphics.getFont():getHeight()) / 2),
            SCREEN_WIDTH, "center")
    elseif self.source_state and self.source_state.draw then
        self.source_state:draw()
    end
    if self.transition then self.transition:draw() end
end

function EditorTransitionState:onKeyPressed() return true end
function EditorTransitionState:onKeyReleased() return true end
function EditorTransitionState:onTextInput() return true end
function EditorTransitionState:onMousePressed() return true end
function EditorTransitionState:onMouseMoved() return true end
function EditorTransitionState:onMouseReleased() return true end
function EditorTransitionState:onWheelMoved() return true end

return EditorTransitionState
