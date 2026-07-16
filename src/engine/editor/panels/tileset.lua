---@class EditorTilesetPanel : EditorControl
---@overload fun(editor: table): EditorTilesetPanel
local EditorTilesetPanel, super = Class(EditorControl)

local MODES = {
    { id = "tileset", name = "Tileset" }, { id = "tile", name = "Tile" },
    { id = "terrain", name = "Terrain" }, { id = "collision", name = "Collision" },
    { id = "animation", name = "Animation" }
}

local TERRAIN_SLOTS = {
    { id = "nw", x = -1, y = -1, u = 0.16, v = 0.16 },
    { id = "n",  x =  0, y = -1, u = 0.50, v = 0.12 },
    { id = "ne", x =  1, y = -1, u = 0.84, v = 0.16 },
    { id = "w",  x = -1, y =  0, u = 0.12, v = 0.50 },
    { id = "center", center = true, u = 0.50, v = 0.50 },
    { id = "e",  x =  1, y =  0, u = 0.88, v = 0.50 },
    { id = "sw", x = -1, y =  1, u = 0.16, v = 0.84 },
    { id = "s",  x =  0, y =  1, u = 0.50, v = 0.88 },
    { id = "se", x =  1, y =  1, u = 0.84, v = 0.84 }
}

local function formatTags(tags)
    return table.concat(tags or {}, ", ")
end

local function parseTags(document, value)
    local result, seen = {}, {}
    for tag in tostring(value or ""):gmatch("[^,%s]+") do
        if document:getTerrainTag(tag) and not seen[tag] then
            seen[tag] = true
            table.insert(result, tag)
        end
    end
    return result
end

function EditorTilesetPanel:init(editor)
    super.init(self, 0, 0, 440, 420)
    self.editor = editor
    self.document = nil
    self.tile = nil
    self.mode = "tileset"
    self.terrain_paint_mode = "is"
    self.terrain_rule_lookup = {}
    self.terrain_expansion = {}
    self.mode_buttons = {}
    for _, mode in ipairs(MODES) do
        local id = mode.id
        local button = self:addChild(EditorButton(mode.name, function() self:setMode(id) end))
        table.insert(self.mode_buttons, button)
    end
    self.add_button = self:addChild(EditorButton("Add", function() self:openAddMenu() end))
    self.tile_grid = self:addChild(EditorTilePalette(editor, {
        show_tools = false,
        on_selection = function()
            if self.mode == "tileset" then self:setMode("tile") end
        end,
        on_tile_pressed = function(...) return self:beginTerrainRulePaint(...) end,
        on_tile_dragged = function(...) return self:continueTerrainRulePaint(...) end,
        on_tile_released = function(...) return self:endTerrainRulePaint(...) end,
        draw_tile_overlay = function(...) self:drawTerrainTileOverlay(...) end
    }))
    self.list = self:addChild(EditorItemList({
        on_select = function(item) self:selectItem(item and item.data) end,
        on_drag_end = function(item, list, _, y) self:reorderItem(item, list:getItemIndexAt(y)) end,
        on_context_menu = function(item, list, x, y) self:openItemContext(item, list, x, y) end,
        on_request_focus = function(control) editor.dockspace:setFocus(control) end
    }))
    self.properties = self:addChild(EditorPropertiesPanel(editor))
    self.zoom_out_button = self:addChild(EditorButton("-", function() self.tile_grid:stepZoom(-1) end))
    self.zoom_label_button = self:addChild(EditorButton("100%", function() self.tile_grid:resetZoom() end))
    self.zoom_in_button = self:addChild(EditorButton("+", function() self.tile_grid:stepZoom(1) end))
    self.terrain_is_button = self:addChild(EditorButton("IS", function()
        self:setTerrainPaintMode("is")
    end))
    self.terrain_not_button = self:addChild(EditorButton("NOT", function()
        self:setTerrainPaintMode("not")
    end))
    self.terrain_any_button = self:addChild(EditorButton("ANY", function()
        self:setTerrainPaintMode("any")
    end))
end

function EditorTilesetPanel:setDocument(document, options)
    options = options or {}
    local state = options.view_state
    local selected = options.preserve_selection and self.selected_item or nil
    local mode = state and state.mode
        or options.preserve_mode and self.mode or "tileset"
    local tile_id = state and state.tile_id
        or options.preserve_tile and self.tile and self.tile.id or 0
    self.document = document
    self.selected_item = nil
    self.tile_grid:setTilesetDocument(document)
    self.tile = document and (document:getTile(tile_id) or document:getTile(0)) or nil
    if self.tile then self.tile_grid:setSelectedTile(self.tile) end
    self:setMode(mode)
    if state and state.selection and mode == "terrain" then
        selected = self:resolveViewSelection(state.selection)
    end
    if selected and mode == "terrain" then self:refreshList(selected) end
end

function EditorTilesetPanel:captureViewState()
    local state = {
        mode = self.mode,
        tile_id = self.tile and self.tile.id or 0
    }
    local item = self.selected_item
    if not item or self.mode ~= "terrain" or not self.document then return state end
    local selection = { kind = item.kind }
    if item.kind == "tag" then
        for index, tag in ipairs(self.document:getTerrainTags()) do
            if tag == item.tag then selection.tag_index = index break end
        end
    else
        for index, terrain in ipairs(self.document:getTerrainSets()) do
            if terrain == item.terrain then selection.terrain_index = index break end
        end
        for index, variant in ipairs(item.terrain and item.terrain.terrain_variants or {}) do
            if variant == item.variant then selection.variant_index = index break end
        end
        for index, rule in ipairs(item.terrain and item.terrain.terrain_tiles or {}) do
            if rule == item.rule then selection.rule_index = index break end
        end
        for index, condition in ipairs(item.rule and item.rule.conditions or {}) do
            if condition == item.condition then selection.condition_index = index break end
        end
    end
    state.selection = selection
    return state
end

function EditorTilesetPanel:resolveViewSelection(selection)
    if not selection or not self.document then return nil end
    if selection.kind == "tag" then
        local tag = self.document:getTerrainTags()[selection.tag_index]
        return tag and { kind = "tag", value = tag, tag = tag } or nil
    end
    local terrain = self.document:getTerrainSets()[selection.terrain_index]
    if not terrain then return nil end
    if selection.kind == "terrain" then
        return { kind = "terrain", value = terrain, terrain = terrain }
    end
    local variant = terrain.terrain_variants and terrain.terrain_variants[selection.variant_index]
    if selection.kind == "variant" then
        return variant and { kind = "variant", value = variant,
            terrain = terrain, variant = variant } or nil
    end
    local rule = terrain.terrain_tiles and terrain.terrain_tiles[selection.rule_index]
    variant = variant or rule and self.document:getTerrainVariant(terrain, rule.terrain)
    if selection.kind == "rule" then
        return rule and { kind = "rule", value = rule, terrain = terrain,
            variant = variant, rule = rule } or nil
    end
    local condition = rule and rule.conditions
        and rule.conditions[selection.condition_index]
    if selection.kind == "condition" and condition then
        return { kind = "condition", value = condition, terrain = terrain,
            variant = variant, rule = rule, condition = condition }
    end
end

function EditorTilesetPanel:setTile(tile)
    self.tile = tile
    self.tile_grid:setSelectedTile(tile)
    if self.mode ~= "tileset" then self:rebuild() end
end

function EditorTilesetPanel:setMode(mode)
    if self.mode ~= mode then self.selected_item = nil end
    self.mode = mode
    self:rebuildTerrainRuleLookup()
    self:rebuild()
    if mode == "terrain" and self.editor.message_bar then
        self.editor.message_bar:setStatus(
            "Terrain setup: select a variant, click tile centers to assign it, then paint neighbor slots")
    end
end

function EditorTilesetPanel:getTerrainExpansionKey(item)
    if not item or not item.kind then return nil end
    local document_id = self.document and self.document.id or ""
    local terrain_id = item.terrain and item.terrain.id or ""
    if item.kind == "terrain" then
        return table.concat({ document_id, "terrain", terrain_id }, ":")
    elseif item.kind == "variant" then
        return table.concat({ document_id, "variant", terrain_id, item.variant.id }, ":")
    elseif item.kind == "rule" then
        local rule_index = 0
        for index, rule in ipairs(item.terrain.terrain_tiles or {}) do
            if rule == item.rule then rule_index = index break end
        end
        return table.concat({ document_id, "rule", terrain_id,
            item.variant and item.variant.id or item.rule.terrain, rule_index }, ":")
    end
end

function EditorTilesetPanel:isTerrainItemExpanded(item)
    local key = self:getTerrainExpansionKey(item)
    if not key then return false end
    local expanded = self.terrain_expansion[key]
    if expanded ~= nil then return expanded end
    return item.kind == "terrain"
end

function EditorTilesetPanel:setTerrainItemExpanded(item, expanded)
    local key = self:getTerrainExpansionKey(item)
    if not key then return false end
    self.terrain_expansion[key] = expanded == true
    return true
end

function EditorTilesetPanel:ensureTerrainItemVisible(item)
    if not item or not item.terrain then return end
    if item.kind == "variant" or item.kind == "rule" or item.kind == "condition" then
        self:setTerrainItemExpanded({ kind = "terrain", terrain = item.terrain }, true)
    end
    if item.kind == "rule" or item.kind == "condition" then
        local variant = item.variant
            or self.document:getTerrainVariant(item.terrain, item.rule.terrain)
        if variant then
            self:setTerrainItemExpanded({ kind = "variant", terrain = item.terrain,
                variant = variant }, true)
        end
    end
    if item.kind == "condition" then
        self:setTerrainItemExpanded({ kind = "rule", terrain = item.terrain,
            variant = item.variant, rule = item.rule }, true)
    end
end

function EditorTilesetPanel:toggleTerrainItem(item)
    if not item then return false end
    self:setTerrainItemExpanded(item, not self:isTerrainItemExpanded(item))
    self:refreshList(item)
    return true
end

function EditorTilesetPanel:getItems()
    if not self.document then return {} end
    if self.mode == "terrain" then
        local rows = {}
        for _, tag in ipairs(self.document:getTerrainTags()) do
            table.insert(rows, { kind = "tag", value = tag, tag = tag })
        end
        for _, terrain in ipairs(self.document:getTerrainSets()) do
            local terrain_row = { kind = "terrain", value = terrain, terrain = terrain,
                has_children = #(terrain.terrain_variants or {}) > 0 }
            table.insert(rows, terrain_row)
            if self:isTerrainItemExpanded(terrain_row) then
                for _, variant in ipairs(terrain.terrain_variants or {}) do
                    local rules = {}
                    for _, rule in ipairs(terrain.terrain_tiles or {}) do
                        if rule.terrain == variant.id then table.insert(rules, rule) end
                    end
                    local variant_row = {
                        kind = "variant", value = variant, terrain = terrain, variant = variant,
                        has_children = #rules > 0
                    }
                    table.insert(rows, variant_row)
                    if self:isTerrainItemExpanded(variant_row) then
                        for _, rule in ipairs(rules) do
                            local rule_row = {
                                kind = "rule", value = rule, terrain = terrain,
                                variant = variant, rule = rule,
                                has_children = #(rule.conditions or {}) > 0
                            }
                            table.insert(rows, rule_row)
                            if self:isTerrainItemExpanded(rule_row) then
                                for _, condition in ipairs(rule.conditions or {}) do
                                    table.insert(rows, {
                                        kind = "condition", value = condition, terrain = terrain,
                                        variant = variant, rule = rule, condition = condition
                                    })
                                end
                            end
                        end
                    end
                end
            end
        end
        return rows
    end
    if self.mode == "collision" then return self.document:getCollisionShapes(self.tile) end
    if self.mode == "animation" then return self.document:getAnimationFrames(self.tile) end
    return {}
end

function EditorTilesetPanel:refreshList(selected)
    if self.mode == "terrain" then self:ensureTerrainItemVisible(selected) end
    local items = {}
    for index, value in ipairs(self:getItems()) do
        local label
        local indent = 0
        if self.mode == "terrain" then
            if value.kind == "tag" then
                label = "# " .. (value.tag.name or value.tag.id)
            elseif value.kind == "terrain" then
                label = value.terrain.name or ("Terrain Set " .. index)
            elseif value.kind == "variant" then
                label = value.variant.name or ("Terrain " .. tostring(value.variant.id))
                indent = 1
            else
                if value.kind == "rule" then
                    label = string.format("Tile %s Rule", tostring(value.rule.tile_id or 0))
                    indent = 2
                else
                    local definition = Registry.getTerrainConditionType(value.condition.type)
                    label = definition and definition.name
                        or ("Unavailable: " .. tostring(value.condition.type))
                    indent = 3
                end
            end
        elseif self.mode == "collision" then label = string.format("%s %d", StringUtils.titleCase(value.shape or "rectangle"), index)
        else label = string.format("Tile %s  -  %sms", tostring(value.tileid or 0), tostring(value.duration or 100)) end
        local list_item = { id = index, label = label, data = value, indent = indent }
        if self.mode == "terrain" and value.has_children then
            list_item.expanded = self:isTerrainItemExpanded(value)
            local row = value
            list_item.on_toggle = function() self:toggleTerrainItem(row) end
        end
        table.insert(items, list_item)
    end
    self.list:setItems(items)
    if #items > 0 then
        local selected_index = 1
        local selected_value = selected and (selected.value or selected)
        for index, list_item in ipairs(self.list.filtered_items) do
            local item_value = list_item.data and (list_item.data.value or list_item.data)
            if item_value == selected_value then selected_index = index break end
        end
        self.list:select(selected_index)
        self:selectItem(self.list:getSelectedItem().data)
    else
        self.properties:setTarget(nil)
    end
end

function EditorTilesetPanel:rebuild()
    local list_mode = self.mode == "terrain" or self.mode == "collision" or self.mode == "animation"
    self.list.visible, self.add_button.visible = list_mode, list_mode
    self.add_button.label = self.mode == "terrain" and "Add..." or "Add"
    self.properties.visible = true
    if not self.document then self.properties:setTarget(nil) return end
    if self.mode == "tileset" then
        self.properties:setTarget(self.document:getPropertiesTarget())
    elseif self.mode == "tile" then
        self.properties:setTarget(self.document:getTilePropertiesTarget(self.tile))
    else
        self:refreshList(self.selected_item)
    end
end

function EditorTilesetPanel:setTerrainPaintMode(mode)
    if mode ~= "is" and mode ~= "not" and mode ~= "any" then return false end
    self.terrain_paint_mode = mode
    if self.editor.message_bar then
        local descriptions = {
            is = "Terrain atlas IS: painted neighbor slots must use the selected terrain",
            ["not"] = "Terrain atlas NOT: painted neighbor slots must not use the selected terrain",
            any = "Terrain atlas ANY: clear painted neighbor requirements"
        }
        self.editor.message_bar:setStatus(descriptions[mode])
    end
    return true
end

function EditorTilesetPanel:getTerrainPaintSelection()
    local document, terrain, variant = self.editor:getSelectedTerrain()
    if self.mode ~= "terrain" or document ~= self.document then return nil end
    return terrain, variant
end

function EditorTilesetPanel:rebuildTerrainRuleLookup()
    self.terrain_rule_lookup = {}
    local terrain = self:getTerrainPaintSelection()
    if not terrain then return end
    for _, rule in ipairs(terrain.terrain_tiles or {}) do
        if self.terrain_rule_lookup[rule.tile_id] == nil then
            self.terrain_rule_lookup[rule.tile_id] = rule
        end
    end
    local selected_rule = self.selected_item and self.selected_item.rule
    if selected_rule and self.selected_item.terrain == terrain then
        self.terrain_rule_lookup[selected_rule.tile_id] = selected_rule
    end
end

function EditorTilesetPanel:getTerrainSlot(tile_id, x, y, palette)
    local tile_x, tile_y, width, height = palette:getTileRect(tile_id)
    if not tile_x then return nil end
    local u = MathUtils.clamp((x - tile_x) / width, 0, 1)
    local v = MathUtils.clamp((y - tile_y) / height, 0, 1)
    local closest, closest_distance
    for _, slot in ipairs(TERRAIN_SLOTS) do
        local distance = (u - slot.u) ^ 2 + (v - slot.v) ^ 2
        if not closest_distance or distance < closest_distance then
            closest, closest_distance = slot, distance
        end
    end
    return closest
end

function EditorTilesetPanel:getTerrainRuleForTile(terrain, tile_id)
    local rule = self.terrain_rule_lookup[tile_id]
    if rule and TableUtils.contains(terrain.terrain_tiles or {}, rule) then return rule end
    for _, candidate in ipairs(terrain.terrain_tiles or {}) do
        if candidate.tile_id == tile_id then return candidate end
    end
end

function EditorTilesetPanel:paintTerrainRuleSlot(tile_id, x, y, palette)
    local terrain, variant = self:getTerrainPaintSelection()
    if not terrain or not variant then return false end
    local slot = self:getTerrainSlot(tile_id, x, y, palette)
    if not slot then return false end
    local paint_key = tostring(tile_id) .. ":" .. slot.id
    if self.terrain_painted_slots and self.terrain_painted_slots[paint_key] then return false end
    self.terrain_painted_slots = self.terrain_painted_slots or {}
    self.terrain_painted_slots[paint_key] = true

    local rule = self:getTerrainRuleForTile(terrain, tile_id)
    local changed = false
    if slot.center then
        if not rule then
            rule = self.document:addTerrainTile(terrain, variant, tile_id)
            changed = rule ~= nil
        elseif rule.terrain ~= variant.id then
            for _, candidate in ipairs(terrain.terrain_tiles or {}) do
                if candidate.tile_id == tile_id then candidate.terrain = variant.id end
            end
            changed = true
        end
    elseif self.terrain_paint_mode == "any" then
        if not rule then return false end
        if not self.document:getTerrainConditionAt(rule, slot.x, slot.y, "terrain") then
            return false
        end
        self.document:setTerrainNeighbor(rule, slot.x, slot.y, nil)
        changed = true
    else
        if not rule then
            rule = self.document:addTerrainTile(terrain, variant, tile_id)
            changed = rule ~= nil
        end
        if rule then
            local existing = self.document:getTerrainConditionAt(rule, slot.x, slot.y, "terrain")
            if not existing or existing.terrain ~= variant.id
                or (existing.operator or "is") ~= self.terrain_paint_mode then changed = true end
            self.document:setTerrainNeighbor(rule, slot.x, slot.y,
                variant.id, self.terrain_paint_mode)
        end
    end
    if not rule then return false end
    self.terrain_rule_lookup[tile_id] = rule
    self.terrain_painted_rule = rule
    if changed then
        self.editor:markHistoryChanged()
        self.terrain_paint_changed = true
    end
    return changed
end

function EditorTilesetPanel:beginTerrainRulePaint(tile_id, x, y, button, _, palette)
    if self.mode ~= "terrain" or button ~= 1 then return false end
    local terrain, variant = self:getTerrainPaintSelection()
    if not terrain or not variant then
        self.editor:addWarning("Select a terrain variant before marking tiles", nil,
            "terrain_editing")
        return true
    end
    self.editor:clearDiagnostics("terrain_editing")
    self.tile = self.document:getTile(tile_id)
    palette:setSelection(tile_id, tile_id, false)
    self.editor:beginHistoryTransaction("Paint Terrain Rules", self.document)
    self.terrain_painted_slots = {}
    self.terrain_painted_rule = nil
    self.terrain_paint_changed = false
    self:paintTerrainRuleSlot(tile_id, x, y, palette)
    return true
end

function EditorTilesetPanel:continueTerrainRulePaint(tile_id, x, y, palette)
    if not self.terrain_painted_slots then return false end
    return self:paintTerrainRuleSlot(tile_id, x, y, palette)
end

function EditorTilesetPanel:endTerrainRulePaint()
    if not self.terrain_painted_slots then return false end
    local changed, selected = self.terrain_paint_changed, self.terrain_painted_rule
    local terrain, variant = self:getTerrainPaintSelection()
    self.terrain_painted_slots = nil
    self.terrain_painted_rule = nil
    self.terrain_paint_changed = false
    if changed then
        self.editor:commitHistoryTransaction()
        self:refreshList(selected and {
            kind = "rule", value = selected, terrain = terrain,
            variant = variant, rule = selected
        })
    else
        self.editor:cancelHistoryTransaction()
    end
    return true
end

function EditorTilesetPanel:getTerrainMarkerColor(terrain, terrain_id, fallback)
    if terrain_id == "same" then terrain_id = fallback end
    if terrain_id == 0 then return { 0.58, 0.62, 0.68, 1 } end
    local variant = self.document:getTerrainVariant(terrain, terrain_id)
    return variant and ColorUtils.tryHexToRGB(variant.color or "")
        or { 1, 1, 1, 1 }
end

function EditorTilesetPanel:drawTerrainMarker(x, y, radius, color, operator, center)
    Draw.setColor(color[1], color[2], color[3], center and 0.92 or 0.82)
    love.graphics.circle("fill", x, y, radius)
    Draw.setColor(0.04, 0.04, 0.05, 0.9)
    love.graphics.setLineWidth(math.max(1, radius * 0.22))
    love.graphics.circle("line", x, y, radius)
    if operator == "not" then
        Draw.setColor(1, 0.28, 0.24, 1)
        local inset = radius * 0.62
        love.graphics.line(x - inset, y - inset, x + inset, y + inset)
        love.graphics.line(x + inset, y - inset, x - inset, y + inset)
    end
end

function EditorTilesetPanel:drawTerrainTileOverlay(tile_id, x, y, width, height, palette)
    if self.mode ~= "terrain" then return end
    local terrain = self:getTerrainPaintSelection()
    if not terrain then return end
    local rule = self:getTerrainRuleForTile(terrain, tile_id)
    local radius = MathUtils.clamp(math.min(width, height) * 0.075, 2.5, 8)
    if rule then
        local center_color = self:getTerrainMarkerColor(terrain, rule.terrain, rule.terrain)
        self:drawTerrainMarker(x + width * 0.5, y + height * 0.5,
            radius * 1.35, center_color, "is", true)
        for _, slot in ipairs(TERRAIN_SLOTS) do
            if not slot.center then
                local condition = self.document:getTerrainConditionAt(rule, slot.x, slot.y, "terrain")
                if condition then
                    local color = self:getTerrainMarkerColor(terrain, condition.terrain, rule.terrain)
                    self:drawTerrainMarker(x + width * slot.u, y + height * slot.v,
                        radius, color, condition.operator or "is", false)
                end
            end
        end
    end
    local mouse_x, mouse_y = self.editor:getMousePosition()
    local local_x, local_y = palette:toLocal(mouse_x, mouse_y)
    if palette:getTileAt(local_x, local_y) == tile_id then
        Draw.setColor(0.86, 0.88, 0.92, 0.52)
        love.graphics.setLineWidth(1)
        for _, slot in ipairs(TERRAIN_SLOTS) do
            local condition = rule and not slot.center
                and self.document:getTerrainConditionAt(rule, slot.x, slot.y, "terrain")
            if (slot.center and not rule) or (not slot.center and not condition) then
                love.graphics.circle("line", x + width * slot.u, y + height * slot.v,
                    slot.center and radius * 1.35 or radius)
            end
        end
    end
    love.graphics.setLineWidth(1)
end

function EditorTilesetPanel:openAddMenu()
    if self.mode ~= "terrain" then return self:addItem() end
    local selected = self.selected_item
    local terrain = selected and selected.terrain
    local variant = selected and (selected.variant
        or selected.rule and self.document:getTerrainVariant(terrain, selected.rule.terrain))
    local items = {
        { label = "New Terrain Tag", action = function() self:addItem("tag") end },
        { label = "New Terrain Set", action = function() self:addItem("terrain") end },
        { label = "New Terrain Variant", is_enabled = function() return terrain ~= nil end,
            action = function() self:addItem("variant", terrain) end },
        { label = "New Tile Rule for Selected Tile",
            is_enabled = function() return variant ~= nil and self.tile ~= nil end,
            action = function() self:addItem("rule", terrain, variant) end }
    }
    local rule = selected and selected.rule
    table.insert(items, { label = "Add Condition", children = self:getConditionMenuItems(
        terrain, variant, rule), is_enabled = function() return rule ~= nil end })
    local x, y = self.add_button:getGlobalPosition()
    return self.editor.dockspace:openContextMenu(items, x, y + self.add_button.height,
        self.add_button)
end

function EditorTilesetPanel:getConditionMenuItems(terrain, variant, rule)
    local items = {}
    for _, definition in ipairs(Registry.getTerrainConditionTypes()) do
        local condition_type = definition.id
        table.insert(items, {
            label = definition.name,
            enabled = rule ~= nil,
            action = function() self:addItem("condition", terrain, variant, rule, condition_type) end
        })
    end
    return items
end

function EditorTilesetPanel:addItem(kind, terrain, variant, rule, condition_type)
    if not self.document then return false end
    self.editor:beginHistoryTransaction("Add Tileset Item", self.document)
    local item, reason
    if self.mode == "terrain" and kind == "tag" then
        item = self.document:addTerrainTag()
        item = { kind = "tag", value = item, tag = item }
    elseif self.mode == "terrain" and kind == "terrain" then
        item = self.document:addTerrainSet()
        item = { kind = "terrain", value = item, terrain = item }
    elseif self.mode == "terrain" and kind == "variant" then
        local value = self.document:addTerrainVariant(terrain)
        if value then item = { kind = "variant", value = value, terrain = terrain, variant = value } end
    elseif self.mode == "terrain" and kind == "rule" then
        local value
        value, reason = self.document:addTerrainTile(terrain, variant, self.tile and self.tile.id)
        if value then item = { kind = "rule", value = value, terrain = terrain, rule = value } end
    elseif self.mode == "terrain" and kind == "condition" then
        local value = self.document:addTerrainCondition(rule, condition_type)
        if value then
            item = { kind = "condition", value = value, terrain = terrain,
                variant = variant, rule = rule, condition = value }
        end
    elseif self.mode == "collision" then item = self.document:addCollisionShape(self.tile)
    elseif self.mode == "animation" then item = self.document:addAnimationFrame(self.tile) end
    if item then
        self.editor:markHistoryChanged()
        self.editor:commitHistoryTransaction()
        self:refreshList(item)
        if self.mode == "terrain" and self.editor.terrain_palette then
            self.editor.terrain_palette:refresh()
        end
        return true
    end
    self.editor:cancelHistoryTransaction()
    if reason then self.editor:addWarning(reason, nil, "terrain_editing") end
    return false
end

function EditorTilesetPanel:getItemTarget(item)
    if not item then return nil end
    local source = self.mode == "terrain" and item.value or item
    local supports_properties = self.mode ~= "terrain"
        or item.kind == "terrain" or item.kind == "variant"
    if supports_properties then
        source.properties = source.properties or {}
        source.__editor_property_types = source.__editor_property_types or {}
    end
    local set = supports_properties
        and EditorPropertySet(source.properties, source.__editor_property_types) or nil
    local function field(label, key, numeric)
        return EditorPropertyFields.value(source, label, key, { numeric = numeric == true })
    end
    local fields, title = {}, "Tileset Item"
    if self.mode == "terrain" then
        local terrain = item.terrain
        if item.kind == "tag" then
            local tag = item.tag
            title = "Terrain Tag: " .. (tag.name or tag.id)
            fields = {
                { label = "ID", get = function() return tag.id end,
                    set = function(value) return self.document:setTerrainTagId(tag, value) end },
                field("Name", "name"), EditorPropertyFields.color(tag, "Color", "color")
            }
        elseif item.kind == "terrain" then
            title = terrain.name or "Terrain Set"
            fields = {
                field("ID", "id"), field("Name", "name"), field("Icon Tile", "tile_icon", true),
                EditorPropertyFields.choice(terrain, "Fallback", "fallback_mode", {
                    { value = "closest", label = "Closest Match" },
                    { value = "strict", label = "Default Rule Only" }
                }, { default = "closest" })
            }
        elseif item.kind == "variant" then
            local variant = item.variant
            title = variant.name or ("Terrain " .. tostring(variant.id))
            fields = {
                { label = "ID", readonly = true, get = function() return variant.id end,
                    set = function() return false end },
                field("Name", "name"), EditorPropertyFields.color(variant, "Color", "color"),
                field("Icon Tile", "tile_icon", true), field("Probability", "probability", true),
                { label = "Tags", get = function() return formatTags(variant.tags) end,
                    set = function(value) variant.tags = parseTags(self.document, value) return true end }
            }
        elseif item.kind == "rule" then
            local rule = item.rule
            title = "Terrain Rule: Tile " .. tostring(rule.tile_id or 0)
            local terrain_choices = {}
            for _, variant in ipairs(terrain.terrain_variants or {}) do
                table.insert(terrain_choices, {
                    value = variant.id,
                    label = variant.name or ("Terrain " .. tostring(variant.id))
                })
            end
            fields = {
                { label = "Tile ID", get = function() return rule.tile_id end,
                    set = function(value)
                        return self.document:setTerrainTileId(terrain, rule, value)
                    end },
                { label = "Center Terrain", choices = terrain_choices,
                    get = function() return rule.terrain end,
                    set = function(value)
                        return self.document:setTerrainTileVariant(terrain, rule, value)
                    end },
                field("Priority", "priority", true), field("Probability", "probability", true),
            }
            local boolean_choices = {
                { value = true, label = "Yes" }, { value = false, label = "No" }
            }
            local function booleanField(label, key, default)
                return { label = label, choices = boolean_choices,
                    get = function()
                        if rule[key] == nil then return default == true end
                        return rule[key] == true
                    end,
                    set = function(value) rule[key] = value == true return true end }
            end
            table.insert(fields, booleanField("Enabled", "enabled", true))
            table.insert(fields, booleanField("Flip X", "flip_x"))
            table.insert(fields, booleanField("Flip Y", "flip_y"))
            local transform_names = {
                { "identity", "Allow Identity" }, { "rotate_90", "Allow Rotated 90 degrees" },
                { "rotate_180", "Allow Rotated 180 degrees" }, { "rotate_270", "Allow Rotated 270 degrees" },
                { "flip_x", "Allow Mirrored X" }, { "flip_y", "Allow Mirrored Y" }
            }
            for _, entry in ipairs(transform_names) do
                local transform, label = entry[1], entry[2]
                table.insert(fields, {
                    label = label, choices = boolean_choices,
                    get = function() return TableUtils.contains(rule.transforms or {}, transform) end,
                    set = function(value)
                        rule.transforms = rule.transforms or {}
                        local present = TableUtils.contains(rule.transforms, transform)
                        if value == true and not present then table.insert(rule.transforms, transform) end
                        if value ~= true and present then TableUtils.removeValue(rule.transforms, transform) end
                        return true
                    end
                })
            end
            table.insert(fields, booleanField("Rotate 90°", "rotate"))
            local directions = {
                { "North", 0, -1 }, { "North East", 1, -1 },
                { "East", 1, 0 }, { "South East", 1, 1 },
                { "South", 0, 1 }, { "South West", -1, 1 },
                { "West", -1, 0 }, { "North West", -1, -1 }
            }
            local neighbor_choices = {
                { value = "any", label = "Any" },
                { value = "is:0", label = "Is Empty" },
                { value = "not:0", label = "Is Not Empty" }
            }
            for _, variant in ipairs(terrain.terrain_variants or {}) do
                local name = variant.name or ("Terrain " .. tostring(variant.id))
                table.insert(neighbor_choices, { value = "is:" .. variant.id, label = "Is " .. name })
                table.insert(neighbor_choices, { value = "not:" .. variant.id, label = "Is Not " .. name })
            end
            for _, direction in ipairs(directions) do
                local x, y = direction[2], direction[3]
                table.insert(fields, {
                    label = direction[1], choices = neighbor_choices,
                    get = function()
                        local neighbor = self.document:getTerrainConditionAt(rule, x, y, "terrain")
                        if not neighbor then return "any" end
                        return (neighbor.operator or "is") .. ":" .. tostring(neighbor.terrain)
                    end,
                    set = function(value)
                        if value == "any" then
                            return self.document:setTerrainNeighbor(rule, x, y, nil)
                        end
                        local match, terrain_id = tostring(value):match("^(%w+):(%d+)$")
                        return terrain_id ~= nil and self.document:setTerrainNeighbor(
                            rule, x, y, tonumber(terrain_id), match)
                    end
                })
            end
        elseif item.kind == "condition" then
            local condition = item.condition
            local definition = Registry.getTerrainConditionType(condition.type)
            title = definition and definition.name or ("Unavailable Condition: " .. tostring(condition.type))
            fields = {
                { label = "Type", readonly = true, get = function() return condition.type end,
                    set = function() return false end }
            }
            local function choice(label, key, choices, rebuild)
                return { label = label, choices = choices,
                    get = function() return condition[key] end,
                    set = function(value)
                        if key == "predicate" then
                            condition[key] = value
                            condition.parameters = {}
                            Registry.terrain_rules.parameter_sets[condition] = nil
                        else
                            condition[key] = value
                        end
                        return true
                    end,
                    rebuild_target = rebuild and function() return self:getItemTarget(item) end or nil }
            end
            local terrain_choices = {
                { value = "same", label = "Same as Center" },
                { value = 0, label = "Empty" }
            }
            for _, variant in ipairs(item.terrain.terrain_variants or {}) do
                table.insert(terrain_choices, { value = variant.id,
                    label = variant.name or ("Terrain " .. variant.id) })
            end
            local tag_choices = {}
            for _, tag in ipairs(self.document:getTerrainTags()) do
                table.insert(tag_choices, { value = tag.id, label = tag.name or tag.id })
            end
            if condition.type == "terrain" then
                table.insert(fields, field("Offset X", "x", true))
                table.insert(fields, field("Offset Y", "y", true))
                table.insert(fields, choice("Operator", "operator", {
                    { value = "is", label = "Is" }, { value = "not", label = "Is Not" }
                }))
                table.insert(fields, choice("Terrain", "terrain", terrain_choices))
            elseif condition.type == "tag" then
                table.insert(fields, field("Offset X", "x", true))
                table.insert(fields, field("Offset Y", "y", true))
                table.insert(fields, choice("Operator", "operator", {
                    { value = "has", label = "Has" }, { value = "not_has", label = "Does Not Have" }
                }))
                table.insert(fields, choice("Tag", "tag", tag_choices))
            elseif condition.type == "count" then
                table.insert(fields, choice("Count", "subject", {
                    { value = "terrain", label = "Terrain" }, { value = "tag", label = "Tag" },
                    { value = "occupied", label = "Occupied Cells" }
                }, true))
                if condition.subject == "tag" then
                    table.insert(fields, choice("Tag", "tag", tag_choices))
                elseif condition.subject ~= "occupied" then
                    table.insert(fields, choice("Terrain", "terrain", terrain_choices))
                end
                table.insert(fields, field("Radius", "radius", true))
                table.insert(fields, choice("Operator", "operator", { "==", "!=", ">", ">=", "<", "<=" }))
                table.insert(fields, field("Expected Count", "count", true))
            elseif condition.type == "predicate" then
                local predicates = {}
                for _, predicate in ipairs(Registry.getTerrainPredicates()) do
                    table.insert(predicates, { value = predicate.id, label = predicate.name })
                end
                table.insert(fields, choice("Predicate", "predicate", predicates, true))
                table.insert(fields, field("Influence Radius", "influence_radius", true))
            elseif condition.type == "script" then
                table.insert(fields, { label = "Script", multiline = true,
                    get = function() return condition.source or "" end,
                    set = function(value)
                        local callback, reason = Registry.terrain_rules:compileScript(value)
                        if not callback then
                            self.editor:addWarning(reason, nil, "terrain_script")
                            return false
                        end
                        condition.source = value
                        return true
                    end })
                table.insert(fields, field("Influence Radius", "influence_radius", true))
            elseif definition then
                for _, condition_field in ipairs(definition.fields or {}) do
                    local field_id = condition_field.id
                    if condition_field.choices then
                        local choices = type(condition_field.choices) == "function"
                            and condition_field.choices(condition, self.document, item.terrain)
                            or condition_field.choices
                        table.insert(fields, choice(condition_field.name or condition_field.label
                            or StringUtils.titleCase(field_id:gsub("_", " ")), field_id, choices,
                            condition_field.rebuild))
                    else
                        table.insert(fields, {
                            label = condition_field.name or condition_field.label
                                or StringUtils.titleCase(field_id:gsub("_", " ")),
                            multiline = condition_field.multiline == true,
                            get = function() return condition[field_id] end,
                            set = function(value)
                                if condition_field.type == "number" or condition_field.type == "integer" then
                                    value = tonumber(value)
                                    if not value then return false end
                                    if condition_field.type == "integer" then value = MathUtils.round(value) end
                                end
                                condition[field_id] = value
                                return true
                            end
                        })
                    end
                end
            end
            local parameter_set
            if condition.type == "predicate" or condition.type == "script" then
                parameter_set = Registry.terrain_rules:getParameterSet(condition)
                    or EditorPropertySet()
                Registry.terrain_rules:setParameterSet(condition, parameter_set)
                local predicate = condition.type == "predicate"
                    and Registry.getTerrainPredicate(condition.predicate) or nil
                for _, parameter in ipairs(predicate and predicate.parameters or {}) do
                    if not parameter_set:getProperty(parameter.id) then
                        parameter_set:registerProperty(parameter.id, parameter.type, parameter)
                    end
                end
            end
            return {
                title = title, fields = fields,
                property_set = parameter_set,
                properties = parameter_set and parameter_set.values or nil,
                property_types = parameter_set and parameter_set.types or nil,
                history_owner = self.document,
                on_changed = function()
                    if parameter_set then
                        local entries, reason = parameter_set:encodeEntries()
                        if entries then condition.parameters = entries
                        elseif reason then self.editor:addWarning(reason, nil, "terrain_parameters") end
                    end
                    self:refreshList(item)
                end
            }
        end
    elseif self.mode == "collision" then
        title = "Tile Collision Shape"
        fields = { EditorPropertyFields.choice(item, "Shape", "shape",
                { "point", "line", "rectangle", "ellipse", "polygon", "polyline" },
                { default = "rectangle" }),
            field("X", "x", true), field("Y", "y", true),
            field("Width", "width", true), field("Height", "height", true),
            field("Rotation", "rotation", true) }
    elseif self.mode == "animation" then
        title = "Animation Frame"
        fields = { field("Tile ID", "tileid", true), field("Duration (ms)", "duration", true) }
    end
    return { title = title, fields = fields, property_set = set,
        properties = supports_properties and source.properties or nil,
        history_owner = self.document,
        property_types = supports_properties and source.__editor_property_types or nil,
        on_changed = function()
            self:refreshList(item)
            if self.mode == "terrain" and self.editor.terrain_palette then
                self.editor.terrain_palette:refresh()
            end
        end }
end

function EditorTilesetPanel:selectItem(item)
    self.selected_item = item
    self.properties:setTarget(self:getItemTarget(item))
    if self.mode == "terrain" and item then
        local variant = item.variant or item.rule
            and self.document:getTerrainVariant(item.terrain, item.rule.terrain)
            or item.kind == "terrain" and item.terrain.terrain_variants
                and item.terrain.terrain_variants[1]
        if variant then self.editor:setSelectedTerrain(self.document, item.terrain, variant) end
    end
    self:rebuildTerrainRuleLookup()
end

function EditorTilesetPanel:removeItem(item)
    if not item then return false end
    self.editor:beginHistoryTransaction("Remove Tileset Item", self.document)
    if self.mode == "terrain" then
        if item.kind == "tag" then
            self.document:removeTerrainTag(item.tag)
        elseif item.kind == "terrain" then
            TableUtils.removeValue(self.document:getTerrainSets(), item.terrain)
        elseif item.kind == "variant" then
            TableUtils.removeValue(item.terrain.terrain_variants, item.variant)
            for index = #(item.terrain.terrain_tiles or {}), 1, -1 do
                if item.terrain.terrain_tiles[index].terrain == item.variant.id then
                    table.remove(item.terrain.terrain_tiles, index)
                else
                    local conditions = item.terrain.terrain_tiles[index].conditions or {}
                    for condition_index = #conditions, 1, -1 do
                        local condition = conditions[condition_index]
                        if (condition.type == "terrain" or condition.type == "count")
                            and condition.terrain == item.variant.id then
                            table.remove(conditions, condition_index)
                        end
                    end
                end
            end
        elseif item.kind == "rule" then
            TableUtils.removeValue(item.terrain.terrain_tiles, item.rule)
        elseif item.kind == "condition" then
            TableUtils.removeValue(item.rule.conditions, item.condition)
        end
    else
        TableUtils.removeValue(self:getItems(), item)
    end
    self.editor:markHistoryChanged()
    self.editor:commitHistoryTransaction()
    self:refreshList()
    if self.mode == "terrain" and self.editor.terrain_palette then
        self.editor.terrain_palette:refresh()
    end
    return true
end

function EditorTilesetPanel:reorderItem(item, target)
    if not item then return end
    if self.mode == "terrain" then return end
    local items = self:getItems()
    local source
    for index, value in ipairs(items) do if value == item.data then source = index break end end
    if not source then return end
    self.editor:beginHistoryTransaction("Reorder Tileset Item", self.document)
    local value = table.remove(items, source)
    table.insert(items, MathUtils.clamp(target, 1, #items + 1), value)
    self.editor:markHistoryChanged()
    self.editor:commitHistoryTransaction()
    self:refreshList(value)
end

function EditorTilesetPanel:openItemContext(item, list, x, y)
    local items
    if self.mode == "terrain" then
        local selected = item and item.data
        local terrain = selected and selected.terrain
        local variant = selected and (selected.variant or selected.rule
            and self.document:getTerrainVariant(terrain, selected.rule.terrain))
        items = {
            { label = "New Terrain Tag", action = function() self:addItem("tag") end },
            { label = "New Terrain Set", action = function() self:addItem("terrain") end },
            { label = "New Terrain Variant", is_enabled = function() return terrain ~= nil end,
                action = function() self:addItem("variant", terrain) end },
            { label = "New Tile Rule for Selected Tile",
                is_enabled = function() return variant ~= nil and self.tile ~= nil end,
                action = function() self:addItem("rule", terrain, variant) end }
        }
        local rule = selected and selected.rule
        table.insert(items, { label = "Add Condition",
            children = self:getConditionMenuItems(terrain, variant, rule),
            is_enabled = function() return rule ~= nil end })
    else
        items = { { label = "Add", action = function() self:addItem() end } }
    end
    if item then table.insert(items, { label = "Delete", action = function() self:removeItem(item.data) end }) end
    local gx, gy = list:getGlobalPosition()
    self.editor.dockspace:openContextMenu(items, gx + x, gy + y, list)
end

function EditorTilesetPanel:update(dt)
    local button_width = math.max(64, math.floor((self.width - 16) / #self.mode_buttons))
    local x = 8
    for _, button in ipairs(self.mode_buttons) do
        button:setBounds(x, 8, button_width - 4, 28)
        button.focused = self.mode == button.label:lower()
        x = x + button_width
    end
    local toolbar_y = 42
    self.zoom_out_button:setBounds(math.max(8, self.width - 148), toolbar_y, 36, 28)
    self.zoom_label_button:setBounds(math.max(48, self.width - 108), toolbar_y, 64, 28)
    self.zoom_in_button:setBounds(math.max(116, self.width - 40), toolbar_y, 36, 28)
    self.zoom_label_button.label = string.format("%d%%", MathUtils.round(self.tile_grid.zoom * 100))
    local terrain_tools = self.mode == "terrain"
    self.terrain_is_button.visible = terrain_tools
    self.terrain_not_button.visible = terrain_tools
    self.terrain_any_button.visible = terrain_tools
    if terrain_tools then
        self.terrain_is_button:setBounds(104, toolbar_y, 42, 28)
        self.terrain_not_button:setBounds(150, toolbar_y, 48, 28)
        self.terrain_any_button:setBounds(202, toolbar_y, 48, 28)
        self.terrain_is_button.focused = self.terrain_paint_mode == "is"
        self.terrain_not_button.focused = self.terrain_paint_mode == "not"
        self.terrain_any_button.focused = self.terrain_paint_mode == "any"
    end

    local atlas_y = 76
    local available_height = math.max(0, self.height - atlas_y - 4)
    local atlas_height = math.floor(available_height * 0.56)
    if available_height >= 180 then
        atlas_height = MathUtils.clamp(atlas_height, 100, available_height - 80)
    else
        atlas_height = available_height
    end
    self.tile_grid:setBounds(4, atlas_y, math.max(0, self.width - 8), atlas_height)
    local details_y = atlas_y + atlas_height + 4
    local details_height = math.max(0, self.height - details_y)
    if self.list.visible then
        local list_width = MathUtils.clamp(math.floor(self.width * 0.34), 150, math.max(150, self.width - 220))
        self.add_button:setBounds(4, details_y + 4, math.max(0, list_width - 8), 28)
        self.list:setBounds(4, details_y + 36,
            math.max(0, list_width - 8), math.max(0, details_height - 40))
        self.properties:setBounds(list_width, details_y,
            math.max(0, self.width - list_width), details_height)
    else
        self.properties:setBounds(0, details_y, self.width, details_height)
    end
    super.update(self, dt)
end

function EditorTilesetPanel:drawSelf()
    Draw.setColor(0.08, 0.08, 0.09, 1)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    Draw.setColor(0.78, 0.78, 0.82, 1)
    love.graphics.setFont(EditorFont.get(16))
    love.graphics.print("Tileset Atlas", 8, 48)
    Draw.setColor(0.30, 0.30, 0.34, 1)
    love.graphics.line(0, 38.5, self.width, 38.5)
    love.graphics.line(0, 73.5, self.width, 73.5)
    love.graphics.line(0, self.tile_grid.y + self.tile_grid.height + 2.5,
        self.width, self.tile_grid.y + self.tile_grid.height + 2.5)
    if self.list.visible then
        love.graphics.line(self.properties.x + 0.5, self.properties.y,
            self.properties.x + 0.5, self.height)
    end
end

return EditorTilesetPanel
