extends Node

var MOD_DIR: String

const SPRITE_OFFSET_Y = 0.0
const SPRITE_SIZE = 3.0

var _current_scene_path := ""
var _last_climber_instance: Node = null
var _applied := false
var _last_arachnophobia_state := false
var _last_bio_lum_state := false
var _last_centipede_count := 0


func _process(_delta: float) -> void:
    var scene = get_tree().current_scene
    if scene == null:
        return
    var path = scene.scene_file_path

    var climber_changed = Game.climber != _last_climber_instance
    var path_changed = path != _current_scene_path

    if path_changed or climber_changed:
        _current_scene_path = path
        _last_climber_instance = Game.climber
        _applied = false
        _last_centipede_count = 0

        if is_instance_valid(Game.climber):
            get_tree().create_timer(0.5).timeout.connect(_try_replace_centipedes.bind(scene))

    var arachnophobia_on = GameSettings.config.get_value("game", "arachnophobia_mode", false)
    if arachnophobia_on != _last_arachnophobia_state:
        _last_arachnophobia_state = arachnophobia_on

    var bio_lum = GameSettings.config.get_value("game", "bio_lum_monster_enabled", false)
    if bio_lum != _last_bio_lum_state:
        _last_bio_lum_state = bio_lum
        if _applied and arachnophobia_on:
            _update_sprite_textures(bio_lum)

    # Watch for newly spawned centipedes
    if _applied and arachnophobia_on and is_instance_valid(Game.climber):
        var current_count = Game.centipedes.size()
        if current_count > _last_centipede_count:
            _last_centipede_count = current_count
            for centipede in Game.centipedes:
                if not centipede.find_child("ArachnoSprite", true, false):
                    _hide_meshes(centipede)
                    _replace_audio(centipede)
                    _add_sprite(centipede)
                    OnscreenMessage.display(centipede.name + " replaced!")


func _try_replace_centipedes(scene: Node) -> void:
    if not GameSettings.config.get_value("game", "arachnophobia_mode", false):
        return
    if _applied:
        return

    var centipedes = scene.find_children("Centipede*", "", true, false)
    for centipede in centipedes:
        if "_pathfinder" in centipede:
            _hide_meshes(centipede)
            _replace_audio(centipede)
            _add_sprite(centipede)
            OnscreenMessage.display(centipede.name + " replaced!")

    _last_bio_lum_state = GameSettings.config.get_value("game", "bio_lum_monster_enabled", false)
    _last_centipede_count = Game.centipedes.size()
    _applied = true


func _update_sprite_textures(bio_lum: bool) -> void:
    for centipede in Game.centipedes:
        var sprite = centipede.find_child("ArachnoSprite", true, false)
        if sprite and sprite is MeshInstance3D:
            var mat = sprite.material_override as StandardMaterial3D
            if mat:
                _apply_bio_lum_to_material(mat, bio_lum)


func _hide_meshes(centipede: Node) -> void:
    var meshes = centipede.find_children("*", "MeshInstance3D", true, false)
    for mesh in meshes:
        mesh.visible = false


func _replace_audio(centipede: Node) -> void:
    var meow = load(MOD_DIR + "/sfx/cat_meow.wav")
    var hiss = load(MOD_DIR + "/sfx/cat_hiss.wav")

    var mappings = {
        "IdleSFX": meow,
        "RoarWanderSFX": meow,
        "HuntingSFX": meow,
        "AttackSFX": hiss,
        "ChompSFX": hiss,
    }

    for node_name in mappings:
        var node = centipede.find_child(node_name, true, false)
        if node and mappings[node_name]:
            node.stream = mappings[node_name]
            node.volume_db = 0.0
        elif node:
            node.volume_db = -80.0

    var all_audio = centipede.find_children("*", "AudioStreamPlayer3D", true, false)
    for audio in all_audio:
        if audio.name not in mappings:
            audio.volume_db = -80.0


func _add_sprite(centipede: Node) -> void:
    if centipede.find_child("ArachnoSprite", true, false):
        return

    var albedo = load(MOD_DIR + "/Art/cat.png")
    if not albedo:
        OnscreenMessage.display("Arachnophobia: missing cat.png, using fallback")
        _add_fallback(centipede)
        return

    var bio_lum = GameSettings.config.get_value("game", "bio_lum_monster_enabled", false)

    var mat := StandardMaterial3D.new()
    mat.albedo_texture = albedo
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
    _apply_bio_lum_to_material(mat, bio_lum)

    var quad := QuadMesh.new()
    quad.size = Vector2(SPRITE_SIZE, SPRITE_SIZE)

    var mesh_instance := MeshInstance3D.new()
    mesh_instance.name = "ArachnoSprite"
    mesh_instance.position = Vector3(0.0, SPRITE_OFFSET_Y, 0.0)
    mesh_instance.mesh = quad
    mesh_instance.material_override = mat

    centipede.add_child(mesh_instance)


func _apply_bio_lum_to_material(mat: StandardMaterial3D, bio_lum: bool) -> void:
    if bio_lum:
        var glow_tex = load(MOD_DIR + "/Art/cat_glow.png")
        if glow_tex:
            mat.emission_enabled = true
            mat.emission_texture = glow_tex
            mat.emission_energy_multiplier = 2.0
            return
    mat.emission_enabled = false
    mat.emission_texture = null
    mat.emission_energy_multiplier = 0.0


func _add_fallback(centipede: Node) -> void:
    var mesh_instance := MeshInstance3D.new()
    mesh_instance.name = "ArachnoSprite"
    mesh_instance.position = Vector3(0.0, SPRITE_OFFSET_Y, 0.0)

    var quad := QuadMesh.new()
    quad.size = Vector2(SPRITE_SIZE, SPRITE_SIZE)
    mesh_instance.mesh = quad

    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(1.0, 0.8, 0.0)
    mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
    mesh_instance.material_override = mat

    centipede.add_child(mesh_instance)
