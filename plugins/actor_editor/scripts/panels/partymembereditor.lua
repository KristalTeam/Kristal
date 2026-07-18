local DataModel, ActorEditorDataPanel = ...
---@class PartyMemberEditor : ActorEditorDataPanel
---@overload fun(editor: Editor, plugin: ActorEditorPlugin): PartyMemberEditor
---@field actor_buttons table
---@field actor_open_buttons table
---@field add_chapter_button EditorButton
---@field base_fields table
---@field chapter_fields table
---@field chapter_list EditorItemList
---@field clip boolean
---@field editor Editor
---@field entries table
---@field entry_lookup table
---@field field_rows table
---@field focusable boolean
---@field has_act EditorCheckbox
---@field has_spells EditorCheckbox
---@field has_xact EditorCheckbox
---@field last_dirty_warning any
---@field member_list EditorItemList
---@field mode string
---@field mode_buttons table
---@field mode_controls table
---@field model any
---@field models table
---@field plugin EditorPlugin
---@field refresh_button EditorButton
---@field save_button EditorButton
---@field saved_signatures table
---@field search EditorSearchBar
---@field selected_chapter any
---@field selected_id any
---@field soul_color EditorColorInput
---@field visual_colors table
---@field visual_fields table
local PartyMemberEditor, super = Class(ActorEditorDataPanel)

local MODES = {
    { id = "base", label = "Base Stats" },
    { id = "chapters", label = "Chapters" },
    { id = "visuals", label = "Visuals" }
}

local number = MathUtils.parseNumber
local sortedKeys = TableUtils.getSortedKeys
local labelFor = StringUtils.humanizeIdentifier
local fitText = StringUtils.truncateToWidth

function PartyMemberEditor:init(editor, plugin)
    super.init(self, editor, plugin)
    self.panel_definition_key = "party_panel_definition"
    self.panel_title = "Party Member Editor"
    self.entity_name = "party member"
    self.diagnostic_id = "party_editor"
    self.entry_list_field = "member_list"
    self.entry_scanner = "scanPartyMembers"
    self.model_factory = "createPartyModel"
    self.field_getter = "getPartyField"
    self.field_setter = "setPartyField"
    self.selected_chapter = nil
    self.mode = "base"

    self.search = self:addChild(EditorSearchBar({
        editor = editor,
        placeholder = "Search party members...",
        on_changed = function(value) self.member_list:setFilter(value) end
    }))
    self.refresh_button = self:addChild(EditorButton("Refresh", function() self:refreshEntries(true) end))
    self.save_button = self:addChild(EditorButton("Save", function() self:saveSelected() end))
    self.member_list = self:addChild(EditorItemList({
        row_height = 28,
        on_select = function(item) self:selectEntry(item and item.data) end,
        on_request_focus = function(control) self.editor.dockspace:setFocus(control) end
    }))

    self.mode_buttons = {}
    for _, definition in ipairs(MODES) do
        local mode = definition.id
        self.mode_buttons[mode] = self:addChild(EditorButton(definition.label,
            function() self:setMode(mode) end))
    end

    self.actor_buttons = {}
    self.actor_open_buttons = {}
    local actor_links = {
        { key = "actor", label = "Dark Actor" },
        { key = "light_actor", label = "Light Actor" },
        { key = "dark_transition_actor", label = "Transition Actor" }
    }
    for _, definition in ipairs(actor_links) do
        local key = definition.key
        self.actor_buttons[key] = self:addChild(EditorButton("None", function()
            self:openActorChoice(key, definition.label)
        end))
        self.actor_open_buttons[key] = self:addChild(EditorButton("Open", function()
            local id = self.model and self.model[key]
            if id then self.plugin:openActor(id) end
        end))
    end

    self.chapter_list = self:addModeControl("chapters", EditorItemList({
        row_height = 28,
        on_select = function(item) self:selectChapter(item and item.id) end,
        on_rename = function(item, old_value, new_value) self:renameChapter(old_value, new_value) end,
        on_context_menu = function(item, list, x, y) self:openChapterMenu(item, list, x, y) end,
        on_request_focus = function(control) self.editor.dockspace:setFocus(control) end
    }))
    self.add_chapter_button = self:addModeControl("chapters",
        EditorButton("New Chapter", function() self:addChapter() end))

    self.base_fields = {}
    local base = {
        { "name", "Display Name" },
        { "title", "Title / Class" },
        { "level", "Level", "number" },
        { "health", "Health", "number" },
        { "attack", "Attack", "stat" },
        { "defense", "Defense", "stat" },
        { "magic", "Magic", "stat" },
        { "lw_lv", "Light LV", "number" },
        { "lw_exp", "Light EXP", "number" },
        { "lw_health", "Light Health", "number" },
        { "lw_attack", "Light Attack", "lw_stat", "attack" },
        { "lw_defense", "Light Defense", "lw_stat", "defense" },
        { "soul_priority", "Soul Priority", "number" },
        { "xact_name", "X-Action Name" }
    }
    for _, definition in ipairs(base) do
        local id, label, kind, stat_key = unpack(definition)
        self.base_fields[id] = self:addField("base", label, EditorTextInput({
            editor = editor,
            on_submit = function(value)
                if kind == "stat" then return self:setStat("stats", id, number(value, 0)) end
                if kind == "lw_stat" then return self:setStat("lw_stats", stat_key, number(value, 0)) end
                if kind == "number" then
                    local parsed = number(value)
                    return parsed ~= nil and self:setPartyField(id, parsed)
                end
                return self:setPartyField(id, value)
            end
        }), kind == "number" or kind == "stat" or kind == "lw_stat")
    end
    self.soul_color = self:addField("base", "Soul Color", EditorColorInput(editor, "#FF0000", {
        on_submit = function(value) return self:setPartyField("soul_color", ColorUtils.tryHexToRGB(value)) end
    }))
    self.has_act = self:addField("base", "Can ACT", EditorCheckbox("", true,
        function(value) self:setPartyField("has_act", value) end), true)
    self.has_spells = self:addField("base", "Can Use Spells", EditorCheckbox("", false,
        function(value) self:setPartyField("has_spells", value) end), true)
    self.has_xact = self:addField("base", "Has X-Action", EditorCheckbox("", true,
        function(value) self:setPartyField("has_xact", value) end), true)

    self.chapter_fields = {}
    local chapter = {
        { "title", "Title / Class" },
        { "level", "Level", "number" },
        { "health", "Health", "number" },
        { "attack", "Attack", "stat" },
        { "defense", "Defense", "stat" },
        { "magic", "Magic", "stat" },
        { "lw_lv", "Light LV", "number" },
        { "lw_exp", "Light EXP", "number" },
        { "lw_health", "Light Health", "number" },
        { "lw_attack", "Light Attack", "lw_stat", "attack" },
        { "lw_defense", "Light Defense", "lw_stat", "defense" }
    }
    for _, definition in ipairs(chapter) do
        local id, label, kind, stat_key = unpack(definition)
        self.chapter_fields[id] = self:addField("chapters", label, EditorTextInput({
            editor = editor,
            on_submit = function(value)
                if not self.selected_chapter then return false end
                if kind == "stat" then
                    return self:setChapterStat("stats", id, number(value, 0))
                elseif kind == "lw_stat" then
                    return self:setChapterStat("lw_stats", stat_key, number(value, 0))
                elseif kind == "number" then
                    local parsed = number(value)
                    return parsed ~= nil and self:setChapterField(id, parsed)
                end
                return self:setChapterField(id, value)
            end
        }), kind ~= nil)
    end

    self.visual_fields = {}
    local visuals = {
        { "weapon_icon", "Weapon Icon", "path" },
        { "lw_weapon_default", "Light Weapon", "optional" },
        { "lw_armor_default", "Light Armor", "optional" },
        { "menu_icon", "Menu Icon", "path" },
        { "head_icons", "Head Icons", "path" },
        { "name_sprite", "Name Sprite", "optional_path" },
        { "attack_sprite", "Attack Effect", "path" },
        { "attack_sound", "Attack Sound" },
        { "attack_pitch", "Attack Pitch", "number" },
        { "battle_x", "Battle X", "vector", "battle_offset", 1 },
        { "battle_y", "Battle Y", "vector", "battle_offset", 2 },
        { "head_x", "Head Icon X", "vector", "head_icon_offset", 1 },
        { "head_y", "Head Icon Y", "vector", "head_icon_offset", 2 },
        { "menu_x", "Menu Icon X", "vector", "menu_icon_offset", 1 },
        { "menu_y", "Menu Icon Y", "vector", "menu_icon_offset", 2 }
    }
    for _, definition in ipairs(visuals) do
        local id, label, kind, vector_key, vector_index = unpack(definition)
        local control
        if kind == "path" or kind == "optional_path" then
            control = EditorPathInput(editor, "", {
                path_kind = "asset", asset_categories = { "sprites" }, strip_extension = true,
                on_submit = function(value)
                    if kind == "optional_path" and value == "" then
                        return self:setPartyField(id, nil)
                    end
                    return self:setPartyField(id, value)
                end
            })
        else
            control = EditorTextInput({
                editor = editor,
                on_submit = function(value)
                    if kind == "number" then
                        local parsed = number(value)
                        return parsed ~= nil and self:setPartyField(id, parsed)
                    elseif kind == "vector" then
                        return self:setVectorField(vector_key, vector_index, number(value, 0))
                    elseif kind == "optional" then
                        return self:setPartyField(id, value ~= "" and value or nil)
                    end
                    return self:setPartyField(id, value)
                end
            })
        end
        self.visual_fields[id] = self:addField("visuals", label, control,
            kind == "number" or kind == "vector")
    end
    self.visual_colors = {}
    for _, definition in ipairs({
        { "color", "Character Color", "#FFFFFF" },
        { "dmg_color", "Damage Color", "#FFFFFF" },
        { "attack_bar_color", "Attack Bar", "#FFFFFF" },
        { "attack_box_color", "Attack Box", "#FFFFFF" },
        { "xact_color", "X-Action Color", "#FFFFFF" }
    }) do
        local key, label, fallback = unpack(definition)
        self.visual_colors[key] = self:addField("visuals", label, EditorColorInput(editor, fallback, {
            on_submit = function(value) return self:setPartyField(key, ColorUtils.tryHexToRGB(value)) end
        }))
    end

    self:refreshEntries(false)
    self:setMode("base")
end

function PartyMemberEditor:captureHistoryState()
    return {
        models = DataModel.copy(self.models),
        selected_id = self.selected_id,
        selected_chapter = self.selected_chapter,
        mode = self.mode
    }
end

function PartyMemberEditor:restoreHistoryState(state)
    self.models = DataModel.copy(state.models)
    self.selected_id = state.selected_id
    self.model = self.selected_id and self.models[self.selected_id] or nil
    self.selected_chapter = state.selected_chapter
    self:setMode(state.mode or "base")
    self:refreshEntryList()
    self:refreshModelControls()
    self:updateDirtyPresentation()
end

function PartyMemberEditor:onModelSelected(model)
    if self.selected_chapter and not model.chapters[self.selected_chapter] then
        self.selected_chapter = nil
    end
    self.selected_chapter = self.selected_chapter or sortedKeys(model.chapters)[1]
end

function PartyMemberEditor:getPartyField(key)
    return self.model and DataModel.getField(self.model, key)
end

function PartyMemberEditor:setPartyField(key, value)
    if not self.model then return false end
    self:performEdit("Edit " .. labelFor(key), function() DataModel.setField(self.model, key, value) end)
    self:updateDirtyPresentation()
    self:refreshModelControls()
    return true
end

function PartyMemberEditor:setStat(table_key, stat, value)
    local stats = DataModel.copy(self:getPartyField(table_key) or {})
    stats[stat] = value
    return self:setPartyField(table_key, stats)
end

function PartyMemberEditor:setActorLink(key, id)
    if not self.model then return false end
    self:performEdit("Change " .. labelFor(key), function()
        self.model[key] = id ~= "" and id or nil
        self.model.dirty = true
    end)
    self:updateDirtyPresentation()
    self:refreshActorLinks()
    return true
end

function PartyMemberEditor:openActorChoice(key, label)
    local items = {
        { label = "None", checked = self.model and self.model[key] == nil,
            action = function() self:setActorLink(key, nil) end }
    }
    for _, id in ipairs(sortedKeys(Registry.actors or {})) do
        local actor_id = id
        table.insert(items, {
            label = actor_id,
            checked = self.model and self.model[key] == actor_id,
            action = function() self:setActorLink(key, actor_id) end
        })
    end
    local button = self.actor_buttons[key]
    local x, y = button:getGlobalPosition()
    self.editor.dockspace:openContextMenu(items, x, y + button.height, button, {
        searchable = true,
        maximum_rows = 14,
        width = 300,
        placeholder = "Search " .. label:lower() .. "s..."
    })
end

function PartyMemberEditor:addChapter()
    if not self.model then return false end
    local chapter = 1
    while self.model.chapters[chapter] do chapter = chapter + 1 end
    self:performEdit("Add Chapter Stats", function()
        self.model.chapters[chapter] = {}
        for _, key in ipairs(DataModel.getChapterFields()) do
            self.model.chapters[chapter][key] = DataModel.copy(self:getPartyField(key))
        end
        self.model.dirty = true
    end)
    self.selected_chapter = chapter
    self:updateDirtyPresentation()
    self:refreshChapterList()
    self:refreshChapterControls()
    return true
end

function PartyMemberEditor:removeChapter(chapter)
    chapter = chapter or self.selected_chapter
    if not self.model or not chapter then return false end
    self:performEdit("Remove Chapter Stats", function() DataModel.clearChapter(self.model, chapter) end)
    self.selected_chapter = sortedKeys(self.model.chapters)[1]
    self:updateDirtyPresentation()
    self:refreshChapterList()
    self:refreshChapterControls()
    return true
end

function PartyMemberEditor:renameChapter(old_value, new_value)
    local chapter = math.floor(number(new_value, 0))
    if not self.model or chapter < 1 or self.model.chapters[chapter] then
        self:refreshChapterList()
        return false
    end
    self:performEdit("Rename Chapter Stats", function()
        self.model.chapters[chapter] = self.model.chapters[old_value]
        self.model.chapters[old_value] = nil
        self.model.dirty = true
    end)
    self.selected_chapter = chapter
    self:updateDirtyPresentation()
    self:refreshChapterList()
    self:refreshChapterControls()
    return true
end

function PartyMemberEditor:openChapterMenu(item, list, x, y)
    local items = { { label = "New Chapter", action = function() self:addChapter() end } }
    if item then
        table.insert(items, { label = "Change Number", action = function() list:beginRename(item) end })
        table.insert(items, { label = "Delete", action = function() self:removeChapter(item.id) end })
    end
    local global_x, global_y = list:getGlobalPosition()
    self.editor.dockspace:openContextMenu(items, global_x + x, global_y + y, list)
end

function PartyMemberEditor:selectChapter(chapter)
    self.selected_chapter = chapter
    self:refreshChapterControls()
end

function PartyMemberEditor:setChapterField(key, value)
    if not self.model or not self.selected_chapter then return false end
    self:performEdit("Edit Chapter " .. self.selected_chapter .. " " .. labelFor(key), function()
        DataModel.setChapterField(self.model, self.selected_chapter, key, value)
    end)
    self:updateDirtyPresentation()
    self:refreshChapterControls()
    return true
end

function PartyMemberEditor:setChapterStat(table_key, stat, value)
    local stats = DataModel.copy(DataModel.getChapterField(
        self.model, self.selected_chapter, table_key) or {})
    stats[stat] = value
    return self:setChapterField(table_key, stats)
end

function PartyMemberEditor:refreshActorLinks()
    for _, key in ipairs({ "actor", "light_actor", "dark_transition_actor" }) do
        local id = self.model and self.model[key]
        self.actor_buttons[key].full_label = id or "None"
        self.actor_buttons[key].label = self.actor_buttons[key].full_label
        self.actor_buttons[key].enabled = self.model ~= nil
        self.actor_open_buttons[key].enabled = id ~= nil
    end
end

function PartyMemberEditor:refreshChapterList()
    local items = {}
    for _, chapter in ipairs(sortedKeys(self.model and self.model.chapters or {})) do
        table.insert(items, { id = chapter, label = "Chapter " .. chapter })
    end
    self.chapter_list:setItems(items)
    if self.selected_chapter then
        for index, item in ipairs(self.chapter_list.filtered_items) do
            if item.id == self.selected_chapter then self.chapter_list:select(index) break end
        end
    end
end

function PartyMemberEditor:refreshBaseControls()
    if not self.model then return end
    local stats, lw_stats = self:getPartyField("stats") or {}, self:getPartyField("lw_stats") or {}
    local values = {
        name = self:getPartyField("name"), title = self:getPartyField("title"),
        level = self:getPartyField("level"), health = self:getPartyField("health"),
        attack = stats.attack, defense = stats.defense, magic = stats.magic,
        lw_lv = self:getPartyField("lw_lv"), lw_exp = self:getPartyField("lw_exp"),
        lw_health = self:getPartyField("lw_health"), lw_attack = lw_stats.attack,
        lw_defense = lw_stats.defense, soul_priority = self:getPartyField("soul_priority"),
        xact_name = self:getPartyField("xact_name")
    }
    for key, input in pairs(self.base_fields) do input:setValue(values[key] or "", true) end
    self.soul_color:setValue(self:getPartyField("soul_color") or { 1, 0, 0, 1 }, true)
    self.has_act:setValue(self:getPartyField("has_act") ~= false, true)
    self.has_spells:setValue(self:getPartyField("has_spells") == true, true)
    self.has_xact:setValue(self:getPartyField("has_xact") ~= false, true)
end

function PartyMemberEditor:refreshChapterControls()
    local enabled = self.model ~= nil and self.selected_chapter ~= nil
    for _, input in pairs(self.chapter_fields) do input.enabled = enabled end
    if not enabled then
        for _, input in pairs(self.chapter_fields) do input:setValue("", true) end
        return
    end
    local stats = DataModel.getChapterField(self.model, self.selected_chapter, "stats") or {}
    local lw_stats = DataModel.getChapterField(self.model, self.selected_chapter, "lw_stats") or {}
    local values = {
        title = DataModel.getChapterField(self.model, self.selected_chapter, "title"),
        level = DataModel.getChapterField(self.model, self.selected_chapter, "level"),
        health = DataModel.getChapterField(self.model, self.selected_chapter, "health"),
        attack = stats.attack, defense = stats.defense, magic = stats.magic,
        lw_lv = DataModel.getChapterField(self.model, self.selected_chapter, "lw_lv"),
        lw_exp = DataModel.getChapterField(self.model, self.selected_chapter, "lw_exp"),
        lw_health = DataModel.getChapterField(self.model, self.selected_chapter, "lw_health"),
        lw_attack = lw_stats.attack, lw_defense = lw_stats.defense
    }
    for key, input in pairs(self.chapter_fields) do input:setValue(values[key] or "", true) end
end

function PartyMemberEditor:refreshVisualControls()
    if not self.model then return end
    for key, input in pairs(self.visual_fields) do
        local value
        if key == "battle_x" or key == "battle_y" then
            local vector = self:getPartyField("battle_offset") or { 0, 0 }
            value = vector[key == "battle_x" and 1 or 2]
        elseif key == "head_x" or key == "head_y" then
            local vector = self:getPartyField("head_icon_offset") or { 0, 0 }
            value = vector[key == "head_x" and 1 or 2]
        elseif key == "menu_x" or key == "menu_y" then
            local vector = self:getPartyField("menu_icon_offset") or { 0, 0 }
            value = vector[key == "menu_x" and 1 or 2]
        else
            value = self:getPartyField(key)
        end
        input:setValue(value or "", true)
    end
    for key, input in pairs(self.visual_colors) do
        input:setValue(self:getPartyField(key) or self:getPartyField("color") or { 1, 1, 1, 1 }, true)
    end
end

function PartyMemberEditor:refreshModelControls()
    self.save_button.enabled = self.model ~= nil and self.model.dirty
    self:refreshActorLinks()
    self:refreshChapterList()
    self:refreshBaseControls()
    self:refreshChapterControls()
    self:refreshVisualControls()
end

function PartyMemberEditor:update(dt)
    local padding, header, list_width = 8, 34, 190
    local footer_height = 24
    self.search:setBounds(padding, padding, list_width - 74, 28)
    self.refresh_button:setBounds(padding + list_width - 68, padding, 68, 28)
    self.member_list:setBounds(padding, padding + header, list_width,
        math.max(0, self.height - header - padding * 2 - footer_height))
    self.save_button:setBounds(math.max(padding, self.width - 76), padding, 68, 28)

    local content_x = padding + list_width + 10
    local content_width = math.max(0, self.width - content_x - padding)
    local mode_width = math.max(90, math.floor((content_width - 84) / #MODES))
    for index, definition in ipairs(MODES) do
        self.mode_buttons[definition.id]:setBounds(content_x + (index - 1) * mode_width,
            padding, mode_width - 4, 28)
    end

    local links_y = padding + header
    local link_width = math.max(150, math.floor((content_width - 24) / 3))
    for index, key in ipairs({ "actor", "light_actor", "dark_transition_actor" }) do
        local x = content_x + (index - 1) * (link_width + 8)
        self.actor_buttons[key]:setBounds(x, links_y + 20, math.max(80, link_width - 54), 28)
        self.actor_open_buttons[key]:setBounds(x + math.max(80, link_width - 50),
            links_y + 20, 50, 28)
        self.actor_buttons[key]._label_x = x
        self.actor_buttons[key]._label_width = link_width
        self.actor_buttons[key].label = fitText(EditorFont.get(16),
            self.actor_buttons[key].full_label or self.actor_buttons[key].label,
            self.actor_buttons[key].width - 10)
    end

    local body_y = links_y + 58
    local body_height = math.max(0, self.height - body_y - padding)
    local chapter_width = self.mode == "chapters" and 150 or 0
    self.chapter_list:setBounds(content_x, body_y, chapter_width, math.max(60, body_height - 36))
    self.add_chapter_button:setBounds(content_x, body_y + body_height - 30, chapter_width, 28)

    local form_x = content_x + chapter_width + (chapter_width > 0 and 10 or 0)
    local form_width = math.max(0, content_width - chapter_width - (chapter_width > 0 and 10 or 0))
    local rows = {}
    for _, row in ipairs(self.field_rows) do if row.mode == self.mode then table.insert(rows, row) end end
    local columns = form_width >= 480 and 3 or 2
    local column_gap = 10
    local column_width = math.max(100,
        math.floor((form_width - column_gap * (columns - 1)) / columns))
    local row_height = 54
    for index, row in ipairs(rows) do
        local column = (index - 1) % columns
        local line = math.floor((index - 1) / columns)
        row.draw_x = form_x + column * (column_width + column_gap)
        row.draw_y = body_y + line * row_height
        row.draw_width = column_width
        row.control:setBounds(row.draw_x, row.draw_y + 20, column_width,
            row.control.preferred_height or 28)
    end
    super.update(self, dt)
end

function PartyMemberEditor:drawSelf()
    love.graphics.push("all")
    Draw.setColor(0.075, 0.075, 0.085, 1)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    local font = EditorFont.get(14)
    love.graphics.setFont(font)
    local link_labels = {
        actor = "Dark World Actor",
        light_actor = "Light World Actor",
        dark_transition_actor = "Dark Transition Actor"
    }
    for key, button in pairs(self.actor_buttons) do
        Draw.setColor(0.68, 0.68, 0.72, 1)
        love.graphics.print(fitText(font, link_labels[key], button._label_width or button.width),
            button._label_x or button.x, button.y - 18)
    end
    for _, row in ipairs(self.field_rows) do
        if row.mode == self.mode and row.control.visible and row.draw_x then
            Draw.setColor(0.68, 0.68, 0.72, 1)
            love.graphics.print(fitText(font, row.label, row.draw_width), row.draw_x, row.draw_y)
        end
    end
    if self.mode == "chapters" and not self.selected_chapter then
        Draw.setColor(0.52, 0.52, 0.56, 1)
        love.graphics.print("Create a chapter override to edit chapter-specific values.",
            self.chapter_list.x + self.chapter_list.width + 10, self.chapter_list.y)
    end
    if self.model then
        Draw.setColor(0.80, 0.84, 0.92, 1)
        love.graphics.print(self.model.id, 8, self.height - font:getHeight() - 8)
    end
    love.graphics.pop()
end

return PartyMemberEditor
