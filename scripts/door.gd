extends Area2D

@export_file("*.tscn") var target_room_path: String
@export var target_door_id: String = "" # e.g., "dining_north", "mainhall_south"
@export var is_door_locked: bool = false # Check if door is open or not

#func _ready():
	#body_entered.connect(_on_body_entered)

#func _on_body_entered(body):
	#if body.is_in_group("player"):
		#TransitionManager.fade_to_room(target_room_path, target_door_id)
	
	
# This is the function player will call
func interact():
	if is_door_locked:
		# Check if the player has a key in WorldState or Inventory
		# if WorldState.has_item("OldKey"): ...
		# TODO: Play a 'locked' sound effect here
		print("It's locked.")
		return

	# If not locked, proceed with transition
	if target_room_path != "":
		TransitionManager.fade_to_room(target_room_path, target_door_id)
	else:
		print("Warning: Door has no target room path set!")
		
