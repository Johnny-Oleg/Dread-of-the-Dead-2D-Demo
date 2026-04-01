extends Node2D

@onready var health_label = $HealthLabel
@onready var ammo_label = $AmmoLabel
@onready var enemy_label = $EnemyLabel
@onready var enemy_state = $EnemyState

@onready var enemy = $"../../../GameWorld/DiningRoom/YSort/Zombie"
@onready var player = $"../../../GameWorld/DiningRoom/YSort/Player"

func _process(_delta):
	health_label.text = "HP: %d" % int(global.player_health)
	ammo_label.text = "Ammo: %d/%d" % [global.current_ammo, global.reserve_ammo]

	if enemy != null:
		enemy_label.text = "Enemy HP: %d" % enemy.health
		enemy_state.text = "Enemy state: %s" % enemy.STATE_NAMES[enemy.current_state]
		
