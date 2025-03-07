---Updates group member categorization
local function update_group_members()
    local module = TankEngine.modules.threat_manager
    module.tanks = {}
    module.healers = {}
    module.dps = {}
    
    -- Get all party members
    local units = core.object_manager.get_all_objects()
    
    for _, unit in pairs(units) do
        if unit and unit:is_valid() and unit:is_player() and unit:is_party_member() then
            if TankEngine.api.unit_helper:is_tank(unit) then
                table.insert(module.tanks, unit)
            elseif TankEngine.api.unit_helper:is_healer(unit) then
                table.insert(module.healers, unit)
            else
                table.insert(module.dps, unit)
            end
        end
    end
    
    -- Always include the player in the appropriate category
    local me = TankEngine.variables.me
    if me and me:is_valid() then
        local found = false
        
        for _, unit in ipairs(module.tanks) do
            if unit == me then
                found = true
                break
            end
        end
        
        if not found then
            -- Add myself to the tanks list since this is a tank engine
            table.insert(module.tanks, me)
        end
    end
end

---Perform fast updates for threat monitoring
function TankEngine.modules.threat_manager.on_fast_update()
    local current_time = core.game_time()
    
    -- Check if we need to update threat table
    if current_time - TankEngine.modules.threat_manager.last_update >= TankEngine.modules.threat_manager.update_interval then
        -- Update nearby enemies
        TankEngine.variables.update_nearby_enemies()
        
        -- Update enemy targets
        TankEngine.variables.update_enemy_targets()
        
        -- Update group member categories
        update_group_members()
        
        -- Process threat data
        TankEngine.modules.threat_manager.update_threat_table()
        
        -- Mark last update time
        TankEngine.modules.threat_manager.last_update = current_time
    end
end

---Process main update logic for the threat manager
function TankEngine.modules.threat_manager.on_update()
    -- Auto-taunt logic
    if TankEngine.modules.threat_manager.settings.auto_taunt() then
        TankEngine.modules.threat_manager.process_auto_taunt()
    end
    
    -- Target swap logic
    TankEngine.modules.threat_manager.process_target_swap()
end

---Updates the complete threat table
function TankEngine.modules.threat_manager.update_threat_table()
    local module = TankEngine.modules.threat_manager
    module.threat_table = {}
    
    for _, enemy in ipairs(TankEngine.variables.nearby_enemies) do
        if enemy and enemy:is_valid() and not enemy:is_dead() then
            local target = enemy:get_target()
            local is_targeting_tank = false
            local is_targeting_healer = false
            local is_targeting_dps = false
            
            -- Determine what role the enemy is targeting
            if target and target:is_valid() then
                for _, tank in ipairs(module.tanks) do
                    if target == tank then
                        is_targeting_tank = true
                        break
                    end
                end
                
                if not is_targeting_tank then
                    for _, healer in ipairs(module.healers) do
                        if target == healer then
                            is_targeting_healer = true
                            break
                        end
                    end
                end
                
                if not is_targeting_tank and not is_targeting_healer then
                    for _, dps in ipairs(module.dps) do
                        if target == dps then
                            is_targeting_dps = true
                            break
                        end
                    end
                end
            end
            
            -- Calculate threat values and taunt priority
            local threat_value = TankEngine.modules.threat_manager.calculate_threat_value(enemy)
            local taunt_priority = TankEngine.modules.threat_manager.calculate_taunt_priority(
                enemy, is_targeting_tank, is_targeting_healer, is_targeting_dps
            )
            
            -- Create threat data entry
            local threat_data = {
                unit = enemy,
                target = target,
                threat_value = threat_value,
                taunt_priority = taunt_priority,
                last_target_change = module.taunt_history[enemy] or 0,
                is_targeting_tank = is_targeting_tank,
                is_targeting_healer = is_targeting_healer,
                is_targeting_dps = is_targeting_dps,
                distance = TankEngine.variables.me:get_position():dist_to(enemy:get_position())
            }
            
            table.insert(module.threat_table, threat_data)
        end
    end
    
    -- Sort by taunt priority (higher first)
    table.sort(module.threat_table, function(a, b) 
        return a.taunt_priority > b.taunt_priority 
    end)
end

---Processes auto-taunt logic
function TankEngine.modules.threat_manager.process_auto_taunt()
    -- Implementation to check for high-priority taunt targets
    -- and automatically taunt them if needed
    
    local module = TankEngine.modules.threat_manager
    
    -- Check cooldown of taunt abilities
    local taunt_available = false
    local taunt_spell_id = 0
    
    -- Look for the highest priority taunt target
    for _, threat_data in ipairs(module.threat_table) do
        -- Skip if already targeting tank
        if threat_data.is_targeting_tank then
            goto continue
        end
        
        -- Check if taunt priority meets threshold
        if threat_data.taunt_priority >= module.settings.taunt_threshold() then
            -- Check if we have a taunt available
            if taunt_available and taunt_spell_id > 0 then
                -- Cast taunt on this target
                if TankEngine.api.spell_helper:cast_spell_on_unit(taunt_spell_id, threat_data.unit) then
                    -- Record taunt history
                    module.taunt_history[threat_data.unit] = core.game_time()
                    
                    -- Log taunt action
                    core.log("Auto-taunting " .. threat_data.unit:get_name() .. " with priority " .. 
                        string.format("%.1f", threat_data.taunt_priority))
                    
                    break
                end
            end
        end
        
        ::continue::
    end
end

---Processes target swap logic
function TankEngine.modules.threat_manager.process_target_swap()
    local module = TankEngine.modules.threat_manager
    
    -- Check if target exists and determine its type
    if not TankEngine.variables.target then
        return -- No target variable set, nothing to do
    end
    
    -- Check if target is a function or a direct value
    local current_target
    if type(TankEngine.variables.target) == "function" then
        current_target = TankEngine.variables.target()
    else
        current_target = TankEngine.variables.target
    end
    
    -- Ensure current_target is valid before proceeding
    if not current_target then
        return -- No actual target, nothing to do
    end
    
    -- Check if the target is valid and alive
    if not current_target:is_valid() or current_target:is_dead() then
        return -- Target is not valid or is dead, nothing to do
    end
    
    -- Check for a better target based on threat priority
    local best_target = nil
    local best_priority = 0
    
    for _, threat_data in ipairs(module.threat_table) do
        -- Skip current target
        if threat_data.unit == current_target then
            goto continue
        end
        
        -- Find the highest priority target above our threshold
        if threat_data.taunt_priority > best_priority and 
           threat_data.taunt_priority >= module.settings.target_swap_threshold() then
            best_target = threat_data.unit
            best_priority = threat_data.taunt_priority
        end
        
        ::continue::
    end
    
    -- Swap to better target if found
    if best_target then
        -- Use core.input.set_target instead of target_selector:set_target
        core.input.set_target(best_target)
        
        -- Add target switch delay for humanization
        local switch_delay = TankEngine.humanizer.target_switch_delay(
            TankEngine.variables.me:get_position():dist_to(best_target:get_position())
        )
        TankEngine.humanizer.next_run = core.game_time() + switch_delay
    end
end

---Custom render function for threat visualization
function TankEngine.modules.threat_manager.on_render()
    -- Add threat visualization if needed
end
