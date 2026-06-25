extends CanvasLayer

signal resumed
signal main_menu_requested

var is_from_main_menu: bool = false

func _ready() -> void:
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
	
	music_slider.value_changed.connect(func(v): _set_bus_volume("Music", v))
	sfx_slider.value_changed.connect(func(v): _set_bus_volume("SFX", v))
	fullscreen_toggle.toggled.connect(func(on): DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED))
	
	_populate_badges()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		resumed.emit()

func _set_bus_volume(bus_name: String, linear: float) -> void:
	var idx = AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(linear))

func _populate_badges() -> void:
	var container = get_node("%BadgeContainer")
	var badges = PlayerDataManager.badges
	
	if badges.is_empty():
		var empty = Label.new()
		empty.text = "No badges yet."
		container.add_child(empty)
		return
	
	for badge in badges:
		var label = Label.new()
		label.text = badge
		container.add_child(label)
