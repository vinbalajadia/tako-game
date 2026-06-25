extends Node
# Autoload: ApiClient
#
# All communication with the ODIN backend goes through here.
# Set base_url before the game starts, or inject it from the web page (see _get_base_url).
#
# Request flow:  caller → _enqueue() → _flush() → HTTPRequest → _on_request_completed()
# Requests are processed one at a time; extras wait in _queue.

signal submission_completed(data: Dictionary)
signal session_created(data: Dictionary)
signal request_failed(tag: String, http_code: int)
signal puzzle_fetched(data: Dictionary)

var base_url: String = ""

var _http: HTTPRequest
var _queue: Array[Dictionary] = []
var _busy: bool = false
var _current_tag: String = ""
var _jwt_token: String = ""

func _ready() -> void:
	base_url = _get_base_url()
	PlayerDataManager.user_id = _get_user_id()
	_jwt_token = _get_jwt_token()

	_http = HTTPRequest.new()
	_http.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)

	GameLogger.info("ApiClient ready — base_url: %s  user_id: %s  auth: %s" % [
		base_url,
		PlayerDataManager.user_id,
		"token present" if not _jwt_token.is_empty() else "no token (local dev)",
	])

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

func post_submission(payload: Dictionary) -> void:
	_enqueue(HTTPClient.METHOD_POST, "/api/submission", payload, "submission")

func post_session_start(payload: Dictionary) -> void:
	_enqueue(HTTPClient.METHOD_POST, "/api/session", payload, "session_start")

func patch_session_end(session_id: String) -> void:
	_enqueue(HTTPClient.METHOD_PATCH, "/api/session/" + session_id + "/end", {}, "session_patch_end")

func post_session_end_telemetry(payload: Dictionary) -> void:
	_enqueue(HTTPClient.METHOD_POST, "/api/submission", payload, "session_end_telemetry")

func get_puzzle(puzzle_id: String) -> void:
	_enqueue(HTTPClient.METHOD_GET, "/api/puzzle/" + puzzle_id, {}, "puzzle_fetch")

func get_game_state() -> void:
	var uid := PlayerDataManager.user_id
	if uid.is_empty() or uid == "local_dev":
		return
	_enqueue(HTTPClient.METHOD_GET, "/api/player/" + uid + "/gamestate", {}, "game_state_load")

func put_game_state(gs_data: Dictionary) -> void:
	var uid := PlayerDataManager.user_id
	if uid.is_empty() or uid == "local_dev":
		return
	_enqueue(HTTPClient.METHOD_PUT, "/api/player/" + uid + "/gamestate",
			{"data": JSON.stringify(gs_data)}, "game_state_save")

# ---------------------------------------------------------------------------
# Internal queue
# ---------------------------------------------------------------------------

func _enqueue(method: int, endpoint: String, payload: Dictionary, tag: String) -> void:
	_queue.append({"method": method, "endpoint": endpoint, "payload": payload, "tag": tag})
	if not _busy:
		_flush()

func _flush() -> void:
	if _queue.is_empty():
		_busy = false
		return
	_busy = true
	var req: Dictionary = _queue.pop_front()
	_current_tag = req.tag

	var body := "" if req.method == HTTPClient.METHOD_GET else JSON.stringify(req.payload)
	var headers: PackedStringArray = ["Content-Type: application/json", "Accept: application/json"]
	if not _jwt_token.is_empty():
		headers.append("Authorization: Bearer " + _jwt_token)
	var err := _http.request(base_url + req.endpoint, headers, req.method, body)
	if err != OK:
		GameLogger.error("ApiClient: request error %d for [%s] %s" % [err, req.tag, req.endpoint])
		request_failed.emit(_current_tag, err)
		_busy = false
		_flush()

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var tag := _current_tag
	_current_tag = ""
	_busy = false

	if result != HTTPRequest.RESULT_SUCCESS:
		GameLogger.error("ApiClient: HTTP result=%d code=%d tag=%s" % [result, response_code, tag])
		request_failed.emit(tag, response_code)
		_flush()
		return

	if response_code < 200 or response_code >= 300:
		var err_text := body.get_string_from_utf8()
		GameLogger.error("ApiClient: HTTP %d for tag=%s — body: %s" % [response_code, tag, err_text])
		request_failed.emit(tag, response_code)
		_flush()
		return

	var text := body.get_string_from_utf8()
	var json := JSON.new()
	if json.parse(text) != OK:
		GameLogger.error("ApiClient: JSON parse failed for tag=%s — body: %s" % [tag, text])
		request_failed.emit(tag, response_code)
		_flush()
		return

	var data: Dictionary = json.data if json.data is Dictionary else {}
	GameLogger.info("ApiClient: response tag=%s code=%d" % [tag, response_code])

	match tag:
		"submission":
			submission_completed.emit(data)
			if OS.has_feature("web"):
				var achievements: Array = data.get("newAchievements", [])
				if achievements is Array and not achievements.is_empty():
					JavaScriptBridge.eval(
						"window.parent.postMessage({type:'odin_achievements_unlocked',achievements:%s},'*');" % JSON.stringify(achievements)
					)
		"session_start":
			session_created.emit(data)
			if OS.has_feature("web"):
				var sid := str(data.get("id", ""))
				if not sid.is_empty():
					JavaScriptBridge.eval(
						"window.parent.postMessage({type:'odin_session_started',sessionId:'%s'},'*');" % sid
					)
		"puzzle_fetch":
			puzzle_fetched.emit(data)
		"session_end_telemetry":
			pass
		"game_state_load":
			var raw := str(data.get("gameState", "{}"))
			var json2 := JSON.new()
			if json2.parse(raw) == OK and json2.data is Dictionary:
				var gs: Dictionary = json2.data
				# Empty state means an admin reset occurred — wipe local save and signal the menu
				if gs.is_empty():
					PlayerDataManager.reset_to_defaults()
				else:
					var achiev: Array[String] = []
					for a in gs.get("achievements", []):
						achiev.append(str(a))
					var dialogues: Array[String] = []
					for d in gs.get("triggered_dialogues", []):
						dialogues.append(str(d))
					PlayerDataManager.set_from_server(
						true,
						gs.get("player_name", PlayerDataManager.player_name),
						gs.get("selected_character", PlayerDataManager.selected_character),
						achiev,
						gs.get("last_level", PlayerDataManager.last_level_name),
						Vector2(gs.get("last_position_x", 0.0), gs.get("last_position_y", 0.0)),
						dialogues
					)
					PlayerDataManager.defeated_enemies.clear()
					Globals.defeated_enemies.clear()
					for e in gs.get("defeated_enemies", []):
						PlayerDataManager.defeated_enemies.append(str(e))
						Globals.defeated_enemies[str(e)] = true
					PlayerDataManager.apply_audio_settings(gs)

	_flush()

# ---------------------------------------------------------------------------
# URL / credential resolution
# ---------------------------------------------------------------------------

# In web builds, the HTML page injects the server URL:
#   <script>window.ODIN_API_URL = "https://api.yourserver.com";</script>
func _get_base_url() -> String:
	if OS.has_feature("web"):
		var js_url = JavaScriptBridge.eval("(window.parent.__ODIN_GAME_CONFIG?.apiUrl) || window.ODIN_API_URL || ''")
		if typeof(js_url) == TYPE_STRING and not (js_url as String).is_empty():
			return js_url
	return "http://localhost:5000"

func _get_user_id() -> String:
	if OS.has_feature("web"):
		var js_id = JavaScriptBridge.eval("(window.parent.__ODIN_GAME_CONFIG?.userId) || window.ODIN_USER_ID || ''")
		if typeof(js_id) == TYPE_STRING and not (js_id as String).is_empty():
			return js_id
	return "local_dev"

func _get_jwt_token() -> String:
	if OS.has_feature("web"):
		var js_token = JavaScriptBridge.eval("(window.parent.__ODIN_GAME_CONFIG?.token) || window.ODIN_JWT_TOKEN || ''")
		if typeof(js_token) == TYPE_STRING and not (js_token as String).is_empty():
			return js_token
	return ""
