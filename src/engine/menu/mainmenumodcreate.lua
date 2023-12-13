---@class MainMenuModCreate : StateClass
---
---@field menu MainMenu
---
---@field state string
---@field state_manager StateManager
---
---@field options modcreateoptions
---@field selected_option number
---
---@field chapter_options number[]
---@field id_adjusted boolean
---
---@field input_pos_x number
---@field input_pos_y number
---
---@overload fun(menu:MainMenu) : MainMenuModCreate
local MainMenuModCreate, super = Class(StateClass)

---@class modcreateoptions
---@field name {[1]: string}
---@field id {[1]: string}
---@field chapter number

function MainMenuModCreate:init(menu)
    self.menu = menu

    self.state_manager = StateManager("NONE", self, true)

    self.options = {
        name = {""},
        id = {""},
        chapter = 2
    }
    self.selected_option = 1

    self.chapter_options = {1, 2}
    self.id_adjusted = false

    self.input_pos_x = 0
    self.input_pos_y = 0
end

function MainMenuModCreate:registerEvents()
    self:registerEvent("enter", self.onEnter)
    self:registerEvent("keypressed", self.onKeyPressed)
    self:registerEvent("draw", self.draw)
end

-------------------------------------------------------------------------------
-- Callbacks
-------------------------------------------------------------------------------

function MainMenuModCreate:onEnter(old_state)
    if old_state == "MODCONFIG" then
        self.selected_option = 4

        local y_off = (4 - 1) * 32
        self.menu.heart_target_x = 45
        self.menu.heart_target_y = 147 + y_off

        return
    end

    self.options = {
        name = {""},
        id = {""},
        chapter = 2
    }
    self.selected_option = 1

    self.id_adjusted = false

    self.input_pos_x = 0
    self.input_pos_y = 0

    self.menu.mod_config:registerOptions()

    self:setState("MENU")

    self.menu.heart_target_x = 45
    self.menu.heart_target_y = 147
end

function MainMenuModCreate:onKeyPressed(key, is_repeat)
    if self.state == "MENU" then
        if Input.isCancel(key) then
            self.menu:setState("MODSELECT")
            Assets.stopAndPlaySound("ui_move")
            return
        end

        local old = self.selected_option
        if Input.is("up"   , key)                              then self.selected_option = self.selected_option - 1  end
        if Input.is("down" , key)                              then self.selected_option = self.selected_option + 1  end
        if Input.is("left" , key) and not Input.usingGamepad() then self.selected_option = self.selected_option - 1  end
        if Input.is("right", key) and not Input.usingGamepad() then self.selected_option = self.selected_option + 1  end
        if self.selected_option > 5 then self.selected_option = is_repeat and 5 or 1    end
        if self.selected_option < 1 then self.selected_option = is_repeat and 1 or 5    end

        local y_off = (self.selected_option - 1) * 32
        if self.selected_option >= 5 then
            y_off = y_off + 32
        end

        self.menu.heart_target_x = 45
        self.menu.heart_target_y = 147 + y_off

        if old ~= self.selected_option then
            Assets.stopAndPlaySound("ui_move")
        end

        if Input.isConfirm(key) then
            if self.selected_option == 1 then
                Assets.stopAndPlaySound("ui_select")
                self:setState("NAME")

            elseif self.selected_option == 2 then
                Assets.stopAndPlaySound("ui_select")
                self:setState("ID")

            elseif self.selected_option == 3 then
                Assets.stopAndPlaySound("ui_select")
                self:setState("CHAPTER")

            elseif self.selected_option == 4 then
                Assets.stopAndPlaySound("ui_select")
                self.menu:setState("MODCONFIG")

            elseif self.selected_option == 5 then
                local valid = true
                if self.options["name"][1] == "" or self.options["id"][1] == "" then valid = false end
                if love.filesystem.getInfo("mods/" .. self.options["id"][1] .. "/") then valid = false end

                if not valid then
                    Assets.stopAndPlaySound("ui_cant_select")
                    return
                end


                Assets.stopAndPlaySound("ui_select")
                self:createMod()
                self.menu:setState("MODSELECT")
            end
        end

    elseif self.state == "NAME" then
        if key == "escape" then
            self:onInputCancel()
            self:setState("MENU")
            Assets.stopAndPlaySound("ui_move")
            return
        end

    elseif self.state == "ID" then
        if key == "escape" then
            self:onInputCancel()
            self:setState("MENU")
            Assets.stopAndPlaySound("ui_move")
            return
        end

    elseif self.state == "CHAPTER" then
        if Input.isConfirm(key) or Input.isCancel(key) then
            self:setState("MENU")
            Assets.stopAndPlaySound("ui_select")
            return
        end
        if Input.is("left", key) then
            Assets.stopAndPlaySound("ui_move")
            self.options["chapter"] = self.options["chapter"] - 1
            if self.options["chapter"] < 1 then self.options["chapter"] = #self.chapter_options end
        end
        if Input.is("right", key) then
            Assets.stopAndPlaySound("ui_move")
            self.options["chapter"] = self.options["chapter"] + 1
            if self.options["chapter"] > #self.chapter_options then self.options["chapter"] = 1 end
        end
    end
end

function MainMenuModCreate:draw()
    love.graphics.setFont(Assets.getFont("main"))
    Draw.printShadow("Create New Mod", 0, 48, 2, "center", 640)

    local menu_x = 64
    local menu_y = 128

    self:drawInputLine("Mod name: ",          menu_x, menu_y + (32 * 0), "name")
    self:drawInputLine("Mod ID:   ",          menu_x, menu_y + (32 * 1), "id")
    Draw.printShadow(  "Base chapter: ",      menu_x, menu_y + (32 * 2))
    Draw.printShadow(  "Edit feature config", menu_x, menu_y + (32 * 3))
    Draw.printShadow(  "Create mod",          menu_x, menu_y + (32 * 5))

    local off = 256
    self:drawSelectionField(menu_x + off, menu_y + (32 * 2), "chapter", self.chapter_options, "CHAPTER")
    --self:drawCheckbox(menu_x + off, menu_y + (32 * 3), "transition")

    Draw.setColor(COLORS.silver)

    if self.selected_option == 1 then
        Draw.printShadow("The name of your mod. Shows in the menu.", 0, 480 - 32, 2, "center", 640)
    elseif self.selected_option == 2 then
        Draw.printShadow("The ID of your mod. Must be unique.", 0, 480 - 32, 2, "center", 640)
    elseif self.selected_option == 3 then
        Draw.printShadow("The chapter to base your mod off of in", 0, 480 - 64 - 32, 2, "center", 640)
        Draw.printShadow("terms of features. Individual features", 0, 480 - 64, 2, "center", 640)
        Draw.printShadow("can be toggled in the config.", 0, 480 - 32, 2, "center", 640)
    elseif self.selected_option == 4 then
        Draw.printShadow("Edit individual Kristal features.", 0, 480 - 32, 2, "center", 640)
    elseif self.selected_option == 5 then
        if self.options["id"][1] == "" then
            Draw.setColor(1, 0.6, 0.6)
            Draw.printShadow("You must enter a valid ID.", 0, 480 - 32, 2, "center", 640)
        elseif self.options["name"][1] == "" then
            Draw.setColor(1, 0.6, 0.6)
            Draw.printShadow("You must enter a valid name.", 0, 480 - 32, 2, "center", 640)
        else
            Draw.printShadow("Create the mod.", 0, 480 - 32, 2, "center", 640)
        end
    end

    Draw.setColor(1, 1, 1)

    if TextInput.active and (self.state ~= "MENU") then
        TextInput.draw({
            x = self.input_pos_x,
            y = self.input_pos_y,
            font = Assets.getFont("main"),
            print = function(text, x, y) Draw.printShadow(text, x, y) end,
        })
    end
end

-------------------------------------------------------------------------------
-- Class Methods
-------------------------------------------------------------------------------

function MainMenuModCreate:setState(state, ...)
    self.state_manager:setState(state, ...)
end

function MainMenuModCreate:onStateChange(old_state, state)
    if state == "MENU" then
        self.menu.heart_target_x = 45
    elseif state == "NAME" then
        self.menu.heart_target_x = 45 + 167
        self:openInput("name")
    elseif state == "ID" then
        self.menu.heart_target_x = 45 + 167
        self:openInput("id", function(letter)
            local disallowed = {"/", "\\", "*", ".", "?", ":", "\"", "<", ">", "|"}
            if Utils.containsValue(disallowed, letter) then
                return false
            end
            if letter == " "  then return "_" end
            return letter:lower()
        end)
    elseif state == "CHAPTER" then
        self.menu.heart_target_x = 45 + 167 + 64
    end
end

function MainMenuModCreate:onInputCancel()
    TextInput.input = {""}
    TextInput.endInput()
    self:setState("MENU")
end

function MainMenuModCreate:onInputSubmit(id)
    Assets.stopAndPlaySound("ui_select")
    TextInput.input = {""}
    TextInput.endInput()

    if id == "id" then
        self.id_adjusted = false
        self.options["id"][1] = self:disallowWindowsFolders(self.options["id"][1], false)
    end

    self:attemptUpdateID(id)

    Input.clear("return")

    self:setState("MENU")
end

function MainMenuModCreate:disallowWindowsFolders(str, auto)
    -- Check if STR is a disallowed file name in windows (e.g. "CON")
    if Utils.containsValue({"CON", "PRN", "AUX", "NUL", "COM1", "COM2", "COM3", "COM4", "COM5", "COM6", "COM7", "COM8", "COM9", "LPT1", "LPT2", "LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8", "LPT9"}, str:upper()) then
        if not auto then Assets.playSound("locker") end
        str = "disallowed_id"
    end
    return str
end

function MainMenuModCreate:adjustCreateID()
    local str = self.options["name"][1]

    str = self:disallowWindowsFolders(str, true)

    local newstr = ""
    for i = 1, utf8.len(str) do
        local offset = utf8.offset(str, i)
        local char = string.sub(str, offset, offset)
        local disallowed = {"/", "\\", "*", ".", "?", ":", "\"", "<", ">", "|"}
        if Utils.containsValue(disallowed, char) then
            char = ""
        end
        if char == " " then char = "_" end
        newstr = newstr .. char:lower()
    end
    self.options["id"][1] = newstr
    self.id_adjusted = true
end

function MainMenuModCreate:openInput(id, restriction)
    TextInput.attachInput(self.options[id], {
        multiline = false,
        enter_submits = true,
        clear_after_submit = false,
        text_restriction = restriction,
    })
    TextInput.submit_callback = function() self:onInputSubmit(id) end
    if id == "name" then
        TextInput.text_callback = function() self:attemptUpdateID("name") end
    else
        TextInput.text_callback = nil
    end
end

function MainMenuModCreate:attemptUpdateID(id)
    if (id == "name" or id == "id") and self.options["id"][1] == "" then
        self:adjustCreateID()
    end
    if (id == "name" and self.id_adjusted) then
        self:adjustCreateID()
    end
end

function MainMenuModCreate:createMod()
    local name = self.options["name"][1]
    local id = self.options["id"][1]

    local config_formatted = "            "
    for i, option in ipairs(self.menu.mod_config.options) do
        local chosen = option.options[option.selected]
        local text = chosen

        if chosen == true  then
            text = "true"
        elseif chosen == false then
            text = "false"
        elseif type(chosen) == "number" then
            text = tostring(chosen)
        elseif type(chosen) == "string" then
            text = "\"" .. chosen .. "\""
        else
            text = "UNHANDLED_TYPE_REPORT_TO_DEVS"
        end

        if chosen ~= nil then
            config_formatted = config_formatted .. "// " .. option.description .. "\n            "
            config_formatted = config_formatted .. "\"" .. option.id .. "\": " .. text .. "," .. "\n            "
        end
    end
    config_formatted = config_formatted .. "// End of config"

    local formatting_dict = {
        id = id,
        name = name,
        engineVer = "v" .. tostring(Kristal.Version),
        chapter = self.chapter_options[self.options["chapter"]],
        --transition = self.transition and "true" or "false",
        config = config_formatted
    }

    -- Create the directory
    local dir = "mods/" .. id .. "/"

    if not love.filesystem.getInfo(dir) then
        love.filesystem.createDirectory(dir)
    end

    -- Copy the files from mod_template
    local files = Utils.findFiles("mod_template")
    for i, file in ipairs(files) do
        local src = "mod_template/" .. file
        local dst = dir .. file
        dst = dst:gsub("modid", id)
        local info = love.filesystem.getInfo(src)
        if info then
            if info.type == "file" then
                if file == "mod.json" then
                    -- Special handling in case we're mod.json
                    local data = love.filesystem.read("string", src) --[[@as string]]
                    data = Utils.format(data, formatting_dict)

                    local write_file = love.filesystem.newFile(dst)
                    write_file:open("w")
                    write_file:write(data)
                    write_file:close()
                else
                    -- Copy the file
                    local data = love.filesystem.read("data", src)
                    local write_file = love.filesystem.newFile(dst)
                    write_file:open("w")
                    write_file:write(data)
                    write_file:close()
                end
            else
                -- Create the directory
                love.filesystem.createDirectory(dst)
            end
        end
    end
    
    -- Create empty useful folders (GitHub won't track empty folders)
    love.filesystem.createDirectory(dir .. "libraries")
    love.filesystem.createDirectory(dir .. "preview")
    love.filesystem.createDirectory(dir .. "scripts/objects")
    love.filesystem.createDirectory(dir .. "scripts/shops")
    love.filesystem.createDirectory(dir .. "scripts/world/bullets")
    love.filesystem.createDirectory(dir .. "scripts/world/scripts")
    love.filesystem.createDirectory(dir .. "scripts/data/party")
    love.filesystem.createDirectory(dir .. "scripts/data/spells")
    love.filesystem.createDirectory(dir .. "assets/music")
    love.filesystem.createDirectory(dir .. "assets/sprites/party")
    love.filesystem.createDirectory(dir .. "assets/sprites/shopkeepers")
    love.filesystem.createDirectory(dir .. "assets/sprites/ui")

    -- Reload mods
    self.menu.mod_list:reloadMods()
end

function MainMenuModCreate:drawSelectionField(x, y, id, options, state)
    Draw.printShadow(options[self.options[id]], x, y)

    if self.state == state then
        Draw.setColor(COLORS.white)
        local off = (math.sin(Kristal.getTime() / 0.2) * 2) + 2
        Draw.draw(Assets.getTexture("kristal/menu_arrow_left"), x - 16 - 8 - off, y + 4, 0, 2, 2)
        Draw.draw(Assets.getTexture("kristal/menu_arrow_right"), x + 16 + 8 - 4 + off, y + 4, 0, 2, 2)
    end
end

function MainMenuModCreate:drawCheckbox(x, y, id)
    x = x - 8
    local checked = self.options[id]
    love.graphics.setLineWidth(2)
    Draw.setColor(COLORS.black)
    love.graphics.rectangle("line", x + 2 + 2, y + 2 + 2, 32 - 4, 32 - 4)
    Draw.setColor(checked and COLORS.white or COLORS.silver)
    love.graphics.rectangle("line", x + 2, y + 2, 32 - 4, 32 - 4)
    if checked then
        Draw.setColor(COLORS.black)
        love.graphics.rectangle("line", x + 6 + 2, y + 6 + 2, 32 - 12, 32 - 12)
        Draw.setColor(COLORS.aqua)
        love.graphics.rectangle("fill", x + 6, y + 6, 32 - 12, 32 - 12)
    end
end

function MainMenuModCreate:drawInputLine(name, x, y, id)
    Draw.printShadow(name, x, y)
    love.graphics.setLineWidth(2)
    local line_x  = x + 128 + 32 + 16
    local line_x2 = line_x + 416 - 32
    local line_y = 32 - 4 - 1 + 2
    Draw.setColor(0, 0, 0)
    love.graphics.line(line_x + 2, y + line_y + 2, line_x2 + 2, y + line_y + 2)
    Draw.setColor(COLORS.silver)
    love.graphics.line(line_x, y + line_y, line_x2, y + line_y)
    Draw.setColor(1, 1, 1)

    if self.options[id] ~= TextInput.input then
        Draw.printShadow(self.options[id][1], line_x, y)
    else
        self.input_pos_x = line_x
        self.input_pos_y = y
    end
end

return MainMenuModCreate