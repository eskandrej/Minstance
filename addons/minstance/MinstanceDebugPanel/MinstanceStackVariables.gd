tool
extends Tree

var root: TreeItem
var minstance_main = null
var editor_theme = null

func initialize(p_minstance_main) -> void:
	minstance_main = p_minstance_main
	editor_theme = minstance_main.get_editor_interface().get_base_control().theme
	
func clear() -> void:
	.clear()
	root = create_item()
	
func _on_tree_cell_selected() -> void:
	var tree_item = get_selected()
	var selected_column = get_selected_column()
	
	var metadata = tree_item.get_metadata(selected_column)
	if metadata is MinstanceRemote:
		minstance_main.inspected_object = metadata
		

func custom_draw_coll(item:TreeItem, rect: Rect2) -> void:
	draw_rect(rect, item.get_custom_bg_color(1))
		
func item_pressed(item: TreeItem) -> void:
	var column = get_selected_column()
	var data = item.get_metadata(column)

	if data is Array or data is Dictionary:
		var child_item = item.get_children()
		
		if not child_item:
			var title_item = create_item(item)

			title_item.set_cell_mode(0, TreeItem.CELL_MODE_CUSTOM)
			title_item.set_custom_draw(0,self, "custom_draw_coll")
			title_item.set_text(1, "Value")
			title_item.set_metadata(0, column)
			
			if column > 0:
				item.set_custom_color(column, Color.green)
				title_item.set_custom_bg_color(1, Color.darkgreen)
			else:
				item.set_custom_color(column, Color.blue)
				title_item.set_custom_bg_color(1, Color.darkblue)
			
			if data is Dictionary: 
				title_item.set_text(0, "Key")

			elif data is Array: 
				title_item.set_text(0, "Index")

			for idx in data.size():
				var columns_data = null
				if data is Dictionary:
					columns_data = [data.keys()[idx], data.values()[idx]]
				elif data is Array:
					columns_data = [idx, data[idx]]
				call_deferred("new_item", columns_data, title_item)
		else:
			if child_item.get_metadata(0) != column:
				call_deferred("item_pressed", item)
				
			item.clear_custom_color(0)
			item.clear_custom_color(1)
			child_item.free()
		
func new_item(columns_data:Array, parent: TreeItem) -> void:
	var item = create_item(parent)
	
	for column in columns:
		if columns_data[column] is Array: 
			item.set_metadata(column, columns_data[column])
			item.set_text(column, "Array (Size:%s)" % [columns_data[column].size()] )
			
		elif columns_data[column] is Dictionary:
			item.set_metadata(column, columns_data[column])
			item.set_text(column, "Dictionary (Size:%s)" % [columns_data[column].size()] )
			
		elif columns_data[column] is EncodedObjectAsID:
			var minstance_remote = minstance_main.active_instance.get_remote_obj(columns_data[column].object_id)
			item.set_metadata(column, minstance_remote)
			item.set_text(column, "Object ID: %s" % [minstance_remote.remote_id])
			item.set_icon(1, editor_theme.get_icon("Object", "EditorIcons"))
			item.set_icon_max_width(1,20)
		else:
			item.set_text(column, str(columns_data[column]))
			
func _gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == 1:
			yield(get_tree(),"idle_frame")
			var item = get_item_at_position(event.position)
			if item:
				item_pressed(item)

func set_data(stack_variables) -> void:
	clear()

	var idx = 0
	var num_title = 0
	
	var titles = ["Local", "Members", "Globals"]

	while idx < stack_variables.size():

		var size = stack_variables[idx]
		if size:
			var child_p = create_item(root)
			child_p.set_text(0, " " + titles[num_title])
			child_p.set_selectable(0,false)
			child_p.set_selectable(1,false)
			child_p.set_custom_bg_color(0, Color.black)
			child_p.set_custom_bg_color(1, Color.black)
		num_title += 1
		
		for i in size:
			var name = stack_variables[idx +1]
			var value = stack_variables[idx +2]
			new_item([name, value], root)
			idx += 2
		idx += 1
