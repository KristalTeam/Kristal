---@class DarkTransition : Object
---@overload fun(...) : DarkTransition
local DarkTransition, super = Class(Object)

function DarkTransition:init(final_y, options)
    super.init(self)

    options = options or {}

    self.persistent = true

    self:setScale(2, 2)
    self:setParallax(0, 0)

    self.loading_callback = nil
    self.land_callback = nil
    self.end_callback = nil

    Kristal.hideBorder(1)

    self.con = 8
    self.timer = 0
    self.index = 0
    self.velocity = 0
    self.friction = 0


    local default_characters = {}

    for _, character in ipairs(Game.party) do
        table.insert(default_characters, Game.world:getPartyCharacterInParty(character))
    end

    self.characters = options["characters"] or default_characters
    self.character_data = {}

    for i, character in ipairs(self.characters) do
        local x, y = character:localToScreenPos(0, 0)
        x = x / 2
        y = y / 2
        local movement = (options["movement_table"] or {1, -1})[i] or 0
        local sprite_holder = self:addChild(Object(x, y))
        local data = {
            x = x,
            y = y,
            movement = movement,
            remx = 0,
            remy = 0,
            character = character,
            party = character:getPartyMember(),
            sprite_holder = sprite_holder,
            sprite_1 = sprite_holder:addChild(ActorSprite(character.actor)),
            sprite_2 = sprite_holder:addChild(ActorSprite(character.actor)),
            sprite_3 = sprite_holder:addChild(ActorSprite(character.actor))
        }
        data.sprite_1.visible = false
        data.sprite_2.visible = false
        data.sprite_3.visible = false
        table.insert(self.character_data, data)
    end

    --self.kris_x = options["kris_x"] or 134
    --self.kris_y = options["kris_y"] or 94
    --self.susie_x = options["susie_x"] or 162
    --self.susie_y = options["susie_y"] or 86

    self.sprite_index = 0
    self.linecon = false
    self.linetimer = 0
    self.rect_draw = 0
    self.fake_screenshake = 0
    self.fake_shakeamount = 0
    self.rx1 = 138
    self.ry1 = 64
    self.rx2 = 182
    self.ry2 = 118
    self.soundtimer = 0
    self.soundcon = 0
    self.linesfxtimer = 0
    self.megablack = false

    -- CONFIG
    self.quick_mode = options["quick_mode"]
    self.skiprunback = options["skiprunback"]
    self.has_head_object = options["has_head_object"]

    if self.quick_mode == nil then self.quick_mode = false end
    if self.skiprunback == nil then self.skiprunback = false end
    if self.has_head_object == nil then self.has_head_object = false end

    self.final_y               = final_y or (SCREEN_HEIGHT / 2)
    self.sparkles              = options["sparkles"] or 0
    self.sparestar             = Assets.getFrames("effects/spare/star")
    self.dtrans_square         = Assets.newSound("dtrans_square")
    self.head_object_sprite    = Assets.getTexture(options["head_object_sprite"] or "misc/trash_ball")

    -- Sprite stuff
    self.use_sprite_index      = false

    if self.has_head_object then
        self.kris_head_object = HeadObject(
            self.head_object_sprite,
            options["head_object_off_x"] + 14 - (self.head_object_sprite:getWidth() / 2),
            options["head_object_off_y"] + -2 - (self.head_object_sprite:getHeight() / 2)
        )
        self.kris_head_object.sparkles = options["head_object_sparkles"] or 30
        self.kris_head_object.visible = true
        self.character_data[1].sprite_holder:addChild(self.kris_head_object)
    end

    -- Some nice hacks for deltatime support, since toby is very weird with cutscenes.
    self.do_once = false
    self.do_once2 = false
    self.do_once3 = false
    self.do_once4 = false
    self.do_once5 = false
    self.do_once6 = false
    self.do_once7 = false
    self.do_once8 = false
    self.do_once9 = false
    self.do_once10 = false
    self.do_once11 = false
    self.do_once12 = false
    self.do_once13 = false

    self.drone_get_louder = false
    self.dronesfx_volume = 0

    self.black_fade = 1
    self.particle_timer = 1
end

function DarkTransition:onAddToStage(stage)
    for _, music in ipairs(Music.getPlaying()) do
        music:fade(0, 20 / 30)
    end
end

function DarkTransition:drawDoor(x, y, xscale, yscale, rot, color)
    local sprite = Assets.getTexture("kristal/doorblack")
    Draw.setColor(color)
    Draw.draw(sprite, x, y, rot, xscale, yscale, sprite:getWidth() / 2, sprite:getHeight() / 2)
end

function DarkTransition:update()
    super.update(self)

    -- Process audio fading
    if self.drone_get_louder then
        self.dronesfx_volume = self.dronesfx_volume + (DT / 4)
        if self.dronesfx_volume > 0.5 then
            self.dronesfx_volume = 0.5
            self.drone_get_louder = false
        end
        self.dronesfx:setVolume(self.dronesfx_volume)
    end
    if self.soundcon == 4 then
        -- self.dronesfx needs to fade out from 0.5 to 0, taking 1 second
        if self.dronesfx_volume < 0 then
            self.dronesfx:stop()
        else
            self.dronesfx_volume = self.dronesfx_volume - (DT / 2)
            self.dronesfx:setVolume(self.dronesfx_volume)
        end
    end

    if self.linecon then
        self.linetimer = self.linetimer + 1 * DTMULT
        if (self.linetimer >= 1) then
            local xrand  = math.random() * (math.pi / 2)
            local xrand2 = math.random() * (math.pi / 2)

            local x      = (70 - (math.sin(xrand) * 70))
            local x2     = (250 + (math.sin(xrand2) * 70))

            self:addChild(DarkTransitionLine(x))
            self:addChild(DarkTransitionLine(x2))

            self.linetimer = 0
        end
        self.linesfxtimer = self.linesfxtimer + (1 * DTMULT)
        if (self.linesfxtimer >= 4) then
            self.linesfxtimer = 0

            Assets.playSound("dtrans_twinkle", 0.3, 0.6 + (math.random() * 0.6))
        end
    end
    if (self.friction ~= 0) then
        if (self.velocity > 0) then
            self.velocity = self.velocity - self.friction * DTMULT
            if (self.velocity < 0) then
                self.velocity = 0
            end
        end
        if (self.velocity < 0) then
            self.velocity = self.velocity + self.friction * DTMULT
            if (self.velocity > 0) then
                self.velocity = 0
            end
        end
    end
    if (self.velocity ~= 0) then
        for _, data in ipairs(self.character_data) do
            data.y = data.y + self.velocity * DTMULT
        end
    end
    if (self.fake_screenshake == 1) then
        self.shaketimer = self.shaketimer + DTMULT
        if (self.fake_shakeamount ~= 0) then
            while (self.shaketimer > 1) do

                if (self.fake_shakeamount > 0) then
                    self.fake_shakeamount = self.fake_shakeamount - 1
                end
                if (self.fake_shakeamount < 0) then
                    self.fake_shakeamount = self.fake_shakeamount + 1
                end

                self.shaketimer = self.shaketimer - 1
                self.fake_shakeamount = self.fake_shakeamount * -1
            end
        else
            self.fake_screenshake = 0
        end
    end
end

function DarkTransition:draw()
    -- Draw a background cover.
    -- In Deltarune, this is a 999x999 black marker.
    if self.megablack then
        Draw.setColor(0, 0, 0, self.black_fade)
        love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2)
        Draw.setColor(1, 1, 1)
    end

    self.index = self.index + 1 * DTMULT
    if (self.rect_draw == 1) then
        self.rs = self.rs + 1 * DTMULT
        for i = 1, self.rect_amount do
            self.rsize[i] = self.rsize[i] + (0.25 * DTMULT)
            if (self.quick_mode) then
                self.rsize[i] = self.rsize[i] + (0.25 * DTMULT)
            end
            if (self.rsize[i] > 0) then
                local r_darkest = (5 - (self.rsize[i] * 0.8))
                if (self.rs < 20) then
                    r_darkest = r_darkest * (self.rs / 20)
                end
                if (r_darkest < 0) then
                    r_darkest = 0
                end
                if (r_darkest > 1) then
                    r_darkest = 1
                end

                local r_color = { r_darkest, r_darkest, r_darkest, 1 }

                self:drawDoor(self.rx, self.ry, (self.rw * self.rsize[i]), (self.rh * self.rsize[i]),
                    -math.rad(self.rsize[i]), r_color)
            end
        end
    end
    if (self.con == 8) then
        Game.world.music:fade(0, 1)
        --mus_volume(global.currentsong[1], 0, 30)
        --with (obj_mainchara)
        --    cutscene = true
        --with (obj_kris_headobj)
        --{
        --    follow = 0
        --    depth = (obj_dw_transition.depth - 10)
        --end

        -- sprite code --
        self.use_sprite_index = true

        for _, data in ipairs(self.character_data) do
            data.sprite_1.visible = true
            data.sprite_1:set("walk/up")
        end

        self.sprite_index = 0
        self.kris_index = 0
        self.velocity = 1.2
        if (self.quick_mode) then
            self.velocity = 2
        end
        self.timer = 0
        self.con = 9
        self.doorblack = 0
    end
    if (self.con == 9) then
        self.timer = self.timer + 1 * DTMULT
        if (self.quick_mode or self.skiprunback) then
            if (self.timer < 40) then
                --snd_free_all()
                if (not self.skiprunback) then
                    --snd_play(snd_locker)
                    Assets.playSound("locker")

                    self.doorblack = 1
                end
                self.velocity = 6
                self.friction = 0.4
                self.timer = 45
                self.do_once = true -- Ugly deltatime hack: skip self.timer == 30

                -- TODO: offset...
                --self.kris_x = self.kris_x - 4 * DTMULT

                for _, data in ipairs(self.character_data) do
                    data.sprite_1.visible = true
                    data.sprite_1:set("walk/up")
                end

            end
        end
        if (self.timer < 30) then
            self.sprite_index = self.sprite_index + 0.2 * DTMULT
        end
        if (math.floor(self.timer) >= 30) and not self.do_once then
            --snd_free_all()
            for _, data in ipairs(self.character_data) do
                data.sprite_1:stop()
            end
            self.do_once = true
            Assets.playSound("locker")
            -- Destroy the dark door object here...
            self.doorblack = 1
            self.sprite_index = 0
            self.velocity = 0

            -- TODO: offset...
            --self.kris_x = self.kris_x - 4

            for _, data in ipairs(self.character_data) do
                data.sprite_1:setActor(data.party:getDarkTransitionActor())
                data.sprite_2:setActor(data.party:getDarkTransitionActor())
                data.sprite_3:setActor(data.party:getDarkTransitionActor())
                data.sprite_1:set("run")
            end
        end
        if (math.floor(self.timer) >= 60) and not self.do_once2 then
            self.do_once2 = true
            self.velocity = -5
            self.friction = 0

            for _, data in ipairs(self.character_data) do
                data.sprite_1:setActor(data.party:getDarkTransitionActor())
                data.sprite_2:setActor(data.party:getDarkTransitionActor())
                data.sprite_3:setActor(data.party:getDarkTransitionActor())
                data.sprite_1:set("run")
            end
        end
        if (self.timer > 60 and self.timer < 68) then
            -- TODO: Huh??
            for _, data in ipairs(self.character_data) do
                data.y = data.y - 1 * DTMULT
            end
            --self.kris_y = self.kris_y - 1 * DTMULT -- ??????????????
            self.sprite_index = self.sprite_index + 0.25 * DTMULT
        end
        if (math.floor(self.timer) >= 68) and not self.do_once3 then
            self.do_once3 = true
            self.friction = 0.15
            self.velocity = -4
            -- TODO: offset...
            --self.susie_y = self.susie_y - 2
            --self.susie_x = self.susie_x - 2
            self.con = 15
            self.soundtimer = 0

            for _, data in ipairs(self.character_data) do
                data.sprite_1.visible = true
                data.sprite_1:set("forward")
            end
        end
        if (self.doorblack == 1) then
            Draw.setColor(0, 0, 0, 1)
            local x1 = self.rx1
            local y1 = self.ry1
            local x2 = self.rx2
            local y2 = self.ry2
            local w = x2 - x1
            local h = y2 - y1
            love.graphics.rectangle("fill", x1, y1, w, h)
            --self:draw_rectangle((self.rx1 + self:camerax()), (self.ry1 + self:cameray()), (self.rx2 + self:camerax()), (self.ry2 + self:cameray()), false)
        end
    end
    if (self.con == 15) then
        self.rs = 0
        self.rh = ((self.ry2 - self.ry1) / 100)
        self.rw = ((self.rx2 - self.rx1) / 100)
        self.rx = ((self.rx1 + self.rx2) / 2)
        self.ry = ((self.ry1 + self.ry2) / 2)
        self.rsize = {}
        for i = 1, 8 do
            self.rsize[i] = (1 + ((i - 1) * -2))
        end
        self.rect_amount = 6
        self.rect_draw = 1
        self.timer = 0
        if (self.quick_mode) then
            self.rect_amount = 3
        end
        self.con = 16
        self.soundtimer = 3
        self.rectsound = 0
    end
    if (self.con == 16) then
        self.soundthreshold = 6
        if (self.quick_mode) then
            self.soundthreshold = 3
        end
        self.soundtimer = self.soundtimer + 1 * DTMULT
        if ((self.soundtimer >= self.soundthreshold) and (self.rectsound < self.rect_amount)) then
            self.soundtimer = 0
            self.dtrans_square:stop()
            self.dtrans_square:setVolume(0.5)
            self.dtrans_square:play()
            self.rectsound = self.rectsound + 1
        end
        self.sprite_index = self.sprite_index + 0.25 * DTMULT
        if (self.velocity >= 0) then
            self.friction = 0
            self.velocity = self.velocity + 0.005 * DTMULT
        end
        self.timer = self.timer + 1 * DTMULT
        self.threshold = 80
        if (self.quick_mode) then
            self.threshold = 30
        end
        if (self.timer >= self.threshold) then
            self.timer = 0
            self.con = 17
            self.sprite_index = 0
        end
    end
    if (self.con == 17) then
        self.draw_rect = 0
        self.linecon = true

        for _, data in ipairs(self.character_data) do
            data.x_current = data.x
        end

        self.con = 18
        self.soundcon = 1
        self.radius = 60

        for _, data in ipairs(self.character_data) do
            data.sprite_1.visible = true
            data.sprite_1:set("turn")
        end
    end
    if (self.soundcon == 1) then
        self.dronesfx = Assets.newSound("dtrans_drone")

        -- Volume starts at 0 and goes to 0.5 over 60 deltarune frames (2 seconds)
        -- This is handled at the top of update
        self.dronesfx:setVolume(0)
        self.drone_get_louder = true

        self.dronesfx:setPitch(0.1)
        self.dronesfx:play()

        self.dronetimer = 0
        self.soundcon = 2
    end
    if (self.soundcon == 2) then
        self.dronetimer = self.dronetimer + 1 * DTMULT
        if (self.quick_mode) then
            self.dronetimer = self.dronetimer + 1 * DTMULT
        end
        self.dronepitch = (self.dronetimer / 80)
        if (self.dronepitch >= 1) then
            self.dronepitch = 1
            self.soundcon = 3
        end
        self.dronesfx:setPitch(self.dronepitch)
    end
    if (self.con == 18) then
        self.timer = self.timer + 1 * DTMULT
        if (self.quick_mode) then
            self.timer = self.timer + 1 * DTMULT
        end
        self.sprite_index = ((self.timer / 36) * 5)
        for _, data in ipairs(self.character_data) do
            data.x = data.x_current + (math.sin(math.rad((self.timer * 2.5))) * self.radius) * data.movement
        end

        if (self.timer >= 35) then
            self.sprite_index = 0
            self.con = 19
            self.timer = 0

            for _, data in ipairs(self.character_data) do
                data.sprite_1.visible = true
                data.sprite_1:set("light")
            end
        end
    end
    if (self.con == 19) then
        self.sprite_index = self.sprite_index + 0.2 * DTMULT
        self.timer = self.timer + 1 * DTMULT
        if (self.quick_mode) then
            self.timer = 8
        end
        if (self.timer >= 8) then
            self.con = 30
            self.timer = 0

            self.use_sprite_index = false

            for _, data in ipairs(self.character_data) do
                data.sprite_1.visible = true
                data.sprite_1:set("light")
            end

            if self.loading_callback then
                self.loading_callback(self)
            end
        end
    end
    if (self.con == 30) then
        for _, data in ipairs(self.character_data) do
            data.sprite_1:setFrame(math.floor(self.index / 4) + 1)
        end

        self.timer = self.timer + 1 * DTMULT
        if (self.quick_mode) then
            self.timer = self.timer + 1 * DTMULT
        end
        if (self.timer >= 15) then
            self.con = 31
            self.timer = 0

            for _, data in ipairs(self.character_data) do
                data.sprite_2:set("white")
                data.sprite_3:set("dark")
                data.top = data.sprite_3.texture:getHeight()
                print(data.top)

                data.sprite_1.cutout_bottom = 0
                data.sprite_2.cutout_top = data.top
                data.sprite_3.cutout_top = data.top

                data.sprite_2.visible = true
                data.sprite_3.visible = true
            end
        end
    end
    if (self.con == 31) then
        self.timer = self.timer + 1 * DTMULT
        for _,data in ipairs(self.character_data) do
            data.sprite_1:setFrame(math.floor(self.index / 4) + 1)
            data.sprite_2:setFrame(math.floor(self.index / 4) + 1)
            data.sprite_3:setFrame(math.floor(self.index / 4) + 1)

            if data.top == 0 then
                data.sprite_2.visible = false
            end

            data.sprite_1.cutout_bottom = data.sprite_3.height - data.top
            data.sprite_2.cutout_top = data.top
            data.sprite_2.cutout_bottom = data.sprite_3.height - data.top - 1
            data.sprite_3.cutout_top = data.top + 1
        end

        if ((math.floor(self.timer) >= 15) and not self.do_once13) then
            self.do_once13 = true
            if self.has_head_object then
                self.kris_head_object.breakcon = 1
            end

            if self.sparkles > 0 then
                Assets.playSound("sparkle_glock")
            end

            for i = 1, self.sparkles do
                local sparkle = DarkTransitionSparkle(self.sparestar, self.kris_x + 15, self.kris_y + 15)
                sparkle:play(1 / 15)
                -- We need to get the stage...
                self:addChild(sparkle)
            end
        end
        if (self.timer >= 4) then
            local particle_amount = 0
            while self.particle_timer >= 1 do
                particle_amount = particle_amount + 1
                self.particle_timer = self.particle_timer - 1
            end
            self.particle_timer = self.particle_timer + DTMULT

            for i, data in ipairs(self.character_data) do
                if data.top > 2 then
                    data.top = data.top - 0.5 * DTMULT
                    if (self.quick_mode) then
                        data.top = data.top - 1.5 * DTMULT
                    end
                else
                    data.top = 0
                end

                if data.top >= 2 then
                    local x = ((data.x + 3) + math.random((data.sprite_1.width - 6)))
                    local y = (data.y + data.top)

                    for _ = 1, particle_amount do
                        self:addChild(DarkTransitionParticle(x, y))
                    end
                end
            end
        end
        self.threshold = 130
        if (self.quick_mode) then
            self.threshold = 40
        end
        if (self.timer >= self.threshold) then
            if (self.quick_mode) then
                self.linecon = false
            end
            self.timer    = 0
            self.velocity = -0.2
            self.friction = 0.01
            self.con      = 32

            for _, data in ipairs(self.character_data) do
                data.x = Utils.round(data.x)
                data.y = Utils.round(data.y)

                data.sprite_1:set("smear")
                data.sprite_1:setFrame(1)

                data.sprite_2.visible = false
                data.sprite_3.visible = false

                data.sprite_1:setCutout()
                data.sprite_2:setCutout()
                data.sprite_3:setCutout()
            end
        end
    end
    if (self.con == 32) then
        if (math.floor(self.timer) >= 2) then
            -- In Deltarune, the megablack marker gets spawned off-screen on the first frame (0) con is 32,
            -- and it's moved on-screen on the third frame (2).
            -- Here, we simulate that by drawing a black background on the third frame.
            self.megablack = true
        end
        self.timer = self.timer + 1 * DTMULT
        if (self.timer >= 0 and self.timer < 8) then
            self.velocity = self.velocity - 0.5 * DTMULT

            for _, data in ipairs(self.character_data) do
                data.sprite_1:setFrame(1)
            end
        end
        if (self.timer >= 8 and self.timer < 12) then
            self.velocity = self.velocity + 1 * DTMULT
            self.friction = 0

            for _, data in ipairs(self.character_data) do
                data.sprite_1:setFrame(2)
            end
        end
        if (self.timer >= 12 and self.timer <= 14) then
            self.velocity = self.velocity + 4 * DTMULT

            for _, data in ipairs(self.character_data) do
                data.sprite_1:setFrame(3)
            end
        end
        if (self.timer >= 14) then
            self.soundcon = 4

            -- self.dronesfx needs to fade out to 0, taking 30 deltarune frames (1 second)
            -- snd_volume(self.dronesfx, 0, 30)

            -- This fade is handled at the top of the update function, when `self.soundcon` is 4.

            self.velocity = 13
            self.friction = 0
            self.timer = 0
            self.con = 33
            self.rect_draw = 0

            for _, data in ipairs(self.character_data) do
                data.sprite_1:set("ball")
                data.sprite_2:set("ball")
                data.sprite_3:set("ball")

                data.sprite_2.visible = true
                data.sprite_3.visible = true

                data.sprite_2.alpha = 0.5
                data.sprite_3.alpha = 0.25
            end
        end
    end
    if (self.con == 33) then
        self.timer = self.timer + 1 * DTMULT
        if (self.quick_mode and (self.timer < 31)) then
            self.timer = 31
            self.do_once4 = true -- skip timer == 14
            self.do_once5 = true -- skip timer == 30
        end

        for _, data in ipairs(self.character_data) do
            data.sprite_1:setFrame(math.floor(self.timer / 2) + 1)
            data.sprite_2:setFrame(math.floor(self.timer / 2) + 1)
            data.sprite_3:setFrame(math.floor(self.timer / 2) + 1)

            data.sprite_2.y = -self.velocity
            data.sprite_3.y = -self.velocity * 2
        end

        if (math.floor(self.timer) >= 14) and not self.do_once4 then
            self.do_once4 = true
            self.linecon = false
        end
        if (math.floor(self.timer) >= 30) and not self.do_once5 then
            self.do_once5 = true
            for i, data in ipairs(self.character_data) do
                data.y = -17
            end
            -- TODO: why are these different? (answer: sprite sizes lol)
            --self.susie_y = -20
            --self.kris_y = -14
        end
        if (self.timer > 30) then
            -- Goodbye accuracy :(
            -- Because we have a configurable self.final_y, we should play the sound when they reach that

            if (self.character_data[1].y >= (self.final_y / 2) - self.character_data[1].sprite_1.height) then
                -- Since our final_y is configurable, play the sound here
                Assets.playSound("dtrans_flip")

                for i, data in ipairs(self.character_data) do
                    data.sprite_1:set("landed")
                    data.sprite_2.visible = false
                    data.sprite_3.visible = false
                end

                self.con              = 34
                self.timer            = 0
                self.velocity         = 0
                for i, data in ipairs(self.character_data) do
                    data.y = (self.final_y / 2) - data.sprite_1.height
                    data.remx = data.x
                    data.remy = data.y
                end
                self.getup_index      = 0
                self.fake_screenshake = 1
                self.fake_shakeamount = 8
                self.shaketimer       = 0

                if self.land_callback then
                    self.land_callback(self)
                end
            end
        end
    end

    if (self.con == 34) then
        self.dronesfx:stop()
        self.timer = self.timer + 1 * DTMULT
        if (self.quick_mode and self.timer < 15) then
            self.timer = 15
        end
        if (self.timer > 1) then

            for _, data in ipairs(self.character_data) do
                data.sprite_1:setFrame(math.floor(self.getup_index) + 1)

                data.sprite_2.visible = false
                data.sprite_3.visible = false
            end
        end
        if ((math.floor(self.timer) >= 26) and not self.do_once8) then
            self.do_once8 = true
            for i, data in ipairs(self.character_data) do
                data.x = data.remx
                data.y = data.remy
            end

            --scr_become_dark()
            --dz = (global.darkzone + 1)
            --room_goto(nextroom)
        end
        if ((math.floor(self.timer) >= 27) and not self.do_once9) then
            self.do_once9 = true
            Assets.playSound("him_quick")
            Kristal.showBorder(1)
            --with (obj_mainchara) then
            --    x = -999
            --    cutscene = true
            --    visible = false
            --end
            --with (obj_caterpillarchara) then
            --    x = -999
            --    visible = false
            --end
            --if (global.chapter == 2) then
            --    if (global.plot == 9) then
            --        obj_mainchara.y = kris_y
            --        kris_y = kris_y + 200
            --        cameray_set((cameray() + 400))
            --    end
            --end
        end
        if (self.timer >= 30 and self.timer < 60) then
            self.black_fade = self.black_fade - 0.05 * DTMULT
            if self.quick_mode then
                self.black_fade = self.black_fade - 0.05 * DTMULT
            end
        end
        if ((math.floor(self.timer) >= 50) and not self.do_once10) then
            self.do_once10 = true
            self.getup_index = 1
        end
        if ((math.floor(self.timer) >= 53) and not self.do_once11) then
            self.do_once11 = true
            self.getup_index = 2
        end
        if ((math.floor(self.timer) >= 55) and not self.do_once12) then
            self.do_once12 = true
            -- We're done!
            if self.end_callback then
                self.end_callback(self, self.character_data)
            end

            self:remove()

            for _, data in ipairs(self.character_data) do
                data.character.x = data.x
                data.character.y = data.y
            end
            --persistent = false
            --global.interact = 0
            --global.facing = 0
            --obj_mainchara.x = ((kris_x * 2) + 8)
            --obj_mainchara.y = ((kris_y * 2) + 4)
            --with (obj_mainchara)
            --    visible = true
            --if i_ex(global.cinstance[1]) then
            --    with (global.cinstance[1])
            --        instance_destroy()
            --end
            --if (kris_only == 0 && i_ex(global.cinstance[0])) then
            --    global.cinstance[0].x = ((susie_x * 2) + 10)
            --    global.cinstance[0].y = (susie_y * 2)
            --    with (obj_caterpillarchara) then
            --        visible = true
            --        scr_caterpillar_interpolate()
            --        facing[target] = 0
            --        sprite_index = dsprite
            --    end
            --end
            --instance_destroy()
        end
    end

    for _, data in ipairs(self.character_data) do
        if self.use_sprite_index then
            data.sprite_1:setFrame(math.floor(self.sprite_index) + 1)
        end
        data.sprite_holder.x = data.x + self.fake_shakeamount
        data.sprite_holder.y = data.y
    end

    --self.stage:draw()
    super.draw(self)
end

return DarkTransition
