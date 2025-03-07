-- Protection Warrior Defensive Cooldown Management
---@type buff_manager
local buff_manager = require("common/modules/buff_manager")
---@type enums
local enums = require("common/enums")

-- Initialize namespace if not already done
TankEngine.warrior_protection = TankEngine.warrior_protection or {}

-- Add spell IDs for defensive abilities
TankEngine.warrior_protection.spells = TankEngine.warrior_protection.spells or {}
TankEngine.warrior_protection.spells.shield_wall = 871
TankEngine.warrior_protection.spells.last_stand = 12975
TankEngine.warrior_protection.spells.demoralizing_shout = 1160
TankEngine.warrior_protection.spells.spell_reflection = 23920
TankEngine.warrior_protection.spells.shield_block = 2565
TankEngine.warrior_protection.spells.ignore_pain = 190456
TankEngine.warrior_protection.spells.taunt = 355
TankEngine.warrior_protection.spells.avatar = 107574
TankEngine.warrior_protection.spells.thunder_clap = 6343
TankEngine.warrior_protection.spells.devastate = 20243

-- Defensive cooldown configuration
TankEngine.warrior_protection.defensives = {
    -- Major defensive cooldowns
    major = {
        {
            spell_id = TankEngine.warrior_protection.spells.shield_wall,
            name = "Shield Wall",
            threshold = 30, -- Use at 30% health by default
            duration = 15,
            cooldown = 240,
            priority = 100,
            condition = function(health_percent, incoming_damage_percent)
                -- Use Shield Wall in emergency situations
                return health_percent <= 30 or incoming_damage_percent >= 40
            end
        },
        {
            spell_id = TankEngine.warrior_protection.spells.last_stand,
            name = "Last Stand",
            threshold = 40, -- Use at 40% health by default
            duration = 15,
            cooldown = 180,
            priority = 90,
            condition = function(health_percent, incoming_damage_percent)
                -- Use Last Stand when health is low or taking heavy damage
                return health_percent <= 40 or incoming_damage_percent >= 30
            end
        },
    },
    
    -- Medium defensive cooldowns
    medium = {
        {
            spell_id = TankEngine.warrior_protection.spells.demoralizing_shout,
            name = "Demoralizing Shout",
            threshold = 60, -- Use at 60% health by default
            duration = 8,
            cooldown = 45,
            priority = 80,
            condition = function(health_percent, incoming_damage_percent)
                -- Use Demoralizing Shout proactively
                return health_percent <= 60 or incoming_damage_percent >= 20
            end
        },
        {
            spell_id = TankEngine.warrior_protection.spells.spell_reflection,
            name = "Spell Reflection",
            threshold = 70, -- Use at 70% health by default
            duration = 5,
            cooldown = 25,
            priority = 70,
            condition = function(health_percent, incoming_damage_percent, damage_type)
                -- Use Spell Reflection against magical damage
                return damage_type == "magical" and (health_percent <= 70 or incoming_damage_percent >= 15)
            end
        },
    },
    
    -- Minor defensive abilities (active mitigation)
    minor = {
        {
            spell_id = TankEngine.warrior_protection.spells.shield_block,
            name = "Shield Block",
            threshold = 80, -- Use at 80% health by default
            duration = 6,
            cooldown = 16, -- Effectively 8s with 2 charges
            priority = 60,
            condition = function(health_percent, incoming_damage_percent, damage_type)
                -- Use Shield Block against physical damage
                return damage_type == "physical" and (health_percent <= 80 or incoming_damage_percent >= 10)
            end
        },
        {
            spell_id = TankEngine.warrior_protection.spells.ignore_pain,
            name = "Ignore Pain",
            threshold = 85, -- Use at 85% health by default
            duration = 15, -- Variable based on damage taken
            cooldown = 0, -- Resource-based, not cooldown-based
            priority = 50,
            condition = function(health_percent, incoming_damage_percent)
                -- Use Ignore Pain against any damage type
                return health_percent <= 85 or incoming_damage_percent >= 8
            end
        },
    }
}

-- Main function to check and use defensive cooldowns
function TankEngine.warrior_protection.check_defensive_cooldowns()
    local me = TankEngine.variables.me
    if not me or me:is_dead() then return false end
    
    local max_health = me:get_max_health()
    local current_health = me:get_health()
    local health_percent = (current_health / max_health) * 100
    
    -- Get predicted incoming damage (from WigsTracker or combat analysis)
    local incoming_damage = TankEngine.variables.predicted_incoming_damage or 0
    local incoming_damage_percent = (incoming_damage / max_health) * 100
    
    -- Determine damage type (from combat analysis)
    local damage_type = TankEngine.variables.incoming_damage_type or "physical"
    
    -- Check if we're in a dangerous situation that requires immediate defensive response
    local is_dangerous = TankEngine.warrior_protection.is_dangerous_situation()
    
    -- Check major defensives first (in emergency situations)
    if is_dangerous or health_percent <= 50 or incoming_damage_percent >= 30 then
        for _, defensive in ipairs(TankEngine.warrior_protection.defensives.major) do
            if TankEngine.api.can_cast_spell(defensive.spell_id) and 
               defensive.condition(health_percent, incoming_damage_percent, damage_type) then
                TankEngine.api.cast_spell(defensive.spell_id)
                return true
            end
        end
    end
    
    -- Check medium defensives
    if health_percent <= 70 or incoming_damage_percent >= 20 then
        for _, defensive in ipairs(TankEngine.warrior_protection.defensives.medium) do
            if TankEngine.api.can_cast_spell(defensive.spell_id) and 
               defensive.condition(health_percent, incoming_damage_percent, damage_type) then
                TankEngine.api.cast_spell(defensive.spell_id)
                return true
            end
        end
    end
    
    -- Always check minor defensives (active mitigation)
    for _, defensive in ipairs(TankEngine.warrior_protection.defensives.minor) do
        if TankEngine.api.can_cast_spell(defensive.spell_id) and 
           defensive.condition(health_percent, incoming_damage_percent, damage_type) then
            TankEngine.api.cast_spell(defensive.spell_id)
            return true
        end
    end
    
    return false
end

-- Function to determine if we're in a dangerous situation
function TankEngine.warrior_protection.is_dangerous_situation()
    local me = TankEngine.variables.me
    if not me then return false end
    
    local max_health = me:get_max_health()
    local current_health = me:get_health()
    local health_percent = (current_health / max_health) * 100
    
    -- Check if we're in a boss fight
    local target = TankEngine.variables.get_safe_target()
    local is_boss_fight = target and target:is_boss()
    
    -- Check if we're fighting multiple enemies
    local enemy_count = TankEngine.variables.enemies_in_melee_range()
    
    -- Check if we have dangerous debuffs
    local has_dangerous_debuff = TankEngine.warrior_protection.has_dangerous_debuff()
    
    -- Check if a dangerous boss ability is incoming (from WigsTracker)
    local dangerous_ability_incoming = false
    if TankEngine.modules and TankEngine.modules.wigs_tracker then
        local should_use_defensive, bar = TankEngine.modules.wigs_tracker.should_use_defensive()
        dangerous_ability_incoming = should_use_defensive
    end
    
    -- Determine if the situation is dangerous
    return (health_percent <= 40) or 
           (is_boss_fight and health_percent <= 60) or 
           (enemy_count >= 4 and health_percent <= 70) or
           has_dangerous_debuff or
           dangerous_ability_incoming
end

-- Function to check for dangerous debuffs
function TankEngine.warrior_protection.has_dangerous_debuff()
    local me = TankEngine.variables.me
    if not me then return false end
    
    -- Ensure debuff_up function exists
    if not TankEngine.variables.debuff_up then
        TankEngine.variables.debuff_up = function(debuff_id, unit)
            unit = unit or TankEngine.variables.me
            if not unit or not unit:is_valid() then return false end
            
            -- Use buff_manager if available, otherwise use basic API
            if TankEngine.api.buff_manager then
                -- Create a table with a single ID for buff_manager
                local result = TankEngine.api.buff_manager:get_debuff_data(unit, { debuff_id })
                return result and result.is_active or false
            else
                return unit:has_debuff(debuff_id)
            end
        end
    end
    
    -- List of dangerous debuff IDs (would need to be expanded in a real implementation)
    local dangerous_debuffs = {
        209858, -- Necrotic Strike
        240559, -- Grievous Wound
        226512, -- Sanguine Ichor
        -- Add more as needed
    }
    
    -- Check if we have any of these debuffs
    for _, debuff_id in ipairs(dangerous_debuffs) do
        if TankEngine.variables.debuff_up(debuff_id) then
            return true
        end
    end
    
    return false
end

-- Integration with WigsTracker for proactive defensive usage
function TankEngine.warrior_protection.integrate_with_wigs_tracker()
    if not TankEngine.modules or not TankEngine.modules.wigs_tracker then
        return
    end
    
    -- Register callback for when dangerous abilities are detected
    TankEngine.modules.wigs_tracker.register_defensive_callback(function(ability_name, time_remaining, importance)
        -- Determine which defensive to use based on the ability
        local defensive_to_use = TankEngine.warrior_protection.get_defensive_for_ability(ability_name, importance)
        
        if defensive_to_use and TankEngine.api.can_cast_spell(defensive_to_use) then
            -- Use the defensive slightly before the ability hits
            if time_remaining <= 1.5 then
                TankEngine.api.cast_spell(defensive_to_use)
                return true
            end
        end
        
        return false
    end)
end

-- Function to determine which defensive to use for a specific boss ability
function TankEngine.warrior_protection.get_defensive_for_ability(ability_name, importance)
    -- Map of boss abilities to appropriate defensives
    local ability_defensive_map = {
        -- High importance abilities (tank busters)
        ["null upheaval"] = TankEngine.warrior_protection.spells.shield_wall,
        ["reaping scythe"] = TankEngine.warrior_protection.spells.shield_wall,
        ["hateful strike"] = TankEngine.warrior_protection.spells.shield_wall,
        
        -- Medium importance abilities
        ["sludge claws"] = TankEngine.warrior_protection.spells.last_stand,
        ["thunder punch"] = TankEngine.warrior_protection.spells.last_stand,
        
        -- Magical abilities
        ["drain light"] = TankEngine.warrior_protection.spells.spell_reflection,
        ["necrotic bolt"] = TankEngine.warrior_protection.spells.spell_reflection,
        
        -- Default to Shield Block for physical damage
        ["default_physical"] = TankEngine.warrior_protection.spells.shield_block,
        
        -- Default to Ignore Pain for any damage
        ["default"] = TankEngine.warrior_protection.spells.ignore_pain
    }
    
    -- Convert ability name to lowercase for case-insensitive matching
    ability_name = string.lower(ability_name)
    
    -- Check if we have a specific defensive for this ability
    if ability_defensive_map[ability_name] then
        return ability_defensive_map[ability_name]
    end
    
    -- If not, use a default based on importance
    if importance >= 9 then
        return TankEngine.warrior_protection.spells.shield_wall
    elseif importance >= 7 then
        return TankEngine.warrior_protection.spells.last_stand
    elseif importance >= 5 then
        return TankEngine.warrior_protection.spells.demoralizing_shout
    else
        return TankEngine.warrior_protection.spells.ignore_pain
    end
end 