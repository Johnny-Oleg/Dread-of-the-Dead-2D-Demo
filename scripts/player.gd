extends CharacterBody2D

# =========================
# REFERENCES
# =========================
@onready var body = $Body
@onready var sprite: AnimatedSprite2D = $Body/AnimatedSprite2D
@onready var shoot_origin = $ShootOrigin

# Timers
@onready var reload_timer = $ReloadTimer
@onready var hurt_timer = $HurtTimer

# =========================
# MOVEMENT
# =========================
@export var walk_speed: float = 140.0
@export var run_speed: float = 260.0


# SHOOTING
@onready var shoot_ray: RayCast2D = $ShootRay

@export var fire_rate: float = 0.4
var can_shoot: bool = true

# =========================
# STATE
# =========================
var is_aiming: bool = false
var is_running: bool = false
var is_moving: bool = false

# Direction tracking
var move_dir: Vector2 = Vector2.ZERO
var aim_dir: Vector2 = Vector2.DOWN
var last_facing_dir: Vector2 = Vector2.DOWN

var debug_timer := 0.0

# =========================
# CORE LOOP
# =========================
func _physics_process(delta):
	
	# optional
	debug_timer += delta

	if debug_timer > 0.3:
		debug_timer = 0
		debug_print()
	# ====================	
		
	#if global.game_over or not global.game_started:
		#return

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

	# Movement input
	move_dir = Vector2.ZERO
	
	move_dir.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	move_dir.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	move_dir = move_dir.normalized()
	
	is_moving = move_dir.length() > 0

	# States
	is_running = Input.is_action_pressed("run") and is_moving and not is_aiming
	is_aiming = Input.is_action_pressed("aim")
	
	# Update last facing from movement
	if is_moving and not is_aiming:
		last_facing_dir = move_dir
		
	# Shooting
	if Input.is_action_pressed("shoot") and can_shoot:
		shoot()

# =========================
# MOVEMENT
# =========================
func handle_movement():
	
	# Lock movement while aiming (RE style)
	if is_aiming:
		velocity = Vector2.ZERO
		return

	var speed = walk_speed
	
	if is_running:
		speed = run_speed
	
	# Danger state slow
	if global.is_player_in_danger():
		speed *= 0.9
	
	velocity = move_dir * speed

# =========================
# AIMING (8-direction)
# =========================
func handle_aiming():

	if not is_aiming:
		return

	var mouse_pos = get_global_mouse_position()
	aim_dir = (mouse_pos - global_position).normalized()

	# While aiming, override facing
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

	can_shoot = false
	reload_timer.start(fire_rate)

	# Rotate ray toward aim
	var target_global = global_position + aim_dir * 500
	shoot_ray.target_position = shoot_ray.to_local(target_global)
	shoot_ray.force_raycast_update()

	if shoot_ray.is_colliding():
		var collider = shoot_ray.get_collider()

		if collider.is_in_group("enemy"):
			print("HIT ENEMY: ", collider.name)
			collider.take_damage(1) # we’ll add this next
	else:
		print("MISS")
	print("Ray target: ", shoot_ray.target_position)
	print("Is colliding: ", shoot_ray.is_colliding())
	print("BANG!")

# =========================
# ANIMATION SYSTEM
# =========================
func update_animation():

	# PRIORITY:
	# 1. Aim
	# 2. Move
	# 3. Idle

	if is_aiming:
		play_aim_animation()
	elif is_moving:
		play_move_animation()
	else:
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
	
	# Also update facing while moving
	last_facing_dir = move_dir

# =========================
# IDLE ANIMATIONS (4-dir)
# =========================
func play_idle_animation():

	#var dir_name = get_4_direction_name(move_dir if move_dir != Vector2.ZERO else aim_dir)
	#
	#if global.is_player_in_danger():
		#sprite.play("danger_idle_" + dir_name)
	#else:
		#sprite.play("idle_" + dir_name)
	
	var dir_name = get_4_direction_name(last_facing_dir)
	
	if global.is_player_in_danger():
		sprite.play("danger_idle_" + dir_name)
	else:
		sprite.play("idle_" + dir_name)

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
	can_shoot = true
