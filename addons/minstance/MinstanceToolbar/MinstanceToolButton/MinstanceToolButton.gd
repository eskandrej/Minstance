tool
extends Button

onready var popup_panel = $PopupMenu
onready var minstance_settings_dialog = $MinstanceSettingsDialog

var minstance_main = null

var colors = [Color.coral]

func _ready() -> void:
	popup_panel.connect("id_pressed", self, "_on_popup_item_pressed")

func _on_minstance_status_changed(status:int) -> void:
	if status == minstance_main.STATUS.STARTED:
		disabled = true
	if status == minstance_main.STATUS.STOPPED:
		disabled = false

func initialize(p_minstance_main) -> void:
	minstance_main = p_minstance_main
	minstance_settings_dialog.minstance_main = minstance_main	
	minstance_main.connect("status_changed", self, "_on_minstance_status_changed")


func _on_popup_item_pressed(id) -> void:
	if id == 0:
		minstance_settings_dialog.popup_centered()
		
func _on_Control_gui_input(event) -> void:
	if not disabled:
		if event is InputEventMouseButton and event.pressed:
			match event.button_index:
				BUTTON_LEFT:
					minstance_main.start()
					event.pressed = false
					
				BUTTON_RIGHT:
					popup_panel.popup(Rect2(event.global_position, popup_panel.rect_size))
					event.pressed = false
