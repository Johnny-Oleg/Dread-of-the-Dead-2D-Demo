extends Node2D

# Expose this so you can type "DiningRoom" or "MainHall" in the Inspector for each scene
@export var room_name: String = "" 
@onready var background = $RoomBG # Ensure your background Sprite2D is named this!
var player_scene = preload("res://scenes/actors/player.tscn")
@onready var howl_timer = $Timer
@onready var howl_sfx = $HowlPlayer

func _ready():
	if room_name == "":
		print("WARNING: You forgot to set the room_name in the inspector for ", name)
		return
	
	WorldState.current_room_name = room_name
	
	setup_room_audio()
	setup_camera_limits()
	spawn_player()
	sync_room_state()
	#bgm.play()
	
	# test ui optional DELETE later
	# --- Tell the UI to update its enemy tracking ---
	var ui = get_tree().get_first_node_in_group("game_ui") # Make sure your UI node is in the "game_ui" group!
	if ui and ui.has_method("refresh_enemy_tracking"):
		ui.refresh_enemy_tracking()

func setup_camera_limits():
	var player = get_tree().get_first_node_in_group("player")
	if player and background:
		var cam = player.get_node("Camera2D") # Adjust path if your camera is named differently
		
		# Get the pixel dimensions of the background sprite
		var rect = background.get_rect()
		
		# Apply those dimensions to the camera limits
		#cam.limit_left = int(rect.position.x)
		#cam.limit_right = int(rect.end.x)
		#cam.limit_top = int(rect.position.y)
		#cam.limit_bottom = int(rect.end.y)

func sync_room_state():
	# 1. Sync all items in the room
	var items_in_room = get_tree().get_nodes_in_group("world_items")
	
	for item in items_in_room:
		if item.state_id != "":
			if WorldState.is_item_picked(room_name, item.state_id):
				item.queue_free() 
				
	# 2. Sync all enemies in the room
	#var enemies_in_room = get_tree().get_nodes_in_group("enemies")
#
	#for enemy in enemies_in_room:
		#print(enemy, enemy.state_id)
		 ## This 'in' check prevents the crash if the node isn't set up right
		#if "state_id" in enemy and enemy.state_id != "":
			#if not WorldState.is_enemy_alive(room_name, enemy.state_id):
				#enemy.queue_free()
				#print("Cleanup: Removed dead zombie ", enemy.state_id)
	var enemies_in_room = get_tree().get_nodes_in_group("zombie")
	
	for enemy in enemies_in_room:
		# PREVENT THE CRASH: Only look at enemies that are children of THIS room
		if not is_ancestor_of(enemy):
			continue 
			
		if "state_id" in enemy and enemy.state_id != "":
			# PREVENT DICTIONARY CRASH: Check if the enemy actually exists in WorldState
			if WorldState.rooms[room_name]["enemies"].has(enemy.state_id):
				
				# If the enemy is marked as dead in the Autoload...
				if not WorldState.is_enemy_alive(room_name, enemy.state_id):
					# KEEP THE CORPSE: Force the zombie into the DEAD state instead of queue_free()
					enemy.change_state(enemy.State.DEAD)
					
					# Turn off their collision so Arthur doesn't bump into the corpse
					if enemy.has_node("CollisionShape2D"):
						enemy.get_node("CollisionShape2D").set_deferred("disabled", true)
	
#func spawn_player():
	#print("DEBUG: Attempting to spawn Arthur. ID is: ", TransitionManager.next_spawn_id)
	#var spawn_id = TransitionManager.next_spawn_id
	#var spawn_position = Vector2.ZERO
	#
	## 1. Find the correct Marker2D
	#if spawn_id != "":
		## Look for a node named "Spawn_" + the ID
		#var marker = find_child("Spawn_" + spawn_id, true, false) 
		#if marker and marker is Marker2D:
			#spawn_position = marker.global_position
		#else:
			#print("ERROR: Could not find spawn point: Spawn_", spawn_id)
	#
	## 2. Instantiate player
	#var arthur = player_scene.instantiate()
	#
	## 3. Place him in the YSort
	##var ysort = get_node("YSort") # Adjust this if your YSort is named differently
	#
	#var ysort = find_child("YSort", true, false)
	#if not ysort:
		#print("CRITICAL ERROR: YSort node not found in ", name)
		#return
	#ysort.add_child(arthur)
	#
	## 4. Move him to the spawn point
	#arthur.global_position = spawn_position
	#
	## Re-run camera limits so the camera snaps to his new position
	#setup_camera_limits()
	#
		
func spawn_player():
	var spawn_id = TransitionManager.next_spawn_id
	var spawn_position = Vector2.ZERO
	
	# 1. Find the Marker
	if spawn_id != "":
		var marker_name = "Spawn_" + spawn_id
		var marker = find_child(marker_name, true, false)
		if marker:
			spawn_position = marker.global_position
			print("Found marker: ", marker_name, " at ", spawn_position)
		else:
			print("ERROR: Marker not found: ", marker_name)
	else:
		print("WARNING: No spawn_id provided. Spawning at (0,0)")

	# 2. Instantiate and Add
	var arthur = player_scene.instantiate()
	var ysort = find_child("YSort", true, false)
	
	if ysort:
		ysort.add_child(arthur)
		arthur.global_position = spawn_position
		print("Arthur added to YSort at ", arthur.global_position)
	else:
		print("ERROR: Could not find YSort node!")
		return

	# 3. Force Camera Update
	await get_tree().process_frame # Wait 1 frame for Arthur to "exist"
	setup_camera_limits()
	
func setup_room_audio():
	# 1. Handle Background Music
	if room_name == "SaveRoom":
		SoundManager.play_safe()
	else:
		SoundManager.play_creepy()

	# 2. Handle Specific Room Ambience
	if room_name == "DiningRoom":
		SoundManager.start_dining_ambience()
	else:
		# If we aren't in the Dining Room, make sure the timer is off
		SoundManager.stop_dining_ambience()
