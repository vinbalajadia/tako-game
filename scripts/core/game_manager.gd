extends Node
# Autoload: GameManager

@export_category("Nodes")
@export var GameViewPort: SubViewport
@export var InitialLevel: PackedScene
@export var settings_icon: Texture2D
@export_range(0.5, 3.0, 0.1) var settings_button_scale: float = 1.0

@export_category("Vars")
@export var player: Node

var instance: Node
var is_dev_boot: bool = false
var dev_boot_level: int = Enums.LevelName.Level0
var _pause_menu: Node
var _settings_layer: CanvasLayer
var _virtual_controls: Node
var _js_save_cb: JavaScriptObject

func _ready() -> void:
	if GameViewPort == null:
		return
	GameManager.instance = self
	GameLogger.info("Loading game manager ...")
	_setup_js_save_listener()

	if GameManager.is_dev_boot:
		GameManager.is_dev_boot = false
		var level: int = GameManager.dev_boot_level
		GameManager.dev_boot_level = Enums.LevelName.Level0
		if Globals.selected_character.is_empty():
			Globals.selected_character = "playerm"
		SceneManager.change_level(level, 0, 0, true)
		return

	PlayerDataManager.load_data()
	_create_settings_button()
	if OS.has_feature("web"):
		var saved: Variant = JavaScriptBridge.eval("localStorage.getItem('odin_character') || ''")
		if typeof(saved) == TYPE_STRING and not (saved as String).is_empty():
			Globals.selected_character = saved
	show_main_menu()

func show_main_menu() -> void:
	if _settings_layer != null:
		_settings_layer.visible = false
	AudioManager.play_music("mainmenu")
	var target = _target()
	if target.get_node_or_null("MainMenuLayer") != null:
		return

	var canvas: CanvasLayer = CanvasLayer.new()
	canvas.layer = 10
	canvas.name = "MainMenuLayer"
	target.add_child(canvas)

	var menu: Node = load("res://scenes/core/main_menu.tscn").instantiate()
	canvas.add_child(menu)
	menu.game_start_requested.connect(_on_game_start_requested)

func _on_game_start_requested(character: String) -> void:
	if _settings_layer != null:
		_settings_layer.visible = true
	var main_menu_layer: Node = _target().get_node_or_null("MainMenuLayer")
	if main_menu_layer != null:
		main_menu_layer.queue_free()

	Globals.selected_character = character

	_add_virtual_controls()

	var target_level: int = Enums.LevelName.Billiards
	if not PlayerDataManager.last_level_name.is_empty():
		var keys: Array = Enums.LevelName.keys()
		var saved_index: int = keys.find(PlayerDataManager.last_level_name)
		if saved_index >= 0:
			target_level = saved_index

	SceneManager.change_level(target_level, 0, 0, true)

func open_pause_menu() -> void:
	if _pause_menu != null:
		return
	var has_player: bool = get_player() != null
	if has_player:
		get_tree().paused = true
	if _settings_layer != null:
		_settings_layer.visible = false
	var scene: PackedScene = load("res://scenes/ui/pause_menu.tscn")
	_pause_menu = scene.instantiate()
	_pause_menu.is_from_main_menu = not has_player
	_target().add_child(_pause_menu)
	_pause_menu.resumed.connect(close_pause_menu)
	_pause_menu.main_menu_requested.connect(return_to_main_menu)

func close_pause_menu() -> void:
	get_tree().paused = false
	if _pause_menu != null:
		_pause_menu.queue_free()
	_pause_menu = null
	if _settings_layer != null:
		_settings_layer.visible = true

func return_to_main_menu() -> void:
	close_pause_menu()
	var current_player = get_player()
	if current_player != null and SceneManager.current_level != null:
		PlayerDataManager.save_progress(SceneManager.current_level.name, current_player.global_position)
	
	SceneManager.clear_game()
	var target = _target()
	if target.player != null:
		target.player.queue_free()
	target.player = null
	show_main_menu()

func get_player() -> Node:
	return _target().player

func set_player(new_player: Node) -> void:
	_target().player = new_player

func get_game_view_port() -> SubViewport:
	return _target().GameViewPort

func add_player(new_player: Node) -> Node:
	var characters: Node2D = SceneManager.get_character_container(SceneManager.current_level)
	if characters != null:
		characters.add_child(new_player)
	elif get_game_view_port() != null:
		get_game_view_port().add_child(new_player)
	set_player(new_player)
	return get_player()

func _add_virtual_controls() -> void:
	if _virtual_controls != null:
		return
	var vc_layer := CanvasLayer.new()
	vc_layer.name = "VirtualControls"
	vc_layer.set_script(load("res://scripts/ui/virtual_controls.gd"))
	_target().add_child(vc_layer)
	_virtual_controls = vc_layer

func _create_settings_button() -> void:
	_settings_layer = CanvasLayer.new()
	_settings_layer.layer = 25
	_settings_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	_settings_layer.visible = false
	_target().add_child(_settings_layer)

	var btn_size := 28.0 * settings_button_scale
	var btn: Button = Button.new()
	btn.expand_icon = true
	btn.custom_minimum_size = Vector2(btn_size, btn_size)
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	btn.position = Vector2(8, 8)
	btn.pressed.connect(open_pause_menu)
	if settings_icon != null:
		btn.icon = settings_icon
	else:
		btn.text = "⚙"
	_settings_layer.add_child(btn)
	btn.size = Vector2(btn_size, btn_size)

func _target():
	return GameManager.instance if GameManager.instance != null else self

func _setup_js_save_listener() -> void:
	if not OS.has_feature("web"):
		return
	_js_save_cb = JavaScriptBridge.create_callback(_on_js_save_requested)
	JavaScriptBridge.get_interface("window").odinSaveCb = _js_save_cb
	JavaScriptBridge.eval("""
		window.addEventListener('message', function(e) {
			if (e.data && e.data.type === 'odin_save_request') {
				window.odinSaveCb();
			}
		});
	""")

func _on_js_save_requested(_args: Array) -> void:
	var current_player = get_player()
	if current_player != null and SceneManager.current_level != null:
		PlayerDataManager.save_progress(str(SceneManager.current_level.name), current_player.global_position)
