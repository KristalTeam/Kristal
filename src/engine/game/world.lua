local World, super = Class(Object)

function World:init(map)
    super:init(self)


    self.layers = {
        ["tiles"]         = 0,
        ["objects"]       = 1,

        ["below_soul"]    = 100,
        ["soul"]          = 200,
        ["above_soul"]    = 300,

        ["below_bullets"] = 300,
        ["bullets"]       = 400,
        ["above_bullets"] = 500,

        ["below_ui"]      = 900,
        ["ui"]            = 1000,
        ["above_ui"]      = 1100
    }


    -- states: GAMEPLAY, TRANSITION_OUT, TRANSITION_IN
    self.state = "GAMEPLAY"

    self.music = Music()

    self.map = Map(self)

    self.width = self.map.width * self.map.tile_width
    self.height = self.map.height * self.map.tile_height

    self.light = false

    self.camera = Camera(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
    self.camera:setBounds()
    self.camera_attached = true

    self.shake_x = 0
    self.shake_y = 0

    self.player = nil
    self.soul = nil

    self.battle_borders = {}

    self.transition_fade = 0
    self.transition_target = nil

    self.in_battle = false
    self.battle_alpha = 0

    self.bullets = {}
    self.followers = {}

    self.cutscene = nil

    self.timer = Timer()
    self.timer.persistent = true
    self:addChild(self.timer)

    self.can_open_menu = true

    self.menu = nil

    if map then
        self:loadMap(map)
    end
end

function World:heal(target, amount)
    target:heal(amount)
    if self.healthbar then
        for _, actionbox in ipairs(self.healthbar.action_boxes) do
            if actionbox.chara.id == target.id then
                local text = HPText("+" .. amount, self.healthbar.x + actionbox.x + 69, self.healthbar.y + actionbox.y + 15)
                text.layer = self.layers.ui + 1
                Game.world:addChild(text)
                return
            end
        end
    end
end

function World:hurtParty(amount)
    Assets.playSound("snd_hurt1")

    self.shake_x = 4
    self.shake_y = 4

    self:showHealthBars()

    local all_killed = true
    for _,party in ipairs(Game.party) do
        party.health = party.health - amount
        if party.health <= 0 then
            party.health = 1
        else
            all_killed = false
        end
        for _,char in ipairs(self.stage:getObjects(Character)) do
            if char.actor and (char.actor.id == party.actor or char.actor.id == party.lw_actor) then
                char:statusMessage("damage", amount)
            end
        end
    end

    if self.player then
        self.player.hurt_timer = 7
    end

    if all_killed then
        Game:gameOver(self.soul:getScreenPos())
    end
end

function World:openMenu(menu)
    if self:hasCutscene() then return end
    if self.in_battle then return end
    if not self.can_open_menu then return end

    if self.menu then
        self.menu:remove()
    end

    self.state = "MENU"

    if not menu then
        if not self.light then
            self.menu = DarkMenu()
        else
            --error("TODO: Light world menu")
            print("TODO: Light world menu")
            self.menu = DarkMenu()
        end
    else
        self.menu = menu
    end
    self.menu.layer = self.layers["ui"]
    self:addChild(self.menu)
    return self.menu
end

function World:closeMenu()
    self.state = "GAMEPLAY"
    if self.menu then
        if not self.menu.animate_out and self.menu.transitionOut then
            self.menu:transitionOut()
        end
    end
    self:hideHealthBars()
end

function World:showHealthBars()
    if self.light then return end

    if self.healthbar then
        self.healthbar:transitionIn()
    else
        self.healthbar = HealthBar()
        self.healthbar.layer = self.layers["ui"]
        self:addChild(self.healthbar)
    end
end

function World:hideHealthBars()
    if self.healthbar then
        if not self.healthbar.animate_out then
            self.healthbar:transitionOut()
        end
    end
end

function World:keypressed(key)
    if Game.console.is_open then return end
    if key == "m" then
        if self.music then
            if self.music:isPlaying() then
                self.music:pause()
            else
                self.music:resume()
            end
        end
    end

    if Game.lock_input then return end

    if self.state == "GAMEPLAY" then
        if Input.isConfirm(key) and self.player then
            self.player:interact()
            Input.consumePress("confirm")
        elseif Input.isMenu(key) then
            self:openMenu()
            Input.consumePress("menu")
        end
    elseif self.state == "MENU" then
        if self.menu and self.menu.keypressed then
            self.menu:keypressed(key)
        end
    end
end

function World:getCollision(enemy_check)
    local col = {}
    for _,collider in ipairs(self.map.collision) do
        table.insert(col, collider)
    end
    if enemy_check then
        for _,collider in ipairs(self.map.enemy_collision) do
            table.insert(col, collider)
        end
    end
    for _,child in ipairs(self.children) do
        if child.collider and child.solid then
            table.insert(col, child.collider)
        end
    end
    return col
end

function World:checkCollision(collider, enemy_check)
    Object.startCache()
    for _,other in ipairs(self:getCollision(enemy_check)) do
        if collider:collidesWith(other) then
            Object.endCache()
            return true, other.parent
        end
    end
    Object.endCache()
    return false
end

function World:hasCutscene()
    return self.cutscene and not self.cutscene.ended
end

function World:startCutscene(group, id, ...)
    if self.cutscene then
        error("Attempt to start a cutscene while already in a cutscene.")
    end
    self.cutscene = WorldCutscene(group, id, ...)
    return self.cutscene
end

function World:showText(text, after)
    if type(text) ~= "table" then
        text = {text}
    end
    self:startCutscene(function(cutscene)
        for _,line in ipairs(text) do
            cutscene:text(line)
        end
        if after then
            after(cutscene)
        end
    end)
end

function World:spawnPlayer(...)
    local args = {...}

    local x, y = 0, 0
    local chara = self.player and self.player.actor
    if #args > 0 then
        if type(args[1]) == "number" then
            x, y = args[1], args[2]
            chara = args[3] or chara
        elseif type(args[1]) == "string" then
            x, y = self.map:getMarker(args[1])
            chara = args[2] or chara
        end
    end

    if type(chara) == "string" then
        chara = Registry.getActor(chara)
    end

    local facing = "down"

    if self.player then
        facing = self.player.facing
        self:removeChild(self.player)
    end
    if self.soul then
        self:removeChild(self.soul)
    end

    self.player = Player(chara, x, y)
    self.player.layer = self.layers["objects"]
    self.player:setFacing(facing)
    self:addChild(self.player)

    self.soul = OverworldSoul(x + 10, y + 24) -- TODO: unhardcode
    self.soul.layer = self.layers["soul"]
    self:addChild(self.soul)

    if self.camera_attached then
        self.camera:lookAt(self.player.x, self.player.y - (self.player.height * 2)/2)
        self:updateCamera()
    end
end

function World:getActorForParty(chara)
    return self.light and chara.lw_actor or chara.actor
end

function World:getPartyCharacter(party)
    if type(party) == "string" then
        party = Registry.getPartyMember(party)
    end
    for _,char in ipairs(Game.stage:getObjects(Character)) do
        if char.actor and char.actor.id == self:getActorForParty(party) then
            return char
        end
    end
end

function World:removeFollower(chara)
    if type(chara) == "string" then
        chara = Registry.getActor(chara)
    end
    local follower_arg = isClass(chara) and chara:includes(Follower)
    for i,follower in ipairs(self.followers) do
        if (follower_arg and follower == chara) or (not follower_arg and follower.actor == chara) then
            table.remove(self.followers, i)
            for j,temp in ipairs(Game.temp_followers) do
                if temp == follower.actor.id or (type(temp) == "table" and temp[1] == follower.actor.id) then
                    table.remove(Game.temp_followers, j)
                    break
                end
            end
            return follower
        end
    end
end

function World:addFollower(chara, options)
    if type(chara) == "string" then
        chara = Registry.getActor(chara)
    end
    options = options or {}
    local follower
    if isClass(chara) and chara:includes(Follower) then
        follower = chara
    else
        follower = Follower(chara, self.player.x, self.player.y)
        follower.layer = self.layers["objects"]
        follower:setFacing(self.player.facing)
    end
    if options["x"] or options["y"] then
        local ex, ey = follower:getExactPosition()
        follower:setExactPosition(options["x"] or ex, options["y"] or ey)
    end
    if options["index"] then
        table.insert(self.followers, options["index"], follower)
    else
        table.insert(self.followers, follower)
    end
    if options["temp"] == false then
        if options["index"] then
            table.insert(Game.temp_followers, {follower.actor.id, options["index"]})
        else
            table.insert(Game.temp_followers, follower.actor.id)
        end
    end
    self:addChild(follower)
    follower:updateIndex()
    return follower
end

function World:spawnParty(marker, party, extra)
    party = party or Game.party or {"kris"}
    if #party > 0 then
        if type(marker) == "table" then
            self:spawnPlayer(marker[1], marker[2], self:getActorForParty(party[1]))
        else
            self:spawnPlayer(marker or "spawn", self:getActorForParty(party[1]))
        end
        for i = 2, #party do
            local follower = self:addFollower(self:getActorForParty(party[i]))
            follower:setFacing(self.player.facing)
        end
        for _,actor in ipairs(extra or Game.temp_followers or {}) do
            if type(actor) == "table" then
                self:addFollower(actor[1], {index = actor[2]})
            else
                self:addFollower(actor)
            end
        end
    end
end

function World:spawnBullet(bullet, ...)
    local new_bullet
    if isClass(bullet) and bullet:includes(WorldBullet) then
        new_bullet = bullet
    elseif Registry.getWorldBullet(bullet) then
        new_bullet = Registry.createWorldBullet(bullet, ...)
    else
        local x, y = ...
        table.remove(arg, 1)
        table.remove(arg, 1)
        new_bullet = WorldBullet(x, y, bullet, unpack(arg))
    end
    new_bullet.layer = self.layers["bullets"]
    new_bullet.world = self
    table.insert(self.bullets, new_bullet)
    if not new_bullet.parent then
        self:addChild(new_bullet)
    end
    return new_bullet
end

function World:loadMap(map, ...)
    if self.map then
        self.map:unload()
    end

    for _,child in ipairs(self.children) do
        if not child.persistent then
            self:removeChild(child)
        end
    end

    self.followers = {}

    if isClass(map) then
        self.map = map
    elseif type(map) == "string" then
        self.map = Registry.createMap(map, self, ...)
    elseif type(map) == "table" then
        self.map = Map(self, map, ...)
    else
        self.map = Map(self, nil, ...)
    end

    self.map:load()

    self.light = self.map.light

    self.layers["objects"] = self.map.object_layer

    self.camera:setBounds(0, 0, self.map.width * self.map.tile_width, self.map.height * self.map.tile_height)

    if self.map.markers["spawn"] then
        local spawn = self.map.markers["spawn"]
        self.camera:lookAt(spawn.center_x, spawn.center_y)
    end

    self.battle_fader = Rectangle(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
    self.battle_fader.layer = self.map.battle_fader_layer
    self:addChild(self.battle_fader)

    self:transitionMusic(self.map.music)

    self:updateCamera()
end

function World:transitionMusic(next, dont_play)
    if next and next ~= "" then
        if self.music.current ~= next then
            if self.music:isPlaying() then
                self.music:fade(0, 0.1, function()
                    if not dont_play then
                        self.music:play(next, 1)
                    else
                        self.music:stop()
                    end
                end)
            elseif not dont_play then
                self.music:play(next, 1)
            end
        else
            if not self.music:isPlaying() then
                if not dont_play then
                    self.music:play(next, 1)
                end
            else
                self.music:fade(1)
            end
        end
    else
        if self.music:isPlaying() then
            self.music:fade(0, 0.1, function() self.music:stop() end)
        end
    end
end

function World:transition(target)
    self.state = "TRANSITION_OUT"
    self.transition_target = Utils.copy(target or {})
    if self.transition_target.map and type(self.transition_target.map) == "string" then
        local map = Registry.createMap(self.transition_target.map)
        self.transition_target.map = map
        self:transitionMusic(map.music, true)
    end
end

function World:transitionImmediate(target)
    if target.map then
        self:loadMap(target.map)
    end
    local pos
    if target.x and target.y then
        pos = {target.x, target.y}
    elseif target.marker then
        pos = target.marker
    end
    self:spawnParty(pos)
end

function World:getCameraTarget()
    return self.player:getRelativePos(self.player.width/2, self.player.height/2)
end

function World:updateCamera()
    if self.shake_x ~= 0 or self.shake_y ~= 0 then
        local last_shake_x = math.ceil(self.shake_x)
        local last_shake_y = math.ceil(self.shake_y)
        self.camera.ox = last_shake_x
        self.camera.oy = last_shake_y
        self.shake_x = Utils.approach(self.shake_x, 0, DTMULT)
        self.shake_y = Utils.approach(self.shake_y, 0, DTMULT)
        local new_shake_x = math.ceil(self.shake_x)
        if new_shake_x ~= last_shake_x then
            self.shake_x = self.shake_x * -1
        end
        local new_shake_y = math.ceil(self.shake_y)
        if new_shake_y ~= last_shake_y then
            self.shake_y = self.shake_y * -1
        end
    else
        self.camera.ox = 0
        self.camera.oy = 0
    end
end

function World:createTransform()
    local transform = super:createTransform(self)
    transform:apply(self.camera:getTransform(0, 0))
    return transform
end

function World:sortChildren()
    Utils.pushPerformance("World#sortChildren")
    -- Sort children by Y position, or by follower index if it's a follower/player (so the player is always on top)
    Object.startCache()
    table.sort(self.children, function(a, b)
        local ax, ay = a:getRelativePos(a.width/2, a.height, self)
        local bx, by = b:getRelativePos(b.width/2, b.height, self)
        return a.layer < b.layer or (a.layer == b.layer and (math.floor(ay) < math.floor(by) or(math.floor(ay) == math.floor(by) and (b == self.player or (a:includes(Follower) and b:includes(Follower) and b.index < a.index)))))
    end)
    Object.endCache()
    Utils.popPerformance()
end

function World:onRemove(parent)
    super:onRemove(self, parent)

    self.music:remove()
end

function World:update(dt)
    if self.cutscene then
        if not self.cutscene.ended then
            self.cutscene:update(dt)
        end
        if self.cutscene.ended then
            self.cutscene = nil
        end
    end

    -- Fade transition
    if self.state == "TRANSITION_OUT" then
        self.transition_fade = Utils.approach(self.transition_fade, 1, dt / 0.25)
        if self.transition_fade == 1 then
            self:transitionImmediate(self.transition_target or {})
            self.transition_target = nil
            self.state = "TRANSITION_IN"
        end
    elseif self.state == "TRANSITION_IN" then
        self.transition_fade = Utils.approach(self.transition_fade, 0, dt / 0.25)
        if self.transition_fade == 0 then
            self.state = "GAMEPLAY"
        end
    elseif self.state == "GAMEPLAY" then
        -- Object collision
        local collided = {}
        Object.startCache()
        for _,obj in ipairs(self.children) do
            if not obj.solid and obj.onCollide then
                for _,char in ipairs(self.stage:getObjects(Character)) do
                    if obj:collidesWith(char) then
                        if not obj:includes(OverworldSoul) then
                            table.insert(collided, {obj, char})
                        end
                    end
                end
            end
        end
        Object.endCache()
        for _,v in ipairs(collided) do
            v[1]:onCollide(v[2])
        end
    end

    -- Keep camera in bounds
    self:updateCamera()

    if self.in_battle then
        self.battle_alpha = math.min(self.battle_alpha + (0.08 * DTMULT), 1)
    else
        self.battle_alpha = math.max(self.battle_alpha - (0.08 * DTMULT), 0)
    end

    local half_alpha = self.battle_alpha * 0.52

    for _,v in ipairs(self.followers) do
        v.sprite:setColor(1 - half_alpha, 1 - half_alpha, 1 - half_alpha, 1)
    end

    for _,battle_border in ipairs(self.map.battle_borders) do
        if battle_border:includes(TileLayer) then
            battle_border.tile_opacity = self.battle_alpha
        else
            battle_border.alpha = self.battle_alpha
        end
    end
    if self.battle_fader then
        --self.battle_fader.layer = self.battle_border.layer - 1
        self.battle_fader:setColor(0, 0, 0, half_alpha)
        local cam_x, cam_y = self.camera:getPosition()
        self.battle_fader.x = cam_x - 320
        self.battle_fader.y = cam_y - 240
    end

    self.map:update(dt)

    -- Always sort
    self.update_child_list = true
    super:update(self, dt)

    --[[if self.player then
        local bx, by = self.player:getRelativePos(self.player.width/2, self.player.height/2, self.soul.parent)
        self.soul.x = bx + 1
        self.soul.y = by + 11
        -- TODO: unhardcode offset (???)
    end]]
end

function World:draw()
    -- Draw background
    love.graphics.setColor(self.map.bg_color or {0, 0, 0, 0})
    love.graphics.rectangle("fill", 0, 0, self.map.width * self.map.tile_width, self.map.height * self.map.tile_height)
    love.graphics.setColor(1, 1, 1)

    super:draw(self)

    self.map:draw()

    if DEBUG_RENDER then
        for _,collision in ipairs(self.map.collision) do
            collision:draw(0, 0, 1, 0.5)
        end
        for _,collision in ipairs(self.map.enemy_collision) do
            collision:draw(0, 1, 1, 0.5)
        end
    end

    -- Draw transition fade
    love.graphics.setColor(0, 0, 0, self.transition_fade)
    love.graphics.rectangle("fill", 0, 0, self.map.width * self.map.tile_width, self.map.height * self.map.tile_height)
    love.graphics.setColor(1, 1, 1)
end

return World