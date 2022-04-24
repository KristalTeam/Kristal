local EnemyTextbox, super = Class(Object)

function EnemyTextbox:init(text, x, y, speaker, right, style)
    super:init(self, x, y, 0, 0)

    self.layer = BATTLE_LAYERS["above_arena"] - 1

    self.font = Assets.getFont("plain")
    self.font_data = Assets.getFontData("plain")

    self.text = DialogueText("", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, "plain", "none")
    self:addChild(self.text)

    self.text_width = 1
    self.text_height = 1

    self.right = right

    self.speaker = speaker
    if self.speaker then
        self.speaker.textbox = self
    end

    self.advance_callback = nil

    self.text:registerCommand("noautoskip", function(text, node)
        Game.battle.use_textbox_timer = false
    end)

    self:setStyle(style)
    self:setText(text)
end

function EnemyTextbox:setStyle(style)
    self.bubble = style or "cyber"
    self.bubble_data = Assets.getBubbleData(self.bubble)
    self.auto = self.bubble_data["auto"] or false -- Whether the bubble automatically resizes.
    self.padding = self.bubble_data["text_padding"] or {left = 0, top = 0, right = 0, bottom = 0}
    self.text_bounds = self.bubble_data["text_bounds"] or {left = 0, top = 0, width = 0, height = 0}
    self.text_color = self.bubble_data["text_color"] or {0, 0, 0, 0}
    self.text.color = self.text_color
    if self.auto then
        self.sprites = {
            left         = Assets.getBubbleImage(self.bubble_data["sprites"]["left"        ]),
            right        = Assets.getBubbleImage(self.bubble_data["sprites"]["right"       ]),
            top          = Assets.getBubbleImage(self.bubble_data["sprites"]["top"         ]),
            bottom       = Assets.getBubbleImage(self.bubble_data["sprites"]["bottom"      ]),
            top_left     = Assets.getBubbleImage(self.bubble_data["sprites"]["top_left"    ]),
            top_right    = Assets.getBubbleImage(self.bubble_data["sprites"]["top_right"   ]),
            bottom_left  = Assets.getBubbleImage(self.bubble_data["sprites"]["bottom_left" ]),
            bottom_right = Assets.getBubbleImage(self.bubble_data["sprites"]["bottom_right"]),
            tail         = Assets.getBubbleImage(self.bubble_data["sprites"]["tail"        ]),
            fill         = Assets.getBubbleImage(self.bubble_data["sprites"]["fill"        ])
        }
    else
        self.sprites = Assets.getBubbleImage(self.bubble_data["sprites"])
    end

    self.text.x = self.text_bounds["left"] or 0
    self.text.y = self.text_bounds["top"]  or 0
    if not self.auto then
        self.text.width  = self.text_bounds["width"]  or SCREEN_WIDTH
        self.text.height = self.text_bounds["height"] or SCREEN_HEIGHT
    end

    if self.right then
        self:setOrigin(0, 0.5)
        if self.auto then
            local left_width, _ = self:getSpriteSize("left")
            self.text.x = self:getTailWidth() + self.padding["left"] + left_width + 1
        end
    else
        self:setOrigin(1, 0.5)
    end
end

function EnemyTextbox:onRemoveFromStage(stage)
    super:onRemoveFromStage(self, stage)
    if self.speaker and self.speaker.textbox == self then
        self.speaker.textbox = nil
    end
end

function EnemyTextbox:advance()
    self.text:advance()
end

function EnemyTextbox:setText(text, callback)
    self.text:setText(text, callback or self.advance_callback)

    self:updateSize()
end

function EnemyTextbox:setAuto(auto)
    self.text.auto_advance = auto or false
end

function EnemyTextbox:setAdvance(advance)
    self.text.can_advance = advance or false
end

function EnemyTextbox:setSkippable(skippable)
    self.text.skippable = skippable or false
end

function EnemyTextbox:setCallback(callback)
    self.advance_callback = callback
    self.text.advance_callback = callback
end

function EnemyTextbox:isTyping()
    return self.text:isTyping()
end

function EnemyTextbox:isDone()
    return self.text:isDone()
end

function EnemyTextbox:update()
    super:update(self)

    self:updateSize()
end

function EnemyTextbox:getBorder()
    -- Lua is a bad language
    local left,  _      = self:getSpriteSize("left")
    local _,     top    = self:getSpriteSize("top")
    local right, _      = self:getSpriteSize("right")
    local _,     bottom = self:getSpriteSize("bottom")
    return left, top, right, bottom
end

function EnemyTextbox:getSpriteSize(name)
    if self.sprites[name] then
        return self.sprites[name]:getWidth(), self.sprites[name]:getHeight()
    end
    return 0, 0
end

function EnemyTextbox:getTailWidth()
    local tail_width, _ = self:getSpriteSize("tail")
    return tail_width
end

function EnemyTextbox:updateSize()
    local parsed = self.text.display_text

    local _,lines = parsed:gsub("\n", "")

    local w = self.font:getWidth(parsed)
    local h = self.font_data["lineSpacing"] * (lines + 1) - (self.font_data["lineSpacing"] - self.font:getHeight())

    self.text_width = w
    self.text_height = h

    local right_width, _ = self:getSpriteSize("right")
    self.width = w + self:getTailWidth() + right_width + self.padding["right"]
    self.height = h
end

function EnemyTextbox:draw()
    if not self.auto then
        love.graphics.draw(self.sprites, 0, 0)
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

        if self.sprites["fill"  ] then love.graphics.draw(self.sprites["fill"  ], offset + inner_left, inner_top, 0, inner_width / self.sprites["fill"]:getWidth(), inner_height / self.sprites["fill"]:getHeight()) end


        if self.sprites["left"  ] then love.graphics.draw(self.sprites["left"  ], offset + inner_left - self.sprites["left"]:getWidth(), inner_top, 0, 1, inner_height / self.sprites["left"]:getHeight()) end
        if self.sprites["top"   ] then love.graphics.draw(self.sprites["top"   ], offset + inner_left,  inner_top - self.sprites["top"]:getHeight(), 0, inner_width / self.sprites["top"]:getWidth(), 1)   end
        if self.sprites["right" ] then love.graphics.draw(self.sprites["right" ], offset + inner_right, inner_top, 0, 1, inner_height / self.sprites["right"]:getHeight())                                 end
        if self.sprites["bottom"] then love.graphics.draw(self.sprites["bottom"], offset + inner_left,  inner_bottom, 0, inner_width / self.sprites["bottom"]:getWidth(), 1)                               end

        if self.sprites["top_left"    ] then love.graphics.draw(self.sprites["top_left"    ], offset + inner_left - self.sprites["top_left"    ]:getWidth(), inner_top - self.sprites["top_left"]:getHeight()) end
        if self.sprites["top_right"   ] then love.graphics.draw(self.sprites["top_right"   ], offset + inner_right,                                          inner_top - self.sprites["top_left"]:getHeight()) end
        if self.sprites["bottom_left" ] then love.graphics.draw(self.sprites["bottom_left" ], offset + inner_left - self.sprites["bottom_left" ]:getWidth(), inner_bottom                                    ) end
        if self.sprites["bottom_right"] then love.graphics.draw(self.sprites["bottom_right"], offset + inner_right,                                          inner_bottom                                    ) end

        local scale = 1
        if self.text.height < 35 then
            scale = 0.5
        end

        if self.sprites["tail"] then
            if not self.right then
                local right, _ = self:getSpriteSize("right")
                love.graphics.draw(self.sprites["tail"], inner_right + right, (self.text_height / 2 - 1 - (self.sprites["tail"]:getHeight() / 2)) * scale, 0, 1, scale)
            else
                local left, _ = self:getSpriteSize("left")
                love.graphics.draw(self.sprites["tail"], offset + inner_left - left, (self.text_height / 2 - 1 - (self.sprites["tail"]:getHeight() / 2)) * scale, 0, -1, scale)
            end
        end
    end

    super:draw(self)
end

return EnemyTextbox