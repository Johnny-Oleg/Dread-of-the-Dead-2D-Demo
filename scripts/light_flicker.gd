extends PointLight2D

@export var min_energy: float = 0.8
@export var max_energy: float = 1.2
@export var flicker_speed: float = 0.1 # Slowed down slightly for stability

var target_energy: float = 1.0
var time_passed: float = 0.0

func _process(delta):
	time_passed += delta
	if time_passed >= flicker_speed:
		target_energy = randf_range(min_energy, max_energy)
		time_passed = 0.0
	
	# Smoothly move to the target without creating new objects
	energy = lerp(energy, target_energy, delta * 10.0)
	
	
