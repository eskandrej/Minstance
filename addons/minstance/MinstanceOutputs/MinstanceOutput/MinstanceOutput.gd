tool
extends VBoxContainer

onready var color_rect = $ColorRect
onready var _log = $Log


enum {MSG_TYPE_STD, MSG_TYPE_ERROR}

var error_color: Color
var error_icon: Texture
var warning_color: Color
var warning_icon: Texture
var message_color: Color


var instance setget set_instance

func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		yield(self, "ready")
		_log.add_font_override("normal_font", get_font("output_source", "EditorFonts"))
		_log.add_color_override("selection_color", get_color("accent_color", "Editor") * Color(1, 1, 1, 0.4))

		error_color = get_color("error_color", "Editor");
		error_icon = get_icon("Error", "EditorIcons");
		warning_color = get_color("warning_color", "Editor");
		warning_icon = get_icon("Warning", "EditorIcons");
		message_color = get_color("font_color", "Editor") * Color(1, 1, 1, 0.6);

func set_instance(p_instance) -> void:
	instance = p_instance
	instance.connect("data_changed", self, "_on_data_changed")
	color_rect.color = instance.color

func _on_data_changed(property) -> void:
	if property.has("color"):
		color_rect.color = property.color
	
func add_message(message, type) -> void:
	if type == MSG_TYPE_ERROR: 
		_log.push_color(error_color)
		_log.add_image(error_icon)
		_log.add_text(" ")
		
	_log.add_text(message)
	_log.newline()
	
	if type != MSG_TYPE_STD: _log.pop()

func clear() -> void:
	_log.clear()

func _on_ClearBtn_pressed() -> void:
	clear()

func _on_CopyBtn_pressed() -> void:
	OS.clipboard = _log.get_selected_text()
