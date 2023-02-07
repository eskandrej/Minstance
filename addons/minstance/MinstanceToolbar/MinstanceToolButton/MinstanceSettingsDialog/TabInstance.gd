tool
extends VBoxContainer

var instance setget set_instance

func set_instance(p_instance) -> void:
	instance = p_instance
	instance.connect("data_changed", self, "_on_data_changed")
	_on_data_changed({
		"name": instance.name,
		"color": instance.color,
		"arguments" : instance.arguments,
		"window_position": instance.window_position,
		"window_size": instance.window_size
	})
	
func _on_data_changed(property) -> void:
		if property.has("name"):
			if $"%TitleLineEdit".text != property.name:
				$"%TitleLineEdit".text = property.name
			if property.name == "":
				name = " "
			else:
				name = property.name
				
		if property.has("color"):
			$"%ColorPickerButton".color = property.color
			
		if property.has("arguments"):
			if $"%ArgumentsLineEdit".text != property.arguments:
				$"%ArgumentsLineEdit".text = property.arguments
				
		if property.has("window_position"):
			$"%WindowPositionXSpinBox".value = property.window_position.x
			$"%WindowPositionYSpinBox".value = property.window_position.y
			
		if property.has("window_size"):
			$"%WindowsSizeXSpinBox".value = property.window_size.x
			$"%WindowsSizeYSpinBox".value = property.window_size.y

func _ready() -> void:
	$"%TitleLineEdit".grab_focus()
	
	
func _on_TitleLineEdit_text_changed(new_text) -> void:
	instance.name = new_text
	
func _on_ArgumentsLineEdit_text_changed(new_text) -> void:
	instance.arguments = new_text
	
func _on_ColorPickerButton_color_changed(color) -> void:
	instance.color = color
	
func _on_WindowPositionXSpinBox_value_changed(value) -> void:
	instance.window_position.x = value

func _on_WindowPositionYSpinBox_value_changed(value) -> void:
	instance.window_position.y = value

func _on_WindowsSizeXSpinBox_value_changed(value) -> void:
	instance.window_size.x = value

func _on_WindowsSizeYSpinBox_value_changed(value) -> void:
	instance.window_size.y = value

func _on_TitleLineEdit_text_entered(new_text) -> void:
	instance.name = new_text
	
func set_as_selected_tab() -> void:
	var tab_container = get_parent()
	if tab_container and tab_container is TabContainer:
		tab_container.current_tab = get_index()
