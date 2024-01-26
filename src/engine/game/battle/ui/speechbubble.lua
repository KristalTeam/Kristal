---@class SpeechBubble : Object
---@overload fun(...) : SpeechBubble
local SpeechBubble, super = Class(Object)

function SpeechBubble:init(text, x, y, options, speaker)
    super.init(self, x, y, 0, 0)
    options = options or {}

    self.layer = BATTLE_LAYERS["above_arena"] - 1

    self.text = DialogueText("", 0, 0, 1, 1, {
        font = options["font"] or "plain",
        style = "none",
        line_offset = 0,
    })
    self:addChild(self.text)

    self.text_width = 1
    self.text_height = 1

    self.right = options["right"]

    self.speaker = speaker
    self.actor = options["actor"]
    if type(self.actor) == "string" then
        self.actor = Registry.createActor(self.actor)
    end
    if self.speaker then
        self.actor = self.speaker.actor
        self.speaker.bubble = self
    end

    self:setCallback(options["after"])
    self:setLineCallback(options["line_callback"])

    self.text:registerCommand("noautoskip", function(text, node)
        Game.battle.use_textbox_timer = false
    end)

    self:setStyle(options["style"])
    self:setText(text)
end

function SpeechBubble:setStyle(style)
    self.bubble = style or Game:getConfig("speechBubble")
    self.bubble_data = Assets.getBubbleData(self.bubble)
    self.auto = self.bubble_data["auto"] or false -- Whether the bubble automatically resizes.
    self.padding = self.bubble_data["text_padding"] or {left = 0, top = 0, right = 0, bottom = 0}
    self.text_bounds = self.bubble_data["text_bounds"] or {left = 0, top = 0, width = 0, height = 0}
    self.text_color = self.bubble_data["text_color"] or {0, 0, 0, 1}
    self.bubble_speed = self.bubble_data["speed"] or 0.5
    self.bubble_anim_timer = 0
    self.text:setTextColor(unpack(self.text_color))
    if self.auto then
        self.sprites = {
            left         = self.bubble_data["sprites"]["left"        ] and Assets.getFramesOrTexture("bubbles/"..self.bubble_data["sprites"]["left"        ]),
            right        = self.bubble_data["sprites"]["right"       ] and Assets.getFramesOrTexture("bubbles/"..self.bubble_data["sprites"]["right"       ]),
            top          = self.bubble_data["sprites"]["top"         ] and Assets.getFramesOrTexture("bubbles/"..self.bubble_data["sprites"]["top"         ]),
            bottom       = self.bubble_data["sprites"]["bottom"      ] and Assets.getFramesOrTexture("bubbles/"..self.bubble_data["sprites"]["bottom"      ]),
            top_left     = self.bubble_data["sprites"]["top_left"    ] and Assets.getFramesOrTexture("bubbles/"..self.bubble_data["sprites"]["top_left"    ]),
            top_right    = self.bubble_data["sprites"]["top_right"   ] and Assets.getFramesOrTexture("bubbles/"..self.bubble_data["sprites"]["top_right"   ]),
            bottom_left  = self.bubble_data["sprites"]["bottom_left" ] and Assets.getFramesOrTexture("bubbles/"..self.bubble_data["sprites"]["bottom_left" ]),
            bottom_right = self.bubble_data["sprites"]["bottom_right"] and Assets.getFramesOrTexture("bubbles/"..self.bubble_data["sprites"]["bottom_right"]),
            tail         = self.bubble_data["sprites"]["tail"        ] and Assets.getFramesOrTexture("bubbles/"..self.bubble_data["sprites"]["tail"        ]),
            fill         = self.bubble_data["sprites"]["fill"        ] and Assets.getFramesOrTexture("bubbles/"..self.bubble_data["sprites"]["fill"        ])
        }
    else
        self.sprites = self.bubble_data["sprites"] and Assets.getFramesOrTexture("bubbles/"..self.bubble_data["sprites"])
    end

    self.text.x = self.text_bounds["left"] or 0
    self.text.y = self.text_bounds["top"]  or 0
    if not self.auto then
        self.text.width  = self.text_bounds["width"]  or SCREEN_WIDTH
        self.text.height = self.text_bounds["height"] or SCREEN_HEIGHT
        self.text.wrap = true
        self.text.auto_size = false
    else
        self.text.wrap = false
        self.text.auto_size = true
    end

    if self.bubble_data["origin"] then
        self:setOrigin(self.bubble_data["origin"][1], self.bubble_data["origin"][2])
    elseif self.right then
        self:setOrigin(0, 0.5)
    else
        self:setOrigin(1, 0.5)
    end

    if self.right and self.auto then
        local left_width, _ = self:getSpriteSize("left")
        self.text.x = self:getTailWidth() + self.padding["left"] + left_width + 1
    end

    self:updateSize()
end

function SpeechBubble:onRemoveFromStage(stage)
    super.onRemoveFromStage(self, stage)
    if self.speaker and self.speaker.bubble == self then
        self.speaker.bubble = nil
    end
end

function SpeechBubble:advance()
    self.text:advance()
end

function SpeechBubble:setText(text, callback, line_callback)
    if self.actor then
        if self.actor:getVoice() then
            if type(text) ~= "table" then
                text = {text}
            else
                text = Utils.copy(text)
            end
            for i,line in ipairs(text or {}) do
                text[i] = "[voice:"..self.actor:getVoice().."]"..line
            end
        end
        if self.actor:getFont() then
            if type(text) ~= "table" then
                text = {text}
            else
                text = Utils.copy(text)
            end
            for i,line in ipairs(text or {}) do
                if self.actor:getSpeechBubbleFontSize() then
                    text[i] = "[font:"..self.actor:getFont()..","..self.actor:getSpeechBubbleFontSize().."]"..line
                else
                    text[i] = "[font:"..self.actor:getFont().."]"..line
                end
            end
        end
    end
    
    self.text:setText(text, callback or self.advance_callback, line_callback or self.line_callback)

    self:updateSize()
end

function SpeechBubble:setAuto(auto)
    self.text.auto_advance = auto or false
end

function SpeechBubble:setAdvance(advance)
    self.text.can_advance = advance or false
end

function SpeechBubble:setSkippable(skippable)
    self.text.skippable = skippable or false
end

function SpeechBubble:setCallback(callback)
    self.advance_callback = callback
    self.text.advance_callback = callback
end

function SpeechBubble:setLineCallback(callback)
    self.line_callback = callback
    self.text.line_callback = callback
end

function SpeechBubble:setRight(right)
    self.right = right
    if not self.bubble_data["origin"] then
        if self.right then
            self:setOrigin(0, 0.5)
        else
            self:setOrigin(1, 0.5)
        end
    end
    self.text.x = self.text_bounds["left"] or 0
    self.text.y = self.text_bounds["top"]  or 0
    if self.right and self.auto then
        local left_width, _ = self:getSpriteSize("left")
        self.text.x = self:getTailWidth() + self.padding["left"] + left_width + 1
    end
    self:updateSize()
end

function SpeechBubble:isTyping()
    return self.text:isTyping()
end

function SpeechBubble:isDone()
    return self.text:isDone()
end

function SpeechBubble:update()
    super.update(self)

    self.bubble_anim_timer = self.bubble_anim_timer + DT

    self:updateSize()
end

function SpeechBubble:getBorder()
    -- Lua is a bad language
    local left,  _      = self:getSpriteSize("left")
    local _,     top    = self:getSpriteSize("top")
    local right, _      = self:getSpriteSize("right")
    local _,     bottom = self:getSpriteSize("bottom")
    return left, top, right, bottom
end

function SpeechBubble:getDebugRectangle()
    if not self.debug_rect then
        local bl, bt, br, bb = self:getBorder()

        local inner_left = -self.padding["left"]
        local inner_top = -self.padding["top"]
        local inner_right = self.text_width + self.padding["right"]
        local inner_bottom = self.text_height + self.padding["bottom"]

        local inner_width = self.padding["left"] + inner_right
        local inner_height = self.padding["top"] + inner_bottom

        -- TODO: FUck
        return {-bl + inner_left, -bt + inner_top, inner_width + bl + br + self:getTailWidth(), inner_height + bt + bb}
    end
    return super.getDebugRectangle(self)
end

function SpeechBubble:getSprite(name)
    local sprite = self.auto and self.sprites[name] or self.sprites
    if sprite then
        local frame = math.floor(self.bubble_anim_timer / self.bubble_speed)

        return sprite[(frame % #sprite) + 1]
    end
end

function SpeechBubble:getSpriteSize(name)
    local sprite = self:getSprite(name)
    if sprite then
        return sprite:getWidth(), sprite:getHeight()
    end
    return 0, 0
end

function SpeechBubble:getTailWidth()
    local tail_width, _ = self:getSpriteSize("tail")
    return tail_width
end

function SpeechBubble:updateSize()
    if self.auto then
        local w, h = self.text:getTextWidth(), self.text:getTextHeight()

        self.text_width = w
        self.text_height = h

        local right_width, _ = self:getSpriteSize("right")
        self.width = w + self:getTailWidth() + right_width + self.padding["right"]
        self.height = h
    else
        self:setSize(self:getSpriteSize())
    end
end

function SpeechBubble:draw()
    if not self.auto then
        Draw.draw(self:getSprite(), 0, 0)
    else
        local inner_left = -self.padding["left"]
        local inner_top = -self.padding["top"]
        local inner_right = self.text_width + self.padding["right"]
        local inner_bottom = self.text_height + self.padding["bottom"]

        local inner_width = self.padding["left"] + inner_right
        local inner_height = self.padding["top"] + inner_bottom

        local offset = 0
        if self.right then
            local left_width, _ = self:getSpriteSize("left")
            offset = self:getTailWidth() + self.padding["left"] + left_width + 1
        end


        local sprite_fill = self:getSprite("fill")
        local sprite_tail = self:getSprite("tail")

        local sprite_left   = self:getSprite("left"  )
        local sprite_top    = self:getSprite("top"   )
        local sprite_right  = self:getSprite("right" )
        local sprite_bottom = self:getSprite("bottom")

        local sprite_top_left     = self:getSprite("top_left"    )
        local sprite_top_right    = self:getSprite("top_right"   )
        local sprite_bottom_left  = self:getSprite("bottom_left" )
        local sprite_bottom_right = self:getSprite("bottom_right")


        if sprite_fill then Draw.draw(sprite_fill, offset + inner_left, inner_top, 0, inner_width / sprite_fill:getWidth(), inner_height / sprite_fill:getHeight()) end

        if sprite_left   then Draw.draw(sprite_left,   offset + inner_left - sprite_left:getWidth(), inner_top,                          0, 1,                                      inner_height / sprite_left:getHeight())  end
        if sprite_top    then Draw.draw(sprite_top,    offset + inner_left,                          inner_top - sprite_top:getHeight(), 0, inner_width / sprite_top:getWidth(),    1)                                       end
        if sprite_right  then Draw.draw(sprite_right,  offset + inner_right,                         inner_top,                          0, 1,                                      inner_height / sprite_right:getHeight()) end
        if sprite_bottom then Draw.draw(sprite_bottom, offset + inner_left,                          inner_bottom,                       0, inner_width / sprite_bottom:getWidth(), 1)                                       end

        if sprite_top_left     then Draw.draw(sprite_top_left,     offset + inner_left - sprite_top_left:getWidth(),    inner_top - sprite_top_left:getHeight())  end
        if sprite_top_right    then Draw.draw(sprite_top_right,    offset + inner_right,                                inner_top - sprite_top_right:getHeight()) end
        if sprite_bottom_left  then Draw.draw(sprite_bottom_left,  offset + inner_left - sprite_bottom_left:getWidth(), inner_bottom)                             end
        if sprite_bottom_right then Draw.draw(sprite_bottom_right, offset + inner_right,                                inner_bottom)                             end

        local scale = 1
        if self.text.height < 35 then
            scale = 0.5
        end

        if sprite_tail then
            if not self.right then
                local right, _ = self:getSpriteSize("right")
                Draw.draw(sprite_tail, inner_right + right, (self.text_height / 2 - 1 - (sprite_tail:getHeight() / 2)) * scale, 0, 1, scale)
            else
                local left, _ = self:getSpriteSize("left")
                Draw.draw(sprite_tail, offset + inner_left - left, (self.text_height / 2 - 1 - (sprite_tail:getHeight() / 2)) * scale, 0, -1, scale)
            end
        end
    end

    super.draw(self)
end

return SpeechBubble