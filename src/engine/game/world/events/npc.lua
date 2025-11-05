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
---@field path          string  *[Property `path`]* The name of a path shape in the current map that the npc will follow.
---@field speed         number  *[Property `speed`]* The speed that the npc will move along the path specified in `path`, if defined.
---
---@field progress      number  *[Property `progress`]* The initial progress of the npc along their path, if defined, as a decimal value between 0 and 1.
---@field reverse_progress boolean
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
    self.text = TiledUtils.parsePropertyMultiList("text", properties)

    self.set_flag = properties["setflag"]
    self.set_value = properties["setvalue"]
    
    self.path = properties["path"]
    self.speed = properties["speed"] or 6

    self.progress = (properties["progress"] or 0) % 1
    self.reverse_progress = false

    self.interact_count = 0

    self.interact_buffer = (5 / 30)
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
            ---@type string|string[]
            local text = self.text
            local text_index = MathUtils.clamp(self.interact_count, 1, #text)
            if type(text[text_index]) == "table" then
                text = text[text_index]
            end
            for _, line in ipairs(text) do
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

function NPC:snapToPath()
    if self.path and self.world.map.paths[self.path] then
        local path = self.world.map.paths[self.path]

        local progress = self.progress
        if not path.closed then
            progress = Ease.inOutSine(progress, 0, 1, 1)
        end

        if path.shape == "line" then
            local dist = progress * path.length
            local current_dist = 0

            for i = 1, #path.points - 1 do
                local next_dist = MathUtils.dist(path.points[i].x, path.points[i].y, path.points[i + 1].x, path.points[i + 1].y)

                if current_dist + next_dist > dist then
                    local x = MathUtils.lerp(path.points[i].x, path.points[i + 1].x, MathUtils.clamp((dist - current_dist) / next_dist, 0, 1))
                    local y = MathUtils.lerp(path.points[i].y, path.points[i + 1].y, MathUtils.clamp((dist - current_dist) / next_dist, 0, 1))

                    if self.debug_x and self.debug_y and Kristal.DebugSystem.last_object == self then
                        x = Utils.ease(self.debug_x, x, Kristal.DebugSystem.release_timer, "outCubic")
                        y = Utils.ease(self.debug_y, y, Kristal.DebugSystem.release_timer, "outCubic")
                        if Kristal.DebugSystem.release_timer >= 1 then
                            self.debug_x = nil
                            self.debug_y = nil
                        end
                    end

                    self:moveTo(x, y)
                    break
                else
                    current_dist = current_dist + next_dist
                end
            end
        elseif path.shape == "ellipse" then
            local angle = progress * (math.pi * 2)
            local x = path.x + math.cos(angle) * path.rx
            local y = path.y + math.sin(angle) * path.ry

            if self.debug_x and self.debug_y and Kristal.DebugSystem.last_object == self then
                x = Utils.ease(self.debug_x, x, Kristal.DebugSystem.release_timer, "outCubic")
                y = Utils.ease(self.debug_y, y, Kristal.DebugSystem.release_timer, "outCubic")
                if Kristal.DebugSystem.release_timer >= 1 then
                    self.debug_x = nil
                    self.debug_y = nil
                end
            end

            self:moveTo(x, y)
        end
    end
end

function NPC:isActive()
    return not self.world.encountering_enemy and
        not self.world:hasCutscene() and
        self.world.state ~= "MENU" and
        Game.state == "OVERWORLD"
end

function NPC:update()
    if self:isActive() then
        if self.path and self.world.map.paths[self.path] then
            local path = self.world.map.paths[self.path]

            if self.reverse_progress then
                self.progress = self.progress - (self.speed / path.length) * DTMULT
            else
                self.progress = self.progress + (self.speed / path.length) * DTMULT
            end
            if path.closed then
                self.progress = self.progress % 1
            elseif self.progress > 1 or self.progress < 0 then
                self.progress = MathUtils.clamp(self.progress, 0, 1)
                self.reverse_progress = not self.reverse_progress
            end

            self:snapToPath()
        end
    end

    super.update(self)
end

return NPC
