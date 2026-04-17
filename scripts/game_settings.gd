extends Node

const SETTINGS_FILE_PATH: String = "user://settings.cfg"
var config: ConfigFile
var config_file_version: int = 1

var game_sfx_fade_amount: float = 1.0


var window_size_options_display_text: Array[String]
var windowSizeValueBySelectorIndex: Array[Vector2i]

func _init():
    window_size_options_display_text.append("1280 x 720")
    windowSizeValueBySelectorIndex.append(Vector2i(1280, 720))
    window_size_options_display_text.append("1920 x 1080")
    windowSizeValueBySelectorIndex.append(Vector2i(1920, 1080))
    window_size_options_display_text.append("2560 x 1440")
    windowSizeValueBySelectorIndex.append(Vector2i(2560, 1440))
    window_size_options_display_text.append("3840 x 2160")
    windowSizeValueBySelectorIndex.append(Vector2i(3840, 2160))

    config = ConfigFile.new()

    if config.load(SETTINGS_FILE_PATH) != OK:
        resetConfig()

func _ready():
    process_mode = Node.PROCESS_MODE_ALWAYS
    apply()

func _process(delta: float):
    game_sfx_fade_amount = lerp(game_sfx_fade_amount, 1.0 if not SceneLoader.was_transitioning_recently() else 0.0, clamp(delta * 2.5, 0, 1))

    AudioServer.set_bus_volume_linear(1, config.get_value("game", "volume", 0.5) * game_sfx_fade_amount)

func resetConfig():
    config = ConfigFile.new()


    config.set_value("game", "volume", 0.5)
    config.set_value("video", "window_mode", 1)
    config.set_value("video", "vsync", 0)
    config.set_value("video", "volumetric_fog_enabled", true)
    config.set_value("game", "bio_lum_monster_enabled", false)
    config.set_value("game", "reduced_pixelization", false)
    config.set_value("game", "ashen_hook_enabled", false)
    config.set_value("input", "invert_y_input", false)
    config.set_value("input", "sensitivity", 0.5)
    config.set_value("input", "sprint_by_default", false)
    config.set_value("input", "hook_toggle_mode", false)
    saveConfig()

func applyAndSaveConfig():
    saveConfig()
    apply()

func saveConfig():
    config.set_value("version", "file_version", config_file_version)
    config.save(SETTINGS_FILE_PATH)

func apply():
    if not OS.has_feature("editor"):

        var window_mode = config.get_value("video", "window_mode", 1)
        match (window_mode):
            0:
                get_window().mode = Window.MODE_WINDOWED
                var windowSize = config.get_value("video", "window_size", -1)
                if windowSize != -1:
                    get_window().size = windowSizeValueBySelectorIndex[windowSize]
            1:
                get_window().mode = Window.MODE_FULLSCREEN
            2:
                get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN


    DisplayServer.window_set_vsync_mode(config.get_value("video", "vsync", 0))

    apply_material_pixelization_mode_to_materials()

func apply_material_pixelization_mode_to_materials():
    var use_reduced_pixelization: bool = config.get_value("video", "reduced_pixelization", false)

    var pixelization_materials: Array[StandardMaterial3D] = [load("res://Art/Textures/Wall_04.tres"), load("res://Art/Textures/Rock_01.tres")]
    for p_mat in pixelization_materials:
        p_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR if use_reduced_pixelization else BaseMaterial3D.TEXTURE_FILTER_NEAREST

    var sand_pixelization_materials: Array[StandardMaterial3D] = [load("res://Art/Textures/Sand.tres"), load("res://Art/Textures/Sand2.tres")]
    for p_mat in sand_pixelization_materials:
        p_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR if use_reduced_pixelization else BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
