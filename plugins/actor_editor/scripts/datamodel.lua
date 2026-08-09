local DataModel = {}

local MARKERS = {
    actor = {
        begin = "-- BEGIN KRISTAL ACTOR EDITOR",
        data_begin = "-- KRISTAL_ACTOR_EDITOR_DATA_BEGIN",
        data_end = "-- KRISTAL_ACTOR_EDITOR_DATA_END",
        finish = "-- END KRISTAL ACTOR EDITOR"
    },
    party = {
        begin = "-- BEGIN KRISTAL PARTY MEMBER EDITOR",
        data_begin = "-- KRISTAL_PARTY_EDITOR_DATA_BEGIN",
        data_end = "-- KRISTAL_PARTY_EDITOR_DATA_END",
        finish = "-- END KRISTAL PARTY MEMBER EDITOR"
    }
}

local ACTOR_FIELDS = {
    "name", "width", "height", "hitbox", "soul_offset", "color", "flip", "path", "default",
    "default_sprite", "default_anim", "voice", "font", "speech_bubble_font_size", "indent_string",
    "portrait_path", "portrait_offset", "miniface", "miniface_offset", "can_blush"
}

local PARTY_FIELDS = {
    "name", "title", "level", "lw_lv", "lw_exp", "soul_priority", "soul_color",
    "has_act", "has_spells", "has_xact", "xact_name", "health", "lw_health",
    "stats", "max_stats", "stronger_absent", "lw_stats", "weapon_icon",
    "lw_weapon_default", "lw_armor_default", "color", "dmg_color", "attack_bar_color",
    "attack_box_color", "xact_color", "menu_icon", "head_icons", "name_sprite",
    "attack_sprite", "attack_sound", "attack_pitch", "battle_offset",
    "head_icon_offset", "menu_icon_offset", "gameover_message", "lw_exp_needed"
}

local CHAPTER_FIELDS = {
    "title", "level", "health", "stats", "lw_lv", "lw_exp", "lw_health", "lw_stats"
}

---@generic T
---@param value T
---@param seen? table
---@return T copy
function DataModel.copy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local result = {}
    seen[value] = result
    for key, child in pairs(value) do
        result[DataModel.copy(key, seen)] = DataModel.copy(child, seen)
    end
    return result
end

local copy = DataModel.copy

local function isIdentifier(value)
    return type(value) == "string" and value:match("^[%a_][%w_]*$") ~= nil
end

local function quote(value)
    return string.format("%q", tostring(value))
end

local sortedKeys = TableUtils.getSortedKeys

local function encode(value, indent, seen)
    local value_type = type(value)
    if value_type == "nil" then return "nil" end
    if value_type == "boolean" or value_type == "number" then return tostring(value) end
    if value_type == "string" then return quote(value) end
    if value_type ~= "table" then error("Unsupported editor value type: " .. value_type) end
    seen = seen or {}
    if seen[value] then error("Actor editor data cannot contain recursive tables") end
    seen[value] = true
    indent = indent or 0
    local child_indent = indent + 1
    local padding, child_padding = string.rep("    ", indent), string.rep("    ", child_indent)
    local entries = {}
    local array_count = 0
    while value[array_count + 1] ~= nil do array_count = array_count + 1 end
    for index = 1, array_count do
        table.insert(entries, child_padding .. encode(value[index], child_indent, seen))
    end
    for _, key in ipairs(sortedKeys(value)) do
        if not (type(key) == "number" and key >= 1 and key <= array_count and key % 1 == 0) then
            local rendered_key = isIdentifier(key) and key or ("[" .. encode(key, child_indent, seen) .. "]")
            table.insert(entries, child_padding .. rendered_key .. " = "
                .. encode(value[key], child_indent, seen))
        end
    end
    seen[value] = nil
    if #entries == 0 then return "{}" end
    return "{\n" .. table.concat(entries, ",\n") .. "\n" .. padding .. "}"
end

local function decode(source)
    local chunk, reason = loadstring("return " .. source)
    if not chunk then return nil, reason end
    if setfenv then setfenv(chunk, {}) end
    local success, result = pcall(chunk)
    if not success then return nil, result end
    if type(result) ~= "table" then return nil, "Editor data is not a table" end
    return result
end

local trim = StringUtils.trim

local function getClassVariable(source)
    return source:match("local%s+([%a_][%w_]*)%s*,?[^=\n]*=%s*Class%s*%(")
        or source:match("local%s+([%a_][%w_]*)%s*=%s*Class%s*%(")
end

local function findManagedData(source, kind)
    local marker = MARKERS[kind]
    local data_start = source:find(marker.data_begin, 1, true)
    if not data_start then return nil end
    data_start = source:find("\n", data_start, true)
    local data_end = data_start and source:find(marker.data_end, data_start + 1, true)
    if not data_start or not data_end then return nil, "Editor data block is incomplete" end
    local assignment = source:sub(data_start + 1, data_end - 1)
    local value = assignment:match("^%s*local%s+[%a_][%w_]*%s*=%s*(.-)%s*$")
    if not value then return nil, "Editor data assignment is invalid" end
    return decode(value)
end

local function setField(data, key, value)
    data.fields = data.fields or {}
    data.nil_fields = data.nil_fields or {}
    if value == nil then
        data.fields[key] = nil
        data.nil_fields[key] = true
    else
        data.fields[key] = copy(value)
        data.nil_fields[key] = nil
    end
end

local function getField(data, key, fallback)
    if data.nil_fields and data.nil_fields[key] then return nil end
    if data.fields and data.fields[key] ~= nil then return copy(data.fields[key]) end
    return copy(fallback)
end

local function actorId(value)
    return type(value) == "table" and value.id or type(value) == "string" and value or nil
end

local function managedActor(data, key, fallback)
    if data[key] == nil then return fallback end
    return data[key] ~= false and data[key] or nil
end

local function editableAnimation(value)
    if type(value) == "string" then return true end
    if type(value) ~= "table" then return false end
    if type(value[1]) ~= "string" or value[2] ~= nil and type(value[2]) ~= "number"
        or value[3] ~= nil and type(value[3]) ~= "boolean" then
        return false
    end
    for key in pairs(value) do
        if key ~= 1 and key ~= 2 and key ~= 3 then return false end
    end
    return true
end

local function scan(directory, registry)
    local root = Mod.info.path:gsub("\\", "/"):gsub("/+$", "") .. "/" .. directory
    local entries = {}
    local function visit(path, relative)
        local info = love.filesystem.getInfo(path)
        if not info then return end
        if info.type == "directory" then
            local items = love.filesystem.getDirectoryItems(path)
            table.sort(items, function(first, second) return first:lower() < second:lower() end)
            for _, name in ipairs(items) do
                visit(path .. "/" .. name, relative == "" and name or relative .. "/" .. name)
            end
        elseif relative:lower():match("%.lua$") then
            local source = ProjectFileSystem.readFile(path)
            if source then
                local fallback_id = relative:gsub("%.lua$", "")
                local explicit_id = source:match("Class%s*%([^,\n]+,%s*[\"']([^\"']+)[\"']")
                local id = explicit_id or fallback_id
                table.insert(entries, {
                    id = id,
                    label = id,
                    path = path,
                    relative_path = directory .. "/" .. relative,
                    class = registry and registry[id],
                    source = source
                })
            end
        end
    end
    visit(root, "")
    table.sort(entries, function(first, second) return first.id:lower() < second.id:lower() end)
    return entries
end

function DataModel.scanActors()
    return scan("scripts/data/actors", Registry.actors)
end

function DataModel.scanPartyMembers()
    return scan("scripts/data/party", Registry.party_members)
end

function DataModel.createActorModel(entry)
    local success, instance = pcall(Registry.createActor, entry.id)
    if not success then instance = nil end
    local existing, reason = findManagedData(entry.source, "actor")
    if reason then return nil, reason end
    existing = existing or {}
    local model = {
        kind = "actor",
        id = entry.id,
        path = entry.path,
        source = entry.source,
        class_variable = getClassVariable(entry.source),
        values = {},
        fields = {},
        nil_fields = copy(existing.nil_fields or {}),
        animations = {},
        animation_editable = {},
        animation_overrides = copy(existing.animation_overrides or {}),
        animation_removals = copy(existing.animation_removals or {}),
        offset_overrides = copy(existing.offset_overrides or {}),
        offset_removals = copy(existing.offset_removals or {}),
        dirty = false
    }
    model.fields = copy(existing.fields or {})
    for _, key in ipairs(ACTOR_FIELDS) do
        model.values[key] = getField(existing, key, instance and instance[key])
    end
    for id, animation in pairs(instance and instance.animations or {}) do
        model.animations[id] = copy(animation)
        model.animation_editable[id] = editableAnimation(animation)
    end
    for id, animation in pairs(model.animation_overrides) do
        model.animations[id] = copy(animation)
        model.animation_editable[id] = editableAnimation(animation)
    end
    for id in pairs(model.animation_removals) do
        model.animations[id], model.animation_editable[id] = nil, nil
    end
    model.offsets = copy(instance and instance.offsets or {})
    for id, offset in pairs(model.offset_overrides) do model.offsets[id] = copy(offset) end
    for id in pairs(model.offset_removals) do model.offsets[id] = nil end
    return model
end

function DataModel.createPartyModel(entry)
    local success, instance = pcall(Registry.createPartyMember, entry.id)
    if not success then instance = nil end
    local existing, reason = findManagedData(entry.source, "party")
    if reason then return nil, reason end
    existing = existing or {}
    local model = {
        kind = "party",
        id = entry.id,
        path = entry.path,
        source = entry.source,
        class_variable = getClassVariable(entry.source),
        values = {},
        fields = {},
        nil_fields = copy(existing.nil_fields or {}),
        chapters = copy(existing.chapters or {}),
        actor = managedActor(existing, "actor", actorId(instance and instance.actor)),
        light_actor = managedActor(existing, "light_actor", actorId(instance and instance.lw_actor)),
        dark_transition_actor = managedActor(existing, "dark_transition_actor",
            actorId(instance and instance.dark_transition_actor)),
        dirty = false
    }
    model.fields = copy(existing.fields or {})
    for _, key in ipairs(PARTY_FIELDS) do
        model.values[key] = getField(existing, key, instance and instance[key])
    end
    return model
end

function DataModel.getField(model, key)
    return getField(model, key, model.values and model.values[key])
end

function DataModel.setField(model, key, value)
    setField(model, key, value)
    model.values = model.values or {}
    model.values[key] = copy(value)
    model.dirty = true
end

function DataModel.getChapterField(model, chapter, key)
    local values = model.chapters[chapter]
    if values and values[key] ~= nil then return copy(values[key]) end
    return DataModel.getField(model, key)
end

function DataModel.setChapterField(model, chapter, key, value)
    model.chapters[chapter] = model.chapters[chapter] or {}
    model.chapters[chapter][key] = copy(value)
    model.dirty = true
end

function DataModel.clearChapter(model, chapter)
    model.chapters[chapter] = nil
    model.dirty = true
end

function DataModel.getActorFields()
    return ACTOR_FIELDS
end

function DataModel.getPartyFields()
    return PARTY_FIELDS
end

function DataModel.getChapterFields()
    return CHAPTER_FIELDS
end

function DataModel.setAnimation(model, id, value)
    model.animations[id] = copy(value)
    model.animation_editable[id] = editableAnimation(value)
    model.animation_overrides[id] = copy(value)
    model.animation_removals[id] = nil
    model.dirty = true
end

function DataModel.removeAnimation(model, id)
    model.animations[id], model.animation_editable[id], model.animation_overrides[id] = nil, nil, nil
    model.animation_removals[id] = true
    model.dirty = true
end

function DataModel.renameAnimation(model, old_id, new_id)
    new_id = trim(new_id)
    if new_id == "" or new_id == old_id or model.animations[new_id] ~= nil then return false end
    local value = model.animations[old_id]
    DataModel.removeAnimation(model, old_id)
    DataModel.setAnimation(model, new_id, value)
    if model.offsets[old_id] then
        DataModel.setOffset(model, new_id, model.offsets[old_id])
        DataModel.removeOffset(model, old_id)
    end
    return true
end

function DataModel.setOffset(model, id, value)
    model.offsets[id] = copy(value)
    model.offset_overrides[id] = copy(value)
    model.offset_removals[id] = nil
    model.dirty = true
end

function DataModel.removeOffset(model, id)
    model.offsets[id], model.offset_overrides[id] = nil, nil
    model.offset_removals[id] = true
    model.dirty = true
end

local function assignmentLines(fields, nil_fields, prefix)
    local lines = {}
    for _, key in ipairs(sortedKeys(fields or {})) do
        table.insert(lines, string.format("    %s.%s = %s", prefix, key, encode(fields[key], 1)))
    end
    for _, key in ipairs(sortedKeys(nil_fields or {})) do
        if nil_fields[key] then table.insert(lines, string.format("    %s.%s = nil", prefix, key)) end
    end
    return lines
end

local function managedData(model)
    if model.kind == "actor" then
        return {
            fields = copy(model.fields),
            nil_fields = copy(model.nil_fields),
            animation_overrides = copy(model.animation_overrides),
            animation_removals = copy(model.animation_removals),
            offset_overrides = copy(model.offset_overrides),
            offset_removals = copy(model.offset_removals)
        }
    end
    return {
        fields = copy(model.fields),
        nil_fields = copy(model.nil_fields),
        actor = model.actor == nil and false or model.actor,
        light_actor = model.light_actor == nil and false or model.light_actor,
        dark_transition_actor = model.dark_transition_actor == nil and false
            or model.dark_transition_actor,
        chapters = copy(model.chapters)
    }
end

local function buildActorBlock(model)
    local marker = MARKERS.actor
    local data = managedData(model)
    local variable = assert(model.class_variable, "Could not identify the actor class variable")
    local lines = {
        marker.begin,
        marker.data_begin,
        "local __kristal_actor_editor_data = " .. encode(data),
        marker.data_end,
        "local __kristal_actor_editor_init = " .. variable .. ".init",
        "function " .. variable .. ":init(...)",
        "    __kristal_actor_editor_init(self, ...)"
    }
    for _, line in ipairs(assignmentLines(data.fields, data.nil_fields, "self")) do table.insert(lines, line) end
    for _, id in ipairs(sortedKeys(data.animation_removals)) do
        if data.animation_removals[id] then
            table.insert(lines, "    self.animations[" .. quote(id) .. "] = nil")
        end
    end
    for _, id in ipairs(sortedKeys(data.animation_overrides)) do
        table.insert(lines, "    self.animations[" .. quote(id) .. "] = "
            .. encode(data.animation_overrides[id], 1))
    end
    for _, id in ipairs(sortedKeys(data.offset_removals)) do
        if data.offset_removals[id] then table.insert(lines, "    self.offsets[" .. quote(id) .. "] = nil") end
    end
    for _, id in ipairs(sortedKeys(data.offset_overrides)) do
        table.insert(lines, "    self.offsets[" .. quote(id) .. "] = "
            .. encode(data.offset_overrides[id], 1))
    end
    table.insert(lines, "end")
    table.insert(lines, marker.finish)
    return table.concat(lines, "\n")
end

local function buildPartyBlock(model)
    local marker = MARKERS.party
    local data = managedData(model)
    local variable = assert(model.class_variable, "Could not identify the party member class variable")
    local lines = {
        marker.begin,
        marker.data_begin,
        "local __kristal_party_editor_data = " .. encode(data),
        marker.data_end,
        "local __kristal_party_editor_init = " .. variable .. ".init",
        "function " .. variable .. ":init(...)",
        "    __kristal_party_editor_init(self, ...)"
    }
    for _, line in ipairs(assignmentLines(data.fields, data.nil_fields, "self")) do table.insert(lines, line) end
    table.insert(lines, "    self:setActor(" .. encode(data.actor ~= false and data.actor or nil) .. ")")
    table.insert(lines, "    self:setLightActor("
        .. encode(data.light_actor ~= false and data.light_actor or nil) .. ")")
    table.insert(lines, "    self:setDarkTransitionActor("
        .. encode(data.dark_transition_actor ~= false and data.dark_transition_actor or nil) .. ")")
    local chapters = sortedKeys(data.chapters)
    for index, chapter in ipairs(chapters) do
        table.insert(lines, string.format("    %s Game.chapter == %s then",
            index == 1 and "if" or "elseif", tostring(chapter)))
        local chapter_values = data.chapters[chapter]
        for _, key in ipairs(CHAPTER_FIELDS) do
            if chapter_values[key] ~= nil then
                table.insert(lines, "        self." .. key .. " = " .. encode(chapter_values[key], 2))
            end
        end
    end
    if #chapters > 0 then table.insert(lines, "    end") end
    table.insert(lines, "end")
    table.insert(lines, marker.finish)
    return table.concat(lines, "\n")
end

local function installBlock(source, kind, block)
    local marker = MARKERS[kind]
    local first = source:find(marker.begin, 1, true)
    if first then
        local last = source:find(marker.finish, first, true)
        if not last then return nil, "Existing editor block is incomplete" end
        last = last + #marker.finish - 1
        return source:sub(1, first - 1) .. block .. source:sub(last + 1)
    end
    local return_start = source:match("()\n%s*return%s+[%a_][%w_]*%s*$")
        or source:match("()^%s*return%s+[%a_][%w_]*%s*$")
    if not return_start then return nil, "Could not find the class return statement" end
    local prefix = source:sub(1, return_start - 1):gsub("%s+$", "")
    local suffix = source:sub(return_start):gsub("^%s+", "")
    return prefix .. "\n\n" .. block .. "\n\n" .. suffix
end

local function reload(model)
    local chunk, reason = love.filesystem.load(model.path)
    if not chunk then return false, reason end
    local success, class = xpcall(chunk, ErrorUtils.traceback)
    if not success then return false, class end
    if not class then return false, "Edited file did not return a class" end
    class.id = class.id or model.id
    if model.kind == "actor" then
        Registry.registerActor(model.id, class)
    else
        Registry.registerPartyMember(model.id, class)
    end
    return true
end

function DataModel.save(model)
    local built, block = xpcall(function()
        return model.kind == "actor" and buildActorBlock(model) or buildPartyBlock(model)
    end, ErrorUtils.traceback)
    if not built then return false, block end
    local source, reason = installBlock(model.source, model.kind, block)
    if not source then return false, reason end
    local written
    written, reason = ProjectFileSystem.writeFile(model.path, source)
    if not written then return false, reason end
    model.source = source
    model.dirty = false
    local reloaded, reload_reason = reload(model)
    if not reloaded then
        return true, "Saved, but could not reload the class:\n" .. tostring(reload_reason)
    end
    return true, nil
end

function DataModel.signature(model)
    local success, result = pcall(function() return encode(managedData(model)) end)
    return success and result or nil
end

function DataModel.animationIsEditable(value)
    return editableAnimation(value)
end

function DataModel.getAnimationSprite(value)
    if type(value) == "string" then return value end
    if type(value) == "table" and type(value[1]) == "string" then return value[1] end
end

function DataModel.getAnimationDelay(value)
    return type(value) == "table" and tonumber(value[2]) or nil
end

function DataModel.getAnimationLoop(value)
    return type(value) == "table" and value[3] == true or false
end

return DataModel
