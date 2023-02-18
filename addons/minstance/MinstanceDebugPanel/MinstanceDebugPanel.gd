@tool
extends Node

const MinstanceDebugPanelScene = preload("MinstanceDebugPanelScene.tscn")

var Util = load("res://addons/minstance/Util.gd")

var minstance_status_list = null
var minstance_stack_frames = null
var minstance_stack_variables = null
var minstance_remote_tree = null

var minstance_main = null
var debug_buttons = {}
var orginal_buttons

var minstance_debug_panel: Control
var error_lbl: Label
var bring_to_front_btn: Button
var sticky_btn: TextureButton


var vbox: VBoxContainer
var h_split_container: HSplitContainer

enum BUTTONS_TYPE {ORGINAL, MINSTANCE}

var enabled = false

func _on_breakpoint_reached(data, p_instance: Instance):
	minstance_main.active_instance = p_instance
	minstance_main.make_bottom_panel_item_visible(minstance_main.script_editor_debugger)
	

func _on_instance_data_changed(property, instance):
	if enabled:
		if property.has("status"):
			if property.status == "Running":
				debug_buttons.get_continue.disabled = true
				debug_buttons.step_over.disabled = true
				debug_buttons.step_into.disabled = true
				debug_buttons.get_break.disabled = false
				error_lbl.text = ""
				
				minstance_stack_variables.clear()
				minstance_stack_frames.clear()
				
			if property.status == "Break":
				debug_buttons.get_continue.disabled = false
				debug_buttons.get_break.disabled = true
				debug_buttons.step_over.disabled = false
				debug_buttons.step_into.disabled = false
		
		if minstance_main.active_instance == instance:
			if property.has("stack"):
				minstance_stack_frames.set_data(property.stack)

			if property.has("stack_vars"):
				minstance_stack_variables.set_data(property.stack_vars)
				
			if property.has("remote_scene_tree"):
				minstance_remote_tree.set_data(property.remote_scene_tree)

			if property.has("debug_msg"):
				error_lbl.text = property.debug_msg

func add_instance(p_instance: Instance) -> void:
	minstance_status_list.add_instance(p_instance)
	p_instance.connect("breakpoint_reached", _on_breakpoint_reached.bind(p_instance))
	p_instance.connect("data_changed", _on_instance_data_changed.bind(p_instance))
	
func remove_instance(p_instance: Instance) -> void:
	minstance_status_list.remove_instance(p_instance)
	
func initialize_instance(p_instance: Instance) -> void:
	_on_instance_data_changed({
							"status" : p_instance.status, 
							"stack": p_instance.stack,
							"stack_vars": p_instance.stack_vars,
							"remote_scene_tree": p_instance.remote_scene_tree,
							"debug_msg": p_instance.debug_msg}, p_instance)	
	
func _on_minstance_status_changed(status:int) -> void:
	if status == minstance_main.STATUS.STARTED:
		enabled = true
		vbox.remove_child(h_split_container)
		vbox.add_child(minstance_debug_panel)
		show_buttons(BUTTONS_TYPE.MINSTANCE)
		bring_to_front_btn.visible = true	
		sticky_btn.visible = true
		_on_active_instance_changed(minstance_main.active_instance)
		
	if status == minstance_main.STATUS.STOPPED:
		enabled = false
		vbox.remove_child(minstance_debug_panel)
		vbox.add_child(h_split_container)
		show_buttons(BUTTONS_TYPE.ORGINAL)
		error_lbl.text = ""
		bring_to_front_btn.visible = false
		sticky_btn.visible = false
		
func show_buttons(buttons_type) -> void:
	for idx in orginal_buttons.size():
		orginal_buttons.values()[idx].visible = !buttons_type
		debug_buttons.values()[idx].visible = buttons_type
		
func minstance_buttons_disabled() -> void:
	for idx in debug_buttons.size():
		debug_buttons.values()[idx].disabled = true
		
func _on_active_instance_changed(instance) -> void:
	if enabled:
		minstance_stack_frames.clear()
		minstance_stack_variables.clear()
		minstance_remote_tree.clear()
		error_lbl.text = ""
		
		if not instance: 
			minstance_buttons_disabled()
		else:
			initialize_instance(instance)
	
func _on_debug_type_button_pressed(type:String) -> void:
	match type:
		"continue":
			minstance_main.active_instance.continue_ex()
			minstance_main.bring_instances_to_front()
		"break":
			minstance_main.active_instance.request_break()
		"step_into":
			minstance_main.active_instance.debug_step()
		"step_over":
			minstance_main.active_instance.debug_next()

func _init(p_minstance_main) -> void:
	minstance_main = p_minstance_main
	minstance_main.connect("status_changed", self, "_on_minstance_status_changed")
	minstance_main.connect("active_instance_changed", self, "_on_active_instance_changed")
	
	minstance_debug_panel = MinstanceDebugPanelScene.instance()
	
	minstance_status_list = minstance_debug_panel.get_node("HSplitContainer2/MinstanceStatusList")
	minstance_stack_variables = minstance_debug_panel.get_node("HSplitContainer/MinstanceStackVariables")
	minstance_stack_frames = minstance_debug_panel.get_node("HSplitContainer/MinstanceStackFrames")
	minstance_remote_tree = minstance_debug_panel.get_node("HSplitContainer2/MinstanceRemoteTree")
	
	minstance_status_list.initialize(minstance_main)
	minstance_remote_tree.initialize(minstance_main)
	minstance_stack_frames.initialize(minstance_main)
	minstance_stack_variables.initialize(minstance_main)

	var tab_container = minstance_main.script_editor_debugger.get_child(0)
	vbox = tab_container.get_child(0)

	
	orginal_buttons = Util.get_toolbuttons_by_shortcut_name(vbox.get_child(0),
								["Step Into", "Step Over", "Break", "Continue"])

	error_lbl = vbox.get_child(0).get_child(0)
	
	bring_to_front_btn = Button.new()
	bring_to_front_btn.text = "Bring to front instances"
	bring_to_front_btn.connect("pressed", _on_bring_to_front_btn_pressed())
	bring_to_front_btn.visible = false
	vbox.get_child(0).add_child(bring_to_front_btn)
	
	var theme = minstance_main.get_editor_interface().get_base_control().theme
	
	sticky_btn = TextureButton.new()
	sticky_btn.toggle_mode = true
	sticky_btn.expand = true
	sticky_btn.rect_min_size = Vector2(16,16)
	sticky_btn.stretch_mode = TextureButton.STRETCH_KEEP_CENTERED

	sticky_btn.texture_normal = theme.get_icon("Unlock", "EditorIcons")
	sticky_btn.texture_pressed = theme.get_icon("Lock", "EditorIcons")

	sticky_btn.connect("pressed" ,_on_sticky_pressed())
	vbox.get_child(0).add_child(sticky_btn)
	

	for button_name in orginal_buttons:
		var button = orginal_buttons[button_name]
		var duplicate = button.duplicate()
		vbox.get_child(0).add_child_below_node(button, duplicate)
		duplicate.connect("pressed", self, "_on_debug_type_button_pressed",[button_name])
		debug_buttons[button_name] = duplicate
		duplicate.visible = false
		duplicate.disabled = true
		
	
	h_split_container = vbox.get_child(1)
	
	var inspector_debug = h_split_container.get_child(1).get_child(1)
		
	for child in h_split_container.get_children():
		child.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
func _on_sticky_pressed():
	minstance_main.set_instances_sticky(sticky_btn.pressed)
	
func _on_bring_to_front_btn_pressed():
	minstance_main.bring_instances_to_front()
	
func delete() -> void:
	minstance_debug_panel.queue_free()
	for btn in debug_buttons.values():
		btn.queue_free()
	error_lbl.text = ""
	bring_to_front_btn.queue_free()
	sticky_btn.queue_free()
