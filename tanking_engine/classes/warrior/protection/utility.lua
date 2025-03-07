-- Protection Warrior Utility Functions

-- Initialize namespace if not already done
TankEngine.warrior_protection = TankEngine.warrior_protection or {}

-- Import required modules
---@type vec3
local vec3 = require("common/geometry/vector_3")

-- Add additional spell IDs for utility abilities
TankEngine.warrior_protection.spells = TankEngine.warrior_protection.spells or {}
TankEngine.warrior_protection.spells.taunt = 355
TankEngine.warrior_protection.spells.heroic_leap = 6544
TankEngine.warrior_protection.spells.heroic_throw = 57755
TankEngine.warrior_protection.spells.intervene = 3411
TankEngine.warrior_protection.spells.intimidating_shout = 5246
TankEngine.warrior_protection.spells.storm_bolt = 107570
TankEngine.warrior_protection.spells.shockwave = 46968
TankEngine.warrior_protection.spells.pummel = 6552

-- Utility functions

-- Check if a target is in taunt range
function TankEngine.warrior_protection.is_in_taunt_range(target)
    if not target then return false end
    
    local taunt_range = 30 -- yards
    local distance = TankEngine.variables.get_distance_to(TankEngine.variables.me, target)
    
    return distance <= taunt_range
end

-- Check if we should taunt a target
function TankEngine.warrior_protection.should_taunt(target)
    if not target or not TankEngine.warrior_protection.is_in_taunt_range(target) then
        return false
    end
    
    -- Check if we're the tank
    local unit_helper = TankEngine.api.unit_helper
    local is_tank = unit_helper:is_tank(TankEngine.variables.me)
    if not is_tank then return false end
    
    -- Check if target is targeting someone else in our group
    local target_target = target:get_target()
    if not target_target then return false end
    
    -- Don't taunt if target is already targeting us
    if target_target:get_guid() == TankEngine.variables.me:get_guid() then
        return false
    end
    
    -- Check if target's target is in our group
    local is_group_member = target_target:is_in_party() or target_target:is_in_raid()
    
    -- Only taunt if target is targeting a group member
    return is_group_member
end

-- Check if we should use Heroic Leap
function TankEngine.warrior_protection.should_heroic_leap()
    -- Use Heroic Leap for mobility
    local me = TankEngine.variables.me
    local target = nil
    
    -- Safely get target using the new safe getter
    if TankEngine.variables.get_safe_target then
        target = TankEngine.variables.get_safe_target()
    else
        -- Fallback to manual safe retrieval
        if TankEngine.variables.target then
            if type(TankEngine.variables.target) == "function" then
                -- Safely call the function
                local success, result = pcall(TankEngine.variables.target)
                if success and result and result:is_valid() then
                    target = result
                end
            else
                -- Direct reference
                target = TankEngine.variables.target
            end
        end
    end
    
    if not target then return false end
    
    local distance = TankEngine.variables.get_distance_to(me, target)
    local min_distance = 10 -- yards
    local max_distance = 40 -- yards
    
    -- Use Heroic Leap if target is far away but within range
    return distance >= min_distance and distance <= max_distance
end

-- Check if we should use Heroic Throw
function TankEngine.warrior_protection.should_heroic_throw(target)
    if not target then return false end
    
    local distance = TankEngine.variables.get_distance_to(TankEngine.variables.me, target)
    local min_range = 8 -- yards
    local max_range = 30 -- yards
    
    -- Use Heroic Throw for ranged pulling or when target is out of melee range
    return distance >= min_range and distance <= max_range
end

-- Check if we should use Intervene
function TankEngine.warrior_protection.should_intervene()
    -- Use Intervene to help allies
    local group_members = TankEngine.variables.group_members or {}
    
    for _, member in ipairs(group_members) do
        if not member:is_dead() and member:get_guid() ~= TankEngine.variables.me:get_guid() then
            local member_health = member:get_health()
            local member_max_health = member:get_max_health()
            local health_percent = (member_health / member_max_health) * 100
            local distance = TankEngine.variables.me:get_distance_to(member)
            
            -- Intervene to help low health allies within range
            if health_percent < 50 and distance <= 25 and distance >= 8 then
                return true, member
            end
        end
    end
    
    return false, nil
end

-- Check if we should use Intimidating Shout
function TankEngine.warrior_protection.should_intimidating_shout()
    local enemy_count = TankEngine.variables.enemies_in_melee_range()
    local me = TankEngine.variables.me
    local current_health = me:get_health()
    local max_health = me:get_max_health()
    local health_percent = (current_health / max_health) * 100
    
    -- Use Intimidating Shout as an emergency defensive or for crowd control
    return enemy_count >= 3 or health_percent < 30
end

-- Check if we should use Storm Bolt
function TankEngine.warrior_protection.should_storm_bolt(target)
    if not target then return false end
    
    -- Use Storm Bolt to interrupt or as crowd control
    local is_casting = target:is_casting()
    local me = TankEngine.variables.me
    local current_health = me:get_health()
    local max_health = me:get_max_health()
    local health_percent = (current_health / max_health) * 100
    
    return is_casting or health_percent < 40
end

-- Check if we should use Shockwave
function TankEngine.warrior_protection.should_shockwave()
    local enemy_count = TankEngine.variables.enemies_in_melee_range()
    local min_enemies = 3
    
    -- Use Shockwave for AoE stun
    return enemy_count >= min_enemies
end

-- Check if we should use Pummel
function TankEngine.warrior_protection.should_pummel(target)
    if not target then return false end
    
    -- Use Pummel to interrupt important spells
    local is_casting = target:is_casting()
    if not is_casting then return false end
    
    -- Get the spell being cast
    local spell_id = target:get_cast_spell_id()
    if not spell_id then return false end
    
    -- Check if the spell is interruptible
    local is_interruptible = target:is_cast_interruptible()
    
    -- List of high-priority spells to interrupt
    local priority_interrupts = {
        -- Add important spell IDs here
    }
    
    -- Always interrupt high-priority spells
    if priority_interrupts[spell_id] then
        return true
    end
    
    -- Otherwise, interrupt if the spell is interruptible and we're the tank
    local unit_helper = TankEngine.api.unit_helper
    local is_tank = unit_helper:is_tank(TankEngine.variables.me)
    return is_interruptible and is_tank
end

-- Get the best target for taunting
function TankEngine.warrior_protection.get_best_taunt_target()
    local enemies = TankEngine.variables.enemies or {}
    local best_target = nil
    local best_priority = 0
    
    for _, enemy in ipairs(enemies) do
        if TankEngine.warrior_protection.is_in_taunt_range(enemy) then
            local priority = 0
            
            -- Check if enemy is targeting a non-tank
            local enemy_target = enemy:get_target()
            if enemy_target then
                local unit_helper = TankEngine.api.unit_helper
                if not unit_helper:is_tank(enemy_target) then
                    priority = priority + 10
                end
            end
            
            -- Check if enemy is a boss
            if enemy:is_boss() then
                priority = priority + 20
            end
            
            -- Check if enemy has high health
            local enemy_health = enemy:get_health()
            local enemy_max_health = enemy:get_max_health()
            local health_percent = (enemy_health / enemy_max_health) * 100
            if health_percent > 80 then
                priority = priority + 5
            end
            
            -- Update best target if this enemy has higher priority
            if priority > best_priority then
                best_target = enemy
                best_priority = priority
            end
        end
    end
    
    return best_target
end