extends Node

@onready var creepy_player = AudioStreamPlayer.new()
@onready var safe_player = AudioStreamPlayer.new()
@onready var haunted_player = AudioStreamPlayer.new()
@onready var ambient_player = AudioStreamPlayer.new() # For the dog!
@onready var ambient_timer = Timer.new()

func _ready():
	add_child(creepy_player)
	add_child(safe_player)
	add_child(ambient_player)
	add_child(ambient_timer)
	
	# Load streams
	creepy_player.stream = load("res://assets/audio/bgm/castle_bgm_2.mp3")
	haunted_player.stream = load("res://assets/audio/bgm/castle_bgm_3.mp3")
	safe_player.stream = load("res://assets/audio/bgm/save_room_bgm.mp3")
	ambient_player.stream = load("res://assets/audio/bgm/dog_howling.wav")

	# Connect the timer
	ambient_timer.timeout.connect(_on_ambient_timeout)

func play_creepy():
	if creepy_player.playing: return
	fade_out(safe_player)
	fade_in(creepy_player)
	
#func play_haunted():
	#if haunted_player.playing: return
	#fade_out(safe_player)
	#fade_out(haunted_player)
	#fade_in(haunted_player)

func play_safe():
	if safe_player.playing: return
	fade_out(creepy_player)
	fade_in(safe_player)
	
# --- AMBIENT HOWL LOGIC ---
func start_dining_ambience():
	if ambient_timer.is_stopped():
		print("Starting dog howling loop...")
		_on_ambient_timeout() # Trigger first one immediately

func stop_dining_ambience():
	ambient_timer.stop()
	print("Leaving Dining Room, howling stopped.")

func _on_ambient_timeout():
	ambient_player.play()
	# Randomize next howl between 30 and 45 seconds
	ambient_timer.wait_time = randf_range(30.0, 45.0)
	ambient_timer.start()

# --- FADE LOGIC ---
func fade_in(player):
	player.volume_db = -40
	player.play()
	create_tween().tween_property(player, "volume_db", 0, 2.0)

func fade_out(player):
	var tween = create_tween()
	tween.tween_property(player, "volume_db", -40, 2.0)
	tween.finished.connect(player.stop)
	
	
	
