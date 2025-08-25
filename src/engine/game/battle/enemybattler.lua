--- `EnemyBattler`s are a type of `Battler` that represent enemies, defining all their properties and behaviours. \
--- Every enemy defined in a mod should be located in its own file in `scripts/battle/enemies/`, and should extend this class. \
--- Each enemy is assigned an id that defaults to their filepath starting from `scripts/battle/enemies`, unless an id is specified as an argument to `Class()`. \
--- Enemies are added to battles in the encounter, with [`Encounter:addEnemy(enemy, x, y, ...)`](lua://Encounter.addEnemy), where `enemy` is their unique id, and all enemies for the current battle reside in [`Game.battle.enemies`](lua://Battle.enemies)
---
--- Recruit data is separate to enemies, see [`Recruit`](lua://Recruit.init) for how to set up a corresponding recruit.
---
---@class EnemyBattler : Battler
---
---@field max_health        integer             The maximum health of this enemy
---@field health            integer             The current health of this enemy
---@field attack            integer             The attack stat of this enemy
---@field defense           integer             The defense stat of this enemy
---
---@field money             integer             The money added to the battle prize money when this enemy is defeated
---@field experience        number              The experience gained when this enemy is defeated
---@field tired             boolean             Whether this enemy is tired
---@field mercy             number              The amount of mercy points this enemy has
---
---@field spare_points      number              The amount of mercy that is added to this enemy when a character spares them below max mercy
---
---@field exit_on_defeat    boolean
---
---@field auto_spare        boolean
---
---@field can_freeze        boolean             Whether this enemy can be frozen
---
---@field selectable        boolean             Whether this enemy is selectable in menus
---
---@field dmg_sprites       Sprite[]            A list of this enemy's damage sprites
---@field dmg_sprite_offset [number, number]    The offset of this enemy's damage sprites
---
---@field disable_mercy     boolean             Whether this enemy has mercy disabled (such as with snowgrave Spamton NEO). Only affects the mercy bar.
---
---@field waves             string[]            A list of wave ids this enemy can use - one is selected each turn in [`EnemyBattler:selectWave()`](lua://EnemyBattler.selectWave)
---@field wave_override     string              A wave id that will be used by the enemy this turn rather than a randomly selected wave. Reset every turn.
---
---@field check             string[]|string     The flavour text displayed when this enemy is checked. Stat text is added automatically.
---
---@field text              string[]            A list of encounter flavour texts that can be selected from at random to display in the battle box at the start of each turn
---
---@field low_health_text   string?             A special text that displays when this enemy is at low HP. See [`low_health_percentage`](lua://EnemyBattler.low_health_percentage) for defining the low HP threshold.
---@field tired_text        string?             A special text that displays when this enemy is TIRED.
---@field spareable_text    string?             A special text that displays when this enemy is spareable.
---
---@field tired_percentage      number          A number from 0-1 that defines what percentage of maximum hp this enemy should become tired at
---@field low_health_percentage number          A number from 0-1 that defines what percentage of maximum hp the [`low_health_text`](lua://EnemyBattler.low_health_text) of this enemy starts displaying
---
---@field dialogue_bubble   string?
---
---@field dialogue_offset   [number, number]    The offset of this enemy's dialogue bubble
---
---@field dialogue      table<string[]|string>  A list of dialogue choices this enemy will select one from at the start of every attacking turn
---@field dialogue_override string[]|string?    An instance of dialogue that will be used on the enemy this turn instead of a randomly selected dialogue. Reset every turn.
---
---@field acts              table<table>        *(Used internally)* Stores the data of all ACTs available on this enemy
---
---@field hurt_timer        number              How long this enemy's hurt sprite should be displayed for when hit
---@field comment           string              The text displayed next to this enemy's name in menu's (such as "(Tired)" in DELTARUNE) 
---@field defeated          boolean             Whether this enemy has been defeated
---
---@field temporary_mercy           number              The current amount of temporary mercy
---@field temporary_mercy_percent   DamageNumber|nil    The DamageNumber object, used to update the mercy display
---
---@overload fun(actor?:Actor|string, use_overlay?:boolean) : EnemyBattler
local EnemyBattler, super = Class(Battler)

---@param actor?        Actor|string
---@param use_overlay?  boolean
function EnemyBattler:init(actor, use_overlay)
    super.init(self)
    self.name = "Test Enemy"

    if actor then
        self:setActor(actor, use_overlay)
    end

    self.max_health = 100
    self.health = 100
    self.attack = 1
    self.defense = 0

    self.money = 0
    self.experience = 0 -- currently useless, maybe in later chapters?

    self.tired = false
    self.mercy = 0

    self.spare_points = 0

    -- Whether this enemy runs/slides away when defeated/spared
    self.exit_on_defeat = true

    -- Whether this enemy is automatically spared at full mercy
    self.auto_spare = false

    self.can_freeze = true

    self.selectable = true

    self.dmg_sprites = {}
    self.dmg_sprite_offset = {0, 0}

    self.disable_mercy = false

    self.done_state = nil

    self.waves = {}

    self.check = "Remember to change\nyour check text!"

    self.text = {}

    self.low_health_text = nil
    self.tired_text = nil
    self.spareable_text = nil

    self.tired_percentage = 0.5
    self.low_health_percentage = 0.5

    -- This is set to nil in `battler.lua` as well, but it's here for completion's sake.

    -- Speech bubble style - defaults to "round" or "cyber", depending on chapter
    self.dialogue_bubble = nil

    self.dialogue_offset = {0, 0}

    self.dialogue = {}

    self.acts = {
        {
            ["name"] = "Check",
            ["description"] = "",
            ["party"] = {}
        }
    }

    self.hurt_timer = 0
    self.comment = ""
    self.icons = {}
    self.defeated = false

    self.current_target = "ANY"

    self.temporary_mercy = 0
    self.temporary_mercy_percent = nil

    self.graze_tension = 1.6 -- (1/10 of a defend, or cheap spell)
end

--- Get the default graze tension for this enemy.
--- Any bullets which don't specify graze tension will use this value.
---@return number tension The tension to gain when bullets spawned by this enemy are grazed.
function EnemyBattler:getGrazeTension()
    return self.graze_tension
end

---@param bool boolean
function EnemyBattler:setTired(bool)
    local old_tired = self.tired
    self.tired = bool
    if self.tired then
        self.comment = "(Tired)"
        if not old_tired and Game:getConfig("tiredMessages") then
            -- Check for self.parent so setting Tired state in init doesn't crash
            if self.parent then
                self:statusMessage("msg", "tired")
                Assets.playSound("spellcast", 0.5, 0.9)
            end
        end
    else
        self.comment = ""
        if old_tired and Game:getConfig("awakeMessages") then
            if self.parent then self:statusMessage("msg", "awake") end
        end
    end
end

--- Registers a new ACT for this enemy. This function is best called in [`EnemyBattler:init()`](lua://EnemyBattler.init) for most acts, unless they only appear under specific conditions. \
--- What happens when this act is used is controlled by [`EnemyBattler:onAct()`](lua://EnemyBattler.onAct) - acts that do not return text there will **softlock** Kristal.
---@param name          string          The name of the act
---@param description?  string          The short description of the act that appears in the menu
---@param party?        string[]|string A list of party member ids required to use this act. Alternatively, the keyword `"all"` can be used to insert the entire current party
---@param tp?           number          An amount of TP required to use this act
---@param highlight?    Battler[]       A list of battlers that will be highlighted when the act is used, overriding default highlighting logic             
---@param icons?        string[]        A list of texture paths to icons that will display next to the name of this act (party member heads are drawn automatically as required)
---@return table act    The data of the act, also added to the `acts` table
function EnemyBattler:registerAct(name, description, party, tp, highlight, icons)
    if type(party) == "string" then
        if party == "all" then
            party = {}
            for _,chara in ipairs(Game.party) do
                table.insert(party, chara.id)
            end
        else
            party = {party}
        end
    end
    local act = {
        ["character"] = nil,
        ["name"] = name,
        ["description"] = description,
        ["party"] = party,
        ["tp"] = tp or 0,
        ["highlight"] = highlight,
        ["short"] = false,
        ["icons"] = icons
    }
    table.insert(self.acts, act)
    return act
end

--- Registers a new Short ACT for this enemy. This function is best called in [`EnemyBattler:init()`](lua://EnemyBattler.init) for most acts, unless they only appear under specific conditions. \
--- What happens when this act is used is controlled by [`EnemyBattler:onShortAct()`](lua://EnemyBattler.onShortAct) - acts that do not return text there will **softlock** Kristal.
---@param name          string          The name of the act
---@param description?  string          The short description of the act that appears in the menu
---@param party?        string[]|string A list of party member ids required to use this act. Alternatively, the keyword `"all"` can be used to insert the entire current party
---@param tp?           number          An amount of TP required to use this act
---@param highlight?    Battler[]       A list of battlers that will be highlighted when the act is used, overriding default highlighting logic             
---@param icons?        string[]        A list of texture paths to icons that will display next to the name of this act (party member heads are drawn automatically as required)
---@return table act    The data of the act, also added to the `acts` table
function EnemyBattler:registerShortAct(name, description, party, tp, highlight, icons)
    if type(party) == "string" then
        if party == "all" then
            party = {}
            for _,battler in ipairs(Game.battle.party) do
                table.insert(party, battler.id)
            end
        else
            party = {party}
        end
    end
    local act = {
        ["character"] = nil,
        ["name"] = name,
        ["description"] = description,
        ["party"] = party,
        ["tp"] = tp or 0,
        ["highlight"] = highlight,
        ["short"] = true,
        ["icons"] = icons
    }
    table.insert(self.acts, act)
    return act
end

--- Registers a new ACT for this enemy that is usable by a specific character. This function is best called in [`EnemyBattler:init()`](lua://EnemyBattler.init) for most acts, unless they only appear under specific conditions. \
--- What happens when this act is used is controlled by [`EnemyBattler:onAct()`](lua://EnemyBattler.onAct) - acts that do not return text there will **softlock** Kristal.
---@param char          string          The id of the character that can use this act
---@param name          string          The name of the act
---@param description?  string          The short description of the act that appears in the menu
---@param party?        string[]|string A list of party member ids required to use this act. Alternatively, the keyword `"all"` can be used to insert the entire current party
---@param tp?           number          An amount of TP required to use this act
---@param highlight?    Battler[]       A list of battlers that will be highlighted when the act is used, overriding default highlighting logic             
---@param icons?        string[]        A list of texture paths to icons that will display next to the name of this act (party member heads are drawn automatically as required)
function EnemyBattler:registerActFor(char, name, description, party, tp, highlight, icons)
    if type(party) == "string" then
        if party == "all" then
            party = {}
            for _,chara in ipairs(Game.party) do
                table.insert(party, chara.id)
            end
        else
            party = {party}
        end
    end
    local act = {
        ["character"] = char,
        ["name"] = name,
        ["description"] = description,
        ["party"] = party,
        ["tp"] = tp or 0,
        ["highlight"] = highlight,
        ["short"] = false,
        ["icons"] = icons
    }
    table.insert(self.acts, act)
end

--- Registers a new Short ACT for this enemy, usable by a specific character. This function is best called in [`EnemyBattler:init()`](lua://EnemyBattler.init) for most acts, unless they only appear under specific conditions. \
--- What happens when this act is used is controlled by [`EnemyBattler:onShortAct()`](lua://EnemyBattler.onShortAct) - acts that do not return text there will **softlock** Kristal.
---@param char          string          The id of the character that can use this act
---@param name          string          The name of the act
---@param description?  string          The short description of the act that appears in the menu
---@param party?        string[]|string A list of party member ids required to use this act. Alternatively, the keyword `"all"` can be used to insert the entire current party
---@param tp?           number          An amount of TP required to use this act
---@param highlight?    Battler[]       A list of battlers that will be highlighted when the act is used, overriding default highlighting logic             
---@param icons?        string[]        A list of texture paths to icons that will display next to the name of this act (party member heads are drawn automatically as required)
function EnemyBattler:registerShortActFor(char, name, description, party, tp, highlight, icons)
    if type(party) == "string" then
        if party == "all" then
            party = {}
            for _,battler in ipairs(Game.battle.party) do
                table.insert(party, battler.id)
            end
        else
            party = {party}
        end
    end
    local act = {
        ["character"] = char,
        ["name"] = name,
        ["description"] = description,
        ["party"] = party,
        ["tp"] = tp or 0,
        ["highlight"] = highlight,
        ["short"] = true,
        ["icons"] = icons
    }
    table.insert(self.acts, act)
end

---@param name string
function EnemyBattler:removeAct(name)
    for i,act in ipairs(self.acts) do
        if act.name == name then
            table.remove(self.acts, i)
            break
        end
    end
end

--- Non-violently defeats the enemy and removes them from battle (if [`exit_on_defeat`](lua://EnemyBattler.exit_on_defeat) is `true`)
---@param pacify?   boolean Whether the enemy was defeated by pacifying them rather than sparing them (defaults to `false`)
function EnemyBattler:spare(pacify)
    if self.exit_on_defeat then
        Game.battle.spare_sound:stop()
        Game.battle.spare_sound:play()

        local spare_flash = self:addFX(ColorMaskFX())
        spare_flash.amount = 0

        local sparkle_timer = 0
        local parent = self.parent

        Game.battle.timer:during(5/30, function()
            spare_flash.amount = spare_flash.amount + 0.2 * DTMULT
            sparkle_timer = sparkle_timer + DTMULT
            if sparkle_timer >= 0.5 then
                local x, y = Utils.random(0, self.width), Utils.random(0, self.height)
                local sparkle = SpareSparkle(self:getRelativePos(x, y))
                sparkle.layer = self.layer + 0.001
                parent:addChild(sparkle)
                sparkle_timer = sparkle_timer - 0.5
            end
        end, function()
            spare_flash.amount = 1
            local img1 = AfterImage(self, 0.7, (1/25) * 0.7)
            local img2 = AfterImage(self, 0.4, (1/30) * 0.4)
            img1:addFX(ColorMaskFX())
            img2:addFX(ColorMaskFX())
            img1.physics.speed_x = 4
            img2.physics.speed_x = 8
            parent:addChild(img1)
            parent:addChild(img2)
            self:remove()
        end)
        
        self:defeat(pacify and "PACIFIED" or "SPARED", false)
    end

    self:onSpared()
end

--- Gets the text that should appear in the battle box when a battler attempts to spare this enemy
---@param battler PartyBattler
---@param success boolean       Whether the enemy was spared successfully
---@return string[]|string
function EnemyBattler:getSpareText(battler, success)
    if success then
        return "* " .. battler.chara:getName() .. " spared " .. self.name .. "!"
    else
        local text = "* " .. battler.chara:getName() .. " spared " .. self.name .. "!\n* But its name wasn't [color:yellow]YELLOW[color:reset]..."
        if self.tired then
            local found_spell = nil
            for _,party in ipairs(Game.battle.party) do
                for _,spell in ipairs(party.chara:getSpells()) do
                    if spell:hasTag("spare_tired") then
                        found_spell = spell
                        break
                    end
                end
                if found_spell then
                    text = {text, "* (Try using "..party.chara:getName().."'s [color:blue]"..found_spell:getCastName().."[color:reset]!)"}
                    break
                end
            end
            if not found_spell then
                text = {text, "* (Try using [color:blue]ACTs[color:reset]!)"}
            end
        end
        return text
    end
end

--- *(Override)*
---@return boolean spareable
function EnemyBattler:canSpare()
    return self.mercy >= 100
end

--- *(Override)* Called when the enemy is spared
function EnemyBattler:onSpared()
    self:setAnimation("spared")
end

--- *(Override)* Called when the enemy becomes spareable
--- *By default, sets the enemy's animation to `"spared"` (if it exists)*
function EnemyBattler:onSpareable()
    self:setAnimation("spared")
end

--- Adds (or removes) mercy from this enemy
---@param amount number
function EnemyBattler:addMercy(amount)
    if (amount >= 0 and self.mercy >= 100) or (amount < 0 and self.mercy <= 0) then
        -- We're already at full mercy and trying to add more; do nothing.
        -- Also do nothing if trying to remove from an empty mercy bar.
        return
    end

    self.mercy = self.mercy + amount
    if self.mercy < 0 then
        self.mercy = 0
    end

    if self.mercy >= 100 then
        self.mercy = 100
    end

    if self:canSpare() then
        self:onSpareable()
        if self.auto_spare then
            self:spare(false)
        end
    end

    if Game:getConfig("mercyMessages") then
        if amount == 0 then
            self:statusMessage("msg", "miss")
        else
            if amount > 0 then
                local pitch = 0.8
                if amount < 99 then pitch = 1 end
                if amount <= 50 then pitch = 1.2 end
                if amount <= 25 then pitch = 1.4 end

                local src = Assets.playSound("mercyadd", 0.8)
                src:setPitch(pitch)
            end

            self:statusMessage("mercy", amount)
        end
    end
end

--- Adds (or removes) temporary mercy from this enemy. *Temporary mercy persists until kill_condition is true at any point.*
---@param amount number
---@param play_sound? boolean       Whether to play a sound the first time temporary mercy is added
---@param clamp? [number, number]   A table containing 2 number values that controls the range of the temporary mercy. Defaults to {0, 100}
---@param kill_condition? function  A function that should return true when the temporary mercy should start to fade out.
function EnemyBattler:addTemporaryMercy(amount, play_sound, clamp, kill_condition)
    kill_condition = kill_condition or function ()
        return Game.battle.state ~= "DEFENDING" and Game.battle.state ~= "DEFENDINGEND"
    end

    clamp = clamp or {0, 100}

    self.temporary_mercy = self.temporary_mercy + amount

    local min, max = clamp[1], clamp[2]
    self.temporary_mercy = Utils.clamp(self.temporary_mercy, min, max)

    if Game:getConfig("mercyMessages") then
        if self.temporary_mercy == 0 then
            if not self.temporary_mercy_percent then
                self.temporary_mercy_percent = self:statusMessage("msg", "miss")
                self.temporary_mercy_percent.kill_condition = kill_condition
                self.temporary_mercy_percent.kill_others = true
                -- In Deltarune, the mercy percent takes a bit more time to start to fade out after the enemy's turn ends
                self.temporary_mercy_percent.kill_delay = 30
            else
                self.temporary_mercy_percent:setDisplay("msg", "miss")
            end
        else
            if not self.temporary_mercy_percent then
                self.temporary_mercy_percent = self:statusMessage("mercy", self.temporary_mercy)
                self.temporary_mercy_percent.kill_condition = kill_condition
                self.temporary_mercy_percent.kill_others = true
                self.temporary_mercy_percent.kill_delay = 30

                -- Only play the mercyadd sound when the DamageNumber is first shown
                if play_sound ~= false then
                    if amount > 0 then
                        local pitch = 0.8
                        if amount < 99 then pitch = 1 end
                        if amount <= 50 then pitch = 1.2 end
                        if amount <= 25 then pitch = 1.4 end

                        local src = Assets.playSound("mercyadd", 0.8)
                        src:setPitch(pitch)
                    end
                end
            else
                self.temporary_mercy_percent:setDisplay("mercy", self.temporary_mercy)
            end
        end
    end
end

--- *(Override)* Called when a battler uses mercy on (spares) the enemy \
--- *By default, responsible for sparing the enemy or increasing their mercy points by [`spare_points`](lua://EnemyBattler.spare_points)*
---@param battler PartyBattler
---@return boolean success  Whether the mercy resulted in a spare
function EnemyBattler:onMercy(battler)
    if self:canSpare() then
        self:spare()
        return true
    else
        self:addMercy(self.spare_points)
        return false
    end
end

--- Creates the particular flash effect used when a party member uses mercy on the enemy, but the spare fails
---@param color? table The color the enemy should flash (defaults to yellow)
function EnemyBattler:mercyFlash(color)
    color = color or {1, 1, 0}

    local recolor = self:addFX(RecolorFX())
    Game.battle.timer:during(8/30, function()
        recolor.color = Utils.lerp(recolor.color, color, 0.12 * DTMULT)
    end, function()
        Game.battle.timer:during(8/30, function()
            recolor.color = Utils.lerp(recolor.color, {1, 1, 1}, 0.16 * DTMULT)
        end, function()
            self:removeFX(recolor)
        end)
    end)
end

--- *(Override)* Returns a nested table of colors `{r, g, b}` that the enemy's name will display in, with multiple colors forming a gradient, and one forming a solid color.
--- *By default, returns a table with the spareable and tired colors, if the enemy meets their conditions
---@return table<[number, number, number]>  colors
function EnemyBattler:getNameColors()
    local result = {}
    if self:canSpare() then
        table.insert(result, {1, 1, 0})
    end
    if self.tired then
        local tiredcol = {0, 0.7, 1}
        if Game:getConfig("pacifyGlow") then
            local battler = Game.battle.party[Game.battle.current_selecting]
            local can_pacify
            for _, spell in ipairs(battler.chara:getSpells()) do
                if spell:hasTag("spare_tired") then
                    can_pacify = true
                    break
                end
            end
            if can_pacify then
                tiredcol = Utils.mergeColor(tiredcol, COLORS.white, 0.5 + math.sin(Game.battle.pacify_glow_timer / 4) * 0.5)
            end
        end
        table.insert(result, tiredcol)
    end
    return result
end

--- Gets the encounter text that should be shown in the battle box if this enemy is chosen for encounter text. Called at the start of each turn.
---@return string? text
function EnemyBattler:getEncounterText()
    local has_spareable_text = self.spareable_text and self:canSpare()

    local priority_spareable_text = Game:getConfig("prioritySpareableText")
    if priority_spareable_text and has_spareable_text then
        return self.spareable_text
    end

    if self.low_health_text and self.health <= (self.max_health * self.low_health_percentage) then
        return self.low_health_text

    elseif self.tired_text and self.tired then
        return self.tired_text

    elseif has_spareable_text then
        return self.spareable_text
    end

    return Utils.pick(self.text)
end

---@return string
function EnemyBattler:getTarget()
    return Game.battle:randomTarget()
end

--- *(Override)* Gets the dialogue the enemy should say each turn.
--- *By default, picks a random dialogue from [`dialogue`](lua://EnemyBattler.dialogue) unless [`dialogue_override`](lua://EnemyBattler.dialogue_override) is set.
---@return string[]|string?
function EnemyBattler:getEnemyDialogue()
    if self.dialogue_override then
        local dialogue = self.dialogue_override
        self.dialogue_override = nil
        return dialogue
    end
    return Utils.pick(self.dialogue)
end

--- *(Override)* Gets the list of waves this enemy can use each turn.
--- *By default, returns the [`waves`](lua://EnemyBattler.waves) table, unless [`wave_override`](lua://EnemyBattler.wave_override) is set.
---@return string[]
function EnemyBattler:getNextWaves()
    if self.wave_override then
        local wave = self.wave_override
        self.wave_override = nil
        return {wave}
    end
    return self.waves
end

--- *(Override)* Selects the wave that this enemy will use each turn.
--- *By default, picks from the available selection provided by [`EnemyBattler:getNextWaves()`](lua://EnemyBattler.getNextWaves)*
---@return string? wave_id
function EnemyBattler:selectWave()
    local waves = self:getNextWaves()
    if waves and #waves > 0 then
        local wave = Utils.pick(waves)
        self.selected_wave = wave
        return wave
    end
end

--- *(Override)* Called whenever the enemy is checked
---@param battler PartyBattler
function EnemyBattler:onCheck(battler) end

--- *(Override)* Called when an ACT on this enemy starts \
--- *By default, sets the sprties of all battlers involved in the act to `"battle/act"`
---@param battler PartyBattler  The battler using this act - if it is a multi-act, this only specifies the one who used the command
---@param name string           The name of the act used
function EnemyBattler:onActStart(battler, name)
    battler:setAnimation("battle/act")
    local action = Game.battle:getCurrentAction()
    if action.party then
        for _,party_id in ipairs(action.party) do
            Game.battle:getPartyBattler(party_id):setAnimation("battle/act")
        end
    end
end

--- *(Override)* Called when an ACT (including X-Acts, excluding short acts, see [`EnemyBattler:onShortAct()`](lua://EnemyBattler.onShortAct)) is used on this enemy - This function should be overriden to define behaviour for every act \
--- *By default, manages the `"Check"` act - call `super.onAct(self, battler, name)` in any override to ensure Check is still handled* \
--- *Acts will **softlock** Kristal if a string value or table is not returned by this function when they are used*
---@param battler   PartyBattler
---@param name      string
---@return string[]|string text
function EnemyBattler:onAct(battler, name)
    if name == "Check" then
        self:onCheck(battler)
        if type(self.check) == "table" then
            local tbl = {}
            for i,check in ipairs(self.check) do
                if i == 1 then
                    table.insert(tbl, "* " .. string.upper(self.name) .. " - " .. check)
                else
                    table.insert(tbl, "* " .. check)
                end
            end
            return tbl
        else
            return "* " .. string.upper(self.name) .. " - " .. self.check
        end
    end
end

--- *(Override)* Called when a short ACT is used, functions identically to [`EnemyBattler:onAct()`](lua://EnemyBattler.onAct) but for short acts
---@param battler   PartyBattler
---@param name      string
---@return string[]|string text
function EnemyBattler:onShortAct(battler, name) end

--- *(Override)* Called at the start of every new turn in battle
function EnemyBattler:onTurnStart() end
--- *(Override)* Called at the end of every turn in battle
function EnemyBattler:onTurnEnd() end

--- Retrieves the data of an act on this enemy by its `name`
---@param name string
---@return table
function EnemyBattler:getAct(name)
    for _,act in ipairs(self.acts) do
        if act.name == name then
            return act
        end
    end
end

--- Gets the name of the X-Action usable on this enemy for each individual party member
---@param battler PartyBattler  The battler the X-Action name is being retrieved for
---@return string name
function EnemyBattler:getXAction(battler)
    return "Standard"
end

--- Whether the X-Action is a short act (Short acts all activate simultaneously) for each individual party member
---@param battler PartyBattler  The battler the X-Action type is being retrieved for
---@return boolean short
function EnemyBattler:isXActionShort(battler)
    return false
end

--- Deals damage to this enemy
---@param amount        number                                  The amount of damage the enemy should take
---@param battler?      PartyBattler                            The party member dealing this damage
---@param on_defeat?    fun(EnemyBattler, number, PartyBattler) A callback to run if the enmy is defeated by this hit
---@param color?        table                                   The color of the damage, overriding the default damage color of the attacker
---@param show_status?  boolean                                 Whether to show the damage numbers from this hit
---@param attacked?     boolean
function EnemyBattler:hurt(amount, battler, on_defeat, color, show_status, attacked)
    if amount == 0 or (amount < 0 and Game:getConfig("damageUnderflowFix")) then
        if show_status ~= false then
            self:statusMessage("msg", "miss", color or (battler and {battler.chara:getDamageColor()}))
        end

        self:onDodge(battler, attacked)
        return
    end

    self.health = self.health - amount
    if show_status ~= false then
        self:statusMessage("damage", amount, color or (battler and {battler.chara:getDamageColor()}))
    end

    if amount > 0 then
        self.hurt_timer = 1
        self:onHurt(amount, battler)
    end

    self:checkHealth(on_defeat, amount, battler)
end

--- Checks the health of the enemy and defeats it if it is below zero.
---@overload fun(self: EnemyBattler)
---@param on_defeat     fun(EnemyBattler, number, PartyBattler) A callback to run if the enemy is defeated
---@param amount        number                                  The amount of damage taken by the last hit
---@param battler       PartyBattler                            The party member that dealt the last hit
function EnemyBattler:checkHealth(on_defeat, amount, battler)
    -- on_defeat is optional
    if self.health <= 0 then
        self.health = 0

        if not self.defeated then
            if on_defeat then
                on_defeat(self, amount, battler)
            else
                self:forceDefeat(amount, battler)
            end
        end
    end
end

--- Immediately defeats an enemy
---@param amount?   number          The amount of damage taken by the last hit
---@param battler?  PartyBattler    The party member that dealt the last hit
function EnemyBattler:forceDefeat(amount, battler)
    self:onDefeat(amount, battler)
end

--- *(Override)* Gets the tension earned by hitting this enemy \
--- *By default, returns `points / 25`, or if you have reduced tension, `points / 65`*
---@param points number The points of the hit, based on closeness to the target box when attacking, maximum value is `150`
---@return number tension
function EnemyBattler:getAttackTension(points)
    -- Kristal transforms tension from 0-250 (DR) to 0-100.
    -- In Deltarune, this is (10 * 2.5), except for JEVIL where it's (15 * 2.5)
    -- And in reduced battles, it's (26 * 2.5)

    if Game.battle:hasReducedTension() then
        return points / 65
    end
    return points / 25
end

--- *(Override)* Gets the attack damage dealt to this enemy \
--- *By default, returns `damage` if it is a number greater than 0, otherwise using the attacking `battler` and `points` against this enemy's `defense` to calculate damage*
---@param damage    number
---@param battler   PartyBattler
---@param points    number          The points of the hit, based on closeness to the target box when attacking, maximum value is `150`
---@return number
function EnemyBattler:getAttackDamage(damage, battler, points)
    if damage > 0 then
        return damage
    end
    return ((battler.chara:getStat("attack") * points) / 20) - (self.defense * 3)
end

--- Gets the name of the damage sound used when this enemy is hit (defaults to `"damage"`)
---@return string? sound
function EnemyBattler:getDamageSound() end

--- *(Override)* Called when an enemy is hurt \
--- *By default, starts the hit effects including shaking, hurt sprite, and checks whether the enemy can be made TIRED*
---@param damage    number
---@param battler?  PartyBattler    The battler that dealt the damage
function EnemyBattler:onHurt(damage, battler)
    self:toggleOverlay(true)
    if not self:getActiveSprite():setAnimation("hurt") then
        self:toggleOverlay(false)
    end
    self:getActiveSprite():shake(9, 0, 0.5, 2/30)

    if self.health <= (self.max_health * self.tired_percentage) then
        self:setTired(true)
    end
end

--- *(Override)* Called when this enemy finishes hurting \
--- *By default, stops the hurt shake and resets the enemy's sprite.
function EnemyBattler:onHurtEnd()
    self:getActiveSprite():stopShake()
    self:toggleOverlay(false)
end

--- *(Override)* Called when the enemy is attacked by a party member, but their hit misses
---@param battler?  PartyBattler
---@param attacked? boolean
function EnemyBattler:onDodge(battler, attacked) end

--- *(Override)* Called when an enemy is defeated through violence \
--- *By default, makes the enemy run via [`EnemyBattler:onDefeatRun()`](lua://EnemyBattler.onDefeatRun) if [`exit_on_defeat`](lua://EnemyBattler.exit_on_defeat) is `true`
---@param damage?    number
---@param battler?   PartyBattler
function EnemyBattler:onDefeat(damage, battler)
    if self.exit_on_defeat then
        self:onDefeatRun(damage, battler)
    else
        self.sprite:setAnimation("defeat")
    end
end

--- *(Override)* Called to defeat an enemy by making them flee when their hp is reduced to 0
---@param damage?    number
---@param battler?   PartyBattler
function EnemyBattler:onDefeatRun(damage, battler)
    self.hurt_timer = -1
    self.defeated = true

    Assets.playSound("defeatrun")

    local sweat = Sprite("effects/defeat/sweat")
    sweat:setOrigin(0.5, 0.5)
    sweat:play(5/30, true)
    sweat.layer = 100
    self:addChild(sweat)

    Game.battle.timer:after(15/30, function()
        sweat:remove()
        self:getActiveSprite().run_away = true

        Game.battle.timer:after(15/30, function()
            self:remove()
        end)
    end)

    self:defeat("VIOLENCED", true)
end

--- *(Override)* Normally unused, called to fatally defeat the enemy and defeat them with the reason `"KILLED"`
---@param damage?    number
---@param battler?   PartyBattler
function EnemyBattler:onDefeatFatal(damage, battler)
    self.hurt_timer = -1

    Assets.playSound("deathnoise")

    local sprite = self:getActiveSprite()

    sprite.visible = false
    sprite:stopShake()

    local death_x, death_y = sprite:getRelativePos(0, 0, self)
    local death = FatalEffect(sprite:getTexture(), death_x, death_y, function() self:remove() end)
    death:setColor(sprite:getDrawColor())
    death:setScale(sprite:getScale())
    self:addChild(death)

    self:defeat("KILLED", true)
end

--- Heals the enemy by `amount` health
---@param amount            number  The amount of health to restore
---@param sparkle_color?    table   The color of the heal sparkles (defaults to the standard green) or false to not show sparkles
function EnemyBattler:heal(amount, sparkle_color)
    Assets.stopAndPlaySound("power")
    self.health = self.health + amount

    if self.health >= self.max_health then
        self.health = self.max_health
        self:statusMessage("msg", "max", nil, nil, 8)
    else
        self:statusMessage("heal", amount, {0, 1, 0}, nil, 8)
    end

    self:healEffect(unpack(sparkle_color or {}))
end

--- Freezes this enemy and defeats them with the reason `"FROZEN"` \
--- If this enemy can not be frozen, it makes them run away instead
function EnemyBattler:freeze()
    if not self.can_freeze then
        self:onDefeatRun()
    end

    Assets.playSound("petrify")

    self:toggleOverlay(true)

    local sprite = self:getActiveSprite()
    if not sprite:setAnimation("frozen") then
        sprite:setAnimation("hurt")
    end
    sprite:stopShake()

    self:recruitMessage("frozen")

    self.hurt_timer = -1

    sprite.frozen = true
    sprite.freeze_progress = 0

    Game.battle.timer:tween(20/30, sprite, {freeze_progress = 1})

    Game.battle.money = Game.battle.money + 24
    self:defeat("FROZEN", true)
end

--- An override of [`Battler:statusMessage()`](lua://Battler.statusMessage) that positions the message for this EnemyBattler
---@param ... unknown
---@return DamageNumber
function EnemyBattler:statusMessage(...)
    return super.statusMessage(self, self.width/2, self.height/2, ...)
end

--- An override of [`Battler:recruitMessage()`](lua://Battler.recruitMessage)
---@param ... unknown
---@return RecruitMessage
function EnemyBattler:recruitMessage(...)
    return super.recruitMessage(self, self.width/2, self.height/2, ...)
end

---@param v boolean|integer
function EnemyBattler:setRecruitStatus(v)
    Game:getRecruit(self.id):setRecruited(v)
end

---@return boolean|integer
function EnemyBattler:getRecruitStatus()
    return Game:getRecruit(self.id):getRecruited()
end

--- Whether the enemy is recruitable - automatically checks to see whether a recruit exists for this enemy
---@return Recruit?
function EnemyBattler:isRecruitable()
    return Game:getRecruit(self.id)
end

--- Called when an enemy is defeated by any means, controls recruit status, battle rewards, and removing the enemy from battle
---@param reason?    string  The mode the enemy was defeated by - default reasons are `"SPARED"`, `"PACIFIED"` (Non-violent), `"VIOLENCED"`, `"FROZEN"`, `"KILLED"` (Violent), `"DEFEATED"` (Default)
---@param violent?   boolean Whetehr the kill method is classed as violent and would result in the enemy's recruit becoming LOST.
function EnemyBattler:defeat(reason, violent)
    self.done_state = reason or "DEFEATED"

    if violent then
        Game.battle.used_violence = true
        if self:isRecruitable() and self:getRecruitStatus() ~= false then
            if Game:getConfig("enableRecruits") and self.done_state ~= "FROZEN" then
                self:recruitMessage("lost")
            end
            self:setRecruitStatus(false)
        end
    end
    
    if self:isRecruitable() and type(self:getRecruitStatus()) == "number" and (self.done_state == "PACIFIED" or self.done_state == "SPARED") then
        self:setRecruitStatus(self:getRecruitStatus() + 1)
        if Game:getConfig("enableRecruits") then
            local counter = self:recruitMessage("recruit")
            counter.first_number = self:getRecruitStatus()
            counter.second_number = Game:getRecruit(self.id):getRecruitAmount()
            Assets.playSound("sparkle_gem")
        end
        if self:getRecruitStatus() >= Game:getRecruit(self.id):getRecruitAmount() then
            self:setRecruitStatus(true)
        end
    end
    
    Game.battle.money = Game.battle.money + self.money
    Game.battle.xp = Game.battle.xp + self.experience

    Game.battle:removeEnemy(self, true)
end

--- Sets the actor used for this enemy.
---@param actor         string|Actor    The id or instance of the `Actor` to set on this battler.
---@param use_overlay?  boolean         Whether to use the overlay sprite system (Defaults to `true`)
function EnemyBattler:setActor(actor, use_overlay)
    super.setActor(self, actor, use_overlay)

    if self.sprite then
        self.sprite.facing = "left"
        self.sprite.inherit_color = true
    end
    if self.overlay_sprite then
        self.overlay_sprite.facing = "left"
        self.overlay_sprite.inherit_color = true
    end
end

--- Shorthand for [`ActorSprite:setSprite()`](lua://ActorSprite.setSprite) and [`Sprite:play()`](lua://Sprite.play)
---@param sprite?   string
---@param speed?    number
---@param loop?     boolean
---@param after?    fun(ActorSprite)
function EnemyBattler:setSprite(sprite, speed, loop, after)
    if not self.sprite then
        self.sprite = Sprite(sprite)
        self:addChild(self.sprite)
    else
        self.sprite:setSprite(sprite)
    end
    if not self.sprite.directional and speed then
        self.sprite:play(speed, loop, after)
    end
end

function EnemyBattler:update()
    if self.hurt_timer > 0 then
        self.hurt_timer = Utils.approach(self.hurt_timer, 0, DT)

        if self.hurt_timer == 0 then
            self:onHurtEnd()
        end
    end

    if self.temporary_mercy_percent and self.temporary_mercy_percent.kill_condition_succeed then
        self.mercy = Utils.clamp(self.mercy + self.temporary_mercy, 0, 100)
        self.temporary_mercy = 0
        self.temporary_mercy_percent = nil
    end

    super.update(self)
end

function EnemyBattler:canDeepCopy()
    return false
end

--- Sets the value of the flag named `flag` to `value` \
--- This variant of `Game:setFlag()` interacts with flags specific to this enemy id
---@param flag  string
---@param value any
function EnemyBattler:setFlag(flag, value)
    Game:setFlag("enemy#"..self.id..":"..flag, value)
end

--- Gets the value of the flag named `flag`, returning `default` if the flag does not exist \
--- This variant of `Game:getFlag()` interacts with flags specific to this enemy id
---@param flag      string
---@param default?  any
---@return any
function EnemyBattler:getFlag(flag, default)
    return Game:getFlag("enemy#"..self.id..":"..flag, default)
end

--- Adds `amount` to a numeric flag named `flag` (or defines it if it does not exist) \
--- This variant of `Game:addFlag()` interacts with flags specific to this enemy id
---@param flag      string  The name of the flag to add to
---@param amount?   number  (Defaults to `1`)
---@return number new_value
function EnemyBattler:addFlag(flag, amount)
    return Game:addFlag("enemy#"..self.id..":"..flag, amount)
end

return EnemyBattler
