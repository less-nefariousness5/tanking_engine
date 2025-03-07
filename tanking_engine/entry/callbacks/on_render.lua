---@alias on_render fun()

---@type on_render
function TankEngine.entry_helper.on_render()
    -- Check if script is enabled
    if not TankEngine.settings.is_enabled() then
        return
    end

    -- Run module render functions
    for _, module in pairs(TankEngine.loaded_modules) do
        if module.on_render then
            module.on_render()
        end
    end

    -- Render spec module if available
    if TankEngine.spec_config and TankEngine.spec_config.on_render then
        TankEngine.spec_config.on_render()
    end
end
