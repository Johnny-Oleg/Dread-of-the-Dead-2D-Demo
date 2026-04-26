extends CharacterBody2D

# =========================
# STATE MACHINE
# =========================
enum State {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	HURT,
	DOWNED,
	DEAD,
	STUMBLED,
	SKID,
	WALL_SIT
}

const STATE_NAMES = {
	State.IDLE: "IDLE",
	State.PATROL: "PATROL",
	State.CHASE: "CHASE",
	State.ATTACK: "ATTACK",
	State.HURT: "HURT",
	State.DOWNED: "DOWNED",
	State.DEAD: "DEAD",
	State.STUMBLED: "STUMBLED",
	State.SKID: "SKID",
	State.WALL_SIT: "WALL_SIT"
}

var current_state: State = State.IDLE

# =========================
# STATS
# =========================
var speed := 90.0
var health := 1000
var max_health := 1000

var patrol_radius := 120.0
var patrol_target: Vector2

var idle_timer := 0.0
var repath_timer := 0.0
var attack_timer := 0.0
var hurt_timer := 0.0
var patrol_timeout := 0.0

var vision_range := 350.0
var vision_angle := 90.0
var voice_cooldown := 0.0
var downed_cooldown := 0.0
var recovery_timer: float = 0.0

var last_direction: Vector2 = Vector2.DOWN
@export var state_id: String = ""

# =========================
# REFERENCES
# =========================
#@onready var player: CharacterBody2D = get_tree().get_first_node_in_group("player")
var player: CharacterBody2D = null
@onready var body_collision: CollisionShape2D = $CollisionShape2D
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var sprite: AnimatedSprite2D = $Body/AnimatedSprite2D
@onready var sfx_idle = $SoundEffects/ZombieIdle
@onready var sfx_chase = $SoundEffects/ZombieChase
@onready var sfx_hurt = $SoundEffects/ZombieHurt
@onready var sfx_attack = $SoundEffects/ZombieAttack
@onready var sfx_shamble = $SoundEffects/ZombieShamble
@onready var sfx_bite = $SoundEffects/ZombieBite
@onready var sfx_dead = $SoundEffects/ZombieDead
@export var blood_splat_scene: PackedScene
@export var blood_pool_scene: PackedScene

# =========================
# VISION debug
# =========================
@onready var debug_line: Line2D = $DebugLine

# =========================
# READY
# =========================
func _ready():
	randomize()

	health = [1500, 2000, 2000, 2500, 2500].pick_random()
	max_health = health
	nav_agent.path_desired_distance = 4.0
	nav_agent.target_desired_distance = 8.0

	change_state(State.IDLE)

# =========================
# MAIN LOOP
# =========================
func _physics_process(delta):
	# If player is missing, try to find him again
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		
		if player == null: return # If he's still not spawned, wait.
	
	match current_state:
		State.IDLE: handle_idle(delta)
		State.PATROL: handle_patrol(delta)
		State.CHASE: handle_chase(delta)
		State.ATTACK: handle_attack(delta)
		State.HURT: handle_hurt(delta)
		State.SKID: return # Do nothing! The Tween is moving the zombie.
		State.STUMBLED: handle_recovery(delta)
		State.WALL_SIT: handle_recovery(delta)
		State.DOWNED: return # Stops move_and_slide while on the ground
		State.DEAD: return # Stops move_and_slide while on the ground

	if voice_cooldown > 0:
		voice_cooldown -= delta
		
	if downed_cooldown > 0:
		downed_cooldown -= delta
		
	move_and_slide()
	
	# The "Bump" Mechanic
	# Only bother checking if the zombie is unaware (Idle or Patrol)
	if current_state == State.IDLE or current_state == State.PATROL:
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			# If the thing zombie bumped into is a player
			if collision.get_collider() == player:
				var dist = global_position.distance_to(player.global_position)
				# Instantly react based on distance
				if dist < 70:
					change_state(State.ATTACK)
				else:
					change_state(State.CHASE)
				
				# Break out of the loop since the zombie found the player
				break
	
	update_animation()

# =========================
# STATE CHANGES
# =========================
func change_state(new_state: State):
	if not global.game_started:
		return

	current_state = new_state

	match new_state:
		State.IDLE:
			sfx_shamble.stop() # <-- STOP SHAMBLING SOUND
			idle_timer = 0.0
			velocity = Vector2.ZERO
			if voice_cooldown <= 0:
				sfx_idle.play()
				voice_cooldown = 8.0 # Wait 8 seconds before making another sound

		State.PATROL:
			# Check if playing so it doesn't restart awkwardly if moving from Chase -> Patrol
			if not sfx_shamble.playing: 
				sfx_shamble.play() # <-- START SHAMBLING SOUND				
			set_new_patrol_target()
		
		State.CHASE:
			if not sfx_shamble.playing:
				sfx_shamble.play() # <-- START SHAMBLING SOUND		
			if voice_cooldown <= 0:
				sfx_chase.play()
				voice_cooldown = 8.0 # Wait 8 seconds before making another sound
			body_collision.set_deferred("disabled", false)

		State.ATTACK:
			sfx_shamble.stop() # <-- STOP SHAMBLING SOUND	
			velocity = Vector2.ZERO
			if voice_cooldown <= 0:
				sfx_attack.play()
				voice_cooldown = 8.0 # Wait 8 seconds before making another sound
			sprite.play("attack_" + get_dir_string())
			
		State.HURT:
			sfx_shamble.stop() # <-- STOP SHAMBLING SOUND
			hurt_timer = 5.0
			if voice_cooldown <= 0:
				sfx_hurt.play()
				voice_cooldown = 8.0 # Wait 8 seconds before making another sound
			sprite.play("hurt_" + get_dir_string()) # Custom helper for 4-dir hurt anims
			#sprite.play("hurt_down") # Custom helper for 4-dir hurt anims
		
		State.DOWNED:
			sfx_shamble.stop() # <-- STOP SHAMBLING SOUND
			velocity = Vector2.ZERO
			sprite.play("downed_" + get_dir_string()) # Same as dead, no blood
			#sprite.play("downed") # For downed animation
			
			# Turn off Layer 3 (Enemy) so a player can walk through
			body_collision.set_deferred("disabled", true)
			await get_tree().create_timer(10.0).timeout
			
			if current_state == State.DOWNED: 
				change_state(State.IDLE)
				# Turn Layer 3 back on when standing up naturally
				body_collision.set_deferred("disabled", false)
		
		State.DEAD:
			sfx_shamble.stop() # <-- STOP SHAMBLING SOUND
			sfx_idle.stop()
			velocity = Vector2.ZERO
			sprite.play("dead_" + get_dir_string())
			sfx_dead.play()
			body_collision.set_deferred("disabled", true)
			
		State.SKID:
			sfx_shamble.stop() # <-- STOP SHAMBLING SOUND
			velocity = Vector2.ZERO
			sprite.play("hurt_up") # Or whichever direction you want for sliding back
			
		State.STUMBLED:
			sfx_shamble.stop() # <-- STOP SHAMBLING SOUND
			velocity = Vector2.ZERO
			sprite.play("downed_" + get_dir_string())
			recovery_timer = 3.0 # Stand up in 3 seconds
			
		State.WALL_SIT:
			sfx_shamble.stop() # <-- STOP SHAMBLING SOUND
			velocity = Vector2.ZERO
			sprite.play("sit_against_wall_" + get_dir_string()) 
			recovery_timer = 4.0 # Takes a bit longer to stand up from a wall
		
func get_shoved(shove_dir: Vector2):
	
	## 1. Enter the SKID state immediately so the hurt animation plays
	change_state(State.SKID)

	var space_state = get_world_2d().direct_space_state
	var ideal_target = global_position + (shove_dir * 250.0) 
	var query = PhysicsRayQueryParameters2D.create(global_position, ideal_target)
	
	# Look for Walls (Layer 1) AND Enemies (Layer 3). 1 + 4 = 5.
	query.collision_mask = 5 
	# CRITICAL: Tell the RayCast to ignore THIS zombie, or it will just hit itself!
	query.exclude = [self] 
	
	var result = space_state.intersect_ray(query)
	var actual_target = ideal_target
	var hit_wall = false
	var hit_zombie: Node2D = null
	
	# Analyze the collision
	if result:
		actual_target = result.position - (shove_dir * 15.0) 
		
		# Did we hit a wall or a zombie?
		# We check if the thing we hit has the "get_shoved" method
		if result.collider.has_method("get_shoved"):
			hit_zombie = result.collider
		else:
			hit_wall = true

	# Perform the Tween slide
	var tween = create_tween()
	tween.tween_property(self, "global_position", actual_target, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	
	# 5. Decide the final fate
	if hit_wall:
		change_state(State.WALL_SIT)
	elif hit_zombie != null:
		# We hit a zombie! We stumble, and we pass the shove to them!
		change_state(State.STUMBLED)
		hit_zombie.get_shoved(shove_dir) # Chain reaction!
	elif randf() < 0.5:
		change_state(State.STUMBLED)
	else:
		change_state(State.CHASE)

# =========================
# VISION
# =========================
func can_see_player() -> bool:
	if player == null:
		debug_line.points = [] # Clear line if no player (debug vision line)
		return false

	var to_player = player.global_position - global_position
#
	if to_player.length() > vision_range:
		debug_line.points = []
		return false
#
	#var angle = rad_to_deg(last_direction.angle_to(to_player.normalized()))
	#return abs(angle) < vision_angle * 0.5
	
	# 2. Check Angle (Cone of Vision)
	var angle = rad_to_deg(last_direction.angle_to(to_player.normalized()))
	if abs(angle) > vision_angle * 0.5:
		debug_line.points = []
		return false

	# 3. Check Line of Sight (Walls/Tables)
	var space_state = get_world_2d().direct_space_state
	# Cast a ray from Zombie to a player, checking ONLY Layer 1 (Environment)
	var query = PhysicsRayQueryParameters2D.create(global_position, player.global_position, 1) 
	var result = space_state.intersect_ray(query)

	if result:
		# The ray hit a wall before it reached a player!
		debug_line.points = []
		return false 

	# If we pass all 3 checks, the zombie sees a player! OPTIONAL
	# Draw the debug line from the zombie (Vector2.ZERO) to a player's local position
	debug_line.points = [Vector2.ZERO, to_local(player.global_position)]
	debug_line.default_color = Color.BLUE
	
	return true

# =========================
# IDLE
# =========================
func handle_idle(delta):

	if can_see_player():
		change_state(State.CHASE)
		return

	idle_timer += delta

	if idle_timer > 30.0:
		change_state(State.PATROL)

# =========================
# PATROL
# =========================
func set_new_patrol_target():
	
	var random_offset = Vector2(
		randf_range(-patrol_radius, patrol_radius),
		randf_range(-patrol_radius, patrol_radius)
	)
	
	var desired_target = global_position + random_offset
	
	# Snap the random target to the nearest valid spot on the Navigation Mesh
	patrol_target = NavigationServer2D.map_get_closest_point(nav_agent.get_navigation_map(), desired_target)
	nav_agent.target_position = patrol_target
	
	# Give the zombie a maximum of 5 seconds to reach the spot before giving up
	patrol_timeout = 5.0

func handle_patrol(delta):

	#if can_see_player():
		#change_state(State.CHASE)
		#return
#
	#if nav_agent.is_navigation_finished():
		#change_state(State.IDLE)
		#return
#
	#var next_point = nav_agent.get_next_path_position()
	#var dir = global_position.direction_to(next_point)
#
	#if dir.length() > 0:
		#last_direction = dir
#
	#velocity = dir * speed
	
	if can_see_player():
		change_state(State.CHASE)
		return

	patrol_timeout -= delta
	
	# Stop patrolling if we reached the spot OR if we took too long (got stuck)
	if nav_agent.is_navigation_finished() or patrol_timeout <= 0:
		change_state(State.IDLE)
		return

	var next_point = nav_agent.get_next_path_position()
	var dir = global_position.direction_to(next_point)

	if dir.length() > 0:
		last_direction = dir

	velocity = dir * speed
	

# =========================
# CHASE
# =========================
func handle_chase(delta):

	if player == null:
		return
	
	var dist_to_player = global_position.distance_to(player.global_position)
	
	# Multiply vision range by 1.5 or 2.0 so the zombie doesn't instantly give up
	if dist_to_player > vision_range * 1.5: 
		change_state(State.IDLE)
		return
		
	repath_timer -= delta

	if repath_timer <= 0:
		nav_agent.target_position = player.global_position
		repath_timer = 0.2
		
	# If a player runs out of the vision range, the zombie loses track of him
	#var dist_to_player = global_position.distance_to(player.global_position)
	#if dist_to_player > vision_range:
		#change_state(State.IDLE)
		#return

	if not nav_agent.is_target_reachable():
		change_state(State.IDLE)
		return

	var next_point = nav_agent.get_next_path_position()
	var dir = global_position.direction_to(next_point)

	if dir.length() > 0:
		last_direction = dir

	# CHANGED: Don't set velocity directly! Feed it to the NavAgent.
	var intended_velocity = dir * speed
	nav_agent.set_velocity(intended_velocity)

	# Attack check 
	var dist = global_position.distance_to(player.global_position)
	if dist < 70: 
		change_state(State.ATTACK)
		
	

# =========================
# ATTACK
# =========================
func handle_attack(delta):
	velocity = Vector2.ZERO
	
	# 1. Tick down the timer FIRST
	if attack_timer > 0:
		attack_timer -= delta
		return # Wait here until the timer is finished

	# 2. Check distance
	var dist = global_position.distance_to(player.global_position)
	if dist > 70: 
		change_state(State.CHASE)
		return
		
	# 3. If still close and timer is 0, FORCE THE GRAB
	if player.has_method("get_grabbed") and not player.is_grabbed:
		player.get_grabbed(self)
		attack_timer = 10.0 # Reset cooldown so it doesn't spam every frame
		sfx_bite.play()
		
# =========================
# HURT
# =========================
func handle_hurt(delta):
	velocity = Vector2.ZERO
	hurt_timer -= delta
	if hurt_timer <= 0:
		change_state(State.CHASE)

# =========================
# DAMAGE
# =========================
func take_damage(is_crit: bool = false):
	if current_state == State.DEAD:
		return
		
	# Safety Check: Ensure we have a player reference before using it
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		
	# Remember if a zombie were on the ground when the bullet hit
	var was_downed = (current_state == State.DOWNED)

	# 1. Calculate Damage
	var damage_to_deal = global.pistol_stats["damage"]
	
	if is_crit:
		damage_to_deal *= global.pistol_stats["crit_multiplier"]
		change_state(State.HURT)
	
	health -= damage_to_deal
	
	# --- SPAWN THE BLOOD SPLAT ---
	if blood_splat_scene:
		var splat = blood_splat_scene.instantiate()
		get_parent().add_child(splat) # Add to the room, not the zombie!
		
		# Position it at the zombie's center, slightly offset upwards so it's not at his feet
		splat.global_position = global_position + Vector2(0, -20) 
	
	# 2. Immediate Alert (Even if out of vision cone. Wakes a zombie up if DOWNED, IDLE, or PATROL)
	if current_state != State.CHASE and current_state != State.ATTACK:
		if player != null: # Only face the player if we found him
			last_direction = global_position.direction_to(player.global_position)
		
		change_state(State.CHASE)

	# 3. Check for Death or Downed
	if health <= 0:
		die()
		return
	
	# If the zombie was just shot while faking death, force it to skip the 
	# stun/downed rolls below so it can stand up and attack!
	if was_downed:
		downed_cooldown = 20.0 # Give a 20 sec grace period before it can fake death again
		return
	
	# 4. 40% Chance to fake death (Only if HP is low AND cooldown is 0)
	if health <= max_health * 0.5 and downed_cooldown <= 0 and randf() < 0.4:
		change_state(State.DOWNED)
		downed_cooldown = 20.0 # Start the 20 sec cooldown
		return

	# 20% Chance to stun (if not already downed/dead)
	if randf() < 0.2:
		change_state(State.HURT)

func die():
	change_state(State.DEAD)
	WorldState.kill_enemy(WorldState.current_room_name, state_id)
	
	# --- SPAWN THE BLOOD POOL AFTER 3 SECONDS ---
	spawn_blood_pool()
	#queue_free()

func spawn_blood_pool():
	# Wait for 3 seconds before pooling
	await get_tree().create_timer(3.0).timeout
	
	# Double check the zombie wasn't magically deleted during those 3 seconds
	if not is_inside_tree(): 
		return 
		
	if blood_pool_scene:
		var pool = blood_pool_scene.instantiate()
		
		get_parent().add_child(pool)
		pool.global_position = global_position

# =========================
# ANIMATION
# =========================

#func update_animation(): #OLD
#
	#var dir = last_direction
#
	#var moving = velocity.length() > 5
#
	#if abs(dir.x) > abs(dir.y):
		#if dir.x > 0:
			#sprite.play("walk_right" if moving else "idle_right")
		#else:
			#sprite.play("walk_left" if moving else "idle_left")
	#else:
		#if dir.y > 0:
			#sprite.play("walk_down" if moving else "idle_down")
		#else:
			#sprite.play("walk_up" if moving else "idle_up")
			
func update_animation():
	# Do not overwrite the animation if we are in these specific states!
	if current_state in [State.HURT, State.DOWNED, State.DEAD, State.STUMBLED, State.WALL_SIT]:
		return
	
	var dir_str = get_dir_string()
	var moving = velocity.length() > 5
	var anim_prefix = "walk_" if moving else "idle_"

	sprite.play(anim_prefix + dir_str)

func get_dir_string() -> String:
	var dir = last_direction
	
	if abs(dir.x) > abs(dir.y):
		return "right" if dir.x > 0 else "left"
	else:
		return "down" if dir.y > 0 else "up"

func _on_grab_area_body_entered(body: Node2D) -> void:
	#if body.is_in_group("player") and current_state != State.DEAD:
		#if body.has_method("get_grabbed"):
			##velocity = Vector2.ZERO
			## Pass this zombie instance so the player knows who is biting them
			#body.get_grabbed(self)
	# Only grab if Zombie is in ATTACK or CHASE state
	if current_state == State.DEAD: 
		return
		
	if body.is_in_group("player") and (current_state == State.ATTACK or current_state == State.CHASE):
		if body.has_method("get_grabbed"):
			# ADDED CHECK: Is the timer at 0, and is the player free?
			if attack_timer <= 0 and not body.is_grabbed:
				## Pass this zombie instance so the player knows who is biting them
				body.get_grabbed(self)
				attack_timer = 10.0 # APPLY THE 10 SEC COOLDOWN HERE
				change_state(State.ATTACK) # Ensure zombie stops moving

func handle_recovery(delta):
	# Applies to both STUMBLED and WALL_SIT
	recovery_timer -= delta
	if recovery_timer <= 0:
		change_state(State.CHASE)

func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	# Only apply this safe movement if we are actually chasing
	if current_state == State.CHASE:
		#velocity = safe_velocity
		# Use lerp to smooth the transition to the safe velocity
		# 0.1 makes it feel heavy/lumbering; 0.3 feels more responsive
		velocity = velocity.lerp(safe_velocity, 0.2)
		
# This is ONLY used when the player re-enters a room with a previously dead zombie
func set_as_already_dead():
	sfx_idle.stop()
	current_state = State.DEAD
	
	# 1. Turn off collisions silently
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
		
	# 2. Set the sprite to the final frame of the death animation silently!
	var anim_name = "dead_" + get_dir_string()
	sprite.animation = anim_name
	# Jump immediately to the last frame of the death animation
	sprite.frame = sprite.sprite_frames.get_frame_count(anim_name) - 1 
	
	# 3. Spawn the blood pool INSTANTLY (No 3-second wait)
	if blood_pool_scene:
		var pool = blood_pool_scene.instantiate()
		
		# We use call_deferred here because doing add_child while the room is 
		# still loading its _ready() function can sometimes crash Godot.
		get_parent().call_deferred("add_child", pool)
		
		pool.global_position = global_position
		
		
