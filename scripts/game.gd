extends Node

var audio: game_audio

var climber: Climber
var centipedes: Array[Centipede]
var lore_point_locations: Array[Vector3]
var in_foglands_scene: bool

enum game_difficulty{Normal, Nightmare, Challenge, NightmareInverted, ChallengeInverted}
var difficulty: game_difficulty = game_difficulty.Normal

var node_to_select_for_controller_mode: Node

var last_frame_pause_requested: int
var last_hide_mouse_requested: int

var seems_to_be_running_using_ANGLE_renderer: bool

var should_unlock_difficulty_up_to_index: int

var this_platform: String = "steam"
var steam_api: Object = null
var steam_id: int
var steam_name: String

var achievements: Dictionary[String, bool] = {
    "BEAT_NORMAL_MODE": false, 
    "BEAT_NIGHTMARE_MODE": false, 
    "BEAT_FIRST_KILN_MODE": false, 
    "BEAT_NIGHTMARE_INVERTED_MODE": false, 
    "BEAT_FIRST_KILN_INVERTED_MODE": false
    }


func initialize_steam() -> void :
    if Engine.has_singleton("Steam"):
        this_platform = "steam"
        steam_api = Engine.get_singleton("Steam")

        var initialized: Dictionary = steam_api.steamInitEx(false)

        print("[STEAM] Did Steam initialize?: %s" % initialized)


        if initialized["status"] > 0:
            print("Failed to initialize Steam, disabling all Steamworks functionality: %s" % initialized)
            steam_api = null
            return


        steam_id = steam_api.getSteamID()
        steam_name = steam_api.getPersonaName()
        print(steam_id)

        load_steam_achievements()
    else:
        this_platform = "itch"
        steam_id = 0
        steam_name = "You"

func is_steam_enabled() -> bool:
    if this_platform == "steam" and steam_api != null:
        return true
    return false

func fire_steam_achievement(ach_name: String) -> void :
    if not achievements[ach_name]:
        achievements[ach_name] = true
        OnscreenMessage.display("fire_steam_achievement %s" % ach_name)
        if is_steam_enabled():
            set_achievement(ach_name)


func load_steam_achievements() -> void :
    for this_achievement in achievements.keys():
        var steam_achievement: Dictionary = steam_api.getAchievement(this_achievement)


        if not steam_achievement["ret"]:
            print("Steam does not have this achievement, defaulting to local value: %s" % achievements[this_achievement])
            continue

        if achievements[this_achievement] == steam_achievement["achieved"]:
            print("Steam achievements match local file, skipping: %s" % this_achievement)
            continue

        set_achievement(this_achievement)

    print("Steam achievements loaded")

func set_achievement(this_achievement: String) -> void :
    if not achievements.has(this_achievement):
        print("This achievement does not exist locally: %s" % this_achievement)
        return
    achievements[this_achievement] = true

    if not steam_api.setAchievement(this_achievement):
        print("Failed to set achievement: %s" % this_achievement)
        return

    print("Set acheivement: %s" % this_achievement)
    store_steam_data()


func store_steam_data() -> void :
    if not steam_api.storeStats():
        print("Failed to store data on Steam, should be stored locally")
        return
    print("Data successfully sent to Steam")

func _ready():
    audio = preload("res://scenes/GameAudio.tscn").instantiate()
    add_child(audio)
    process_mode = PROCESS_MODE_ALWAYS





    var rendering_driver_name: String = RenderingServer.get_current_rendering_driver_name()
    match (rendering_driver_name):
        "opengl3_angle", "opengl3_es":
            seems_to_be_running_using_ANGLE_renderer = true

    await get_tree().process_frame


    if PlayerData.config.get_value("unlocked", "difficulty", 0) == 2:
        PlayerData.config.set_value("unlocked", "difficulty", 3)
        PlayerData.saveConfig()

    if not OS.has_feature("editor"):
        initialize_steam()

        var player_data_unlocked_difficulty: int = PlayerData.config.get_value("unlocked", "difficulty", 0)

        match (player_data_unlocked_difficulty):
            1:
                fire_steam_achievement_for_difficulty_index(1)
            2, 3:
                fire_steam_achievement_for_difficulty_index(2)
            4:
                fire_steam_achievement_for_difficulty_index(3)
            5:
                fire_steam_achievement_for_difficulty_index(5)

func fire_steam_achievement_for_difficulty_index(diff_index: int):
    match (diff_index):
        1:
            Game.fire_steam_achievement("BEAT_NORMAL_MODE")
        2:
            Game.fire_steam_achievement("BEAT_NIGHTMARE_MODE")
        3:
            Game.fire_steam_achievement("BEAT_FIRST_KILN_MODE")
        4:
            Game.fire_steam_achievement("BEAT_NIGHTMARE_INVERTED_MODE")
        5:
            Game.fire_steam_achievement("BEAT_FIRST_KILN_INVERTED_MODE")

func register_climber(p_climber: Climber):
    climber = p_climber
    audio.register_climber(p_climber)

func register_centipede(p_centipede: Centipede):
    centipedes.append(p_centipede)

func _process(delta: float) -> void :
    var mouse_should_be_captured: bool = is_instance_valid(climber) and not get_tree().paused
    if ControllerIcons._last_input_type == ControllerIcons.InputType.CONTROLLER:
        mouse_should_be_captured = true
    if Engine.get_frames_drawn() == last_hide_mouse_requested:
        mouse_should_be_captured = true

    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if mouse_should_be_captured else Input.MOUSE_MODE_VISIBLE

    get_tree().paused = Engine.get_frames_drawn() == last_frame_pause_requested or Dialogic.current_timeline

    if ControllerIcons._last_input_type == ControllerIcons.InputType.CONTROLLER:
        if node_to_select_for_controller_mode:
            node_to_select_for_controller_mode.grab_focus.call_deferred()
            node_to_select_for_controller_mode = null


func request_pause_next_frame():
    last_frame_pause_requested = Engine.get_frames_drawn() + 1

func request_hide_mouse_next_frame():
    last_hide_mouse_requested = Engine.get_frames_drawn() + 1

func trigger_ending():
    climber.enter_ending_state()





func load_level_based_on_difficulty(from_main_menu: bool = false):
    centipedes.clear()
    lore_point_locations.clear()

    match (difficulty):
        game_difficulty.ChallengeInverted:
            Game.get_tree().change_scene_to_file("res://scenes/first_kiln_invert.tscn")
        game_difficulty.NightmareInverted:
            Game.get_tree().change_scene_to_file("res://scenes/FogLands_Invert.tscn")
        game_difficulty.Challenge:
            if from_main_menu:
                Game.get_tree().change_scene_to_file("res://scenes/transition_to_first_kiln.tscn")
            else:
                Game.get_tree().change_scene_to_file("res://scenes/ViperPit.tscn")
            in_foglands_scene = false
        _:
            Game.get_tree().change_scene_to_file("res://scenes/FogLands.tscn")
            in_foglands_scene = true

func centipede_should_go_after_claw() -> bool:
    return difficulty >= game_difficulty.Nightmare
