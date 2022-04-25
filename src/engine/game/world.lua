local World, super = Class(Object)

function World:init(map)
    super:init(self)

    -- states: GAMEPLAY, TRANSITION, MENU
    self.state_manager = StateManager("GAMEPLAY", self, true)
    self.state_manager:addState("GAMEPLAY")
    self.state_manager:addState("TRANSITION")
    self.state_manager:addState("MENU")

    self.music = Music()

    self.map = Map(self)

    self.width = self.map.width * self.map.tile_width
    self.height = self.map.height * self.map.tile_height

    self.camera = Camera(self, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, true)
    self.camera_attached_x = true
    self.camera_attached_y = true
    self.camera_return_target = nil

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

    self.fader = Fader()
    self.fader.layer = WORLD_LAYERS["above_ui"]
    self.fader.persistent = true
    self:addChild(self.fader)

    self.timer = Timer()
    self.timer.persistent = true
    self:addChild(self.timer)

    self.can_open_menu = true

    self.menu = nil

    self.calls = {}

    -- Reset keypresses in-case they didn't get wiped on crash
    Input.clearDownPressed()

    if map then
        self:loadMap(map)
    end
end

function World:heal(target, amount)
    if type(target) == "string" then
        target = Game:getPartyMember(target)
    end
    target:heal(amount)
    if self.healthbar then
        for _, actionbox in ipairs(self.healthbar.action_boxes) do
            if actionbox.chara.id == target.id then
                local text = HPText("+" .. amount, self.healthbar.x + actionbox.x + 69, self.healthbar.y + actionbox.y + 15)
                text.layer = WORLD_LAYERS["ui"] + 1
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
            if char.actor and (char.actor.id == party:getActor().id) then
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

function World:setState(state)
    self.state_manager:setState(state)
end

function World:openMenu(menu, layer)
    if self:hasCutscene() then return end
    if self.in_battle then return end
    if not self.can_open_menu then return end

    if self.menu then
        self.menu:remove()
        self.menu = nil
    end

    if not menu then
        self:createMenu()
    else
        self.menu = menu
    end
    if self.menu then
        self.menu.layer = layer and self:parseLayer(layer) or WORLD_LAYERS["ui"]
        self:addChild(self.menu)
        self:setState("MENU")
    end
    return self.menu
end

function World:createMenu()
    if Game:isLight() then
        self.menu = LightMenu()
    else
        self.menu = DarkMenu()
    end
end

function World:closeMenu()
    if self.menu then
        if not self.menu.animate_out and self.menu.transitionOut then
            self.menu:transitionOut()
        elseif (not self.menu.transitionOut) and self.menu.close then
            self.menu:close()
        end
    end
    self:hideHealthBars()
    self:setState("GAMEPLAY")
end


function World:setCellFlag(name, value)
    Game:setFlag("lightmenu#cell:" .. name, value)
end

function World:getCellFlag(name, default)
    return Game:getFlag("lightmenu#cell:" .. name, default)
end

function World:registerCall(name, scene)
    table.insert(self.calls, {name, scene})
end

function World:replaceCall(name, index, scene)
    self.calls[index] = {name, scene}
end

function World:showHealthBars()
    if Game.light then return end

    if self.healthbar then
        self.healthbar:transitionIn()
    else
        self.healthbar = HealthBar()
        self.healthbar.layer = WORLD_LAYERS["ui"]
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

function World:onStateChange(old, new)
    if new == "TRANSITION" then
        self.transition_target = self.transition_target or {}
        if self.transition_target.map and type(self.transition_target.map) == "string" then
            local map = Registry.createMap(self.transition_target.map)
            self.transition_target.map = map
            self:transitionMusic(map.music, true)
        elseif self.transition_target.shop then
            if type(self.transition_target.shop) == "string" then
                local shop = Registry.createShop(self.transition_target.shop)
                self.transition_target.shop = shop
            end
            Game:setupShop(self.transition_target.shop)
            if not self.transition_target.map then
                self.transition_target.map = self.map
            end
            self.transition_target.shop.transition_target = self.transition_target
            self:transitionMusic("", true)
        end
        Game.fader:transition(function()
            self:transitionImmediate(self.transition_target or {})
            if self.transition_target.map and (self.state == "TRANSITION") and (not self.transition_target.shop) then
                self:setState("GAMEPLAY")
            end
            self.transition_target = nil
        end)
    end
end

function World:keypressed(key)
    if Game.console.is_open then return end
    if Kristal.Config["debug"] and (Input.keyDown("lctrl") or Input.keyDown("rctrl")) then
        if key == "m" then
            if self.music then
                if self.music:isPlaying() then
                    self.music:pause()
                else
                    self.music:resume()
                end
            end
        elseif key == "j" then
            Game:enterShop("test")
        elseif key == "s" then
            if Game:isLight() or Game:getConfig("smallSaveMenu") then
                self:openMenu(SimpleSaveMenu(Game.save_id))
            else
                self:openMenu(SaveMenu())
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
    if self.cutscene and not self.cutscene.ended then
        local cutscene_name = ""
        if type(group) == "string" then
            cutscene_name = group
            if type(id) == "string" then
                cutscene_name = group.."."..id
            end
        elseif type(group) == "function" then
            cutscene_name = "<function>"
        end
        error("Attempt to start a cutscene "..cutscene_name.." while already in cutscene "..self.cutscene.id)
    end
    if Game.console.is_open then
        Game.console:close()
    end
    self.cutscene = WorldCutscene(group, id, ...)
    return self.cutscene
end

function World:stopCutscene()
    if not self.cutscene then
        error("Attempt to stop a cutscene while none are active.")
    end
    self.cutscene:onEnd()
    coroutine.yield(self.cutscene)
    self.cutscene = nil
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
        chara = Registry.createActor(chara)
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
    self.player.layer = self.map.object_layer
    self.player:setFacing(facing)
    self:addChild(self.player)

    self.soul = OverworldSoul(x + 10, y + 24) -- TODO: unhardcode
    self.soul:setColor(Game:getSoulColor())
    self.soul.layer = WORLD_LAYERS["soul"]
    self:addChild(self.soul)

    if self.camera_attached_x then
        self.camera:setPosition(self.player.x, self.camera.y)
    end
    if self.camera_attached_y then
        self.camera:setPosition(self.camera.x, self.player.y - (self.player.height * 2)/2)
    end
end

function World:getPartyCharacter(party)
    if type(party) == "string" then
        party = Game:getPartyMember(party)
    end
    for _,char in ipairs(Game.stage:getObjects(Character)) do
        if char.actor and char.actor.id == party:getActor().id then
            return char
        end
    end
end

function World:removeFollower(chara)
    local follower_arg = isClass(chara) and chara:includes(Follower)
    for i,follower in ipairs(self.followers) do
        if (follower_arg and follower == chara) or (not follower_arg and follower.actor.id == chara) then
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

function World:spawnFollower(chara, options)
    if type(chara) == "string" then
        chara = Registry.createActor(chara)
    end
    options = options or {}
    local follower
    if isClass(chara) and chara:includes(Follower) then
        follower = chara
    else
        follower = Follower(chara, self.player.x, self.player.y)
        follower.layer = self.map.object_layer
        follower:setFacing(self.player.facing)
    end
    if options["x"] or options["y"] then
        follower:setPosition(options["x"] or follower.x, options["y"] or follower.y)
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

function World:spawnParty(marker, party, extra, facing)
    party = party or Game.party or {"kris"}
    if #party > 0 then
        if type(marker) == "table" then
            self:spawnPlayer(marker[1], marker[2], party[1]:getActor())
        else
            self:spawnPlayer(marker or "spawn", party[1]:getActor())
        end
        if facing then
            self.player:setFacing(facing)
        end
        for i = 2, #party do
            local follower = self:spawnFollower(party[i]:getActor())
            follower:setFacing(facing or self.player.facing)
        end
        for _,actor in ipairs(extra or Game.temp_followers or {}) do
            if type(actor) == "table" then
                local follower = self:spawnFollower(actor[1], {index = actor[2]})
                follower:setFacing(facing or self.player.facing)
            else
                local follower = self:spawnFollower(actor)
                follower:setFacing(facing or self.player.facing)
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
    new_bullet.layer = WORLD_LAYERS["bullets"]
    new_bullet.world = self
    table.insert(self.bullets, new_bullet)
    if not new_bullet.parent then
        self:addChild(new_bullet)
    end
    return new_bullet
end

function World:spawnNPC(actor, x, y, properties)
    return self:spawnObject(NPC(actor, x, y, properties))
end

function World:spawnObject(obj, layer)
    obj.layer = self:parseLayer(layer)
    self:addChild(obj)
    return obj
end

function World:getCharacter(id, index)
    local party_member = Game:getPartyMember(id)
    local i = 0
    for _,chara in ipairs(Game.stage:getObjects(Character)) do
        if chara.actor.id == id or (party_member and chara.actor.id == party_member:getActor().id) then
            i = i + 1
            if not index or index == i then
                return chara
            end
        end
    end
end

function World:getEvent(id)
    return self.map:getEvent(id)
end

function World:getEvents(name)
    return self.map:getEvents(name)
end

function World:detachFollowers()
    for _,follower in ipairs(self.followers) do
        follower.following = false
    end
end

function World:attachFollowers(return_speed)
    for _,follower in ipairs(self.followers) do
        follower:updateIndex()
        follower:returnToFollowing(return_speed)
    end
end
function World:attachFollowersImmediate()
    for _,follower in ipairs(self.followers) do
        follower.following = true

        follower:updateIndex()
        follower:moveToTarget()
    end
end

function World:parseLayer(layer)
    return (type(layer) == "number" and layer)
            or WORLD_LAYERS[layer]
            or self.map.layers[layer]
            or self.map.object_layer
end

function World:loadMap(map, ...)
    if self.map then
        self.map:onExit()
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

    Game:setLight(self.map.light)

    self.width = self.map.width * self.map.tile_width
    self.height = self.map.height * self.map.tile_height

    --self.camera:setBounds(0, 0, self.map.width * self.map.tile_width, self.map.height * self.map.tile_height)

    if self.map.markers["spawn"] then
        local spawn = self.map.markers["spawn"]
        self.camera:setPosition(spawn.center_x, spawn.center_y)
    end

    self.battle_fader = Rectangle(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
    self.battle_fader:setParallax(0, 0)
    self.battle_fader:setColor(0, 0, 0)
    self.battle_fader.alpha = 0
    self.battle_fader.layer = self.map.battle_fader_layer
    self:addChild(self.battle_fader)

    self:transitionMusic(self.map.music)
end

function World:transitionMusic(next, fade_out)
    if next and next ~= "" then
        if self.music.current ~= next then
            if self.music:isPlaying() and fade_out then
                self.music:fade(0, 10/30, function() self.music:stop() end)
            elseif not fade_out then
                self.music:play(next, 1)
            end
        else
            if not self.music:isPlaying() then
                if not fade_out then
                    self.music:play(next, 1)
                end
            else
                self.music:fade(1)
            end
        end
    else
        if self.music:isPlaying() then
            if fade_out then
                self.music:fade(0, 10/30, function() self.music:stop() end)
            else
                self.music:stop()
            end
        end
    end
end

--[[
    Possible argument formats:
        - Target table
            e.g. ({map = "mapid", marker = "markerid", facing = "down"})
        - Map id, [ spawn X, spawn Y, [facing] ]
            e.g. ("mapid")
                 ("mapid", 20, 5)
                 ("mapid", 30, 40, "down")
        - Map id, [ marker, [facing] ]
            e.g. ("mapid", "markerid")
                 ("mapid", "markerid", "up")
]]
local function parseTransitionTargetArgs(...)
    local args = {...}
    if #args == 0 then return {} end
    if type(args[1]) ~= "table" or isClass(args[1]) then
        local target = {map = args[1]}
        if type(args[2]) == "number" and type(args[3]) == "number" then
            target.x = args[2]
            target.y = args[3]
            if type(args[4]) == "string" then
                target.facing = args[4]
            end
        elseif type(args[2]) == "string" then
            target.marker = args[2]
            if type(args[3]) == "string" then
                target.facing = args[3]
            end
        end
        return target
    else
        return args[1]
    end
end

function World:transition(...)
    self.transition_target = parseTransitionTargetArgs(...)
    self:setState("TRANSITION")
end

function World:transitionImmediate(...)
    local target = parseTransitionTargetArgs(...)
    if target.map and (not target.shop) then
        self:loadMap(target.map)
    end

    if target.shop then
        Game:enterShop(target.shop)
    end

    local pos
    if target.x and target.y then
        pos = {target.x, target.y}
    elseif target.marker then
        pos = target.marker
    end

    if target.map and (not target.shop) then
        self:spawnParty(pos, nil, nil, target.facing)
        self.map:onEnter()
    end
end

function World:getCameraTarget()
    return self.player:getRelativePos(self.player.width/2, self.player.height/2)
end

function World:setCameraAttached(attached_x, attached_y)
    if attached_y == nil then
        attached_y = attached_x
    end
    if not attached_x or not attached_y then
        self.camera_returning = false
    end
    self.camera_attached_x = attached_x or false
    self.camera_attached_y = attached_y or false
end

function World:setCameraAttachedX(attached) self:setCameraAttached(attached, self.camera_attached_y) end
function World:setCameraAttachedY(attached) self:setCameraAttached(self.camera_attached_x, attached) end

function World:returnCamera(time)
    self:setCameraAttached(false)
    self.camera_return_target = {start_x = self.camera.x, start_y = self.camera.y, time = time or 0.5, timer = 0}
end

function World:updateCamera()
    if self.camera_return_target then
        self.camera_return_target.timer = Utils.approach(self.camera_return_target.timer, self.camera_return_target.time, DT)

        local target_x, target_y = self:getCameraTarget()

        local x = Utils.lerp(self.camera_return_target.start_x, target_x, self.camera_return_target.timer / self.camera_return_target.time)
        local y = Utils.lerp(self.camera_return_target.start_y, target_y, self.camera_return_target.timer / self.camera_return_target.time)

        self.camera:setPosition(x, y)

        if self.camera_return_target.timer >= self.camera_return_target.time then
            self.camera_return_target = nil
            self:setCameraAttached(true)
        end
    end

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

function World:update()
    if self.cutscene then
        if not self.cutscene.ended then
            self.cutscene:update()
            if self.stage == nil then
                return
            end
        else
            self.cutscene = nil
        end
    end

    if self.state == "GAMEPLAY" then
        -- Object collision
        local collided = {}
        local exited = {}
        Object.startCache()
        for _,obj in ipairs(self.children) do
            if not obj.solid and (obj.onCollide or obj.onEnter) then
                for _,char in ipairs(self.stage:getObjects(Character)) do
                    if obj:collidesWith(char) then
                        if not obj:includes(OverworldSoul) then
                            table.insert(collided, {obj, char})
                        end
                    elseif obj.current_colliding and obj.current_colliding[char] then
                        table.insert(exited, {obj, char})
                    end
                end
            end
        end
        Object.endCache()
        for _,v in ipairs(collided) do
            if v[1].onCollide then
                v[1]:onCollide(v[2], DT)
            end
            if not v[1].current_colliding then
                v[1].current_colliding = {}
            end
            if not v[1].current_colliding[v[2]] then
                if v[1].onEnter then
                    v[1]:onEnter(v[2])
                end
                v[1].current_colliding[v[2]] = true
            end
        end
        for _,v in ipairs(exited) do
            if v[1].onExit then
                v[1]:onExit(v[2])
            end
            v[1].current_colliding[v[2]] = nil
        end
    end

    -- Camera effects (shake)
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
        self.battle_fader:setColor(0, 0, 0, half_alpha)
    end

    self.map:update()

    -- Always sort
    self.update_child_list = true
    super:update(self)

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
end

return World