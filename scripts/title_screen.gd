extends Node2D

signal start_game
signal exit_game

@onready var start_button = $Title/GameStart/VBoxContainer/StartGame
@onready var exit_button = $Title/GameStart/VBoxContainer/ExitButton
@onready var music = $TitleMusic

func _ready():
	start_button.pressed.connect(_on_start_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

func _on_start_pressed():
	music.stop()
	start_game.emit()
	print("title start")

func _on_exit_pressed():
	exit_game.emit()
	
	
