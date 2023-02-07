tool
extends Panel

var instance

signal active
signal selected
signal deselected

var color setget set_color


func set_color(p_color):
	var stylebox = get("custom_styles/panel")
	color = p_color
	stylebox.set("border_color", p_color)
	var bg_color = p_color
	bg_color.a = 0.2
	stylebox.set("bg_color", bg_color)

func _ready():
	var stylebox = get("custom_styles/panel")
	set("custom_styles/panel",stylebox.duplicate())

func _on_Window_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			emit_signal("selected", self, event.position)
			emit_signal("active")
		else:
			emit_signal("deselected")
