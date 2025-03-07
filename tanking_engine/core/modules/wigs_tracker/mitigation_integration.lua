-- Integration with the mitigation module

-- Check if any dangerous abilities are coming soon and suggest defensive cooldowns
function TankEngine.modules.wigs_tracker.check_incoming_boss_abilities()
    -- Skip if module isn't enabled
    if not TankEngine.modules.wigs_tracker.settings.enabled() then
        return false, nil
    end
    
    -- Check if any dangerous abilities are coming soon
    local should_use_defensive, dangerous_bar = TankEngine.modules.wigs_tracker.should_use_defensive()
    
    if should_use_defensive and dangerous_bar then
        -- Make sure dangerous_bar has all required fields
        if not dangerous_bar.text or not dangerous_bar.remaining or not dangerous_bar.importance then
            core.log_error("[WigsTracker] Dangerous bar missing required fields")
            return false, nil
        end
        
        -- Log the decision
        core.log(string.format("[Mitigation] Preparing for %s (%.1fs remaining, Priority: %d)", 
            dangerous_bar.text, dangerous_bar.remaining, dangerous_bar.importance))
        
        return true, dangerous_bar
    end
    
    return false, nil
end

-- Add this function to the mitigation module's decision-making process
function TankEngine.modules.wigs_tracker.integrate_with_mitigation()
    -- Skip if mitigation module isn't loaded
    if not TankEngine.modules.mitigation then
        return
    end
    
    -- Add a function to check for boss abilities in the mitigation module
    TankEngine.modules.mitigation.check_incoming_boss_abilities = TankEngine.modules.wigs_tracker.check_incoming_boss_abilities
    
    -- Log successful integration
    core.log("[WigsTracker] Successfully integrated with mitigation module")
end 