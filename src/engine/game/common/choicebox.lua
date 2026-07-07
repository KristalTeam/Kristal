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

    self.text_positions = {}
    self.heart_positions = {}

    self.heart_offset_x = options["heart_offset_x"] or 0
    self.heart_offset_y = options["heart_offset_y"] or 0

    self.choice_offsets = options["choice_offsets"] or { { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 } }

    if self:shouldUseNewStyle() then
        self.heart_x = 254 + self.heart_offset_x
        self.heart_y = 4 + self.heart_offset_y
    else
        self.heart_x = 224
        self.heart_y = 38
    end
end

function Choicebox:handleConfirmInput()
    if Input.pressed("confirm") and self.current_choice ~= 0 then
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

function Choicebox:handleDirectionalInput()
    local old_choice = self.current_choice
    if Input.down("left") then self.current_choice = 1 end
    if Input.down("right") then self.current_choice = 2 end
    if Input.down("up") then self.current_choice = 3 end
    if Input.down("down") then self.current_choice = 4 end

    if self.current_choice > #self.choices then
        self.current_choice = old_choice
    end
end

function Choicebox:shouldUseNewStyle()
    if self.battle_box then
        return false
    end

    return Game:getConfig("newChoicers")
end

function Choicebox:initNewChoices()
    self.heart_x = 254 + self.heart_offset_x
    self.heart_y = 42 + self.heart_offset_y

    self.text_positions = {
        { 97 + self.choice_offsets[1][1], 52 + self.choice_offsets[1][2] },
        { 429 + self.choice_offsets[2][1], 52 + self.choice_offsets[2][2] },
        { 263 + self.choice_offsets[3][1], 12 + self.choice_offsets[3][2] },
        { 269 + self.choice_offsets[4][1], 91 + self.choice_offsets[4][2] }
    }

    local line_counts = {}

    for i = 1, #self.choices do

        self.text_positions[i][1] = self.text_positions[i][1] + 2 -- Unsure why this is needed
        self.text_positions[i][2] = self.text_positions[i][2] - 3

        local width = self.font:getWidth(self.choices[i])
        local split = StringUtils.split(self.choices[i], "\n", false)
        line_counts[i] = #split

        if i == 3 and line_counts[i] > 1 then
            self.text_positions[3][2] = self.text_positions[3][2] + 4
            self.heart_y = self.heart_y + 5
        end

        self.heart_positions[i] = {
            self.text_positions[i][1] - ((width / 2) + 22),
            self.text_positions[i][2]
        }
    end

    if #self.choices == 3 then
        if line_counts[3] == 1 and line_counts[4] == 2 then
            self.heart_y = self.heart_y - 11
        end

        if line_counts[3] == 2 and line_counts[4] == 1 then
            self.heart_y = self.heart_y + 3
        end

        if line_counts[3] == 2 and line_counts[4] == 2 then
            self.heart_y = self.heart_y - 4
        end
    end

    -- Take input early
    self:handleDirectionalInput()

    if self.current_choice ~= 0 then
        self.heart_x = self.heart_positions[self.current_choice][1]
        self.heart_y = self.heart_positions[self.current_choice][2]
    end
end

function Choicebox:initOldChoices()
    self.heart_x = 224
    self.heart_y = 38

    self.heart_positions[1] = { 4, 34 }
    self.text_positions[1] = { 4 + 32, -8 }

    if #StringUtils.split(self.choices[1], "\n", false) < 3 then
        self.text_positions[1][2] = self.text_positions[1][2] + self.font:getHeight()
    end

    if #self.choices >= 2 then
        local str_width = self.font:getWidth(self.choices[2])
        self.heart_positions[2] = { 496 - str_width, 34 }
        self.text_positions[2] = { 496 - str_width + 32, -8 }

        if #StringUtils.split(self.choices[2], "\n", false) < 3 then
            self.text_positions[2][2] = self.text_positions[2][2] + self.font:getHeight()
        end
    end

    if #self.choices >= 3 then
        -- The left bound is the right side of the left choice (plus 32 pixels of padding)
        local left_bound = self.heart_positions[1][1] + 32 + self.font:getWidth(self.choices[1])

        -- The right bound is the left side of the right choice
        local right_bound = self.heart_positions[2][1]

        local top_width = self.font:getWidth(self.choices[3]) + 32
        local bottom_width = 0

        if #self.choices >= 4 then
            bottom_width = self.font:getWidth(self.choices[4]) + 32
        end

        local vertical_width = math.max(top_width, bottom_width)

        self.heart_positions[3] = { (left_bound + ((right_bound - left_bound) / 2)) - (vertical_width / 2), -2 }
        self.text_positions[3] = { self.heart_positions[3][1] + 32, -8 }

        if #self.choices >= 4 then
            self.heart_positions[4] = { self.heart_positions[3][1], 86 }

            self.text_positions[4] = { self.heart_positions[4][1] + 32, 78 }
        end
    end

    if self.current_choice ~= 0 then
        self.heart_x = self.heart_positions[self.current_choice][1]
        self.heart_y = self.heart_positions[self.current_choice][2]
    end
end

function Choicebox:initChoices()
    if self:shouldUseNewStyle() then
        self:initNewChoices()
    else
        self:initOldChoices()
    end
end

function Choicebox:updateNewHeart()
    if self.current_choice ~= 0 then
        local t = 1 - (1 - 0.8) ^ DTMULT

        self.heart_x = MathUtils.lerp(self.heart_x, self.heart_positions[self.current_choice][1], t)
        self.heart_y = MathUtils.lerp(self.heart_y, self.heart_positions[self.current_choice][2] - 8, t)
    end
end

function Choicebox:updateOldHeart()
    if self.current_choice ~= 0 then
        self.heart_x = self.heart_positions[self.current_choice][1]
        self.heart_y = self.heart_positions[self.current_choice][2]
    end
end

function Choicebox:updateHeart()
    if self:shouldUseNewStyle() then
        self:updateNewHeart()
    else
        self:updateOldHeart()
    end
end

function Choicebox:update()
    self:handleConfirmInput()
    self:handleDirectionalInput()

    self:updateHeart()

    super.update(self)
end

function Choicebox:draw()
    super.draw(self)

    love.graphics.push("all")
    love.graphics.setFont(self.font)

    for i = 1, #self.choices do
        if self.current_choice == i then
            Draw.setColor(self.hover_colors[i])
        else
            Draw.setColor(self.main_colors[i])
        end

        local text_x = self.text_positions[i][1]
        local text_y = self.text_positions[i][2]

        if self:shouldUseNewStyle() then
            local lines = StringUtils.split(self.choices[i], "\n", false)

            local starting_y = text_y - (self.font:getHeight() * #lines / 2)

            for j = 1, #lines do
                local draw_x = text_x - (self.font:getWidth(lines[j]) / 2)
                local draw_y = starting_y + (self.font:getHeight() * (j - 1))
                love.graphics.print(lines[j], draw_x, draw_y)
            end
        else
            love.graphics.print(self.choices[i], text_x, text_y)
        end
    end

    Draw.setColor(Game:getSoulColor())
    Draw.draw(self.heart, self.heart_x, self.heart_y, 0, 2, 2)

    love.graphics.pop()
end

function Choicebox:setSize(w, h)
    self.width, self.height = w or 0, h or 0

    self.box:setSize(self.width, self.height)
end

function Choicebox:clearChoices()
    self.choices = {}
    self.text_positions = {}
    self.heart_positions = {}
    self.current_choice = 0
end

--- Adds a new choice to the choicebox.
---@param name string The name of the new choice that will be shown for the selection.
function Choicebox:addChoice(name)
    if #self.choices >= 4 then
        error("Choicebox cannot have more than 4 choices")
    end

    table.insert(self.choices, name)
    self:initChoices()
end

--- Sets the main and hover colors for every choice in the choicebox.
---@param main? table   The main color to set for all choices, or a table of main colors for each individual choice. (Defaults to `COLORS.white`)
---@param hover? table  The hover color to set for all choices, or a table of hover colors for each individual choice. (Defaults to `COLORS.yellow`)
function Choicebox:setColors(main, hover)
    main = main or COLORS.white
    hover = hover or COLORS.yellow

    if type(main[1]) == "number" then
        self.main_colors = {
            ColorUtils.ensureAlpha(main),
            ColorUtils.ensureAlpha(main),
            ColorUtils.ensureAlpha(main),
            ColorUtils.ensureAlpha(main)
        }
    else
        self.main_colors = TableUtils.copy(main)
    end

    if type(hover[1]) == "number" then
        self.hover_colors = {
            ColorUtils.ensureAlpha(hover),
            ColorUtils.ensureAlpha(hover),
            ColorUtils.ensureAlpha(hover),
            ColorUtils.ensureAlpha(hover)
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
