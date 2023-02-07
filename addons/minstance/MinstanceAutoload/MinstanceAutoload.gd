extends CanvasLayer

var focus:bool setget set_focused
var quit:bool setget set_quit
var sticky:bool = false

var _kill:bool = false

func get_minstance_value_from_args(p_argument:String) -> String:
	var arguments = OS.get_cmdline_args()
	if not arguments: return ""
	
	var at = arguments[0].find(p_argument)
	if at > -1:
		return arguments[0].right(at).get_slice(" ", 1)
	else: return ""

func _ready() -> void:
	var minstance_color = get_minstance_value_from_args("--minstance-color")
	if minstance_color.empty(): 
		_kill = true
		queue_free()
		return
	$ColorRect.color = minstance_color
	
func _exit_tree() -> void:
	if not _kill: _save_window_position()

func _save_window_position() -> void:
	var save_window = str2var(get_minstance_value_from_args("--minstance-save-window")) # using str2var because value is bool
	
	# There is a bug when exiting program that is still paused on breakpoint. 
	# After it is terminated it will have empty window_size so if it happens we are skipping saving that
	if not save_window or OS.window_size == Vector2(0,0): return 
	
	var minstace_config_path = get_minstance_value_from_args("--minstance-config-path")
	var minstance_id = get_minstance_value_from_args("--minstance-id")
	
	var config = ConfigFile.new()	
	config.load(minstace_config_path)

	var instance = config.get_value("Instances", minstance_id)
	instance.window_position = OS.window_position
	instance.window_size = OS.window_size
	
	config.set_value("Instances", minstance_id, instance)
	config.save(minstace_config_path)

func set_quit(p_value) -> void:
	get_tree().quit()

func set_focused(p_value) -> void:
	# OS.move_window_to_foreground() will not bring window to front on Windows
	# if its called from background so using this workaround
	OS.set_window_always_on_top(true)
	if not sticky: OS.set_window_always_on_top(false)
	
