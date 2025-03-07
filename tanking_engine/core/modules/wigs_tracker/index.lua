-- WigsTracker module for Tanking Engine
-- Provides integration with BigWigs/LittleWigs boss timers

---@type wigs_tracker
local wigs_tracker = require("common/utility/wigs_tracker")

-- Initialize wigs tracker module
TankEngine.modules.wigs_tracker = {
    -- Module settings
    settings = {
        enabled = function() return TankEngine.modules.wigs_tracker.menu.enable_wigs_tracker:get_state() end,
        show_debug_info = function() return TankEngine.modules.wigs_tracker.menu.show_debug_info:get_state() end,
        warning_threshold = function() return TankEngine.modules.wigs_tracker.menu.warning_threshold:get() end,
        danger_threshold = function() return TankEngine.modules.wigs_tracker.menu.danger_threshold:get() end
    },
    
    -- Menu configuration
    menu = {
        tree = TankEngine.menu.tree_node(),
        enable_wigs_tracker = TankEngine.menu.checkbox(true, "wigs_tracker_enable"),
        show_debug_info = TankEngine.menu.checkbox(false, "wigs_tracker_show_debug"),
        warning_threshold = TankEngine.menu.slider_float(3.0, 10.0, 5.0, "wigs_tracker_warning_threshold"),
        danger_threshold = TankEngine.menu.slider_float(0.5, 5.0, 2.0, "wigs_tracker_danger_threshold")
    },
    
    -- Cache for the last update
    last_update_time = 0,
    update_interval = 0.1, -- 100ms update interval
    
    -- Cache for active bars
    active_bars = {},
    
    -- Important ability patterns to watch for
    important_abilities = {
        -- Format: pattern = priority (1-10, higher = more important)
        -- Generic patterns

        -- Rookery: Kyrioss abilities
        ["crashing thunder"] = 8,  -- Party damage, need to avoid
        ["wild lightning"] = 7,    -- Locks players
        ["lightning torrent"] = 9, -- Party damage + CC effect
        ["lightning dash"] = 6,    -- Need to avoid
        
        -- Rookery: Stormguard Gorren abilities
        ["chaotic corruption"] = 7, -- Need to avoid, physical
        ["crush reality"] = 8,      -- Party damage, need to avoid
        ["dark gravity"] = 9,       -- Party damage, need to avoid, CC effect
        
        -- Rookery: Voidstone Monstrosity abilities
        ["void shell"] = 6,           -- Physical buff
        ["entropy"] = 7,              -- Party damage
        ["oblivion wave"] = 8,        -- Follows players, magical debuff
        ["unleash corruption"] = 7,   -- Need to avoid, magic
        ["null upheaval"] = 9,        -- Party damage, need to avoid, tank buster
        ["corruption overload"] = 8,  -- Party damage
        ["stormrider's charge"] = 6,  -- Movement ability
        
        -- Priory of the Sacred Flame: Captain Dailcry abilities
        ["strength in numbers"] = 6,  -- Physical buff
        ["bound by fate"] = 6,        -- Physical buff
        ["pierce armor"] = 7,         -- Physical tank buster, bleed debuff
        ["hurl spear"] = 8,           -- Bleed debuff, locks players
        ["savage mauling"] = 7,       -- Physical, CC effect
        ["battle cry"] = 9,           -- Interruptible, party damage, enrage buff
        
        -- Priory of the Sacred Flame: Baron Braunpyke abilities
        ["hammer of purity"] = 6,     -- Need to avoid
        ["sacrificial pyre"] = 8,     -- Party damage, physical debuff, CC effect
        ["burning light"] = 9,        -- Interruptible, party damage
        ["castigator's shield"] = 8,  -- Party damage, need to avoid, CC effect
        ["vindictive wrath"] = 7,     -- Physical buff, physical tank buster
        
        -- Priory of the Sacred Flame: Prioress Marrpray abilities
        ["holy smite"] = 6,           -- Interruptible
        ["holy flame"] = 7,           -- Need to avoid, magic debuff
        ["purify"] = 5,               -- Utility spell
        ["inner fire"] = 7,           -- Party damage, physical buff
        ["blinding light"] = 8,       -- Party damage, CC effect
        ["embrace the light"] = 9,    -- Interruptible, party damage, physical buff, CC effect
        ["overwhelming power"] = 7,   -- Need to avoid, physical buff
        
        -- Darkflame Cleft: Ol' Waxbeard abilities
        ["kol%-to%-arms"] = 8,        -- Need to avoid, add spawn, CC effect
        ["luring candleflame"] = 6,   -- Physical debuff
        ["rock buster"] = 7,          -- Physical debuff, physical tank buster
        ["reckless charge"] = 8,      -- Need to avoid, follows players, CC effect
        ["underhanded track%-tics"] = 8, -- Party damage, physical debuff, add spawn
        
        -- Darkflame Cleft: Blazikon abilities
        ["blazing storms"] = 8,       -- Party damage
        ["dousing breath"] = 8,       -- Party damage
        ["wicklighter barrage"] = 7,  -- Need to avoid
        ["enkindling inferno"] = 9,   -- Party damage, need to avoid, physical debuff
        ["extinguishing gust"] = 6,   -- Follows players
        ["incite flames"] = 7,        -- Need to avoid
        
        -- Darkflame Cleft: The Candle King abilities
        ["eerie molds"] = 9,          -- Party damage, need to avoid, CC effect
        ["paranoid mind"] = 8,        -- Interruptible, magic debuff, CC effect
        ["darkflame pickaxe"] = 8,    -- Follows players, CC effect
        ["throw darkflame"] = 8,      -- Party damage, need to avoid, physical debuff
        
        -- Darkflame Cleft: The Darkness abilities
        ["flame%-scarred"] = 5,       -- Utility spell
        ["smothering shadows"] = 6,   -- Physical debuff
        ["rising gloom"] = 8,         -- Party damage, physical debuff, CC effect
        ["wax lump"] = 5,             -- Utility spell
        ["shadowblast"] = 7,          -- Need to avoid
        ["umbral slash"] = 7,         -- Locks players
        ["call darkspawn"] = 8,       -- Interruptible, add spawn
        ["drain light"] = 9,          -- Interruptible, party damage
        ["eternal darkness"] = 8,     -- Party damage
        
        -- Cinderbrew Meadery: Brew Master Aldryr abilities
        ["keg smash"] = 7,            -- Need to avoid, physical tank buster, CC effect
        ["throw cinderbrew"] = 6,     -- Need to avoid, physical buff
        ["blazing belch"] = 7,        -- Locks players
        ["happy hour"] = 8,           -- Party damage, physical buff, physical debuff
        ["crawling brawl"] = 7,       -- Need to avoid, CC effect
        
        -- Cinderbrew Meadery: I'pa abilities
        ["spouting stout"] = 8,       -- Party damage, need to avoid, add spawn
        ["fill 'er up"] = 7,          -- Party damage, physical buff
        ["oozing honey"] = 7,         -- Need to avoid, add spawn
        ["bottoms uppercut"] = 7,     -- Physical tank buster, CC effect
        ["burning fermentation"] = 6, -- Magic debuff
        
        -- Cinderbrew Meadery: Benk Buzzbee abilities
        ["snack time"] = 7,           -- Need to avoid, add spawn
        ["shredding sting"] = 6,      -- Bleed debuff
        ["bee%-haw"] = 5,             -- Utility spell
        ["honey marinade"] = 8,       -- Need to avoid, physical buff, magical tank buster
        ["fluttering wing"] = 7,      -- Party damage, CC effect
        
        -- Cinderbrew Meadery: Goldie Baronbottom abilities
        ["cinder%-boom"] = 8,         -- Need to avoid, CC effect
        ["cindering wounds"] = 7,     -- Party damage, physical debuff
        ["cash cannon"] = 8,          -- Follows players, physical tank buster, CC effect
        ["burning ricochet"] = 7,     -- Need to avoid, magic debuff
        ["let it hail"] = 8,          -- Party damage, need to avoid
        
        -- Floodgate: Big M.O.M.M.A abilities
        ["mobilize mechadrones"] = 7, -- Add spawn
        ["maximum distortion"] = 9,   -- Interruptible, party damage, CC effect
        ["doom storm"] = 7,           -- Locks players
        ["electrocrush"] = 7,         -- Physical debuff, magical tank buster
        ["sonic boom"] = 8,           -- Need to avoid, follows players, CC effect
        ["kill%-o%-block barrier"] = 8, -- Party damage, physical buff
        ["jumpstart"] = 7,            -- Party damage
        
        -- Floodgate: Demolition Duo abilities
        ["divided duo"] = 6,          -- Physical buff
        ["quick shot"] = 5,           -- Utility spell
        ["b%.b%.b%.f%.g"] = 8,        -- Need to avoid, CC effect
        ["wallop"] = 8,               -- Need to avoid, physical tank buster, CC effect
        ["big bada boom"] = 9,        -- Party damage, need to avoid, physical debuff
        ["kinetic explosive gel"] = 8, -- Need to avoid, magic debuff, CC effect
        ["barreling charge"] = 7,     -- Follows players, CC effect
        
        -- Floodgate: Swampface abilities
        ["razorchoke vines"] = 8,     -- Party damage, physical debuff, CC effect
        ["mudslide"] = 7,             -- Locks players
        ["awaken the swamp"] = 8,     -- Party damage, need to avoid
        ["sludge claws"] = 7,         -- Physical debuff, mixed tank buster
        
        -- Floodgate: Geezle Gigazap abilities
        ["turbo charge"] = 8,         -- Party damage, locks players, CC effect
        ["dam"] = 7,                  -- Need to avoid
        ["leaping sparks"] = 8,       -- Need to avoid, CC effect
        ["gigazap"] = 7,              -- Need to avoid, physical debuff
        ["thunder punch"] = 8,        -- Physical debuff, mixed tank buster, CC effect
        
        -- Motherload: Coin-Operated Crowd Pummeler abilities
        ["static pulse"] = 8,         -- Party damage, physical debuff, CC effect
        ["throw coins"] = 6,          -- Need to avoid
        ["coin magnet"] = 6,          -- Need to avoid
        ["footbomb launcher"] = 7,    -- Party damage, physical debuff
        ["shocking claw"] = 7,        -- Locks players, CC effect
        
        -- Motherload: Azerokk abilities
        ["fracking totem"] = 5,       -- Utility spell
        ["jagged cut"] = 7,           -- Bleed debuff
        ["tectonic smash"] = 7,       -- Locks players, CC effect
        ["azerite infusion"] = 7,     -- Party damage, physical buff
        ["resonant quake"] = 8,       -- Party damage, need to avoid
        ["call earthrager"] = 7,      -- Add spawn
        
        -- Motherload: Rixxa Fluxflame abilities
        ["searing reagent"] = 7,      -- Magical tank buster
        ["gushing catalyst"] = 6,     -- Need to avoid
        ["azerite catalyst"] = 6,     -- Need to avoid
        ["propellant blast"] = 8,     -- Follows players, CC effect
        
        -- Motherload: Mogul Razdunk abilities
        ["alpha cannon"] = 7,         -- Magical tank buster
        ["b%.o%.o%.m%.b%.a"] = 6,     -- Need to avoid
        ["homing missile"] = 7,       -- Need to avoid, physical debuff
        ["gatling gun"] = 7,          -- Locks players
        ["configuration: drill"] = 8, -- Need to avoid, physical buff, CC effect
        ["drill smash"] = 8,          -- Party damage, need to avoid
        
        -- Workshop: Tussle Tonks abilities
        ["electrical storm"] = 8,     -- Party damage, physical debuff
        ["platinum pummel"] = 7,      -- Need to avoid, physical tank buster
        ["foe flipper"] = 8,          -- Need to avoid, physical debuff, CC effect
        ["ground pound"] = 7,         -- Party damage
        ["b%.4%.t%.t%.l%.3 mine"] = 6, -- Need to avoid
        ["maximum thrust"] = 8,       -- Need to avoid, locks players, CC effect
        ["platinum plating"] = 6,     -- Physical buff
        
        -- Workshop: K.U.J.O abilities
        ["air drop"] = 8,             -- Need to avoid, CC effect
        ["blazing chomp"] = 8,        -- Party damage, magic debuff, magical tank buster
        ["explosive leap"] = 8,       -- Party damage, need to avoid
        ["venting flames"] = 7,       -- Party damage
        
        -- Workshop: Machinist's Garden abilities
        ["inconspicuous plant"] = 7,  -- Need to avoid, add spawn, CC effect
        ["self%-trimming hedge"] = 6, -- Need to avoid
        ["discom%-bomb%-ulator"] = 8, -- Need to avoid, magic debuff, CC effect
        ["\"hidden\" flame cannon"] = 7, -- Need to avoid, physical debuff
        
        -- Workshop: King Mechagon abilities
        ["pulse blast"] = 7,          -- Magical tank buster
        ["recalibrate"] = 8,          -- Need to avoid, locks players, CC effect
        ["mega%-zap"] = 7,            -- Physical debuff, follows players
        ["take off"] = 8,             -- Party damage, need to avoid
        ["protocol: ninety%-nine"] = 7, -- Party damage
        ["magneto%-arm"] = 8,         -- Party damage, CC effect
        
        -- Theatre of Pain: An Afrront of Challengers abilities
        ["final will"] = 6,           -- Physical buff
        ["necromantic bolt"] = 7,     -- Interruptible, magical tank buster
        ["withering touch"] = 7,      -- Party damage, magic debuff
        ["searing death"] = 8,        -- Party damage, need to avoid, physical debuff
        ["decaying breath"] = 7,      -- Locks players
        ["noxious spores"] = 6,       -- Need to avoid
        ["mortal strike"] = 7,        -- Physical debuff, physical tank buster
        ["mighty smash"] = 7,         -- Party damage, physical debuff
        
        -- Theatre of Pain: Xav the Unfallen abilities
        ["brutal combo"] = 7,         -- Physical tank buster
        ["oppressive banner"] = 8,    -- Physical debuff, add spawn, CC effect
        ["might of maldraxxus"] = 9,  -- Party damage, need to avoid, locks players, CC effect
        ["blood and glory"] = 7,      -- Physical buff, CC effect
        
        -- Theatre of Pain: Kul'tharok abilities
        ["necrotic bolt"] = 6,        -- Interruptible
        ["well of darkness"] = 7,     -- Need to avoid, physical debuff
        ["death spiral"] = 7,         -- Need to avoid
        ["necrotic eruption"] = 8,    -- Follows players, magical tank buster
        ["draw soul"] = 9,            -- Party damage, physical debuff, add spawn, CC effect
        
        -- Theatre of Pain: Gorechomp abilities
        ["hateful strike"] = 7,       -- Physical tank buster
        ["meat hooks"] = 8,           -- Need to avoid, bleed debuff, add spawn, CC effect
        ["leaping thrash"] = 7,       -- Need to avoid
        ["coagulating ooze"] = 6,     -- Need to avoid
        ["tenderizing smash"] = 8,    -- Need to avoid, CC effect
        
        -- Theatre of Pain: Mordretha, the Endless Empress abilities
        ["reaping scythe"] = 7,       -- Mixed tank buster
        ["dark devastation"] = 8,     -- Locks players, CC effect
        ["grasping rift"] = 9,        -- Party damage, need to avoid, curse debuff, CC effect
        ["manifest death"] = 9,       -- Party damage, need to avoid, physical debuff, add spawn, CC effect
        ["death bolt"] = 6,           -- Interruptible
        ["echoes of carnage"] = 9     -- Party damage, need to avoid, CC effect
    }
}

-- Get all active bars with remaining time
function TankEngine.modules.wigs_tracker.get_active_bars()
    local bars = wigs_tracker:get_all()
    local current_time = core.time()
    local result = {}
    
    for _, bar in ipairs(bars) do
        local remaining = bar.expire_time - current_time
        if remaining > 0 then
            table.insert(result, {
                key = bar.key,
                text = bar.text,
                duration = bar.duration,
                created_at = bar.created_at,
                expire_time = bar.expire_time,
                remaining = remaining
            })
        end
    end
    
    return result
end

-- Get important bars that are about to happen
function TankEngine.modules.wigs_tracker.get_important_bars(threshold)
    local bars = TankEngine.modules.wigs_tracker.get_active_bars()
    local important_bars = {}
    
    for _, bar in ipairs(bars) do
        if bar.remaining <= threshold then
            -- Check if this bar matches any important ability patterns
            local importance = 0
            for pattern, priority in pairs(TankEngine.modules.wigs_tracker.important_abilities) do
                if string.match(string.lower(bar.text), pattern) then
                    importance = priority
                    break
                end
            end
            
            if importance > 0 then
                bar.importance = importance
                table.insert(important_bars, bar)
            end
        end
    end
    
    -- Sort by importance (highest first) and then by remaining time (lowest first)
    table.sort(important_bars, function(a, b)
        if a.importance == b.importance then
            return a.remaining < b.remaining
        end
        return a.importance > b.importance
    end)
    
    return important_bars
end

-- Check if any dangerous abilities are coming soon
function TankEngine.modules.wigs_tracker.should_use_defensive()
    if not TankEngine.modules.wigs_tracker.settings.enabled() then
        return false, nil
    end
    
    local danger_threshold = TankEngine.modules.wigs_tracker.settings.danger_threshold()
    local important_bars = TankEngine.modules.wigs_tracker.get_important_bars(danger_threshold)
    
    -- If we have any high importance abilities (7+) coming soon, suggest defensive
    for _, bar in ipairs(important_bars) do
        if bar.importance >= 7 then
            return true, bar
        end
    end
    
    return false, nil
end

-- Load module files
require("core/modules/wigs_tracker/menu")
require("core/modules/wigs_tracker/update")
require("core/modules/wigs_tracker/mitigation_integration")

-- Initialize module
function TankEngine.modules.wigs_tracker.initialize()
    -- Integrate with mitigation module
    TankEngine.modules.wigs_tracker.integrate_with_mitigation()
    
    -- Adjust priorities based on tank spec
    TankEngine.modules.wigs_tracker.adjust_priorities_for_spec()
    
    -- Log initialization
    core.log("[WigsTracker] Module initialized")
end

-- Adjust ability priorities based on current tank spec
function TankEngine.modules.wigs_tracker.adjust_priorities_for_spec()
    -- Get player class and spec
    local player_class = core.object_manager.get_local_player():get_class()
    
    -- Adjust priorities based on class/spec
    if player_class == "WARRIOR" then -- Protection Warrior
        -- Warriors have strong physical mitigation but weaker magical
        -- Voidstone Monstrosity
        TankEngine.modules.wigs_tracker.important_abilities["void shell"] = 5 -- Lower priority (physical)
        TankEngine.modules.wigs_tracker.important_abilities["oblivion wave"] = 9 -- Higher priority (magical)
        TankEngine.modules.wigs_tracker.important_abilities["unleash corruption"] = 8 -- Higher priority (magical)
        
        -- Captain Dailcry - Warriors handle physical well
        TankEngine.modules.wigs_tracker.important_abilities["strength in numbers"] = 5
        TankEngine.modules.wigs_tracker.important_abilities["bound by fate"] = 5
        TankEngine.modules.wigs_tracker.important_abilities["pierce armor"] = 6 -- Lower priority due to strong armor
        
        -- Prioress Murrpray - Magic is more dangerous
        TankEngine.modules.wigs_tracker.important_abilities["holy flame"] = 8 -- Higher priority (magical)
        
        -- The Candle King - Magic is more dangerous
        TankEngine.modules.wigs_tracker.important_abilities["paranoid mind"] = 9 -- Higher priority (magical)
        
        -- The Darkness - Magic is more dangerous
        TankEngine.modules.wigs_tracker.important_abilities["drain light"] = 10 -- Higher priority (magical)
        
        -- I'pa - Magic is more dangerous
        TankEngine.modules.wigs_tracker.important_abilities["burning fermentation"] = 7 -- Higher priority (magical)
        
        -- Benk Buzzbee - Magical damage is more dangerous
        TankEngine.modules.wigs_tracker.important_abilities["honey marinade"] = 9 -- Higher priority (magical component)
        
        -- Goldie Baronbottom - Magic is more dangerous
        TankEngine.modules.wigs_tracker.important_abilities["burning ricochet"] = 8 -- Higher priority (magical)
        
        -- Big M.O.M.M.A - Magic is more dangerous
        TankEngine.modules.wigs_tracker.important_abilities["electrocrush"] = 8 -- Higher priority (magical component)
        
        -- Demolition Duo - Magic is more dangerous
        TankEngine.modules.wigs_tracker.important_abilities["kinetic explosive gel"] = 9 -- Higher priority (magical)
        
        -- Swampface - Mixed damage is more dangerous
        TankEngine.modules.wigs_tracker.important_abilities["sludge claws"] = 8 -- Higher priority (mixed)
        
        -- Geezle Gigazap - Mixed damage is more dangerous
        TankEngine.modules.wigs_tracker.important_abilities["thunder punch"] = 9 -- Higher priority (mixed)
        
        -- Coin-Operated Crowd Pummeler - Magic is more dangerous
        TankEngine.modules.wigs_tracker.important_abilities["static pulse"] = 9 -- Higher priority (magical component)
        
        -- Rixxa Fluxflame - Magic is more dangerous
        TankEngine.modules.wigs_tracker.important_abilities["searing reagent"] = 8 -- Higher priority (magical)
        
        -- Mogul Razdunk - Magic is more dangerous
        TankEngine.modules.wigs_tracker.important_abilities["alpha cannon"] = 8 -- Higher priority (magical)
        
        -- K.U.J.O - Magic is more dangerous
        TankEngine.modules.wigs_tracker.important_abilities["blazing chomp"] = 9 -- Higher priority (magical)
        
        -- Machinist's Garden - Magic is more dangerous
        TankEngine.modules.wigs_tracker.important_abilities["discom-bomb-ulator"] = 9 -- Higher priority (magical)
        
        -- King Mechagon - Magic is more dangerous
        TankEngine.modules.wigs_tracker.important_abilities["pulse blast"] = 8 -- Higher priority (magical)
        
        -- An Affront of Challengers - Magic is more dangerous
        TankEngine.modules.wigs_tracker.important_abilities["necromantic bolt"] = 8 -- Higher priority (magical)
        TankEngine.modules.wigs_tracker.important_abilities["withering touch"] = 8 -- Higher priority (magical)
        
        -- Kul'tharok - Magic is more dangerous
        TankEngine.modules.wigs_tracker.important_abilities["necrotic eruption"] = 9 -- Higher priority (magical)
        
        -- Mordretha - Mixed damage is more dangerous
        TankEngine.modules.wigs_tracker.important_abilities["reaping scythe"] = 8 -- Higher priority (mixed)
        
    elseif player_class == "PALADIN" then -- Protection Paladin
        -- Paladins have good magical mitigation
        -- Voidstone Monstrosity
        TankEngine.modules.wigs_tracker.important_abilities["oblivion wave"] = 7 -- Lower priority (magical)
        TankEngine.modules.wigs_tracker.important_abilities["unleash corruption"] = 6 -- Lower priority (magical)
        
        -- Prioress Murrpray - Magic is less dangerous
        TankEngine.modules.wigs_tracker.important_abilities["holy flame"] = 6 -- Lower priority (magical)
        TankEngine.modules.wigs_tracker.important_abilities["embrace the light"] = 8 -- Lower priority (magical component)
        
        -- The Candle King - Magic is less dangerous
        TankEngine.modules.wigs_tracker.important_abilities["paranoid mind"] = 7 -- Lower priority (magical)
        
        -- The Darkness - Magic is less dangerous
        TankEngine.modules.wigs_tracker.important_abilities["drain light"] = 8 -- Lower priority (magical)
        
        -- I'pa - Magic is less dangerous
        TankEngine.modules.wigs_tracker.important_abilities["burning fermentation"] = 5 -- Lower priority (magical)
        
        -- Benk Buzzbee - Magical damage is less dangerous
        TankEngine.modules.wigs_tracker.important_abilities["honey marinade"] = 7 -- Lower priority (magical component)
        
        -- Goldie Baronbottom - Magic is less dangerous
        TankEngine.modules.wigs_tracker.important_abilities["burning ricochet"] = 6 -- Lower priority (magical)
        
        -- Big M.O.M.M.A - Magic is less dangerous
        TankEngine.modules.wigs_tracker.important_abilities["electrocrush"] = 6 -- Lower priority (magical component)
        
        -- Demolition Duo - Magic is less dangerous
        TankEngine.modules.wigs_tracker.important_abilities["kinetic explosive gel"] = 7 -- Lower priority (magical)
        
        -- Swampface - Mixed damage is less dangerous for magical component
        TankEngine.modules.wigs_tracker.important_abilities["sludge claws"] = 6 -- Lower priority (mixed)
        
        -- Geezle Gigazap - Mixed damage is less dangerous for magical component
        TankEngine.modules.wigs_tracker.important_abilities["thunder punch"] = 7 -- Lower priority (mixed)
        
        -- Mogul Razdunk - Magic is less dangerous
        TankEngine.modules.wigs_tracker.important_abilities["alpha cannon"] = 6 -- Lower priority (magical)
        
        -- K.U.J.O - Magic is less dangerous
        TankEngine.modules.wigs_tracker.important_abilities["blazing chomp"] = 7 -- Lower priority (magical)
        
        -- Machinist's Garden - Magic is less dangerous
        TankEngine.modules.wigs_tracker.important_abilities["discom-bomb-ulator"] = 7 -- Lower priority (magical)
        
        -- King Mechagon - Magic is less dangerous
        TankEngine.modules.wigs_tracker.important_abilities["pulse blast"] = 6 -- Lower priority (magical)
        
        -- An Affront of Challengers - Magic is less dangerous
        TankEngine.modules.wigs_tracker.important_abilities["necromantic bolt"] = 6 -- Lower priority (magical)
        TankEngine.modules.wigs_tracker.important_abilities["withering touch"] = 6 -- Lower priority (magical)
        
        -- Kul'tharok - Magic is less dangerous
        TankEngine.modules.wigs_tracker.important_abilities["necrotic eruption"] = 7 -- Lower priority (magical)
        
        -- Mordretha - Mixed damage is less dangerous for magical component
        TankEngine.modules.wigs_tracker.important_abilities["reaping scythe"] = 6 -- Lower priority (mixed)
        
    elseif player_class == "MONK" then -- Brewmaster Monk
        -- Monks have stagger for all damage types
        -- Monks handle bleeds well with stagger
        TankEngine.modules.wigs_tracker.important_abilities["pierce armor"] = 6
        TankEngine.modules.wigs_tracker.important_abilities["hurl spear"] = 7
        
        -- Ol' Waxbeard - Physical damage is less dangerous with stagger
        TankEngine.modules.wigs_tracker.important_abilities["rock buster"] = 6
        
        -- Blazikon - Stagger helps with burst damage
        TankEngine.modules.wigs_tracker.important_abilities["enkindling inferno"] = 8
        
        -- Brew Master Aldryr - Monks handle physical damage well with stagger
        TankEngine.modules.wigs_tracker.important_abilities["keg smash"] = 6
        
        -- Benk Buzzbee - Monks handle bleeds well with stagger
        TankEngine.modules.wigs_tracker.important_abilities["shredding sting"] = 5
        
        -- Demolition Duo - Monks handle physical damage well with stagger
        TankEngine.modules.wigs_tracker.important_abilities["wallop"] = 7
        
        -- Swampface - Monks handle mixed damage well with stagger
        TankEngine.modules.wigs_tracker.important_abilities["sludge claws"] = 6
        
        -- Geezle Gigazap - Monks handle mixed damage well with stagger
        TankEngine.modules.wigs_tracker.important_abilities["thunder punch"] = 7
        
        -- Coin-Operated Crowd Pummeler - Monks handle physical damage well with stagger
        TankEngine.modules.wigs_tracker.important_abilities["static pulse"] = 7
        TankEngine.modules.wigs_tracker.important_abilities["footbomb launcher"] = 6
        
        -- Azerokk - Monks handle bleeds well with stagger
        TankEngine.modules.wigs_tracker.important_abilities["jagged cut"] = 6
        
        -- Mogul Razdunk - Monks handle physical damage well with stagger
        TankEngine.modules.wigs_tracker.important_abilities["homing missile"] = 6
        TankEngine.modules.wigs_tracker.important_abilities["configuration: drill"] = 7
        
        -- Tussle Tonks - Monks handle physical damage well with stagger
        TankEngine.modules.wigs_tracker.important_abilities["electrical storm"] = 7
        TankEngine.modules.wigs_tracker.important_abilities["platinum pummel"] = 6
        TankEngine.modules.wigs_tracker.important_abilities["foe flipper"] = 7
        
        -- King Mechagon - Monks handle physical damage well with stagger
        TankEngine.modules.wigs_tracker.important_abilities["mega-zap"] = 6
        
        -- An Affront of Challengers - Monks handle physical damage well with stagger
        TankEngine.modules.wigs_tracker.important_abilities["mortal strike"] = 6
        TankEngine.modules.wigs_tracker.important_abilities["mighty smash"] = 6
        
        -- Xav the Unfallen - Monks handle physical damage well with stagger
        TankEngine.modules.wigs_tracker.important_abilities["brutal combo"] = 6
        
        -- Gorechomp - Monks handle bleeds well with stagger
        TankEngine.modules.wigs_tracker.important_abilities["meat hooks"] = 7
        TankEngine.modules.wigs_tracker.important_abilities["hateful strike"] = 6
        
        -- Mordretha - Monks handle mixed damage well with stagger
        TankEngine.modules.wigs_tracker.important_abilities["reaping scythe"] = 6
        
    elseif player_class == "DRUID" then -- Guardian Druid
        -- Druids have high health pools but less active mitigation
        -- Druids handle bleeds well with high health
        TankEngine.modules.wigs_tracker.important_abilities["pierce armor"] = 6
        TankEngine.modules.wigs_tracker.important_abilities["hurl spear"] = 7
        
        -- Baron Braunpyke - Physical damage is more dangerous
        TankEngine.modules.wigs_tracker.important_abilities["vindictive wrath"] = 8
        
        -- The Darkness - Physical damage is more dangerous
        TankEngine.modules.wigs_tracker.important_abilities["smothering shadows"] = 7
        
        -- Benk Buzzbee - Druids handle bleeds well with high health
        TankEngine.modules.wigs_tracker.important_abilities["shredding sting"] = 5
        
        -- Goldie Baronbottom - Physical damage is more dangerous
        TankEngine.modules.wigs_tracker.important_abilities["cash cannon"] = 9
        
        -- Demolition Duo - Physical damage is more dangerous
        TankEngine.modules.wigs_tracker.important_abilities["big bada boom"] = 10
        
        -- Swampface - Physical component of mixed damage is more dangerous
        TankEngine.modules.wigs_tracker.important_abilities["sludge claws"] = 8
        
        -- Geezle Gigazap - Physical component of mixed damage is more dangerous
        TankEngine.modules.wigs_tracker.important_abilities["thunder punch"] = 9
        
        -- Mogul Razdunk - Physical damage is more dangerous
        TankEngine.modules.wigs_tracker.important_abilities["homing missile"] = 8
        TankEngine.modules.wigs_tracker.important_abilities["configuration: drill"] = 9
        
        -- Tussle Tonks - Physical damage is more dangerous
        TankEngine.modules.wigs_tracker.important_abilities["electrical storm"] = 9
        TankEngine.modules.wigs_tracker.important_abilities["platinum pummel"] = 8
        TankEngine.modules.wigs_tracker.important_abilities["foe flipper"] = 9
        
        -- Machinist's Garden - Physical damage is more dangerous
        TankEngine.modules.wigs_tracker.important_abilities["\"hidden\" flame cannon"] = 8
        
        -- King Mechagon - Physical damage is more dangerous
        TankEngine.modules.wigs_tracker.important_abilities["mega-zap"] = 8
        
        -- An Affront of Challengers - Physical damage is more dangerous
        TankEngine.modules.wigs_tracker.important_abilities["mortal strike"] = 8
        TankEngine.modules.wigs_tracker.important_abilities["mighty smash"] = 8
        TankEngine.modules.wigs_tracker.important_abilities["searing death"] = 9
        
        -- Xav the Unfallen - Physical damage is more dangerous
        TankEngine.modules.wigs_tracker.important_abilities["brutal combo"] = 8
        TankEngine.modules.wigs_tracker.important_abilities["oppressive banner"] = 9
        
        -- Gorechomp - Physical damage is more dangerous
        TankEngine.modules.wigs_tracker.important_abilities["meat hooks"] = 9
        TankEngine.modules.wigs_tracker.important_abilities["hateful strike"] = 8
        
        -- Mordretha - Physical component of mixed damage is more dangerous
        TankEngine.modules.wigs_tracker.important_abilities["reaping scythe"] = 8
        TankEngine.modules.wigs_tracker.important_abilities["manifest death"] = 10
        
    elseif player_class == "DEMONHUNTER" then -- Vengeance Demon Hunter
        -- Demon Hunters have self-healing but can be spiky
        -- Demon Hunters handle magic well
        TankEngine.modules.wigs_tracker.important_abilities["holy flame"] = 6
        TankEngine.modules.wigs_tracker.important_abilities["oblivion wave"] = 7
        
        -- Baron Braunpyke - Physical damage is more dangerous
        TankEngine.modules.wigs_tracker.important_abilities["vindictive wrath"] = 8
        
        -- Blazikon - Demon Hunters can handle fire damage well
        TankEngine.modules.wigs_tracker.important_abilities["blazing storms"] = 7
        TankEngine.modules.wigs_tracker.important_abilities["enkindling inferno"] = 8
        
        -- The Candle King - Demon Hunters handle magic well
        TankEngine.modules.wigs_tracker.important_abilities["paranoid mind"] = 7
        
        -- Brew Master Aldryr - Demon Hunters handle fire damage well
        TankEngine.modules.wigs_tracker.important_abilities["throw cinderbrew"] = 5
        TankEngine.modules.wigs_tracker.important_abilities["blazing belch"] = 6
        
        -- I'pa - Demon Hunters handle magic well
        TankEngine.modules.wigs_tracker.important_abilities["burning fermentation"] = 5
        
        -- Goldie Baronbottom - Demon Hunters handle fire damage well
        TankEngine.modules.wigs_tracker.important_abilities["burning ricochet"] = 6
        TankEngine.modules.wigs_tracker.important_abilities["cinder-boom"] = 7
        
        -- Big M.O.M.M.A - Demon Hunters handle magic well
        TankEngine.modules.wigs_tracker.important_abilities["electrocrush"] = 6
        
        -- Demolition Duo - Demon Hunters handle magic well
        TankEngine.modules.wigs_tracker.important_abilities["kinetic explosive gel"] = 7
        
        -- Geezle Gigazap - Demon Hunters handle electrical damage well
        TankEngine.modules.wigs_tracker.important_abilities["gigazap"] = 6
        
        -- Coin-Operated Crowd Pummeler - Demon Hunters handle electrical damage well
        TankEngine.modules.wigs_tracker.important_abilities["static pulse"] = 7
        TankEngine.modules.wigs_tracker.important_abilities["shocking claw"] = 6
        
        -- Rixxa Fluxflame - Demon Hunters handle magic well
        TankEngine.modules.wigs_tracker.important_abilities["searing reagent"] = 6
        
        -- Mogul Razdunk - Demon Hunters handle magic well
        TankEngine.modules.wigs_tracker.important_abilities["alpha cannon"] = 6
        
        -- K.U.J.O - Demon Hunters handle magic well
        TankEngine.modules.wigs_tracker.important_abilities["blazing chomp"] = 7
        
        -- Machinist's Garden - Demon Hunters handle magic well
        TankEngine.modules.wigs_tracker.important_abilities["discom-bomb-ulator"] = 7
        
        -- King Mechagon - Demon Hunters handle magic well
        TankEngine.modules.wigs_tracker.important_abilities["pulse blast"] = 6
        
        -- An Affront of Challengers - Demon Hunters handle magic well
        TankEngine.modules.wigs_tracker.important_abilities["necromantic bolt"] = 6
        TankEngine.modules.wigs_tracker.important_abilities["withering touch"] = 6
        
        -- Kul'tharok - Demon Hunters handle magic well
        TankEngine.modules.wigs_tracker.important_abilities["necrotic eruption"] = 7
        
    elseif player_class == "DEATHKNIGHT" then -- Blood Death Knight
        -- Death Knights have strong self-healing but can be spiky
        -- Death Knights handle bleeds well with self-healing
        TankEngine.modules.wigs_tracker.important_abilities["pierce armor"] = 6
        TankEngine.modules.wigs_tracker.important_abilities["hurl spear"] = 7
        
        -- Baron Braunpyke - Physical damage is more dangerous when not prepared
        TankEngine.modules.wigs_tracker.important_abilities["vindictive wrath"] = 8
        
        -- Ol' Waxbeard - Death Knights handle physical damage well with self-healing
        TankEngine.modules.wigs_tracker.important_abilities["rock buster"] = 6
        
        -- The Darkness - Death Knights have good magic mitigation
        TankEngine.modules.wigs_tracker.important_abilities["drain light"] = 8
        
        -- Benk Buzzbee - Death Knights handle bleeds well with self-healing
        TankEngine.modules.wigs_tracker.important_abilities["shredding sting"] = 5
        
        -- Goldie Baronbottom - Death Knights have good magic mitigation
        TankEngine.modules.wigs_tracker.important_abilities["burning ricochet"] = 6
        
        -- Swampface - Death Knights handle physical damage well with self-healing
        TankEngine.modules.wigs_tracker.important_abilities["razorchoke vines"] = 7
        
        -- Geezle Gigazap - Death Knights have good magic mitigation
        TankEngine.modules.wigs_tracker.important_abilities["gigazap"] = 6
        
        -- Azerokk - Death Knights handle bleeds well with self-healing
        TankEngine.modules.wigs_tracker.important_abilities["jagged cut"] = 6
        
        -- Rixxa Fluxflame - Death Knights have good magic mitigation
        TankEngine.modules.wigs_tracker.important_abilities["searing reagent"] = 6
        
        -- Mogul Razdunk - Death Knights have good magic mitigation
        TankEngine.modules.wigs_tracker.important_abilities["alpha cannon"] = 6
        
        -- K.U.J.O - Death Knights have good magic mitigation
        TankEngine.modules.wigs_tracker.important_abilities["blazing chomp"] = 7
        
        -- Machinist's Garden - Death Knights have good magic mitigation
        TankEngine.modules.wigs_tracker.important_abilities["discom-bomb-ulator"] = 7
        
        -- King Mechagon - Death Knights have good magic mitigation
        TankEngine.modules.wigs_tracker.important_abilities["pulse blast"] = 6
        
        -- An Affront of Challengers - Death Knights have good magic mitigation
        TankEngine.modules.wigs_tracker.important_abilities["necromantic bolt"] = 6
        TankEngine.modules.wigs_tracker.important_abilities["withering touch"] = 6
        
        -- Kul'tharok - Death Knights have good magic mitigation
        TankEngine.modules.wigs_tracker.important_abilities["necrotic eruption"] = 7
        
        -- Gorechomp - Death Knights handle bleeds well with self-healing
        TankEngine.modules.wigs_tracker.important_abilities["meat hooks"] = 7
    end
    
    -- Log that priorities were adjusted
    core.log("[WigsTracker] Adjusted ability priorities for " .. player_class)
end

-- Export module interface
return {
    on_update = TankEngine.modules.wigs_tracker.on_update,
    on_render = TankEngine.modules.wigs_tracker.on_render,
    on_render_menu = TankEngine.modules.wigs_tracker.menu.on_render_menu,
    initialize = TankEngine.modules.wigs_tracker.initialize
} 