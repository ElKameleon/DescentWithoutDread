extends Node
const WAYPOINTS_FILE_PATH: String = "user://waypoints.cfg"
var MOD_DIR: String

var config: ConfigFile
var markers: Dictionary = {}
var _markers_spawned_for_scene: String = ""
var _current_scene_path: String = ""

var menu_marker: Node3D = null
const MENU_MARKER_POSITION := Vector3(86.12, 5.952, 51.66)

# Constants for waypoint slot range and UI timing
const WAYPOINT_SLOT_START := 1
const WAYPOINT_SLOT_END_EXCLUSIVE := 10
const WAYPOINT_DISPLAY_DURATION_MS := 3000
const WAYPOINT_LERP_FACTOR := 3.3
const WAYPOINT_GROUND_OFFSET := 0.75

func _ready():
    set_process_unhandled_input(true)
    config = ConfigFile.new()
    config.load(WAYPOINTS_FILE_PATH)
    if not config.has_section_key("firstkiln", "has_seen_intro"):
        config.set_value("firstkiln", "has_seen_intro", false)
        config.save(WAYPOINTS_FILE_PATH)

func _process(delta: float) -> void:
    _process_waypoint_label(delta)
    var scene = get_tree().current_scene
    if scene == null:
        return

    var path = scene.scene_file_path
    var scene_changed = path != _current_scene_path
    if scene_changed:
        _current_scene_path = path

        if path.contains("transition_to_first_kiln"):
            if config.get_value("firstkiln", "has_seen_intro", false):
                Game.get_tree().change_scene_to_file("res://scenes/ViperPit.tscn")
                return
            else:
                config.set_value("firstkiln", "has_seen_intro", true)
                config.save(WAYPOINTS_FILE_PATH)

    if is_main_menu_scene():
        clear_spawned_markers()
        spawn_main_menu_marker()
        return
    else:
        clear_main_menu_marker()

    if not is_instance_valid(Game.climber):
        clear_spawned_markers()
        return

    var scene_key = get_scene_key()
    if scene_changed or _markers_spawned_for_scene != scene_key:
        _markers_spawned_for_scene = scene_key
        initialize_scene(scene_key)
        spawn_existing_markers()

func _unhandled_input(event: InputEvent) -> void:
    if not can_use_waypoint_actions():
        return
    if event is InputEventKey and event.pressed and not event.echo:
        for i in range(WAYPOINT_SLOT_START, WAYPOINT_SLOT_END_EXCLUSIVE):
            if event.keycode == KEY_1 + (i - 1):
                if event.ctrl_pressed:
                    save_waypoint(i, Game.climber.global_position)
                else:
                    teleport_to_waypoint(i)
        if event.keycode == KEY_BACKSPACE and event.ctrl_pressed:
            clear_waypoints()

func is_main_menu_scene() -> bool:
    var scene = get_tree().current_scene
    return scene != null and scene.scene_file_path.contains("MainMenu")

func get_scene_key() -> String:
    return get_tree().current_scene.scene_file_path.get_file().get_basename()

func initialize_scene(scene_key: String) -> void:
    # Intentionally no-op: missing waypoint slots are handled by get_value() defaults.
    pass

func can_use_waypoint_actions() -> bool:
    if not is_instance_valid(Game.climber):
        return false
    if Game.climber.injured_state:
        return false
    if not Game.climber.grapple_claw_is_enabled:
        return false
    return true

var _waypoint_label: Label = null
var _waypoint_label_last_ms: int = -9999

func _get_or_create_waypoint_label() -> Label:
    if is_instance_valid(_waypoint_label):
        return _waypoint_label
    if not (Game.climber and is_instance_valid(Game.climber.hud)):
        return null
    var label = Label.new()
    label.size = Vector2(339, 37)
    label.position = Vector2(25, 87)
    label.modulate = Color.WHITE * 0.0
    var label_settings = load("res://scenes/hud.tscn::LabelSettings_3swnk")
    if label_settings:
        label.label_settings = label_settings
    else:
        var main_theme = load("res://ui/main_theme.tres")
        label.theme = main_theme
    Game.climber.hud.add_child(label)
    _waypoint_label = label
    return label

func display_message(msg: String) -> void:
    var label = _get_or_create_waypoint_label()
    if label:
        label.text = msg
        label.modulate = Color.WHITE
        _waypoint_label_last_ms = Time.get_ticks_msec()

func _process_waypoint_label(delta: float) -> void:
    if is_instance_valid(_waypoint_label):
        if Time.get_ticks_msec() > _waypoint_label_last_ms + WAYPOINT_DISPLAY_DURATION_MS:
            _waypoint_label.modulate = lerp(_waypoint_label.modulate, Color.WHITE * 0.0, WAYPOINT_LERP_FACTOR * delta)

func save_waypoint(slot: int, position: Vector3) -> void:
    if not can_use_waypoint_actions():
        return
    if not Game.climber.is_on_floor():
        display_message("Not on ground!")
        return
    var ground_position = position - Vector3.UP * WAYPOINT_GROUND_OFFSET
    config.set_value(get_scene_key(), str(slot), ground_position)
    config.save(WAYPOINTS_FILE_PATH)
    spawn_marker(slot, ground_position)
    display_message("Waypoint %d set!" % slot)

func clear_waypoints() -> void:
    if not can_use_waypoint_actions():
        return
    var scene_key = get_scene_key()
    for i in range(WAYPOINT_SLOT_START, WAYPOINT_SLOT_END_EXCLUSIVE):
        config.set_value(scene_key, str(i), "")
    config.save(WAYPOINTS_FILE_PATH)
    clear_spawned_markers()
    display_message("All waypoints cleared!")

func get_saved_waypoint(scene_key: String, slot: int) -> Variant:
    var slot_key = str(slot)
    if not config.has_section_key(scene_key, slot_key):
        return null

    var position = config.get_value(scene_key, slot_key)
    if typeof(position) == TYPE_VECTOR3:
        return position

    return null

func teleport_to_waypoint(slot: int) -> void:
    if not can_use_waypoint_actions():
        return
    var position = get_saved_waypoint(get_scene_key(), slot)
    if position == null:
        display_message("Waypoint %d not set!" % slot)
        return
    Game.climber.teleport_to_location(position + Vector3(0, 1, 0))
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

    for marker in markers.values():
        if is_instance_valid(marker):
            marker.queue_free()
    markers.clear()

    var scene_key = get_scene_key()
    for i in range(WAYPOINT_SLOT_START, WAYPOINT_SLOT_END_EXCLUSIVE):
        var position = get_saved_waypoint(scene_key, i)
        if position != null:
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
