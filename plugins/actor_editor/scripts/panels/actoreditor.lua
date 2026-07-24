local DataModel, ActorPreview, ActorEditorDataPanel = ...
---@class ActorEditor : ActorEditorDataPanel
---@overload fun(editor: Editor, plugin: ActorEditorPlugin): ActorEditor
---@field DataModel any
---@field actor_list EditorItemList
---@field add_animation_button EditorButton
---@field animation_delay EditorTextInput
---@field animation_list EditorItemList
---@field animation_loop EditorCheckbox
---@field animation_sprite EditorTextInput
---@field blush_toggle EditorCheckbox
---@field clip boolean
---@field color_input EditorColorInput
---@field continuous_edit boolean
---@field direction string
---@field direction_button EditorButton
---@field editor Editor
---@field entries table
---@field entry_lookup table
---@field field_rows table
---@field flip_button EditorButton
---@field focusable boolean
---@field general_fields table
---@field hitbox_inputs table
---@field last_dirty_warning any
---@field miniface_path EditorPathInput
---@field miniface_select EditorButton
---@field miniface_x EditorTextInput
---@field miniface_y EditorTextInput
---@field mode string
---@field mode_buttons table
---@field mode_controls table
---@field model any
---@field models table
---@field offset_x EditorTextInput
---@field offset_y EditorTextInput
---@field plugin EditorPlugin
---@field portrait_path EditorPathInput
---@field portrait_select EditorButton
---@field portrait_target string
---@field portrait_x EditorTextInput
---@field portrait_y EditorTextInput
---@field preview ActorPreview
---@field reference_toggle EditorCheckbox
---@field refresh_button EditorButton
---@field save_button EditorButton
---@field saved_signatures table
---@field search EditorSearchBar
---@field selected_animation any
---@field selected_id any
---@field show_reference boolean
---@field soul_x EditorTextInput
---@field soul_y EditorTextInput
local ActorEditor, super = Class(ActorEditorDataPanel)

local MODES = {
    { id = "animation", label = "Animations" },
    { id = "hitbox", label = "Hitbox" },
    { id = "portraits", label = "Portraits" },
    { id = "soul", label = "Soul" },
    { id = "general", label = "General" }
}

local number = MathUtils.parseNumber
local sortedKeys = TableUtils.getCaseInsensitiveSortedKeys
local labelFor = StringUtils.humanizeIdentifier

function ActorEditor:init(editor, plugin)
    super.init(self, editor, plugin)
    self.panel_definition_key = "actor_panel_definition"
    self.panel_title = "Actor Editor"
    self.entity_name = "actor"
    self.diagnostic_id = "actor_editor"
    self.entry_list_field = "actor_list"
    self.entry_scanner = "scanActors"
    self.model_factory = "createActorModel"
    self.field_getter = "getActorField"
    self.field_setter = "setActorField"
    self.DataModel = DataModel
    self.selected_animation = nil
    self.direction = "down"
    self.mode = "animation"
    self.show_reference = true
    self.portrait_target = "portrait"

    self.search = self:addChild(EditorSearchBar({
        editor = editor,
        placeholder = "Search actors...",
        on_changed = function(value) self.actor_list:setFilter(value) end
    }))
    self.refresh_button = self:addChild(EditorButton("Refresh", function() self:refreshEntries(true) end))
    self.save_button = self:addChild(EditorButton("Save", function() self:saveSelected() end))
    self.actor_list = self:addChild(EditorItemList({
        row_height = 28,
        on_select = function(item) self:selectEntry(item and item.data) end,
        on_request_focus = function(control) self.editor.dockspace:setFocus(control) end
    }))

    self.mode_buttons = {}
    for _, definition in ipairs(MODES) do
        local mode = definition.id
        local button = self:addChild(EditorButton(definition.label, function() self:setMode(mode) end))
        self.mode_buttons[mode] = button
    end

    self.preview = self:addChild(ActorPreview(self))
    self.animation_list = self:addModeControl("animation", EditorItemList({
        row_height = 28,
        on_select = function(item) self:selectAnimation(item and item.id) end,
        on_rename = function(item, old_id, new_id) self:renameAnimation(old_id, new_id) end,
        on_context_menu = function(item, list, x, y) self:openAnimationMenu(item, list, x, y) end,
        on_request_focus = function(control) self.editor.dockspace:setFocus(control) end
    }))
    self.add_animation_button = self:addModeControl("animation",
        EditorButton("New Animation", function() self:addAnimation() end))
    self.direction_button = self:addModeControl("animation",
        EditorButton("Direction: down", function() self:openDirectionMenu() end))
    self.reference_toggle = self:addModeControl("animation",
        EditorCheckbox("Show Default Reference", true, function(value) self.show_reference = value end))

    self.animation_sprite = self:addField("animation", "Sprite", EditorTextInput({
        editor = editor,
        on_submit = function(value) return self:setAnimationComponent("sprite", value) end
    }))
    self.animation_delay = self:addField("animation", "Frame Delay", EditorTextInput({
        editor = editor,
        on_submit = function(value) return self:setAnimationComponent("delay", number(value)) end
    }), true)
    self.animation_loop = self:addField("animation", "Loop", EditorCheckbox("", false, function(value)
        self:setAnimationComponent("loop", value)
    end), true)
    self.offset_x = self:addField("animation", "Offset X", EditorTextInput({
        editor = editor,
        on_submit = function(value) return self:setAnimationOffset(number(value, 0), nil) end
    }), true)
    self.offset_y = self:addField("animation", "Offset Y", EditorTextInput({
        editor = editor,
        on_submit = function(value) return self:setAnimationOffset(nil, number(value, 0)) end
    }), true)

    self.hitbox_inputs = {}
    for index, field in ipairs({ "X", "Y", "Width", "Height" }) do
        local component = index
        self.hitbox_inputs[index] = self:addField("hitbox", field, EditorTextInput({
            editor = editor,
            on_submit = function(value) return self:setHitboxComponent(component, number(value, 0)) end
        }), true)
    end

    self.portrait_path = self:addField("portraits", "Portrait", EditorPathInput(editor, "", {
        path_kind = "asset", asset_categories = { "sprites" }, strip_extension = true,
        on_submit = function(value) return self:setActorField("portrait_path", value ~= "" and value or nil) end
    }))
    self.portrait_x = self:addField("portraits", "Portrait X", EditorTextInput({
        editor = editor,
        on_submit = function(value) return self:setVectorField("portrait_offset", 1, number(value, 0)) end
    }), true)
    self.portrait_y = self:addField("portraits", "Portrait Y", EditorTextInput({
        editor = editor,
        on_submit = function(value) return self:setVectorField("portrait_offset", 2, number(value, 0)) end
    }), true)
    self.miniface_path = self:addField("portraits", "Miniface", EditorPathInput(editor, "", {
        path_kind = "asset", asset_categories = { "sprites" }, strip_extension = true,
        on_submit = function(value) return self:setActorField("miniface", value ~= "" and value or nil) end
    }))
    self.miniface_x = self:addField("portraits", "Miniface X", EditorTextInput({
        editor = editor,
        on_submit = function(value) return self:setVectorField("miniface_offset", 1, number(value, 0)) end
    }), true)
    self.miniface_y = self:addField("portraits", "Miniface Y", EditorTextInput({
        editor = editor,
        on_submit = function(value) return self:setVectorField("miniface_offset", 2, number(value, 0)) end
    }), true)
    self.portrait_select = self:addModeControl("portraits",
        EditorButton("Edit Portrait Offset", function() self:setPortraitTarget("portrait") end))
    self.miniface_select = self:addModeControl("portraits",
        EditorButton("Edit Miniface Offset", function() self:setPortraitTarget("miniface") end))

    self.soul_x = self:addField("soul", "Soul X", EditorTextInput({
        editor = editor,
        on_submit = function(value) return self:setVectorField("soul_offset", 1, number(value, 0)) end
    }), true)
    self.soul_y = self:addField("soul", "Soul Y", EditorTextInput({
        editor = editor,
        on_submit = function(value) return self:setVectorField("soul_offset", 2, number(value, 0)) end
    }), true)

    self.general_fields = {}
    local general = {
        { "name", "Display Name" },
        { "width", "Width", "number" },
        { "height", "Height", "number" },
        { "path", "Sprite Path" },
        { "default", "Default" },
        { "default_sprite", "Default Sprite", "optional" },
        { "default_anim", "Default Animation", "optional" },
        { "voice", "Voice", "optional" },
        { "font", "Font", "optional" },
        { "speech_bubble_font_size", "Speech Font Size", "optional_number" },
        { "indent_string", "Indent String", "optional" }
    }
    for _, definition in ipairs(general) do
        local key, label, kind = unpack(definition)
        local input = EditorTextInput({
            editor = editor,
            on_submit = function(value)
                if kind == "number" then
                    local parsed = number(value)
                    return parsed ~= nil and self:setActorField(key, parsed)
                elseif kind == "optional_number" then
                    local parsed = value == "" and nil or number(value)
                    if value == "" then return self:setActorField(key, nil) end
                    return parsed ~= nil and self:setActorField(key, parsed)
                elseif kind == "optional" then
                    return self:setActorField(key, value ~= "" and value or nil)
                end
                return self:setActorField(key, value)
            end
        })
        self.general_fields[key] = self:addField("general", label, input,
            key == "width" or key == "height" or key == "speech_bubble_font_size")
    end
    self.color_input = self:addField("general", "Outline Color", EditorColorInput(editor, "#FF0000", {
        on_submit = function(value)
            return self:setActorField("color", ColorUtils.tryHexToRGB(value))
        end
    }))
    self.flip_button = self:addField("general", "Flip Direction",
        EditorButton("None", function() self:openFlipMenu() end))
    self.blush_toggle = self:addField("general", "Can Blush",
        EditorCheckbox("", false, function(value) self:setActorField("can_blush", value) end), true)

    self:refreshEntries(false)
    self:setMode("animation")
end

function ActorEditor:captureHistoryState()
    return {
        models = DataModel.copy(self.models),
        selected_id = self.selected_id,
        selected_animation = self.selected_animation,
        direction = self.direction,
        mode = self.mode,
        portrait_target = self.portrait_target
    }
end

function ActorEditor:restoreHistoryState(state)
    self.models = DataModel.copy(state.models)
    self.selected_id = state.selected_id
    self.model = self.selected_id and self.models[self.selected_id] or nil
    self.selected_animation = state.selected_animation
    self.direction = state.direction or "down"
    self.portrait_target = state.portrait_target or "portrait"
    self:setMode(state.mode or "animation")
    self:refreshEntryList()
    self:refreshModelControls()
    self:updateDirtyPresentation()
end

function ActorEditor:onModelSelected(model)
    local animations = sortedKeys(model.animations)
    if not self.selected_animation or not model.animations[self.selected_animation] then
        self.selected_animation = animations[1]
    end
end

function ActorEditor:getActorField(key)
    return self.model and DataModel.getField(self.model, key)
end

function ActorEditor:setActorField(key, value, live)
    if not self.model then return false end
    local apply = function() DataModel.setField(self.model, key, value) end
    if live or self.continuous_edit then apply() else self:performEdit("Edit " .. labelFor(key), apply) end
    self:updateDirtyPresentation()
    if not live then self:refreshModelControls() end
    return true
end

function ActorEditor:setHitboxComponent(index, value)
    local width = number(self:getActorField("width"), 0)
    local height = number(self:getActorField("height"), 0)
    local hitbox = DataModel.copy(self:getActorField("hitbox") or { 0, 0, width, height })
    hitbox[index] = value
    return self:setActorField("hitbox", hitbox)
end

function ActorEditor:setAnimationComponent(component, value)
    if not self.model or not self.selected_animation then return false end
    local current = self.model.animations[self.selected_animation]
    if not DataModel.animationIsEditable(current) then return false end
    local old_key = self:getAnimationOffsetKey(self.selected_animation)
    local sprite = component == "sprite" and value or DataModel.getAnimationSprite(current) or ""
    local delay = component == "delay" and value or DataModel.getAnimationDelay(current)
    if component == "loop" and delay == nil then delay = 0.25 end
    local loop = component == "loop" and value or DataModel.getAnimationLoop(current)
    if component == "delay" and value == nil then return false end
    local animation = delay and { sprite, delay, loop == true } or sprite
    self:performEdit("Edit Animation", function()
        DataModel.setAnimation(self.model, self.selected_animation, animation)
        if component == "sprite" then
            local new_key = self:getAnimationOffsetKey(self.selected_animation)
            if old_key ~= new_key and self.model.offsets[old_key] then
                DataModel.setOffset(self.model, new_key, self.model.offsets[old_key])
                DataModel.removeOffset(self.model, old_key)
            end
        end
    end)
    self:updateDirtyPresentation()
    self:refreshAnimationControls()
    return true
end

function ActorEditor:setAnimationOffset(x, y, live)
    if not self.model or not self.selected_animation then return false end
    local key = self:getAnimationOffsetKey(self.selected_animation)
    local animation = self.model.animations[self.selected_animation]
    local base_key = DataModel.getAnimationSprite(animation) or self.selected_animation
    local current = self.model.offsets[key] or self.model.offsets[base_key] or { 0, 0 }
    local offset = { x ~= nil and x or number(current[1], 0), y ~= nil and y or number(current[2], 0) }
    local apply = function() DataModel.setOffset(self.model, key, offset) end
    if live or self.continuous_edit then apply() else self:performEdit("Edit Animation Offset", apply) end
    self:updateDirtyPresentation()
    if not live then self:refreshAnimationControls() end
    return true
end

function ActorEditor:getAnimationOffsetKey(animation_id)
    local animation = self.model and self.model.animations[animation_id]
    local sprite = DataModel.getAnimationSprite(animation) or animation_id
    if not sprite then return animation_id end
    local path = tostring(self:getActorField("path") or ""):gsub("/+$", "")
    local base = path == "" and sprite or (path .. "/" .. sprite)
    if not Assets.getTexture(base) and not Assets.getFrames(base) then
        if Assets.getTexture(base .. "/" .. self.direction) or Assets.getFrames(base .. "/" .. self.direction) then
            return sprite .. "/" .. self.direction
        elseif Assets.getTexture(base .. "_" .. self.direction) or Assets.getFrames(base .. "_" .. self.direction) then
            return sprite .. "_" .. self.direction
        end
    end
    return sprite
end

function ActorEditor:addAnimation()
    if not self.model then return false end
    local id, index = "new_animation", 2
    while self.model.animations[id] do id, index = "new_animation_" .. index, index + 1 end
    self:performEdit("Add Animation", function()
        DataModel.setAnimation(self.model, id, { id, 0.25, true })
        DataModel.setOffset(self.model, id, { 0, 0 })
    end)
    self.selected_animation = id
    self:updateDirtyPresentation()
    self:refreshAnimationList()
    self:refreshAnimationControls()
    return true
end

function ActorEditor:removeAnimation(id)
    id = id or self.selected_animation
    if not self.model or not id then return false end
    local offset_key = self:getAnimationOffsetKey(id)
    self:performEdit("Remove Animation", function()
        DataModel.removeAnimation(self.model, id)
        DataModel.removeOffset(self.model, offset_key)
    end)
    self.selected_animation = sortedKeys(self.model.animations)[1]
    self:updateDirtyPresentation()
    self:refreshAnimationList()
    self:refreshAnimationControls()
    return true
end

function ActorEditor:renameAnimation(old_id, new_id)
    if not self.model then return false end
    local renamed = false
    self:performEdit("Rename Animation", function()
        renamed = DataModel.renameAnimation(self.model, old_id, new_id)
    end)
    if not renamed then
        self:refreshAnimationList()
        return false
    end
    self.selected_animation = new_id
    self:updateDirtyPresentation()
    self:refreshAnimationList()
    self:refreshAnimationControls()
    return true
end

function ActorEditor:openAnimationMenu(item, list, x, y)
    local items = { { label = "New Animation", action = function() self:addAnimation() end } }
    if item then
        table.insert(items, { label = "Rename", action = function() list:beginRename(item) end })
        table.insert(items, { label = "Delete", action = function() self:removeAnimation(item.id) end })
    end
    local global_x, global_y = list:getGlobalPosition()
    self.editor.dockspace:openContextMenu(items, global_x + x, global_y + y, list)
end

function ActorEditor:selectAnimation(id)
    self.selected_animation = id
    self:refreshAnimationControls()
end

function ActorEditor:openDirectionMenu()
    local directions = self.preview:getDirections()
    if #directions == 0 then directions = { "down", "left", "right", "up" } end
    local items = {}
    for _, value in ipairs(directions) do
        local direction = value
        table.insert(items, {
            label = labelFor(direction),
            checked = direction == self.direction,
            action = function()
                self.direction = direction
                self.direction_button.label = "Direction: " .. direction
                self:refreshAnimationControls()
            end
        })
    end
    local x, y = self.direction_button:getGlobalPosition()
    self.editor.dockspace:openContextMenu(items, x, y + self.direction_button.height,
        self.direction_button)
end

function ActorEditor:openFlipMenu()
    local items = {}
    for _, value in ipairs({ false, "left", "right" }) do
        local actual = value or nil
        table.insert(items, {
            label = actual and labelFor(actual) or "None",
            checked = self:getActorField("flip") == actual,
            action = function() self:setActorField("flip", actual) end
        })
    end
    local x, y = self.flip_button:getGlobalPosition()
    self.editor.dockspace:openContextMenu(items, x, y + self.flip_button.height, self.flip_button)
end

function ActorEditor:setPortraitTarget(target)
    self.portrait_target = target
    self.portrait_select.label = target == "portrait" and "Editing Portrait" or "Edit Portrait Offset"
    self.miniface_select.label = target == "miniface" and "Editing Miniface" or "Edit Miniface Offset"
end

---@param mode string
function ActorEditor:onModeChanged(mode)
    self.preview.visible = mode ~= "general"
end

function ActorEditor:refreshAnimationList()
    local items = {}
    for _, id in ipairs(sortedKeys(self.model and self.model.animations or {})) do
        table.insert(items, {
            id = id,
            label = id .. (self.model.animation_editable[id] and "" or "  (custom)")
        })
    end
    self.animation_list:setItems(items)
    if self.selected_animation then
        for index, item in ipairs(self.animation_list.filtered_items) do
            if item.id == self.selected_animation then self.animation_list:select(index) break end
        end
    end
end

function ActorEditor:refreshAnimationControls()
    local animation = self.model and self.selected_animation
        and self.model.animations[self.selected_animation]
    local editable = animation and DataModel.animationIsEditable(animation) or false
    self.animation_sprite.enabled = editable
    self.animation_delay.enabled = editable
    self.animation_loop.enabled = editable
    self.offset_x.enabled = animation ~= nil
    self.offset_y.enabled = animation ~= nil
    self.animation_sprite:setValue(DataModel.getAnimationSprite(animation) or "", true)
    self.animation_delay:setValue(DataModel.getAnimationDelay(animation) or "", true)
    self.animation_loop:setValue(DataModel.getAnimationLoop(animation), true)
    local offset_key = self.model and self.selected_animation
        and self:getAnimationOffsetKey(self.selected_animation)
    local animation = self.model and self.selected_animation
        and self.model.animations[self.selected_animation]
    local base_key = DataModel.getAnimationSprite(animation) or self.selected_animation
    local offset = self.model and (self.model.offsets[offset_key] or self.model.offsets[base_key]) or { 0, 0 }
    self.offset_x:setValue(offset and offset[1] or 0, true)
    self.offset_y:setValue(offset and offset[2] or 0, true)
    self.direction_button.label = "Direction: " .. self.direction
end

function ActorEditor:refreshModelControls()
    self.save_button.enabled = self.model ~= nil and self.model.dirty
    self:refreshAnimationList()
    self:refreshAnimationControls()
    if not self.model then return end
    local hitbox = self:getActorField("hitbox")
        or { 0, 0, self:getActorField("width") or 0, self:getActorField("height") or 0 }
    for index, input in ipairs(self.hitbox_inputs) do input:setValue(hitbox[index] or 0, true) end
    self.portrait_path:setValue(self:getActorField("portrait_path") or "", true)
    local portrait = self:getActorField("portrait_offset") or { 0, 0 }
    self.portrait_x:setValue(portrait[1] or 0, true)
    self.portrait_y:setValue(portrait[2] or 0, true)
    self.miniface_path:setValue(self:getActorField("miniface") or "", true)
    local miniface = self:getActorField("miniface_offset") or { 0, 0 }
    self.miniface_x:setValue(miniface[1] or 0, true)
    self.miniface_y:setValue(miniface[2] or 0, true)
    local soul = self:getActorField("soul_offset") or { 0, 0 }
    self.soul_x:setValue(soul[1] or 0, true)
    self.soul_y:setValue(soul[2] or 0, true)
    for key, input in pairs(self.general_fields) do input:setValue(self:getActorField(key) or "", true) end
    self.color_input:setValue(self:getActorField("color") or { 1, 0, 0, 1 }, true)
    local flip = self:getActorField("flip")
    self.flip_button.label = flip and labelFor(flip) or "None"
    self.blush_toggle:setValue(self:getActorField("can_blush") == true, true)
    self:setPortraitTarget(self.portrait_target)
end

function ActorEditor:update(dt)
    local padding, header, list_width = 8, 34, 184
    self.search:setBounds(padding, padding, list_width - 74, 28)
    self.refresh_button:setBounds(padding + list_width - 68, padding, 68, 28)
    self.actor_list:setBounds(padding, padding + header, list_width, math.max(0, self.height - header - padding * 2))
    self.save_button:setBounds(math.max(padding, self.width - 76), padding, 68, 28)
    local mode_x = padding + list_width + 10
    local available = math.max(0, self.width - mode_x - 84)
    local mode_width = math.max(70, math.floor(available / #MODES))
    for index, definition in ipairs(MODES) do
        self.mode_buttons[definition.id]:setBounds(mode_x + (index - 1) * mode_width,
            padding, mode_width - 4, 28)
    end

    local content_x, content_y = mode_x, padding + header
    local content_width, content_height = math.max(0, self.width - content_x - padding),
        math.max(0, self.height - content_y - padding)
    local form_width = self.mode == "general" and content_width
        or math.max(220, math.min(310, math.floor(content_width * 0.32)))
    local animation_width = self.mode == "animation" and math.max(130, math.min(190,
        math.floor(content_width * 0.20))) or 0
    local preview_x = content_x + animation_width + (animation_width > 0 and 8 or 0)
    local preview_width = math.max(160, content_width - animation_width - form_width
        - (animation_width > 0 and 16 or 8))
    self.preview:setBounds(preview_x, content_y, preview_width, content_height)
    self.animation_list:setBounds(content_x, content_y, animation_width,
        math.max(60, content_height - 74))
    self.add_animation_button:setBounds(content_x, content_y + content_height - 66,
        animation_width, 28)
    self.direction_button:setBounds(content_x, content_y + content_height - 34,
        animation_width, 28)

    local form_x = self.mode == "general" and content_x or content_x + content_width - form_width
    local rows = {}
    for _, row in ipairs(self.field_rows) do if row.mode == self.mode then table.insert(rows, row) end end
    if self.mode == "general" then
        local gap = 12
        local column_width = math.max(120, math.floor((form_width - gap) / 2))
        for index, row in ipairs(rows) do
            local column = (index - 1) % 2
            local line = math.floor((index - 1) / 2)
            row.draw_x = form_x + column * (column_width + gap)
            row.draw_y = content_y + line * 54
            row.draw_width = column_width
            row.control:setBounds(row.draw_x, row.draw_y + 20, column_width,
                row.control.preferred_height or 28)
        end
        super.update(self, dt)
        return
    end
    local y = content_y
    local compact_pending
    for _, row in ipairs(rows) do
        if row.compact and compact_pending then
            local half = math.floor((form_width - 8) / 2)
            compact_pending.control:setBounds(form_x, compact_pending.y + 20, half, 28)
            row.control:setBounds(form_x + half + 8, compact_pending.y + 20, half, 28)
            compact_pending.paired = true
            row.draw_x, row.draw_y, row.draw_width = form_x + half + 8, compact_pending.y, half
            y = compact_pending.y + 54
            compact_pending = nil
        elseif row.compact then
            compact_pending = row
            row.y = y
            row.draw_x, row.draw_y, row.draw_width = form_x, y, math.floor((form_width - 8) / 2)
        else
            if compact_pending then
                compact_pending.control:setBounds(form_x, compact_pending.y + 20, form_width, 28)
                y = compact_pending.y + 54
                compact_pending = nil
            end
            row.draw_x, row.draw_y, row.draw_width = form_x, y, form_width
            row.control:setBounds(form_x, y + 20, form_width, row.control.preferred_height or 28)
            y = y + (row.control.preferred_height or 28) + 26
        end
    end
    if compact_pending then
        compact_pending.control:setBounds(form_x, compact_pending.y + 20, form_width, 28)
        compact_pending = nil
    end
    self.reference_toggle:setBounds(form_x, math.max(content_y, content_y + content_height - 28),
        form_width, 28)
    self.portrait_select:setBounds(form_x, math.max(content_y, content_y + content_height - 64),
        math.floor((form_width - 6) / 2), 28)
    self.miniface_select:setBounds(form_x + math.floor((form_width - 6) / 2) + 6,
        math.max(content_y, content_y + content_height - 64), math.floor((form_width - 6) / 2), 28)
    super.update(self, dt)
end

function ActorEditor:drawSelf()
    love.graphics.push("all")
    Draw.setColor(0.075, 0.075, 0.085, 1)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    local font = EditorFont.get(14)
    love.graphics.setFont(font)
    for _, row in ipairs(self.field_rows) do
        if row.mode == self.mode and row.control.visible and row.draw_x then
            Draw.setColor(0.68, 0.68, 0.72, 1)
            love.graphics.print(row.label, row.draw_x, row.draw_y)
        end
    end
    if self.model then
        Draw.setColor(0.80, 0.84, 0.92, 1)
        love.graphics.print(self.model.id, 8, self.height - font:getHeight() - 8)
    end
    love.graphics.pop()
end

return ActorEditor
