--- A button that either characters or [`PushBlock`s](lua://PushBlock.init) can activate. \
--- `TileButton` is an [`Event`](lua://Event.init) - naming an object `tilebutton` on an `objects` layer in a map creates this object. \
--- See this object's Fields for the configurable properties on this object.
--- 
---@class TileButton : Event
---
---@field idle_sprite       string  *[Property `sprite`]* An optional custom sprite to use for this TileButton
---@field pressed_sprite    string  *[Property `pressedsprite`]* An optional custom sprite to use for this TileButton when it is pressed down
---
---@field on_sound          string  *[Property `onsound`]* The sound file that plays when this button is pressed down
---@field off_sound         string  *[Property `offsound`]* The sound file that plays when this button stops being pressed down
---
---@field npc_activated     boolean *[Property `blocks`]* Whether this button is activated by blocks or players and npcs (Defaults to `true` - players and npcs)
---@field player_activated  boolean *[Property `blocks`]* Whether this button is activated by blocks or players and npcs (Defaults to `true` - players and npcs)
---@field block_activated   boolean *[Property `blocks`]* Whether this button is activated by blocks or players and npcs (Defaults to `false` - players and npcs)
---
---@field group             string|number *[Property `group`]* When this value is the same for mutliple tile buttons in one room, they are grouped together, and will not be marked as completed/solved until all of them are pressed simultaneously
---
---@field flag              string  *[Property `flag`]* The name of a flag to set to `true` when the button's group is solved
---@field once              boolean *[Property `once`]* Whether the tile button's puzzle can only be solved once per save file
---
---@field keep_down         boolean *[Property `keepdown`]* Whether the button should remain pressed even when the object pressing it moves away (Defaults to `false`)
---
---@field cutscene          string  *[Property `cutscene`]* The name of a cutscene that should play when the button's puzzle is solved
---@field script            string  *[Property `script`]* The name of a script file that should be executed when the button's puzzle is solved
---
---@field pressed           boolean Whether the button is currently pressed down
---
---@overload fun(...) : TileButton
local TileButton, super = Class(Event)

function TileButton:init(x, y, shape, properties, idle_sprite, pressed_sprite)
    super.init(self, x, y, shape)

    self.idle_sprite = properties["sprite"] or idle_sprite or "world/events/glowtile/idle"
    self.pressed_sprite = properties["pressedsprite"] or properties["sprite"] or pressed_sprite or idle_sprite or "world/events/glowtile/pressed"

    self:setSprite(self.idle_sprite, 5/30)
    self:setHitbox(10, 6, 20, 12)

    properties = properties or {}

    -- Options
    self.on_sound = properties["onsound"]
    self.off_sound = properties["offsound"]

    self.npc_activated = not properties["blocks"]
    self.player_activated = not properties["blocks"]
    self.block_activated = properties["blocks"] or false

    self.group = properties["group"]

    self.flag = properties["flag"]
    self.once = properties["once"]

    if properties["keepdown"] then
        self.keep_down = properties["keepdown"]
    end

    self.cutscene = properties["cutscene"]
    self.script = properties["script"]

    -- State variables
    self.pressed = false
end

function TileButton:onLoad()
    self:checkCompletion()
end

function TileButton:update()
    if self.block_activated then

        Object.startCache()
        local collided = nil
        for _,block in ipairs(Game.stage:getObjects(PushBlock)) do
            if block.press_buttons ~= false and block:collidesWith(self) then
                collided = block
                break
            end
        end
        Object.endCache()

        if self:setPressed(collided ~= nil) and self.pressed then
            collided.solved = true
            collided:onSolved()
        end
    end

    super.update(self)
end

--- Changes the pressed state of the button and checks for completion of its puzzle
---@param pressed boolean
---@return boolean
function TileButton:setPressed(pressed)
    if self.pressed == pressed then return false end

    self.pressed = pressed

    if self.pressed then
        self:onPressed()
        self:checkCompletion()
        return true
    else
        self:onReleased()
        self:checkCompletion()
        return true
    end
end

--- Called whenever the button is pressed, setting its sprite and playing the press sound
function TileButton:onPressed()
    self:setSprite(self.pressed_sprite)
    if self.on_sound and self.on_sound ~= "" then
        Assets.stopAndPlaySound(self.on_sound)
    end
end

--- Called whenever the button is released, playing its idle sprite at 6fps (`5/30` seconds speed), and playing the release sound
function TileButton:onReleased()
    self:setSprite(self.idle_sprite, 5/30)
    if self.off_sound and self.off_sound ~= "" then
        Assets.stopAndPlaySound(self.off_sound)
    end
end

--- Called to run everything that happens when the tile button puzzle is completed
function TileButton:onCompleted()
    self:setFlag("solved", true)

    if self.flag then
        Game:setFlag(self.flag, true)
    end

    if self.script then
        Registry.getEventScript(self.script)(self)
    end
    if self.cutscene then
        self.world:startCutscene(self.cutscene, self)
    end
end

--- Called to set the tile button puzzle as incomplete
function TileButton:onIncompleted()
    self:setFlag("solved", false)

    if self.flag then
        Game:setFlag(self.flag, false)
    end
end

--- Checks whether the tile button puzzle is completed and then calls [`onCompleted()`](lua://TileButton.onCompleted) or [`onIncompleted()`](lua://TileButton.onIncompleted) appropriately.
function TileButton:checkCompletion()
    if not self.group then
        if self.pressed and not self:getFlag("solved") then
            self:onCompleted()
        elseif not self.pressed and self:getFlag("solved") and not self.once then
            self:onIncompleted()
        end
    else
        local flag_id = "tile_puzzle#"..tostring(self.group)

        local was_completed = self.world.map:getFlag(flag_id)

        if self.once and was_completed then
            return
        end

        local all_pressed = true
        for _,button in ipairs(Game.stage:getObjects(TileButton)) do
            if button.group == self.group and not button.pressed then
                all_pressed = false
                break
            end
        end

        if all_pressed ~= was_completed then
            self.world.map:setFlag(flag_id, all_pressed)

            if all_pressed then
                self:onCompleted()
            else
                self:onIncompleted()
            end
        end
    end
end

function TileButton:onCollide(chara)
    if (chara.is_player and self.player_activated) or (not chara.is_player and self.npc_activated) then
        self:setPressed(true)
    end
end

function TileButton:onExit(chara)
    if ((chara.is_player and self.player_activated) or (not chara.is_player and self.npc_activated)) and not self.keep_down then
        self:setPressed(false)
    end
end

return TileButton