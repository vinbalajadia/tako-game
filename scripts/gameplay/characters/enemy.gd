class_name Enemy
extends CharacterBody2D

@export_category("Enemy AI")
@export var enemy_id: String = ""
@export var initial_facing: Enums.FacingDirection = Enums.FacingDirection.Down
@export var vision_range: int = 5
@export var alert_duration: float = 0.8

@export_category("Sprite")
@export var custom_frames: SpriteFrames

var vision_direction: Vector2 = Vector2.DOWN

@export_category("Battle")
@export var skill_type: Enums.SkillType = Enums.SkillType.BasicArithmetic

@export_category("Dialogue")
@export var battle_dialogue: Array[DialogueEntry] = []
@export var defeat_dialogue: Array[DialogueEntry] = []
@export var post_defeat_dialogue: Array[DialogueEntry] = []

@export_category("Boss")
@export var is_level_boss: bool = false
@export var is_final_boss: bool = false
@export var player_m_boss_frames: SpriteFrames
@export var player_f_boss_frames: SpriteFrames

var state_machine: StateMachine

func _ready() -> void:
	if enemy_id != "" and Globals.defeated_enemies.has(enemy_id):
		queue_free()
		return

	match initial_facing:
		Enums.FacingDirection.Up:
			vision_direction = Vector2.UP
		Enums.FacingDirection.Left:
			vision_direction = Vector2.LEFT
		Enums.FacingDirection.Right:
			vision_direction = Vector2.RIGHT
		_:
			vision_direction = Vector2.DOWN

	state_machine = get_node("StateMachine")

	if custom_frames != null:
		get_node("AnimatedSprite2D").sprite_frames = custom_frames
	elif is_final_boss:
		_apply_boss_sprites()

	state_machine.change_state("Idle")

func _apply_boss_sprites() -> void:
	# Intentionally swapped: female boss frames shown for male player and vice versa.
	var frames: SpriteFrames = player_f_boss_frames if Globals.selected_character == "playerm" \
		else player_m_boss_frames
	if frames != null:
		get_node("AnimatedSprite2D").sprite_frames = frames
