tool
extends Tree

var minstance_main = null
var root_item: TreeItem
var items = {}

func initialize(p_minstance_main) -> void:
	minstance_main = p_minstance_main

func select_inspected_object(object) -> void:
	if not object or not items.has(object.remote_id): return
	var tree_item = items[object.remote_id]
	if tree_item: 
		scroll_to_item(tree_item)
		var p = tree_item.get_parent()
		
		while p != null:
			p.collapsed = false
			p = p.get_parent()
			
		tree_item.select(0)
		tree_item.collapsed = false
	
func create_child_item(parent, p_data, idx) -> int:

	var child_count = p_data[idx]
	var name = p_data[idx + 1]
	var type = p_data[idx + 2]
	var remote_id = p_data[idx + 3]
	
	var item = create_item(parent)
	items[remote_id] = item
	if idx > 0: item.collapsed = true
	
	item.set_metadata(0, remote_id)

	item.set_text(0, name)
	var icon = minstance_main.get_editor_interface().get_base_control().get_icon(type, "EditorIcons")
	item.set_icon(0, icon)
	idx = idx + 4
	for i in child_count: 
		idx = create_child_item(item, p_data, idx)
		
	return idx

	
func set_data(p_data) -> void:
	items.clear()
	clear()
	var idx = 0
	while idx < p_data.size():
		idx = create_child_item(null, p_data, idx)
	
func _on_MinstanceRemoteTree_item_selected() -> void:
	var remote_id = get_selected().get_metadata(0)
	var remote_obj = minstance_main.active_instance.get_remote_obj(remote_id)
	minstance_main.inspected_object = remote_obj
