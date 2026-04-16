extends CharacterBody2D

# =========================
# REFERENCES
# =========================
@onready var body = $Body
@onready var sprite: AnimatedSprite2D = $Body/AnimatedSprite2D
@onready var grapple_sprite: AnimatedSprite2D = $Body/GrappleSprite
@onready var shoot_origin = $ShootOrigin
@onready var interaction_cast = $InteractionCast

# Timers
@onready var reload_timer = $ReloadTimer
@onready var hurt_timer = $HurtTimer
@onready var fire_timer = $FireTimer # shoot_cooldown_timer

# Sound Effects
@onready var pistol_shot = $SoundEffects/PistolShot
@onready var sfx_pistol_reload = $SoundEffects/PistolReload
@onready var sfx_run = $SoundEffects/Run
@onready var sfx_walk = $SoundEffects/Walk
@onready var sfx_hurt = $SoundEffects/Hurt


# =========================
# MOVEMENT
# =========================
@export var walk_speed: float = 140.0
@export var run_speed: float = 260.0

# SHOOTING
@onready var shoot_ray: RayCast2D = $ShootRay
@export var fire_rate: float = 0.4
var can_shoot: bool = true

# RELOAD
var is_reloading: bool = false
var reload_time_full: float = 2.4
var reload_time_partial: float = 1.4

# =========================
# STATE
# =========================
var is_aiming: bool = false
var is_running: bool = false
var is_moving: bool = false
var is_grabbed = false

# =========================
# ZOMBIE GRAB
# =========================
var current_attacker: CharacterBody2D = null # Store the zombie here
var struggle_count: int = 0
var struggle_goal: int = 15 # How many mashes to escape early

# Direction tracking
var move_dir: Vector2 = Vector2.ZERO
var aim_dir: Vector2 = Vector2.DOWN
var last_facing_dir: Vector2 = Vector2.DOWN

var debug_timer := 0.0

# Aiming Modes
var is_auto_aim_enabled: bool = true # Toggled by 'Q'
var targets_in_room: Array = []      # List of all living enemies
var target_index: int = 0            # Which enemy we are currently locked onto

# =========================
# CORE LOOP
# =========================
func _physics_process(delta):
	
	if is_grabbed:
		if Input.is_action_just_pressed("ui_accept"): # Or whatever your mash key is
			struggle_count += 1
			# Optional: shake the screen or play a struggle sound here
	
	# optional
	debug_timer += delta

	if debug_timer > 0.3:
		debug_timer = 0
		debug_print()
	# ====================	
	if global.player_health <= 0:
		trigger_game_over()
	if global.game_over or not global.game_started:
		return

	handle_input()
	handle_movement()
	handle_aiming()
	update_animation()

	move_and_slide()
	
	debug_print() # optional

# =========================
# INPUT
# =========================
func handle_input():
	if is_grabbed:
		return
	
	# Movement input NEW
	move_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	is_moving = move_dir.length() > 0

	# States
	is_running = Input.is_action_pressed("run") and is_moving and not is_aiming
	is_aiming = Input.is_action_pressed("aim")
	
	# Update last facing from movement
	if is_moving and not is_aiming:
		last_facing_dir = move_dir
		
	# 1. Toggle Aim Mode (Q) - Unrestrained
	if Input.is_action_just_pressed("auto_aim"):
		is_auto_aim_enabled = !is_auto_aim_enabled
		print("Auto-Aim: ", is_auto_aim_enabled)

	is_aiming = Input.is_action_pressed("aim")

	# 2. Logic for Auto-Aiming
	if is_auto_aim_enabled and is_aiming:
		# Initial Snap: Refresh list and grab closest
		if Input.is_action_just_pressed("aim"):
			refresh_targets()
			target_index = 0 
		
		# Cycle Targets (Tab/Z) while holding Aim
		if Input.is_action_just_pressed("switch_target") and targets_in_room.size() > 1:
			target_index = (target_index + 1) % targets_in_room.size()
			# Safety check if an enemy died while we were aiming
			if not is_instance_valid(targets_in_room[target_index].owner) or targets_in_room[target_index].owner.current_state == targets_in_room[target_index].owner.State.DEAD:
				refresh_targets()
				target_index = 0	
		
	# Shooting
	if Input.is_action_pressed("shoot") and can_shoot:
		shoot()
		
	# Reload input
	if Input.is_action_just_pressed("reload"):
		start_reload()
		
	# Cancel reload if moving (RE style)
	if is_reloading and is_moving and not is_aiming:
		cancel_reload()

# =========================
# MOVEMENT
# =========================
func handle_movement():
	
	# Lock movement completely if aiming or reloading (RE style)
	if is_aiming or is_reloading:
		velocity = Vector2.ZERO
		sfx_run.stop() # <-- Stops walking sound when aiming or reloading
		sfx_walk.stop()
		return

	var speed = walk_speed
	
	if is_running:
		speed = run_speed
	
	# Danger state slow
	if global.is_player_in_danger():
		speed *= 0.9
	
	velocity = move_dir * speed
	
	# Rotate the interaction net
	# Only change rotation if we are actively moving
	if move_dir != Vector2.ZERO:
		# .angle() converts the direction vector straight into the correct rotation!
		interaction_cast.rotation = move_dir.angle()

# =========================
# AIMING (8-direction)
# =========================
func handle_aiming():

	if not is_aiming or is_reloading:
		return
	#
	#var mouse_pos = get_global_mouse_position()
	#aim_dir = (mouse_pos - global_position).normalized()
#
	## While aiming, override facing
	#last_facing_dir = aim_dir
	#shoot_ray.target_position = aim_dir * 500
	
	var target_found = false

	# MODE A: AUTO-AIM
	if is_auto_aim_enabled and targets_in_room.size() > 0:
		var current_target = targets_in_room[target_index]
		
		# Double-check target is still valid/alive
		if is_instance_valid(current_target) and current_target.owner.current_state != current_target.owner.State.DEAD:
			aim_dir = (current_target.global_position - global_position).normalized()
			target_found = true
		else:
			# If target died, refresh mid-aim
			refresh_targets()

	# MODE B: MANUAL AIM (Fallback if no targets or auto-aim is OFF)
	if not target_found:
		var mouse_pos = get_global_mouse_position()
		aim_dir = (mouse_pos - global_position).normalized()

	# Apply final aim direction
	last_facing_dir = aim_dir
	shoot_ray.target_position = aim_dir * 500
	

# =========================
# SHOOTING (8-direction)
# =========================
func shoot():
	if not is_aiming:
		return
	if not can_shoot:
		return
	if is_reloading:
		return
	if is_grabbed:
		return 

	# PREVENT NEGATIVE AMMO: Only shoot if we have bullets!
	if global.current_ammo > 0:
		global.current_ammo -= 1
		print("BANG!")
		# ... play animation, cast raycast, etc.
		pistol_shot.play()
		can_shoot = false
		fire_timer.start(fire_rate)
	else:
		print("Click... Out of ammo!")
		
	## Rotate ray toward aim OLD
	#var target_global = global_position + aim_dir * 500
	#shoot_ray.target_position = shoot_ray.to_local(target_global)
	#shoot_ray.force_raycast_update()
	
	# Just set the target position directly using the aim_dir
	shoot_ray.target_position = aim_dir * 500
	shoot_ray.force_raycast_update()

	if shoot_ray.is_colliding():
		var target = shoot_ray.get_collider()
		# Remember: player's RayCast mask should hit Layer 5 (EnemyHurtbox)
		if target.is_in_group("zombie_hurtbox"):
			var is_crit = randf() < global.pistol_stats["crit_chance"]
			# Access the zombie script from the hurtbox's owner
			target.owner.take_damage(is_crit)
	#else:
		#print("MISS")
	#print("Ray target: ", shoot_ray.target_position)
	#print("Is colliding: ", shoot_ray.is_colliding())
	#print("BANG!")

# =========================
# ANIMATION SYSTEM
# =========================
func update_animation():

	# PRIORITY:
	# 1. Relaod
	# 2. Aim
	# 3. Move
	# 4. Idle
	# Reload > Aim > Move > Idle

	if is_reloading:
		play_reload_animation()
		return

	if is_aiming:
		play_aim_animation()
		return

	if is_moving:
		if is_running:
			play_run_animation()
			return
		else:
			play_move_animation()
			return

	play_idle_animation()

# =========================
# AIM ANIMATIONS (8-dir)
# =========================
func play_aim_animation():
	var dir_name = get_8_direction_name(aim_dir)
	sprite.play("aim_" + dir_name)

# =========================
# MOVE ANIMATIONS (4-dir)
# =========================
func play_move_animation():
	var dir_name = get_4_direction_name(move_dir)
		
	sprite.play("walk_" + dir_name)
	
	# Check if playing before restarting it
	if not sfx_walk.playing:
		sfx_walk.play()
	
	# Also update facing while moving
	last_facing_dir = move_dir

func play_run_animation():
	var dir_name = get_4_direction_name(move_dir)
	
	sprite.play("run_" + dir_name)
	
	# Check if playing before restarting it
	if not sfx_run.playing:
		sfx_run.play()
			
	# Also update facing while moving
	last_facing_dir = move_dir

# =========================
# IDLE ANIMATIONS (4-dir)
# =========================
func play_idle_animation():
	
	var dir_name = get_4_direction_name(last_facing_dir)
	
	if global.is_player_in_danger():
		sprite.play("danger_idle_" + dir_name)
	else:
		sprite.play("idle_" + dir_name)

	sfx_run.stop()
	sfx_walk.stop()

# =========================
# DIRECTION HELPERS
# =========================

# 4-direction
func get_4_direction_name(dir: Vector2) -> String:

	if abs(dir.x) > abs(dir.y):
		if dir.x > 0:
			return "right"
		else:
			return "left"
	else:
		if dir.y > 0:
			return "down"
		else:
			return "up"

# 8-direction
func get_8_direction_name(dir: Vector2) -> String:

	var angle = rad_to_deg(dir.angle())

	if angle >= -22.5 and angle < 22.5:
		return "right"
	elif angle >= 22.5 and angle < 67.5:
		return "down_right"
	elif angle >= 67.5 and angle < 112.5:
		return "down"
	elif angle >= 112.5 and angle < 157.5:
		return "down_left"
	elif angle >= 157.5 or angle < -157.5:
		return "left"
	elif angle >= -157.5 and angle < -112.5:
		return "up_left"
	elif angle >= -112.5 and angle < -67.5:
		return "up"
	elif angle >= -67.5 and angle < -22.5:
		return "up_right"

	return "down" # fallback

# ================== optional
func debug_print():

	print(
		#"MoveDir: ", move_dir,
		#" | AimDir: ", aim_dir,
		#" | Facing: ", last_facing_dir,
		#" | Moving: ", is_moving,
		#" | Aiming: ", is_aiming
	)
	


func _on_reload_timer_timeout() -> void:
	finish_reload()
	
func play_reload_animation():
	var dir = last_facing_dir

	if is_aiming:
		dir = aim_dir

	var dir_name = get_4_direction_name(dir)
	sprite.play("reload_" + dir_name) # Removed the duplicate line here

func start_reload():
		
	# Block conditions
	if is_reloading:
		return
	if global.current_ammo == global.pistol_stats["mag_size"]:
		return
	if global.reserve_ammo <= 0:
		return
	# (later add: if is_hurt or dead)

	is_reloading = true
	can_shoot = false
	sfx_pistol_reload.play()

	# Choose reload time
	var reload_time = global.pistol_stats["reload_time"]
	var max_mag = global.pistol_stats.mag_size
	var missing_ammo = max_mag - global.current_ammo

	# Only reload if the gun isn't full AND we have spare bullets
	if missing_ammo > 0 and global.reserve_ammo > 0:
		# 1. Find the inventory
		var inventory = get_tree().get_first_node_in_group("inventory_ui")
		if inventory:
			# 2. Ask the inventory to consume the .tres items
			var ammo_gained = inventory.consume_ammo(missing_ammo)
			
			# 3. Add what we successfully grabbed to our gun
			global.current_ammo += ammo_gained
			print("Reloaded ", ammo_gained, " bullets.")

	if global.current_ammo == 0:
		reload_time = 2.4 # empty reload override

	reload_timer.start(reload_time)

	play_reload_animation()
	
func cancel_reload():
	is_reloading = false
	reload_timer.stop()
	can_shoot = true
	sfx_pistol_reload.stop()
	
func finish_reload():

	is_reloading = false
	can_shoot = true
	sfx_pistol_reload.stop()

	var needed = global.pistol_stats["mag_size"] - global.current_ammo
	var to_reload = min(needed, global.reserve_ammo)

	global.current_ammo += to_reload
	global.reserve_ammo -= to_reload


func _on_fire_timer_timeout() -> void:
	can_shoot = true

func refresh_targets():
	targets_in_room.clear()
	var all_hurtboxes = get_tree().get_nodes_in_group("zombie_hurtbox")
	
	for box in all_hurtboxes:
		if is_instance_valid(box.owner) and box.owner.current_state != box.owner.State.DEAD:
			targets_in_room.append(box)
	
	# Sort targets by distance (closest to the player first)
	targets_in_room.sort_custom(func(a, b): 
		return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position)
	)
	
func get_grabbed(zombie: CharacterBody2D):
	if is_grabbed: # Don't get double-grabbed
		return 

	if is_reloading: 
		cancel_reload()
	
	is_aiming = false
	is_grabbed = true
	velocity = Vector2.ZERO
	sfx_run.stop() # <-- Stops walking sound when grabbed by enemy
	sfx_walk.stop()
	
	# 1. Hide regular sprites
	current_attacker = zombie # Save the reference!
	# ... (hide Arthur, hide zombie body, play animation) ...
	sprite.hide()
	# Adjust path to zombie's sprite
	current_attacker.get_node("Body").hide()
	
	# 2. Position and Play the Grapple
	# We move the grapple sprite to the midpoint between them
	grapple_sprite.global_position = (global_position + current_attacker.global_position) / 2
	grapple_sprite.show()
	
	# Determine direction for the 4-way flip logic
	var is_front = (last_facing_dir.dot(global_position.direction_to(current_attacker.global_position)) > 0)
	var is_right = current_attacker.global_position.x > global_position.x
	
	play_grapple_animation(is_front, is_right)

func play_grapple_animation(front: bool, right: bool):
	var anim_name = "grab_front" if front else "grab_back"
	grapple_sprite.flip_h = !right # Flip if the zombie is on the left
	
	if not front: # Inverse flip if the zombie is on the left and behind
		grapple_sprite.flip_h = right
		
	grapple_sprite.play(anim_name)
	#if grapple_sprite.frame == 15:
		#bite.play()

func _on_grapple_sprite_animation_finished() -> void:
	is_grabbed = false
	grapple_sprite.hide()
	var is_front = (last_facing_dir.dot(global_position.direction_to(current_attacker.global_position)) > 0)

	# Show everyone again
	sprite.show()
	if is_instance_valid(current_attacker):
		current_attacker.get_node("Body").show()
		
		if global.player_health <= 0:
			trigger_game_over()
		
		# Apply damage logic
		var damage = 300
		
		if struggle_count >= struggle_goal:
			damage = 150 # 50% damage reduction
			
			# 50% Chance to knock the zombie down (Downed State) and if it in front
			if is_front:
				# Just pass the direction to the zombie
				var shove_dir = (current_attacker.global_position - global_position).normalized()
				current_attacker.get_shoved(shove_dir)

		global.player_health -= damage
		
		# Start HurtTimer for I-Frames
		hurt_timer.start(1.5) 
		
	if global.player_health <= 0:
		trigger_game_over()
		
	struggle_count = 0 # Reset for next time
	current_attacker = null
		
func trigger_game_over():
	if global.game_over: 
		return # Prevent this from firing 50 times a second
		
	global.game_over = true
	global.player_died.emit() # SHOUT TO MAIN.GD!
	
func _unhandled_input(event):
	if event.is_action_pressed("interact"):
		check_interaction()

func check_interaction():
	# Force the cast to update its physics right now (good practice for instant button presses)
	interaction_cast.force_shapecast_update() 
	
	if interaction_cast.is_colliding():
		# Grab the first object the shape touched
		var target = interaction_cast.get_collider(0)
		
		if target.has_method("get_item_data"):
			var main_scene = get_tree().current_scene
			if main_scene.has_method("show_pickup_prompt"):
				main_scene.show_pickup_prompt(target)
				
		if target.has_method("interact"):
			target.interact()
				
