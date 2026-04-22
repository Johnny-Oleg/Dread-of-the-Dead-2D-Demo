extends Sprite2D

func _ready():
	# Randomize rotation so it doesn't look identical every time!
	rotation = randf_range(0, TAU) 
	
	# Fade out and delete automatically
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5).set_delay(0.2)
	tween.tween_callback(queue_free)
	
	
	
