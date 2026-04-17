class_name HUD extends CanvasLayer

@export var healthBar: ProgressBar
@export var slackLabel: Label
@export var slackCircle: TextureRect
@export var slackCircleHook: TextureRect
@export var fade_layer: CanvasLayer
@export var blackRect: ColorRect
@export var actionable_ui: Control
@export var actionable_label: Label
@export var _ending_text: ending_text
@export var controls_hint_root: Control
@export var damage_effects_root: Control

@export var damage_effect_hands_ms_duration: int = 200
@export var damage_effect_hands_ms_offset: int = 800
@export var damage_effect_hands_cycle_speed: float = 1.0
@export var damage_effect_hands_fade_based_on_damage_factor: float = 1.0

@export var game_saved_message: Label
var last_saved_ms: int = -9999

@export var healed_message: Label
var last_healed_ms: int = -9999

var damage_effect_hands: Array[TextureRect]

var pause_menu: Node

var slackCircle_material: ShaderMaterial

var climber: Climber

var override_to_full_back: bool = false

func _ready() -> void :
    climber = get_parent() as Climber
    fade_layer.visible = true
    process_mode = PROCESS_MODE_ALWAYS
    slackCircle_material = slackCircle.material as ShaderMaterial

    for dmg_effect in damage_effects_root.get_children():
        if dmg_effect is TextureRect:
            damage_effect_hands.append(dmg_effect as TextureRect)

func _physics_process(delta: float) -> void :
    var target_color_for_black_rect: Color = Color.BLACK * 0.0
    if Dialogic.current_timeline:
        target_color_for_black_rect = Color.BLACK * 0.95
    if override_to_full_back:
        target_color_for_black_rect = Color.BLACK
    blackRect.modulate = lerp(blackRect.modulate, target_color_for_black_rect, 3.3 * delta)

func _input(event: InputEvent) -> void :
    if event.is_action_pressed("ioa_escape"):
        toggle_pause_menu()

func toggle_pause_menu():
    if not pause_menu:
        pause_menu = load("res://scenes/pause_menu_ui.tscn").instantiate()
        add_child(pause_menu)
    else:
        pause_menu.queue_free()

func _process(delta: float) -> void :
    actionable_ui.modulate = lerp(actionable_ui.modulate, Color.WHITE if climber.has_actionable_available() and Dialogic.current_timeline == null else Color.WHITE * 0.0, delta * 3.0)

    var climber_actionable: = climber.get_actionable()
    if climber_actionable:
        actionable_label.text = climber_actionable.displayed_action_text

    slackCircle.visible = climber.grapple_claw_is_enabled

    if Time.get_ticks_msec() > last_saved_ms + 3000:
        game_saved_message.modulate = lerp(game_saved_message.modulate, Color.WHITE * 0.0, 3.3 * delta)
    if Time.get_ticks_msec() > last_healed_ms + 3000:
        healed_message.modulate = lerp(healed_message.modulate, Color.WHITE * 0.0, 3.3 * delta)

    healthBar.value = climber.health / climber.healthMax
    if climber.Rope:
        slackCircleHook.modulate = Color.RED if climber.Rope._claw.visible else Color.DARK_RED
        var slack_percent: float = clampf(climber.activeClimberState.get_slack_length() / climber.Rope._settings.ropeLengthMax, 0.0, 1.0)
        slackCircle_material.set_shader_parameter("percent", slack_percent if climber.Rope._claw.visible else 1.0)

    var target_hint_set_to_display: ControlHintSet
    if Time.get_ticks_msec() < last_ms_control_hint_set_request + 1000:
        target_hint_set_to_display = last_control_hint_set_requested

    if target_hint_set_to_display != active_control_hint_set:
        controls_hint_root.modulate = lerp(controls_hint_root.modulate, Color.WHITE * 0.0, delta * 3.3)
        if controls_hint_root.modulate.a < 0.001:
            active_control_hint_set = target_hint_set_to_display
            for chld in controls_hint_root.get_children():
                chld.queue_free()
            if active_control_hint_set:
                active_control_hint_set.setup_control_hint_uis(self)
    elif active_control_hint_set:
        controls_hint_root.modulate = lerp(controls_hint_root.modulate, Color.WHITE, delta * 3.3)

    var show_damage_effect: bool = Time.get_ticks_msec() < climber.last_damage_taken_ms + damage_effect_hands_ms_duration
    for dmg_eff_hand_index in damage_effect_hands.size():
        damage_effect_hands[dmg_eff_hand_index].visible = show_damage_effect
        damage_effect_hands[dmg_eff_hand_index].modulate = Color.RED * sin((dmg_eff_hand_index * damage_effect_hands_ms_offset + Time.get_ticks_msec()) * 0.02 * damage_effect_hands_cycle_speed) * clamp(climber.recent_damage_buffer * 0.02 * damage_effect_hands_fade_based_on_damage_factor, 0.1, 1.0)

var active_control_hint_set: ControlHintSet
var last_control_hint_set_requested: ControlHintSet
var last_ms_control_hint_set_request: int

func request_controls_hints_display(control_hint_set: ControlHintSet):
    last_ms_control_hint_set_request = Time.get_ticks_msec()
    last_control_hint_set_requested = control_hint_set

func set_to_black():
    blackRect.modulate = Color.BLACK
    override_to_full_back = true

func unset_to_black():
    blackRect.modulate = Color.BLACK * 0.0
    override_to_full_back = false

func request_text_display(text_display_area: ending_text_display_area):
    _ending_text.request_text_display(text_display_area.displayed_text)

func on_game_saved():
    await get_tree().create_timer(0.5).timeout
    while (Dialogic.current_timeline):
        await get_tree().process_frame
    game_saved_message.modulate = Color.WHITE
    last_saved_ms = Time.get_ticks_msec()

func on_game_healed():
    healed_message.modulate = Color.WHITE
    last_healed_ms = Time.get_ticks_msec()
