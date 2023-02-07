tool
extends Control

const Window = preload("Window.tscn")

var windows = []
var selected_window = null
var offset_position = null

var factor_screen_widget

onready var monitor_screen = $MonitorScreen
onready var monitor_border = $MonitorBorder
onready var monitor_stand = $MonitorStand

func _ready():
	var ratio = OS.get_screen_size().x / OS.get_screen_size().y

	monitor_screen.rect_size.x =  monitor_screen.rect_size.y * ratio
	monitor_border.rect_size = monitor_screen.rect_size + Vector2(2,2)
	
	var x = monitor_screen.rect_position.x + monitor_screen.rect_size.x / 2
	var y = monitor_screen.rect_position.y +  monitor_screen.rect_size.y - 10
	monitor_stand.rect_position = Vector2(x, y)
	factor_screen_widget = OS.get_screen_size().x / monitor_screen.rect_size.x

func remove_window(window):
	windows.erase(window)
	window.queue_free()
	
func add_window(instance):
	var new_window = Window.instance()
	new_window.instance = instance
	monitor_screen.add_child(new_window)	
	new_window.color = instance.color
	new_window.rect_size = instance.window_size / factor_screen_widget
	new_window.rect_position = instance.window_position / factor_screen_widget
	new_window.connect("deselected",self, "on_window_deselected")
	new_window.connect("selected",self, "on_window_selected")
	windows.append(new_window)
	
	return new_window
	
	
func on_window_selected(p_window, p_offset_position):
	selected_window = p_window
	offset_position = p_offset_position

func on_window_deselected():
	selected_window = null

func _process(_delta):
	for window in windows:
		window.rect_position = window.instance.window_position / factor_screen_widget
		window.color = window.instance.color
		window.rect_size = window.instance.window_size / factor_screen_widget

func _on_MonitorScreen_gui_input(event):
	if event is InputEventMouse:
		if selected_window:
			var a = monitor_screen.get_global_transform().xform_inv(event.global_position) - offset_position
			selected_window.rect_position = Vector2(
				clamp(a.x,0, monitor_screen.rect_size.x-selected_window.rect_size.x),
				clamp(a.y,0, monitor_screen.rect_size.y-selected_window.rect_size.y))
			selected_window.instance.window_position = selected_window.rect_position * factor_screen_widget
