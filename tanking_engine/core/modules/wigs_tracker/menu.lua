local tag = "wigs_tracker_"
local name = "BigWigs Tracker"

---@type color
local color = require("shared/color")

---@type on_render_menu
function TankEngine.modules.wigs_tracker.menu.on_render_menu()
    -- Check if tree exists before trying to render
    if not TankEngine.modules.wigs_tracker.menu.tree then
        core.log_error("WigsTracker menu tree is nil")
        return
    end

    TankEngine.modules.wigs_tracker.menu.tree:render(name, function()
        -- Main enable/disable toggle
        if TankEngine.modules.wigs_tracker.menu.enable_wigs_tracker then
            TankEngine.modules.wigs_tracker.menu.enable_wigs_tracker:render("Enable BigWigs Tracking", 
                "Track boss ability timers from BigWigs/LittleWigs")
        end
        
        -- Only show additional options when enabled
        if not TankEngine.modules.wigs_tracker.settings.enabled() then return end
        
        -- Debug info toggle
        if TankEngine.modules.wigs_tracker.menu.show_debug_info then
            TankEngine.modules.wigs_tracker.menu.show_debug_info:render("Show Debug Information\n", 
                "Display tracked abilities on screen")
        end
        
        -- Threshold settings
        if TankEngine.modules.wigs_tracker.menu.warning_threshold then
            TankEngine.modules.wigs_tracker.menu.warning_threshold:render("Warning Threshold\n",
                "Track abilities coming within this many seconds")
        end
        
        if TankEngine.modules.wigs_tracker.menu.danger_threshold then
            TankEngine.modules.wigs_tracker.menu.danger_threshold:render("Danger Threshold\n",
                "Consider using defensive cooldowns when important abilities are within this threshold")
        end
        
        -- Show currently tracked bars if debug is enabled
        if TankEngine.modules.wigs_tracker.settings.show_debug_info() then
            local active_bars = TankEngine.modules.wigs_tracker.active_bars
            
            if active_bars and #active_bars > 0 then
                core.menu.text_input("Currently tracking " .. #active_bars .. " bars")
                
                local warning_threshold = TankEngine.modules.wigs_tracker.settings.warning_threshold()
                local important_bars = TankEngine.modules.wigs_tracker.get_important_bars(warning_threshold)
                
                if important_bars and #important_bars > 0 then
                    core.menu.text_input("Important abilities coming soon:")
                    for _, bar in ipairs(important_bars) do
                        -- Skip bars with missing fields
                        if not bar.text or not bar.remaining or not bar.importance then
                            goto continue
                        end
                        
                        core.menu.text_input(string.format("  %s: %.1fs (Priority: %d)", 
                            bar.text, bar.remaining, bar.importance))
                            
                        ::continue::
                    end
                else
                    core.menu.text_input("No important abilities coming soon")
                end
            else
                core.menu.text_input("No active BigWigs bars detected")
            end
        end
        
        -- Advanced settings tree
        local advanced_tree = TankEngine.menu.tree_node()
        if advanced_tree then
            advanced_tree:render("Advanced Settings", function()
                -- Show important ability patterns
                core.menu.text_input("Important ability patterns:")
                for pattern, priority in pairs(TankEngine.modules.wigs_tracker.important_abilities) do
                    core.menu.text_input(string.format("  %s: Priority %d", pattern, priority))
                end
                
                -- Boss-specific settings
                local boss_tree = TankEngine.menu.tree_node()
                if boss_tree then
                    boss_tree:render("Boss-Specific Settings", function()
                        -- Group bosses by dungeon
                        
                        -- Rookery
                        local rookery_tree = TankEngine.menu.tree_node()
                        if rookery_tree then
                            rookery_tree:render("Rookery", function()
                                -- Kyrioss
                                local kyrioss_tree = TankEngine.menu.tree_node()
                                if kyrioss_tree then
                                    kyrioss_tree:render("Kyrioss", function()
                                        core.menu.text_input("Crashing Thunder: Party damage, need to avoid")
                                        core.menu.text_input("Wild Lightning: Locks players")
                                        core.menu.text_input("Lightning Torrent: Party damage + CC effect")
                                        core.menu.text_input("Lightning Dash: Need to avoid")
                                    end)
                                end
                                
                                -- Stormguard Gorren
                                local gorren_tree = TankEngine.menu.tree_node()
                                if gorren_tree then
                                    gorren_tree:render("Stormguard Gorren", function()
                                        core.menu.text_input("Chaotic Corruption: Need to avoid, physical")
                                        core.menu.text_input("Crush Reality: Party damage, need to avoid")
                                        core.menu.text_input("Dark Gravity: Party damage, need to avoid, CC effect")
                                    end)
                                end
                                
                                -- Voidstone Monstrosity
                                local voidstone_tree = TankEngine.menu.tree_node()
                                if voidstone_tree then
                                    voidstone_tree:render("Voidstone Monstrosity", function()
                                        core.menu.text_input("Void Shell: Physical buff")
                                        core.menu.text_input("Entropy: Party damage")
                                        core.menu.text_input("Oblivion Wave: Follows players, magical debuff")
                                        core.menu.text_input("Unleash Corruption: Need to avoid, magic")
                                        core.menu.text_input("Null Upheaval: Party damage, need to avoid, tank buster")
                                        core.menu.text_input("Corruption Overload: Party damage")
                                        core.menu.text_input("Stormrider's Charge: Movement ability")
                                    end)
                                end
                            end)
                        end
                        
                        -- Priory of the Sacred Flame
                        local priory_tree = TankEngine.menu.tree_node()
                        if priory_tree then
                            priory_tree:render("Priory of the Sacred Flame", function()
                                -- Captain Dailcry
                                local dailcry_tree = TankEngine.menu.tree_node()
                                if dailcry_tree then
                                    dailcry_tree:render("Captain Dailcry", function()
                                        core.menu.text_input("Strength in Numbers: Physical buff")
                                        core.menu.text_input("Bound by Fate: Physical buff")
                                        core.menu.text_input("Pierce Armor: Physical tank buster, bleed debuff")
                                        core.menu.text_input("Hurl Spear: Bleed debuff, locks players")
                                        core.menu.text_input("Savage Mauling: Physical, CC effect")
                                        core.menu.text_input("Battle Cry: Interruptible, party damage, enrage buff")
                                    end)
                                end
                                
                                -- Baron Braunpyke
                                local braunpyke_tree = TankEngine.menu.tree_node()
                                if braunpyke_tree then
                                    braunpyke_tree:render("Baron Braunpyke", function()
                                        core.menu.text_input("Hammer of Purity: Need to avoid")
                                        core.menu.text_input("Sacrificial Pyre: Party damage, physical debuff, CC effect")
                                        core.menu.text_input("Burning Light: Interruptible, party damage")
                                        core.menu.text_input("Castigator's Shield: Party damage, need to avoid, CC effect")
                                        core.menu.text_input("Vindictive Wrath: Physical buff, physical tank buster")
                                    end)
                                end
                                
                                -- Prioress Marrpray
                                local marrpray_tree = TankEngine.menu.tree_node()
                                if marrpray_tree then
                                    marrpray_tree:render("Prioress Marrpray", function()
                                        core.menu.text_input("Holy Smite: Interruptible")
                                        core.menu.text_input("Holy Flame: Need to avoid, magic debuff")
                                        core.menu.text_input("Purify: Utility spell")
                                        core.menu.text_input("Inner Fire: Party damage, physical buff")
                                        core.menu.text_input("Blinding Light: Party damage, CC effect")
                                        core.menu.text_input("Embrace the Light: Interruptible, party damage, physical buff, CC effect")
                                        core.menu.text_input("Overwhelming Power: Need to avoid, physical buff")
                                    end)
                                end
                            end)
                        end
                        
                        -- Darkflame Cleft
                        local darkflame_tree = TankEngine.menu.tree_node()
                        if darkflame_tree then
                            darkflame_tree:render("Darkflame Cleft", function()
                                -- Ol' Waxbeard
                                local waxbeard_tree = TankEngine.menu.tree_node()
                                if waxbeard_tree then
                                    waxbeard_tree:render("Ol' Waxbeard", function()
                                        core.menu.text_input("\"Kol\"-to-Arms: Need to avoid, add spawn, CC effect")
                                        core.menu.text_input("Luring Candleflame: Physical debuff")
                                        core.menu.text_input("Rock Buster: Physical debuff, physical tank buster")
                                        core.menu.text_input("Reckless Charge: Need to avoid, follows players, CC effect")
                                        core.menu.text_input("Underhanded Track-tics: Party damage, physical debuff, add spawn")
                                    end)
                                end
                                
                                -- Blazikon
                                local blazikon_tree = TankEngine.menu.tree_node()
                                if blazikon_tree then
                                    blazikon_tree:render("Blazikon", function()
                                        core.menu.text_input("Blazing Storms: Party damage")
                                        core.menu.text_input("Dousing Breath: Party damage")
                                        core.menu.text_input("Wicklighter Barrage: Need to avoid")
                                        core.menu.text_input("Enkindling Inferno: Party damage, need to avoid, physical debuff")
                                        core.menu.text_input("Extinguishing Gust: Follows players")
                                        core.menu.text_input("Incite Flames: Need to avoid")
                                    end)
                                end
                                
                                -- The Candle King
                                local candleking_tree = TankEngine.menu.tree_node()
                                if candleking_tree then
                                    candleking_tree:render("The Candle King", function()
                                        core.menu.text_input("Eerie Molds: Party damage, need to avoid, CC effect")
                                        core.menu.text_input("Paranoid Mind: Interruptible, magic debuff, CC effect")
                                        core.menu.text_input("Darkflame Pickaxe: Follows players, CC effect")
                                        core.menu.text_input("Throw Darkflame: Party damage, need to avoid, physical debuff")
                                    end)
                                end
                                
                                -- The Darkness
                                local darkness_tree = TankEngine.menu.tree_node()
                                if darkness_tree then
                                    darkness_tree:render("The Darkness", function()
                                        core.menu.text_input("Flame-Scarred: Utility spell")
                                        core.menu.text_input("Smothering Shadows: Physical debuff")
                                        core.menu.text_input("Rising Gloom: Party damage, physical debuff, CC effect")
                                        core.menu.text_input("Wax Lump: Utility spell")
                                        core.menu.text_input("Shadowblast: Need to avoid")
                                        core.menu.text_input("Umbral Slash: Locks players")
                                        core.menu.text_input("Call Darkspawn: Interruptible, add spawn")
                                        core.menu.text_input("Drain Light: Interruptible, party damage")
                                        core.menu.text_input("Eternal Darkness: Party damage")
                                    end)
                                end
                            end)
                        end
                        
                        -- Cinderbrew Meadery
                        local cinderbrew_tree = TankEngine.menu.tree_node()
                        if cinderbrew_tree then
                            cinderbrew_tree:render("Cinderbrew Meadery", function()
                                -- Brew Master Aldryr
                                local aldryr_tree = TankEngine.menu.tree_node()
                                if aldryr_tree then
                                    aldryr_tree:render("Brew Master Aldryr", function()
                                        core.menu.text_input("Keg Smash: Need to avoid, physical tank buster, CC effect")
                                        core.menu.text_input("Throw Cinderbrew: Need to avoid, physical buff")
                                        core.menu.text_input("Blazing Belch: Locks players")
                                        core.menu.text_input("Happy Hour: Party damage, physical buff, physical debuff")
                                        core.menu.text_input("Crawling Brawl: Need to avoid, CC effect")
                                    end)
                                end
                                
                                -- I'pa
                                local ipa_tree = TankEngine.menu.tree_node()
                                if ipa_tree then
                                    ipa_tree:render("I'pa", function()
                                        core.menu.text_input("Spouting Stout: Party damage, need to avoid, add spawn")
                                        core.menu.text_input("Fill 'Er Up: Party damage, physical buff")
                                        core.menu.text_input("Oozing Honey: Need to avoid, add spawn")
                                        core.menu.text_input("Bottoms Uppercut: Physical tank buster, CC effect")
                                        core.menu.text_input("Burning Fermentation: Magic debuff")
                                    end)
                                end
                                
                                -- Benk Buzzbee
                                local buzzbee_tree = TankEngine.menu.tree_node()
                                if buzzbee_tree then
                                    buzzbee_tree:render("Benk Buzzbee", function()
                                        core.menu.text_input("Snack Time: Need to avoid, add spawn")
                                        core.menu.text_input("Shredding Sting: Bleed debuff")
                                        core.menu.text_input("Bee-Haw!: Utility spell")
                                        core.menu.text_input("Honey Marinade: Need to avoid, physical buff, magical tank buster")
                                        core.menu.text_input("Fluttering Wing: Party damage, CC effect")
                                    end)
                                end
                                
                                -- Goldie Baronbottom
                                local baronbottom_tree = TankEngine.menu.tree_node()
                                if baronbottom_tree then
                                    baronbottom_tree:render("Goldie Baronbottom", function()
                                        core.menu.text_input("Cinder-BOOM!: Need to avoid, CC effect")
                                        core.menu.text_input("Cindering Wounds: Party damage, physical debuff")
                                        core.menu.text_input("Cash Cannon: Follows players, physical tank buster, CC effect")
                                        core.menu.text_input("Burning Ricochet: Need to avoid, magic debuff")
                                        core.menu.text_input("Let it Hail: Party damage, need to avoid")
                                    end)
                                end
                            end)
                        end
                        
                        -- Floodgate
                        local floodgate_tree = TankEngine.menu.tree_node()
                        if floodgate_tree then
                            floodgate_tree:render("Floodgate", function()
                                -- Big M.O.M.M.A
                                local momma_tree = TankEngine.menu.tree_node()
                                if momma_tree then
                                    momma_tree:render("Big M.O.M.M.A", function()
                                        core.menu.text_input("Mobilize Mechadrones: Add spawn")
                                        core.menu.text_input("Maximum Distortion: Interruptible, party damage, CC effect")
                                        core.menu.text_input("Doom Storm: Locks players")
                                        core.menu.text_input("Electrocrush: Physical debuff, magical tank buster")
                                        core.menu.text_input("Sonic Boom: Need to avoid, follows players, CC effect")
                                        core.menu.text_input("Kill-o-Block Barrier: Party damage, physical buff")
                                        core.menu.text_input("Jumpstart: Party damage")
                                    end)
                                end
                                
                                -- Demolition Duo
                                local demo_duo_tree = TankEngine.menu.tree_node()
                                if demo_duo_tree then
                                    demo_duo_tree:render("Demolition Duo", function()
                                        core.menu.text_input("Divided Duo: Physical buff")
                                        core.menu.text_input("Quick Shot: Utility spell")
                                        core.menu.text_input("B.B.B.F.G: Need to avoid, CC effect")
                                        core.menu.text_input("Wallop: Need to avoid, physical tank buster, CC effect")
                                        core.menu.text_input("Big Bada Boom: Party damage, need to avoid, physical debuff")
                                        core.menu.text_input("Kinetic Explosive Gel: Need to avoid, magic debuff, CC effect")
                                        core.menu.text_input("Barreling Charge: Follows players, CC effect")
                                    end)
                                end
                                
                                -- Swampface
                                local swampface_tree = TankEngine.menu.tree_node()
                                if swampface_tree then
                                    swampface_tree:render("Swampface", function()
                                        core.menu.text_input("Razorchoke Vines: Party damage, physical debuff, CC effect")
                                        core.menu.text_input("Mudslide: Locks players")
                                        core.menu.text_input("Awaken the Swamp: Party damage, need to avoid")
                                        core.menu.text_input("Sludge Claws: Physical debuff, mixed tank buster")
                                    end)
                                end
                                
                                -- Geezle Gigazap
                                local gigazap_tree = TankEngine.menu.tree_node()
                                if gigazap_tree then
                                    gigazap_tree:render("Geezle Gigazap", function()
                                        core.menu.text_input("Turbo Charge: Party damage, locks players, CC effect")
                                        core.menu.text_input("Dam!: Need to avoid")
                                        core.menu.text_input("Leaping Sparks: Need to avoid, CC effect")
                                        core.menu.text_input("Gigazap: Need to avoid, physical debuff")
                                        core.menu.text_input("Thunder Punch: Physical debuff, mixed tank buster, CC effect")
                                    end)
                                end
                            end)
                        end
                        
                        -- Motherload
                        local motherload_tree = TankEngine.menu.tree_node()
                        if motherload_tree then
                            motherload_tree:render("Motherload", function()
                                -- Coin-Operated Crowd Pummeler
                                local pummeler_tree = TankEngine.menu.tree_node()
                                if pummeler_tree then
                                    pummeler_tree:render("Coin-Operated Crowd Pummeler", function()
                                        core.menu.text_input("Static Pulse: Party damage, physical debuff, CC effect")
                                        core.menu.text_input("Throw Coins: Need to avoid")
                                        core.menu.text_input("Coin Magnet: Need to avoid")
                                        core.menu.text_input("Footbomb Launcher: Party damage, physical debuff")
                                        core.menu.text_input("Shocking Claw: Locks players, CC effect")
                                    end)
                                end
                                
                                -- Azerokk
                                local azerokk_tree = TankEngine.menu.tree_node()
                                if azerokk_tree then
                                    azerokk_tree:render("Azerokk", function()
                                        core.menu.text_input("Fracking Totem: Utility spell")
                                        core.menu.text_input("Jagged Cut: Bleed debuff")
                                        core.menu.text_input("Tectonic Smash: Locks players, CC effect")
                                        core.menu.text_input("Azerite Infusion: Party damage, physical buff")
                                        core.menu.text_input("Resonant Quake: Party damage, need to avoid")
                                        core.menu.text_input("Call Earthrager: Add spawn")
                                    end)
                                end
                                
                                -- Rixxa Fluxflame
                                local rixxa_tree = TankEngine.menu.tree_node()
                                if rixxa_tree then
                                    rixxa_tree:render("Rixxa Fluxflame", function()
                                        core.menu.text_input("Searing Reagent: Magical tank buster")
                                        core.menu.text_input("Gushing Catalyst: Need to avoid")
                                        core.menu.text_input("Azerite Catalyst: Need to avoid")
                                        core.menu.text_input("Propellant Blast: Follows players, CC effect")
                                    end)
                                end
                                
                                -- Mogul Razdunk
                                local razdunk_tree = TankEngine.menu.tree_node()
                                if razdunk_tree then
                                    razdunk_tree:render("Mogul Razdunk", function()
                                        core.menu.text_input("Alpha Cannon: Magical tank buster")
                                        core.menu.text_input("B.O.O.M.B.A: Need to avoid")
                                        core.menu.text_input("Homing Missile: Need to avoid, physical debuff")
                                        core.menu.text_input("Gatling Gun: Locks players")
                                        core.menu.text_input("Configuration: Drill: Need to avoid, physical buff, CC effect")
                                        core.menu.text_input("Drill Smash: Party damage, need to avoid")
                                    end)
                                end
                            end)
                        end
                        
                        -- Workshop
                        local workshop_tree = TankEngine.menu.tree_node()
                        if workshop_tree then
                            workshop_tree:render("Workshop", function()
                                -- Tussle Tonks
                                local tonks_tree = TankEngine.menu.tree_node()
                                if tonks_tree then
                                    tonks_tree:render("Tussle Tonks", function()
                                        core.menu.text_input("Electrical Storm: Party damage, physical debuff")
                                        core.menu.text_input("Platinum Pummel: Need to avoid, physical tank buster")
                                        core.menu.text_input("Foe Flipper: Need to avoid, physical debuff, CC effect")
                                        core.menu.text_input("Ground Pound: Party damage")
                                        core.menu.text_input("B.4.T.T.L.3 Mine: Need to avoid")
                                        core.menu.text_input("Maximum Thrust: Need to avoid, locks players, CC effect")
                                        core.menu.text_input("Platinum Plating: Physical buff")
                                    end)
                                end
                                
                                -- K.U.J.O
                                local kujo_tree = TankEngine.menu.tree_node()
                                if kujo_tree then
                                    kujo_tree:render("K.U.J.O", function()
                                        core.menu.text_input("Air Drop: Need to avoid, CC effect")
                                        core.menu.text_input("Blazing Chomp: Party damage, magic debuff, magical tank buster")
                                        core.menu.text_input("Explosive Leap: Party damage, need to avoid")
                                        core.menu.text_input("Venting Flames: Party damage")
                                    end)
                                end
                                
                                -- Machinist's Garden
                                local garden_tree = TankEngine.menu.tree_node()
                                if garden_tree then
                                    garden_tree:render("Machinist's Garden", function()
                                        core.menu.text_input("Inconspicuous Plant: Need to avoid, add spawn, CC effect")
                                        core.menu.text_input("Self-Trimming Hedge: Need to avoid")
                                        core.menu.text_input("Discom-BOMB-ulator: Need to avoid, magic debuff, CC effect")
                                        core.menu.text_input("\"Hidden\" Flame Cannon: Need to avoid, physical debuff")
                                    end)
                                end
                                
                                -- King Mechagon
                                local mechagon_tree = TankEngine.menu.tree_node()
                                if mechagon_tree then
                                    mechagon_tree:render("King Mechagon", function()
                                        core.menu.text_input("Pulse Blast: Magical tank buster")
                                        core.menu.text_input("Recalibrate: Need to avoid, locks players, CC effect")
                                        core.menu.text_input("Mega-Zap: Physical debuff, follows players")
                                        core.menu.text_input("Take Off!: Party damage, need to avoid")
                                        core.menu.text_input("Protocol: Ninety-Nine: Party damage")
                                        core.menu.text_input("Magneto-Arm: Party damage, CC effect")
                                    end)
                                end
                            end)
                        end
                        
                        -- Theatre of Pain
                        local theatre_tree = TankEngine.menu.tree_node()
                        if theatre_tree then
                            theatre_tree:render("Theatre of Pain", function()
                                -- An Afrront of Challengers
                                local challengers_tree = TankEngine.menu.tree_node()
                                if challengers_tree then
                                    challengers_tree:render("An Afrront of Challengers", function()
                                        core.menu.text_input("Final Will: Physical buff")
                                        core.menu.text_input("Necromantic Bolt: Interruptible, magical tank buster")
                                        core.menu.text_input("Withering Touch: Party damage, magic debuff")
                                        core.menu.text_input("Searing Death: Party damage, need to avoid, physical debuff")
                                        core.menu.text_input("Decaying Breath: Locks players")
                                        core.menu.text_input("Noxious Spores: Need to avoid")
                                        core.menu.text_input("Mortal Strike: Physical debuff, physical tank buster")
                                        core.menu.text_input("Mighty Smash: Party damage, physical debuff")
                                    end)
                                end
                                
                                -- Xav the Unfallen
                                local xav_tree = TankEngine.menu.tree_node()
                                if xav_tree then
                                    xav_tree:render("Xav the Unfallen", function()
                                        core.menu.text_input("Brutal Combo: Physical tank buster")
                                        core.menu.text_input("Oppressive Banner: Physical debuff, add spawn, CC effect")
                                        core.menu.text_input("Might of Maldraxxus: Party damage, need to avoid, locks players, CC effect")
                                        core.menu.text_input("Blood and Glory: Physical buff, CC effect")
                                    end)
                                end
                                
                                -- Kul'tharok
                                local kultharok_tree = TankEngine.menu.tree_node()
                                if kultharok_tree then
                                    kultharok_tree:render("Kul'tharok", function()
                                        core.menu.text_input("Necrotic Bolt: Interruptible")
                                        core.menu.text_input("Well of Darkness: Need to avoid, physical debuff")
                                        core.menu.text_input("Death Spiral: Need to avoid")
                                        core.menu.text_input("Necrotic Eruption: Follows players, magical tank buster")
                                        core.menu.text_input("Draw Soul: Party damage, physical debuff, add spawn, CC effect")
                                    end)
                                end
                                
                                -- Gorechomp
                                local gorechomp_tree = TankEngine.menu.tree_node()
                                if gorechomp_tree then
                                    gorechomp_tree:render("Gorechomp", function()
                                        core.menu.text_input("Hateful Strike: Physical tank buster")
                                        core.menu.text_input("Meat Hooks: Need to avoid, bleed debuff, add spawn, CC effect")
                                        core.menu.text_input("Leaping Thrash: Need to avoid")
                                        core.menu.text_input("Coagulating Ooze: Need to avoid")
                                        core.menu.text_input("Tenderizing Smash: Need to avoid, CC effect")
                                    end)
                                end
                                
                                -- Mordretha, the Endless Empress
                                local mordretha_tree = TankEngine.menu.tree_node()
                                if mordretha_tree then
                                    mordretha_tree:render("Mordretha, the Endless Empress", function()
                                        core.menu.text_input("Reaping Scythe: Mixed tank buster")
                                        core.menu.text_input("Dark Devastation: Locks players, CC effect")
                                        core.menu.text_input("Grasping Rift: Party damage, need to avoid, curse debuff, CC effect")
                                        core.menu.text_input("Manifest Death: Party damage, need to avoid, physical debuff, add spawn, CC effect")
                                        core.menu.text_input("Death Bolt: Interruptible")
                                        core.menu.text_input("Echoes of Carnage: Party damage, need to avoid, CC effect")
                                    end)
                                end
                            end)
                        end
                    end)
                end
            end)
        end
    end)
end 