class_name BattleMetrics
extends RefCounted

const BURST_GAP_MS := 450.0

var _load_time_ms: float = 0.0
var _first_key_time_ms: float = -1.0
var _last_key_up_ms: float = -1.0
var _dwell_times: Array[float] = []
var _flight_times: Array[float] = []
var _key_down_times: Dictionary = {}
var _raw_events: Array = []

func start() -> void:
	_load_time_ms = float(Time.get_ticks_msec())

func record_key_down(keycode: int) -> void:
	var now := float(Time.get_ticks_msec())
	if _first_key_time_ms < 0.0:
		_first_key_time_ms = now
	if _last_key_up_ms >= 0.0:
		_flight_times.append(now - _last_key_up_ms)
	_key_down_times[keycode] = now
	_raw_events.append([int(now), keycode, 0])

func record_key_up(keycode: int) -> void:
	var now := float(Time.get_ticks_msec())
	_last_key_up_ms = now
	if keycode in _key_down_times:
		_dwell_times.append(now - float(_key_down_times[keycode]))
		_key_down_times.erase(keycode)
	_raw_events.append([int(now), keycode, 1])

func collect(starter_text: String, source_text: String, paste_detected: bool) -> Dictionary:
	var now := float(Time.get_ticks_msec())
	var burst := _typing_burst_coverage(_raw_events, source_text, starter_text)
	var self_corr := _self_correction_count(_raw_events)
	var key_downs := _key_down_count(_raw_events)
	var result := {
		"avg_flight_time_ms":    _avg(_flight_times),
		"avg_dwell_time_ms":     _avg(_dwell_times),
		"initial_latency_ms":    (_first_key_time_ms - _load_time_ms) if _first_key_time_ms >= 0.0 else -1.0,
		"total_time_seconds":    (now - _load_time_ms) / 1000.0,
		"paste_detected":        paste_detected,
		"typingBurstCoverage":   burst,
		"selfCorrectionCount":   self_corr,
		"systemCheckCount":      0,
		"keyDownCount":          key_downs,
	}
	result["raw_events"] = _raw_events.duplicate()
	# Reset per-attempt buffers so next submission reflects only that attempt's keystrokes.
	_dwell_times.clear()
	_flight_times.clear()
	_raw_events.clear()
	_first_key_time_ms = -1.0
	_last_key_up_ms    = -1.0
	_load_time_ms      = now
	return result

func _typing_burst_coverage(raw: Array, source: String, starter: String) -> float:
	if raw.is_empty():
		return 0.0
	var max_burst := 0
	var cur_burst := 0
	var last_t := -1.0
	for ev in raw:
		if not (ev is Array):
			continue
		var arr: Array = ev
		if arr.size() < 3:
			continue
		var t := float(arr[0])
		var phase := int(arr[2])
		if last_t >= 0.0 and (t - last_t) > BURST_GAP_MS:
			max_burst = maxi(max_burst, cur_burst)
			cur_burst = 0
		if phase == 0:
			cur_burst += 1
		last_t = t
	max_burst = maxi(max_burst, cur_burst)
	var denom := maxi(maxi(source.length(), starter.length()), 1)
	return clampf(float(max_burst) / float(denom), 0.0, 1.0)

func _self_correction_count(raw: Array) -> int:
	var n := 0
	for ev in raw:
		if not (ev is Array):
			continue
		var arr: Array = ev
		if arr.size() < 3 or int(arr[2]) != 0:
			continue
		var k := int(arr[1])
		if k == KEY_BACKSPACE or k == KEY_DELETE:
			n += 1
	return n

func _key_down_count(raw: Array) -> int:
	var n := 0
	for ev in raw:
		if not (ev is Array):
			continue
		var arr: Array = ev
		if arr.size() >= 3 and int(arr[2]) == 0:
			n += 1
	return n

# Levenshtein distance between two strings (used for edit_distance metric).
static func levenshtein(a: String, b: String) -> int:
	var m := a.length()
	var n := b.length()
	if m == 0: return n
	if n == 0: return m
	var prev: Array = []
	prev.resize(n + 1)
	for j in range(n + 1):
		prev[j] = j
	for i in range(1, m + 1):
		var curr: Array = []
		curr.resize(n + 1)
		curr[0] = i
		for j in range(1, n + 1):
			curr[j] = prev[j - 1] if a[i - 1] == b[j - 1] else 1 + mini(prev[j], mini(curr[j - 1], prev[j - 1]))
		prev = curr
	return prev[n]

static func _avg(arr: Array[float]) -> float:
	if arr.is_empty():
		return 0.0
	var total := 0.0
	for v in arr:
		total += v
	return total / float(arr.size())
