extends VBoxContainer

@onready var _title: Label = $TitleLabel
@onready var _desc: Label = $DescLabel

func setup(title: String, description: String, unlocked: bool) -> void:
	_title.text = ("✓  " if unlocked else "✗  ") + title
	_desc.text = description
	modulate = Color(1, 1, 1, 1) if unlocked else Color(0.45, 0.45, 0.45, 1)
