---@class MainMenuCredits : StateClass
---
---@field menu MainMenu
---
---@field pages {[1]: string, [2]: creditsline[], [3]: creditsline[]|nil}[]
---
---@field selected_page number
---@field scroll_direction string
---@field scroll_timer number
---
---@overload fun(menu:MainMenu) : MainMenuCredits
local MainMenuCredits, super = Class(StateClass)

---@alias creditsline string|{[1]: string, [2]: number[]}

function MainMenuCredits:init(menu)
    self.menu = menu

    self.pages = {
        {
            "Kristal Engine",
            {
                {"Lead Developers", COLORS.silver},
                "Nyakorita",
                "SylviBlossom",
                "vitellary",
                "",
                {"Assets", COLORS.silver},
                "Toby Fox",
                "Temmie Chang",
                "DELTARUNE team",
                "",
                "",
            },
            {
                {"GitHub Contributors", COLORS.silver},
                "AcousticJamm",
                "Agent 7",
                "AlexGamingSW",
                "Archie-osu",
                "Bor",
                "Dobby233Liu",
                "FireRainV",
                "HUECYCLES",
                "Luna",
                "MrOinky"
            }
        },
        {
            "Kristal Engine",
            {
                {"GitHub Contributors", COLORS.silver},
                "prokube",
                "Scarm",
                "Simbel",
                "sjl057",
                "skarph",
                "WIL-TZY",
                "",
                "",
                "",
                ""
            },
            {
                {"GitHub Contributors", COLORS.silver},
                "",
                "",
                "",
                "",
                "",
                "",
                "",
                "",
                "",
                "",
            }
        }
    }
    self.selected_page = 1

    self.scroll_direction = "right"
    self.scroll_timer = 0
end

function MainMenuCredits:registerEvents(master)
    self:registerEvent("enter", self.onEnter)
    self:registerEvent("keypressed", self.onKeyPressed)

    self:registerEvent("update", self.update)
    self:registerEvent("draw", self.draw)
end

-------------------------------------------------------------------------------
-- Callbacks
-------------------------------------------------------------------------------

function MainMenuCredits:onEnter(old_state)
    self.selected_page = 1

    self.scroll_direction = "right"
    self.scroll_timer = 0

    self.menu.heart_target_x = 320 - 32 - 16 + 1
    self.menu.heart_target_y = 480 - 16 + 1
end

function MainMenuCredits:onKeyPressed(key, is_repeat)
    if Input.isCancel(key) or Input.isConfirm(key) then
        self.menu:setState("TITLE")

        if Input.isCancel(key) then
            Assets.stopAndPlaySound("ui_move")
        else
            Assets.stopAndPlaySound("ui_select")
        end

        self.menu.title_screen:selectOption("credits")
    end

    local page_dir = "right"
    local page_now = self.selected_page

    if Input.is("left", key) then
        page_now = page_now - 1
        page_dir = "left"
    end
    if Input.is("right", key) then
        page_now = page_now + 1
        page_dir = "right"
    end

    page_now = Utils.clamp(page_now, 1, #self.pages)

    if page_now ~= self.selected_page then
        self.selected_page = page_now

        Assets.stopAndPlaySound("ui_move")

        self.scroll_direction = page_dir
        self.scroll_timer = 0.1
    end
end

function MainMenuCredits:update()
    if self.scroll_timer > 0 then
        self.scroll_timer = Utils.approach(self.scroll_timer, 0, DT)
    end
end

function MainMenuCredits:draw()
    local menu_font = Assets.getFont("main")

    local page = self.pages[self.selected_page]

    local title = page[1]:upper()
    local title_width = menu_font:getWidth(title)

    Draw.setColor(COLORS.silver)
    Draw.printShadow("( CREDITS )", 0, 0, 2, "center", 640)

    Draw.setColor(1, 1, 1)
    Draw.printShadow(title, 0, 48, 2, "center", 640)

    if #self.pages > 1 then
        local l_offset, r_offset = 0, 0

        if self.scroll_timer > 0 then
            if self.scroll_direction == "left" then
                l_offset = -4
            elseif self.scroll_direction == "right" then
                r_offset = 4
            end
        end

        if self.selected_page >= #self.pages then
            Draw.setColor(COLORS.silver, 0.5)
        else
            Draw.setColor(COLORS.white)
        end
        Draw.draw(Assets.getTexture("kristal/menu_arrow_right"), 320 + (title_width / 2) + 8 + r_offset, 52, 0, 2, 2)

        if self.selected_page == 1 then
            Draw.setColor(COLORS.silver, 0.5)
        else
            Draw.setColor(COLORS.white)
        end
        Draw.draw(Assets.getTexture("kristal/menu_arrow_left"), 320 - (title_width / 2) - 26 + l_offset, 52, 0, 2, 2)

        Draw.setColor(COLORS.white)
    end

    local left_column = page[2]
    local right_column = page[3] or {}

    for index, value in ipairs(left_column) do
        local color = {1, 1, 1, 1}
        local offset = 0
        if type(value) == "table" then
            color = value[2]
            value = value[1]
        else
            offset = offset + 32
        end
        Draw.setColor(color)
        Draw.printShadow(value, 32 + offset, 64 + (32 * index))
    end
    for index, value in ipairs(right_column) do
        local color = {1, 1, 1, 1}
        local offset = 0
        if type(value) == "table" then
            color = value[2]
            value = value[1]
        else
            offset = offset - 32
        end
        Draw.setColor(color)
        Draw.printShadow(value, 0, 64 + (32 * index), 2, "right", 640 - 32 + offset)
    end

    Draw.setColor(1, 1, 1)
    Draw.printShadow("Back", 0, 454 - 8, 2, "center", 640)
end

return MainMenuCredits
