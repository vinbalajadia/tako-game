extends Node
# Autoload: AudioManager

const SETTINGS_PATH: String = "user://settings.json"

const _MUSIC: Dictionary = {
	"indoor":   "res://assets/audio/music/indoor.ogg",
	"outdoors": "res://assets/audio/music/outdoors.ogg",
	"mainmenu": "res://assets/audio/music/mainmenu.ogg",
	"battle":   "res://assets/audio/music/battle.ogg",
}

const _SFX: Dictionary = {
	"buttonclick": "res://assets/audio/sfx/buttonclick.mp3",
}

const _OUTDOOR_LEVELS: Array = ["Level11", "Level12"]

const FADE_DURATION: float = 1.0

var _music_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer
var _current_music: String = ""
var _fade_tween: Tween = null

func _ready() -> void:
	_ensure_buses()
	_load_settings()

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_music_player)

	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.bus = "SFX"
	_sfx_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_sfx_player)

	get_tree().node_added.connect(_on_node_added)
	call_deferred("_scan_existing_buttons", get_tree().root)

func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		_connect_button(node)

func _connect_button(button: BaseButton) -> void:
	if button.has_meta("_sfx_connected"):
		return
	button.set_meta("_sfx_connected", true)
	button.pressed.connect(func(): play_sfx("buttonclick"))

func _scan_existing_buttons(node: Node) -> void:
	if node is BaseButton:
		_connect_button(node)
	for child in node.get_children():
		_scan_existing_buttons(child)

func play_music(track: String) -> void:
	if _current_music == track and _music_player.playing:
		return
	_current_music = track
	if _fade_tween != null:
		_fade_tween.kill()
	_fade_tween = create_tween()
	if _music_player.playing:
		_fade_tween.tween_property(_music_player, "volume_db", -80.0, FADE_DURATION)
	_fade_tween.tween_callback(func():
		var stream: AudioStream = load(_MUSIC[track])
		stream.set("loop", true)
		_music_player.stream = stream
		_music_player.volume_db = 0.0  # Start at full volume — no fade-in
		_music_player.play()
	)

func play_music_for_level(level_name: String) -> void:
	if level_name.is_empty():
		return
	if level_name in _OUTDOOR_LEVELS:
		play_music("outdoors")
	else:
		play_music("indoor")

func stop_music() -> void:
	_current_music = ""
	if _fade_tween != null:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(_music_player, "volume_db", -80.0, FADE_DURATION)
	_fade_tween.tween_callback(_music_player.stop)

func play_sfx(sfx: String) -> void:
	_sfx_player.stream = load(_SFX[sfx])
	_sfx_player.play()

func _ensure_buses() -> void:
	if AudioServer.get_bus_index("Music") < 0:
		var idx := AudioServer.get_bus_count()
		AudioServer.add_bus()
		AudioServer.set_bus_name(idx, "Music")
		AudioServer.set_bus_volume_db(idx, linear_to_db(0.5))
	if AudioServer.get_bus_index("SFX") < 0:
		var idx := AudioServer.get_bus_count()
		AudioServer.add_bus()
		AudioServer.set_bus_name(idx, "SFX")
		AudioServer.set_bus_volume_db(idx, linear_to_db(0.5))

func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.ModeFlags.READ)
	if file == null:
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK or not json.data is Dictionary:
		return
	var s: Dictionary = json.data
	var music_bus := AudioServer.get_bus_index("Music")
	var sfx_bus   := AudioServer.get_bus_index("SFX")
	if music_bus >= 0:
		AudioServer.set_bus_volume_db(music_bus, linear_to_db(s.get("music_volume", 0.5)))
		AudioServer.set_bus_mute(music_bus, s.get("music_muted", false))
	if sfx_bus >= 0:
		AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(s.get("sfx_volume", 0.5)))
		AudioServer.set_bus_mute(sfx_bus, s.get("sfx_muted", false))

func save_settings() -> void:
	var music_bus := AudioServer.get_bus_index("Music")
	var sfx_bus   := AudioServer.get_bus_index("SFX")
	var s := {
		"music_volume": db_to_linear(AudioServer.get_bus_volume_db(music_bus)) if music_bus >= 0 else 0.5,
		"music_muted":  AudioServer.is_bus_mute(music_bus) if music_bus >= 0 else false,
		"sfx_volume":   db_to_linear(AudioServer.get_bus_volume_db(sfx_bus)) if sfx_bus >= 0 else 0.5,
		"sfx_muted":    AudioServer.is_bus_mute(sfx_bus) if sfx_bus >= 0 else false,
	}
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.ModeFlags.WRITE)
	if file != null:
		file.store_string(JSON.stringify(s))
