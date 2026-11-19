--- Warp Doors allow for fast travel between Overworld locations. \
--- `WarpDoor` is an [`Event`](lua://Event.init) - naming an object `warpdoor` on an `objects` layer in a map creates this object. \
--- See this object's Fields for the configurable properties on this object.
---
---@class WarpDoor : Event
---
---@field solid         boolean
---@field collider      Collider
---@field light         Sprite      Sprite instance for the light that appears under an active door
---
---@field open          boolean     *[Property `open`]* Whether the door is open (Defaults to `true`)
---@field open_flag     string      *[Property `openflag`]* The name of a flag that will be used to control the state of the door
---
---@field maps          table<string, string> Maps from the `destinations` array, keyed by display name.
---@field names         string[] Destination display names.
---@field markers       table<string, MarkerRef> Destination markers, keyed by display name.
---@field flags         string[] Flags controlling destination availability.
---
---@overload fun(...) : WarpDoor
local WarpDoor, super = Class(Event, "warpdoor")

function WarpDoor:init(x, y, properties)
    super.init(self, x, y)
    self:setSprite("world/events/shortcut_door_off")
    self:setOrigin(0.5, 1)
    self.solid = true
    self.collider = Hitbox(self, 0, 58, 72, 40)

    self.open = properties["open"] ~= false
    self.open_flag = properties["openflag"]
    if self.open_flag then
        self.open = Game:getFlag(self.open_flag)
    end

    if self.open then
        self:setSprite("world/events/shortcut_door")
        self.light = Sprite("world/events/shortcut_light", 8, 96)
        self.light:play(0.25, true)
        self.light:setScale(2)
        self:addChild(self.light)
    end

    self.maps = {}
    self.names = {}
    self.markers = {}
    self.flags = {}
    for i, destination in ipairs(properties.destinations or {}) do
        if destination.name and destination.name ~= "" then
            self.names[i] = destination.name
        else
            self.names[i] = StringUtils.titleCase(destination.map or "")
        end
        if destination.flag and destination.flag ~= "" then
            self.flags[i] = destination.flag
        end
        local marker = destination.marker
        local marker_map = type(marker) == "table" and (marker.map_id or marker.map) or nil
        self.maps[self.names[i]] = marker_map or destination.map
        self.markers[self.names[i]] = marker
    end
end

function WarpDoor:onInteract(chara, facing)
    if not self.open then
        Game.world:showText("* (It's a lone doorframe.)[wait:5]\n* (But for some reason,[wait:5] you can't\nsee through it...)")
    else
        Game.world:startCutscene(function(cutscene)
            cutscene:text("* (It's a door.)[wait:5]\n* (Where will you go?)")
            local choices = {}
            for i=1,#self.names do
                if not self.flags[i] or Game:getFlag(self.flags[i], false) then
                    table.insert(choices, self.names[i])
                end
            end
            table.insert(choices, "Cancel")
            local choice_i = cutscene:choicer(choices)
            if choice_i < #choices then
                local name = choices[choice_i]
                local map = self.maps[name]
                if map == self.world.map.id then
                    cutscene:text("* (Amazingly,[wait:5] you are already there.)")
                else
                    Assets.playSound("dooropen")
                    self.sprite:setFrame(2)
                    self.light:remove()
                    cutscene:text("* (The door opened...)")
                    cutscene:wait(0.2) -- 6/30
                    Assets.stopAllSounds()
                    Assets.playSound("doorclose")
                    Game.world.music:stop()
                    Game.world.fader:fadeOut(nil, {
                        speed = 0,
                    })
                    cutscene:wait(1)
                    cutscene:loadMap(map, self.markers[name] or "spawn", "down", function() Assets.playSound("dooropen") end)
                    Game.world.fader:fadeIn(nil, {
                        speed = 0.25,
                    })
                end
            else
                cutscene:text("* (You doorn't.)")
            end
        end)
    end

    return true
end

--- Updates the state of the door based on its `open_flag`, and accordingly adjusts it's own sprite and its [`light`](lua://WarpDoor.light)
function WarpDoor:updateOpen()
    self.open = Game:getFlag(self.open_flag)
    if self.open then
        self:setSprite("world/events/shortcut_door")
        if not self.light then
            self.light = Sprite("world/events/shortcut_light", 8, 96)
            self.light:play(0.25, true)
            self.light:setScale(2)
            self:addChild(self.light)
        end
    else
        self:setSprite("world/events/shortcut_door_off")
        if self.light then
            self.light:remove()
        end
    end
end

return WarpDoor
