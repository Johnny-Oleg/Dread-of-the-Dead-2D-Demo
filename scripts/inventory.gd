extends CanvasLayer

@onready var item_grid = $InventoryLayer/MainLayout/ItemGrid
@onready var item_name_label = $InventoryLayer/MainLayout/ProfileSection/EquippedWeapon/ItemName
@onready var weapon_mag_label = $InventoryLayer/MainLayout/ProfileSection/EquippedWeapon/WeaponMag
@onready var health_percent = global.player_health / global.player_max_health
@onready var bar = $InventoryLayer/MainLayout/ProfileSection/PlayerSection/ConditionSection/HealthBar
@onready var label = $InventoryLayer/MainLayout/ProfileSection/PlayerSection/ConditionSection/StatusLabel
	
func _ready():
	# Add this script to a group so slots can easily talk to it
	add_to_group("inventory_ui")	
	
# Called from Main.gd when you press Tab
func on_open():
	update_condition()
	scan_ammo_reserves() # Count ammo every time we open
	
	# Snap the cursor to Slot 1 (the first child in the grid)
	if item_grid.get_child_count() > 0:
		item_grid.get_child(0).grab_focus()
		
# Called by the slots when the cursor moves over them
func update_description(item: Item):
	if item != null:
		item_name_label.text = item.name
	else:
		item_name_label.text = "Empty"
		
# --- AMMO CALCULATION ---
func scan_ammo_reserves():
	var total_ammo = 0
	
	# Look through every slot in the grid
	for slot in item_grid.get_children():
		if slot.current_item != null and slot.current_item.item_type == "ammo":
			total_ammo += slot.current_item.count
			
	# Update global reserve
	global.reserve_ammo = total_ammo
	
	# Update the equipped weapon mag label
	weapon_mag_label.text = str(global.current_ammo) + " / " + str(global.reserve_ammo)
	
func update_condition():
	
	bar.value = health_percent * 100
	
	if health_percent > 0.6:
		label.text = "FINE"
		label.modulate = Color.GREEN
		# Set bar color to green via StyleBox
	elif health_percent > 0.3:
		label.text = "CAUTION"
		label.modulate = Color.YELLOW
	else:
		label.text = "DANGER"
		label.modulate = Color.RED
		
		
		
