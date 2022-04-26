local Game = {}

function Game:clear()
    if self.world and self.world.music then
        self.world.music:stop()
    end
    if self.battle and self.battle.music then
        self.battle.music:stop()
    end
    self.stage = nil
    self.world = nil
    self.battle = nil
    self.shop = nil
    self.gameover = nil
    self.inventory = nil
    self.quick_save = nil
    self.lock_input = false
    --self.console = nil
end

function Game:enter(previous_state, save_id, save_name)
    self.previous_state = previous_state

    self.music = Music()

    self.quick_save = nil

    Kristal.callEvent("init")

    self.lock_input = false

    if save_id then
        Kristal.loadGame(save_id, true)
    else
        self:load(nil, nil, true)
    end

    if save_name then
        self.save_name = save_name
    end

    self.started = true

    if Kristal.getModOption("encounter") then
        self:encounter(Kristal.getModOption("encounter"), false)
    elseif Kristal.getModOption("shop") then
        self:enterShop(Kristal.getModOption("shop"), {map = self.world.map.id})
    end

    Kristal.callEvent("postInit", self.is_new_file)
end


function Game:leave()
    self:clear()
    self.console = nil
    self.quick_save = nil
end

function Game:returnToMenu()
    self.fader:fadeOut(Kristal.returnToMenu, {speed = 0.5, music = 10/30})
    self.state = "EXIT"
end

function Game:getConfig(key, merge, deep_merge)
    local default_config = Kristal.ChapterConfigs[Utils.clamp(self.chapter, 1, #Kristal.ChapterConfigs)]

    if not Mod then return default_config[key] end

    local mod_config = Mod.info and Mod.info.config and Utils.getAnyCase(Mod.info.config, "Kristal") or {}

    local default_value = Utils.getAnyCase(default_config, key)
    local mod_value = Utils.getAnyCase(mod_config, key)

    if mod_value ~= nil and default_value == nil then
        return mod_value
    elseif default_value ~= nil and mod_value == nil then
        return default_value
    elseif type(default_value) == "table" and merge then
        return Utils.merge(Utils.copy(default_value, true), mod_value, deep_merge)
    else
        return mod_value
    end
end

function Game:getActiveMusic()
    if self.state == "OVERWORLD" then
        return self.world.music
    elseif self.state == "BATTLE" then
        return self.battle.music
    elseif self.state == "SHOP" then
        return self.shop.music
    elseif self.state == "GAMEOVER" then
        return self.gameover.music
    else
        return self.music
    end
end

function Game:getSavePreview()
    return {
        name = self.save_name,
        level = self.save_level,
        playtime = self.playtime,
        room_name = self.world and self.world.map and self.world.map.name or "???",
    }
end

function Game:save(x, y)
    local data = {
        chapter = self.chapter,

        name = self.save_name,
        level = self.save_level,
        playtime = self.playtime,

        light = self.light,

        room_name = self.world and self.world.map and self.world.map.name or "???",
        room_id = self.world and self.world.map and self.world.map.id,

        money = self.money,
        xp = self.xp,

        lw_money = self.lw_money,

        level_up_count = self.level_up_count,

        temp_followers = self.temp_followers,

        flags = self.flags
    }

    if x then
        if type(x) == "string" then
            data.spawn_marker = x
        elseif type(x) == "table" then
            data.spawn_position = x
        elseif x and y then
            data.spawn_position = {x, y}
        end
    end

    data.party = {}
    for _,party in ipairs(self.party) do
        table.insert(data.party, party.id)
    end

    data.inventory = self.inventory:save()

    data.party_data = {}
    for k,v in pairs(self.party_data) do
        data.party_data[k] = v:save()
    end

    Kristal.callEvent("save", data)

    return data
end

function Game:load(data, index, fade)
    self.is_new_file = data == nil

    data = data or {}

    self:clear()

    -- states: OVERWORLD, BATTLE, SHOP, GAMEOVER
    self.state = "OVERWORLD"

    self.stage = Stage()

    self.world = World()
    self.stage:addChild(self.world)

    if not self.console then
        self.console = Console()
        self.stage:addChild(self.console)
    else
        self.console:setParent(self.stage)
    end

    self.fader = Fader()
    self.fader.layer = 1000
    self.stage:addChild(self.fader)

    if fade then
        self.fader:fadeIn(nil, {alpha = 1, speed = 0.5})
    end

    self.battle = nil

    self.shop = nil

    self.max_followers = Kristal.getModOption("maxFollowers") or 10

    -- BEGIN SAVE FILE VARIABLES --

    self.chapter = data.chapter or Kristal.getModOption("chapter") or 2

    self.save_name = data.name or "PLAYER"
    self.save_level = data.level or self.chapter
    self.save_id = index or self.save_id or 1

    self.playtime = data.playtime or 0

    self.flags = data.flags or {}

    self:initPartyMembers()
    if data.party_data then
        for k,v in pairs(data.party_data) do
            if self.party_data[k] then
                self.party_data[k]:load(v)
            end
        end
    end

    self.party = {}
    for _,id in ipairs(data.party or Kristal.getModOption("party") or {"kris"}) do
        table.insert(self.party, self:getPartyMember(id))
    end

    if self.is_new_file then
        for id,equipped in pairs(Kristal.getModOption("equipment") or {}) do
            if equipped["weapon"] then
                self.party_data[id]:setWeapon(equipped["weapon"] ~= "" and equipped["weapon"] or nil)
            end
            local armors = equipped["armor"] or {}
            for i = 1, 2 do
                if armors[i] then
                    self.party_data[id]:setArmor(i, armors[i] ~= "" and armors[i] or nil)
                end
            end
        end
    end

    self.light = data.light or self.world.map.light

    if self.light then
        self.inventory = LightInventory()
    else
        self.inventory = DarkInventory()
    end

    if data.inventory then
        self.inventory:load(data.inventory)
    else
        for storage,items in pairs(Kristal.getModOption("inventory") or {}) do
            for i,item in ipairs(items) do
                self.inventory:setItem(storage, i, item)
            end
        end
    end

    if data.temp_followers then
        self.temp_followers = data.temp_followers
    else
        self.temp_followers = {}
        for _,id in ipairs(Kristal.getModOption("followers") or {}) do
            table.insert(self.temp_followers, id)
        end
    end

    self.level_up_count = data.level_up_count or 0

    self.money = data.money or 0
    self.xp = data.xp or 0

    self.lw_money = data.lw_money or 2

    local room_id = data.room_id or Kristal.getModOption("map")
    if room_id then
        self.world:loadMap(room_id)
    end

    -- END SAVE FILE VARIABLES --

    self.world:spawnParty(data.spawn_marker or data.spawn_position)

    Kristal.callEvent("load", data, self.is_new_file, index)

    self.world.map:onEnter()
end

function Game:setLight(light)
    light = light or false

    if self.light == light then return end

    self.light = light

    if self.light then
        self:convertToLight()
    else
        self:convertToDark()
    end
end

function Game:isLight()
    return self.light
end

function Game:convertToLight()
    if self.inventory:hasItem("cell_phone") then
        self:setFlag("has_cell_phone", true)
        self.inventory:removeItem("cell_phone")
    else
        self:setFlag("has_cell_phone", false)
    end

    self.inventory = self.inventory:convertToLight()

    for _,chara in pairs(self.party_data) do
        chara:convertToLight()
    end
end

function Game:convertToDark()
    self.inventory = self.inventory:convertToDark()

    for _,chara in pairs(self.party_data) do
        chara:convertToDark()
    end

    if self:getFlag("has_cell_phone", false) then
        self.inventory:addItemTo("key_items", 1, "cell_phone")
    end
end

function Game:gameOver(x, y)
    self.state = "GAMEOVER"
    if self.battle   then self.battle  :remove() end
    if self.world    then self.world   :remove() end
    if self.shop     then self.shop    :remove() end
    if self.gameover then self.gameover:remove() end

    self.gameover = GameOver(x, y)
    self.stage:addChild(self.gameover)
end

function Game:saveQuick(...)
    self.quick_save = Utils.copy(self:save(...), true)
end

function Game:loadQuick(fade)
    local save = self.quick_save
    if save then
        self:load(save, self.save_id, fade)
    else
        Kristal.loadGame(self.save_id)
    end
    self.quick_save = save
end

function Game:encounter(encounter, transition, enemy)
    if transition == nil then transition = true end

    if self.battle then
        error("Attempt to enter battle while already in battle")
    end

    if enemy and not isClass(enemy) then
        self.encounter_enemies = enemy
    else
        self.encounter_enemies = {enemy}
    end

    self.state = "BATTLE"

    self.battle = Battle()
    if type(transition) == "string" then
        self.battle:postInit(transition, encounter)
    else
        self.battle:postInit(transition and "TRANSITION" or "INTRO", encounter)
    end
    self.stage:addChild(self.battle)
end

function Game:setupShop(shop)
    if self.shop then
        error("Attempt to enter shop while already in shop")
    end

    if type(shop) == "string" then
        shop = Registry.createShop(shop)
    end

    if shop == nil then
        error("Attempt to enter shop with nil shop")
    end

    self.shop = shop
    self.shop:postInit()
end

function Game:enterShop(shop, options)
    -- Add the shop to the stage and enter it.
    if not self.shop then
        self:setupShop(shop)
    end

    self.shop.leave_options = options

    if self.world then
        self.world.music:stop()
    end

    self.state = "SHOP"

    self.stage:addChild(self.shop)
    self.shop:onEnter()
end

function Game:setFlag(flag, value)
    self.flags[flag] = value
end

function Game:getFlag(flag, default)
    local result = self.flags[flag]
    if result == nil then
        return default
    else
        return result
    end
end

function Game:addFlag(flag, amount)
    self.flags[flag] = (self.flags[flag] or 0) + (amount or 1)
end

function Game:initPartyMembers()
    self.party_data = {}
    for id,_ in pairs(Registry.party_members) do
        self.party_data[id] = Registry.createPartyMember(id)
    end
end

function Game:getPartyMember(id)
    if self.party_data[id] then
        return self.party_data[id]
    end
end

function Game:addPartyMember(chara, index)
    if type(chara) == "string" then
        chara = self:getPartyMember(chara)
    end
    if index then
        table.insert(self.party, index, chara)
    else
        table.insert(self.party, chara)
    end
end

function Game:removePartyMember(chara)
    if type(chara) == "string" then
        chara = self:getPartyMember(chara)
    end
    Utils.removeFromTable(self.party, chara)
end

function Game:hasPartyMember(chara)
    if type(chara) == "string" then
        chara = self:getPartyMember(chara)
    end
    for _,party_member in ipairs(self.party) do
        if party_member.id == chara.id then
            return true
        end
    end
    return false
end

function Game:movePartyMember(chara, index)
    if type(chara) == "string" then
        chara = self:getPartyMember(chara)
    end
    self:removePartyMember(chara)
    self:addPartyMember(chara, index)
end

function Game:checkPartyEquipped(item_id)
    local success, count = false, 0
    for _,party in ipairs(self.party) do
        if party:checkWeapon(item_id) then
            success = true
            count = count + 1
        end
        local armor_success, armor_count = party:checkArmor(item_id)
        if armor_success then
            success = true
            count = count + armor_count
        end
    end
    return success, count
end

function Game:getSoulPartyMember()
    local current
    for _,party in ipairs(self.party) do
        if not current or (party:getSoulPriority() > current:getSoulPriority()) then
            current = party
        end
    end
    return current
end

function Game:getSoulColor()
    local chara = Game:getSoulPartyMember()

    if chara and chara:getSoulPriority() >= 0 then
        return chara:getSoulColor()
    end

    return 1, 0, 0, 1
end

function Game:getActLeader()
    for _,party in ipairs(self.party) do
        if party.has_act then
            return party
        end
    end
end

function Game:addFollower(chara, index)
    if isClass(chara) then
        chara = chara.actor.id
    end
    if index then
        table.insert(self.temp_followers, {chara, index})
    else
        table.insert(self.temp_followers, chara)
    end
end

function Game:removeFollower(chara)
    if isClass(chara) then
        chara = chara.actor.id
    end
    for i,v in ipairs(self.temp_followers) do
        if type(v) == "table" then
            if v[1] == chara then
                table.remove(self.temp_followers, i)
                return
            end
        elseif v == chara then
            table.remove(self.temp_followers, i)
            return
        end
    end
end

function Game:update()
    if self.state == "EXIT" then
        self.fader:update()
        return
    end

    if not self.started then
        self.started = true
        self.lock_input = false
        if self.world.player then
            self.world.player.visible = true
        end
        for _,follower in ipairs(self.world.followers) do
            follower.visible = true
        end
        if Kristal.getModOption("encounter") then
            self:encounter(Kristal.getModOption("encounter"), self.world.player ~= nil)
        end
    end

    if Kristal.callEvent("preUpdate", DT) then
        return
    end

    if (self.state == "BATTLE" and self.battle and self.battle:isWorldHidden()) or
       (self.state == "SHOP"   and self.shop) then
        self.world.active = false
        self.world.visible = false
    else
        self.world.active = true
        self.world.visible = true
    end

    self.playtime = self.playtime + DT

    self.stage:update()

    Kristal.callEvent("postUpdate", DT)
end

function Game:textinput(key)
    self.console:textinput(key)
end

function Game:keypressed(key)

    if Kristal.callEvent("onKeyPressed", key) then
        return
    end

    self.console:keypressed(key)

    if self.state == "BATTLE" then
        if self.battle then
            self.battle:keypressed(key)
        end
    elseif self.state == "OVERWORLD" then
        if self.world then
            self.world:keypressed(key)
        end
    elseif self.state == "SHOP" then
        if self.shop then
            self.shop:keypressed(key)
        end
    elseif self.state == "GAMEOVER" then
        if self.gameover then
            self.gameover:keypressed(key)
        end
    end
end

function Game:draw()
    love.graphics.clear(0, 0, 0, 1)
    love.graphics.push()
    if Kristal.callEvent("preDraw") then
        love.graphics.pop()
        return
    end
    love.graphics.pop()

    self.stage:draw()

    love.graphics.push()
    Kristal.callEvent("postDraw")
    love.graphics.pop()
end

return Game