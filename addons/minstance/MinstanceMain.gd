@tool
extends EditorPlugin

const MinstanceScriptEditor = preload("MinstanceScriptEditor/MinstanceScriptEditor.gd")
const MinstanceDebugPanel = preload("MinstanceDebugPanel/MinstanceDebugPanel.gd")
const MinstanceToolbar = preload("MinstanceToolbar/MinstanceToolbar.gd")
const MinstanceOutputs = preload("MinstanceOutputs/MinstanceOutputs.gd")
const MinstanceInspector = preload("MinstanceInspector.gd")

var minstance_script_editor: MinstanceScriptEditor
var minstance_debug_panel: MinstanceDebugPanel
var minstance_toolbar: MinstanceToolbar
var minstance_outputs: MinstanceOutputs
var minstance_inspector: MinstanceInspector

var script_editor_debugger:Control

const MINSTANCE_CONFIG_PATH = "res://minstance_data.cfg"
var instances: Array
var active_instance = null : set = set_active_instance
var inspected_object = null : set = set_inspected_object
var config: ConfigFile

var save_breakpoints = true
var remember_window_position_size = true
var remove_autoload_on_exit = true
var close_all_instances_on_exit = true
var debugger_port = 4567
var spawn_time = 0

enum STATUS {NONE, STARTED, STOPPED, STOPPING}
var status = STATUS.NONE : set = set_status
var object_id_selected_connection: Dictionary

signal active_instance_changed(instance)
signal status_changed(status)

func _enter_tree() -> void:
	script_editor_debugger = get_script_editor_debugger()
	
	minstance_script_editor = await MinstanceScriptEditor.new(self)
	minstance_debug_panel = MinstanceDebugPanel.new(self)
	minstance_toolbar = MinstanceToolbar.new(self)
	minstance_outputs = MinstanceOutputs.new(self)
	minstance_inspector = MinstanceInspector.new(self)
	
	add_inspector_plugin(minstance_inspector)
	config = ConfigFile.new()
	load_config()

func stop_all() -> void:
	if status != STATUS.STARTED: return
	
	self.status = STATUS.STOPPING
	self.active_instance = null
	self.inspected_object = null

	for instance in instances:	
		await get_tree().process_frame # wait a little to avoid writting file at a same time
		instance.stop()

	if remove_autoload_on_exit:
		remove_autoload_singleton("MinstanceAutoload")
		ProjectSettings.save()
		
	self.status = STATUS.STOPPED
	
	get_editor_interface().get_inspector().connect(object_id_selected_connection.get_signal, object_id_selected_connection.target, object_id_selected_connection.method)
	get_editor_interface().get_inspector().disconnect("object_id_selected", _on_object_id_selected)
	
func set_inspected_object(p_inspected_object: MinstanceRemote) -> void:
	inspected_object = p_inspected_object
	minstance_debug_panel.minstance_remote_tree.select_inspected_object(inspected_object)
	get_editor_interface().inspect_object(inspected_object)

func set_status(p_status:int):
	status = p_status
	emit_signal("status_changed", status)
	
func set_active_instance(p_instance: Instance) -> void:
	if active_instance != p_instance:
		active_instance = p_instance
		emit_signal("active_instance_changed", active_instance)

func update_window_size_position() -> void:
	for instance in instances:
		config.load(MINSTANCE_CONFIG_PATH)
		var data = config.get_value("Instances", instance.id)
		if data:
			instance.window_position = data.window_position
			instance.window_size = data.window_size

func _on_object_id_selected(id):
	var object = inspected_object.instance.get_remote_obj(id)
	self.inspected_object = object

func start() -> void:
	if instances.is_empty(): 
		minstance_toolbar.instruction_popup.popup_centered()
		return
		
	if ProjectSettings.get_setting("application/run/main_scene").empty():
		minstance_toolbar.no_main_screen_popup.popup_centered()
		return
		
	self.active_instance = null
	
	minstance_outputs.show()

	add_autoload_singleton("MinstanceAutoload", "res://addons/minstance/MinstanceAutoload/MinstanceAutoload.tscn")
	ProjectSettings.save()

	get_editor_interface().save_scene()

	update_window_size_position()
	for instance in instances:
		instance.config_path = MINSTANCE_CONFIG_PATH
		instance.save_window = remember_window_position_size
		instance.port = debugger_port + instances.find(instance)
		instance.start_app()
		await get_tree().create_timer(spawn_time).timeout
		
	self.status = STATUS.STARTED
	
	object_id_selected_connection = get_editor_interface().get_inspector().get_signal_connection_list("object_id_selected")[0]
	get_editor_interface().get_inspector().disconnect(object_id_selected_connection.get_signal, object_id_selected_connection.target.method)
	get_editor_interface().get_inspector().connect("object_id_selected", _on_object_id_selected)
	
func save_config() -> void:
	config.clear()

	config.set_value("Configuration","debugger_port", debugger_port)
	config.set_value("Configuration","save_breakpoints", save_breakpoints)
	config.set_value("Configuration","remove_autoload_on_exit", remove_autoload_on_exit)
	config.set_value("Configuration","remember_window_position_size", remember_window_position_size)
	config.set_value("Configuration","close_all_instances_on_exit", close_all_instances_on_exit)
	config.set_value("Configuration", "spawn_time", spawn_time)
	
	for instance in instances:
		if save_breakpoints: config.set_value("Breakpoints", instance.id, instance.breakpoints.data)
		config.set_value("Instances", instance.id, instance.serialize())

	if save_breakpoints: 
		config.set_value("Breakpoints", "default_breakpoints", minstance_script_editor.default_breakpoints.data)

	var err = config.save(MINSTANCE_CONFIG_PATH)
	if err != OK: print("Error in saving config file!")
	
func load_config() -> void:
	var err = config.load(MINSTANCE_CONFIG_PATH)
	if err != OK:
		return
		
	debugger_port = config.get_value("Configuration", "debugger_port", debugger_port)
	save_breakpoints = config.get_value("Configuration", "save_breakpoints", save_breakpoints)
	remember_window_position_size = config.get_value("Configuration", "remember_window_position_size", remember_window_position_size)
	remove_autoload_on_exit = config.get_value("Configuration","remove_autoload_on_exit", remove_autoload_on_exit)
	close_all_instances_on_exit = config.get_value("Configuration","close_all_instances_on_exit", close_all_instances_on_exit)
	spawn_time = config.get_value("Configuration", "spawn_time", spawn_time)
	
	if config.has_section("Instances"):
		for instance_id in config.get_section_keys("Instances"):
			var data = config.get_value("Instances", instance_id)
			var instance = new_instance(data.name,data.color,data.arguments,data.window_position,data.window_size)
			instance.id = instance_id
			instance.breakpoints.data = config.get_value("Breakpoints", instance.id, {})
			minstance_toolbar.minstance_tool_button.minstance_settings_dialog.add_instance(instance)

	minstance_script_editor.default_breakpoints.data = config.get_value("data", "default_breakpoints", {})
		
func new_instance(p_name, p_color, p_arguments, p_window_position, p_window_size) -> Instance:
	var new_instance = Instance.new(p_name, p_color, p_arguments, p_window_position, p_window_size)
	add_child(new_instance)
	instances.append(new_instance)
	new_instance.minstance_main = self
	new_instance.output_log = minstance_outputs.add_log(new_instance)
	
	minstance_script_editor.add_instance(new_instance)
	minstance_debug_panel.add_instance(new_instance)

	return new_instance
	
func remove_instance(instance: Instance) -> void:
	minstance_script_editor.remove_instance(instance)
	minstance_debug_panel.remove_instance(instance)
	
	instances.erase(instance)
	instance.delete()
	
func get_script_editor_debugger() -> Control:
	var script_editor_debuger:Control
	
	var dummy = Control.new()
	add_control_to_bottom_panel(dummy,"")
	var p = dummy.get_parent()
	remove_control_from_bottom_panel(dummy)
	
	for child in p.get_children():
		if child.get_class() == "ScriptEditorDebugger":
			script_editor_debuger = child

	return script_editor_debuger
	
func bring_instances_to_front() -> void:
	for instance in instances:
		instance.set_focus()
		
func set_instances_sticky(enable: bool) -> void:
	minstance_debug_panel.sticky_btn.button_pressed = enable
	for instance in instances:
		instance.set_sticky(enable)

func apply_changes() -> void:
	update_window_size_position()
	save_config()

func build() -> bool:
	self.active_instance = null
	return true
	
func _exit_tree() -> void:
	
	minstance_script_editor.delete()
	minstance_debug_panel.delete()
	minstance_toolbar.delete()
	minstance_outputs.delete()
	
	for instance in instances:
		instance.delete()

	remove_inspector_plugin(minstance_inspector)
