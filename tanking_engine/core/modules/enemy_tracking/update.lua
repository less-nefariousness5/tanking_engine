---Initialize tracking for a new enemy
---@param enemy game_object
local function init_enemy_tracking(enemy)
    if not enemy or not enemy:is_valid() then
        return
    end
    
    TankEngine.modules.enemy_tracking.tracked_enemies[enemy] = {
        unit = enemy,
        cast_history = {},
        cooldowns = {},
        interrupt_priority = 0,
        is_dangerous = false,
        current_cast = nil,
        pathing_pattern = nil,
        position_history = {}
    }
end

---Update cast information for an enemy
---@param enemy game_object
---@param enemy_data EnemyData
local function update_cast_info(enemy, enemy_data)
    if enemy:is_casting_spell() then
        local spell = enemy:get_current_cast_spell()
        
        if spell then
            enemy_data.current_cast = {
                spell_id = spell.spell_id,
                name = spell.name,
                cast_time = spell.cast_time,
                start_time = spell.start_time,
                end_time = spell.end_time,
                interruptible = TankEngine.api.spell_helper:is_spell_interruptible(enemy, spell.spell_id),
                priority = TankEngine.modules.enemy_tracking.get_interrupt_priority(spell.spell_id),
                is_dangerous = TankEngine.modules.enemy_tracking.is_dangerous_spell(spell.spell_id)
            }
            
            -- Set interrupt priority based on spell
            enemy_data.interrupt_priority = enemy_data.current_cast.priority
            
            -- Set dangerous flag if casting dangerous spell
            enemy_data.is_dangerous = enemy_data.is_dangerous or enemy_data.current_cast.is_dangerous
        end
    else
        -- If enemy was casting but isn't anymore, record the cast
        if enemy_data.current_cast then
            local spell_id = enemy_data.current_cast.spell_id
            enemy_data.cast_history[spell_id] = core.game_time()
            
            -- Reset current cast
            enemy_data.current_cast = nil
            
            -- Recalculate interrupt priority
            enemy_data.interrupt_priority = 0
        end
    end
end

---Update position history for an enemy
---@param enemy game_object
---@param enemy_data EnemyData
local function update_position_history(enemy, enemy_data)
    local position = enemy:get_position()
    
    -- Add current position to history
    table.insert(enemy_data.position_history, {
        x = position.x,
        y = position.y,
        z = position.z,
        time = core.game_time()
    })
    
    -- Trim history to maintain maximum length
    while #enemy_data.position_history > TankEngine.modules.enemy_tracking.settings.position_history_length() do
        table.remove(enemy_data.position_history, 1)
    end
    
    -- Update pathing pattern if enabled
    if TankEngine.modules.enemy_tracking.settings.enable_pathing_prediction() and #enemy_data.position_history >= 3 then
        enemy_data.pathing_pattern = TankEngine.modules.enemy_tracking.analyze_pathing(enemy_data.position_history)
    end
end

---Perform fast updates for enemy tracking
function TankEngine.modules.enemy_tracking.on_fast_update()
    local current_time = core.game_time()
    
    -- Only update at specified intervals
    if current_time - TankEngine.modules.enemy_tracking.last_update < TankEngine.modules.enemy_tracking.update_interval then
        return
    end
    
    -- Get nearby enemies
    for _, enemy in ipairs(TankEngine.variables.nearby_enemies) do
        if enemy and enemy:is_valid() and not enemy:is_dead() then
            -- Initialize tracking if this is a new enemy
            if not TankEngine.modules.enemy_tracking.tracked_enemies[enemy] then
                init_enemy_tracking(enemy)
            end
            
            -- Get existing enemy data
            local enemy_data = TankEngine.modules.enemy_tracking.tracked_enemies[enemy]
            
            -- Update cast information
            update_cast_info(enemy, enemy_data)
            
            -- Update position history
            update_position_history(enemy, enemy_data)
        end
    end
    
    -- Clean up stale enemy data
    for enemy, data in pairs(TankEngine.modules.enemy_tracking.tracked_enemies) do
        if not enemy or not enemy:is_valid() or enemy:is_dead() or 
           TankEngine.variables.me:get_position():dist_to(enemy:get_position()) > TankEngine.modules.enemy_tracking.settings.max_tracking_distance() then
            TankEngine.modules.enemy_tracking.tracked_enemies[enemy] = nil
        end
    end
    
    -- Record last update
    TankEngine.modules.enemy_tracking.last_update = current_time
end

---Process main update logic for enemy tracking
function TankEngine.modules.enemy_tracking.on_update()
    -- This function can be used for less frequent or more intensive processing
end

---Custom render function for enemy visualization
function TankEngine.modules.enemy_tracking.on_render()
    -- Implement visualization of enemy cast bars, danger indicators, etc.
end
