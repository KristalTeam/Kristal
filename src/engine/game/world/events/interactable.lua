--- Interactables are Overworld objects in Kristal that activate scripts, cutscenes, or text, when interacted with. \
--- `Interactable` is an [`Event`](lua://Event.init) - naming an object `interactable` on an `objects` layer in a map creates this object. \
--- See this object's Fields for the configurable properties on this object.
---
---@class Interactable : Event
---
---@field solid     boolean *[Property `solid`]* Whether the interactable is solid
---
---@field cutscene  string *[Property `cutscene`]* The name of a cutscene to start when interacting with this object
---@field script    string *[Property `script`]* The name of a script file to execute when interacting with this object
--- *[Property `text`]* A line of text to display when interacting with this object \
--- *[Property list `text`]* Several lines of text to display when interacting with this object \
--- *[Property multi-list `text`]* Several groups of lines of text to display on sequential interactions with this object - all of `text1_i` forms the first interaction, all of `text2_i` forms the second interaction etc...
---@field text string[] 
---
---@field set_flag string   *[Property `setflag`]* The name of a flag to set the value of when interacting with this object
---@field set_value any     *[Property `setvalue`]* The value to set the flag specified by [`set_flag`](lua://Interactable.set_flag) to (Defaults to `true`)
---
---@field once boolean      *[Property `once`]* Whether this event can only be interacted with once per save file (Defaults to `false`)
---
---@field interact_count number The number of times this interactable has been interacted with on this map load
---
---@overload fun(...) : Interactable
local Interactable, super = Class(Event)

---@param x?            number
---@param y?            number
---@param shape?        { [1]: number, [2]: number, [3]: table? }
---@param properties?   table
function Interactable:init(x, y, shape, properties)
    shape = shape or { TILE_WIDTH, TILE_HEIGHT }
    super.init(self, x, y, shape)

    properties = properties or {}

    self.solid = properties["solid"] or false

    self.cutscene = properties["cutscene"]
    self.script = properties["script"]
    self.text = TiledUtils.parsePropertyMultiList("text", properties)

    self.set_flag = properties["setflag"]
    self.set_value = properties["setvalue"]

    self.once = properties["once"] or false

    self.interact_count = 0
end

function Interactable:getDebugInfo()
    local info = super.getDebugInfo(self)
    if self.cutscene then table.insert(info, "Cutscene: " .. self.cutscene) end
    if self.script then table.insert(info, "Script: " .. self.script) end
    if self.set_flag then table.insert(info, "Set Flag: " .. self.set_flag) end
    if self.set_value then table.insert(info, "Set Value: " .. self.set_value) end
    table.insert(info, "Once: " .. (self.once and "True" or "False"))
    table.insert(info, "Text length: " .. #self.text)
    return info
end

function Interactable:onAdd(parent)
    super.onAdd(self, parent)
    if self.once and self:getFlag("used_once", false) then
        self:remove()
    end
end

function Interactable:onInteract(player, dir)
    self.interact_count = self.interact_count + 1

    if self.script then
        Registry.getEventScript(self.script)(self, player, dir)
    end
    local current_cutscene
    if self.cutscene then
        current_cutscene = self.world:startCutscene(self.cutscene, self, player, dir)
    else
        current_cutscene = self.world:startCutscene(function(cutscene)
            ---@type string|string[]
            local text = self.text
            local text_index = MathUtils.clamp(self.interact_count, 1, #text)

            if type(text[text_index]) == "table" then
                text = text[text_index]
            end

            for _, line in ipairs(text) do
                cutscene:text(line)
            end
        end)
    end

    current_cutscene:after(function()
        self:onTextEnd()
    end)

    if self.set_flag then
        Game:setFlag(self.set_flag, (self.set_value == nil and true) or self.set_value)
    end

    self:setFlag("used_once", true)
    if self.once then
        self:remove()
    end

    return true
end

--- *(Override)* Called when the cutscene/text of this interactable finishes
function Interactable:onTextEnd() end

function Interactable:applyTileObject(data, map)
    local tile = map:createTileObject(data, 0, 0, self.width, self.height)

    local ox, oy = tile:getOrigin()
    self:setOrigin(ox, oy)

    tile:setPosition(ox * self.width, oy * self.height)

    self:addChild(tile)
end

return Interactable
