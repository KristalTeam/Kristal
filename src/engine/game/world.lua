--- The `World` Object manages everything relating to the overworld in Kristal. \
--- A globally available instance of `World` is stored in [`Game.world`](lua://Game.world).
---
---@class World : Object
---
---@field state             string                          The current state that this `World` is in - should never be set manually, see [`World:setState()`](lua://World.setState) instead
---@field state_manager     StateManager                    An object that manages the state of this `World`
---
---@field music             Music                           The `Music` instance that controls audio playback for this `World`
---
---@field map               Map                             The currently loaded map instance
---
---@field camera            Camera                          The camera object used to display the world
---
---@field player            Player                          The player character
---@field soul              OverworldSoul                   The soul of the player
---
---@field battle_borders    table                           *(unused? See [`Map.battle_borders`](lua://Map.battle_borders))*
---
---@field transition_fade   number                          *(unused?)*
---
---@field in_battle         boolean                         Whether the player is currently in a world battle set through [`World:setBattle()](lua://World.setBattle) (affects the visibility of world battle content)
---@field in_battle_area    boolean                         Whether the player is currently standing inside a battlearea of the map (affects the visibility of world battle content)
---@field battle_alpha      number                          The current alpha value of world battle content
---
---@field bullets           WorldBullet[]                   A table of currently active bullets
---@field followers         Follower[]                      A table of all followers currently present in the world
---
---@field cutscene          WorldCutscene?                  The `WorldCutscene` object of the currently active cutscene, if present
---
---@field conroller_parent  Object                          The object that all controllers are parented to
---
---@field fader             Fader
---
---@field timer             Timer
---
---@field can_open_menu     boolean                         Whether the player can open their menu
---
---@field menu              LightMenu|DarkMenu?             The Menu object of the menu, if it is open
---
---@field calls             table<[string, string]>   A list of calls available on the cell phone in the Light World CELL menu
---
---@field door_delay        number                          *(Used internally)* Timer variable for door transition sounds
---
---@field healthbar         HealthBar
---
---@overload fun(map?: string) : World
local World, super = Class(Object)

---@param map? string    The optional name of a map to initially load with the world
function World:init(map)
    super.init(self)

    -- states: GAMEPLAY, FADING, MENU
    self.state = "" -- Make warnings shut up, TODO: fix this
    self.state_manager = StateManager("GAMEPLAY", self, true)
    self.state_manager:addState("GAMEPLAY")
    self.state_manager:addState("FADING")
    self.state_manager:addState("MENU")

    self.music = Music()

    self.map = Map(self)

    self.width = self.map.width * self.map.tile_width
    self.height = self.map.height * self.map.tile_height

    self.camera = Camera(self, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, true)
    self.camera.target_getter = function()
        return self:getCameraTarget()
    end

    self.player = nil
    self.soul = nil

    self.battle_borders = {}

    self.transition_fade = 0

    self.in_battle = false
    self.in_battle_area = false
    self.battle_alpha = 0

    self.bullets = {}
    self.followers = {}

    self.cutscene = nil

    self.controller_parent = Object()
    self.controller_parent.layer = WORLD_LAYERS["bottom"] - 1
    self.controller_parent.persistent = true
    self.controller_parent.world = self
    self:addChild(self.controller_parent)

    self.fader = Fader()
    self.fader.layer = WORLD_LAYERS["above_ui"]
    self.fader.persistent = true
    self:addChild(self.fader)

    self.timer = Timer()
    self.timer.persistent = true
    self:addChild(self.timer)

    self.can_open_menu = true

    self.menu = nil

    self.debug_select = false

    self.calls = {}

    self.door_delay = 0

    if map then
        self:loadMap(map)
    end
end

--- Heals a member of the party
---@param target    string|PartyMember  The party member to heal
---@param amount    number              The amount of HP to restore
---@param text?     string              An optional text to display when HP is resotred in the Light World, before the HP restoration message
function World:heal(target, amount, text)
    if type(target) == "string" then
        target = Game:getPartyMember(target)
    end

    local maxed = target:heal(amount)

    if Game:isLight() then
        local message
        if maxed then
            message = "* Your HP was maxed out."
        else
            message = "* You recovered " .. amount .. " HP!"
        end
        if text then
            message = text .. " \n" .. message
        end
        Game.world:showText(message)
    elseif self.healthbar then
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

--- Hurts the party member `battler` by `amount`, or hurts the whole party for `amount`
---@overload fun(self: World, amount: number)
---@param battler   Character|string    The Character to hurt
---@param amount    number              The amount of damage to deal
---@return boolean  killed  Whether all targetted characters were knocked out by this damage
function World:hurtParty(battler, amount)
    Assets.playSound("hurt")

    self:shakeCamera()
    self:showHealthBars()

    if type(battler) == "number" then
        amount = battler
        battler = nil
    end

    local any_killed = false
    local any_alive = false
    for _,party in ipairs(Game.party) do
        if not battler or battler == party.id or battler == party then
            local current_health = party:getHealth()
            party:setHealth(party:getHealth() - amount)
            if party:getHealth() <= 0 then
                party:setHealth(1)
                any_killed = true
            else
                any_alive = true
            end

            local dealt_amount = current_health - party:getHealth()

            for _,char in ipairs(self.stage:getObjects(Character)) do
                if char.actor and (char.actor.id == party:getActor().id) and dealt_amount > 0 then
                    char:statusMessage("damage", dealt_amount)
                end
            end
        elseif party:getHealth() > amount then
            any_alive = true
        end
    end

    if self.player then
        self.player.hurt_timer = 7
    end

    if any_killed and not any_alive then
        if not self.map:onGameOver() then
            Game:gameOver(self.soul:getScreenPos())
        end
        return true
    elseif battler then
        return any_killed
    end

    return false
end

--- Changes the state of the world
---@param state string
function World:setState(state)
    self.state_manager:setState(state)
end

--- Opens the main overworld menu
---@param menu?     LightMenu|DarkMenu  An optional menu instance to open
---@param layer?    number  The layer to create the menu on (defaults to `WORLD_LAYERS["ui"]` or `600`)
---@return (DarkMenu|LightMenu)?
function World:openMenu(menu, layer)
    if self:hasCutscene() then return end
    if self:inBattle() then return end
    if not self.can_open_menu then return end

    if self.menu then
        self.menu:remove()
        self.menu = nil
    end

    if not menu then
        menu = self:createMenu()
    end

    self.menu = menu
    if self.menu then
        self.menu.layer = layer and self:parseLayer(layer) or WORLD_LAYERS["ui"]

        if self.menu:includes(AbstractMenuComponent) then
            self.menu.close_callback = function()
                self:afterMenuClosed()
            end
        elseif self.menu:includes(Component) then
            -- Sigh... traverse the children to find the menu component
            for _,child in ipairs(self.menu:getComponents()) do
                if child:includes(AbstractMenuComponent) then
                    child.close_callback = function()
                        self:afterMenuClosed()
                    end
                    break
                end
            end
        end

        self:addChild(self.menu)
        self:setState("MENU")
    end
    return self.menu
end

--- Creates the main overworld menu if it does not exist \
--- *The [event](lua://KRISTAL_EVENT) `createMenu` is called by this function, which can return a custom menu to use instead of the default Light/Dark menu*
---@return LightMenu|DarkMenu
function World:createMenu()
    local menu = Kristal.callEvent(KRISTAL_EVENT.createMenu)
    if menu then return menu end
    if Game:isLight() then
        menu = LightMenu()
    else
        menu = DarkMenu()
    end
    return menu
end

--- Closes the menu
function World:closeMenu()
    if self.menu then
        if not self.menu.animate_out and self.menu.transitionOut then
            self.menu:transitionOut()
        elseif (not self.menu.transitionOut) and self.menu.close then
            self.menu:close()
        end
    end
    self:afterMenuClosed()
end

--- Runs whenever the menu is closed
function World:afterMenuClosed()
    self:hideHealthBars()
    self.menu = nil
    self:setState("GAMEPLAY")
end

--- Sets the value of a cell flag (a special flag which normally starts at -1 and increments by 1 at the start of every call, named after the call cutscene)
---@param name  string  The name of the flag to set
---@param value integer The value to set the flag to
function World:setCellFlag(name, value)
    Game:setFlag("lightmenu#cell:" .. name, value)
end

--- Gets the value of a cell flag (a special flag which normally starts at -1 and increments by 1 at the start of every call, named after the call cutscene)
---@param name      string
---@param default?  integer
---@return integer
function World:getCellFlag(name, default)
    return Game:getFlag("lightmenu#cell:" .. name, default)
end

--- Registers a phone call in the Light World CELL menu
---@param name  string          The name of the call as it will show in the CELL menu
---@param scene string          The cutscene to play when the call is selected
function World:registerCall(name, scene)
    table.insert(self.calls, {name, scene})
end

--- Replaces a phone call in the Light World CELL menu with another
---@param name  string          The name of the call as it will show in the CELL menu
---@param index integer         The index of the call to replace
---@param scene string          The cutscene to play when the call is selected
function World:replaceCall(name, index, scene)
    self.calls[index] = {name, scene}
end

--- Shows party member health bars
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

--- Hides party member health bars
function World:hideHealthBars()
    if self.healthbar then
        if not self.healthbar.animate_out then
            self.healthbar:transitionOut()
        end
    end
end

--- Called whenever the state of the world changes
---@param old string
---@param new string
function World:onStateChange(old, new)
end

---@param key string
function World:onKeyPressed(key)
    if Kristal.Config["debug"] and Input.ctrl() then
        if key == "m" then
            if self.music then
                if self.music:isPlaying() then
                    self.music:pause()
                else
                    self.music:resume()
                end
            end
        end
        if key == "s" then
            local save_pos = nil
            if Input.shift() then
                save_pos = {self.player.x, self.player.y}
            end
            if Game:isLight() or Game:getConfig("smallSaveMenu") then
                self:openMenu(SimpleSaveMenu(Game.save_id, save_pos))
            else
                self:openMenu(SaveMenu(save_pos))
            end
        end
        if key == "h" then
            for _,party in ipairs(Game.party) do
                party:heal(math.huge)
            end
        end
        if key == "b" then
            Game.world:hurtParty(math.huge)
        end
        if key == "k" then
            Game:setTension(Game:getMaxTension() * 2, true)
        end
        if key == "n" then
            NOCLIP = not NOCLIP
        end
    end

    if Game.lock_movement then return end

    if self.state == "GAMEPLAY" then
        if Input.isConfirm(key) and self.player and not self:hasCutscene() then
            if self.player:interact() then
                Input.clear("confirm")
            end
        elseif Input.isMenu(key) and not self:hasCutscene() then
            self:openMenu(nil, WORLD_LAYERS["ui"] + 1)
            Input.clear("menu")
        end
    elseif self.state == "MENU" then
        if self.menu and self.menu.onKeyPressed then
            self.menu:onKeyPressed(key)
        end
    end
end

--- Checks whether there is currently a textbox open
---@return boolean
function World:isTextboxOpen()
    return self:hasCutscene() and self.cutscene.textbox and self.cutscene.textbox.stage ~= nil
end

--- Gets the collision map for the world
---@param enemy_check?  boolean     Whether to include the enemy collision map (defaults to `false`)
---@return Collider[]
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

--- Checks whether the input `collider` is colliding with anything in the world
---@param collider      Collider    The collider to check collision for
---@param enemy_check?  boolean     Whether to include the enemy collision map in the check
---@return boolean  collided    Whether a collision was found
---@return Object?  with        The object that was collided with
function World:checkCollision(collider, enemy_check)
    Object.startCache()
    for _,other in ipairs(self:getCollision(enemy_check)) do
        if collider:collidesWith(other) and collider ~= other then
            Object.endCache()
            return true, other.parent
        end
    end
    Object.endCache()
    return false
end

--- Whether the world has a currently active cutscene
---@return boolean?
function World:hasCutscene()
    return self.cutscene and not self.cutscene.ended
end

--- Starts a cutscene in the world
---@overload fun(self: World, id: string, ...)
---@param group string  The name of the group the cutscene is a part of
---@param id    string  The id of the cutscene 
---@param ...   any     Additional arguments that will be passed to the cutscene function
---@return WorldCutscene?   The cutscene object that was created
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
    if Kristal.Console.is_open then
        Kristal.Console:close()
    end
    self.cutscene = WorldCutscene(self, group, id, ...)
    return self.cutscene
end

--- Stops the current cutscene \
--- An error will be thrown when trying to stop a cutscene if none are active
function World:stopCutscene()
    if not self.cutscene then
        error("Attempt to stop a cutscene while none are active.")
    end
    self.cutscene:onEnd()
    coroutine.yield(self.cutscene)
    self.cutscene = nil
end

--- Shows a textbox with the input `text`
---@param text      string|string[]
---@param after?    fun(cutscene: WorldCutscene)    A callback to run when the textbox is closed, receiving the cutscene instance used to display the text
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

--- Spawns the player into the world
---@overload fun(self: World, x: number, y: number, chara: string|Actor, party?: string)
---@overload fun(self: World, marker: string, chara: string|Actor, party?: string)
---@param ... unknown   Arguments detailing how the player spawns
---|"x, y, chara"   # The co-ordinates of the player spawn and the Actor (instance or id) to use for the player
---|"marker, chara" # The marker name to spawn the player at and the Actor (instance or id) to use for the player
---@param party? string The party member ID associated with the player
function World:spawnPlayer(...)
    local args = {...}

    local x, y = 0, 0
    local chara = self.player and self.player.actor
    local party
    if #args > 0 then
        if type(args[1]) == "number" then
            x, y = args[1], args[2]
            chara = args[3] or chara
            party = args[4]
        elseif type(args[1]) == "string" then
            x, y = self.map:getMarker(args[1])
            chara = args[2] or chara
            party = args[3]
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

    if party then
        self.player.party = party
    end

    self.soul = OverworldSoul(self.player:getRelativePos(self.player.actor:getSoulOffset()))
    self.soul:setColor(Game:getSoulColor())
    self.soul.layer = WORLD_LAYERS["soul"]
    self:addChild(self.soul)

    if self.camera.attached_x then
        self.camera:setPosition(self.player.x, self.camera.y)
    end
    if self.camera.attached_y then
        self.camera:setPosition(self.camera.x, self.player.y - (self.player.height * 2)/2)
    end
end

--- Gets the `Character` in the world of a party member
---@param party string|PartyMember  The party member to get the character for
---@return Character?
function World:getPartyCharacter(party)
    if type(party) == "string" then
        party = Game:getPartyMember(party)
    end
    local char_to_return
    for _,char in ipairs(Game.stage:getObjects(Character)) do
        -- Immediately break the loop and return if we find an explicit party match
        if char.party and char.party.id == party.id then
            return char
        end
        -- Store the first actor match, do not break loop as the match is not explicit
        if char.actor and char.actor.id == party:getActor().id then
            char_to_return = char_to_return or char
        end
    end
    return char_to_return
end

--- Gets the `Follower` or `Player` of a character currently in the party
---@param party string|PartyMember  The party member to get the character for
---@return Player|Follower?
function World:getPartyCharacterInParty(party)
    if type(party) == "string" then
        party = Game:getPartyMember(party)
    end
    if self.player and Game:hasPartyMember(self.player:getPartyMember()) and party == self.player:getPartyMember() then
        return self.player
    else
        for _,follower in ipairs(self.followers) do
            if Game:hasPartyMember(follower:getPartyMember()) and party == follower:getPartyMember() then
                return follower
            end
        end
    end
end

--- Removes a follower
---@param chara string|Follower The `Follower` or the follower's actor id to remove
---@return Follower follower The follower that was removed
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

--- Spawns a follower into the world
---@param chara     Follower|string|Actor   The character to spawn as a follower
---@param options?  table                 A table defining additional properties to control the new follower
---|"x"         # The position of the follower
---|"y"         # The position of the follower
---|"index"     # The index of the follower in the list of followers
---|"temp"      # Whether the follower is temporary and disappears when the current map is exited (defaults to `true`)
---|"party"     # The id of the party member associated with this follower
---@return Follower
function World:spawnFollower(chara, options)
    if type(chara) == "string" then
        chara = Registry.createActor(chara)
    end
    options = options or {}
    local follower
    if isClass(chara) and chara:includes(Follower) then
        follower = chara
    else
        local x = 0
        local y = 0
        if self.player then
            x = self.player.x
            y = self.player.y
        end
        follower = Follower(chara, x, y)
        follower.layer = self.map.object_layer
        if self.player then
            follower:setFacing(self.player.facing)
        end
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
    if options["party"] then
        follower.party = options["party"]
    end
    self:addChild(follower)
    follower:updateIndex()
    return follower
end

--- Spawns characters in the world for the current party
---@param marker?   string|{x: number, y: number}                               The marker or co-ordinates to spawn the player at
---@param party?    (PartyMember|string)[]                                      A table of party members to spawn (Defaults to [`Game.party`](lua://Game.party))    
---@param extra?    (Follower|Actor|string|[Follower|Actor|string,integer])[]   Additional followers to add that are not in the party (defaults to [`Game.temp_followers`](lua://Game.temp_followers))
---@param facing?   "up"|"down"|"left"|"right"                                  The direction the party should be facing when they spawn
function World:spawnParty(marker, party, extra, facing)
    party = party or Game.party or {"kris"}
    if #party > 0 then
        for i,chara in ipairs(party) do
            if type(chara) == "string" then
                party[i] = Game:getPartyMember(chara)
            end
        end
        if type(marker) == "table" then
            self:spawnPlayer(marker[1], marker[2], party[1]:getActor(), party[1].id)
        else
            self:spawnPlayer(marker or "spawn", party[1]:getActor(), party[1].id)
        end
        if facing then
            self.player:setFacing(facing)
        end
        for i = 2, #party do
            local follower = self:spawnFollower(party[i]:getActor(), {party = party[i].id})
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

--- Spawns a new `WorldBullet` to the world
---@overload fun(self: World, bullet: WorldBullet)
---@param bullet?   string  The bullet to add to the world, if left unspecified, spawns the basic `WorldBullet`
---@param ...       any     Additional arguments to pass to the bullet's init() function
---@return WorldBullet bullet The newly created bullet
function World:spawnBullet(bullet, ...)
    ---@diagnostic disable param-type-mismatch
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
    ---@diagnostic enable param-type-mismatch
end

--- Spawns a new NPC object in the world
---@param actor         string|Actor    The actor to use for the new NPC, either an id string or an actor object
---@param x             number          The x-coordinate to place the NPC at
---@param y             number          The y-coordinate to place the NPC at
---@param properties?   table           A table of additional properties for the new NPC. Supports all the same values as an `npc` map event
---@return NPC npc The newly created npc.
function World:spawnNPC(actor, x, y, properties)
    return self:spawnObject(NPC(actor, x, y, properties))
end

--- Spawns an object to the world
---@param obj Object            The object to add to the world
---@param layer? string|number  The layer to place the object on
---@return Object
function World:spawnObject(obj, layer)
    obj.layer = self:parseLayer(layer)
    self:addChild(obj)
    return obj
end

--- Gets a specific character currently present in the world
---@param id        string  The actor id of the character to search for
---@param index?    number  The character's index, if they have multiple instances in the world. (Defaults to `1`)
---@return Character|nil chara The character instance, or `nil` if it was not found
function World:getCharacter(id, index)
    local party_member = Game:getPartyMember(id)
    local i = 0
    for _,chara in ipairs(Game.stage:getObjects(Character)) do
        if chara.actor.id == id or (party_member and chara.party and chara.party == party_member.id) then
            i = i + 1
            if not index or index == i then
                return chara
            end
        end
    end
end

--- Gets the action box instance for a member of the party
---@param party_member string|PartyMember
---@return OverworldActionBox?
function World:getActionBox(party_member)
    if not self.healthbar then return nil end
    if type(party_member) == "string" then
        party_member = Game:getPartyMember(party_member)
    end
    for _,box in ipairs(self.healthbar.action_boxes) do
        if box.chara == party_member then
            return box
        end
    end
    return nil
end

--- Creates a reaction text on a party member's healthbar (usually used for equipment and items)
---@param party_member  string|PartyMember  The party member who will react
---@param text          string              The text to display for the reaction
---@param display_time? number              The display time, in seconds, of the reaction (defaults to 5/3 seconds)
function World:partyReact(party_member, text, display_time)
    local action_box = self:getActionBox(party_member)
    if action_box then
        action_box:react(text, display_time)
    end
end

--- Gets a specific event present in the current map
---@param id string|number  The unique numerical id of an event OR the text id of an event type to get the first instance of
---@return Event event The event instnace, or `nil` if it was not found
function World:getEvent(id)
    return self.map:getEvent(id)
end

--- Gets a list of all instances of one type of event in the current maps
---@param name? string The text id of the event to search for, fetches every event if `nil`
---@return Event[] events A table containing every instance of the event in the current map
function World:getEvents(name)
    return self.map:getEvents(name)
end

--- Disables following for all of the player's current followers
function World:detachFollowers()
    for _,follower in ipairs(self.followers) do
        follower.following = false
    end
end

--- Enables following for all of the player's current followers and causes them to walk to their positions
---@param return_speed? number The walking speed of the followers while they return to the player
function World:attachFollowers(return_speed)
    for _,follower in ipairs(self.followers) do
        follower:updateIndex()
        follower:returnToFollowing(return_speed)
    end
end
--- Enables following for all of the player's current followers, and immediately teleports them to their positions
function World:attachFollowersImmediate()
    for _,follower in ipairs(self.followers) do
        follower.following = true

        follower:updateIndex()
        follower:moveToTarget()
    end
end

--- Parses a variable-type layer specification into a recognised layer
---@param layer?    number|string
---@return number
function World:parseLayer(layer)
    return (type(layer) == "number" and layer)
            or WORLD_LAYERS[layer]
            or self.map.layers[layer]
            or self.map.object_layer
end

--- Sets up several variables for a new map
---@param map? Map|string|table The Map object, name, or data to load
---@param ... unknown           Additional arguments that will be passed forward into Map:onEnter()
function World:setupMap(map, ...)
    for _,child in ipairs(self.children) do
        if not child.persistent then
            self:removeChild(child)
        end
    end
    for _,child in ipairs(self.controller_parent.children) do
        if not child.persistent then
            self.controller_parent:removeChild(child)
        end
    end

    self:updateChildList()

    self.healthbar = nil
    self.followers = {}

    self.camera:resetModifiers(true)
    self.camera:setAttached(true)

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

    local dark_transitioned = self.map.light ~= Game:isLight()

    Game:setLight(self.map.light)

    self.width = self.map.width * self.map.tile_width
    self.height = self.map.height * self.map.tile_height

    --self.camera:setBounds(0, 0, self.map.width * self.map.tile_width, self.map.height * self.map.tile_height)

    self.battle_fader = Rectangle(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
    self.battle_fader:setParallax(0, 0)
    self.battle_fader:setColor(0, 0, 0)
    self.battle_fader.alpha = 0
    self.battle_fader.layer = self.map.battle_fader_layer
    self.battle_fader.debug_select = false
    self:addChild(self.battle_fader)

    self.in_battle = false
    self.in_battle_area = false
    self.battle_alpha = 0

    local map_border = self.map:getBorder(dark_transitioned)
    if map_border then
        Game:setBorder(Kristal.callEvent(KRISTAL_EVENT.onMapBorder, self.map, map_border) or map_border)
    end

    if not self.map.keep_music then
        self:transitionMusic(Kristal.callEvent(KRISTAL_EVENT.onMapMusic, self.map, self.map.music) or self.map.music)
    end
end

--- Loads into a new map file.
---@overload fun(self: World, map: string, x: number, y: number, facing?: string, callback?: string, ...: any)
---@overload fun(self: World, map: string, marker?: string, facing?: string, callback?: string, ...: any)
---@param map       string      The name of the map file to load
---@param x         number      The x-coordinate the player will spawn at in the new map
---@param y         number      The y-coordinate the player will spawn at in the new map
---@param marker?   string      The name of the marker the player will spawn at in the new map (Defaults to `"spawn"`)
---@param facing?   string      The direction the party should be facing when they spawn in the new map
---@param callback? fun()       A callback to run once the map has finished loading (Post Map:onEnter())
---@param ... unknown           Additional arguments that will be passed forward into Map:onEnter()
function World:loadMap(...)
    local args = {...}
    -- x, y, facing, callback
    local map = table.remove(args, 1)
    local marker, x, y, facing, callback
    if type(args[1]) == "string" then
        marker = table.remove(args, 1)
    elseif type(args[1]) == "number" then
        x = table.remove(args, 1)
        y = table.remove(args, 1)
    else
        marker = "spawn"
    end
    if args[1] then
        facing = table.remove(args, 1)
    end
    if args[1] then
        callback = table.remove(args, 1)
    end

    if self.map then
        self.map:onExit()
    end

    self:setupMap(map, unpack(args))

    if self.map.markers["spawn"] then
        local spawn = self.map.markers["spawn"]
        self.camera:setPosition(spawn.center_x, spawn.center_y)
    end

    if marker then
        self:spawnParty(marker, nil, nil, facing)
    else
        self:spawnParty({x, y}, nil, nil, facing)
    end

    self:setState("GAMEPLAY")

    for _,event in ipairs(self.map.events) do
        if event.postLoad then
            event:postLoad()
        end
    end

    self.map:onEnter()

    if callback then
        callback(self.map)
    end
end

--- Transitions the music from the current track to the `next`
---@overload fun(self: World, music: string)
---@param music     string                                              The name of the file to play next
---@param next      {music?: string, volume?: number, pitch?: number}   The filename, volume, and pitch of the next track
---@param fade_out? boolean                                             Whether to fade out the currently playing track before playing the next track
function World:transitionMusic(next, fade_out)
    -- Compatibility with older versions of transitionMusic which have "next" as the music
    local music = ""
    local volume = 1
    local pitch = 1
    if type(next) == "table" then
        music = next[1]
        volume = next[2]
        pitch = next[3]
    else
        music = next
    end
    --
    if music and music ~= "" then
        if self.music.current ~= music then
            if self.music:isPlaying() and fade_out then
                self.music:fade(0, 10/30, function() self.music:stop() end)
            elseif not fade_out then
                self.music:play(music, volume, pitch)
            end
        else
            if not self.music:isPlaying() then
                if not fade_out then
                    self.music:play(music, volume, pitch)
                end
            else
                self.music:fade(volume)
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

--- Transitions from the world into a shop
---@param shop      string|Shop The shop to enter
---@param options?  table       An optional table of [`leave_options`](lua://Shop.leave_options) for exiting the shop
function World:shopTransition(shop, options)
    self:fadeInto(function()
        Game:enterShop(shop, options)
    end)
end

--- Loads a new map and starts the transition effects for world music, borders, and the screen as a whole
---@overload fun(self: World, map: string, ...: any)
---@param ... any   Additional arguments that will be passed into World:loadMap()
---@see World - World:loadMap() 
function World:mapTransition(...)
    local args = {...}
    local map = args[1]
    if type(map) == "string" then
        local map = Registry.createMap(map)
        if not map.keep_music then
            self:transitionMusic(Kristal.callEvent(KRISTAL_EVENT.onMapMusic, self.map, self.map.music) or map.music, true)
        end
        local dark_transition = map.light ~= Game:isLight()
        local map_border = map:getBorder(dark_transition)
        if map_border then
            Game:setBorder(Kristal.callEvent(KRISTAL_EVENT.onMapBorder, self.map, map_border) or map_border, 1)
        end
    end
    self:fadeInto(function()
        self:loadMap(Utils.unpack(args))
    end)
end

--- Fades the world out and into another piece of content
---@param callback fun()    The callback that is run in the middle of the fade (fully faded out) to load the next piece of content
function World:fadeInto(callback)
    self:setState("FADING")
    Game.fader:transition(callback)
end

--- Gets the object that the camera is currently targetting
---@return Object|nil
function World:getCameraTarget()
    if self.camera.target and self.camera.target.stage then
        return self.camera.target
    else
        return self.player
    end
end

--- Sets the object the camera should target
---@param target Object?
function World:setCameraTarget(target)
    self.camera.target = target
end

--- Sets whether the camera should be attached to its target for each axis
---@param attached_x? boolean   Whether the camera's x-axis position should follow its target
---@param attached_y? boolean   Whether the camera's y-axis position should follow its target
function World:setCameraAttached(attached_x, attached_y)
    self.camera:setAttached(attached_x, attached_y)
end

--- Sets whether the camera should follow its target on the x-axis
---@param attached? boolean
function World:setCameraAttachedX(attached) self:setCameraAttached(attached, self.camera.attached_x) end
--- Sets whether the camera should follow its target on the y-axis
---@param attached? boolean
function World:setCameraAttachedY(attached) self:setCameraAttached(self.camera.attached_y, attached) end

---@param x? number
---@param y? number
---@param friction? number
function World:shakeCamera(x, y, friction)
    self.camera:shake(x, y, friction)
end

function World:sortChildren()
    Utils.pushPerformance("World#sortChildren")
    Object.startCache()
    local positions = {}
    for _,child in ipairs(self.children) do
        local x, y = child:getSortPosition()
        positions[child] = {x = x, y = y}
    end
    table.stable_sort(self.children, function(a, b)
        local a_pos, b_pos = positions[a], positions[b]
        local ax, ay = a_pos.x, a_pos.y
        local bx, by = b_pos.x, b_pos.y
        -- Sort children by Y position, or by follower index if it's a follower/player (so the player is always on top)
        return a.layer < b.layer or
              (a.layer == b.layer and (math.floor(ay) < math.floor(by) or
              (math.floor(ay) == math.floor(by) and (b == self.player or
              (a:includes(Follower) and b:includes(Follower) and b.index < a.index)))))
    end)
    Object.endCache()
    Utils.popPerformance()
end

---@param parent Object
function World:onRemove(parent)
    super.onRemove(self, parent)

    self.music:remove()
end

--- Sets whether the player is currently in battle - cannot override being inside a battle area
---@param value boolean
function World:setBattle(value)
    self.in_battle = value
end

--- Whether the player is currently in a world battle
---@return boolean
function World:inBattle()
    return self.in_battle or self.in_battle_area
end

function World:update()
    if self.state == "GAMEPLAY" then
        -- Object collision
        local collided = {}
        local exited = {}
        Object.startCache()
        for _,obj in ipairs(self.children) do
            if not obj.solid and (obj.onCollide or obj.onEnter or obj.onExit) then
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

    if self:inBattle() then
        self.battle_alpha = math.min(self.battle_alpha + (0.08 * DTMULT), 1)
    else
        self.battle_alpha = math.max(self.battle_alpha - (0.08 * DTMULT), 0)
    end

    local half_alpha = self.battle_alpha * 0.52

    for _,v in ipairs(self.followers) do
        v.sprite:setColor(1 - half_alpha, 1 - half_alpha, 1 - half_alpha, 1)
    end

    for _,battle_border in ipairs(self.map.battle_borders) do
        battle_border.alpha = self.battle_alpha
    end
    if self.battle_fader then
        self.battle_fader:setColor(0, 0, 0, half_alpha)
    end

    if (self.door_delay > 0) then
        self.door_delay = math.max(self.door_delay - DT, 0)
    end

    self.map:update()

    -- Always sort
    self.update_child_list = true
    super.update(self)

    -- Update cutscene after updating objects
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
end

function World:draw()
    -- Draw background
    Draw.setColor(self.map.bg_color or {0, 0, 0, 0})
    love.graphics.rectangle("fill", 0, 0, self.map.width * self.map.tile_width, self.map.height * self.map.tile_height)
    Draw.setColor(1, 1, 1)

    super.draw(self)

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

function World:canDeepCopy()
    return false
end

return World