extends CanvasLayer

var on_confirmed: Callable
var on_cancelled: Callable

func _ready() -> void:
	if Globals.instance and Globals.instance.ui_theme:
		get_node("%Window").theme = Globals.instance.ui_theme
	
	get_node("%YesButton").pressed.connect(func(): on_confirmed.call() if on_confirmed else null)
	get_node("%NoButton").pressed.connect(func(): on_cancelled.call() if on_cancelled else null)

func set_message(message: String) -> void:
	get_node("%MessageLabel").text = message
