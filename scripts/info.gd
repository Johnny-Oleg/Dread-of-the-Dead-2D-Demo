extends Node2D

@onready var health_label = $HealthLabel
@onready var ammo_label = $AmmoLabel
@onready var enemy_label = $EnemyLabel
@onready var enemy_state = $EnemyState
@onready var aim_label = $AimLabel

# Don't grab these on ready, because they might not exist yet!
var player: Node2D = null
var enemy: Node2D = null

func _ready():
	# Wait one frame to ensure the room and actors are fully loaded
	await get_tree().process_frame 
	
	# Find the nodes dynamically anywhere in the tree!
	player = get_tree().get_first_node_in_group("player")
	enemy = get_tree().get_first_node_in_group("zombie")

func _process(_delta):
	# Update Global Stats
	health_label.text = "HP: %d" % int(global.player_health)
	ammo_label.text = "Ammo: %d/%d" % [global.current_ammo, global.reserve_ammo]

	# Update Enemy Stats (If an enemy exists)
	if enemy != null and is_instance_valid(enemy):
		var enemy_sprite = enemy.get_node("Body/AnimatedSprite2D") # Get sprite relative to the zombie
		#aim_label.text = "sprite: " + str(enemy_sprite.get_animation()) 
		aim_label.text = "AIM: AUTO" if player.is_auto_aim_enabled else "AIM: MANUAL"
		enemy_label.text = "Enemy HP: %d" % enemy.health
		enemy_state.text = "Enemy state: %s" % enemy.STATE_NAMES[enemy.current_state]
	else:
		enemy_label.text = "Enemy HP: None"
		enemy_state.text = "Enemy state: None"

#@onready var health_label = $HealthLabel
#@onready var ammo_label = $AmmoLabel
#@onready var enemy_label = $EnemyLabel
#@onready var enemy_state = $EnemyState
#@onready var aim_label = $AimLabel
#
#@onready var enemy = $"../../../GameWorld/DiningRoom/YSort/Zombie"
#@onready var enemya = $"../../../GameWorld/DiningRoom/YSort/Zombie/Body/AnimatedSprite2D"
#
#@onready var player = $"../../../GameWorld/DiningRoom/YSort/Player"
#
#func _process(_delta):
	##aim_label.text = "AIM: AUTO" if player.is_auto_aim_enabled else "AIM: MANUAL"
	#aim_label.text = "sprite" + str(enemya.get_animation()) 
#
	#health_label.text = "HP: %d" % int(global.player_health)
	#ammo_label.text = "Ammo: %d/%d" % [global.current_ammo, global.reserve_ammo]
#
	#if enemy != null:
		#enemy_label.text = "Enemy HP: %d" % enemy.health
		#enemy_state.text = "Enemy state: %s" % enemy.STATE_NAMES[enemy.current_state]
		#
