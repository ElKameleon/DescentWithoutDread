extends "res://scripts/settings_ui.gd"

var peaceful_mode: CheckBox
var peaceful_mode_label: Label
var _peaceful_injected := false

func setupUI() -> void:
    if not _peaceful_injected:
        _peaceful_injected = true

        await get_tree().process_frame

        $MarginContainer/VBoxContainer.add_theme_constant_override("separation", 10)
        $MarginContainer/VBoxContainer/VideoContainer/GridContainer2.add_theme_constant_override("v_separation", -4)
        $MarginContainer/VBoxContainer/AudioContainer.add_theme_constant_override("separation", 0)
        $MarginContainer/VBoxContainer/AccessContainer/GridContainer3.add_theme_constant_override("v_separation", -4)

        var grid = $MarginContainer/VBoxContainer/AccessContainer/GridContainer3
        var label = Label.new()
        label.text = "Peaceful Mode"
        peaceful_mode_label = label

        var checkbox = CheckBox.new()
        peaceful_mode = checkbox

        grid.add_child(label)
        grid.add_child(checkbox)

        var main_theme = load("res://ui/main_theme.tres")
        label.theme = main_theme
        checkbox.theme = main_theme
        checkbox.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

        peaceful_mode.toggled.connect(func(_value): onUIChangedValue())

    super()

    if is_instance_valid(peaceful_mode):
        peaceful_mode.set_pressed_no_signal(GameSettings.config.get_value("game", "peaceful_mode", false))

        var in_level = _is_in_level()
        var dim_color = Color(1, 1, 1, 0.4) if in_level else Color.WHITE

        peaceful_mode.modulate = dim_color
        if is_instance_valid(peaceful_mode_label):
            peaceful_mode_label.modulate = dim_color

        peaceful_mode.mouse_filter = Control.MOUSE_FILTER_IGNORE if in_level else Control.MOUSE_FILTER_STOP
        peaceful_mode.focus_mode = Control.FOCUS_NONE if in_level else Control.FOCUS_ALL

func _is_in_level() -> bool:
    return Game.climber != null and is_instance_valid(Game.climber)

func onUIChangedValue() -> void:
    if _is_in_level():
        peaceful_mode.set_pressed_no_signal(GameSettings.config.get_value("game", "peaceful_mode", false))
    else:
        GameSettings.config.set_value("game", "peaceful_mode", peaceful_mode.button_pressed)
    super()
