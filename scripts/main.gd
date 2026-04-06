extends Node2D

# 1. PRELOAD SCENES FROM THE FOLDERS
const DINING_ROOM_SCENE = preload("res://scenes/rooms/dining_room.tscn")
const GAME_UI_SCENE = preload("res://scenes/ui/test_ui.tscn")
const GAME_OVER_SCENE = preload("res://scenes/ui/game_over.tscn")
const INVENTORY_SCENE = preload("res://scenes/ui/inventory.tscn")

@onready var game_world = $GameWorld
@onready var ui_layer = $UI
@onready var title_screen = $UI/TitleScreen
@onready var title_layer = $UI/TitleScreen/Title

# Keep track of what is currently loaded so we can delete it later
var current_room: Node = null
var current_ui: Node = null
var inventory_instance: Node = null # Keep track of the inventory

func _ready():
	global.game_started = false
	
	# Connect signals
	title_screen.start_game.connect(_on_start_game)
	title_screen.exit_game.connect(_on_exit_game)
	global.player_died.connect(_on_player_died)

# =========================
# GAME FLOW
# =========================

func _on_start_game():
	global.game_started = true

	# 1. Hide the Title Screen
	#title_screen.visible = false # You cannot hide a parent node with gd attached so hide its child node
	title_layer.visible = false
	

	# 2. Spawn the Dining Room
	current_room = DINING_ROOM_SCENE.instantiate()
	game_world.add_child(current_room) # Adds it to the tree!

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
	# Only allow opening the inventory if the game is actually running
	if event.is_action_pressed("toggle_inventory") and global.game_started and not global.game_over:
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
