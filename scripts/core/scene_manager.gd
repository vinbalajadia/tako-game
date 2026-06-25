extends Node
# Autoload: SceneManager

var is_changing: bool = false
var is_battling: bool = false
var is_enemy_approaching: bool = false
var battle_enemy: Node
var current_level: Node2D
var all_levels: Array[Node2D] = []
var fade_rect: ColorRect

func _ready() -> void:
	GameLogger.info("Loading scene manager ...")
	
	fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	canvas.add_child(fade_rect)
	add_child(canvas)
	
	call_deferred("_try_dev_boot")

func _try_dev_boot() -> void:
	if GameManager.instance != null:
		return

	var current_scene := get_tree().current_scene
	if current_scene == null:
		return

	var scene_path: String = current_scene.scene_file_path
	var scene_name: String = scene_path.get_file().get_basename().to_lower()
	var level_names: Array = Enums.LevelName.keys()
	var level_index: int = -1
	for index in range(level_names.size()):
		if str(level_names[index]).to_lower() == scene_name:
			level_index = index
			break
	if level_index < 0:
		return

	current_scene.queue_free()
	GameManager.is_dev_boot = true
	GameManager.dev_boot_level = level_index
	get_tree().root.add_child(load("res://scenes/core/game_manager.tscn").instantiate())

func set_enemy_approaching(value: bool) -> void:
	is_enemy_approaching = value

func change_level(level_name: int = Enums.LevelName.Level0, trigger: int = 0, tile_offset: int = 0, spawn: bool = false) -> void:
	if is_changing:
		return

	is_changing = true
	await get_level(level_name)
	AudioManager.play_music_for_level(str(current_level.name))

	var player = GameManager.get_player()
	var characters: Node2D = get_character_container(current_level)
	if player != null and characters != null and player.get_parent() != characters:
		player.reparent(characters)

	if spawn:
		spawn_player()
	else:
		switch_player(trigger, tile_offset)

	await fade_in()
	is_changing = false
	var pos = player.global_position if player != null else Vector2.ZERO
	PlayerDataManager.save_progress(Enums.LevelName.keys()[level_name], pos)

	var spawn_dialogue = current_level.get("spawn_dialogue")
	if spawn_dialogue != null and (spawn_dialogue as Array).size() > 0:
		var intro_id := "spawn_" + str(current_level.name)
		if not PlayerDataManager.triggered_dialogues.has(intro_id):
			PlayerDataManager.mark_dialogue_triggered(intro_id)
			await DialogueManager.show(spawn_dialogue)

func get_level(level_name: int) -> void:
	await fade_out()
	await get_tree().process_frame

	var viewport: SubViewport = GameManager.get_game_view_port()
	if viewport == null:
		push_error("GameManager.GameViewPort is not assigned.")
		return

	var player = GameManager.get_player()
	if current_level != null:
		if player != null and player.get_parent() != viewport:
			player.reparent(viewport)
		viewport.remove_child(current_level)

	var level_key: String = Enums.LevelName.keys()[level_name]
	current_level = null
	for level in all_levels:
		if level.name == level_key:
			current_level = level
			break

	if current_level == null:
		var scene: PackedScene = load("res://scenes/levels/%s.tscn" % level_key.to_lower())
		current_level = scene.instantiate()
		current_level.name = level_key
		all_levels.append(current_level)

	viewport.add_child(current_level)
	viewport.move_child(current_level, 0)

func get_character_container(level: Node2D) -> Node2D:
	if level == null:
		return null
	var node: Node2D = level.get_node_or_null("Characters")
	if node == null:
		node = level.get_node_or_null("Enemies")
	if node != null:
		node.y_sort_enabled = true
	return node

func spawn_player() -> void:
	if current_level == null:
		return

	var spawn_points: Array = current_level.get_tree().get_nodes_in_group(Enums.LevelGroup.keys()[Enums.LevelGroup.SPAWNPOINTS])
	if spawn_points.is_empty():
		push_error("Missing spawn point(s)!")
		return

	var player_scene: PackedScene = load("res://scenes/characters/%s.tscn" % Globals.selected_character)
	var player: Node2D = player_scene.instantiate()
	GameManager.add_player(player)
	if PlayerDataManager.last_position != Vector2.ZERO:
		player.global_position = PlayerDataManager.last_position
	else:
		player.global_position = spawn_points[0].global_position

func switch_player(trigger: int, tile_offset: int = 0) -> void:
	if current_level == null:
		return

	var triggers: Array = current_level.get_tree().get_nodes_in_group(Enums.LevelGroup.keys()[Enums.LevelGroup.SCENETRIGGERS])
	var scene_trigger: SceneTrigger = null
	for candidate in triggers:
		if candidate is SceneTrigger and candidate.current_level_trigger == trigger:
			scene_trigger = candidate
			break
	if scene_trigger == null:
		push_error("Missing scene trigger with trigger id %s!" % trigger)
		return

	var player = GameManager.get_player()
	if player == null:
		return

	var perp: Vector2 = Vector2(tile_offset * Globals.grid_size, 0) if scene_trigger.entry_direction.y != 0 else Vector2(0, tile_offset * Globals.grid_size)
	player.global_position = scene_trigger.global_position + perp + scene_trigger.entry_direction * Globals.grid_size

	var input: CharacterInput = player.get_node_or_null("Input")
	if input != null and scene_trigger.entry_direction != Vector2.ZERO:
		input.direction = scene_trigger.entry_direction
		
		var animation: CharacterAnimation = player.get_node_or_null("AnimatedSprite2D")
		if animation != null:
			animation._play_animation("idle")

func clear_game() -> void:
	is_changing = false
	is_battling = false
	is_enemy_approaching = false
	battle_enemy = null

	if GameManager.instance != null:
		var canvas := GameManager.instance.get_node_or_null("BattleCanvas")
		if canvas != null:
			canvas.queue_free()

	DialogueManager.cancel()

	for level in all_levels:
		if is_instance_valid(level):
			level.queue_free()
	all_levels.clear()
	current_level = null
	if fade_rect != null:
		fade_rect.color = Color(0, 0, 0, 0)

func start_battle(enemy: Node) -> void:
	if is_changing or is_battling:
		return
	battle_enemy = enemy
	is_battling = true
	is_enemy_approaching = false
	AudioManager.play_music("battle")

	await fade_out()

	if GameManager.instance == null:
		push_error("Cannot start battle without an active GameManager scene.")
		is_battling = false
		return

	var canvas := CanvasLayer.new()
	canvas.layer = 5
	canvas.name = "BattleCanvas"
	GameManager.instance.add_child(canvas)

	var battle = load("res://scenes/gameplay/battle_scene.tscn").instantiate()
	canvas.add_child(battle)

	await fade_in()

func end_battle() -> void:
	if not is_battling:
		return
	is_enemy_approaching = false

	await fade_out()

	if GameManager.instance != null:
		var canvas := GameManager.instance.get_node_or_null("BattleCanvas")
		if canvas != null:
			canvas.queue_free()

	var enemy := battle_enemy
	var is_final := false
	var is_level_boss := false
	if enemy != null:
		var enemy_id: String = str(enemy.get("enemy_id"))
		is_final = enemy.get("is_final_boss") == true
		is_level_boss = enemy.get("is_level_boss") == true
		if not enemy_id.is_empty() and not is_final:
			Globals.defeated_enemies[enemy_id] = true
			PlayerDataManager.mark_enemy_defeated(enemy_id)
		if is_final:
			Globals.final_boss_defeated = true

	if is_level_boss and not is_final:
		_award_level_achievement()

	if not is_final and enemy != null:
		enemy.queue_free()
	battle_enemy = null
	is_battling = false

	await fade_in()
	AudioManager.play_music_for_level(str(current_level.name) if current_level != null else "")

	var player_node = GameManager.get_player()
	if player_node != null and current_level != null:
		PlayerDataManager.save_progress(str(current_level.name), player_node.global_position)

	if is_final and is_instance_valid(enemy):
		await _show_final_boss_ending(enemy, is_level_boss)

func _award_level_achievement() -> void:
	if current_level == null:
		return
	PlayerDataManager.unlock_achievement(str(current_level.name).to_lower() + "_complete")

func _show_final_boss_ending(enemy: Node, award_level: bool = false) -> void:
	if award_level:
		_award_level_achievement()
	PlayerDataManager.unlock_achievement("final_boss_complete")

	var defeat_dialogue = enemy.get("defeat_dialogue")
	if defeat_dialogue != null and (defeat_dialogue as Array).size() > 0:
		await DialogueManager.show(defeat_dialogue)

	await fade_out()

	var screen = load("res://scenes/ui/to_be_continued.tscn").instantiate()
	add_child(screen)
	await screen.show_and_wait()
	screen.queue_free()

	GameManager.return_to_main_menu()

func fade_out() -> void:
	if fade_rect == null:
		return
	var tween: Tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 0.25)
	await tween.finished

func fade_in() -> void:
	if fade_rect == null:
		return
	var tween: Tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, 0.25)
	await tween.finished
