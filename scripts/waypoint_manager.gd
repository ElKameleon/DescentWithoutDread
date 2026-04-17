extends Node
const WAYPOINTS_FILE_PATH: String = "user://waypoints.cfg"
var config: ConfigFile
var markers: Dictionary = {}

func _init():
    pass

func _ready():
    config = ConfigFile.new()
    config.load(WAYPOINTS_FILE_PATH)
    var scenes = ["FogLands", "FogLands_Invert", "ViperPit", "first_kiln_invert"]
    for scene in scenes:
        for i in range(1, 10):
            if not config.has_section_key(scene, str(i)):
                config.set_value(scene, str(i), "")
    config.save(WAYPOINTS_FILE_PATH)

func is_valid_scene() -> bool:
    var path = get_tree().current_scene.scene_file_path
    return path.contains("FogLands") or path.contains("ViperPit") or path.contains("first_kiln_invert")

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
    for marker in markers.values():
        if is_instance_valid(marker):
            marker.queue_free()
    markers.clear()
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
    var marker = preload("res://scenes/waypoint_marker.tscn").instantiate()
    var scene = get_tree().current_scene
    scene.add_child(marker)
    marker.global_position = position
    markers[slot] = marker

func spawn_existing_markers() -> void:
    config.load(WAYPOINTS_FILE_PATH)
    markers.clear()
    var scene_key = get_scene_key()
    for i in range(1, 10):
        var position = config.get_value(scene_key, str(i), null)
        if typeof(position) == TYPE_VECTOR3:
            spawn_marker(i, position)
