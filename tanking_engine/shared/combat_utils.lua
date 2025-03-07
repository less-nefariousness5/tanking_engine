-- Combat utility functions for the Tanking Engine

-- Directly require the enums to avoid circular dependency
local api_enums = require("common/enums")
local tank_enums = require("shared/tank_enums")

-- Combine enums
local enums = {}
for k, v in pairs(api_enums) do
    enums[k] = v
end
for k, v in pairs(tank_enums) do
    enums[k] = v
end

local utils = require("shared/utils")

local CombatUtils = {}

-- Check if the player is in a dangerous situation
---@param health_percent number Current health percentage (0-100)
---@param enemy_count number Number of enemies in combat
---@param is_boss boolean Whether fighting a boss
---@return boolean is_dangerous Whether the situation is dangerous
function CombatUtils.is_dangerous_situation(health_percent, enemy_count, is_boss)
    -- Low health is always dangerous
    if health_percent < 30 then
        return true
    end
    
    -- Many enemies is dangerous
    if enemy_count > 4 and health_percent < 60 then
        return true
    end
    
    -- Boss fights with moderate health loss
    if is_boss and health_percent < 50 then
        return true
    end
    
    return false
end

-- Analyze incoming damage type
---@param damage_events table Recent damage events
---@return number damage_type The predominant damage type
function CombatUtils.analyze_damage_type(damage_events)
    if not damage_events or #damage_events == 0 then
        return enums.mitigation_type.PHYSICAL
    end
    
    local damage_counts = {
        [enums.mitigation_type.PHYSICAL] = 0,
        [enums.mitigation_type.MAGICAL] = 0,
        [enums.mitigation_type.BLEED] = 0,
        [enums.mitigation_type.DOT] = 0
    }
    
    for _, event in ipairs(damage_events) do
        if event.school then
            if event.school == enums.spell_schools_flags.Physical then
                if event.is_dot then
                    damage_counts[enums.mitigation_type.BLEED] = damage_counts[enums.mitigation_type.BLEED] + event.amount
                else
                    damage_counts[enums.mitigation_type.PHYSICAL] = damage_counts[enums.mitigation_type.PHYSICAL] + event.amount
                end
            else
                if event.is_dot then
                    damage_counts[enums.mitigation_type.DOT] = damage_counts[enums.mitigation_type.DOT] + event.amount
                else
                    damage_counts[enums.mitigation_type.MAGICAL] = damage_counts[enums.mitigation_type.MAGICAL] + event.amount
                end
            end
        end
    end
    
    -- Find the damage type with the highest amount
    local highest_type = enums.mitigation_type.PHYSICAL
    local highest_amount = 0
    
    for damage_type, amount in pairs(damage_counts) do
        if amount > highest_amount then
            highest_amount = amount
            highest_type = damage_type
        end
    end
    
    return highest_type
end

-- Determine if the current damage pattern is burst or sustained
---@param damage_events table Recent damage events
---@param time_window number Time window to analyze (in seconds)
---@return number damage_pattern The damage pattern type
function CombatUtils.analyze_damage_pattern(damage_events, time_window)
    if not damage_events or #damage_events == 0 then
        return enums.mitigation_type.SUSTAINED
    end
    
    local current_time = core.time()
    local recent_damage = 0
    local total_damage = 0
    local recent_count = 0
    local total_count = 0
    
    for _, event in ipairs(damage_events) do
        total_damage = total_damage + event.amount
        total_count = total_count + 1
        
        if current_time - event.timestamp < time_window then
            recent_damage = recent_damage + event.amount
            recent_count = recent_count + 1
        end
    end
    
    -- If most damage happened recently, it's burst damage
    if recent_count > 0 and total_count > 0 then
        local recent_avg = recent_damage / recent_count
        local total_avg = total_damage / total_count
        
        if recent_avg > total_avg * 1.5 then
            return enums.mitigation_type.BURST
        end
    end
    
    return enums.mitigation_type.SUSTAINED
end

-- Prioritize defensive cooldowns based on the situation
---@param cooldowns table List of available defensive cooldowns
---@param health_percent number Current health percentage (0-100)
---@param damage_type number The predominant damage type
---@param damage_pattern number The damage pattern type
---@return table prioritized_cooldowns Prioritized list of cooldowns to use
function CombatUtils.prioritize_defensive_cooldowns(cooldowns, health_percent, damage_type, damage_pattern)
    if not cooldowns or #cooldowns == 0 then
        return {}
    end
    
    local prioritized = {}
    
    for _, cooldown in ipairs(cooldowns) do
        local priority = cooldown.base_priority or enums.cooldown_priority.MEDIUM
        
        -- Adjust priority based on health
        if health_percent < 30 then
            priority = priority + 1
        elseif health_percent > 70 then
            priority = priority - 1
        end
        
        -- Adjust priority based on damage type
        if cooldown.effective_against and cooldown.effective_against == damage_type then
            priority = priority + 1
        end
        
        -- Adjust priority based on damage pattern
        if damage_pattern == enums.mitigation_type.BURST and cooldown.is_burst_mitigation then
            priority = priority + 1
        elseif damage_pattern == enums.mitigation_type.SUSTAINED and cooldown.is_sustained_mitigation then
            priority = priority + 1
        end
        
        -- Ensure priority is within bounds
        priority = math.max(enums.cooldown_priority.LOW, math.min(enums.cooldown_priority.EMERGENCY, priority))
        
        table.insert(prioritized, {
            spell_id = cooldown.spell_id,
            name = cooldown.name,
            priority = priority
        })
    end
    
    -- Sort by priority (highest first)
    table.sort(prioritized, function(a, b)
        return a.priority > b.priority
    end)
    
    return prioritized
end

-- Check if an interrupt should be used on a target
---@param target game_object The target unit
---@param interrupt_spells table List of available interrupt spells
---@return number|nil spell_id The spell ID to use for interrupting, or nil if none
function CombatUtils.should_interrupt(target, interrupt_spells)
    if not target or not target:is_valid() or not interrupt_spells or #interrupt_spells == 0 then
        return nil
    end
    
    -- Check if the target is casting
    local is_casting, spell_id, spell_name = target:is_casting()
    if not is_casting then
        return nil
    end
    
    -- Check if the spell is interruptible
    local is_interruptible = target:is_interruptible()
    if not is_interruptible then
        return nil
    end
    
    -- Find the first available interrupt spell
    for _, interrupt in ipairs(interrupt_spells) do
        if utils.can_cast_spell(interrupt) then
            return interrupt
        end
    end
    
    return nil
end

-- Analyze group positioning and determine if tank needs to reposition
---@param group_members table List of group member units
---@param enemies table List of enemy units
---@return boolean should_reposition Whether the tank should reposition
---@return number strategy The positioning strategy to use
function CombatUtils.analyze_group_positioning(group_members, enemies)
    if not group_members or #group_members == 0 or not enemies or #enemies == 0 then
        return false, enums.positioning_strategy.STATIONARY
    end
    
    local local_player = core.object_manager.get_local_player()
    if not local_player then
        return false, enums.positioning_strategy.STATIONARY
    end
    
    -- Check if any group members are in danger
    local members_in_danger = 0
    for _, member in ipairs(group_members) do
        if member:is_valid() and member:get_guid() ~= local_player:get_guid() then
            -- Check if member is being targeted by enemies
            for _, enemy in ipairs(enemies) do
                if enemy:is_valid() then
                    local target = enemy:get_target()
                    if target and target:is_valid() and target:get_guid_string() == member:get_guid_string() then
                        members_in_danger = members_in_danger + 1
                        break
                    end
                end
            end
        end
    end
    
    -- If multiple members are in danger, we need to gather enemies
    if members_in_danger > 1 then
        return true, enums.positioning_strategy.GATHERING
    end
    
    -- Check if tank health is low and there are many enemies
    local health_percent = (local_player:get_health() / local_player:get_max_health()) * 100
    if health_percent < 30 and #enemies > 3 then
        return true, enums.positioning_strategy.KITING
    end
    
    -- Check if there's a boss enemy
    for _, enemy in ipairs(enemies) do
        if enemy:is_valid() and enemy:get_classification() >= enums.classification.ELITE then
            return true, enums.positioning_strategy.BOSS_POSITIONING
        end
    end
    
    return false, enums.positioning_strategy.STATIONARY
end

return CombatUtils 