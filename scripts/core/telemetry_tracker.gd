extends Node
class_name TelemetryTracker

var time_since_last_submit: float = 0.0
var inactivity_duration: float = 0.0
var hint_requests_timestamps: Array[float] = []
var error_log: Array[Dictionary] = []

func _process(delta: float) -> void:
	time_since_last_submit += delta
	inactivity_duration += delta

func _input(event: InputEvent) -> void:
	# Reset inactivity on GUI input events (keystrokes, mouse clicks)
	if event is InputEventKey or event is InputEventMouseButton:
		inactivity_duration = 0.0

func on_compile_submit() -> void:
	# Reset timers on submit
	time_since_last_submit = 0.0
	inactivity_duration = 0.0

func on_hint_requested() -> void:
	hint_requests_timestamps.append(Time.get_unix_time_from_system())

func on_compilation_failed(error_message: String, code_state: String) -> void:
	error_log.append({
		"category": "SyntaxError",
		"message": error_message,
		"timestamp": Time.get_datetime_string_from_system(),
		"codeStateAtError": code_state
	})

func get_hint_requests_within_60s() -> int:
	var current_time = Time.get_unix_time_from_system()
	var recent_count = 0
	for ts in hint_requests_timestamps:
		if current_time - ts <= 60.0:
			recent_count += 1
	return recent_count

func get_telemetry_payload(is_paste_event: bool, is_successful_compile: bool, current_code: String) -> Dictionary:
	var error_log_mapped = []
	for err in error_log:
		error_log_mapped.append({
			"category": err.get("category", "SyntaxError"),
			"message": err.get("message", "")
		})
	
	# The generated dictionary matches the KeystrokePayload exactly
	var keystroke_data = {
		"averageFlightTimeMs": 0.0,
		"averageDwellTimeMs": 0.0,
		"initialLatencyMs": 0.0,
		"totalTimeSeconds": 0.0,
		"rawEvents": [],
		"pasteDetected": is_paste_event,
		"inactivityDuration": inactivity_duration,
		"timeSinceLastSubmit": time_since_last_submit,
		"errorLog": error_log_mapped,
		"isFirstSubmission": false,
		"typingBurstCoverage": 0.0,
		"selfCorrectionCount": 0,
		"systemCheckCount": 0,
		"postErrorInactivitySeconds": -1.0,
		"keyDownCount": 0,
		"taskBypassedDuration": null # Optional float
	}
	
	# Structure representing the full SubmissionRequest DTO
	var payload = {
		# These IDs should be filled by the parent script before sending
		"playerId": "",
		"sessionId": "",
		"puzzleId": "",
		"skillType": "",
		"sourceCode": current_code,
		"keystrokeData": keystroke_data,
		"hintUsageCount": get_hint_requests_within_60s(),
		"isHintRequest": false,
		"isSessionEndTelemetry": false
	}
	
	return payload
