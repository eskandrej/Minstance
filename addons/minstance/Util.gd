static func get_toolbuttons_by_shortcut_name(parent, shortcuts_names) -> Dictionary:
	var buttons = {}
	for child in parent.get_children():
		if child.get_class() == "ToolButton":
			if child.shortcut:
				for shortcut_name in shortcuts_names:
					if child.shortcut.resource_name == shortcut_name:
						buttons[shortcut_name.to_lower().replace(" ","_")] = child
						shortcuts_names.erase(shortcut_name)
	return buttons

static func color_texture(color, size = Vector2(10,10)) -> GradientTexture2D:
	var gradient_texture := GradientTexture2D.new()
	var gradient := Gradient.new()
	gradient.offsets = [0.0]
	gradient.colors = [color]
	gradient_texture.gradient = gradient
	gradient_texture.width = size.x
	gradient_texture.height = size.y
	return gradient_texture
