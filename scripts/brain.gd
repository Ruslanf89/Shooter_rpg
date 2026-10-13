extends Node
## The game's link to the Northvale brain (brain/server.py, Python): AI personalities for the first
## location. Starts Ollama and the brain server, keeps an eye on them, and offers
## talk / bark / chat / event calls. Lines come back with a WAV file (Piper / Windows voices),
## which say_at() plays in 3D with a subtitle over the speaker's head.

signal status_changed(text: String)

const URL := "http://127.0.0.1:8765"
const AI_LEVELS := [0]          # locations that use the AI brains (Northvale for now)

var is_ready := false
var status := "Starting the AI brain..."
var _launched := false
var _ollama_launched := false
var _poll_t := 0.0
var _sent_lang := ""
var _sent_mode := ""
var _pid := -1
var _bark_cd := 0.0             # a little space between shouts so fights don't become a choir


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## True while playing a location that uses the AI brains.
func active() -> bool:
	return is_ready and Game.level_index in AI_LEVELS


func _process(delta: float) -> void:
	_bark_cd = maxf(0.0, _bark_cd - delta)
	_poll_t -= delta
	if _poll_t > 0.0:
		return
	_poll_t = 2.0 if is_ready else 1.0
	_poll()


func _set_status(text: String, ok: bool) -> void:
	if text != status or ok != is_ready:
		status = text
		is_ready = ok
		status_changed.emit(text)


var _polling := false


func _poll() -> void:
	if _polling:
		return
	_polling = true
	var h := await call_api("/health", null, 3.0)
	_polling = false
	if h.is_empty():
		if not _launched:
			_launch()
			_set_status(Loc.t("Starting the AI brain..."), false)
		elif not is_ready:
			_set_status(Loc.t("Waiting for the AI brain (Python)..."), false)
		return
	if not h.get("ollama", false):
		_start_ollama()
		_set_status(Loc.t("Waiting for Ollama..."), false)
		return
	if not h.get("model_installed", false):
		_set_status(Loc.t("The AI model %s is not installed (ollama pull %s)") % [h.get("model", ""), h.get("model", "")], false)
		return
	var lang := "uk" if Loc.is_uk() else "en"
	var mode := "play" if get_tree().current_scene and get_tree().current_scene.get("player") != null else "menu"
	if lang != _sent_lang or mode != _sent_mode:
		_sent_lang = lang
		_sent_mode = mode
		call_api("/config", {"lang": lang, "mode": mode})
	if not h.get("model_loaded", false):
		_set_status(Loc.t("Loading the AI model into memory..."), false)
		return
	_set_status(Loc.t("AI brain ready") + " (%s)" % h.get("model", ""), true)


# --------------------------------------------------------------------------- processes

func _brain_dir() -> String:
	if OS.has_feature("editor"):
		return ProjectSettings.globalize_path("res://brain")
	return OS.get_executable_path().get_base_dir().path_join("brain")


func _python() -> String:
	var local := OS.get_environment("LOCALAPPDATA").path_join("Programs/Python/Python312/python.exe")
	if FileAccess.file_exists(local):
		return local
	return "python"


func _launch() -> void:
	_launched = true
	_start_ollama()
	var script := _brain_dir().path_join("server.py")
	if not FileAccess.file_exists(script):
		_set_status(Loc.t("The AI brain is missing (brain/server.py)"), false)
		return
	_pid = OS.create_process(_python(), [script], false)


func _start_ollama() -> void:
	if _ollama_launched:
		return
	_ollama_launched = true
	var exe := OS.get_environment("LOCALAPPDATA").path_join("Programs/Ollama/ollama.exe")
	if FileAccess.file_exists(exe):
		OS.create_process(exe, ["serve"], false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		if _pid > 0:
			OS.kill(_pid)
			_pid = -1


# --------------------------------------------------------------------------- requests

## POST (or GET when data is null) to the brain; {} on any failure.
func call_api(path: String, data = null, timeout := 90.0) -> Dictionary:
	var http := HTTPRequest.new()
	http.timeout = timeout
	add_child(http)
	var body := "" if data == null else JSON.stringify(data)
	var err := http.request(URL + path, ["Content-Type: application/json"], HTTPClient.METHOD_GET if data == null else HTTPClient.METHOD_POST, body)
	if err != OK:
		http.queue_free()
		return {}
	var res: Array = await http.request_completed
	http.queue_free()
	if res[0] != HTTPRequest.RESULT_SUCCESS or res[1] != 200:
		return {}
	var d = JSON.parse_string((res[3] as PackedByteArray).get_string_from_utf8())
	return d if d is Dictionary else {}


## One dialogue turn. While the character "thinks", the game runs at 24 FPS (you're standing in
## a conversation anyway) so the AI gets most of the graphics card and answers much faster.
func talk(req: Dictionary) -> Dictionary:
	_think(1)
	var r := await call_api("/talk", req, 180.0)
	_think(-1)
	return r


var _thinking := 0
var _saved_fps := 0


func _think(d: int) -> void:
	if _thinking == 0 and d > 0:
		_saved_fps = Engine.max_fps
		Engine.max_fps = 24
	_thinking = maxi(0, _thinking + d)
	if _thinking == 0 and d < 0:
		Engine.max_fps = _saved_fps


func bark(kind: String, event: String) -> Dictionary:
	return await call_api("/bark", {"kind": kind, "event": event}, 5.0)


func chat(a: Dictionary, b: Dictionary, ctx: Dictionary) -> Dictionary:
	return await call_api("/chat", {"a": a, "b": b, "ctx": ctx}, 120.0)


## Something happened in the valley (kills, quests, crimes, raids...): fire and forget.
func event(kind: String, text := "", extra := {}) -> void:
	if not active():
		return
	var d := {"kind": kind, "text": text}
	d.merge(extra)
	call_api("/event", d, 10.0)


func new_world() -> void:
	if is_ready:
		call_api("/reset", {}, 10.0)


## May a mob shout right now? (one shout every couple of seconds at most)
func can_bark() -> bool:
	if not active() or _bark_cd > 0.0:
		return false
	_bark_cd = randf_range(1.6, 3.0)
	return true


# --------------------------------------------------------------------------- speech

func load_voice(path: String) -> AudioStream:
	if path == "" or not FileAccess.file_exists(path):
		return null
	return AudioStreamWAV.load_from_file(path)


## Plays a line on `node` in 3D with a subtitle over its head. Returns the line's length.
func say_at(node: Node3D, text: String, audio: String, height := 2.1, pitch := 1.0, colour := Color(1.0, 0.95, 0.8)) -> float:
	if not is_instance_valid(node) or text == "":
		return 0.0
	var dur := clampf(text.length() * 0.06, 1.5, 6.0)
	var stream := load_voice(audio)
	if stream:
		var p := AudioStreamPlayer3D.new()
		p.stream = stream
		p.bus = "SFX"
		p.unit_size = 7.0
		p.max_distance = 45.0
		p.volume_db = 4.0
		p.pitch_scale = pitch
		p.position.y = height - 0.3
		node.add_child(p)
		p.play()
		dur = stream.get_length() / pitch
		p.finished.connect(p.queue_free)
	var l := Label3D.new()
	l.text = text
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.fixed_size = true
	l.pixel_size = 0.0008
	l.font_size = 34
	l.outline_size = 9
	l.modulate = colour
	l.width = 900.0
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.position.y = height + 0.35
	l.no_depth_test = true
	l.visibility_range_end = 35.0
	node.add_child(l)
	var tw := l.create_tween()
	tw.tween_interval(dur + 0.8)
	tw.tween_property(l, "modulate:a", 0.0, 0.4)
	tw.tween_callback(l.queue_free)
	return dur
