extends Node

# =========================
# GAME STATE
# =========================
var game_started: bool = false
var game_over: bool = false

# =========================
# PLAYER CORE STATS
# =========================
signal player_died
var player_health: float = 1200.0
var player_max_health: float = 1200.0

# Danger threshold (30%)
const DANGER_THRESHOLD: float = 0.3

# =========================
# WEAPON DATA (START SIMPLE)
# =========================
var weapon_equipped: String = "m1911"

var pistol_stats = {
	"damage": 400,
	"crit_chance": 0.1, # 10%
	"crit_multiplier": 2.0,
	"mag_size": 10,
	"fire_rate": 2.0, # shots per second
	"reload_time": 1.4
}

# =========================
# AMMO
# =========================
var current_ammo: int = 10
var reserve_ammo: int = 5

# =========================
# ZOMBIE BASE SETTINGS
# =========================
var zombie_health_min: float = 1000.0
var zombie_health_max: float = 2500.0

# =========================
# FUNCTIONS
# =========================

func reset_game():
	game_started = false
	game_over = false
	
	player_health = player_max_health
	
	current_ammo = 10
	reserve_ammo = 5

func is_player_in_danger() -> bool:
	return player_health <= player_max_health * DANGER_THRESHOLD
	
	
