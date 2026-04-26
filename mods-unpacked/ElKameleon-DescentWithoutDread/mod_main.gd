extends Node
const ELKAMELEON_DESCENTWITHOUTDREAD_DIR := "ElKameleon-DescentWithoutDread"
const ELKAMELEON_DESCENTWITHOUTDREAD_LOG_NAME := "ElKameleon-DescentWithoutDread:Main"
var mod_dir_path := ""
func _init() -> void:
    mod_dir_path = ModLoaderMod.get_unpacked_dir().path_join(ELKAMELEON_DESCENTWITHOUTDREAD_DIR)
    ModLoaderMod.install_script_extension(mod_dir_path.path_join("scripts/settings_ui_ext.gd"))
func _ready() -> void:
    var waypoint_manager = load(mod_dir_path.path_join("scripts/waypoint_manager.gd")).new()
    waypoint_manager.MOD_DIR = mod_dir_path
    get_tree().root.call_deferred("add_child", waypoint_manager)
    var arachnophobia_manager = load(mod_dir_path.path_join("scripts/arachnophobia_manager.gd")).new()
    arachnophobia_manager.MOD_DIR = mod_dir_path
    get_tree().root.call_deferred("add_child", arachnophobia_manager)
    var precision_hook = load(mod_dir_path.path_join("scripts/precision_hook.gd")).new()
    get_tree().root.call_deferred("add_child", precision_hook)
    ModLoaderLog.info("Ready!", ELKAMELEON_DESCENTWITHOUTDREAD_LOG_NAME)
