extends Node

var default_breakpoints: Instance.Breakpoints
var script_editor = null
var editor_interface = null

var tab_container: TabContainer
var tab_container_stylebox: StyleBoxFlat

var option_btn = null
var minstance_main = null

var instances = {}
var scripts = {}

func _init(p_minstance_main) -> void:
	minstance_main = p_minstance_main
	minstance_main.connect("active_instance_changed", self, "_on_active_instance_changed")
	
	editor_interface = minstance_main.get_editor_interface()
	
	script_editor = editor_interface.get_script_editor()
	script_editor.connect("editor_script_changed", self, "_on_editor_script_changed")
	script_editor.connect("script_close", self, "_on_editor_script_closed")
	
	tab_container = script_editor.get_child(0).get_child(1).get_child(1) # texteditors are here when script is opened
	
	default_breakpoints = Instance.Breakpoints.new()
	
	option_btn = OptionButton.new()
	option_btn.text = "Select Instance"
	option_btn.add_item("Default")
	option_btn.add_separator()
	option_btn.connect("item_selected", self, "_on_option_btn_item_selected")
	script_editor.get_child(0).get_child(0).add_child(option_btn)
	
	tab_container_stylebox = StyleBoxFlat.new()
	tab_container_stylebox.draw_center = false
	tab_container_stylebox.border_width_top = 2
	tab_container_stylebox.border_width_left = 2
	tab_container_stylebox.border_width_bottom = 2
	tab_container_stylebox.border_width_right = 2
	
	update_opened_scripts() # This will update already opened scripts
	yield(ProjectSettings, "project_settings_changed") # wait for scirpts to update


func _on_active_instance_changed(instance) -> void:
	if not instance :
		option_btn.selected = 0
		init_instance_breakpoints(default_breakpoints)
		tab_container.add_stylebox_override("panel", StyleBoxEmpty.new())
	else:
		init_instance_breakpoints(instance.breakpoints)
		option_btn.selected = instances[instance].id
		tab_container_stylebox.border_color = instance.color
		tab_container.add_stylebox_override("panel", tab_container_stylebox)

func _on_editor_script_closed(script) -> void:
	scripts.erase(script)
	default_breakpoints.remove_script_bp(script.resource_path)
	for instance in instances:
		instance.breakpoints.remove_script_bp(script.resource_path)
	minstance_main.save_config()

func _on_editor_script_changed(script) -> void:
	if not script or scripts.has(script): return
	
	 # on startup godot will not create text editor until script is opened so this line will force it
	editor_interface.edit_script(script)
	
	var script_text_editor = tab_container.get_current_tab_control()
	var text_editor = script_text_editor.get_child(0).get_child(0).get_child(0)

	scripts[script] = {"text_editor": text_editor}
	
	if not text_editor.is_connected("breakpoint_toggled", self, "_breakpoint_toggled"):
		text_editor.connect("breakpoint_toggled", self, "_breakpoint_toggled", [text_editor])
		
	if not text_editor.is_connected("text_changed", self, "update_breakpoints"):
		text_editor.connect("text_changed", self, "update_breakpoints", [text_editor])

func update_opened_scripts() -> void:
	var current_tab = tab_container.current_tab
	_on_editor_script_changed(script_editor.get_current_script())
	for script in script_editor.get_open_scripts():
		editor_interface.edit_script(script)
	if current_tab < 1: return
	tab_container.current_tab = current_tab
	
func _breakpoint_toggled(row: int, text_editor: TextEdit) -> void:
	var toggle = text_editor.is_line_set_as_breakpoint(row)
	if minstance_main.active_instance:
		if minstance_main.active_instance.status != "Inactive":
			var script_path = script_editor.get_current_script().resource_path
			minstance_main.active_instance.remote_breakpoint(script_path, row + 1, toggle)
	update_breakpoints(text_editor)
	
func update_breakpoints(text_editor: TextEdit) -> void:
	var text_editor_bp = text_editor.get_breakpoints()
	var script_path = script_editor.get_current_script().resource_path
	
	if minstance_main.active_instance:
		minstance_main.active_instance.breakpoints.set_script_bp(script_path, text_editor_bp)
	else:
		default_breakpoints.set_script_bp(script_path, text_editor_bp)
	
func _on_breakpoint_set(idx, text_editor: TextEdit) -> void:
	var toggle = text_editor.is_line_set_as_breakpoint(idx)
	var breakpoints = default_breakpoints
	
	if minstance_main.active_instance:
		breakpoints = minstance_main.active_instance.breakpoints

	breakpoints.toggle_breakpoint(
			script_editor.get_current_script().resource_path,
			idx,
			toggle)

func add_instance(instance) -> void:
	instance.connect("data_changed", self, "_on_instance_data_changed", [instance])
	
	option_btn.add_icon_item(instance.icon, instance.name)
	option_btn.set_item_metadata(option_btn.get_item_count() - 1, instance)
	
	instances[instance] = {"id": option_btn.get_item_count() - 1} 

func remove_instance(instance) -> void:
	var id = instances[instance].id
	if id == option_btn.get_selected_id():
		minstance_main.active_instance = null
	option_btn.remove_item(option_btn.get_item_index(id))
	instances.erase(instance)
	
func _on_instance_data_changed(property, instance) -> void:
	var idx = instances[instance].id
	
	if property.has("color"):
		if minstance_main.active_instance == instance:
			tab_container_stylebox.border_color = instance.color
			
	if property.has("name"):
		option_btn.set_item_text(idx, property.name)
		
	if property.has("status"):
		if property.status == "Running":
			var current_script = script_editor.get_current_script()
			if current_script:
				var text_editor = scripts[current_script].text_editor
				if text_editor:
					text_editor.update()

func init_instance_breakpoints(breakpoints) -> void:
	for script in scripts:
		var text_editor = scripts[script].text_editor
		text_editor.remove_breakpoints()
		for bp in breakpoints.get_script_bp(script.resource_path):
			text_editor.set_line_as_breakpoint(bp, true)
		text_editor.update()

func _on_option_btn_item_selected(idx) -> void:
	var instance = option_btn.get_selected_metadata()
	minstance_main.active_instance = instance

func delete() -> void:
	for script_val in scripts.values():
		script_val.text_editor.disconnect("breakpoint_toggled", self, "_breakpoint_toggled")
		script_val.text_editor.disconnect("text_changed", self, "update_breakpoints")
	scripts.clear()
	option_btn.queue_free()
	queue_free()
