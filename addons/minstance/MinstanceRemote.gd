extends Object
class_name MinstanceRemote

var __remote_properties = []
var __properties = {}
var remote_id: int
var name: String

var instance = null

func _get_property_list() -> Array:
	return __remote_properties
	
func _init(p_instance, p_remote_data:Array = []) -> void:
	instance = p_instance
	if not p_remote_data.is_empty(): set_remote_data(p_remote_data)
	
func set_remote_data(p_remote_data:Array) -> void:
	var old_prop = __properties
	__remote_properties.clear()
	
	remote_id = p_remote_data[0]
	name = p_remote_data[1]

	var needs_update = false
	var changed = []
	for property in p_remote_data[2]:

		var value = property[5]
		
		var dic = {
			"name": property[0],
			"type": property[1],
			"hint": property[2],
			"hint_string": property[3],
			"usage": property[4]
		}

		if dic.name == "Node/path": dic.name = "Minstance_path"

		if dic.type == TYPE_OBJECT:
			if value is String:
				value = load(value)
				
			if value is EncodedObjectAsID:
				dic.type = TYPE_INT
				dic.hint = 25 # PROPERTY_HINT_OBJECT_ID
				dic.hint_string = "Object"
				value = value.object_id

		if not old_prop.has(dic.name):
			__properties[dic.name] = null
			needs_update = true

		if old_prop.has(dic.name) and not deep_equal(__properties[dic.name],value):
			__properties[dic.name] = value
			if instance.minstance_main.inspected_object == self:
				instance.minstance_main.get_editor_interface().get_inspector().refresh()
			
		if not dic.name == "script":
			__remote_properties.append(dic)

	if needs_update: notify_property_list_changed()

func _get(property):
	if __properties.has(property):
		return __properties[property]
	return
	
func _set(property, value) -> bool:
	if not __properties.has(property):
		return false

	__properties[property] = value
	instance.set_object_property(remote_id, property, value)

	return true
	
func _to_string() -> String:
	return "MinstanceRemote:%s" % remote_id
