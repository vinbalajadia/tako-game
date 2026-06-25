extends Node
# Autoload: GameLogger

func _log_msg(level: int, message: Variant) -> void:
	var timestamp: String = Time.get_datetime_string_from_system()
	var level_name: String = Enums.LogLevel.keys()[level]
	var color: String = "CYAN"
	match level:
		Enums.LogLevel.DEBUG:   color = "WHITE"
		Enums.LogLevel.INFO:    color = "CYAN"
		Enums.LogLevel.WARNING: color = "YELLOW"
		Enums.LogLevel.ERROR:   color = "RED"
	print_rich("[color=%s][%s] [%s][/color] %s" % [color, timestamp, level_name, str(message)])

func debug(message: Variant) -> void:
	_log_msg(Enums.LogLevel.DEBUG, message)

func info(message: Variant) -> void:
	_log_msg(Enums.LogLevel.INFO, message)

func warning(message: Variant) -> void:
	_log_msg(Enums.LogLevel.WARNING, message)

func error(message: Variant) -> void:
	_log_msg(Enums.LogLevel.ERROR, message)
