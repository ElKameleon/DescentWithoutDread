extends Node

const DATA_FILE_PATH: String = "user://player_data.cfg"
var config: ConfigFile
var config_file_version: int = 2

func _init():
    config = ConfigFile.new()

    if config.load(DATA_FILE_PATH) != OK:
        resetConfig()


    if config.get_value("version", "file_version") < 2:
        if config.get_value("unlocked", "difficulty", 0) == 2:
            config.set_value("unlocked", "difficulty", 3)
            saveConfig()

func resetConfig():
    config = ConfigFile.new()


    config.set_value("death", "count", 0)
    config.set_value("unlocked", "difficulty", 0)
    saveConfig()

func saveConfig():
    config.set_value("version", "file_version", config_file_version)
    config.save(DATA_FILE_PATH)

func reset_player_death_count():
    config.set_value("death", "count", 0)
    saveConfig()

func on_player_has_died():
    var death_count: int = config.get_value("death", "count", 0)
    config.set_value("death", "count", death_count + 1)
    saveConfig()

func get_death_count() -> int:
    return config.get_value("death", "count", 0)
