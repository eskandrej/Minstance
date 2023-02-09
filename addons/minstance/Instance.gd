class_name Instance
extends Node

var Util = load("res://addons/minstance/Util.gd")

const _properties = [
					"name",
					"color",
					"arguments",
					"window_position",
					"window_size",
					"port",
					"status",
					"stack",
					"stack_vars",
					"remote_scene_tree",
					"debug_msg"
					]
var _values = {}

var _tcp_server: TCP_Server
var _connection: StreamPeerTCP

var _autoload_id: int

var icon: Texture
var id: String
var config_path
var output_log: Control
var breakpoints: Breakpoints
var save_window: bool
var remote_objs = {}

var inspect_edited_object_timeout = 0.2
var remote_scene_tree_timeout = 1

var minstance_main = null

signal data_changed(property)
signal breakpoint_reached(data)

func _get(property):
	if _properties.has(property):
		return _values[property]

func _set(property, value) -> bool:
	if _properties.has(property):
		if not _values.has(property): 
			_values[property] = value
			return true
		elif _values[property] != value:
			_values[property] = value
			emit_signal("data_changed", {property: value})
			if property == "color": icon.gradient.colors = [value]
		return true
	return false

func _init(name, color, arguments, window_position, window_size) -> void:
	self.name = name
	self.color = color
	self.arguments = arguments
	self.window_position = window_position
	self.window_size = window_size
	
	self.status = "Inactive"
	self.stack = []
	self.stack_vars = []
	self.remote_scene_tree = []
	self.debug_msg = ""
	
	randomize()
	id = "%02x-%02x-%02x" % [randi(),randi(),randi()]
	
	icon = Util.color_texture(self.color, Vector2(10,10))
	_tcp_server = TCP_Server.new()
	breakpoints = Breakpoints.new()
	
func start_debug_server() -> void:
	clear_connection()
	output_log.clear()
	if _tcp_server.listen(self.port) != OK:
		output_log.add_message("Can't listen on port %d" % self.port, 1)

func start_app() -> void:
	start_debug_server()
	
	var autoload_arguments = self.arguments + \
	" --minstance-id %s --minstance-color %s --minstance-save-window %s --minstance-config-path %s" % [id, self.color.to_html(), var2str(self.save_window), self.config_path]
	
	OS.execute(OS.get_executable_path(), [
				"--position", "%d,%d" % [self.window_position.x, self.window_position.y],
				"--resolution", "%dx%d" % [self.window_size.x, self.window_size.y],
				"--remote-debug", "127.0.0.1:%s" % self.port,
				"--allow_focus_steal_pid", OS.get_process_id(),
				"--breakpoints", self.breakpoints,
				autoload_arguments
			], false)

	self.status = "Running"

func clear_connection() -> void:
	if _tcp_server.is_listening():
		_connection = null
		_tcp_server.stop()

func set_sticky(enable:bool) -> void:
	set_object_property(_autoload_id, "sticky", enable)
	set_focus()

func _process (delta) -> void:
	if _connection == null:
		if _tcp_server.is_connection_available():
			_connection = _tcp_server.take_connection()
	else:
		if _connection.get_status() == _connection.STATUS_CONNECTED:
			if _connection.get_available_bytes() > 0:
				var message = _connection.get_var()
				var size = _connection.get_var()
				var data = []
				
				for i in size:
					data.append(_connection.get_var())

				match message:
					"output":
						for line_data in data:
							output_log.add_message(line_data[0], line_data[1])
							
					"debug_enter":
						if data: self.debug_msg = data[1]
						minstance_main.set_instances_sticky(false)
						yield(get_tree(),"idle_frame")
						OS.set_window_always_on_top(true)
						OS.set_window_always_on_top(false)
						get_stack_dump()
						
					"message:scene_tree":
						self.remote_scene_tree = data
						if not _autoload_id:
							var idx = self.remote_scene_tree.find("MinstanceAutoload")
							if idx > -1:
								_autoload_id = self.remote_scene_tree[idx + 2]
							
					"stack_dump":
						self.stack = data
						if data: emit_signal("breakpoint_reached", data[0])
						self.status = "Break"

					"stack_frame_vars":
						self.stack_vars = data
						
					"message:inspect_object":
						var remote_obj = get_remote_obj(data[0])
						remote_obj.set_remote_data(data)
						
					"debug_exit":
						self.status = "Running"
						self.debug_msg = ""
						
			remote_scene_tree_timeout -= delta
			if (remote_scene_tree_timeout < 0):
				remote_scene_tree_timeout = 1
				request_scene_tree()

			inspect_edited_object_timeout -= delta
			if (inspect_edited_object_timeout < 0):
				inspect_edited_object_timeout = 0.2
				
				if minstance_main.inspected_object and minstance_main.inspected_object.instance == self:
					inspect_object(minstance_main.inspected_object.remote_id)
		
		if _connection.get_status() == _connection.STATUS_NONE:
			clear_connection()
			stop()
			minstance_main.stop_all()
			
func get_remote_obj(id) -> MinstanceRemote:
	if not remote_objs.has(id):
		remote_objs[id] = MinstanceRemote.new(self)
		remote_objs[id].remote_id = id
	return remote_objs[id]

func stop() -> void:
	if _connection:
		if self.status == "Break":
			continue_ex()
		yield(async_call_autoload_function("quit"), "completed")

	self.status = "Inactive"

	for remote_obj in remote_objs.values():
		remote_obj.free()
	remote_objs.clear()
	_autoload_id = 0
	
	yield(get_tree(),"idle_frame")
	clear_connection()

func continue_ex() -> void:
	_connection.put_var(["continue"])
	self.stack_vars.clear()
	self.stack.clear()
	self.status = "Running"
	
func async_call_autoload_function(function_name:String) -> GDScriptFunctionState:
	if not _autoload_id:
		request_scene_tree()
		yield(get_tree(),"idle_frame")
		async_call_autoload_function(function_name)
	else:
		set_object_property(_autoload_id, function_name, true)
		
	return yield()
	
func set_focus() -> void:
	async_call_autoload_function("focus")

func remote_breakpoint(script_path: String, line:int, toggle: bool) -> void:
	_connection.put_var(["breakpoint", script_path, line, toggle])
	
func request_scene_tree() -> void:
	_connection.put_var(["request_scene_tree"])
	
func request_break() -> void:
	_connection.put_var(["break"])
	
func debug_step() -> void:
	_connection.put_var(["step"])
	
func debug_next() -> void:
	_connection.put_var(["next"])
	
func get_stack_frame_vars(level: int) -> void:
	_connection.put_var(["get_stack_frame_vars", level])
	
func get_stack_dump():
	_connection.put_var(["get_stack_dump"])

func set_object_property(id, property, value) -> void:
	var data = ["set_object_property",id, property, value]
	_connection.put_var(data)
	inspect_edited_object_timeout = 0.7
	
func inspect_object(id) -> void:
	_connection.put_var(["inspect_object",id])
	
func serialize() -> Dictionary:
	return { 
		"name": self.name,
		"color": self.color,
		"arguments": self.arguments,
		"window_position": self.window_position,
		"window_size": self.window_size
	}

func delete() -> void:
	clear_connection()
	output_log.queue_free()
	
class Breakpoints:
	var data = {}
	
	func get_script_bp(p_script_path:String) -> Array:
		if data.has(p_script_path):
			return data[p_script_path]
		else:
			return []
			
	func set_script_bp(p_script_path:String, p_breakpoints:Array) -> void:
		data[p_script_path] = p_breakpoints
		if p_breakpoints.empty():
			remove_script_bp(p_script_path)
		
	func remove_script_bp(p_script_path:String) -> void:
		data.erase(p_script_path)
		
	func _to_string() -> String:
		var output: String
		
		for script_path in data:
			for line in data[script_path]:
				output += "%s:%d," % [script_path, line + 1]
		
		if output.empty():
			output = " " 	# Added for convenience, so that we don't need to check if its empty when adding to argument
							# without whitespace it would go to next argument
		else:
			output = output.rstrip(",")
			
		return output
