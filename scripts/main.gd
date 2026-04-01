extends Node2D

@onready var game_world = $GameWorld
@onready var player = $GameWorld/DiningRoom/YSort/Player # $Player
@onready var zombie =  $GameWorld/DiningRoom/YSort/Zombie # $Zombie
@onready var game_ui = $UI
@onready var title_screen = $UI/TitleScreen
@onready var title_layer = $UI/TitleScreen/Title
@onready var start_game = $UI/TitleScreen/Title/GameStart/VBoxContainer/StartGame
@onready var exit_game = $UI/TitleScreen/Title/GameStart/VBoxContainer/ExitButton

func _ready():
	
	# Initial state
	global.game_started = false
	
	game_world.visible = false
	player.visible = false
	player.set_process(false)
	player.set_physics_process(false)
	zombie.visible = false
	
	# (optional) hide gameplay UI if you want
	game_ui.get_node("GameUITest").visible = false

	# Connect signals from title screen
	title_screen.start_game.connect(_on_start_game)
	title_screen.exit_game.connect(_on_exit_game)
	

# =========================
# GAME FLOW
# =========================

func _on_start_game():
	global.game_started = true

	# Hide title
	title_layer.visible = false
	print("Title visible: ", title_screen.visible)
	print("Canvas visible: ", title_screen.get_node("Title").visible)

	# Enable gameplay
	game_world.visible = true
	player.visible = true
	player.set_process(true)
	player.set_physics_process(true)
	zombie.visible = true
	game_ui.get_node("GameUITest").visible = true
	player.z_index = int(player.global_position.y)

func _on_exit_game():
	get_tree().quit()
	
	
	
