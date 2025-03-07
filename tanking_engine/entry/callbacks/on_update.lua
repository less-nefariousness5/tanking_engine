---@alias on_update fun()

---@type on_update
function TankEngine.entry_helper.on_update()
    -- Check if the tanking engine is enabled
    if not TankEngine.settings.is_enabled() then
        return
    end
    
    -- Process fast updates for all modules
    for _, module in pairs(TankEngine.loaded_modules) do
        if module.on_fast_update then
            module.on_fast_update()
        end
    end
    
    -- Apply humanization to simulate natural play
    if not TankEngine.humanizer.can_run() then
        return
    end
    
    -- Update local player reference
    TankEngine.variables.me = core.object_manager.get_local_player()
    
    -- Update humanizer timing
    TankEngine.humanizer.update()
    
    -- Run update functions for all modules
    for _, module in pairs(TankEngine.loaded_modules) do
        if module.on_update then
            module.on_update()
        end
    end
    
    -- Run spec-specific update function
    if TankEngine.spec_config.on_update then
        TankEngine.spec_config.on_update()
    end
end
