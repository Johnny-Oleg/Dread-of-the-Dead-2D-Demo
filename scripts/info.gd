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
	if enemy != null and is_instance_valid(enemy) and player != null and is_instance_valid(player):
		
		aim_label.text = "AIM: AUTO" if player.is_auto_aim_enabled else "AIM: MANUAL"
		enemy_label.text = "Enemy HP: %d" % enemy.health
		enemy_state.text = "Enemy state: %s" % enemy.STATE_NAMES[enemy.current_state]
	else:
		refresh_enemy_tracking()
		enemy_label.text = "Enemy HP: None"
		enemy_state.text = "Enemy state: None"
	
func refresh_enemy_tracking():
	# Find the new zombies in the current room
	#var fresh_zombies = get_tree().get_nodes_in_group("zombie")
	## Link your UI labels to these new nodes
	#if fresh_zombies.size() > 0:
		## Example: track the first zombie found
		#enemy = fresh_zombies[0]
	
	# 1. Wait one frame so the old room's zombies are fully deleted
	await get_tree().process_frame 
	
	# 2. Find the new zombies
	var fresh_zombies = get_tree().get_nodes_in_group("zombie")
	
	if fresh_zombies.size() > 0:
		enemy = fresh_zombies[0]
	else:
		enemy = null # Clear it if there are no zombies in the room!
		enemy_label.text = "No enemies found"
