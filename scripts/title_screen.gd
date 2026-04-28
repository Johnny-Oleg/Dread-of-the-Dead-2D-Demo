extends Node2D

signal start_game
signal exit_game

@onready var start_button = $Title/GameStart/VBoxContainer/StartGame
@onready var exit_button = $Title/GameStart/VBoxContainer/ExitButton
@onready var music = $TitleMusic

@export var focus_color: Color = Color(1.0, 0.0, 0.0, 1.0) # Red (Change to fit your vibe!)
@export var default_color: Color = Color(1.0, 1.0, 1.0, 1.0) # White

func _ready():
	# 1. Standard click/press connections
	start_button.pressed.connect(_on_start_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

	# 2. Connect focus signals for gamepad visual feedback
	# We use .bind() so we can use one function for all buttons
	start_button.focus_entered.connect(_on_button_focused.bind(start_button))
	start_button.focus_exited.connect(_on_button_unfocused.bind(start_button))
	
	exit_button.focus_entered.connect(_on_button_focused.bind(exit_button))
	exit_button.focus_exited.connect(_on_button_unfocused.bind(exit_button))

	# 3. Synchronize Mouse and Gamepad!
	# If a player uses the mouse, force the gamepad focus to jump to that button too.
	start_button.mouse_entered.connect(start_button.grab_focus)
	exit_button.mouse_entered.connect(exit_button.grab_focus)

	# 4. Give the gamepad a starting point
	start_button.grab_focus()

# --- FOCUS VISUALS ---

func _on_button_focused(button: Button):
	button.modulate = focus_color

func _on_button_unfocused(button: Button):
	button.modulate = default_color

# --- BUTTON LOGIC ---

func _on_start_pressed():
	music.stop()
	start_game.emit()

func _on_exit_pressed():
	exit_game.emit()
	
