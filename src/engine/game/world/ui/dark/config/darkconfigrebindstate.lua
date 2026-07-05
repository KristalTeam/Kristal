---@class DarkConfigRebindState : StateClass
---
---@field menu DarkConfigMenu
---
---@overload fun(menu: DarkConfigMenu) : DarkConfigRebindState
local DarkConfigRebindState, super = Class(StateClass)

function DarkConfigRebindState:init(menu)
    self.menu = menu
end

function DarkConfigRebindState:registerEvents()
    self:registerEvent("enter", self.onEnter)
    self:registerEvent("leave", self.onLeave)
    self:registerEvent("update", self.onUpdate)
    self:registerEvent("draw", self.onDraw)
    self:registerEvent("keyPressed", self.onKeyPressed)
end

-------------------------------------------------------------------------------
-- Callbacks
-------------------------------------------------------------------------------

function DarkConfigRebindState:onEnter(old_state)
    self.currently_selected = 1
    self.rebinding = false
    self.reset_flash_timer = 0

    self.menu:hideOptions()
end

function DarkConfigRebindState:onLeave(new_state)
    self.menu:showOptions()
end

function DarkConfigRebindState:onKeyPressed(key)
    if self.rebinding then
        local gamepad = StringUtils.startsWith(key, "gamepad:")

        local worked = key ~= "escape" and Input.setBind(Input.orderedNumberToKey(self.currently_selected), 1, key, gamepad)

        self.rebinding = false

        if worked then
            Assets.stopAndPlaySound("ui_select")
        else
            Assets.stopAndPlaySound("ui_cant_select")
        end

        return
    end
    if Input.pressed("confirm") then
        if self.currently_selected < 8 then
            Assets.stopAndPlaySound("ui_select")
            self.rebinding = true
            return
        end

        if self.currently_selected == 8 then
            Assets.playSound("levelup")

            if Kristal.isConsole() then
                Input.resetBinds(true)  -- Console, no keyboard, only reset gamepad binds
            elseif Input.hasGamepad() then
                Input.resetBinds()      -- PC, keyboard and gamepad, reset all binds
            else
                Input.resetBinds(false) -- PC, no gamepad, only reset keyboard binds
            end
            Input.saveBinds()
            self.reset_flash_timer = 10
        end

        if self.currently_selected == 9 then
            self.reset_flash_timer = 0
            self.menu:setState("MAIN")
            self.currently_selected = 2

            Assets.stopAndPlaySound("ui_select")

            Input.clear("confirm", true)
        end
        return
    end

    local old_selected = self.currently_selected
    if Input.pressed("up") then
        self.currently_selected = self.currently_selected - 1
    end
    if Input.pressed("down") then
        self.currently_selected = self.currently_selected + 1
    end

    self.currently_selected = MathUtils.clamp(self.currently_selected, 1, 9)

    if old_selected ~= self.currently_selected then
        Assets.stopAndPlaySound("ui_move")
    end
end

function DarkConfigRebindState:getBindNumberFromIndex(current_index)
    local shown_bind = 1
    local alias = Input.orderedNumberToKey(current_index)
    local keys = Input.getBoundKeys(alias, Input.usingGamepad())
    for index, current_key in ipairs(keys) do
        if Input.usingGamepad() then
            if StringUtils.startsWith(current_key, "gamepad:") then
                shown_bind = index
                break
            end
        else
            if not StringUtils.startsWith(current_key, "gamepad:") then
                shown_bind = index
                break
            end
        end
    end
    return shown_bind
end

function DarkConfigRebindState:onUpdate()
    self.reset_flash_timer = math.max(self.reset_flash_timer - DTMULT, 0)
end

function DarkConfigRebindState:onDraw()
    love.graphics.setFont(Assets.getFont("main"))
    Draw.setColor(PALETTE["world_text"])

    -- NOTE: This is forced to true if using a PlayStation in DELTARUNE... Kristal doesn't have a PlayStation port though.
    local dualshock = Input.getControllerType() == "ps4"

    love.graphics.print("Function", 23, -12)
    -- Console accuracy for the Heck of it
    if not Kristal.isConsole() then
        love.graphics.print("Key", 243, -12)
    end
    if Input.hasGamepad() then
        love.graphics.print(Kristal.isConsole() and "Button" or "Gamepad", 353, -12)
    end

    for index, name in ipairs(Input.order) do
        if index > 7 then
            break
        end
        Draw.setColor(PALETTE["world_text"])
        if self.currently_selected == index then
            if self.rebinding then
                Draw.setColor(PALETTE["world_text_rebind"])
            else
                Draw.setColor(PALETTE["world_text_hover"])
            end
        end

        if dualshock then
            love.graphics.print(name:gsub("_", " "):upper(), 23, -4 + (29 * index))
        else
            love.graphics.print(name:gsub("_", " "):upper(), 23, -4 + (28 * index) + 4)
        end

        local shown_bind = self:getBindNumberFromIndex(index)

        if not Kristal.isConsole() then
            local alias = Input.getBoundKeys(name, false)[1]
            if type(alias) == "table" then
                local title_cased = {}
                for _, word in ipairs(alias) do
                    table.insert(title_cased, StringUtils.titleCase(word))
                end
                love.graphics.print(table.concat(title_cased, "+"), 243, 0 + (28 * index))
            elseif alias ~= nil then
                love.graphics.print(StringUtils.titleCase(alias), 243, 0 + (28 * index))
            end
        end

        Draw.setColor(1, 1, 1)

        if Input.hasGamepad() then
            local alias = Input.getBoundKeys(name, true)[1]
            if alias then
                local btn_tex = Input.getButtonTexture(alias)
                if dualshock then
                    Draw.draw(btn_tex, 353 + 42, -2 + (29 * index), 0, 2, 2, btn_tex:getWidth() / 2, 0)
                else
                    Draw.draw(btn_tex, 353 + 42 + 16 - 6, -2 + (28 * index) + 11 - 6 + 1, 0, 2, 2, btn_tex:getWidth() / 2, 0)
                end
            end
        end
    end

    Draw.setColor(PALETTE["world_text"])
    if self.currently_selected == 8 then
        Draw.setColor(PALETTE["world_text_hover"])
    end

    if (self.reset_flash_timer > 0) then
        Draw.setColor(ColorUtils.mergeColor(PALETTE["world_text_hover"], PALETTE["world_text_selected"],
                                        ((self.reset_flash_timer / 10) - 0.1)))
    end

    if dualshock then
        love.graphics.print("Reset to default", 23, -4 + (29 * 8))
    else
        love.graphics.print("Reset to default", 23, -4 + (28 * 8) + 4)
    end

    Draw.setColor(PALETTE["world_text"])
    if self.currently_selected == 9 then
        Draw.setColor(PALETTE["world_text_hover"])
    end

    if dualshock then
        love.graphics.print("Finish", 23, -4 + (29 * 9))
    else
        love.graphics.print("Finish", 23, -4 + (28 * 9) + 4)
    end

    Draw.setColor(Game:getSoulColor())

    local heart = Assets.getTexture("player/heart")

    if dualshock then
        Draw.draw(heart, -2, 34 + ((self.currently_selected - 1) * 29))
    else
        Draw.draw(heart, -2, 34 + ((self.currently_selected - 1) * 28) + 2)
    end
end

return DarkConfigRebindState
