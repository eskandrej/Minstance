extends Node

const MinstanceToolButton = preload("MinstanceToolButton/MinstanceToolButton.tscn")
const Util = preload("../Util.gd")

var minstance_tool_button: Button
var instruction_popup: AcceptDialog
var no_main_screen_popup: AcceptDialog
var toolbar_buttons: Dictionary
var minstance_main = null

func _init(p_minstance_main) -> void:
	minstance_main = p_minstance_main
	minstance_main.connect("status_changed", self, "_on_minstance_status_changed")
	minstance_tool_button = MinstanceToolButton.instance()
	
	instruction_popup = minstance_tool_button.get_node("InstructionPopup")
	no_main_screen_popup = minstance_tool_button.get_node("NoMainScenePopup")

	minstance_main.add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, minstance_tool_button)
	minstance_tool_button.get_parent().move_child(minstance_tool_button, 4)
	minstance_tool_button.initialize(minstance_main)
	toolbar_buttons = get_toolbar_buttons()
	
	
func _on_minstance_status_changed(status:int) -> void:
	if status == minstance_main.STATUS.STARTED:
		toolbar_buttons.play.disabled = true
		toolbar_buttons.stop.disabled = false
		toolbar_buttons.stop.connect("pressed", minstance_main, "stop_all")
		
	if status == minstance_main.STATUS.STOPPED:
		toolbar_buttons.play.disabled = false
		toolbar_buttons.stop.disabled = true
		toolbar_buttons.stop.disconnect("pressed", minstance_main, "stop_all")

func get_toolbar_buttons() -> Dictionary:
	var buttons: Dictionary
	var dummy = Control.new()
	minstance_main.add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, dummy)
	
	for parent in dummy.get_parent().get_children():
		buttons = Util.get_toolbuttons_by_shortcut_name(parent, ["Play", "Stop"])
		if buttons: break

	minstance_main.remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, dummy)
	dummy.queue_free()
	return buttons

func delete() -> void:
	
	minstance_main.remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, minstance_tool_button)
	self.queue_free()
	minstance_tool_button.queue_free()
	
