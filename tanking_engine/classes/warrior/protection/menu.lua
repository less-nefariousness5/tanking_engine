-- Protection Warrior Menu Configuration

-- Initialize namespace if not already done
TankEngine.warrior_protection = TankEngine.warrior_protection or {}
TankEngine.warrior_protection.menu = TankEngine.warrior_protection.menu or {}

-- Menu elements
TankEngine.warrior_protection.menu.elements = {
    -- General settings
    enable_module = TankEngine.menu.checkbox(true, "warrior_prot_enable"),
    use_defensives = TankEngine.menu.checkbox(true, "warrior_prot_use_defensives"),
    show_debug_info = TankEngine.menu.checkbox(false, "warrior_prot_show_debug"),
    
    -- Defensive settings
    shield_wall_threshold = TankEngine.menu.slider_int(20, 60, 30, "warrior_prot_shield_wall_threshold"),
    last_stand_threshold = TankEngine.menu.slider_int(30, 70, 40, "warrior_prot_last_stand_threshold"),
    demoralizing_shout_threshold = TankEngine.menu.slider_int(40, 80, 60, "warrior_prot_demo_shout_threshold"),
    
    -- Active mitigation settings
    shield_block_threshold = TankEngine.menu.slider_int(60, 90, 80, "warrior_prot_shield_block_threshold"),
    ignore_pain_threshold = TankEngine.menu.slider_int(70, 95, 85, "warrior_prot_ignore_pain_threshold"),
    
    -- Rage management
    min_rage_for_ignore_pain = TankEngine.menu.slider_int(30, 60, 40, "warrior_prot_min_rage_ip"),
    min_rage_for_shield_block = TankEngine.menu.slider_int(20, 50, 30, "warrior_prot_min_rage_sb"),
    
    -- Advanced settings
    save_rage_for_defensives = TankEngine.menu.checkbox(true, "warrior_prot_save_rage"),
    prioritize_shield_block = TankEngine.menu.checkbox(true, "warrior_prot_prio_sb"),
    use_victory_rush_on_proc = TankEngine.menu.checkbox(true, "warrior_prot_vr_on_proc"),
    
    -- WigsTracker integration
    use_wigs_tracker = TankEngine.menu.checkbox(true, "warrior_prot_use_wigs"),
    proactive_defensive_time = TankEngine.menu.slider_float(0.5, 3.0, 1.5, "warrior_prot_proactive_time"),
}

-- Render the menu
function TankEngine.warrior_protection.menu.on_render_menu()
    -- Create menu tree if it doesn't exist
    if not TankEngine.warrior_protection.menu.tree then
        TankEngine.warrior_protection.menu.tree = TankEngine.menu.tree_node()
    end
    
    -- Render the menu tree
    TankEngine.warrior_protection.menu.tree:render("Protection Warrior", function()
        -- Main enable/disable toggle
        if TankEngine.warrior_protection.menu.elements.enable_module then
            TankEngine.warrior_protection.menu.elements.enable_module:render("Enable Protection Warrior Module", 
                "Enable or disable the Protection Warrior module")
        end
        
        -- Only show additional options when enabled
        if not TankEngine.warrior_protection.menu.elements.enable_module:get_state() then return end
        
        -- General settings
        if TankEngine.warrior_protection.menu.elements.use_defensives then
            TankEngine.warrior_protection.menu.elements.use_defensives:render("Use Defensive Cooldowns", 
                "Enable or disable automatic defensive cooldown usage")
        end
        
        if TankEngine.warrior_protection.menu.elements.show_debug_info then
            TankEngine.warrior_protection.menu.elements.show_debug_info:render("Show Debug Information\n", 
                "Display debug information on screen")
        end
        
        -- Defensive cooldowns section
        local defensive_tree = TankEngine.menu.tree_node()
        if defensive_tree then
            defensive_tree:render("Defensive Cooldowns", function()
                -- Major defensives
                if TankEngine.warrior_protection.menu.elements.shield_wall_threshold then
                    TankEngine.warrior_protection.menu.elements.shield_wall_threshold:render("Shield Wall Health Threshold %\n", 
                        "Use Shield Wall when health falls below this percentage")
                end
                
                if TankEngine.warrior_protection.menu.elements.last_stand_threshold then
                    TankEngine.warrior_protection.menu.elements.last_stand_threshold:render("Last Stand Health Threshold %\n", 
                        "Use Last Stand when health falls below this percentage")
                end
                
                if TankEngine.warrior_protection.menu.elements.demoralizing_shout_threshold then
                    TankEngine.warrior_protection.menu.elements.demoralizing_shout_threshold:render("Demoralizing Shout Health Threshold %\n", 
                        "Use Demoralizing Shout when health falls below this percentage")
                end
            end)
        end
        
        -- Active mitigation section
        local mitigation_tree = TankEngine.menu.tree_node()
        if mitigation_tree then
            mitigation_tree:render("Active Mitigation", function()
                if TankEngine.warrior_protection.menu.elements.shield_block_threshold then
                    TankEngine.warrior_protection.menu.elements.shield_block_threshold:render("Shield Block Health Threshold %\n", 
                        "Use Shield Block when health falls below this percentage")
                end
                
                if TankEngine.warrior_protection.menu.elements.ignore_pain_threshold then
                    TankEngine.warrior_protection.menu.elements.ignore_pain_threshold:render("Ignore Pain Health Threshold %\n", 
                        "Use Ignore Pain when health falls below this percentage")
                end
                
                if TankEngine.warrior_protection.menu.elements.min_rage_for_shield_block then
                    TankEngine.warrior_protection.menu.elements.min_rage_for_shield_block:render("Minimum Rage for Shield Block\n", 
                        "Minimum rage required to use Shield Block")
                end
                
                if TankEngine.warrior_protection.menu.elements.min_rage_for_ignore_pain then
                    TankEngine.warrior_protection.menu.elements.min_rage_for_ignore_pain:render("Minimum Rage for Ignore Pain\n", 
                        "Minimum rage required to use Ignore Pain")
                end
                
                if TankEngine.warrior_protection.menu.elements.save_rage_for_defensives then
                    TankEngine.warrior_protection.menu.elements.save_rage_for_defensives:render("Save Rage for Defensives", 
                        "Save rage for defensive abilities when health is low")
                end
                
                if TankEngine.warrior_protection.menu.elements.prioritize_shield_block then
                    TankEngine.warrior_protection.menu.elements.prioritize_shield_block:render("Prioritize Shield Block", 
                        "Prioritize Shield Block over Ignore Pain for physical damage")
                end
            end)
        end
        
        -- Advanced settings section
        local advanced_tree = TankEngine.menu.tree_node()
        if advanced_tree then
            advanced_tree:render("Advanced Settings", function()
                if TankEngine.warrior_protection.menu.elements.use_victory_rush_on_proc then
                    TankEngine.warrior_protection.menu.elements.use_victory_rush_on_proc:render("Use Victory Rush on Proc", 
                        "Automatically use Victory Rush/Impending Victory when available")
                end
                
                -- WigsTracker integration
                if TankEngine.warrior_protection.menu.elements.use_wigs_tracker then
                    TankEngine.warrior_protection.menu.elements.use_wigs_tracker:render("Use BigWigs Integration", 
                        "Use BigWigs/LittleWigs integration for proactive defensive usage")
                end
                
                if TankEngine.warrior_protection.menu.elements.use_wigs_tracker:get_state() and 
                   TankEngine.warrior_protection.menu.elements.proactive_defensive_time then
                    TankEngine.warrior_protection.menu.elements.proactive_defensive_time:render("Proactive Defensive Time (seconds)                                ", 
                        "How many seconds before a boss ability to use defensives")
                end
            end)
        end
    end)
end

-- Update defensive thresholds based on menu settings
function TankEngine.warrior_protection.menu.update_defensive_thresholds()
    -- Update major defensive thresholds
    for _, defensive in ipairs(TankEngine.warrior_protection.defensives.major) do
        if defensive.name == "Shield Wall" then
            defensive.threshold = TankEngine.warrior_protection.menu.elements.shield_wall_threshold:get()
        elseif defensive.name == "Last Stand" then
            defensive.threshold = TankEngine.warrior_protection.menu.elements.last_stand_threshold:get()
        end
    end
    
    -- Update medium defensive thresholds
    for _, defensive in ipairs(TankEngine.warrior_protection.defensives.medium) do
        if defensive.name == "Demoralizing Shout" then
            defensive.threshold = TankEngine.warrior_protection.menu.elements.demoralizing_shout_threshold:get()
        end
    end
    
    -- Update minor defensive thresholds
    for _, defensive in ipairs(TankEngine.warrior_protection.defensives.minor) do
        if defensive.name == "Shield Block" then
            defensive.threshold = TankEngine.warrior_protection.menu.elements.shield_block_threshold:get()
        elseif defensive.name == "Ignore Pain" then
            defensive.threshold = TankEngine.warrior_protection.menu.elements.ignore_pain_threshold:get()
        end
    end
end

-- Initialize menu settings
function TankEngine.warrior_protection.menu.initialize()
    -- Update defensive thresholds based on menu settings
    TankEngine.warrior_protection.menu.update_defensive_thresholds()
    
    -- Register menu update callback
    core.register_on_update_callback(function()
        TankEngine.warrior_protection.menu.update_defensive_thresholds()
    end)
end 