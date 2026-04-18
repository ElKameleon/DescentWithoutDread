extends Node
const WAYPOINTS_FILE_PATH: String = "user://waypoints.cfg"
var MOD_DIR: String

var config: ConfigFile
var markers: Dictionary = {}
var _markers_spawned_for_scene: String = ""
var _current_scene_path: String = ""

var menu_marker: Node3D = null
const MENU_MARKER_POSITION := Vector3(86.12, 5.952, 51.66)

func _init():
    pass

func _ready():
    print("waypoint_manager _ready called")
    set_process_unhandled_input(true)
    config = ConfigFile.new()
    config.load(WAYPOINTS_FILE_PATH)
    var scenes = ["FogLands", "FogLands_Invert", "ViperPit", "first_kiln_invert"]
    for scene in scenes:
        for i in range(1, 10):
            if not config.has_section_key(scene, str(i)):
                config.set_value(scene, str(i), "")
    config.save(WAYPOINTS_FILE_PATH)

func _process(_delta: float) -> void:
    print("process running")
    var scene = get_tree().current_scene
    if scene == null:
        return

    var path = scene.scene_file_path
    var scene_changed = path != _current_scene_path
    if scene_changed:
        _current_scene_path = path

    if is_main_menu_scene():
        clear_spawned_markers()
        spawn_main_menu_marker()
        return
    else:
        clear_main_menu_marker()

    if not is_valid_scene():
        clear_spawned_markers()
        return

    if Game.climber == null:
        return

    var scene_key = get_scene_key()
    if scene_changed or _markers_spawned_for_scene != scene_key:
        _markers_spawned_for_scene = scene_key
        initialize_scene(scene_key)
        spawn_existing_markers()

func _unhandled_input(event: InputEvent) -> void:
    if not is_valid_scene():
        return
    if Game.climber == null:
        return
    if event is InputEventKey and event.pressed and not event.echo:
        for i in range(1, 10):
            if event.keycode == KEY_1 + (i - 1):
                if event.ctrl_pressed:
                    save_waypoint(i, Game.climber.global_position)
                else:
                    teleport_to_waypoint(i)
        if event.keycode == KEY_BACKSPACE and event.ctrl_pressed:
            clear_waypoints()

func is_valid_scene() -> bool:
    var path = get_tree().current_scene.scene_file_path
    return path.contains("FogLands") or path.contains("ViperPit") or path.contains("first_kiln_invert")

func is_main_menu_scene() -> bool:
    var scene = get_tree().current_scene
    return scene != null and scene.scene_file_path.contains("MainMenu")

func get_scene_key() -> String:
    return get_tree().current_scene.scene_file_path.get_file().get_basename()

func initialize_scene(scene_key: String) -> void:
    for i in range(1, 10):
        if not config.has_section_key(scene_key, str(i)):
            config.set_value(scene_key, str(i), "")
    config.save(WAYPOINTS_FILE_PATH)

func is_unlocked() -> bool:
    var cleared = PlayerData.config.get_value("unlocked", "difficulty", 0)
    return cleared >= Game.difficulty + 1

func display_message(msg: String) -> void:
    if Game.climber and is_instance_valid(Game.climber.hud):
        Game.climber.hud.game_saved_message.text = msg
        Game.climber.hud.game_saved_message.modulate = Color.WHITE
        Game.climber.hud.last_saved_ms = Time.get_ticks_msec()

func save_waypoint(slot: int, position: Vector3) -> void:
    if not is_valid_scene():
        return
    if not is_unlocked():
        display_message("Clear this difficulty to use waypoints!")
        return
    if not Game.climber.is_on_floor():
        display_message("Not on ground!")
        return
    var ground_position = position - Vector3.UP * 0.78
    config.set_value(get_scene_key(), str(slot), ground_position)
    config.save(WAYPOINTS_FILE_PATH)
    spawn_marker(slot, ground_position)
    display_message("Waypoint %d set!" % slot)

func clear_waypoints() -> void:
    if not is_valid_scene():
        return
    if not is_unlocked():
        display_message("Clear this difficulty to use waypoints!")
        return
    var scene_key = get_scene_key()
    for i in range(1, 10):
        config.set_value(scene_key, str(i), "")
    config.save(WAYPOINTS_FILE_PATH)
    clear_spawned_markers()
    display_message("All waypoints cleared!")

func teleport_to_waypoint(slot: int) -> void:
    if not is_valid_scene():
        return
    if not is_unlocked():
        display_message("Clear this difficulty to use waypoints!")
        return
    var position = config.get_value(get_scene_key(), str(slot), null)
    if position == null or typeof(position) != TYPE_VECTOR3:
        display_message("Waypoint %d not set!" % slot)
        return
    Game.climber.teleport_to_location(position)
    Game.climber.AirVelocity = Vector3.ZERO
    Game.climber.velocity = Vector3.ZERO
    Game.climber.additional_velocity_next_frame = Vector3.ZERO
    Game.climber.physics_process_velocity_last_frame = Vector3.ZERO
    display_message("Teleported to waypoint %d!" % slot)

func spawn_marker(slot: int, position: Vector3) -> void:
    if markers.has(slot) and is_instance_valid(markers[slot]):
        markers[slot].queue_free()
    var marker = load(MOD_DIR + "/scenes/waypoint_marker.tscn").instantiate()
    var scene = get_tree().current_scene
    scene.add_child(marker)
    marker.global_position = position
    markers[slot] = marker

func spawn_existing_markers() -> void:
    config.load(WAYPOINTS_FILE_PATH)
    clear_spawned_markers()
    var scene_key = get_scene_key()
    for i in range(1, 10):
        var position = config.get_value(scene_key, str(i), null)
        if typeof(position) == TYPE_VECTOR3:
            spawn_marker(i, position)

func clear_spawned_markers() -> void:
    for marker in markers.values():
        if is_instance_valid(marker):
            marker.queue_free()
    markers.clear()
    _markers_spawned_for_scene = ""

func spawn_main_menu_marker() -> void:
    if is_instance_valid(menu_marker):
        return
    var marker = load(MOD_DIR + "/scenes/waypoint_marker.tscn").instantiate()
    var scene = get_tree().current_scene
    scene.add_child(marker)
    marker.position = MENU_MARKER_POSITION
    menu_marker = marker

func clear_main_menu_marker() -> void:
    if is_instance_valid(menu_marker):
        menu_marker.queue_free()
    menu_marker = null
