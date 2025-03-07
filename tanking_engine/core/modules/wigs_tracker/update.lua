---@type wigs_tracker
local wigs_tracker = require("common/utility/wigs_tracker")
---@type color
local color = require("common/color")


-- Update function called on each frame
function TankEngine.modules.wigs_tracker.on_update()
    if not TankEngine.modules.wigs_tracker.settings.enabled() then
        return
    end
    
    local current_time = core.time()
    
    -- Only update at the specified interval
    if current_time - TankEngine.modules.wigs_tracker.last_update_time < TankEngine.modules.wigs_tracker.update_interval then
        return
    end
    
    TankEngine.modules.wigs_tracker.last_update_time = current_time
    
    -- Update active bars cache
    TankEngine.modules.wigs_tracker.active_bars = TankEngine.modules.wigs_tracker.get_active_bars()
    
    -- Check for important abilities
    local warning_threshold = TankEngine.modules.wigs_tracker.settings.warning_threshold()
    local important_bars = TankEngine.modules.wigs_tracker.get_important_bars(warning_threshold)
    
    -- Debug output if enabled
    if TankEngine.modules.wigs_tracker.settings.show_debug_info() and #important_bars > 0 then
        for _, bar in ipairs(important_bars) do
            core.log(string.format("[WigsTracker] Important ability: %s - %.1fs remaining (Priority: %d)", 
                bar.text, bar.remaining, bar.importance))
        end
    end
    
    -- Check if we should suggest using a defensive cooldown
    local should_use_defensive, dangerous_bar = TankEngine.modules.wigs_tracker.should_use_defensive()
    if should_use_defensive and dangerous_bar then
        -- Make sure dangerous_bar has all required fields
        if dangerous_bar.text and dangerous_bar.remaining and dangerous_bar.importance then
            -- Log the suggestion
            core.log(string.format("[WigsTracker] Dangerous ability incoming: %s - %.1fs remaining (Priority: %d)", 
                dangerous_bar.text, dangerous_bar.remaining, dangerous_bar.importance))
        else
            core.log_error("[WigsTracker] Dangerous bar missing required fields")
        end
    end
end

-- Render debug information if enabled
function TankEngine.modules.wigs_tracker.on_render()
    if not TankEngine.modules.wigs_tracker.settings.enabled() or 
       not TankEngine.modules.wigs_tracker.settings.show_debug_info() then
        return
    end
    
    local warning_threshold = TankEngine.modules.wigs_tracker.settings.warning_threshold()
    local important_bars = TankEngine.modules.wigs_tracker.get_important_bars(warning_threshold)
    
    if important_bars and #important_bars > 0 then
        local y_offset = 100
        for _, bar in ipairs(important_bars) do
            -- Skip bars with missing fields
            if not bar.text or not bar.remaining or not bar.importance then
                goto continue
            end
            
            local color_val = 255 * math.min(1.0, bar.importance / 10)
            local text_color = color.new(255, 255 - color_val, 255 - color_val, 255)
            
            core.drawing.draw_text_world(
                core.vector.new(0, y_offset, 0),
                string.format("%s: %.1fs (Priority: %d)", bar.text, bar.remaining, bar.importance),
                text_color
            )
            
            y_offset = y_offset + 15
            
            ::continue::
        end
    end
end 