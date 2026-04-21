extends Node

var _precision_active: bool = false

func _ready() -> void:
    set_process_unhandled_input(true)

func _unhandled_input(event: InputEvent) -> void:
    if not _climber_valid():
        return

    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
        if is_instance_valid(Game.climber.activeClimberState) and Game.climber.activeClimberState.get_script().resource_path.contains("climber_state_throw"):
            _enable_precision_mode()

func _enable_precision_mode() -> void:
    if _precision_active:
        return
    var current_velocity = PhysicsServer3D.body_get_state(
        Game.climber.Rope._claw.get_rid(),
        PhysicsServer3D.BODY_STATE_LINEAR_VELOCITY
    )
    PhysicsServer3D.body_set_state(
        Game.climber.Rope._claw.get_rid(),
        PhysicsServer3D.BODY_STATE_LINEAR_VELOCITY,
        Vector3(current_velocity.x * 0.3, -2.0, current_velocity.z * 0.3)
    )
    _precision_active = true

func _process(_delta: float) -> void:
    if not _climber_valid():
        if _precision_active:
            _precision_active = false
        return

    if _precision_active:
        var state = Game.climber.activeClimberState
        var state_path = state.get_script().resource_path if is_instance_valid(state) and state.get_script() else ""
        if state_path.contains("climber_state_default") or state_path.contains("climber_state_attached"):
            _precision_active = false
        else:
            var player_camera = Game.climber.PlayerCamera
            if is_instance_valid(player_camera):
                if player_camera.zoom_tween:
                    player_camera.zoom_tween.kill()
                player_camera.Camera.fov = 75.0
                player_camera.is_zoomed_in = false

func _climber_valid() -> bool:
    return Game.climber != null \
        and is_instance_valid(Game.climber) \
        and is_instance_valid(Game.climber.Rope) \
        and is_instance_valid(Game.climber.Rope._settings)
