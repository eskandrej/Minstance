tool
extends HBoxContainer

const MinstanceOutputScene = preload("MinstanceOutput/MinstanceOutputScene.tscn")

var minstance_main = null
var editor_plugin = null

func _init(p_editor_plugin) -> void:
	editor_plugin = p_editor_plugin
	editor_plugin.add_control_to_bottom_panel(self, "Minstance Outputs")

func add_log(instance) -> Control:
	var new_minstance_output = MinstanceOutputScene.instance()
	add_child(new_minstance_output)
	new_minstance_output.theme = editor_plugin.get_editor_interface().get_base_control().theme
	
	new_minstance_output.set_instance(instance)

	return new_minstance_output

func remove_log(p_log) -> void:
	pass

func show() -> void:
	editor_plugin.make_bottom_panel_item_visible(self)
	
func delete() -> void:
	editor_plugin.remove_control_from_bottom_panel(self)
	queue_free()
