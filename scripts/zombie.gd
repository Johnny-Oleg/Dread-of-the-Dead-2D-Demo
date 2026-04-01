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
	DEAD
}

const STATE_NAMES = {
	State.IDLE: "IDLE",
	State.PATROL: "PATROL",
	State.CHASE: "CHASE",
	State.ATTACK: "ATTACK",
	State.HURT: "HURT",
	State.DOWNED: "DOWNED",
	State.DEAD: "DEAD"
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

var vision_range := 250.0
var vision_angle := 90.0

var last_direction: Vector2 = Vector2.DOWN

# =========================
# REFERENCES
# =========================
@onready var player: CharacterBody2D = get_tree().get_first_node_in_group("player")
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var sprite: AnimatedSprite2D = $Body/AnimatedSprite2D
@onready var sfx_idle = $SoundEffects/ZombieIdle
@onready var sfx_chase = $SoundEffects/ZombieChase
@onready var sfx_hurt = $SoundEffects/ZombieHurt
@onready var sfx_attack = $SoundEffects/ZombieAttack

# =========================
# READY
# =========================
func _ready():
	randomize()

	health = [1000,1500,2000,2500].pick_random()
	max_health = health

	#motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	#if not player.is_empty(): 
		#player = player[0]
		#nav_agent.target_position = player.global_position
	nav_agent.path_desired_distance = 4.0
	nav_agent.target_desired_distance = 8.0

	change_state(State.IDLE)

# =========================
# MAIN LOOP
# =========================
func _physics_process(delta):

	match current_state:
		State.IDLE: handle_idle(delta)
		State.PATROL: handle_patrol(delta)
		State.CHASE: handle_chase(delta)
		State.ATTACK: handle_attack(delta)
		State.HURT: handle_hurt(delta)
		State.DEAD: return

	move_and_slide()
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
			idle_timer = 0.0
			velocity = Vector2.ZERO
			sfx_idle.play()

		State.PATROL:
			set_new_patrol_target()
		
		State.CHASE:
			sfx_chase.play()
		
		State.ATTACK:
			attack_timer = 1.0
			velocity = Vector2.ZERO
			sfx_attack.play()

		State.HURT:
			hurt_timer = 2.0
			sfx_hurt.play()

		State.DEAD:
			velocity = Vector2.ZERO
			#set_physics_process(false) need this?

# =========================
# VISION
# =========================
func can_see_player() -> bool:
	if player == null:
		return false

	var to_player = player.global_position - global_position

	if to_player.length() > vision_range:
		return false

	var angle = rad_to_deg(last_direction.angle_to(to_player.normalized()))
	
	return abs(angle) < vision_angle * 0.5

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

	patrol_target = global_position + random_offset
	nav_agent.target_position = patrol_target

func handle_patrol(delta):

	if can_see_player():
		change_state(State.CHASE)
		return

	if nav_agent.is_navigation_finished():
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

	repath_timer -= delta

	if repath_timer <= 0:
		nav_agent.target_position = player.global_position
		repath_timer = 0.2

	if not nav_agent.is_target_reachable():
		change_state(State.IDLE)
		return

	var next_point = nav_agent.get_next_path_position()
	var dir = global_position.direction_to(next_point)

	if dir.length() > 0:
		last_direction = dir

	velocity = dir * speed

	# Attack check 
	var dist = global_position.distance_to(player.global_position)
	if dist < 70: 
		change_state(State.ATTACK)

# =========================
# ATTACK
# =========================
func handle_attack(delta):
	velocity = Vector2.ZERO
	attack_timer -= delta

	if attack_timer <= 0:
		attack_timer = 1.0
		#change_state(State.CHASE) # every second changes to chase state. why?
		
	# Attack check (chase only if the player is escaping)
	var dist = global_position.distance_to(player.global_position)
	if dist > 70: 
		change_state(State.CHASE)

# =========================
# HURT TODO
# =========================
func handle_hurt(delta):

	hurt_timer -= delta

	if hurt_timer <= 0:
		change_state(State.CHASE)

# =========================
# DAMAGE TODO
# =========================
func take_damage(amount: int):

	if current_state == State.DEAD:
		return

	health -= amount

	if health <= 0:
		change_state(State.DEAD)
	else:
		if randf() < 0.3:
			change_state(State.HURT)

# =========================
# ANIMATION
# =========================
func update_animation():

	var dir = last_direction

	var moving = velocity.length() > 5

	if abs(dir.x) > abs(dir.y):
		if dir.x > 0:
			sprite.play("walk_right" if moving else "idle_right")
		else:
			sprite.play("walk_left" if moving else "idle_left")
	else:
		if dir.y > 0:
			sprite.play("walk_down" if moving else "idle_down")
		else:
			sprite.play("walk_up" if moving else "idle_up")
			
			
