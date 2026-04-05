extends Node2D

# 1. PRELOAD SCENES FROM THE FOLDERS
const DINING_ROOM_SCENE = preload("res://scenes/rooms/dining_room.tscn")
const GAME_UI_SCENE = preload("res://scenes/ui/test_ui.tscn") # Make sure this name matches your file!
const GAME_OVER_SCENE = preload("res://scenes/ui/game_over.tscn")

@onready var game_world = $GameWorld
@onready var ui_layer = $UI
@onready var title_screen = $UI/TitleScreen
@onready var title_layer = $UI/TitleScreen/Title

# Keep track of what is currently loaded so we can delete it later
var current_room: Node = null
var current_ui: Node = null

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

	# 4. Hide the mouse for gameplay
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
	
	# 3. Wait for the dramatic pause
	await get_tree().create_timer(3.0).timeout
	
	# 4. Clean up and load the actual Game Over menu
	if current_room != null: current_room.queue_free()
	if current_ui != null: current_ui.queue_free()
	$UI/Died.visible = false

	var go_screen = GAME_OVER_SCENE.instantiate()
	ui_layer.add_child(go_screen)
	#Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

#@onready var game_world = $GameWorld
#@onready var music = $GameWorld/DiningRoom/BGM
#@onready var player = $GameWorld/DiningRoom/YSort/Player # $Player
#@onready var zombie =  $GameWorld/DiningRoom/YSort/Zombie # $Zombie
#@onready var game_ui = $UI
#@onready var title_screen = $UI/TitleScreen
#@onready var title_layer = $UI/TitleScreen/Title
#@onready var start_game = $UI/TitleScreen/Title/GameStart/VBoxContainer/StartGame
#@onready var exit_game = $UI/TitleScreen/Title/GameStart/VBoxContainer/ExitButton
#
#func _ready():
	#
	## Initial state
	#global.game_started = false
	#
	#game_world.visible = false
	#music.stop()
	#player.visible = false
	#player.set_process(false)
	#player.set_physics_process(false)
	#zombie.visible = false
	#
	## (optional) hide gameplay UI if you want
	#game_ui.get_node("GameUITest").visible = false
#
	## Connect signals from title screen
	#title_screen.start_game.connect(_on_start_game)
	#title_screen.exit_game.connect(_on_exit_game)
	#
	## This makes the mouse invisible but it can still click things
	##if global.game_started == true:
		##Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
#
## =========================
## GAME FLOW
## =========================
#
#func _on_start_game():
	#global.game_started = true
#
	## Hide title
	#title_layer.visible = false
	#print("Title visible: ", title_screen.visible)
	#print("Canvas visible: ", title_screen.get_node("Title").visible)
#
	## Enable gameplay
	#game_world.visible = true
	#music.play()
	#player.visible = true
	#player.set_process(true)
	#player.set_physics_process(true)
	#zombie.visible = true
	#game_ui.get_node("GameUITest").visible = true
	#player.z_index = int(player.global_position.y)
#
#func _on_exit_game():
	#get_tree().quit()
	#
	#
	#
