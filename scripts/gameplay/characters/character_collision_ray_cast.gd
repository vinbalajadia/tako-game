class_name CharacterCollisionRayCast
extends RayCast2D

signal collision_detected(collided: bool)

@export_category("Collision Vars")
@export var character_input: CharacterInput
var collider: Object

func _ready() -> void:
	GameLogger.info("Loading character collision ray cast component ...")
	enabled = true
	# Make the raycast reliably detect TileMap collisions regardless of editor defaults.
	collide_with_bodies = true
	collide_with_areas = true
	hit_from_inside = true
	# Default mask in scenes is easy to accidentally misconfigure; allow all by default.
	collision_mask = 0xFFFFFFFF

func _physics_process(_delta: float) -> void:
	if character_input == null:
		return

	# Always cast exactly one grid cell ahead of the current facing direction.
	var dir: Vector2 = character_input.direction
	if dir != Vector2.ZERO:
		target_position = dir * Globals.grid_size
		force_raycast_update()

	if is_colliding():
		collider = get_collider()
		collision_detected.emit(true)
	else:
		collision_detected.emit(false)
