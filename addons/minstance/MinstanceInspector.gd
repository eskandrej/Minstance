extends EditorInspectorPlugin

var minstance_main = null

func _init(p_minstance_main) -> void:
	minstance_main = p_minstance_main

func can_handle(object) -> bool:
	return object is MinstanceRemote

func parse_begin(object) -> void:
	var vbox = VBoxContainer.new()
	var label = Label.new()
	
	var path = object.get("Minstance_path")
	if path:
		label.text = "%s:%s" % [path,object.remote_id]
		
	label.add_color_override("font_color", object.instance.color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.rect_min_size.y = 5
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(label)
	
	var color_rect = ColorRect.new()
	color_rect.rect_min_size.y = 5
	color_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	color_rect.color = object.instance.color
	vbox.add_child(color_rect)
	
	add_custom_control(vbox)
	
func parse_property(object, type, path, hint, hint_text, usage) -> bool:
	if path == "Minstance_path":
		return true
	
	var p_object = null
	if object: p_object = object.get(path)
	
#	if p_object is MinstanceRemote:
#		var e = EditorProperty.new()
#		var b = Button.new()
#		b.text = str(p_object)
#		b.connect("pressed", self, "remote_obj_to_inspect", [p_object])
#		e.add_child(b)
#
#		add_property_editor(path,e)
#		return true
	return false

func remote_obj_to_inspect(remote_obj) -> void:
	minstance_main.call_deferred("set_inspected_object",remote_obj)
