extends Node
# Autoload: Globals

@export_category("Gameplay")
@export var grid_size: int = 16
@export var walk_speed: float = 12.0
@export var run_speed: float = 18.0

@export_category("UI")
@export var ui_theme: Theme

@export_category("Session")
@export var selected_character: String = "playerm"

# HashSet<string> → Dictionary with dummy values for O(1) has().
var defeated_enemies: Dictionary = {}
var triggered_dialogues: Dictionary = {}
var final_boss_defeated: bool = false
var instance: Node

func _ready() -> void:
	instance = self
	GameLogger.info("Loading Globals ...")
