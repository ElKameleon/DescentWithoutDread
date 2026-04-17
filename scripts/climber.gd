class_name Climber extends Pawn

@export var Camera: Camera3D
@export var PlayerCamera: PlayerCamera
@export var CameraShakeNode: Node3D
@export var Rope: ClimberRope
@export var hud: HUD

var Edge: ClimbingEdgePlayer

@onready var actionable_finder: Area3D = $PlayerCamera / Camera / ActionableFinder

@export var GrapplingEnabled: = true

@export_category("Player Physics")
@export var WalkSpeed: = 10.0
@export var AirControl: = 0.5
@export var TerminalVelocity: = 50.0
@export var GravityAcceleration: = 0.3
@export var minDecelerationForDamage: = 20.0

var WalkSpeedMultiplier: float = 1.0

@onready var footstepsAudioPlayer_Default: AudioStreamPlayer3D = $Footsteps_Default
@onready var footstepsAudioPlayer_Stone: AudioStreamPlayer3D = $Footsteps_Stone

@export var rope_swish_for_ending: Node3D

var lastMsPlayedFootstep: int

var currentFootstepPhysicsMaterialPath: String


var AirVelocity: Vector3


var LastVelocity: Vector3

var activeClimberState: ClimberState

var defaultClimberState: ClimberState_Default

var last_sliding_down_rope_ms: int
var last_climbing_up_rope_ms: int

var additional_velocity_next_frame: Vector3

var additional_slack_offset: float

var last_processed_move_result: bool
var last_y_velocity_on_last_processed_move_result: float

var last_damage_from_over_tension_ms: int

var grapple_claw_is_enabled: bool = true
var jump_is_enabled: bool = true
var sprint_is_enabled: bool = true
var injured_state: bool = false
var ending_should_trigger_next_step_on_next_collision: bool = false
var prevent_player_death: bool = false

var player_audio_enabled: bool = true

var time_since_actionable_triggered: float = 0.0
const min_delay_for_triggering_actionable: float = 2.0

var last_grounded_frames_ago: int

var original_global_position_in_level: Vector3

func _ready() -> void :
    super ()
    hud.set_to_black()

    await get_tree().process_frame

    Edge = ClimbingEdgePlayer.new()
    Edge.setup(self)

    Rope.setup(self)

    original_global_position_in_level = global_position

    defaultClimberState = ClimberState_Default.new()
    set_climber_state(defaultClimberState)

    Game.register_climber(self)

    if get_tree().current_scene.scene_file_path.contains("FogLands"):
        if PlayerData.get_death_count() > 0 or Game.difficulty == Game.game_difficulty.Nightmare:
            if Game.difficulty != Game.game_difficulty.NightmareInverted:
                set_global_position(Vector3(10.0, 854.536, 0.0))
                set_global_rotation(Vector3(0.0, 127.0, 0.0))
                process_in_air_position_last_frame = global_position

        if Game.difficulty == Game.game_difficulty.Normal:
            if SaveGameData.exists():
                SaveGameData.load(self)
    elif get_tree().current_scene.scene_file_path.contains("ViperPit"):
        if PlayerData.get_death_count() > 0:
            set_global_position(Vector3(-21.312, 1428.991, 0.0))
            process_in_air_position_last_frame = global_position

    await get_tree().create_timer(0.5).timeout
    cut_from_black()

func set_climber_state(climber_state: ClimberState):
    if climber_state and climber_state == activeClimberState:
        return
    if not Rope.is_setup:
        return
    if activeClimberState:
        activeClimberState._exit_state()
    activeClimberState = climber_state
    if activeClimberState:
        activeClimberState._climber = self

        if activeClimberState:
            activeClimberState._enter_state()

func _unhandled_input(event: InputEvent) -> void :
    if OS.has_feature("editor"):
        if event is InputEventKey:
            if Game.in_foglands_scene:
                if event.keycode == KEY_F1:
                    set_global_position(Vector3(10.0, 854.536, 0.0))
                    process_in_air_position_last_frame = global_position
                elif event.keycode == KEY_F2:
                    set_global_position(Vector3(-14.325, -715.739 + 854.536, 60.681))
                    process_in_air_position_last_frame = global_position
                elif event.keycode == KEY_F3:
                    set_global_position(Vector3(2.433, -995.261 + 854.536, -43.729))
                    process_in_air_position_last_frame = global_position
                elif event.keycode == KEY_F4:
                    set_global_position(Vector3(123.0, -1486.0 + 854.536, -83.0))
                    process_in_air_position_last_frame = global_position
                elif event.keycode == KEY_F5:
                    set_global_position(Vector3(-10.335, -2036.0 + 854.536, -56))
                    process_in_air_position_last_frame = global_position
            elif get_tree().current_scene.scene_file_path.contains("ViperPit"):
                if event.keycode == KEY_F1:
                    set_global_position(Vector3(40.0, -3300.426 + 1428.991, 0.0))
                    process_in_air_position_last_frame = global_position
                elif event.keycode == KEY_F2:
                    set_global_position(Vector3(10.0, -4320.426 + 1428.991, 0.0))
                    process_in_air_position_last_frame = global_position
            elif Game.difficulty == Game.game_difficulty.NightmareInverted:
                if event.keycode == KEY_F1:
                    set_global_position(Vector3(28.0, -852, -4.3))
                    process_in_air_position_last_frame = global_position
            elif Game.difficulty == Game.game_difficulty.ChallengeInverted:
                if event.keycode == KEY_F1:
                    set_global_position(Vector3(-55.0, -1534.057, 9.3))
                    process_in_air_position_last_frame = global_position


func _input(event: InputEvent) -> void :
    if Dialogic.current_timeline == null:
        if grapple_claw_is_enabled and event.is_action_pressed("ioa_hook"):
            if not GameSettings.config.get_value("input", "hook_toggle_mode", false):
                set_climber_state(ClimberState_Throw.new())
            else:
                if not activeClimberState == defaultClimberState:
                    set_climber_state(defaultClimberState)
                else:
                    set_climber_state(ClimberState_Throw.new())


    if event.is_action_released("ioa_hook") and not GameSettings.config.get_value("input", "hook_toggle_mode", false):
        set_climber_state(defaultClimberState)

func has_actionable_available() -> bool:
    var actions: = actionable_finder.get_overlapping_areas()
    return actions.size() > 0 and not actions[0].auto_trigger and time_since_actionable_triggered > min_delay_for_triggering_actionable

func get_actionable() -> Actionable:
    var actions: = actionable_finder.get_overlapping_areas()
    if actions.size() > 0:
        return (actions[0] as Node3D) as Actionable
    else:
        return null

func _process(delta: float) -> void :
    if activeClimberState:
        activeClimberState._process(delta)

    time_since_actionable_triggered += delta

    if time_since_actionable_triggered > min_delay_for_triggering_actionable and Dialogic.current_timeline == null and not ending_should_trigger_next_step_on_next_collision:
        var actionables: Array[Area3D] = actionable_finder.get_overlapping_areas()
        if actionables.size() > 0:
            if actionables[0].auto_trigger or Input.is_action_just_pressed("ioa_Activate"):
                actionables[0].action()
                time_since_actionable_triggered = 0.0





func updateFootsteps() -> void :
    if not injured_state:

        var ray = PhysicsRayQueryParameters3D.create(global_position, global_position - Vector3.UP * 6.0)
        var results = get_world_3d().direct_space_state.intersect_ray(ray)

        if results.size() > 0:
            var collider: StaticBody3D = results["collider"] as StaticBody3D
            if is_instance_valid(collider) and collider.physics_material_override != null:
                setFootstepPhysicsMaterialPath(collider.physics_material_override.resource_path)
            else:
                setFootstepPhysicsMaterialPath("default")

        var velocity_length = velocity.length()
        var msDelayForFootsteps = round(2500.0 / velocity_length)

        if (is_on_floor() && Time.get_ticks_msec() - lastMsPlayedFootstep > msDelayForFootsteps):
            lastMsPlayedFootstep = Time.get_ticks_msec()

            var footstep_volume: float = math_helpers.clamp01(velocity_length * 0.01)

            match (currentFootstepPhysicsMaterialPath):
                "res://physics_materials/Sand.tres":
                    Game.audio.play_sfx_sand_footstep(footstep_volume)
                _:
                    Game.audio.play_sfx_normal_footstep(footstep_volume)
    else:
        var velocity_length = velocity.length()
        Game.audio.request_crawling_sfx(velocity_length)

func _physics_process(delta: float) -> void :
    super (delta)

    if not is_inside_tree():
        return

    if is_on_floor():
        last_grounded_frames_ago = 0
    else:
        last_grounded_frames_ago += 1


    AirVelocity.y = clamp(AirVelocity.y, - TerminalVelocity, TerminalVelocity)


    var inputGlobalMovementVector: = PlayerFunctions.GetGlobalMovementVector(Camera) * WalkSpeed * WalkSpeedMultiplier

    var should_sprint: bool = Input.is_action_pressed("ioa_sprint")
    if GameSettings.config.get_value("input", "sprint_by_default", false):
        should_sprint = not should_sprint

    if is_on_floor() and sprint_is_enabled and should_sprint:
        inputGlobalMovementVector *= 2.0




    if ending_should_trigger_next_step_on_next_collision:
        rope_swish_for_ending.global_rotation = Vector3(0.0, Time.get_ticks_msec() * 0.005, 0.0)

    if Dialogic.current_timeline:
        inputGlobalMovementVector = Vector3.ZERO

    if activeClimberState:
        activeClimberState._physics_process(delta, inputGlobalMovementVector)

    if additional_velocity_next_frame.length_squared() > 0.01:
        velocity += additional_velocity_next_frame
        additional_velocity_next_frame *= 0.96

    LastVelocity = velocity
    stair_step_up(delta)
    last_processed_move_result = move_and_slide()
    if last_processed_move_result:

        var deltaVelocity: Vector3 = velocity - physics_process_velocity_last_frame
        if deltaVelocity.dot(physics_process_velocity_last_frame) < 0.0:
            var deltaVelocityMagnitude: float = deltaVelocity.length()
            if (deltaVelocityMagnitude > 4.0):
                if (deltaVelocityMagnitude > minDecelerationForDamage):
                    take_damage(5.0 * (deltaVelocityMagnitude - minDecelerationForDamage))
                else:
                    Game.audio.play_small_bump(deltaVelocityMagnitude * 0.01, currentFootstepPhysicsMaterialPath)

        last_y_velocity_on_last_processed_move_result = velocity.y

        if ending_should_trigger_next_step_on_next_collision:
            ending_should_trigger_next_step_on_next_collision = false

            time_since_actionable_triggered = 0.0
            ending_cut()

    physics_process_position_last_frame = global_position
    physics_process_velocity_last_frame = velocity

    updateFootsteps()

func processOnGround(delta: float, movementVector: Vector3) -> void :
    AirVelocity.y = velocity.y
    AirVelocity.x = movementVector.x
    AirVelocity.z = movementVector.z


    if jump_is_enabled and Input.is_action_just_pressed("ioa_jump"):
        AirVelocity.y += 9.0

    AirVelocity.y = clampf(AirVelocity.y - GravityAcceleration, - TerminalVelocity, TerminalVelocity)

    velocity = AirVelocity


func setFootstepPhysicsMaterialPath(path: String) -> void :
    currentFootstepPhysicsMaterialPath = path

var process_in_air_position_last_frame: Vector3
var process_in_air_position_last_frame_count: int

var physics_process_position_last_frame: Vector3
var physics_process_velocity_last_frame: Vector3

func processInAir(delta: float, movementVector: Vector3, gravity_force_enabled: bool) -> void :
    var calculated_velocity_last_frame: Vector3 = AirVelocity


    if Engine.get_physics_frames() == process_in_air_position_last_frame_count + 1:
        var delta_position_last_frame: Vector3 = global_position - process_in_air_position_last_frame
        calculated_velocity_last_frame = delta_position_last_frame / delta

    if AirVelocity.y < -5.0:

        var max_velocity = calculated_velocity_last_frame.y - 9.0
        if AirVelocity.y < max_velocity:
            AirVelocity.y = max_velocity
            OnscreenMessage.display("limiting airvelocity.y to %f" % max_velocity)

    AirVelocity.x = lerp(AirVelocity.x, 0.0, delta * 0.33)
    AirVelocity.z = lerp(AirVelocity.z, 0.0, delta * 0.33)


    movementVector *= AirControl


    if gravity_force_enabled:
        AirVelocity.y -= GravityAcceleration


    velocity = movementVector + AirVelocity

    process_in_air_position_last_frame = global_position
    process_in_air_position_last_frame_count = Engine.get_physics_frames()


















func is_rope_active() -> bool:
    return activeClimberState.is_rope_active()

func was_recently_sliding_down_rope() -> bool:
    return Time.get_ticks_msec() - last_sliding_down_rope_ms < 20

func was_recently_climbing_up_rope() -> bool:
    return Time.get_ticks_msec() - last_climbing_up_rope_ms < 20

func get_current_stress_level() -> float:
    var creature_dist: float = 9999.9

    for centipede in Game.centipedes:
        if centipede and centipede.is_inside_tree():
            creature_dist = min(creature_dist, centipede.global_position.distance_to(global_position))

    var stress_level: float = 5.0 / creature_dist
    stress_level += AirVelocity.length() * 0.05

    if Time.get_ticks_msec() < last_high_damage_taken_ms + 3000:
        stress_level = 1.0

    if injured_state:
        stress_level += 0.5

    return math_helpers.clamp01(stress_level)

func enter_slowed_state():
    grapple_claw_is_enabled = false
    WalkSpeed *= 0.2
    jump_is_enabled = false
    sprint_is_enabled = false

func enter_injured_state():
    enter_slowed_state()
    injured_state = true
    PlayerCamera.position -= Vector3.UP

func enter_ending_state():

    if activeClimberState is ClimberState_Attached:
        Game.audio.play_rope_snap_sfx()
        var rope_swish = get_node("%Rope_Swish")
        var rope_swish_animation = get_node("%Rope_Swish/AnimationPlayer") as AnimationPlayer
        rope_swish.visible = true
        rope_swish_animation.play("Animation")
        var rope_swish2_animation = rope_swish_for_ending.get_node("AnimationPlayer") as AnimationPlayer
        rope_swish_for_ending.visible = true
        rope_swish2_animation.play("Animation")
    grapple_claw_is_enabled = false
    prevent_player_death = true
    ending_should_trigger_next_step_on_next_collision = true
    set_climber_state(defaultClimberState)
    PlayerCamera.set_look_at_target(get_node("%LookAtHoleNode"), 1.5)

func ending_cut():
    player_audio_enabled = false
    hud.set_to_black()
    PlayerCamera.LookAtOverrideNode = null

    await get_tree().process_frame

    var rope_fallen = get_node("%Rope_Fallen")
    rope_fallen.visible = true

    var new_player_transform = get_node("%BottomEndingPlayerNode").global_transform
    teleport_to_location(new_player_transform.origin)
    global_rotation = Vector3.ZERO
    PlayerCamera.set_camera_rotation(new_player_transform.basis.get_rotation_quaternion().get_euler())
    enter_injured_state()

    await get_tree().create_timer(4.0).timeout
    cut_from_black()
    Game.audio.start_ending_music()

    var rope_swish = get_node("%Rope_Swish")
    rope_swish.visible = false
    rope_swish_for_ending.visible = false

func cut_from_black():
    Game.audio.play_big_breath()
    await get_tree().create_timer(0.66).timeout
    hud.unset_to_black()
    player_audio_enabled = true

func teleport_to_location(location: Vector3):
    global_position = location
    process_in_air_position_last_frame = global_position

func took_lethal_damage() -> void :
    if not prevent_player_death and not SceneLoader.is_transitioning():
        super ()

func save_to_save_data(sgd: SaveGameData):
    sgd.position = global_position
    sgd.rotation = global_rotation
    sgd.health = health

func load_from_save_data(sgd: SaveGameData):
    global_position = sgd.position
    if not sgd.version or sgd.version == 0:
        global_position += Vector3.UP * 854.536
    process_in_air_position_last_frame = global_position
    global_rotation = sgd.rotation






























func stair_step_up(delta: float) -> void :
    if last_grounded_frames_ago >= 4: return
    var _horizontal: = Vector3(1, 0, 1)

    var _step_height: = 0.15
    var testing_velocity: = velocity * _horizontal

    if testing_velocity == Vector3.ZERO:
        return

    var result = PhysicsTestMotionResult3D.new()
    var parameters = PhysicsTestMotionParameters3D.new()
    parameters.margin = 0.001


    var motion_transform = global_transform


    var distance = testing_velocity * delta
    parameters.from = motion_transform
    parameters.motion = distance


    if PhysicsServer3D.body_test_motion(get_rid(), parameters, result) == false:

        return


    var remainder = result.get_remainder()
    motion_transform = motion_transform.translated(result.get_travel())


    var step_up = _step_height * Vector3.UP
    parameters.from = motion_transform
    parameters.motion = step_up
    PhysicsServer3D.body_test_motion(get_rid(), parameters, result)

    motion_transform = motion_transform.translated(result.get_travel())
    var step_up_distance = result.get_travel().length()


    parameters.from = motion_transform
    parameters.motion = remainder
    PhysicsServer3D.body_test_motion(get_rid(), parameters, result)
    motion_transform = motion_transform.translated(result.get_travel())


    parameters.from = motion_transform;

    parameters.motion = Vector3.DOWN * step_up_distance


    if PhysicsServer3D.body_test_motion(get_rid(), parameters, result) == false:
        return

    motion_transform = motion_transform.translated(result.get_travel())

    var surfaceNormal = result.get_collision_normal(0)
    if (surfaceNormal.angle_to(Vector3.UP) > floor_max_angle * 1.2):
        OnscreenMessage.display("normal surface failed walkable check")
        return


    global_position.y = motion_transform.origin.y
