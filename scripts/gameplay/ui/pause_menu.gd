extends CanvasLayer

signal resumed
signal main_menu_requested

var is_from_main_menu: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if Globals.instance and Globals.instance.ui_theme:
		get_node("%Window").theme = Globals.instance.ui_theme
	
	var resume_btn = get_node("%ResumeButton")
	var main_menu_btn = get_node("%MainMenuButton")
	
	if is_from_main_menu:
		resume_btn.text = "Close"
		main_menu_btn.visible = false
	
	resume_btn.pressed.connect(func(): resumed.emit())
	main_menu_btn.pressed.connect(func(): main_menu_requested.emit())
	
	var music_slider = get_node("%MusicSlider")
	var sfx_slider = get_node("%SFXSlider")
	var fullscreen_toggle = get_node("%FullscreenToggle")
	
	var music_bus = AudioServer.get_bus_index("Music")
	var sfx_bus = AudioServer.get_bus_index("SFX")
	
	music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(music_bus)) if music_bus >= 0 else 1.0
	sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_bus)) if sfx_bus >= 0 else 1.0
	fullscreen_toggle.button_pressed = DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
	
	music_slider.value_changed.connect(func(v): _set_bus_volume("Music", v); AudioManager.save_settings())
	sfx_slider.value_changed.connect(func(v): _set_bus_volume("SFX", v); AudioManager.save_settings())
	fullscreen_toggle.toggled.connect(func(on): DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED))
	
	_populate_achievements()

func _set_bus_volume(bus_name: String, linear: float) -> void:
	var idx = AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(linear))

func _populate_achievements() -> void:
	var container = get_node("%AchievementsContainer")
	var entry_scene: PackedScene = preload("res://scenes/ui/achievement_entry.tscn")
	for entry in PlayerDataManager.ACHIEVEMENTS:
		var id: String = entry["id"]
		var unlocked: bool = id in PlayerDataManager.achievements
		var row = entry_scene.instantiate()
		container.add_child(row)
		row.setup(entry["title"], entry["description"], unlocked)
		container.add_child(HSeparator.new())
