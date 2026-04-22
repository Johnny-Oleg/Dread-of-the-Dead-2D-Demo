extends PointLight2D

@export var min_energy: float = 0.8
@export var max_energy: float = 1.2
@export var flicker_speed: float = 0.05

func _ready():
	flicker()

func flicker():
	var tween = create_tween()
	# Randomly pick a new brightness
	var target_energy = randf_range(min_energy, max_energy)
	
	# Smoothly transition to it
	tween.tween_property(self, "energy", target_energy, flicker_speed)
	
	# Do it again when finished
	tween.finished.connect(flicker)
	
	
