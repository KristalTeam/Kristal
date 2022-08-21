-- replaces mod list with "Start game", should be a string of the mod id
TARGET_MOD = nil


-- Dont replace state variables if we are hotswapping
if HOTSWAPPING then return end

HOTSWAPPING = false

FRAMERATE = 60

BASE_DT = (1/60)
DT = (1/60)
DTMULT = DT * 30

FPS = 0
FPS_COUNTER = 0
FPS_TIMER = 0

RUNTIME = 0

MOD_LOADING = false
ACTIVE_LIB = nil

DEBUG_RENDER = false

FAST_FORWARD = false
FAST_FORWARD_SPEED = 5
CURRENT_SPEED_MULT = 1

CURRENT_SCALE_X = 1
CURRENT_SCALE_Y = 1

MOUSE_VISIBLE = false
MOUSE_SPRITE = nil

OVERLAY_OPEN = false
NOCLIP = false

REGISTRY_LOADED = false
