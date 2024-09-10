--- NPCs are an extension of Character that provide the ability to use them in the Overworld similar to an `Event`. \
--- Naming an object `npc` on an `objects` layer in a map creates an NPC. \
--- The actor used for an NPC can be set by defining an `actor` property and setting it to the id of the desired actor. \
--- See this object's Fields for other configurable properties on this object.
--- 
---@class NPC : Character
---
---@field idle_sprite string *[Property `sprite`]* The name of the sprite this NPC should use when idle
---@field idle_animation string *[Property `animation`]* The name of the animation this NPC should use when idle
---
---@field start_facing string *[Property `facing`]* The direction the npc should be facing by default (Defaults to `"down"`)
---
---@field turn boolean *[Property `turn`]* Whether the NPC should turn to face the player when interacted with (Defaults to `false`)
---
---@field talk boolean *[Property `talk`]* Whether the npc should do a talking animation when interacted with and currently typing dialogue (Defaults to `true`)
---@field talk_sprite string *[Property `talksprite`]* The name of a talk sprite to use for the NPC when talking
---
---@field solid boolean *[Property `solid`]* Whether the npc is solid (Defaults to `true`)
---
---@field cutscene  string *[Property `cutscene`]* The name of a cutscene to start when interacting with this npc
---@field script    string *[Property `script`]* The name of a script file to execute when interacting with this npc
--- *[Property `text`]* A line of text to display when interacting with this npc \
--- *[Property list `text`]* Several lines of text to display when interacting with this npc \
--- *[Property multi-list `text`]* Several groups of lines of text to display on sequential interactions with this npc - all of `text1_i` forms the first interaction, all of `text2_i` forms the second interaction etc...
---@field text string[] 
---
---@field set_flag string   *[Property `setflag`]* The name of a flag to set the value of when interacting with this object
---@field set_value any     *[Property `setvalue`]* The value to set the flag specified by [`set_flag`](lua://Interactable.set_flag) to (Defaults to `true`)
---
---@field interact_count number The number of times this npc has been interacted with on this map load
---
---@field interact_buffer number
---
---@overload fun(...) : NPC
local NPC, super = Class(Character)

function NPC:init(actor, x, y, properties)
    super.init(self, actor, x, y)

    properties = properties or {}

    if properties["sprite"] then
        self.idle_sprite = properties["sprite"]
        self.sprite:setSprite(properties["sprite"])
    elseif properties["animation"] then
        self.idle_animation = properties["animation"]
        self.sprite:setAnimation(properties["animation"])
    end

    self.start_facing = properties["facing"] or "down"

    if properties["facing"] then
        self:setFacing(properties["facing"])
    end

    self.turn = properties["turn"] or false

    self.talk = properties["talk"] ~= false
    self.talk_sprite = properties["talksprite"]

    self.solid = properties["solid"] == nil or properties["solid"]

    self.cutscene = properties["cutscene"]
    self.script = properties["script"]
    self.text = Utils.parsePropertyMultiList("text", properties)

    self.set_flag = properties["setflag"]
    self.set_value = properties["setvalue"]

    self.interact_count = 0

    self.interact_buffer = (5/30)
end

function NPC:onInteract(player, dir)
    if self.talk_sprite then
        self:setSprite(self.talk_sprite)
    end
    if self.turn then
        self:facePlayer()
    end
    self.interact_count = self.interact_count + 1

    if self.script then
        Registry.getEventScript(self.script)(self, player, dir)
    end
    if self.set_flag then
        Game:setFlag(self.set_flag, (self.set_value == nil and true) or self.set_value)
    end
    if self.cutscene then
        self.world:startCutscene(self.cutscene, self, player, dir):after(function()
            self:onTextEnd()
        end)
        return true
    elseif #self.text > 0 then
        self.world:startCutscene(function(cutscene)
            cutscene:setSpeaker(self, self.talk)
            local text = self.text
            local text_index = Utils.clamp(self.interact_count, 1, #text)
            if type(text[text_index]) == "table" then
                text = text[text_index]
            end
            for _,line in ipairs(text) do
                cutscene:text(line)
            end
        end):after(function()
            self:onTextEnd()
        end)
        return true
    end
end

--- Resets the NPCs sprite to it's idle if it was talking, and turns it to face its original position
function NPC:onTextEnd()
    if self.talk_sprite then
        if self.idle_sprite then
            self.sprite:setSprite(self.idle_sprite)
        elseif self.idle_animation then
            self.sprite:setAnimation(self.idle_animation)
        elseif self.actor:getDefaultSprite() then
            self.sprite:setSprite(self.actor:getDefaultSprite())
        elseif self.actor:getDefaultAnim() then
            self.sprite:setAnimation(self.actor:getDefaultAnim())
        elseif self.actor:getDefault() then
            self.sprite:set(self.actor:getDefault())
        end
    end
    if self.turn then
        self:setFacing(self.start_facing)
    end
end

return NPC