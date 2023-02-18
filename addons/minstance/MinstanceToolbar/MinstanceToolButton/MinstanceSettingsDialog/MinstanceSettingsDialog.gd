@tool
extends Window

const tab_instance = preload("TabInstance.tscn")
var minstance_main = null
var predef_colors = [Color.RED, Color.AQUAMARINE, Color.YELLOW]
var windows = {}

func _on_CloseBtn_pressed():
	minstance_main.debugger_port = int($"%DebbugerPortTextEdit".text)
	minstance_main.remember_window_position_size = $"%RemeberWinPosCheckBtn".pressed
	minstance_main.save_breakpoints = $"%SaveBreakpointsBtn".pressed
	minstance_main.remove_autoload_on_exit = $"%RemoveAutoloadOnExitBtn".pressed
	minstance_main.close_all_instances_on_exit = $"%CloseAllInstancesOnExitBtn".pressed
	minstance_main.spawn_time = $"%SpawnTimeSB".value
	hide()

func add_instance(instance = null):
	if not $"%Instances".visible: 
		$"%Instances".show()
		
	$"%DeleteInstBtn".disabled = false
	
	var tab = tab_instance.instance()
	
	if not instance:
		var name = "Instance %d" %  (minstance_main.instances.size() + 1)
		var color
		if minstance_main.instances.size() < predef_colors.size():
			color = predef_colors[minstance_main.instances.size()]
		else:
			color = Color(randf(), randf(), randf())
		instance = minstance_main.new_instance(name, color, "", Vector2(200,300), Vector2(500,300))
	
	tab.instance = instance
	
	var new_window = $"%Monitor".add_window(instance)
	new_window.connect("active", tab, "set_as_selected_tab")
	windows[tab] = new_window
	$"%Instances".add_child(tab)
	$"%Instances".set_tab_icon(tab.get_index(), instance.icon)
	$"%Instances".current_tab = tab.get_index()	

func _on_AddNewInstBtn_pressed():
	add_instance()


func _on_DeleteInstBtn_pressed():
	var tab_to_delete = $"%Instances".get_current_tab_control()
	if not tab_to_delete:
		return
	if $"%Instances".get_child_count() == 1:
		$"%Instances".hide()
		$"%DeleteInstBtn".disabled = true
		$"%DeleteInstBtn".release_focus()
	minstance_main.remove_instance(tab_to_delete.instance)
	$"%Monitor".remove_window(windows[tab_to_delete])
	tab_to_delete.queue_free()

func popup_centered(pos = Vector2()):
	super(popup_centered(pos))
	$"%AddNewInstBtn".grab_focus()
	minstance_main.update_window_size_position()
	
	$"%DebbugerPortTextEdit".text = str(minstance_main.debugger_port)
	$"%RemeberWinPosCheckBtn".pressed = minstance_main.remember_window_position_size
	$"%SaveBreakpointsBtn".pressed =  minstance_main.save_breakpoints
	$"%RemoveAutoloadOnExitBtn".pressed = minstance_main.remove_autoload_on_exit
	$"%CloseAllInstancesOnExitBtn".pressed = minstance_main.close_all_instances_on_exit
	$"%SpawnTimeSB".value = minstance_main.spawn_time 
	
func _on_VBoxContainer_resized():
	size.y = $VBoxContainer.size.y


func _on_WindowDialog_popup_hide():
	minstance_main.save_config()
