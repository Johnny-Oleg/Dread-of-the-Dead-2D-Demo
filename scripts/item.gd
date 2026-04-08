extends Resource
class_name Item

@export var name: String = ""
@export var description: String = ""
@export var icon: Texture
# Using export_enum gives a nice dropdown menu in the Inspector!
@export var is_stackable: bool = false
@export var max_stack: int = 255 # Only matters if stackable is true
@export var count: int = 1
@export var healing_amount: int = 0
@export var is_equipped: bool

@export_enum("weapon", "ammo", "healing", "key_item") var item_type: String = ""
@export_enum("pistol", "shotgun", "magnum", "rifle", "smg", "knife") var weapon_type: String = ""
@export_enum("pistol", "shotgun", "magnum", "rifle", "smg") var ammo_type: String = ""
