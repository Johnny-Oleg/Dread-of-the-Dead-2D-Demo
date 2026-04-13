extends Area2D

@export var item_data: Item
@onready var sprite = $Sprite2D
@export var state_id: String = "" # e.g., "PistolAmmo_01"

func _ready() -> void:
	# If we assigned a .tres file in the Inspector, apply its icon to the sprite!
	if item_data != null:
		sprite.texture = item_data.icon
	else:
		print("WARNING: No item data assigned to ", name)
		
func get_item_data():
	return item_data
