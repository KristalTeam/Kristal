SCREEN_WIDTH = 640
SCREEN_HEIGHT = 480

BORDER_WIDTH = 1920
BORDER_HEIGHT = 1080
BORDER_SCALE = 0.5

BORDER_ALPHA = 0
BORDER_FADING = "OUT"
BORDER_FADE_TIME = 0.5
BORDER_FADE_FROM = nil
BORDER_TRANSITIONING = false
LAST_BORDER = nil

USING_CONSOLE = false

KEY_REPEAT_DELAY = 0.4
KEY_REPEAT_INTERVAL = 0.075

TILE_WIDTH = 40
TILE_HEIGHT = 40

FOLLOW_DELAY = 0.4

BATTLE_LAYERS = {
    ["bottom"]         = -1000,
    ["below_battlers"] = -200,
    ["battlers"]       = -100,
    ["above_battlers"] = 0, --┰-- 0
    ["below_ui"]       = 0, --┙
    ["ui"]             = 100,
    ["damage_numbers"] = 150,
    ["above_ui"]       = 200, --┰-- 200
    ["below_arena"]    = 200, --┙
    ["arena"]          = 300,
    ["above_arena"]    = 400, --┰-- 400
    ["below_soul"]     = 400, --┙
    ["soul"]           = 500,
    ["above_soul"]     = 600, --┰-- 600
    ["below_bullets"]  = 600, --┙
    ["bullets"]        = 700,
    ["above_bullets"]  = 800,
    ["top"]            = 1000
}

WORLD_LAYERS = {
    ["bottom"] = -100,
    ["above_events"] = 100,  --┰-- 100
    ["below_soul"] = 100,    --┙
    ["soul"] = 200,
    ["above_soul"] = 300,    --┰-- 300
    ["below_bullets"] = 300, --┙
    ["bullets"] = 400,
    ["above_bullets"] = 500, --┰-- 500
    ["below_ui"] = 500,      --┙
    ["ui"] = 600,
    ["above_ui"] = 700,      --┰-- 700
    ["below_textbox"] = 700, --┙
    ["textbox"] = 800,
    ["above_textbox"] = 900,
    ["top"] = 1000
}

SHOP_LAYERS = {
    ["background"] = -100,
    ["below_shopkeeper"] = 100,
    ["shopkeeper"] = 200,
    ["above_shopkeeper"] = 300, --┰-- 300
    ["below_boxes"] = 300,      --┙
    ["cover"] = 400,
    ["large_box"] = 450,
    ["left_box"] = 500,
    ["info_box"] = 550,
    ["right_box"] = 600,
    ["above_boxes"] = 700,    --┰-- 700
    ["below_dialogue"] = 700, --┙
    ["dialogue"] = 800,
    ["above_dialogue"] = 900,
    ["top"] = 1000
}

MUSIC_VOLUME = 0.7
MUSIC_VOLUMES = {
    ["battle"] = 0.7
}
MUSIC_PITCHES = {}

-- Colors used by the engine for various things, here for customizability
local palette_data = {
    ["battle_mercy_bg"] = { 255 / 255, 80 / 255, 32 / 255, 1 },
    ["battle_mercy_text"] = { 128 / 255, 0, 0, 1 },
    ["battle_attack_lines"] = { 0, 0, 0.5, 1 },

    ["world_fill"] = { 0, 0, 0, 1 },
    ["world_border"] = { 1, 1, 1, 1 },
    ["world_text"] = { 1, 1, 1, 1 },
    ["world_text_selected"] = { 1, 1, 0, 1 },
    ["world_text_hover"] = { 0, 1, 1, 1 },
    ["world_text_rebind"] = { 1, 0, 0, 1 },
    ["world_text_shadow"] = { 51 / 255, 32 / 255, 51 / 255, 1 },
    ["world_text_unusable"] = { 192 / 255, 192 / 255, 192 / 255, 1 },
    ["world_gray"] = { 128 / 255, 128 / 255, 128 / 255, 1 },
    ["world_dark_gray"] = { 0.25, 0.25, 0.25, 1 },
    ["world_light_gray"] = { 0.75, 0.75, 0.75, 1 },
    ["world_header"] = { 1, 1, 1, 1 },
    ["world_header_selected"] = { 255 / 255, 160 / 255, 64 / 255, 1 },
    ["world_save_other"] = { 68 / 255, 68 / 255, 68 / 255, 1 },
    ["world_ability_icon"] = { 255 / 255, 160 / 255, 64 / 255, 1 },

    ["action_strip"] = { 51 / 255, 32 / 255, 51 / 255, 1 },
    ["action_fill"] = { 0, 0, 0, 1 },
    ["action_health_bg"] = { 128 / 255, 0, 0, 1 },
    ["action_health_text_down"] = { 1, 0, 0, 1 },
    ["action_health_text_low"] = { 1, 1, 0, 1 },
    ["action_health_text"] = { 1, 1, 1, 1 },
    ["action_health"] = { 0, 1, 0, 1 },

    ["tension_back"] = { 128 / 255, 0, 0, 1 },
    ["tension_decrease"] = { 1, 0, 0, 1 },
    ["tension_fill"] = { 255 / 255, 160 / 255, 64 / 255, 1 },
    ["tension_max"] = { 255 / 255, 208 / 255, 32 / 255, 1 },
    ["tension_maxtext"] = { 1, 1, 0, 1 },
    ["tension_desc"] = { 255 / 255, 160 / 255, 64 / 255, 1 },
}
PALETTE = {}
setmetatable(PALETTE, {
    __index = function (t, i) return Kristal.callEvent(KRISTAL_EVENT.getPaletteColor, i) or palette_data[i] end,
    __newindex = function (t, k, v) palette_data[k] = v end,
})

COLORS = {
    aqua = { 0, 1, 1, 1 },
    black = { 0, 0, 0, 1 },
    blue = { 0, 0, 1, 1 },
    dkgray = { 0.25, 0.25, 0.25, 1 },
    fuchsia = { 1, 0, 1, 1 },
    gray = { 0.5, 0.5, 0.5, 1 },
    green = { 0, 0.5, 0, 1 },
    lime = { 0, 1, 0, 1 },
    ltgray = { 0.75, 0.75, 0.75, 1 },
    maroon = { 0.5, 0, 0, 1 },
    navy = { 0, 0, 0.5, 1 },
    olive = { 0.5, 0.5, 0, 1 },
    orange = { 1, 0.625, 0.25, 1 },
    purple = { 0.5, 0, 0.5, 1 },
    red = { 1, 0, 0, 1 },
    silver = { 0.75, 0.75, 0.75, 1 },
    teal = { 0, 0.5, 0.5, 1 },
    white = { 1, 1, 1, 1 },
    yellow = { 1, 1, 0, 1 }
}
for _, v in pairs(COLORS) do
    setmetatable(v, { __call = function (c, a) return { c[1], c[2], c[3], a or 1 } end })
end

ALPHABET = { "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u",
    "v", "w", "x", "y", "z" }
FACINGS = { "right", "down", "left", "up" }

-- Different chase types that can be used by ChaserEnemys.
CHASETYPE = { "linear", "multiplier", "flee" }

--- Different pace types that can be used by ChaserEnemys. \
--- `wander`          - Wanders between the enemy spawn point and several markers in a fixed order. \
--- `randomwander`    - Wanders between the enemy spawn point and several markers at random. \
--- `verticalswing`   - Moves along a sinusodial wave on the y-axis. \
--- `horizontalswing` - Moves along a sinusodial wave on the x-axis.
PACETYPE = { "wander", "randomwander", "verticalswing", "horizontalswing"}

-- exposed events called by Kristal
--
--  keywords  --
-- "intercept": events' return value are used as the primary argument to an `or` expression, or equivalent effect: `Kristal.callEvent(KRISTAL_EVENT.event or value)`
-- "optional": events' return value are used as the secondary argument to an `or` expression, or equivalent effect: `value or Kristal.callEvent(KRISTAL_EVENT.event)`
-- "overrides": if events' return value is "truthy", the calling function returns early, or equivalent effect
--
-- when adding a new event, put it in alphabetical order, unless other specified, under the appropriate event group (create one if it doesnt exist), and follow this format:
-- <newEvent> = "<newEvent>", -- <short description> / at: <callingFunction()>, <...> / passes: <Type>:<arg>, <...> / returns: NONE|<Type>:<arg>, <...>
KRISTAL_EVENT = {

    --inventory events--
    createDarkInventory = "createDarkInventory", -- dark world inventory is created / at: DarkInventory:clear() / passes: DarkInventory:self / returns: NONE
    createLightInventory = "createLightInventory", -- light world inventory is created / at: LightInventory:clear() / passes: LightInventory:self / returns: NONE
    onConvertToDark = "onConvertToDark", -- dark world inventory converted to light world inventory / at: DarkInventory:convertToLight() / passes: LightInventory:new_inventory / returns: NONE
    onConvertToLight = "onConvertToLight", -- light world inventory converted to dark world inventory / at: LightInventory:convertToDark() / passes: DarkInventory:new_inventory / returns: NONE

    --item events--
    onJunkCheck = "onJunkCheck", -- intercept ball of junk additional check text / at: item:onCheck() (light/ball_of_junk.lua) / passes: Item:item, nil|string:comment / returns: nil|string
    onShadowCrystal = "onShadowCrystal", -- overrides text when shadow crystal or glass is used / at: item:onWorldUse() (light/glass.lua and key/shadowcrystal.lua) / passes: Item:item, bool:light / returns: nil|bool

    --menu events--
    createMenu = "createMenu", -- returns optional custom overworld menu / at: World:createMenu() / passes: NONE / returns: nil|Object
    getDarkMenuButtons = "getDarkMenuButtons", -- optional creation of buttons for custom dark world menu / at: DarkMenu:init() / passes: table:buttons, DarkMenu:self / returns: nil|table
    getUISkin = "getUISkin", --optional default UI skin key / at: UIBox:init(x, y, width, height, skin) / passes: NONE / returns: nil|string
    onDarkMenuOpen = "onDarkMenuOpen",  -- dark world menu is opened / at: DarkMenu:onAdd(parent) / passes: DarkMenu:self / returns: NONE

    --discordrpc events--
    getPresenceDetails = "getPresenceDetails", -- optional discordRPC detail message at mod start / at: Game:enter(previous_state, save_id, save_name, fade) / passes: NONE / returns: nil|string
    getPresenceImage = "getPresenceImage", -- optional discordRPC largeImageKey / at: Game:enter(previous_state, save_id, save_name, fade) / passes: NONE / returns: nil|string
    getPresenceState = "getPresenceState", -- optional discordRPC state message / at: Game:enter(previous_state, save_id, save_name, fade) /  passes: NONE / returns: nil|string

    --game state events-- (sorted by execution order, save&unload last)
    init = "init", -- mod begins initialization, after assets loaded / at: Game:enter(previous_state, save_id, save_name, fade) / passes: NONE / returns: NONE
    load = "load", -- mod loads save data / at: Game:load(data, index, fade) / passes: table:save_data, bool:is_new_file, int:save_index / returns: NONE
    postLoad = "postLoad", -- after mod loads save data and current map or encounter / at: Game:load(data, index, fade) / passes: NONE / returns: NONE
    postInit = "postInit", -- mod & libraries have finished initialization and registration / at: Game:enter(previous_state, save_id, save_name, fade) / passes: bool:is_new_file / returns: NONE
    preUpdate = "preUpdate", -- overrides game update / at: Game:update() / passes: number:DT / returns: bool
	postUpdate = "postUpdate", -- update finished processing / at: Game:update() / passes: number:DT / returns: NONE
	preDraw = "preDraw", -- overrides game draw, always pops final graphics state after / at: Game:draw() / passes: NONE / returns: bool
	postDraw = "postDraw", -- finished drawing / at: Game:draw() / passes: NONE / returns: NONE
    save = "save", -- game is about to be saved / at: Game:save(x, y) / passes: table:save_data / returns: NONE
    unload = "unload", -- current game execution is stopped and data unloaded / at: Kristal.clearModState() / passes: NONE / returns: NONE

    --gameplay events--
    onBorderDraw = "onBorderDraw", -- game border draw time / at: [HOOK]love.draw(...)J\love.load(args) / passes: string:border, love.Image:border_texture / returns: NONE
    onFootstep = "onFootstep", -- character walk cycle advances / at: Character:onFootstep(num) / passes: Character:self, int:num / returns: NONE
    
    --game variable events--
    getConfig = "getConfig", -- intercept mod's config value / at: Game:getConfig(key, merge, deep_merge) / passes: string:key / returns: nil|any
    getPaletteColor = "getPaletteColor", -- intercept rgba color pallete value / at: (metatable@PALETTE).__index(t,i) / passes: string:i / returns: nil|table
    getSoulColor = "getSoulColor", -- intercept rgba soul color value / at: Game:getSoulColor() / passes: NONE / returns nil|table

    --battle events--
    onActionSelect = "onActionSelect", -- overrides action button selection / at: ActionButton:select() / passes: Battler:battler, ActionButton:self / returns: bool
    onBattleActionBegin = "onBattleActionBegin", -- overrides begin action / at: Battle:beginAction(action) / passes: table:action, string:action_type,  PartyBattler:battler, Battler:enemy / returns: bool
    onBattleActionCommit = "onBattleActionCommit", -- overrides commit action / at: Battle:commitSingleAction(action) / passes: table:action, string:action_type,  PartyBattler:battler, Battler:enemy / returns: bool
    onBattleActionEnd = "onBattleActionEnd", -- battlers finishes any action / at: Battle:commitSingleAction(action) / passes: table:action, string:action_type,  PartyBattler:battler, Battler:enemy / returns: NONE
    onBattleActionEndAnimation = "onBattleActionEndAnimation", -- overrides end of action's animation; action's callback is provided / at: Battle:endActionAnimation(battler, action, callback) / passes: table:action, string:action_type, PartyBattler:battler, Battler:target, function:callback, function:raw_callback / returns: bool
    onBattleActionUndo = "onBattleActionUndo", -- overrides action cancellation battler behavior. still clears the battler's action/ at: Battle:removeSingleAction(action) / passes: table:action, string:action_type, PartyBattler:battler, Battler:target / returns: bool
    onBattleEnemyCancel = "onBattleEnemyCancel", -- overrides default enemy selection cancel / at: Battle:onKeyPressed(key) / passes: string:state_reason, int:current_menu_y / returns: bool
    onBattleEnemySelect = "onBattleEnemySelect", -- overrides default enemy select / at: Battle:onKeyPressed(key) / passes: string:state_reason, int:current_menu_y / returns: bool
    onBattleMenuCancel = "onBattleMenuCancel", -- overrides default menu selection cancel / at: Battle:onKeyPressed(key) / passes: string:state_reason, table:menu_item, bool:can_select / returns: bool
    onBattleMenuSelect = "onBattleMenuSelect", -- overrides default menu select / at: Battle:onKeyPressed(key) / passes: string:state_reason, table:menu_item, bool:can_select / returns: bool
    onBattlePartyCancel = "onBattlePartyCancel", -- overrides default party member selection cancellation / at: Battle:onKeyPressed(key) / passes: string:state_reason, int:current_menu_y / returns: bool
    onBattlePartySelect = "onBattlePartySelect", -- overrides default party member select / at: Battle:onKeyPressed(key) / passes: string:state_reason, int:current_menu_y / returns: bool

    --text events--
    isTextStyleAnimated = "isTextStyleAnimated", -- determines if `style` is animated text/ at: Text:isStyleAnimated(style) / passes: string:style, Text:self / returns: bool
    onDrawText = "onDrawText", -- overrides character is drawn / at: Text:drawChar(node, state, use_color) / passes: Text:self, table:node, table:state, number:x, number:y, number:scale, love.Font:font, bool:use_base_color / returns: bool
    onTextSound = "onTextSound", -- overrides text scrawl noise / at: DialogueText:playTextSound(current_node) / passes: string:typing_sound, table:current_node / returns: bool
    registerTextCommands = "registerTextCommands", -- new text is ready to recieve custom command table / passes: Text:self / returns: NONE

    --input events--
    onKeyPressed = "onKeyPressed", -- overrides key is pressed / at: Game:onKeyPressed(key, is_repeat) / passes: string:key, bool:is_repeat / returns: bool
    onKeyReleased = "onKeyReleased", -- key is released / at: Game:onKeyReleased(key) / passes: string:key / returns: NONE
    onMouseMoved = "onMouseMoved", -- mouse is moved / at: love.mousemoved(x, y, dx, dy, istouch) / passes: number:x, number:y, number:dx, number:dy, bool:istouch returns: NONE
    onMousePressed = "onMousePressed", -- mouse button pressed / at: love.mousepressed(win_x, win_y, button, istouch, presses) / passes: number:x, number:y, int:button, bool:istouch, int:presses / returns:NONE
    onMouseReleased = "onMouseReleased", -- mouse button release / at: love.mousereleased(x, y, button, istouch, presses) / passes: number:x, number:y, int:button, bool:istouch, int:presses / returns:NONE
    onTextInput = "onTextInput", -- character is read for text / love.textinput(key) / passes: string:key / returns: NONE
    onWheelMoved = "onWheelMoved", -- mouse wheel is moved / at: Game:onWheelMoved(x, y) / passes: int:x, int:y / returns: NONE

    --map events--
    loadLayer = "loadLayer", -- overrides the map loading the tile layer data on layer depth, when true / at: Map:loadMapData(data) / passes: Map:self, table:layer, number:depth / returns: bool
    onMapBorder = "onMapBorder", -- intercept game border for this map / at: World:setupMap(map, ...), World:mapTransition(...) / passes: Map:map, string:map_music/ returns: string
    onMapMusic = "onMapMusic", -- intercept game border for this map / at: World:setupMap(map, ...), World:mapTransition(...) / passes: Map:map, string:map_music / returns: string

    --debug events--
    registerDebugContext = "registerDebugContext", -- new debug ContextMenu created / at: DebugSystem:onMousePressed(x, y, button, istouch, presses), DebugSystem:openObjectContext(object) / passes: ContextMenu:context, Object:selected_object / return: NONE
	registerDebugOptions = "registerDebugOptions", -- DebugSystem is ready to recieve custom debug options / passes: DebugSystem:self / returns: NONE

    --asset registration events-- (sorted by execution order)
    onRegisterActors = "onRegisterActors", -- actor scripts finished registering / in: Registry.initActors() / passes: NONE / returns: NONE
    onRegisterGlobals = "onRegisterGlobals", -- global scripts finished registering / in: Registry.initGlobals() / passes: NONE / returns: NONE
    onRegisterObjects = "onRegisterObjects", -- object scripts finished registering / in: Registry.initObjects() / passes: NONE / returns: NONE
    onRegisterDrawFX = "onRegisterDrawFX", -- DrawFX scripts finished registering / in: Registry.initDrawFX() / passes: NONE / returns: NONE
    onRegisterItems = "onRegisterItems", -- item scripts finished registering / in: Registry.initItems() / passes: NONE / returns: NONE
    onRegisterSpells = "onRegisterSpells", -- spell scripts finished registering / in: Registry.initSpells() / passes: NONE / returns: NONE
    onRegisterPartyMembers = "onRegisterPartyMembers", -- party member scripts finished registering / in: Registry.initPartyMembers() / passes: NONE / returns: NONE
    onRegisterRecruits = "onRegisterRecruits", -- recruit scripts finished registering / in: Registry.initRecruits() / passes: NONE / returns: NONE
    onRegisterEncounters = "onRegisterEncounters", -- encounter scripts finished registering / in: Registry.initEncounters() / passes: NONE / returns: NONE
    onRegisterEnemies = "onRegisterEnemies", -- enemy scripts finished registering / in: Registry.initEnemies() / passes: NONE / returns: NONE
    onRegisterWaves = "onRegisterWaves", -- wave scripts finished registering / in: Registry.initWaves() / passes: NONE / returns: NONE
    onRegisterBullets = "onRegisterBullets", -- bullet scripts finished registering / in: Registry.initBullets() / passes: NONE / returns: NONE
    onRegisterCutscenes = "onRegisterCutscenes", -- cutscene scripts finished registering / in: Registry.initCutscenes() / passes: NONE / returns: NONE
    onRegisterEvents = "onRegisterEvents", -- event scripts finished registering / in: Registry.initEventScripts() / passes: NONE / returns: NONE
    onRegisterTilesets = "onRegisterTilesets", -- tileset scripts finished registering / in: Registry.initTilesets() / passes: NONE / returns: NONE
    onRegisterMaps = "onRegisterMaps", -- map scripts finished registering / in: Registry.initMaps() / passes: NONE / returns: NONE
    onRegisterEventScripts = "onRegisterEventScripts", -- event scripts finished registering / in: Registry.initEvents() / passes: NONE / returns: NONE
    onRegisterControllers = "onRegisterControllers", -- controller scripts finished registering / in: Registry.initControllers() / passes: NONE / returns: NONE
    onRegisterShops = "onRegisterShops", -- shop scripts finished registering / in: Registry.initShops() / passes: NONE / returns: NONE
    onRegistered = "onRegistered", -- all scripts finished registering / in: Registry.initialize(preload) / passes: NONE / returns: NONE
}