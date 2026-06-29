---@class Choicebox : Object
---@overload fun(...) : Choicebox
local Choicebox, super = Class(Object)

function Choicebox:init(x, y, width, height, battle_box, options)
    super.init(self, x, y, width, height)

    self.box = UIBox(0, 0, width, height)
    self.box.layer = -1
    self:addChild(self.box)

    self.battle_box = battle_box
    if battle_box then
        self.box.visible = false
    end

    self.choices = {}

    self.current_choice = 0
    self.selected_choice = nil

    options = options or {}
    self:setColors(options["color"], options["highlight"])

    self.done = false

    self.font = Assets.getFont("main")

    self.heart = Assets.getTexture("player/heart_menu")

    Input.clear("confirm")
end

function Choicebox:update()
    local old_choice = self.current_choice
    if Input.down("left") then self.current_choice = 1 end
    if Input.down("right") then self.current_choice = 2 end
    if Input.down("up") then self.current_choice = 3 end
    if Input.down("down") then self.current_choice = 4 end

    if self.current_choice > #self.choices then
        self.current_choice = old_choice
    end

    if Input.pressed("confirm") then
        if self.current_choice ~= 0 then
            self.selected_choice = self.current_choice

            self.done = true

            if not self.battle_box then
                self:remove()
                if Game.world:hasCutscene() then
                    Game.world.cutscene.choice = self.selected_choice
                    Game.world.cutscene:tryResume()
                end
            else
                self:clearChoices()
                self.active = false
                self.visible = false
                Game.battle.battle_ui.encounter_text.active = true
                Game.battle.battle_ui.encounter_text.visible = true
                if Game.battle:hasCutscene() then
                    Game.battle.cutscene.choice = self.selected_choice
                    Game.battle.cutscene:tryResume()
                end
            end
        end
    end
    super.update(self)
end

function Choicebox:draw()
    super.draw(self)
    love.graphics.setFont(self.font)

    if self.choices[1] ~= nil then
        Draw.setColor(self.current_choice == 1 and self.hover_colors[1] or self.main_colors[1])
        love.graphics.print(self.choices[1], 36, 24)
    end

    if self.choices[2] ~= nil then
        Draw.setColor(self.current_choice == 2 and self.hover_colors[2] or self.main_colors[2])
        love.graphics.print(self.choices[2], 528 - self.font:getWidth(self.choices[2]), 24)
    end

    local top_width = 0
    local bottom_width = 0

    if self.choices[3] ~= nil then
        top_width = self.font:getWidth(self.choices[3])
    end

    if self.choices[4] ~= nil then
        bottom_width = self.font:getWidth(self.choices[4])
    end

    local vertical_width = math.max(top_width, bottom_width)

    if self.choices[3] ~= nil then
        Draw.setColor(self.current_choice == 3 and self.hover_colors[3] or self.main_colors[3])
        love.graphics.print(self.choices[3], 17 + MathUtils.round(self.width / 2) - MathUtils.round(vertical_width / 2), -8)
    end

    if self.choices[4] ~= nil then
        Draw.setColor(self.current_choice == 4 and self.hover_colors[4] or self.main_colors[4])
        love.graphics.print(self.choices[4], 17 + MathUtils.round(self.width / 2) - MathUtils.round(vertical_width / 2), 78)
    end

    local soul_positions = {
        --[[ Left:   ]] { 4,   34 },
        --[[ Right:  ]] { 528 - self.font:getWidth(self.choices[2] or "") - 32, 34 },
        --[[ Top:    ]] { 17 + MathUtils.round(self.width / 2) - MathUtils.round(vertical_width / 2) - 32, -8 + 6 },
        --[[ Bottom: ]] { 17 + MathUtils.round(self.width / 2) - MathUtils.round(vertical_width / 2) - 32, 78 + 6 }
    }

    -- Default to center
    local heart_x = 224
    local heart_y = 38

    local position = soul_positions[self.current_choice]
    if position ~= nil then
        heart_x = position[1]
        heart_y = position[2]
    end

    Draw.setColor(Game:getSoulColor())
    Draw.draw(self.heart, heart_x, heart_y, 0, 2, 2)
end

function Choicebox:setSize(w, h)
    self.width, self.height = w or 0, h or 0

    self.box:setSize(self.width, self.height)
end

function Choicebox:clearChoices()
    self.choices = {}
    self.current_choice = 0
end

--- Adds a new choice to the choicebox.
---@param name string The name of the new choice that will be shown for the selection.
function Choicebox:addChoice(name)
    table.insert(self.choices, name)
end

--- Sets the main and hover colors for every choice in the choicebox.
---@param main? table   The main color to set for all choices, or a table of main colors for each individual choice. (Defaults to `COLORS.white`)
---@param hover? table  The hover color to set for all choices, or a table of hover colors for each individual choice. (Defaults to `COLORS.yellow`)
function Choicebox:setColors(main, hover)
    main = main or { 1, 1, 1 }
    if type(main[1]) == "number" then
        self.main_colors = {
            { main[1], main[2], main[3], main[4] or 1 },
            { main[1], main[2], main[3], main[4] or 1 },
            { main[1], main[2], main[3], main[4] or 1 },
            { main[1], main[2], main[3], main[4] or 1 },
        }
    else
        self.main_colors = TableUtils.copy(main)
    end

    hover = hover or { 1, 1, 0 }
    if type(hover[1]) == "number" then
        self.hover_colors = {
            { hover[1], hover[2], hover[3], hover[4] or 1 },
            { hover[1], hover[2], hover[3], hover[4] or 1 },
            { hover[1], hover[2], hover[3], hover[4] or 1 },
            { hover[1], hover[2], hover[3], hover[4] or 1 },
        }
    else
        self.hover_colors = TableUtils.copy(hover)
    end
end

function Choicebox:getBorder()
    if self.box.visible then
        return self.box:getBorder()
    else
        return 0, 0
    end
end

return Choicebox
