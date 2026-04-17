extends Node

func _init():
    var mods_path = OS.get_executable_path().get_base_dir() + "/mods"
    var dir = DirAccess.open(mods_path)
    if not dir:
        return
    dir.list_dir_begin()
    var folder_name = dir.get_next()
    while folder_name != "":
        if dir.current_is_dir() and not folder_name.begins_with("."):
            var mod_folder = mods_path + "/" + folder_name
            var mod_dir = DirAccess.open(mod_folder)
            if mod_dir:
                mod_dir.list_dir_begin()
                var file_name = mod_dir.get_next()
                while file_name != "":
                    if file_name.ends_with(".pck"):
                        ProjectSettings.load_resource_pack(mod_folder + "/" + file_name)
                    file_name = mod_dir.get_next()
        folder_name = dir.get_next()
