---@type control_panel_helper
local control_panel_helper = require("common/utility/control_panel_helper")
---@type key_helper
local key_helper = require("common/utility/key_helper")
---@type color
local color = require("common/color")
---@type vec2
local vec2 = require("common/geometry/vector_2")

local tag = "tank_engine_"

-- Menu system for the tanking engine
TankEngine.menu = {
    main_tree = core.menu.tree_node(),
    enable_script_check = core.menu.checkbox(false, tag .. "enable_script_check"),
    
    -- Humanizer settings
    humanizer = {
        tree = core.menu.tree_node(),
        enable_humanizer = core.menu.checkbox(true, tag .. "enable_humanizer"),
        min_delay = core.menu.slider_int(0, 1500, 125, tag .. "min_delay"),
        max_delay = core.menu.slider_int(1, 1500, 250, tag .. "max_delay"),
        
        -- Advanced randomization (jitter) settings
        jitter = {
            enable_jitter = core.menu.checkbox(true, tag .. "enable_jitter"),
            base_jitter = core.menu.slider_float(0.05, 0.30, 0.15, tag .. "base_jitter"),
            latency_jitter = core.menu.slider_float(0.01, 0.20, 0.05, tag .. "latency_jitter"),
            max_jitter = core.menu.slider_float(0.10, 0.50, 0.25, tag .. "max_jitter"),
        },
    },
    
    -- Threat management settings
    threat = {
        tree = core.menu.tree_node(),
        prioritize_loose_mobs = core.menu.checkbox(true, tag .. "prioritize_loose_mobs"),
        taunt_threshold = core.menu.slider_int(50, 100, 80, tag .. "taunt_threshold"),
        auto_taunt = core.menu.checkbox(true, tag .. "auto_taunt"),
        target_swap_threshold = core.menu.slider_int(0, 100, 60, tag .. "target_swap_threshold"),
    },
    
    -- Mitigation settings
    mitigation = {
        tree = core.menu.tree_node(),
        -- Healing Awareness settings
        consider_incoming_heals = core.menu.checkbox(true, tag .. "consider_incoming_heals"),
        heal_significance_threshold = core.menu.slider_int(5, 25, 10, tag .. "heal_significance_threshold"),
        -- Standard mitigation settings
        major_cooldown_threshold = core.menu.slider_int(10, 90, 40, tag .. "major_cooldown_threshold"),
        minor_cooldown_threshold = core.menu.slider_int(40, 95, 70, tag .. "minor_cooldown_threshold"),
        predictive_mitigation = core.menu.checkbox(true, tag .. "predictive_mitigation"),
        active_mitigation_overlap = core.menu.slider_int(0, 50, 20, tag .. "active_mitigation_overlap"),
        save_for_spikes = core.menu.checkbox(true, tag .. "save_for_spikes"),
    },
    
    -- Movement settings
    movement = {
        tree = core.menu.tree_node(),
        auto_position = core.menu.checkbox(true, tag .. "auto_position"),
        kiting_threshold = core.menu.slider_int(10, 60, 30, tag .. "kiting_threshold"),
        maintain_range = core.menu.checkbox(true, tag .. "maintain_range"),
    },
    
    -- Interrupt settings
    interrupt = {
        tree = core.menu.tree_node(),
        auto_interrupt = core.menu.checkbox(true, tag .. "auto_interrupt"),
        prioritize_dangerous = core.menu.checkbox(true, tag .. "prioritize_dangerous"),
        save_for_important = core.menu.checkbox(true, tag .. "save_for_important"),
    },
}

-- Default window style configuration
TankEngine.menu.window_style = {
    background = {
        top_left = color.new(31, 31, 46, 255),
        top_right = color.new(20, 20, 31, 255),
        bottom_right = color.new(31, 31, 46, 255),
        bottom_left = color.new(20, 20, 31, 255)
    },
    size = vec2.new(800, 500),
    padding = vec2.new(15, 15),
    header_color = color.new(255, 255, 255, 255),
    header_spacing = 36,
    column_spacing = 400
}

-- Window helper functions
---Setup window with default styling
---@param window window The window to setup
function TankEngine.menu.setup_window(window)
    window:set_background_multicolored(
        TankEngine.menu.window_style.background.top_left,
        TankEngine.menu.window_style.background.top_right,
        TankEngine.menu.window_style.background.bottom_right,
        TankEngine.menu.window_style.background.bottom_left
    )
    window:set_initial_size(TankEngine.menu.window_style.size)
    window:set_next_window_padding(TankEngine.menu.window_style.padding)
end

---Render a header with consistent styling
---@param window window The window to render in
---@param text string The header text
function TankEngine.menu.render_header(window, text)
    local dynamic = window:get_current_context_dynamic_drawing_offset()
    window:render_text(1, vec2.new(dynamic.x, dynamic.y), TankEngine.menu.window_style.header_color, text)
    window:set_current_context_dynamic_drawing_offset(
        vec2.new(dynamic.x, dynamic.y + TankEngine.menu.window_style.header_spacing)
    )
end

---Begin a two-column layout section
---@param window window The window to render in
---@param left_content function Function to render left column content
---@param right_content function Function to render right column content
function TankEngine.menu.begin_columns(window, left_content, right_content)
    local window_size = window:get_size()

    -- Left Column
    window:begin_group(function()
        window:set_next_window_padding(vec2.new((window_size.x - 625) / 2, 0))
        left_content()
    end)

    -- Right Column
    window:draw_next_dynamic_widget_on_same_line(TankEngine.menu.window_style.column_spacing)
    window:begin_group(right_content)
end

---Render a settings section with header and sliders/checkboxes
---@param window window The window to render in
---@param title string Section title
---@param objects table Array of {slider = slider_object, label = string, tooltip = string} or {checkbox = checkbox_object, label = string, tooltip = string}
function TankEngine.menu.render_settings_section(window, title, objects)
    TankEngine.menu.render_header(window, title)
    for _, obj in ipairs(objects) do
        if obj.slider then
            obj.slider:render(obj.label, obj.tooltip)
        elseif obj.checkbox then
            obj.checkbox:render(obj.label, obj.tooltip)
        elseif obj.keybind then
            obj.keybind:render(obj.label, obj.tooltip)
        end
    end
end

-- Helper functions for menu generation
function TankEngine.menu.insert_toggle(control_panel, keybind, name)
    control_panel_helper:insert_toggle(control_panel,
        {
            name = "[Tank Engine " .. name .. "] Enable (" ..
                key_helper:get_key_name(keybind:get_key_code()) .. ") ",
            keybind = keybind
        })
end

function TankEngine.menu.register_menu()
    return core.menu.register_menu()
end

function TankEngine.menu.tree_node()
    return core.menu.tree_node()
end

function TankEngine.menu.checkbox(default_state, id)
    return core.menu.checkbox(default_state, tag .. id)
end

function TankEngine.menu.key_checkbox(default_key, initial_toggle_state, default_state, show_in_binds, default_mode_state, id)
    return core.menu.key_checkbox(default_key, initial_toggle_state, default_state, show_in_binds, default_mode_state, tag .. id)
end

function TankEngine.menu.slider_int(min_value, max_value, default_value, id)
    return core.menu.slider_int(min_value, max_value, default_value, tag .. id)
end

function TankEngine.menu.slider_float(min_value, max_value, default_value, id)
    return core.menu.slider_float(min_value, max_value, default_value, tag .. id)
end

function TankEngine.menu.combobox(default_index, id)
    return core.menu.combobox(default_index, tag .. id)
end

function TankEngine.menu.combobox_reorderable(default_index, id)
    return core.menu.combobox_reorderable(default_index, tag .. id)
end

function TankEngine.menu.keybind(default_value, initial_toggle_state, id)
    return core.menu.keybind(default_value, initial_toggle_state, tag .. id)
end

function TankEngine.menu.button(id)
    return core.menu.button(tag .. id)
end

function TankEngine.menu.colorpicker(default_color, id)
    return core.menu.colorpicker(default_color, tag .. id)
end

function TankEngine.menu.header()
    return core.menu.header()
end

function TankEngine.menu.text_input(id)
    return core.menu.text_input(tag .. id)
end

function TankEngine.menu.window(window_id)
    return core.menu.window(tag .. window_id)
end
