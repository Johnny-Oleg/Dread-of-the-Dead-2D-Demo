extends Node2D

var can_skip: bool = false

func _ready():
	# 1. Give the player 1 second to breathe so they don't accidentally 
	# skip the screen if they were mashing the shoot button when they died.
	await get_tree().create_timer(1.0).timeout
	can_skip = true
	
	# 2. Wait the remaining 9 seconds for the auto-restart
	await get_tree().create_timer(9.0).timeout
	
	# 3. If the scene is still active, restart!
	if is_inside_tree():
		restart_game()

func _input(event):
	if not can_skip:
		return
		
	# Check if the input is a keyboard key, a gamepad button, or a mouse click
	if event is InputEventKey or event is InputEventJoypadButton or event is InputEventMouseButton:
		if event.is_pressed():
			restart_game()

func restart_game():
	# Prevent this from triggering twice if the timer and a button press overlap
	set_process_input(false) 
	
	# 1. Wipe the memory!
	SoundManager.instant_stop_all()
	WorldState.reset_state()
	global.reset_game() # (Add this if you have a health/ammo Autoload)
	
	# 2. Reload the entire main scene
	get_tree().reload_current_scene()
	
	
