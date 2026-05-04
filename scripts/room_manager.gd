extends Node2D

# Expose this so you can type "DiningRoom" or "MainHall" in the Inspector for each scene
@export var room_name: String = "" 
@onready var background = $RoomBG # Ensure your background Sprite2D is named this!
var player_scene = preload("res://scenes/actors/player.tscn")

func _ready():
	if room_name == "":
		print("WARNING: You forgot to set the room_name in the inspector for ", name)
		return
	
	WorldState.current_room_name = room_name
	
	# 1. VISUALS & LOGIC INSTANTLY (This happens while the screen is still black!)
	#spawn_player()
	#sync_room_state()
	
	# WAIT FOR THE GAME/BROWSER TO SETTLE (CRITICAL breaks the camera smoothness)
	await get_tree().create_timer(0.1).timeout
	spawn_player()
	sync_room_state()
	setup_camera_limits()
	
	# Setup audio LAST, after the scene is physically present
	setup_room_audio()
	
	# test ui optional DELETE later
	# --- Tell the UI to update its enemy tracking ---
	var ui = get_tree().get_first_node_in_group("game_ui") # Make sure your UI node is in the "game_ui" group!
	if ui and ui.has_method("refresh_enemy_tracking"):
		ui.refresh_enemy_tracking()

func setup_camera_limits():
	var player = get_tree().get_first_node_in_group("player")
	if player and background:
		var cam = player.get_node("Camera2D") # Adjust path if your camera is named differently
		
		# 1. FORCE the camera to Arthur's position immediately
		cam.global_position = player.global_position
		
		# 2. Tell the camera to forget its previous position (skips the "slide")
		if cam.has_method("reset_smoothing"):
			cam.reset_smoothing()

		# 3. FIX THE LIMITS: 
		# We use global_position because background.get_rect() is local to the sprite.
		var rect = background.get_rect()
		var scale = background.global_scale
		
		#cam.limit_left = int(background.global_position.x - (rect.size.x / 2) * scale.x)
		#cam.limit_right = int(background.global_position.x + (rect.size.x / 2) * scale.x)
		#cam.limit_top = int(background.global_position.y - (rect.size.y / 2) * scale.y)
		#cam.limit_bottom = int(background.global_position.y + (rect.size.y / 2) * scale.y)

func sync_room_state():
	# 1. Sync all items in the room
	var items_in_room = get_tree().get_nodes_in_group("world_items")
	
	for item in items_in_room:
		# PREVENT THE OVERLAP CRASH: Only look at items that belong to THIS room
		if not is_ancestor_of(item):
			continue 
			
		if "state_id" in item and item.state_id != "":
			# PREVENT DICTIONARY CRASH: Check if the item actually exists in this room's data
			if WorldState.rooms[room_name]["items"].has(item.state_id):
				
				# If it exists and is picked up, delete it
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
					#enemy.change_state(enemy.State.DEAD)
					## Turn off their collision so Arthur doesn't bump into the corpse
					#if enemy.has_node("CollisionShape2D"):
						#enemy.get_node("CollisionShape2D").set_deferred("disabled", true)
					
					# --- Use a new silent setup instead of change_state! ---
					enemy.set_as_already_dead()
					# -------
	
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
	#await get_tree().process_frame # Wait 1 frame for Arthur to "exist"
	setup_camera_limits()
	
func setup_room_audio():
	
	# 1. Handle Background Music
	if room_name == "SaveRoom":
		SoundManager.play_safe()
	elif room_name == "Library":
		SoundManager.play_haunted()
	else:
		SoundManager.play_creepy()

	# 2. Handle Specific Room Ambience
	if room_name == "DiningRoom":
		SoundManager.start_dining_ambience()
	else:
		# If we aren't in the Dining Room, make sure the timer is off
		SoundManager.stop_dining_ambience()
		
	# Handle Clock Ambience
	if room_name == "MainHall":
		SoundManager.start_mainhall_ambience()
	else:
		SoundManager.stop_mainhall_ambience()


		
