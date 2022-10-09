local celesteEnums = {}

celesteEnums.cassette_songs = require("consts.cassette_songs")
celesteEnums.environmental_sounds = require("consts.environmental_sounds")
celesteEnums.ambient_sounds = require("consts.ambient_sounds")
celesteEnums.songs = require("consts.songs")

celesteEnums.depths = require("consts.object_depths")

celesteEnums.tileset_sound_ids = {
    ["Default"] = -1,
    ["Null"] = 0,
    ["Asphalt"] = 1,
    ["Car"] = 2,
    ["Dirt"] = 3,
    ["Snow"] = 4,
    ["Wood"] = 5,
    ["Bridge"] = 6,
    ["Girder"] = 7,
    ["Brick"] = 8,
    ["Zip Mover"] = 9,
    ["Space Jam (Inactive)"] = 11,
    ["Space Jam (Active)"] = 12,
    ["Resort Wood"] = 13,
    ["Resort Roof"] = 14,
    ["Resort Platform"] = 15,
    ["Resort Basement"] = 16,
    ["Resort Laundry"] = 17,
    ["Resort Boxes"] = 18,
    ["Resort Books"] = 19,
    ["Resort Forcefield"] = 20,
    ["Resort Clutterswitch"] = 21,
    ["Resort Elevator"] = 22,
    ["Cliffside Snow"] = 23,
    ["Cliffside Grass"] = 25,
    ["Cliffside Whiteblock"] = 27,
    ["Gondola"] = 28,
    ["Glass"] = 32,
    ["Grass"] = 33,
    ["Cassette Block"] = 35,
    ["Core Ice"] = 36,
    ["Core Rock"] = 37,
    ["Glitch"] = 40,
    ["Internet Café"] = 42,
    ["Cloud"] = 43,
    ["Moon"] = 44
}

celesteEnums.wind_patterns = {
    "None",
    "Left",
    "Right",
    "LeftStrong",
    "RightStrong",
    "LeftOnOff",
    "RightOnOff",
    "LeftOnOffFast",
    "RightOnOffFast",
    "Alternating",
    "LeftGemsOnly",
    "RightCrazy",
    "Down",
    "Up",
    "Space"
}

celesteEnums.temple_gate_modes = {
    "NearestSwitch",
    "CloseBehindPlayer",
    "CloseBehindPlayerAlways",
    "HoldingTheo",
    "TouchSwitches",
    "CloseBehindPlayerAndTheo"
}

celesteEnums.bird_npc_modes = {
    "ClimbingTutorial",
    "DashingTutorial",
    "DreamJumpTutorial",
    "SuperWallJumpTutorial",
    "HyperJumpTutorial",
    "FlyAway",
    "Sleeping",
    "MoveToNodes",
    "WaitForLightningOff",
    "None"
}

celesteEnums.everest_bird_tutorial_tutorials = {
    "TUTORIAL_CLIMB",
    "TUTORIAL_HOLD",
    "TUTORIAL_DASH",
    "TUTORIAL_DREAMJUMP",
    "TUTORIAL_CARRY",
    "hyperjump/tutorial00",
    "hyperjump/tutorial01"
}

celesteEnums.bonfire_modes = {
    "Unlit",
    "Lit",
    "Smoking"
}

celesteEnums.clutter_block_colors = {
    "Red",
    "Green",
    "Yellow"
}

-- Core and Rainbow color added by Everest
celesteEnums.crystal_colors = {
    "Blue",
    "Red",
    "Purple",
    "Core",
    "Rainbow"
}

celesteEnums.dash_switch_sides = {
    "Up",
    "Down",
    "Left",
    "Right"
}

celesteEnums.tentacle_sides = {
    "Up",
    "Down",
    "Left",
    "Right"
}

celesteEnums.tentacle_fear_distance = {
    "close",
    "medium",
    "far"
}

celesteEnums.move_block_directions = {
    "Up",
    "Down",
    "Left",
    "Right"
}

celesteEnums.spike_directions = {
    "Up",
    "Down",
    "Left",
    "Right"
}

celesteEnums.tentacle_effect_directions = {
    "Up",
    "Down",
    "Left",
    "Right"
}

celesteEnums.planet_effect_sizes = {
    "big",
    "small"
}

celesteEnums.trigger_spike_directions = {
    "Up",
    "Down",
    "Left",
    "Right"
}

celesteEnums.spring_orientations = {
    "Floor",
    "WallLeft",
    "WallRight"
}

celesteEnums.track_spinner_speeds = {
    "Slow",
    "Normal",
    "Fast"
}

celesteEnums.fake_wall_modes = {
    "Wall",
    "Block"
}

celesteEnums.condition_block_conditions = {
    "Key",
    "Button",
    "Strawberry"
}

celesteEnums.spike_types = {
    "default",
    "outline",
    "cliffside",
    "tentacles",
    "reflection"
}

celesteEnums.crumble_block_textures = {
    "default",
    "cliffside"
}

celesteEnums.wood_platform_textures = {
    "default",
    "cliffside"
}

celesteEnums.kevin_axes = {
    "both",
    "horizontal",
    "vertical"
}

celesteEnums.npc_npcs = {
    "granny_00_house",
    "theo_01_campfire",
    "theo_02_campfire",
    "theo_03_escaping",
    "theo_03_vents",
    "oshiro_03_lobby",
    "oshiro_03_hallway",
    "oshiro_03_hallway2",
    "oshiro_03_bigroom",
    "oshiro_03_breakdown",
    "oshiro_03_suite",
    "oshiro_03_rooftop",
    "granny_04_cliffside",
    "theo_04_cliffside",
    "theo_05_entrance",
    "theo_05_inmirror",
    "evil_05",
    "theo_06_plateau",
    "granny_06_intro",
    "badeline_06_crying",
    "granny_06_ending",
    "theo_06_ending",
    "granny_07x",
    "theo_08_inside",
    "granny_08_inside",
    "granny_09_outside",
    "granny_09_inside",
    "gravestone_10",
    "granny_10_never"
}

celesteEnums.seeker_statue_hatches = {
    "Distance",
    "PlayerRightOfX"
}

celesteEnums.badeline_boss_shooting_patterns = {
    0, 1, 2, 3, 4,
    5, 6, 7, 8, 9,
    10, 11, 12, 13,
    14, 15
}

celesteEnums.slider_surfaces = {
    "Ceiling",
    "LeftWall",
    "RightWall",
    "Floor"
}

celesteEnums.trigger_position_modes = {
    "HorizontalCenter",
    "VerticalCenter",
    "TopToBottom",
    "BottomToTop",
    "LeftToRight",
    "RightToLeft",
    "NoEffect"
}

celesteEnums.event_trigger_events = {
    "end_city",
    "end_oldsite_dream",
    "end_oldsite_awake",
    "ch5_see_theo",
    "ch5_found_theo",
    "ch5_mirror_reflection",
    "cancel_ch5_see_theo",
    "ch6_boss_intro",
    "ch6_reflect",
    "ch7_summit",
    "ch8_door",
    "ch9_goto_the_future",
    "ch9_goto_the_past",
    "ch9_moon_intro",
    "ch9_hub_intro",
    "ch9_hub_transition_out",
    "ch9_badeline_helps",
    "ch9_farewell",
    "ch9_ending",
    "ch9_end_golden",
    "ch9_final_room",
    "ch9_ding_ding_ding",
    "ch9_golden_snapshot"
}

celesteEnums.mini_textbox_trigger_modes = {
    "OnPlayerEnter",
    "OnLevelStart",
    "OnTheoEnter"
}

celesteEnums.everest_flag_trigger_modes = {
    "OnPlayerEnter",
    "OnPlayerLeave",
    "OnLevelStart"
}

celesteEnums.everest_crystal_shatter_trigger_modes = {
    "All",
    "Contained"
}

celesteEnums.everest_fake_heart_colors = {
    "Normal",
    "BSide",
    "CSide",
    "Random"
}

celesteEnums.music_fade_trigger_directions = {
    "leftToRight",
    "topToBottom"
}

celesteEnums.black_hole_trigger_strengths = {
    "Mild",
    "Medium",
    "High",
    "Wild"
}

celesteEnums.moon_glitch_background_trigger_durations = {
    "Short",
    "Medium",
    "Long"
}

celesteEnums.spawn_facing_trigger_facings = {
    "Right",
    "Left"
}

celesteEnums.zip_mover_themes = {
    "Normal",
    "Moon"
}

celesteEnums.swap_block_themes = {
    "Normal",
    "Moon"
}

celesteEnums.intro_types = {
    "Respawn",
    "WalkInRight",
    "WalkInLeft",
    "Jump",
    "WakeUp",
    "Fall",
    "TempleMirrorVoid",
    "ThinkForABit",
    "None"
}

celesteEnums.color_grades = {
    "oldsite",
    "reflection",
    "cold",
    "credits",
    "feelingdown",
    "golden",
    "hot",
    "none",
    "panicattack",
    "templevoid"
}

celesteEnums.inventories = {
    "Default",
    "CH6End",
    "Core",
    "OldSite",
    "Prologue",
    "TheSummit",
    "Farewell"
}

celesteEnums.mountain_time = {
    "Night",
    "Dawn",
    "Morning"
}

celesteEnums.core_modes = {
    "None",
    "Cold",
    "Hot"
}

-- "Display Name" => "Expected Value"
celesteEnums.wipe_names = {
    Angled = "Celeste.AngledWipe", --Prologue
    Curtain = "Celeste.CurtainWipe", --Forsaken City
    Dream = "Celeste.DreamWipe", --Old Site
    Drop = "Celeste.DropWipe", --Mirror Temple
    Fade = "Celeste.FadeWipe", --Cutscenes
    Fall = "Celeste.FallWipe", --Reflection
    Heart = "Celeste.HeartWipe", --Core
    KeyDoor = "Celeste.KeyDoorWipe", --Celestial Resort
    Mountain = "Celeste.MountainWipe", --Summit
    Spotlight = "Celeste.SpotlightWipe", --Cutscenes
    Starfield = "Celeste.StarfieldWipe", --Farewell
    Wind = "Celeste.WindWipe" --Golden Ridge
}

return celesteEnums