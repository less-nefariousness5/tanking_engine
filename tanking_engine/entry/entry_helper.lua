---@type enums
local enums = require("shared/enums")

-- Entry helper provides utility functions for module loading and initialization
TankEngine.entry_helper = {
    -- Map of class and specialization IDs to module paths
    class_spec_map = {
        [enums.class_spec_id.spec_enum.PROTECTION_WARRIOR] = "warrior/protection",
        [enums.class_spec_id.spec_enum.PROTECTION_PALADIN] = "paladin/protection",
        [enums.class_spec_id.spec_enum.GUARDIAN_DRUID] = "druid/guardian",
        [enums.class_spec_id.spec_enum.BLOOD_DEATHKNIGHT] = "deathknight/blood",
        [enums.class_spec_id.spec_enum.BREWMASTER_MONK] = "monk/brewmaster",
        [enums.class_spec_id.spec_enum.VENGEANCE_DEMON_HUNTER] = "demonhunter/vengeance",
    },
    -- List of allowed specializations for this framework
    allowed_specs = {
        [enums.class_spec_id.spec_enum.PROTECTION_WARRIOR] = true,
        [enums.class_spec_id.spec_enum.PROTECTION_PALADIN] = true,
        [enums.class_spec_id.spec_enum.GUARDIAN_DRUID] = true,
        [enums.class_spec_id.spec_enum.BLOOD_DEATHKNIGHT] = true,
        [enums.class_spec_id.spec_enum.BREWMASTER_MONK] = true,
        [enums.class_spec_id.spec_enum.VENGEANCE_DEMON_HUNTER] = true,
    }
}
