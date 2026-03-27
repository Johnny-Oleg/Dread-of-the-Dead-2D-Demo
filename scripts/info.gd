extends Node2D

@onready var health_label = $HealthLabel
@onready var ammo_label = $AmmoLabel
@onready var enemy_label = $EnemyLabel


func _process(delta):

	health_label.text = "HP: " + str(int(global.player_health))
	ammo_label.text = "Ammo: " + str(global.current_ammo) + "/" + str(global.reserve_ammo)
# optional debug
	#if player.last_hit_enemy != null:
		#enemy_label.text = "Enemy HP: " + str(player.last_hit_enemy.health)
