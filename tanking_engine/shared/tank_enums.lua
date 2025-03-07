-- Tank-specific enumerations for the Tanking Engine

---@class tank_mitigation_type
---@field public PHYSICAL number
---@field public MAGICAL number
---@field public BLEED number
---@field public DOT number
---@field public BURST number
---@field public SUSTAINED number

---@class tank_threat_level
---@field public LOW number
---@field public MEDIUM number
---@field public HIGH number
---@field public CRITICAL number

---@class tank_positioning_strategy
---@field public STATIONARY number
---@field public KITING number
---@field public GATHERING number
---@field public BOSS_POSITIONING number

---@class tank_cooldown_priority
---@field public LOW number
---@field public MEDIUM number
---@field public HIGH number
---@field public EMERGENCY number

---@class tank_enums
---@field public mitigation_type tank_mitigation_type
---@field public threat_level tank_threat_level
---@field public positioning_strategy tank_positioning_strategy
---@field public cooldown_priority tank_cooldown_priority

-- Create tank-specific enums
local tank_enums = {
    mitigation_type = {
        PHYSICAL = 1,
        MAGICAL = 2,
        BLEED = 3,
        DOT = 4,
        BURST = 5,
        SUSTAINED = 6
    },
    
    threat_level = {
        LOW = 1,
        MEDIUM = 2,
        HIGH = 3,
        CRITICAL = 4
    },
    
    positioning_strategy = {
        STATIONARY = 1,
        KITING = 2,
        GATHERING = 3,
        BOSS_POSITIONING = 4
    },
    
    cooldown_priority = {
        LOW = 1,
        MEDIUM = 2,
        HIGH = 3,
        EMERGENCY = 4
    }
}

return tank_enums 