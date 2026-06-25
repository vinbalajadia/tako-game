extends Button

# Signal emitted when the button is pressed
signal hint_requested

func _ready() -> void:
	text = "Hint" # Default text, user can customize
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	hint_requested.emit()
