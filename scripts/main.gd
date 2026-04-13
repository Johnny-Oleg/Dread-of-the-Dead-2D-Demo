extends Node2D

# 1. PRELOAD SCENES FROM THE FOLDERS
#const DINING_ROOM_SCENE = preload("res://scenes/rooms/dining_room.tscn")
var main_hall_path = "res://scenes/rooms/main_hall.tscn"
const GAME_UI_SCENE = preload("res://scenes/ui/test_ui.tscn")
const GAME_OVER_SCENE = preload("res://scenes/ui/game_over.tscn")
const INVENTORY_SCENE = preload("res://scenes/ui/inventory.tscn")

@onready var pickup_prompt = $UI/PickupPrompt # Adjust path if necessary
@onready var prompt_message = $UI/PickupPrompt/Message
@onready var yes_button = $UI/PickupPrompt/HBoxContainer/YesButton
@onready var no_button = $UI/PickupPrompt/HBoxContainer/NoButton
@onready var game_world = $GameWorld
@onready var ui_layer = $UI
@onready var title_screen = $UI/TitleScreen
@onready var title_layer = $UI/TitleScreen/Title

# Keep track of what is currently loaded so we can delete it later
var current_room: Node = null
var current_ui: Node = null
var inventory_instance: Node = null # Keep track of the inventory
var current_world_item: Area2D = null

func _ready():
	global.game_started = false
	
	# Connect signals
	title_screen.start_game.connect(_on_start_game)
	title_screen.exit_game.connect(_on_exit_game)
	global.player_died.connect(_on_player_died)
	yes_button.pressed.connect(_on_yes_pressed)
	no_button.pressed.connect(_on_no_pressed)
	pickup_prompt.visible = false

# =========================
# GAME FLOW
# =========================

func _on_start_game():
	global.game_started = true

	# 1. Hide the Title Screen
	#title_screen.visible = false # You cannot hide a parent node with gd attached so hide its child node
	title_layer.visible = false
	

	# 2. Spawn the Dining Room DEPRICATED
	#current_room = DINING_ROOM_SCENE.instantiate()
	#game_world.add_child(current_room) # Adds it to the tree!
	
	# --- LOGIC START ---
	# 2. Set the starting point BEFORE instantiating the room
	TransitionManager.next_spawn_id = "MainHall_Start"
	
	# 3. Load the Main Hall dynamically
	var starting_room_scene = load(main_hall_path)
	current_room = starting_room_scene.instantiate()
	game_world.add_child(current_room) 
	# --- LOGIC END ---

	# 3. Spawn the Gameplay UI
	current_ui = GAME_UI_SCENE.instantiate()
	ui_layer.add_child(current_ui)

	# 4. SPAWN THE INVENTORY (But keep it hidden!)
	inventory_instance = INVENTORY_SCENE.instantiate()
	ui_layer.add_child(inventory_instance)
	inventory_instance.visible = false
	
	# 5. Hide the mouse for gameplay
	#Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _on_exit_game():
	get_tree().quit()

func _on_player_died():
	# 1. Show the quick "You Died" overlay (the Died node in your tree)
	$UI/Died.visible = true 
	
	# 2. Stop the world (Zombies, moaning, movement)
	if current_room != null:
		current_room.process_mode = PROCESS_MODE_DISABLED # Freezes the room
		# Or queue_free() if you want them gone instantly
	if inventory_instance != null:
		inventory_instance.queue_free()
	
	# 3. Wait for the dramatic pause
	await get_tree().create_timer(3.0).timeout
	
	# 4. Clean up and load the actual Game Over menu
	if current_room != null: current_room.queue_free()
	if current_ui != null: current_ui.queue_free()
	$UI/Died.visible = false

	var go_screen = GAME_OVER_SCENE.instantiate()
	ui_layer.add_child(go_screen)
	#Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# =========================
# INPUT HANDLING
# =========================

func _unhandled_input(event):
	# Only allow opening the inventory if the game is actually running, and a player is not grabbed
	# Listen for the inventory button
	if event.is_action_pressed("toggle_inventory") and global.game_started and not global.game_over:
		
		# GUARD CLAUSE 1: Is the pickup prompt currently on screen?
		if pickup_prompt.visible:
			return # Stop right here, don't open the diary
			
		# GUARD CLAUSE 2: Is Arthur being grabbed?
		# We grab the player node dynamically to check his state.
		# (Make sure your Player root node is added to a group called "player")
		var player = get_tree().get_first_node_in_group("player")
		if player and player.is_grabbed:
			return # Stop right here, he is fighting for his life!

		# If both checks pass, it is safe to open/close the diary
		toggle_diary()

func toggle_diary():
	if inventory_instance.visible:
		# CLOSE INVENTORY
		inventory_instance.visible = false
		get_tree().paused = false # Unfreeze the game
		#Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN) # Hide mouse for gameplay
	else:
		# OPEN INVENTORY
		#inventory_instance.update_condition()
		inventory_instance.visible = true
		inventory_instance.on_open() # Run the health and ammo check
		get_tree().paused = true # Freeze the zombies!
		#Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) # Show mouse to click items

func show_pickup_prompt(world_item_node: Area2D):
	current_world_item = world_item_node
	var item_data = current_world_item.get_item_data()
	
	prompt_message.text = "Will you take the " + item_data.name + "?"
	
	get_tree().paused = true
	pickup_prompt.visible = true
	yes_button.grab_focus() # Automatically highlight 'Yes' for gamepad/keyboard users
	print(item_data, pickup_prompt.visible)

func _on_yes_pressed():
	if current_world_item:
		var item_data = current_world_item.get_item_data()
		var inventory = get_tree().get_first_node_in_group("inventory_ui")
		
		if inventory and inventory.add_item(item_data):
			# Tell the WorldState we picked this up!
			# We need to know what room we are currently in.
			var current_room = get_tree().current_scene
			WorldState.pick_item(WorldState.current_room_name, current_world_item.state_id)
			
			# Item was added! Delete it from the floor.
			current_world_item.queue_free()
		else:
			# Inventory was full! Maybe play a "buzzer" sound here later.
			print("Cannot pick up, inventory full!")
			
	close_pickup_prompt()

func _on_no_pressed():
	close_pickup_prompt()

func close_pickup_prompt():
	current_world_item = null
	pickup_prompt.visible = false
	get_tree().paused = false
	
func change_room(path: String):
	if current_room:
		current_room.queue_free() # Delete old room
	
	var new_room_resource = load(path)
	current_room = new_room_resource.instantiate()
	game_world.add_child(current_room)
	
	
	
