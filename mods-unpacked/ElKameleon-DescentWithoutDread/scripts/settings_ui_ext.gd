extends "res://scripts/settings_ui.gd"

var arachnophobia_mode: CheckBox
var arachnophobia_mode_label: Label
var _injected := false

func setupUI() -> void:
    if not _injected:
        _injected = true

        await get_tree().process_frame

        $MarginContainer/VBoxContainer.add_theme_constant_override("separation", 10)
        $MarginContainer/VBoxContainer/VideoContainer/GridContainer2.add_theme_constant_override("v_separation", -4)
        $MarginContainer/VBoxContainer/AudioContainer.add_theme_constant_override("separation", 0)
        $MarginContainer/VBoxContainer/AccessContainer/GridContainer3.add_theme_constant_override("v_separation", -4)

        var grid = $MarginContainer/VBoxContainer/AccessContainer/GridContainer3
        var main_theme = load("res://ui/main_theme.tres")

        # Arachnophobia Mode
        var a_label = Label.new()
        a_label.text = "Arachnophobia Mode"
        arachnophobia_mode_label = a_label

        var a_checkbox = CheckBox.new()
        arachnophobia_mode = a_checkbox

        grid.add_child(a_label)
        grid.add_child(a_checkbox)

        a_label.theme = main_theme
        a_checkbox.theme = main_theme
        a_checkbox.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
        arachnophobia_mode.toggled.connect(func(_value): onUIChangedValue())

    super()

    var in_level = _is_in_level()
    var dim_color = Color(1, 1, 1, 0.4) if in_level else Color.WHITE

    if is_instance_valid(arachnophobia_mode):
        arachnophobia_mode.set_pressed_no_signal(GameSettings.config.get_value("game", "arachnophobia_mode", false))
        arachnophobia_mode.modulate = dim_color
        if is_instance_valid(arachnophobia_mode_label):
            arachnophobia_mode_label.modulate = dim_color
        arachnophobia_mode.mouse_filter = Control.MOUSE_FILTER_IGNORE if in_level else Control.MOUSE_FILTER_STOP
        arachnophobia_mode.focus_mode = Control.FOCUS_NONE if in_level else Control.FOCUS_ALL

func _is_in_level() -> bool:
    return Game.climber != null and is_instance_valid(Game.climber)

func onUIChangedValue() -> void:
    if _is_in_level():
        arachnophobia_mode.set_pressed_no_signal(GameSettings.config.get_value("game", "arachnophobia_mode", false))
    else:
        GameSettings.config.set_value("game", "arachnophobia_mode", arachnophobia_mode.button_pressed)
    super()
