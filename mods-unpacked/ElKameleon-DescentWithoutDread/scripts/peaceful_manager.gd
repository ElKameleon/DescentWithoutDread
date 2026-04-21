extends Node

var _current_scene_path := ""
var _fall_damage_disabled := false
var _peaceful_was_active := false
var _last_peaceful_state := false

func _process(_delta: float) -> void:
    var scene = get_tree().current_scene
    if scene == null:
        return
    var path = scene.scene_file_path
    if path != _current_scene_path:
        _current_scene_path = path
        _fall_damage_disabled = false

        if is_instance_valid(Game.climber):
            _peaceful_was_active = false
            get_tree().create_timer(0.5).timeout.connect(_try_disable_centipedes.bind(get_tree().current_scene))
        elif path.contains("post_credits"):
            OnscreenMessage.display("Post credits! Peaceful flag = " + str(_peaceful_was_active))
            if _peaceful_was_active:
                OnscreenMessage.display("Skipping post credits - peaceful was active!")
                get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
                return

    var peaceful_on = GameSettings.config.get_value("game", "peaceful_mode", false)

    if peaceful_on != _last_peaceful_state:
        _last_peaceful_state = peaceful_on
        if is_instance_valid(Game.climber):
            if peaceful_on:
                OnscreenMessage.display("Peaceful mode on! Peaceful flag = true")
                _peaceful_was_active = true
            else:
                OnscreenMessage.display("Peaceful mode off! Peaceful flag = " + str(_peaceful_was_active))

    if peaceful_on and is_instance_valid(Game.climber):
        _peaceful_was_active = true

    if not _fall_damage_disabled and peaceful_on:
        if is_instance_valid(Game.climber):
            Game.climber.minDecelerationForDamage = 9999.0
            _fall_damage_disabled = true

func _try_disable_centipedes(scene: Node) -> void:
    if not GameSettings.config.get_value("game", "peaceful_mode", false):
        return
    var centipedes = scene.find_children("Centipede*", "", true, false)
    for centipede in centipedes:
        if "_pathfinder" in centipede:
            centipede.process_mode = Node.PROCESS_MODE_DISABLED
            centipede.hide()
            OnscreenMessage.display(centipede.name + " nuked!")
