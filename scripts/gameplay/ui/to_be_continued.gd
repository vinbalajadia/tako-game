extends CanvasLayer

@export var display_duration: float = 3.0

func show_and_wait() -> void:
	await get_tree().create_timer(display_duration).timeout
