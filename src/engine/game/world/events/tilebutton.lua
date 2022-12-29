---@class TileButton : Event
---@overload fun(...) : TileButton
local TileButton, super = Class(Event)

function TileButton:init(x, y, w, h, properties, idle_sprite, pressed_sprite)
    super.init(self, x, y, w, h)

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

function TileButton:onPressed()
    self:setSprite(self.pressed_sprite)
    if self.on_sound and self.on_sound ~= "" then
        Assets.stopAndPlaySound(self.on_sound)
    end
end

function TileButton:onReleased()
    self:setSprite(self.idle_sprite, 5/30)
    if self.off_sound and self.off_sound ~= "" then
        Assets.stopAndPlaySound(self.off_sound)
    end
end

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

function TileButton:onIncompleted()
    self:setFlag("solved", false)

    if self.flag then
        Game:setFlag(self.flag, false)
    end
end

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