tool
extends Tree

var root: TreeItem
var minstance_main = null

func _ready() -> void:
	set_column_title(0, "Stack Frames")
	
func initialize(p_minstance_main) -> void:
	minstance_main = p_minstance_main

func set_data(stack_data) -> void:
	clear()
	for idx in stack_data.size():
		var stack = stack_data[idx]
		var child = create_item(root)
		stack["id"] = idx
		child.set_metadata(0, stack)
		child.set_text(0, "%s - %s:%s - at function: %s" % [idx, stack.file,stack.line,stack.function])
	
	if root.get_children(): root.get_children().select(0)

func clear() -> void:
	deselect()
	.clear()
	root = create_item()
	
func deselect() -> void:
	var selected_item = get_selected()
	if not selected_item: return
	var data = selected_item.get_metadata(0)
	var script = load(data.file)
	minstance_main.script_editor_debugger.emit_signal("clear_execution", script)
	selected_item.deselect(0)
	

func _on_MinstanceStackFrames_item_selected() -> void:
	var data = get_selected().get_metadata(0)
	var se = minstance_main.script_editor_debugger
	var script = load(data.file)
	minstance_main.get_editor_interface().edit_script(script)
	se.emit_signal("set_execution",script, data.line -1)
	se.emit_signal("goto_script_line",script, data.line -1)
	minstance_main.active_instance.get_stack_frame_vars(data.id)
