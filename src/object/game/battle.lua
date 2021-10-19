local Battle, super = Class(Object)

function Battle:init(state, background, music)
    super:init(self)

    self.party = {}

    self.music = nil
    self.music_file = music

    self.party_beginning_positions = {} -- Only used in TRANSITION, but whatever

    -- Create the player battler
    if Game.world.player then
        local player_x, player_y = Game.world.player:getScreenPos()
        local player_battler = BattleCharacter(Game.world.player.info, player_x, player_y)
        player_battler:setBattleSprite("transition")
        self:addChild(player_battler)
        table.insert(self.party,player_battler)
        table.insert(self.party_beginning_positions, {player_x, player_y})

        Game.world.player.visible = false
    end

    for i = 1, 2 do
        local chara = Game.followers[i]
        if chara then
            local chara_x, chara_y = chara:getScreenPos()
            local chara_battler = BattleCharacter(chara.info, chara_x, chara_y)
            chara_battler:setBattleSprite("transition")
            self:addChild(chara_battler)
            table.insert(self.party, chara_battler)
            table.insert(self.party_beginning_positions, {chara_x, chara_y})
            chara.visible = false
        end
    end

    self.intro_timer = 0
    self.offset = 0

    -- states: TRANSITION, INTRO, ACTIONSELECT, DEFENDING, ATTACKING
    self.state = "NONE"
    self:setState(state)

    if state == "TRANSITION" then
        self.transition_timer = 0
        self.afterimage_count = 0
        self.battler_targets = {}
        for index, battler in ipairs(self.party) do
            local target_x, target_y
            if #self.party == 1 then
                target_x = 80
                target_y = 140
            elseif #self.party == 2 then
                target_x = 80
                target_y = 100 + (80 * (index - 1))
            elseif #self.party == 3 then
                target_x = 80
                target_y = 50 + (80 * (index - 1))
            end

            target_x = target_x + (battler.info.width/2 + battler.info.battle_offset[1]) * 2
            target_y = target_y + (battler.info.height  + battler.info.battle_offset[2]) * 2
            table.insert(self.battler_targets, {target_x, target_y})
        end
    end

    self.camera = Camera(0, 0)
end

function Battle:setState(state)
    local old = self.state
    self.state = state
    self:onStateChange(old, self.state)
end

function Battle:getState(state)
    return self.state
end

function Battle:onStateChange(old,new)
    if new == "INTRO" then
        local src = love.audio.newSource("assets/sounds/snd_impact.wav", "static")
        src:setVolume(0.7)
        src:play()
        local src2 = love.audio.newSource("assets/sounds/snd_weaponpull_fast.wav", "static")
        src2:setVolume(0.8)
        src2:play()

        for _,battler in ipairs(self.party) do
            battler:setBattleSprite("intro", 1/15, true)
        end
    elseif new == "ACTIONSELECT" then
        for _,battler in ipairs(self.party) do
            battler:setBattleSprite("idle", 1/5, true)
        end
        if not self.music_file then
            self.music = love.audio.newSource("assets/music/battle.ogg", "stream")
            self.music:setVolume(0.7)
        else
            self.music = love.audio.newSource("assets/music/" .. self.music_file, "stream")
        end

        self.music:setLooping(true)
        self.music:play()
    end
end

function Battle:update(dt)
    if self.state == "TRANSITION" then
        self:updateTransition(dt)
    elseif self.state == "INTRO" then
        self:updateIntro(dt)
    end
    -- Always sort
    self.update_child_list = true
    self:updateChildren(dt)
end

function Battle:updateIntro(dt)
    self.intro_timer = self.intro_timer + 1 * (dt * 30)
    if self.intro_timer >= 13 then
        self:setState("ACTIONSELECT")
    end
end

function Battle:updateTransition(dt)
    while self.afterimage_count < math.floor(self.transition_timer) do
        for index, battler in ipairs(self.party) do
            local target_x, target_y = unpack(self.battler_targets[index])

            local battler_x = battler.x
            local battler_y = battler.y

            battler.x = Utils.lerp(self.party_beginning_positions[index][1], target_x, (self.afterimage_count + 1) / 10)
            battler.y = Utils.lerp(self.party_beginning_positions[index][2], target_y, (self.afterimage_count + 1) / 10)

            local afterimage = AfterImage(battler, 0.5)
            self:addChild(afterimage)

            battler.x = battler_x
            battler.y = battler_y
        end
        self.afterimage_count = self.afterimage_count + 1
    end

    self.transition_timer = self.transition_timer + 1 * (dt * 30)

    if self.transition_timer >= 10 then
        self.transition_timer = 10
        self:setState("INTRO")
    end

    for index, battler in ipairs(self.party) do
        local target_x, target_y = unpack(self.battler_targets[index])

        battler.x = Utils.lerp(self.party_beginning_positions[index][1], target_x, self.transition_timer / 10)
        battler.y = Utils.lerp(self.party_beginning_positions[index][2], target_y, self.transition_timer / 10)
    end
end

function Battle:draw()
    love.graphics.setColor(0, 0, 0, self.transition_timer / 10)
    love.graphics.rectangle("fill", 0, 0, 640, 480)

    self.offset = self.offset + 1 * (DT * 30)

    if self.offset > 100 then
        self.offset = self.offset - 100
    end

    love.graphics.setLineStyle("rough")
    love.graphics.setLineWidth(1)

    for i = 2, 16 do
        love.graphics.setColor(66 / 255, 0, 66 / 255, (self.transition_timer / 10) / 2)
        love.graphics.line(0, -210 + (i * 50) + math.floor(self.offset / 2), 640, -210 + (i * 50) + math.floor(self.offset / 2))
        love.graphics.line(-200 + (i * 50) + math.floor(self.offset / 2), 0, -200 + (i * 50) + math.floor(self.offset / 2), 480)
    end

    for i = 3, 16 do
        love.graphics.setColor(66 / 255, 0, 66 / 255, self.transition_timer / 10)
        love.graphics.line(0, -100 + (i * 50) - math.floor(self.offset), 640, -100 + (i * 50) - math.floor(self.offset))
        love.graphics.line(-100 + (i * 50) - math.floor(self.offset), 0, -100 + (i * 50) - math.floor(self.offset), 480)
    end

    self:drawChildren()
end

return Battle