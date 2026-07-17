---@class EditorTemplateRegistry
local EditorTemplateRegistry = {}

local function replacePlain(source, from, to)
    local pattern = tostring(from):gsub("([^%w])", "%%%1")
    return source:gsub(pattern, function() return tostring(to) end)
end

local function luaQuote(value)
    return string.format("%q", tostring(value or ""))
end

local function luaValue(value, indent)
    if Registry and Registry.editor_properties and Registry.editor_properties.formatValue then
        return Registry.editor_properties:formatValue(value, indent or 0)
    end
    if type(value) == "string" then return luaQuote(value) end
    if type(value) ~= "table" then return value == nil and "nil" or tostring(value) end
    local entries = {}
    for _, key in ipairs(TableUtils.getSortedKeys(value)) do
        local key_text = type(key) == "number" and "" or "[" .. luaQuote(key) .. "] = "
        table.insert(entries, key_text .. luaValue(value[key], (indent or 0) + 1))
    end
    return "{" .. table.concat(entries, ", ") .. "}"
end

local function classFromId(id, suffix)
    local words = tostring(id or "new"):gsub("[^%w]+", " ")
    local result = words:gsub("(%w+)", function(word)
        return word:sub(1, 1):upper() .. word:sub(2)
    end):gsub("%s+", "")
    if result == "" or result:match("^%d") then result = "New" .. result end
    return result .. (suffix or "")
end

local function sourceRenderer(definition, values)
    local source = definition.source
    if not source and definition.source_path then
        local reason
        source, reason = love.filesystem.read(definition.source_path)
        if not source then return nil, reason or ("Could not read " .. definition.source_path) end
    end
    source = source or ""
    for _, replacement in ipairs(definition.replacements or {}) do
        local value = values[replacement.value]
        if replacement.format == "lua" then value = luaQuote(value) end
        source = replacePlain(source, replacement.from, value == nil and "" or value)
    end
    source = source:gsub("{{([%w_]+)|lua}}", function(id) return luaQuote(values[id]) end)
    source = source:gsub("{{([%w_]+)}}", function(id) return tostring(values[id] or "") end)

    local overrides = {}
    for _, method in ipairs(definition.methods or {}) do
        if values._methods and values._methods[method.id] then table.insert(overrides, method.source) end
    end
    local method_source = table.concat(overrides, "\n\n")
    if source:find("-- Function overrides go here", 1, true) then
        source = replacePlain(source, "-- Function overrides go here", method_source)
    elseif method_source ~= "" then
        local inserted = false
        source = source:gsub("\n(return%s+[%w_%.]+%s*)$", function(return_line)
            inserted = true
            return "\n\n" .. method_source .. "\n\n" .. return_line
        end, 1)
        if not inserted then source = source:gsub("%s*$", "\n\n" .. method_source .. "\n") end
    end
    return source
end

local function replaceLuaAssignment(source, key, replacement)
    local marker = "self." .. key
    local search = 1
    while true do
        local start = source:find(marker, search, true)
        if not start then return source, false end
        local equals = start + #marker
        while source:sub(equals, equals):match("[ \t]") do equals = equals + 1 end
        if source:sub(equals, equals) == "=" then
            local value_start = equals + 1
            while source:sub(value_start, value_start):match("[ \t]") do value_start = value_start + 1 end
            local depth, quote, escaped, index = 0, nil, false, value_start
            while index <= #source do
                local character = source:sub(index, index)
                local next_character = source:sub(index + 1, index + 1)
                if quote then
                    if escaped then
                        escaped = false
                    elseif character == "\\" then
                        escaped = true
                    elseif character == quote then
                        quote = nil
                    end
                elseif character == "\"" or character == "'" then
                    quote = character
                elseif character == "{" or character == "[" or character == "(" then
                    depth = depth + 1
                elseif character == "}" or character == "]" or character == ")" then
                    depth = math.max(0, depth - 1)
                elseif depth == 0 and character == "-" and next_character == "-" then
                    break
                elseif depth == 0 and (character == "\n" or character == "\r") then
                    break
                end
                index = index + 1
            end
            local value_end = index - 1
            while value_end >= value_start and source:sub(value_end, value_end):match("[ \t]") do
                value_end = value_end - 1
            end
            return source:sub(1, value_start - 1) .. replacement .. source:sub(value_end + 1), true
        end
        search = start + #marker
    end
end

local function assignment(id, key, transform, options)
    options = options or {}
    return { id = id, key = key or id, transform = transform, skip_nil = options.skip_nil == true }
end

local function assignmentRenderer(definition, values)
    local source, reason = sourceRenderer(definition, values)
    if not source then return nil, reason end
    for _, entry in ipairs(definition.assignments or {}) do
        local value = values[entry.id]
        if entry.transform then value = entry.transform(value, values, definition) end
        if value ~= nil or not entry.skip_nil then
            local found
            source, found = replaceLuaAssignment(source, entry.key, luaValue(value, 1))
            if not found then
                return nil, "Template is missing assignment for self." .. entry.key
            end
        end
    end
    return source
end

local function variable(id, name, field_type, default, options)
    options = options or {}
    options.id = id
    options.name = name
    options.type = field_type or "string"
    options.default = default
    return options
end

local function emptyToNil(value)
    return value == "" and nil or value
end

local function colorValue(value)
    return value and ColorUtils.tryHexToRGB(value) or nil
end

local function method(id, label, source, default)
    return { id = id, name = label, source = source, default = default == true }
end

local function classDefinition(options)
    local code_names = {}
    for _, entry in ipairs(options.assignments or {}) do
        local names = code_names[entry.id] or {}
        if not TableUtils.contains(names, entry.key) then table.insert(names, entry.key) end
        code_names[entry.id] = names
    end
    for _, field in ipairs(options.variables or {}) do
        if field.id == "class_name" and not field.validate then
            field.validate = function(value)
                return value:match("^[%a_][%w_]*$") ~= nil, "Class must be a valid Lua identifier"
            end
        end
        if field.code_name == nil and code_names[field.id] then
            field.code_name = table.concat(code_names[field.id], ", ")
        end
    end
    local replacements = {
        { from = options.template_class, value = "class_name" },
        { from = luaQuote(options.template_id), value = "id", format = "lua" }
    }
    for _, replacement in ipairs(options.replacements or {}) do table.insert(replacements, replacement) end
    return {
        name = options.name,
        kind = "file",
        category = options.category,
        description = options.description,
        suggested_directory = options.directory,
        suggested_filename = function(values) return (values.id:match("([^/]+)$") or values.id) .. ".lua" end,
        source_path = options.source_path,
        replacements = replacements,
        assignments = options.assignments,
        variables = options.variables,
        methods = options.methods,
        render = options.render or (options.assignments and assignmentRenderer or sourceRenderer)
    }
end

function EditorTemplateRegistry.render(definition, values, context)
    if type(definition) == "string" then definition = Registry.getEditorTemplate(definition) end
    if not definition then return nil, "Unknown editor template" end
    if definition.render then return definition.render(definition, values or {}, context or {}) end
    return sourceRenderer(definition, values or {})
end

function EditorTemplateRegistry.defaultValue(field, values, context, definition)
    local value = field.default
    if type(value) == "function" then value = value(values or {}, context or {}, definition) end
    if type(value) == "table" then return TableUtils.copy(value, true) end
    return value
end

function EditorTemplateRegistry.coerce(field, value)
    if field.type == "boolean" then return value == true end
    if field.type == "asset_path_list" then
        if type(value) == "string" then value = { value } end
        if value == nil then value = {} end
        if type(value) ~= "table" then return nil, field.name .. " must be a list of asset paths" end
        local result = {}
        for index, path in ipairs(value) do
            if type(path) ~= "string" then
                return nil, field.name .. " entry " .. index .. " must be an asset path"
            end
            path = path:match("^%s*(.-)%s*$"):gsub("\\", "/"):gsub("^%./", "")
            result[index] = path
        end
        while result[#result] == "" do table.remove(result) end
        if #result == 0 and field.required ~= true then return nil end
        if #result == 0 then return nil, field.name .. " requires at least one asset path" end
        return result
    end
    if field.type == "table" then
        if value == nil and field.nullable then return nil end
        if type(value) ~= "table" then return nil, field.name .. " must be a table" end
        if field.nullable and next(value) == nil then return nil end
        return TableUtils.copy(value, true)
    end
    if field.type == "vector2" or field.type == "vector4" or field.type == "vector" then
        if value == nil and field.nullable then return nil end
        local size = field.size or (field.type == "vector4" and 4 or 2)
        if type(value) ~= "table" then return nil, field.name .. " must have " .. size .. " components" end
        local result = {}
        for index = 1, size do
            result[index] = tonumber(value[index])
            if not result[index] then return nil, field.name .. " component " .. index .. " must be a number" end
        end
        return result
    end
    if field.type == "value" then
        if value == nil or value == "" then return field.nullable and nil or "" end
        local result = Registry.editor_properties:coerce("value", value)
        if result == nil then
            return nil, Registry.editor_properties.last_function_error or (field.name .. " is invalid")
        end
        return result
    end
    if field.type == "color" then
        value = tostring(value or "")
        if value == "" and field.nullable then return nil end
        if not ColorUtils.tryHexToRGB(value) then return nil, field.name .. " must be a hex RGB or RGBA color" end
        return value
    end
    if field.type == "integer" or field.type == "number" then
        if (value == nil or value == "") and field.nullable then return nil end
        value = tonumber(value)
        if not value then return nil, field.name .. " must be a number" end
        if field.type == "integer" then value = MathUtils.round(value) end
        if field.minimum then value = math.max(field.minimum, value) end
        if field.maximum then value = math.min(field.maximum, value) end
        return value
    end
    if field.type == "choice" then
        for _, choice in ipairs(type(field.choices) == "function" and field.choices(field) or field.choices or {}) do
            local choice_value = type(choice) == "table" and (choice.value ~= nil and choice.value or choice.id) or choice
            if tostring(choice_value) == tostring(value) then return choice_value end
        end
        return nil, field.name .. " has an unknown option"
    end
    value = tostring(value or "")
    if field.required ~= false and value:match("^%s*$") then return nil, field.name .. " is required" end
    if field.validate then
        local valid, reason = field.validate(value)
        if valid == false then return nil, reason or (field.name .. " is invalid") end
    end
    return value
end

function EditorTemplateRegistry.registerBuiltins(registry)
    local register = function(id, definition) registry.registerEditorTemplate(id, definition) end
    local validId = function(value)
        return value:match("^[%w_%-/]+$") ~= nil,
            "IDs may only contain letters, numbers, underscores, dashes, and slashes"
    end

    register("core:map", {
        name = "Map", kind = "map", category = "Editor Data",
        description = "Create a native Kristal map.",
        variables = {
            variable("id", "ID", "string", "new_map", { validate = validId }),
            variable("name", "Name", "string", "New Map"),
            variable("width", "Grid Width", "integer", 16, { minimum = 1 }),
            variable("height", "Grid Height", "integer", 12, { minimum = 1 }),
            variable("grid_width", "Tile Width", "integer", 40, { minimum = 1 }),
            variable("grid_height", "Tile Height", "integer", 40, { minimum = 1 }),
            variable("background_color", "Background", "color", "#00000000")
        }
    })
    register("core:world", {
        name = "World", kind = "world", category = "Editor Data",
        description = "Create a world and optionally seed it with the active map.",
        variables = {
            variable("id", "ID", "string", "new_world", { validate = validId }),
            variable("name", "Name", "string", "New World"),
            variable("include_active_map", "Include Active Map", "boolean", true)
        }
    })
    register("core:tileset", {
        name = "Tileset", kind = "tileset", category = "Editor Data",
        description = "Create a native Kristal tileset.",
        variables = {
            variable("id", "ID", "string", "new_tileset", { validate = validId }),
            variable("name", "Name", "string", "New Tileset"),
            variable("image", "Images", "asset_path_list", { "" }, { required = false,
                path_kind = "asset", asset_categories = { "sprites" },
                extensions = { "png", "jpg", "jpeg", "bmp", "tga", "webp" },
                maximum_visible_rows = 5,
                description = "Add one image for a spritesheet, or one image per tile for a multi-image tileset." }),
            variable("tile_width", "Tile Width", "integer", 40, { minimum = 1 }),
            variable("tile_height", "Tile Height", "integer", 40, { minimum = 1 }),
            variable("tile_columns", "Columns", "integer", 1, { minimum = 1 }),
            variable("tile_count", "Tile Count", "integer", 0, { minimum = 0 }),
            variable("margin", "Margin", "integer", 0, { minimum = 0 }),
            variable("spacing", "Spacing", "integer", 0, { minimum = 0 })
        }
    })

    register("core:file_empty", {
        name = "Empty File", kind = "file", category = "General",
        description = "Create an empty file.", suggested_filename = "new.lua", source = ""
    })

    register("core:data_actor", classDefinition({
        name = "Actor", category = "Data", directory = "scripts/data/actors",
        source_path = "data_templates/actors/template.lua", template_class = "TemplateActor",
        template_id = "test_actor",
        variables = {
            variable("id", "ID", "string", "new_actor", { validate = validId }),
            variable("class_name", "Class", "string", "NewActor"),
            variable("display_name", "Display Name", "string", "New Actor", { code_name = "name" }),
            variable("width", "Width", "integer", 16, { minimum = 0 }),
            variable("height", "Height", "integer", 16, { minimum = 0 }),
            variable("hitbox", "Hitbox", "vector4", { 0, 0, 16, 16 },
                { components = { "X", "Y", "W", "H" } }),
            variable("soul_offset", "Soul Offset", "vector2", { 10, 24 }),
            variable("color", "Outline Color", "color", "#FF0000"),
            variable("flip", "Flip", "choice", "", { choices = {
                { value = "", label = "None" }, "right", "left"
            } }),
            variable("sprite_path", "Sprite Path", "string", "", { required = false, code_name = "path" }),
            variable("default", "Default Sprite / Animation", "string", "walk", { required = false }),
            variable("default_sprite", "Default Sprite", "value", nil, { nullable = true,
                description = "Optional explicit sprite value; accepts strings or Lua tables." }),
            variable("default_anim", "Default Animation", "value", nil, { nullable = true,
                description = "Optional explicit animation value; accepts strings or Lua tables." }),
            variable("voice", "Voice", "string", "", { required = false }),
            variable("font", "Font", "string", "", { required = false }),
            variable("speech_bubble_font_size", "Speech Bubble Font Size", "number", nil,
                { nullable = true }),
            variable("indent_string", "Indent String", "string", "", { required = false }),
            variable("portrait_path", "Portrait Path", "string", "", { required = false }),
            variable("portrait_offset", "Portrait Offset", "vector2", nil, { nullable = true }),
            variable("miniface", "Miniface", "string", "", { required = false }),
            variable("miniface_offset", "Miniface Offset", "vector2", nil, { nullable = true }),
            variable("can_blush", "Can Blush", "boolean", false),
            variable("talk_sprites", "Talk Sprites", "table", {}, { maximum_visible_rows = 4 }),
            variable("flip_sprites", "Sprite Flip Overrides", "table", {}, { maximum_visible_rows = 4 }),
            variable("mirror_sprites", "Mirror Sprites", "table", {
                ["walk/down"] = "walk/up", ["walk/up"] = "walk/down",
                ["walk/left"] = "walk/left", ["walk/right"] = "walk/right"
            }, { maximum_visible_rows = 4 }),
            variable("animations", "Animations", "table", {}, { maximum_visible_rows = 5 }),
            variable("offsets", "Sprite Offsets", "table", {}, { maximum_visible_rows = 5 })
        },
        replacements = {
            { from = luaQuote("Test Actor"), value = "display_name", format = "lua" },
            { from = luaQuote("party/kris/dark"), value = "sprite_path", format = "lua" }
        },
        methods = {
            method("get_name", "Get display name", "function actor:getName()\n    return self.name or self.id\nend"),
            method("world_update", "World update", "function actor:onWorldUpdate(chara)\nend"),
            method("world_draw", "World draw", "function actor:onWorldDraw(chara)\nend"),
            method("battle_update", "Battle update", "function actor:onBattleUpdate(battler)\nend"),
            method("battle_draw", "Battle draw", "function actor:onBattleDraw(battler)\nend"),
            method("talk_start", "Talk start", "function actor:onTalkStart(text, sprite)\nend"),
            method("talk_end", "Talk end", "function actor:onTalkEnd(text, sprite)\nend"),
            method("sprite_init", "Sprite initialization", "function actor:onSpriteInit(sprite)\nend"),
            method("pre_set", "Before setting sprite state", "function actor:preSet(sprite, name, callback)\nend"),
            method("on_set", "After setting sprite state", "function actor:onSet(sprite, name, callback)\nend"),
            method("pre_set_sprite", "Before setting sprite", "function actor:preSetSprite(sprite, texture, keep_anim)\nend"),
            method("on_set_sprite", "After setting sprite", "function actor:onSetSprite(sprite, texture, keep_anim)\nend"),
            method("pre_set_animation", "Before setting animation", "function actor:preSetAnimation(sprite, anim, callback)\nend"),
            method("on_set_animation", "After setting animation", "function actor:onSetAnimation(sprite, anim, callback)\nend"),
            method("pre_reset_sprite", "Before resetting sprite", "function actor:preResetSprite(sprite)\nend"),
            method("on_reset_sprite", "After resetting sprite", "function actor:onResetSprite(sprite)\nend"),
            method("pre_sprite_update", "Before sprite update", "function actor:preSpriteUpdate(sprite)\nend"),
            method("sprite_update", "After sprite update", "function actor:onSpriteUpdate(sprite)\nend"),
            method("pre_sprite_draw", "Before sprite draw", "function actor:preSpriteDraw(sprite)\nend"),
            method("sprite_draw", "After sprite draw", "function actor:onSpriteDraw(sprite)\nend"),
            method("text_sound", "Text sound", "function actor:onTextSound(node, state)\nend")
        },
        render = function(definition, values)
            local source, reason = sourceRenderer(definition, values)
            if not source then return nil, reason end
            local function optional(value)
                return (value == nil or value == "") and "nil" or luaQuote(value)
            end
            local replacements = {
                { "self.width = 16", "self.width = " .. tostring(values.width) },
                { "self.height = 16", "self.height = " .. tostring(values.height) },
                { "self.hitbox = {0, 0, 16, 16}", "self.hitbox = " .. luaValue(values.hitbox, 1) },
                { "self.soul_offset = {10, 24}", "self.soul_offset = " .. luaValue(values.soul_offset, 1) },
                { "self.color = {1, 0, 0}", "self.color = " .. luaValue(ColorUtils.tryHexToRGB(values.color), 1) },
                { "self.flip = nil", "self.flip = " .. optional(values.flip) },
                { "self.default = \"walk\"", "self.default = " .. luaQuote(values.default) },
                { "self.default_sprite = nil", "self.default_sprite = " .. luaValue(values.default_sprite, 1) },
                { "self.default_anim = nil", "self.default_anim = " .. luaValue(values.default_anim, 1) },
                { "self.voice = nil", "self.voice = " .. optional(values.voice) },
                { "self.font = nil", "self.font = " .. optional(values.font) },
                { "self.speech_bubble_font_size = nil", "self.speech_bubble_font_size = " .. luaValue(values.speech_bubble_font_size) },
                { "self.indent_string = nil", "self.indent_string = " .. optional(values.indent_string) },
                { "self.portrait_path = nil", "self.portrait_path = " .. optional(values.portrait_path) },
                { "self.portrait_offset = nil", "self.portrait_offset = " .. luaValue(values.portrait_offset, 1) },
                { "self.miniface = nil", "self.miniface = " .. optional(values.miniface) },
                { "self.miniface_offset = nil", "self.miniface_offset = " .. luaValue(values.miniface_offset, 1) },
                { "self.can_blush = false", "self.can_blush = " .. tostring(values.can_blush) },
                { "self.talk_sprites = {}", "self.talk_sprites = " .. luaValue(values.talk_sprites, 1) },
                { "self.flip_sprites = {}", "self.flip_sprites = " .. luaValue(values.flip_sprites, 1) },
                { "self.animations = {}", "self.animations = " .. luaValue(values.animations, 1) },
                { "self.offsets = {}", "self.offsets = " .. luaValue(values.offsets, 1) }
            }
            for _, replacement in ipairs(replacements) do
                source = replacePlain(source, replacement[1], replacement[2])
            end
            local mirror_default = [[self.mirror_sprites = {
        ["walk/down"] = "walk/up",
        ["walk/up"] = "walk/down",
        ["walk/left"] = "walk/left",
        ["walk/right"] = "walk/right",
    }]]
            source = replacePlain(source, mirror_default,
                "self.mirror_sprites = " .. luaValue(values.mirror_sprites, 1))
            return source
        end
    }))
    local function itemVariables(options)
        local fields = {
            variable("id", "ID", "string", options.id, { validate = validId }),
            variable("class_name", "Class", "string", options.class_name),
            variable("display_name", "Display Name", "string", options.display_name),
            variable("use_name", "Battle Use Name", "string", "", { required = false }),
            variable("type", "Item Type", "choice", "item", { choices = { "item", "key", "weapon", "armor" } }),
            variable("icon", "Equipment Icon", "string", "", { required = false }),
            variable("light", "Light World Item", "boolean", false),
            variable("effect", "Battle Description", "string", options.effect or "", { multiline = true }),
            variable("shop", "Shop Description", "string", options.shop or "", { multiline = true }),
            variable("description", "Menu Description", "string", options.description, { multiline = true }),
            variable("check", "Check Text", "value", options.check),
            variable("price", "Default Price", "integer", 0, { minimum = 0 }),
            variable("can_sell", "Can Sell", "boolean", true),
            variable("buy_price", "Buy Price", "integer", nil, { nullable = true, minimum = 0 }),
            variable("sell_price", "Sell Price", "integer", nil, { nullable = true, minimum = 0 }),
            variable("target", "Target", "choice", options.target or "none", {
                choices = { "ally", "party", "enemy", "enemies", "none" }
            }),
            variable("usable_in", "Usable In", "choice", "all", {
                choices = { "world", "battle", "all", "none" }
            }),
            variable("result_item", "Result Item", "string", "", { required = false }),
            variable("instant", "Instant Battle Use", "boolean", false),
            variable("bonuses", "Equip Bonuses", "table", {}, { maximum_visible_rows = 5 }),
            variable("bonus_name", "Bonus Name", "string", "", { required = false }),
            variable("bonus_icon", "Bonus Icon", "string", "", { required = false }),
            variable("bonus_color", "Bonus Color", "color", nil, { nullable = true,
                description = "Blank uses the editor's world ability icon color." }),
            variable("can_equip", "Character Equip Rules", "table", {}, { maximum_visible_rows = 4 }),
            variable("reactions", "Character Reactions", "table", {}, { maximum_visible_rows = 5 })
        }
        return fields
    end
    local function itemAssignments()
        return {
            assignment("display_name", "name"), assignment("use_name", nil, emptyToNil),
            assignment("type"), assignment("icon", nil, emptyToNil), assignment("light"),
            assignment("effect"), assignment("shop"), assignment("description"), assignment("check"),
            assignment("price"), assignment("can_sell"), assignment("buy_price"), assignment("sell_price"),
            assignment("target"), assignment("usable_in"), assignment("result_item", nil, emptyToNil),
            assignment("instant"), assignment("bonuses"), assignment("bonus_name", nil, emptyToNil),
            assignment("bonus_icon", nil, emptyToNil),
            assignment("bonus_color", nil, colorValue, { skip_nil = true }),
            assignment("can_equip"), assignment("reactions")
        }
    end
    local itemMethods = {
        method("world_use", "World use", "function item:onWorldUse(target)\n    -- Apply the item's world effect here.\nend"),
        method("battle_use", "Battle use", "function item:onBattleUse(user, target)\n    -- Apply the item's battle effect here.\nend"),
        method("battle_select", "Battle select / deselect", "function item:onBattleSelect(user, target)\nend\n\nfunction item:onBattleDeselect(user, target)\nend"),
        method("equip", "Equip / unequip", "function item:onEquip(character, replacement)\n    return true\nend\n\nfunction item:onUnequip(character, replacement)\n    return true\nend"),
        method("menu", "Menu open / close", "function item:onMenuOpen(menu)\nend\n\nfunction item:onMenuClose(menu)\nend"),
        method("damage", "Damage modifiers", "function item:onWorldDamage(amount)\n    return amount\nend\n\nfunction item:onBattleDamage(amount, swoon, all)\n    return amount\nend"),
        method("save", "Save / load", "function item:onSave(data)\nend\n\nfunction item:onLoad(data)\nend")
    }

    register("core:data_item", classDefinition({
        name = "Item", category = "Data", directory = "scripts/data/items",
        source_path = "data_templates/items/template.lua", template_class = "TemplateItem",
        template_id = "test_item",
        variables = itemVariables({ id = "new_item", class_name = "NewItem", display_name = "New Item",
            description = "A new item.", check = "Example info" }),
        assignments = itemAssignments(), methods = itemMethods
    }))

    local foodVariables = itemVariables({ id = "new_food", class_name = "NewFoodItem",
        display_name = "New Food", effect = "Heals\n100HP", shop = "Example\nfood\nheals 100HP",
        description = "Example food. +100HP", check = "Heals 100HP", target = "ally" })
    local healingFields = {
        variable("heal_amount", "Heal Amount", "integer", 100),
        variable("world_heal_amount", "World Heal Amount", "integer", nil, { nullable = true }),
        variable("battle_heal_amount", "Battle Heal Amount", "integer", nil, { nullable = true }),
        variable("heal_amounts", "Character Heal Amounts", "table", {}, { maximum_visible_rows = 4 }),
        variable("world_heal_amounts", "World Character Amounts", "table", {}, { maximum_visible_rows = 4 }),
        variable("battle_heal_amounts", "Battle Character Amounts", "table", {}, { maximum_visible_rows = 4 })
    }
    for _, field in ipairs(healingFields) do table.insert(foodVariables, field) end
    local foodAssignments = itemAssignments()
    for _, key in ipairs({ "heal_amount", "world_heal_amount", "battle_heal_amount",
        "heal_amounts", "world_heal_amounts", "battle_heal_amounts" }) do
        table.insert(foodAssignments, assignment(key))
    end
    register("core:data_food", classDefinition({
        name = "Healing Item", category = "Data", directory = "scripts/data/items",
        source_path = "data_templates/items/food_template.lua", template_class = "TemplateFoodItem",
        template_id = "test_food", variables = foodVariables, assignments = foodAssignments,
        methods = itemMethods
    }))

    local defaultLwExp = {
        0, 10, 30, 70, 120, 200, 300, 500, 800, 1200,
        1700, 2500, 3500, 5000, 7000, 10000, 15000, 25000, 50000, 99999
    }
    local partyAssignments = {
        assignment("display_name", "name"), assignment("title"), assignment("level"),
        assignment("lw_lv"), assignment("lw_exp"), assignment("soul_priority"),
        assignment("soul_color", nil, colorValue), assignment("has_act"), assignment("has_spells"),
        assignment("has_xact"), assignment("xact_name"), assignment("health"), assignment("lw_health"),
        assignment("stats"), assignment("max_stats"), assignment("stronger_absent"), assignment("lw_stats"),
        assignment("weapon_icon"), assignment("lw_weapon_default", nil, emptyToNil),
        assignment("lw_armor_default", nil, emptyToNil), assignment("color", nil, colorValue),
        assignment("dmg_color", nil, colorValue), assignment("attack_bar_color", nil, colorValue),
        assignment("attack_box_color", nil, colorValue), assignment("xact_color", nil, colorValue),
        assignment("menu_icon"), assignment("head_icons"), assignment("name_sprite", nil, emptyToNil),
        assignment("attack_sprite"), assignment("attack_sound"), assignment("attack_pitch"),
        assignment("battle_offset"), assignment("head_icon_offset"), assignment("menu_icon_offset"),
        assignment("gameover_message"), assignment("lw_exp_needed")
    }
    register("core:data_party", classDefinition({
        name = "Party Member", category = "Data", directory = "scripts/data/party",
        source_path = "data_templates/party/template.lua", template_class = "TemplateCharacter",
        template_id = "test_character",
        variables = {
            variable("id", "ID", "string", "new_member", { validate = validId }),
            variable("class_name", "Class", "string", "NewPartyMember"),
            variable("display_name", "Display Name", "string", "New Member"),
            variable("actor", "Actor", "string", "new_actor", { code_name = "actor" }),
            variable("light_actor", "Light Actor", "string", "", { required = false, code_name = "lw_actor" }),
            variable("dark_transition_actor", "Dark Transition Actor", "string", "", {
                required = false, code_name = "dark_transition_actor"
            }),
            variable("title", "Title / Class", "string", "Player"),
            variable("level", "Display Level", "integer", 1, { minimum = 1 }),
            variable("lw_lv", "Light World LV", "integer", 1, { minimum = 1 }),
            variable("lw_exp", "Light World EXP", "integer", 0, { minimum = 0 }),
            variable("soul_priority", "Soul Priority", "integer", 2),
            variable("soul_color", "Soul Color", "color", "#FF0000"),
            variable("has_act", "Can ACT", "boolean", true),
            variable("has_spells", "Can Use Spells", "boolean", false),
            variable("has_xact", "Has X-Action", "boolean", true),
            variable("xact_name", "X-Action Name", "string", "?-Action"),
            variable("spells", "Starting Spells", "table", { "heal_prayer" }, {
                maximum_visible_rows = 4, code_name = "spells"
            }),
            variable("health", "Starting Health", "number", 100, { minimum = 0 }),
            variable("lw_health", "Light World Health", "number", 20, { minimum = 0 }),
            variable("stats", "Base Stats", "table", { health = 100, attack = 10, defense = 2, magic = 0 },
                { maximum_visible_rows = 5 }),
            variable("max_stats", "Max Stats", "table", {}, { maximum_visible_rows = 4 }),
            variable("stronger_absent", "Linked Growth Members", "table", {}, { maximum_visible_rows = 4 }),
            variable("lw_stats", "Light World Stats", "table", { health = 20, attack = 10, defense = 10 },
                { maximum_visible_rows = 4 }),
            variable("weapon_icon", "Weapon Icon", "string", "ui/menu/equip/sword"),
            variable("weapon", "Starting Weapon", "string", "wood_blade", {
                required = false, code_name = "equipped.weapon"
            }),
            variable("armors", "Starting Armors", "table", {}, {
                maximum_visible_rows = 3, code_name = "equipped.armor"
            }),
            variable("lw_weapon_default", "Light World Weapon", "string", "light/pencil", { required = false }),
            variable("lw_armor_default", "Light World Armor", "string", "light/bandage", { required = false }),
            variable("color", "Character Color", "color", "#FFFFFF"),
            variable("dmg_color", "Damage Color", "color", nil, { nullable = true }),
            variable("attack_bar_color", "Attack Bar Color", "color", nil, { nullable = true }),
            variable("attack_box_color", "Attack Box Color", "color", nil, { nullable = true }),
            variable("xact_color", "X-Action Color", "color", nil, { nullable = true }),
            variable("menu_icon", "Menu Icon", "string", "party/kris/head"),
            variable("head_icons", "Battle Head Icons", "string", "party/kris/icon"),
            variable("name_sprite", "Name Sprite", "string", "", { required = false }),
            variable("attack_sprite", "Attack Effect", "string", "effects/attack/cut"),
            variable("attack_sound", "Attack Sound", "string", "laz_c"),
            variable("attack_pitch", "Attack Pitch", "number", 1),
            variable("battle_offset", "Battle Offset", "vector2", nil, { nullable = true }),
            variable("head_icon_offset", "Head Icon Offset", "vector2", nil, { nullable = true }),
            variable("menu_icon_offset", "Menu Icon Offset", "vector2", nil, { nullable = true }),
            variable("gameover_message", "Game Over Message", "table", nil, { nullable = true,
                maximum_visible_rows = 4 }),
            variable("lw_exp_needed", "Light World EXP Table", "table", defaultLwExp,
                { maximum_visible_rows = 5 })
        },
        assignments = partyAssignments,
        render = function(definition, values)
            local source, reason = assignmentRenderer(definition, values)
            if not source then return nil, reason end
            source = replacePlain(source, "self:setActor(\"kris\")",
                "self:setActor(" .. luaQuote(values.actor) .. ")")
            source = replacePlain(source, "self:setLightActor(\"kris_lw\")",
                "self:setLightActor(" .. luaValue(emptyToNil(values.light_actor)) .. ")")
            source = replacePlain(source, "self:setDarkTransitionActor(nil)",
                "self:setDarkTransitionActor(" .. luaValue(emptyToNil(values.dark_transition_actor)) .. ")")
            local spellLines = {}
            for _, spell in ipairs(values.spells or {}) do
                table.insert(spellLines, "self:addSpell(" .. luaQuote(spell) .. ")")
            end
            source = replacePlain(source, "self:addSpell(\"heal_prayer\")", table.concat(spellLines, "\n    "))
            source = replacePlain(source, "self:setWeapon(\"wood_blade\")",
                "self:setWeapon(" .. luaValue(emptyToNil(values.weapon)) .. ")")
            local armorLines = {}
            for index, armor in ipairs(values.armors or {}) do
                table.insert(armorLines, "self:setArmor(" .. index .. ", " .. luaValue(emptyToNil(armor)) .. ")")
            end
            if #armorLines == 0 then
                armorLines = { "self:setArmor(1, nil)", "self:setArmor(2, nil)" }
            end
            source = replacePlain(source, "self:setArmor(1, nil)\n    self:setArmor(2, nil)",
                table.concat(armorLines, "\n    "))
            return source
        end,
        methods = {
            method("attack_hit", "Attack hit", "function character:onAttackHit(enemy, damage)\nend"),
            method("turn_start", "Turn start", "function character:onTurnStart(battler)\nend"),
            method("action_select", "Action select", "function character:onActionSelect(battler, undo)\nend"),
            method("level_up", "Level up", "function character:onLevelUp(level)\nend"),
            method("power_menu", "Power menu select / deselect", "function character:onPowerSelect(menu)\nend\n\nfunction character:onPowerDeselect(menu)\nend"),
            method("equip", "Equip / unequip", "function character:onEquip(item, replacement)\n    return true\nend\n\nfunction character:onUnequip(item, replacement)\n    return true\nend"),
            method("save", "Save / load", "function character:onSave(data)\nend\n\nfunction character:onLoad(data)\nend")
        }
    }))

    register("core:data_spell", classDefinition({
        name = "Spell", category = "Data", directory = "scripts/data/spells",
        source_path = "data_templates/spells/template.lua", template_class = "TemplateSpell",
        template_id = "test_spell",
        variables = {
            variable("id", "ID", "string", "new_spell", { validate = validId }),
            variable("class_name", "Class", "string", "NewSpell"),
            variable("display_name", "Display Name", "string", "New Spell"),
            variable("cast_name", "Cast Name", "string", "", { required = false }),
            variable("effect", "Battle Description", "string", "Test\neffect", { multiline = true }),
            variable("description", "Menu Description", "string", "Example spell.", { multiline = true }),
            variable("cost", "TP Cost", "number", 32, { minimum = 0 }),
            variable("usable", "Usable", "boolean", true),
            variable("target", "Target", "choice", "enemy", {
                choices = { "ally", "party", "enemy", "enemies", "none" }
            }),
            variable("tags", "Tags", "table", {}, { maximum_visible_rows = 4 }),
            variable("cast_anim", "Cast Animation", "string", "", { required = false,
                description = "Blank uses battle/spell." }),
            variable("select_anim", "Select Animation", "string", "", { required = false,
                description = "Blank uses battle/spell_ready." })
        },
        assignments = {
            assignment("display_name", "name"), assignment("cast_name", nil, emptyToNil),
            assignment("effect"), assignment("description"), assignment("cost"), assignment("usable"),
            assignment("target"), assignment("tags"), assignment("cast_anim", nil, emptyToNil),
            assignment("select_anim", nil, emptyToNil)
        },
        methods = {
            method("world_usage", "World usage", "function spell:hasWorldUsage(chara)\n    return true\nend\n\nfunction spell:onWorldCast(chara)\nend"),
            method("cast_message", "Cast message", "function spell:getCastMessage(user, target)\n    return super.getCastMessage(self, user, target)\nend"),
            method("animations", "Cast animations", "function spell:getCastAnimation()\n    return \"battle/spell\"\nend\n\nfunction spell:getSelectAnimation()\n    return \"battle/spell_ready\"\nend"),
            method("start", "Action start", "function spell:onStart(user, target)\nend"),
            method("select", "Select / deselect", "function spell:onSelect(user, target)\nend\n\nfunction spell:onDeselect(user, target)\nend")
        }
    }))

    local scriptMethods = {
        bullet = {
            method("on_collide", "On collision", "function bullet:onCollide(soul)\n    super.onCollide(self, soul)\nend"),
            method("on_damage", "On damage", "function bullet:onDamage(soul)\n    return super.onDamage(self, soul)\nend"),
            method("on_graze", "On graze", "function bullet:onGraze(first)\nend"),
            method("on_spawn", "On wave spawn", "function bullet:onWaveSpawn(wave)\nend"),
            method("damage_rules", "Damage rules", "function bullet:getDamage()\n    return super.getDamage(self)\nend\n\nfunction bullet:shouldSwoon(damage, target, soul)\n    return false\nend\n\nfunction bullet:getInvulnFrames()\n    return super.getInvulnFrames(self)\nend")
        },
        encounter = {
            method("battle_init", "Battle initialization", "function encounter:onBattleInit()\nend"),
            method("battle_start", "Battle start", "function encounter:onBattleStart()\nend"),
            method("turn", "Turn start / end", "function encounter:onTurnStart()\nend\n\nfunction encounter:onTurnEnd()\nend"),
            method("actions", "Actions start / end", "function encounter:onActionsStart()\nend\n\nfunction encounter:onActionsEnd()\nend"),
            method("character_turn", "Character turn", "function encounter:onCharacterTurn(battler, undo)\nend"),
            method("next_waves", "Choose waves", "function encounter:getNextWaves()\n    return super.getNextWaves(self)\nend"),
            method("battle_end", "Battle end", "function encounter:onBattleEnd()\nend"),
            method("return_world", "Return to world", "function encounter:onReturnToWorld(events)\nend"),
            method("victory", "Victory rewards / text", "function encounter:getVictoryMoney(money)\n    return money\nend\n\nfunction encounter:getVictoryXP(xp)\n    return xp\nend\n\nfunction encounter:getVictoryText(text, money, xp)\n    return text\nend")
        },
        enemy = {
            method("act", "ACT handling", "function enemy:onAct(battler, name)\n    if name == \"Check\" then\n        return self:onCheck(battler)\n    end\nend"),
            method("check", "Check handling", "function enemy:onCheck(battler)\nend"),
            method("dialogue", "Enemy dialogue", "function enemy:getEnemyDialogue()\n    return self.dialogue\nend"),
            method("waves", "Choose waves", "function enemy:getNextWaves()\n    return self.waves\nend"),
            method("turn", "Turn start / end", "function enemy:onTurnStart()\nend\n\nfunction enemy:onTurnEnd()\nend"),
            method("hurt", "Hurt / dodge", "function enemy:onHurt(damage, battler)\nend\n\nfunction enemy:onDodge(battler, attacked)\nend"),
            method("spared", "Spared / spareable", "function enemy:onSpared()\nend\n\nfunction enemy:onSpareable()\nend"),
            method("defeat", "On defeat", "function enemy:onDefeat(damage, battler)\n    super.onDefeat(self, damage, battler)\nend")
        },
        wave = {
            method("start", "Wave start", "function wave:onStart()\n    -- Spawn bullets and schedule attacks here.\nend", true),
            method("update", "Wave update", "function wave:update()\n    super.update(self)\nend"),
            method("arena", "Arena enter / exit", "function wave:onArenaEnter()\nend\n\nfunction wave:onArenaExit()\nend"),
            method("finish", "Wave end", "function wave:onEnd(death)\nend"),
            method("end_rules", "Wave end rules", "function wave:beforeEnd()\nend\n\nfunction wave:canEnd()\n    return true\nend")
        },
        event = {
            method("interact", "Interaction", "function event:onInteract(player, dir)\n    return true\nend"),
            method("collide", "Collision", "function event:onCollide(player)\nend"),
            method("enter_exit", "Enter / exit", "function event:onEnter(player)\nend\n\nfunction event:onExit(player)\nend"),
            method("load", "Map load", "function event:onLoad()\nend\n\nfunction event:postLoad()\nend"),
            method("tree", "Added / removed", "function event:onAdd(parent)\n    super.onAdd(self, parent)\nend\n\nfunction event:onRemove(parent)\n    super.onRemove(self, parent)\nend"),
            method("draw", "Draw", "function event:draw()\n    super.draw(self)\nend")
        },
        shop = {
            method("post_init", "Post initialization", "function shop:postInit()\n    super.postInit(self)\nend"),
            method("enter", "Enter shop", "function shop:onEnter()\nend"),
            method("talk", "Talk", "function shop:onTalk()\nend"),
            method("leave", "Leave shop", "function shop:onLeave()\nend"),
            method("state", "State change", "function shop:onStateChange(old, new)\n    super.onStateChange(self, old, new)\nend"),
            method("emote", "Shopkeeper emote", "function shop:onEmote(emote)\n    super.onEmote(self, emote)\nend"),
            method("background", "Draw background", "function shop:drawBackground()\n    super.drawBackground(self)\nend")
        }
    }
    local scripts = {
        { "bullet", "Battle Bullet", "Battle", "script_templates/battle/bullets/template.lua", "TemplateBullet", "test_bullet", "scripts/battle/bullets" },
        { "encounter", "Battle Encounter", "Battle", "script_templates/battle/encounters/template.lua", "TemplateEncounter", "test_encounter", "scripts/battle/encounters" },
        { "enemy", "Battle Enemy", "Battle", "script_templates/battle/enemies/template.lua", "TemplateEnemy", "test_enemy", "scripts/battle/enemies" },
        { "wave", "Battle Wave", "Battle", "script_templates/battle/waves/template.lua", "TemplateWave", "test_wave", "scripts/battle/waves" },
        { "event", "World Event", "World", "script_templates/world/events/template.lua", "TemplateEvent", "test_event", "scripts/world/events" },
        { "shop", "Shop", "World", "script_templates/shops/template.lua", "TemplateShop", "test_shop", "scripts/shops" }
    }
    local scriptVariables = {
        bullet = {
            variable("damage", "Damage", "number", nil, { nullable = true }),
            variable("tp", "Graze TP", "number", nil, { nullable = true }),
            variable("can_graze", "Can Graze", "boolean", true),
            variable("time_bonus", "Graze Time Bonus", "number", 1),
            variable("inv_frames", "Invulnerability Frames", "integer", nil, { nullable = true,
                description = "Blank uses Game:getDefaultInvulnFrames()." }),
            variable("destroy_on_hit", "Destroy On Hit", "boolean", true),
            variable("remove_offscreen", "Remove Offscreen", "boolean", true)
        },
        encounter = {
            variable("battle_text", "Encounter Text", "string", "* A battle begins!", { multiline = true }),
            variable("music", "Music", "string", "battle", { required = false }),
            variable("background", "Create Background", "boolean", true),
            variable("hide_world", "Hide World", "boolean", false),
            variable("default_xactions", "Default X-Actions", "choice", "", { choices = {
                { value = "", label = "Project Default" }, { value = true, label = "Enabled" },
                { value = false, label = "Disabled" }
            } }),
            variable("no_end_message", "Skip End Message", "boolean", false),
            variable("reduced_tension", "Reduced Tension", "boolean", false)
        },
        enemy = {
            variable("display_name", "Display Name", "string", "New Enemy"),
            variable("health", "Health", "integer", 100, { minimum = 1 }),
            variable("attack", "Attack", "integer", 1),
            variable("defense", "Defense", "integer", 0),
            variable("money", "Money", "integer", 0),
            variable("experience", "Experience", "integer", 0),
            variable("tired", "Starts Tired", "boolean", false),
            variable("mercy", "Starting Mercy", "number", 0),
            variable("spare_points", "Spare Points", "number", 0),
            variable("exit_on_defeat", "Exit On Defeat", "boolean", true),
            variable("auto_spare", "Auto Spare", "boolean", false),
            variable("can_freeze", "Can Freeze", "boolean", true),
            variable("selectable", "Selectable", "boolean", true),
            variable("disable_mercy", "Disable Mercy", "boolean", false),
            variable("check", "Check Text", "string", "A new enemy.", { multiline = true }),
            variable("text", "Encounter Text", "table", {}, { maximum_visible_rows = 4 }),
            variable("low_health_text", "Low Health Text", "string", "", { required = false, multiline = true }),
            variable("tired_text", "Tired Text", "string", "", { required = false, multiline = true }),
            variable("spareable_text", "Spareable Text", "string", "", { required = false, multiline = true }),
            variable("tired_percentage", "Tired Threshold", "number", 0.5),
            variable("low_health_percentage", "Low Health Threshold", "number", 0.5),
            variable("dmg_sprites", "Damage Sprites", "table", {}, { maximum_visible_rows = 4 }),
            variable("dmg_sprite_offset", "Damage Sprite Offset", "vector2", { 0, 0 }),
            variable("dialogue_bubble", "Dialogue Bubble", "string", "", { required = false }),
            variable("dialogue_offset", "Dialogue Offset", "vector2", { 0, 0 }),
            variable("dialogue", "Dialogue", "table", {}, { maximum_visible_rows = 4 }),
            variable("waves", "Waves", "table", {}, { maximum_visible_rows = 5 }),
            variable("acts", "ACTs", "table", {
                { name = "Check", description = "Useless\nanalysis", party = {} }
            }, { maximum_visible_rows = 4 }),
            variable("comment", "Comment", "string", "", { required = false }),
            variable("icons", "Icons", "table", {}, { maximum_visible_rows = 4 }),
            variable("graze_tension", "Graze Tension", "number", 1.6)
        },
        wave = {
            variable("time", "Duration", "number", 5, { minimum = -1 }),
            variable("arena_x", "Arena X", "number", nil, { nullable = true }),
            variable("arena_y", "Arena Y", "number", nil, { nullable = true }),
            variable("arena_width", "Arena Width", "number", nil, { nullable = true }),
            variable("arena_height", "Arena Height", "number", nil, { nullable = true }),
            variable("arena_shape", "Arena Shape", "value", nil, { nullable = true }),
            variable("arena_rotation", "Arena Rotation", "number", 0),
            variable("has_arena", "Has Arena", "boolean", true),
            variable("spawn_soul", "Spawn Soul", "boolean", true),
            variable("soul_start_x", "Soul Start X", "number", nil, { nullable = true }),
            variable("soul_start_y", "Soul Start Y", "number", nil, { nullable = true }),
            variable("soul_offset_x", "Soul Offset X", "number", nil, { nullable = true }),
            variable("soul_offset_y", "Soul Offset Y", "number", nil, { nullable = true })
        },
        event = {
            variable("sprite", "Sprite", "string", "", { required = false, code_name = "sprite" }),
            variable("solid", "Solid", "boolean", false),
            variable("unique_id", "Default Unique ID", "string", "", { required = false }),
            variable("interact_buffer", "Interaction Buffer", "number", 5 / 30, { minimum = 0 })
        },
        shop = {
            variable("music", "Music", "string", "", { required = false }),
            variable("background", "Background", "string", "", { required = false }),
            variable("background_speed", "Background Speed", "number", 5 / 30),
            variable("voice", "Voice", "string", "", { required = false }),
            variable("currency_text", "Currency Format", "string", "$%d"),
            variable("encounter_text", "Encounter Text", "string", "* Encounter text", { multiline = true }),
            variable("shop_text", "Shop Text", "string", "* Shop text", { multiline = true }),
            variable("leaving_text", "Leaving Text", "string", "* Leaving text", { multiline = true }),
            variable("buy_menu_text", "Buy Menu Text", "string", "Purchase\ntext", { multiline = true }),
            variable("buy_confirmation_text", "Buy Confirmation", "string", "Buy it for\n%s ?", { multiline = true }),
            variable("buy_refuse_text", "Buy Refusal", "string", "Buy\nrefused\ntext", { multiline = true }),
            variable("buy_text", "Buy Success", "string", "Buy text", { multiline = true }),
            variable("buy_storage_text", "Buy To Storage", "string", "Storage\nbuy text", { multiline = true }),
            variable("buy_too_expensive_text", "Too Expensive", "string", "Not\nenough\nmoney.", { multiline = true }),
            variable("buy_no_space_text", "No Space", "string", "You're\ncarrying\ntoo much.", { multiline = true }),
            variable("sell_no_price_text", "No Sell Price", "string", "No\nprice\ntext", { multiline = true }),
            variable("sell_menu_text", "Sell Menu Text", "string", "Sell\nmenu\ntext", { multiline = true }),
            variable("sell_nothing_text", "Nothing To Sell", "string", "Sell\nnothing\nattempt", { multiline = true }),
            variable("sell_confirmation_text", "Sell Confirmation", "string", "Sell it for\n%s ?", { multiline = true }),
            variable("sell_refuse_text", "Sell Refusal", "string", "Sell\nrefuse\ntext", { multiline = true }),
            variable("sell_text", "Sell Success", "string", "Sell\ntext", { multiline = true }),
            variable("sell_no_storage_text", "Empty Storage", "string", "Empty\ninventory\ntext", { multiline = true }),
            variable("sell_everything_text", "Sold Everything", "string", "Sold\neverything\ntext", { multiline = true }),
            variable("talk_text", "Talk Text", "string", "Talk\ntext", { multiline = true }),
            variable("sell_options_text", "Sell Option Text", "table", {
                items = "Item text", weapons = "Weapon\ntext",
                armors = "Armor text", storage = "Storage\ntext"
            }, { maximum_visible_rows = 4 }),
            variable("menu_options", "Menu Options", "table", {
                { "Buy", "BUYMENU" }, { "Sell", "SELLMENU" },
                { "Talk", "TALKMENU" }, { "Exit", "LEAVE" }
            }, { maximum_visible_rows = 4 }),
            variable("hide_storage_text", "Hide Storage Text", "boolean", false),
            variable("hide_price", "Hide Price", "boolean", false),
            variable("hide_world", "Hide World", "boolean", true),
            variable("hide_main_menu_currency", "Hide Main Menu Currency", "boolean", false),
            variable("leave_options", "Leave Options", "table", {}, { maximum_visible_rows = 4 })
        }
    }
    local scriptAssignments = {
        bullet = {
            assignment("damage"), assignment("tp"), assignment("can_graze"), assignment("time_bonus"),
            assignment("inv_frames", nil, nil, { skip_nil = true }), assignment("destroy_on_hit"),
            assignment("remove_offscreen")
        },
        encounter = {
            assignment("battle_text", "text"), assignment("music", nil, emptyToNil),
            assignment("background"), assignment("hide_world"),
            assignment("default_xactions", nil, emptyToNil, { skip_nil = true }),
            assignment("no_end_message"), assignment("reduced_tension")
        },
        enemy = {
            assignment("display_name", "name"), assignment("health", "max_health"), assignment("health"),
            assignment("attack"), assignment("defense"), assignment("money"), assignment("experience"),
            assignment("tired"), assignment("mercy"), assignment("spare_points"), assignment("exit_on_defeat"),
            assignment("auto_spare"), assignment("can_freeze"), assignment("selectable"),
            assignment("disable_mercy"), assignment("check"), assignment("text"),
            assignment("low_health_text", nil, emptyToNil), assignment("tired_text", nil, emptyToNil),
            assignment("spareable_text", nil, emptyToNil), assignment("tired_percentage"),
            assignment("low_health_percentage"), assignment("dmg_sprites"), assignment("dmg_sprite_offset"),
            assignment("dialogue_bubble", nil, emptyToNil), assignment("dialogue_offset"),
            assignment("dialogue"), assignment("waves"), assignment("acts"), assignment("comment"),
            assignment("icons"), assignment("graze_tension")
        },
        wave = {
            assignment("time"), assignment("arena_x"), assignment("arena_y"), assignment("arena_width"),
            assignment("arena_height"), assignment("arena_shape"), assignment("arena_rotation"),
            assignment("has_arena"), assignment("spawn_soul"), assignment("soul_start_x"),
            assignment("soul_start_y"), assignment("soul_offset_x"), assignment("soul_offset_y")
        },
        event = {
            assignment("solid"), assignment("unique_id", nil, emptyToNil), assignment("interact_buffer")
        },
        shop = {
            assignment("music", "shop_music"), assignment("background", nil, emptyToNil),
            assignment("background_speed"), assignment("voice", nil, emptyToNil),
            assignment("currency_text"), assignment("encounter_text"), assignment("shop_text"),
            assignment("leaving_text"), assignment("buy_menu_text"), assignment("buy_confirmation_text"),
            assignment("buy_refuse_text"), assignment("buy_text"), assignment("buy_storage_text"),
            assignment("buy_too_expensive_text"), assignment("buy_no_space_text"),
            assignment("sell_no_price_text"), assignment("sell_menu_text"), assignment("sell_nothing_text"),
            assignment("sell_confirmation_text"), assignment("sell_refuse_text"), assignment("sell_text"),
            assignment("sell_no_storage_text"), assignment("sell_everything_text"), assignment("talk_text"),
            assignment("sell_options_text"), assignment("menu_options"), assignment("hide_storage_text"),
            assignment("hide_price"), assignment("hide_world"), assignment("hide_main_menu_currency"),
            assignment("leave_options")
        }
    }
    for _, script in ipairs(scripts) do
        local id, name, category, path, template_class, template_id, directory = unpack(script)
        local script_id = id
        local variables = {
            variable("id", "ID", "string", "new_" .. id, { validate = validId }),
            variable("class_name", "Class", "string", classFromId("new_" .. id))
        }
        for _, field in ipairs(scriptVariables[id] or {}) do table.insert(variables, field) end
        local options = {
            name = name, category = category, directory = directory, source_path = path,
            template_class = template_class, template_id = template_id,
            variables = variables,
            methods = scriptMethods[script_id],
            assignments = scriptAssignments[script_id]
        }
        if script_id == "event" then
            options.render = function(definition, values)
                local source, reason = assignmentRenderer(definition, values)
                if not source then return nil, reason end
                return replacePlain(source, "-- self:setSprite(\"objects/example\")",
                    values.sprite ~= "" and "self:setSprite(" .. luaQuote(values.sprite) .. ")"
                        or "-- self:setSprite(\"objects/example\")")
            end
        end
        register("core:script_" .. id, classDefinition(options))
    end

    local cutscenes = {
        { "cutscene", "Cutscene", "script_templates/cutscenes/template.lua", "scripts/cutscenes" },
        { "world_cutscene", "World Cutscene", "script_templates/world/cutscenes/template.lua", "scripts/world/cutscenes" },
        { "battle_cutscene", "Battle Cutscene", "script_templates/battle/cutscenes/template.lua", "scripts/battle/cutscenes" }
    }
    for _, entry in ipairs(cutscenes) do
        register("core:script_" .. entry[1], {
            name = entry[2], kind = "file", category = "Cutscenes", source_path = entry[3],
            suggested_directory = entry[4],
            suggested_filename = function(values) return values.id .. ".lua" end,
            variables = {
                variable("id", "File ID", "string", "new_cutscene", { validate = validId }),
                variable("function_name", "Function", "string", "new_cutscene", {
                    validate = function(value)
                        return value:match("^[%a_][%w_]*$") ~= nil,
                            "Function must be a valid Lua identifier"
                    end
                })
            },
            replacements = { { from = "template_cutscene", value = "function_name" } },
            render = sourceRenderer
        })
    end
end

return EditorTemplateRegistry
