# Tanking Engine Framework - TODO List

## Overview
This project aims to create a standalone tanking engine framework for WoW rotation automation. The framework will follow a modular, high-level approach similar to the healing engine framework but specifically tailored for tank specializations. It will have its own namespace and API structure, independent of the FS framework.

## Project Structure
```
tanking_engine/
├── core/                     # Core framework functionality
│   ├── api.lua               # Localized API functions
│   ├── variables.lua         # Global state tracking
│   ├── settings.lua          # Settings management
│   ├── menu.lua              # UI menu system
│   ├── humanizer.lua         # Human-like action timing
│   └── modules/              # Core framework modules
│       ├── threat_manager/   # Threat tracking and management
│       ├── mitigation/       # Defensive ability management
│       ├── positioning/      # Tank positioning optimization
│       └── enemy_tracking/   # Enemy ability and pattern tracking
├── classes/                  # Tank class-specific implementations
│   ├── warrior/
│   │   └── protection/
│   ├── paladin/
│   │   └── protection/
│   ├── monk/
│   │   └── brewmaster/
│   ├── deathknight/
│   │   └── blood/
│   ├── demonhunter/
│   │   └── vengeance/
│   └── druid/
│       └── guardian/
├── entry/                    # Entry point and initialization
│   ├── entry_helper.lua
│   ├── check_spec.lua
│   ├── init.lua
│   └── callbacks/            # Event callbacks
│       ├── on_update.lua
│       ├── on_render.lua
│       └── on_render_menu.lua
├── shared/                   # Shared utility functions
│   ├── enums.lua
│   ├── utils.lua
│   ├── combat_utils.lua
│   └── math_utils.lua
├── version.lua               # Version information
├── header.lua                # Plugin header information
└── main.lua                  # Main entry point
```

## Core Components to Implement

### 1. Framework Foundation
- [x] Create base namespace structure (separate from FS namespace)
- [x] Implement version tracking and plugin header
- [x] Create entry points and initialization logic
- [x] Set up event callback system

### 2. Core Engine Components
- [ ] **Threat Manager**
  - [x] Track threat levels for all enemies in combat
  - [x] Calculate taunt priority based on threat differentials
  - [ ] Implement AoE vs Single target threat priority systems
  - [ ] Create threat threshold settings

- [ ] **Mitigation Manager**
  - [x] Track and predict incoming damage patterns
  - [x] Manage defensive cooldowns based on incoming damage
  - [ ] Implement different mitigation strategies based on damage types
  - [ ] Develop cooldown rotation optimization

- [ ] **Enemy Tracking**
  - [x] Track dangerous enemy abilities and casts
  - [x] Identify and prioritize interruptible spells
  - [x] Analyze enemy positioning and clustering
  - [x] Track enemies targeting group members vs tank

- [ ] **Positioning System**
  - [x] Calculate optimal tank positioning for group safety
  - [x] Implement kiting logic for high damage scenarios
  - [x] Create pathing algorithms for mob gathering
  - [ ] Maintain proper boss positioning

### 3. API and Utilities
- [x] Create localized API wrapper for core functions
- [x] Implement common utility functions for tanks
- [x] Develop math utilities for positioning calculations
- [ ] Create combat analysis utilities for pattern recognition

### 4. Menu and Settings System
- [x] Design comprehensive settings UI with categories:
  - [ ] Threat management
  - [x] Defensive cooldown usage
  - [x] Interrupt priorities
  - [x] Movement and positioning
  - [ ] Class-specific settings

### 5. Class-Specific Modules
- [x] Design template for tank class modules
- [ ] Implement specialized modules for each tank spec:
  - [x] Warrior (Protection)
  - [ ] Paladin (Protection)
  - [ ] Death Knight (Blood)
  - [ ] Demon Hunter (Vengeance)
  - [ ] Druid (Guardian)
  - [ ] Monk (Brewmaster)

## Advanced Features

### 1. Defensive Analysis System
- [ ] Develop AI-like pattern recognition for boss attack patterns
- [ ] Create predictive damage models based on encounter history
- [ ] Implement optimal cooldown sequencing based on predicted damage
- [ ] Add emergency response logic for unexpected damage spikes

### 2. Group Synergy Management
- [ ] Track healer mana and cooldown usage
- [ ] Coordinate defensive cooldowns with healer abilities
- [ ] Monitor DPS positions for optimal boss positioning
- [ ] Implement communication system between tank and healer engines (if both running)

### 3. Encounter-Specific Logic
- [ ] Create framework for encounter-specific handling
- [ ] Implement dungeon route optimization
- [ ] Add support for boss-specific mechanics and positioning
- [ ] Develop M+ affix handling (Necrotic, Raging, etc.)

## Implementation Strategy

### Phase 1: Core Framework
- [x] Set up project structure and namespace
- [x] Implement basic engine functions and utilities
- [x] Create menu and settings system
- [x] Build threat tracking and enemy monitoring systems

### Phase 2: Tank Mechanics
- [x] Implement active mitigation logic
- [x] Develop defensive cooldown management
- [x] Create positioning and movement systems
- [x] Add interrupt and crowd control handling

### Phase 3: Class Specialization
- [x] Implement template for class modules
- [x] Build first class module (Protection Warrior as reference)
- [ ] Design rotation logic systems
- [ ] Create class-specific resource management

### Phase 4: Advanced Features
- [ ] Add pattern recognition and damage prediction
- [ ] Implement dungeon and raid specific optimizations
- [ ] Create group coordination systems
- [ ] Develop performance analysis and logging

### Phase 5: Refinement and Testing
- [ ] Optimize performance
- [ ] Create extensive testing framework
- [ ] Refine user interface and settings
- [ ] Add visualization tools for debugging

## Design Principles
1. **Modularity**: Each component should be self-contained with clear APIs
2. **Performance**: Optimization for minimal performance impact
3. **Configurability**: Extensive user settings without overwhelming complexity
4. **Adaptability**: Framework should adapt to different encounter types
5. **Maintainability**: Clean code structure for easy updates and expansion

## Technical Considerations
- Maintain compatibility with the game's API
- Ensure smooth integration with existing addon frameworks
- Consider performance implications of tracking many combat entities
- Implement debug and logging systems for troubleshooting
- Use local functions and variables as much as possible for performance
- Minimize table creation during combat loops

## Bug Fixes and Optimizations

### Critical Issues to Address
- [ ] **Initialization Sequence**: Create a proper initialization sequence to ensure all components are loaded in the correct order
- [ ] **Dependency Injection**: Add a system to explicitly define and inject dependencies between modules
- [x] **Error Handling**: Implement comprehensive error handling with pcall/xpcall throughout critical code paths
- [x] **Nil Reference Protection**: Add safeguards against nil references, especially for game objects and API calls

### API and Function Consistency
- [x] **Standardize API Access Pattern**: Choose one consistent way to access API functions (either through TankEngine.api.X or through local references)
- [ ] **Function Signature Standardization**: Ensure all similar functions follow the same parameter order and naming conventions
- [ ] **Return Value Consistency**: Standardize function return values (e.g., all functions that can fail should return success, errorMsg)
- [ ] **Documentation**: Add proper LuaDoc comments to all public functions

### Module-Specific Issues

#### Core Framework
- [ ] **Variable Initialization**: Fix TankEngine.variables being accessed before proper initialization
- [x] **Safe Getters**: Add safe getter functions for commonly accessed values like current target
- [x] **API Wrappers**: Ensure all external API calls are properly wrapped to catch errors
- [x] **Event Handlers**: Add error handling in event callbacks to prevent cascade failures

#### Threat Manager
- [ ] **Error Protection**: Add validation checks before accessing unit target or other potentially nil references
- [ ] **Performance Optimization**: Reduce unnecessary calculations in the frequent update loop
- [ ] **Cross-Module Dependencies**: Resolve circular dependencies with other modules

#### Mitigation Manager
- [ ] **Defensive Cooldown Logic**: Fix potential issues with defensive ability selection and timing
- [ ] **Health/Damage Prediction**: Improve accuracy of health prediction and damage forecasting
- [ ] **WigsTracker Integration**: Ensure proper integration with the WigsTracker module

#### Enemy Tracking
- [ ] **Memory Management**: Optimize storage of tracked entities to reduce memory usage
- [ ] **Stale Data Cleanup**: Ensure proper cleanup of stale enemy data
- [ ] **Cast Detection**: Fix issues with cast detection and interrupt priority logic

#### Positioning
- [ ] **Movement Calculations**: Improve accuracy of position calculations and pathing
- [ ] **Position Safety Checks**: Add validation to ensure calculated positions are valid and reachable
- [ ] **Performance**: Optimize costly vector calculations that run frequently

#### Warrior Protection Module
- [x] **API Consistency**: Standardize API usage across the warrior protection module
- [ ] **Defensive Logic**: Fix issues with defensive cooldown priority selection
- [ ] **WigsTracker Integration**: Ensure boss ability detection properly triggers defensive responses
- [x] **Error Handling**: Add safeguards around ability usage and target selection

### Testing and Quality Assurance
- [ ] **Create Unit Tests**: Develop a testing framework for core functionality
- [ ] **Add Logging**: Implement comprehensive logging with severity levels
- [ ] **Performance Profiling**: Add tools to measure performance impact of each module
- [ ] **Stress Testing**: Test framework with high entity counts and rapid state changes

### Documentation
- [ ] **Code Comments**: Improve inline documentation, especially for complex algorithms
- [ ] **API Documentation**: Create comprehensive API documentation for all public interfaces
- [ ] **Installation Guide**: Add detailed setup instructions for new users
- [ ] **Configuration Guide**: Document all available settings and customization options
