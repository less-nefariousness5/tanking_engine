if TankEngine.entry_helper.init() then
    core.register_on_update_callback(TankEngine.entry_helper.on_update)
    core.register_on_render_callback(TankEngine.entry_helper.on_render)
    core.register_on_render_menu_callback(TankEngine.entry_helper.on_render_menu)
    core.register_on_render_control_panel_callback(TankEngine.entry_helper.on_render_control_panel)
    core.log("Successfully initialized Tanking Engine")
else
    core.log("Failed to initialize Tanking Engine")
end
