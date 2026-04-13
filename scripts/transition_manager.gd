extends CanvasLayer

# This stores the door ID we are trying to reach during the scene load
var next_spawn_id: String = ""

# The Black Screen UI
var color_rect: ColorRect

func _ready():
	# 1. TELL THIS SCRIPT TO NEVER PAUSE
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Create the black screen via code so you don't have to make a UI scene
	layer = 100 # Put it above EVERYTHING
	color_rect = ColorRect.new()
	color_rect.color = Color(0, 0, 0, 0) # Start transparent
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT) # Cover the whole screen
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(color_rect)

func fade_to_room(scene_path: String, spawn_id: String):
	# 1. Store where we want to spawn
	next_spawn_id = spawn_id
	
	# 2. Pause the game so enemies don't attack while fading
	get_tree().paused = true 
	
	# 3. Fade to Black (using Godot 4 Tweens)
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, 0.5) # Fade to alpha 1.0 over 0.5 seconds
	
	# Wait for fade to finish
	await tween.finished
	
	# 4. Swap the Scene!
	#get_tree().change_scene_to_file(scene_path)
	var main_node = get_tree().root.get_node("Main") # Make sure your root node is named "Main"
	main_node.change_room(scene_path)
	
	# 5. The new scene takes a frame to load, so wait one frame
	await get_tree().process_frame
	
	# 6. Fade back in
	var fade_in = create_tween()
	fade_in.tween_property(color_rect, "color:a", 0.0, 0.5)
	
	# 7. Unpause
	await fade_in.finished
	get_tree().paused = false
	
	
