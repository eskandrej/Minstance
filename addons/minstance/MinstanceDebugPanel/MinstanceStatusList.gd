tool
extends Tree

const Util = preload("res://addons/minstance/Util.gd")

var root:TreeItem
var items = {}
var minstance_main = null

func _on_instance_data_changed(properties: Dictionary, instance: Instance) -> void:
	if properties.has("color"):
		var item = items[instance]
		var texture = item.get_icon(0)
		texture.gradient.colors = [properties.color]
	if properties.has("name"):
		items[instance].set_text(0, properties.name)
		
	if properties.has("status"):
		items[instance].set_text(1, properties.status)
		if properties.status == "Running":
			items[instance].set_custom_color(1, Color.green)
		elif properties.status == "Break":
			items[instance].set_custom_color(1, Color.red)
		
func add_instance(instance: Instance) -> void:
	instance.connect("data_changed", self, "_on_instance_data_changed",[instance])
	var child = create_item(root)
	child.set_text(0, instance.name)
	child.set_text(1, instance.status)
	if instance.status == "Running":
		child.set_custom_color(1, Color.green)
		get_parent().debug_buttons.continue.visible = false
	elif instance.status == "Break":
		child.set_custom_color(1, Color.red)
		get_parent().debug_buttons.continue.visible = true
	child.set_icon(0, Util.color_texture(instance.color, Vector2(10,10)))
	child.set_text_align(1, TreeItem.ALIGN_CENTER)
	child.set_metadata(0,instance)
	items[instance] = child
	
func remove_instance(instance: Instance) -> void:
	root.remove_child(items[instance])
	update()
	items.erase(instance)

func initialize(p_minstance_main) -> void:
	minstance_main = p_minstance_main
	minstance_main.connect("active_instance_changed", self, "_on_active_instance_changed")
	
func _init() -> void:
	root = create_item()
	set_column_title(0, "Instances")
	set_column_title(1, "Status")


func _on_active_instance_changed(instance: Instance) -> void:
	if not instance: 
		var selected = get_selected() 
		if selected: 
			select_mode = Tree.SELECT_SINGLE # there is a bug when is set to select row so we temp change it
			selected.deselect(0)
			select_mode = Tree.SELECT_ROW # and return it back

		return
	items[instance].select(0)

func _on_MinstanceStatusList_item_selected() -> void:
	var instance = get_selected().get_metadata(0)
	if instance:
		minstance_main.active_instance = instance
