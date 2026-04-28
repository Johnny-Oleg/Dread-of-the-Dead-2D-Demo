extends CanvasLayer

@onready var item_grid = $InventoryLayer/MainLayout/MarginContainer/ItemGrid
@onready var item_name_label = $InventoryLayer/MainLayout/ProfileSection/EquippedWeapon/ItemName
@onready var weapon_mag_label = $InventoryLayer/MainLayout/ProfileSection/EquippedWeapon/WeaponMag
@onready var health_percent = global.player_health / global.player_max_health
@onready var bar = $InventoryLayer/MainLayout/ProfileSection/PlayerSection/ConditionSection/HealthBar
@onready var label = $InventoryLayer/MainLayout/ProfileSection/PlayerSection/ConditionSection/StatusLabel
@onready var item_use_sfx = $InventoryLayer/UseItem
	
func _ready():
	# Add this script to a group so slots can easily talk to it
	add_to_group("inventory_ui")	
	
# Called from Main.gd when you press Tab
func on_open():

	consolidate_inventory() # Sort everything silently
	update_condition()
	scan_ammo_reserves() # Count ammo every time we open
	
	# FORCE all slots to update their visuals so the pistol mag size refreshes!
	for slot in item_grid.get_children():
		slot.update_slot()
			
	# Snap the cursor to Slot 1 (the first child in the grid)
	if item_grid.get_child_count() > 0:
		item_grid.get_child(0).grab_focus()
		
# Called by the slots when the cursor moves over them
func update_description(item: Item):
	if item != null:
		item_name_label.text = item.name
	else:
		item_name_label.text = ""
		
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
	
	# FOOLPROOF FIX: Force the bar to match global max health
	bar.max_value = global.player_max_health
	bar.value = global.player_health 
	
	# We still need the percentage just for the colors
	var health_percent = global.player_health / global.player_max_health
	var style = StyleBoxFlat.new()
	
	if health_percent > 0.6:
		label.text = "FINE"
		label.modulate = Color.GREEN
		style.bg_color = Color.GREEN
	elif health_percent > 0.3:
		label.text = "CAUTION"
		label.modulate = Color.YELLOW
		style.bg_color = Color.YELLOW
	else:
		label.text = "DANGER"
		label.modulate = Color.RED
		style.bg_color = Color.RED
	
	# Apply the specific style to just the "fill" portion of the bar
	bar.add_theme_stylebox_override("fill", style)
	#consolidate_inventory() # Sort everything silently
		
# --- AMMO CONSUMPTION ---
# The player asks for a certain amount of bullets, and the inventory returns what it can find.
func consume_ammo(amount_needed: int) -> int:
	var amount_taken = 0
	
	# Go through every slot in the grid
	for slot in item_grid.get_children():
		if amount_taken >= amount_needed:
			break # We have enough bullets, stop searching!
			
		if slot.current_item != null and slot.current_item.item_type == "ammo":
			var available = slot.current_item.count
			var take = min(available, amount_needed - amount_taken)
			
			# Physically remove the bullets from the .tres item
			slot.current_item.count -= take
			amount_taken += take
			
			# If the ammo box is empty, delete it from the slot!
			if slot.current_item.count <= 0:
				slot.current_item = null
				
			slot.update_slot() # Update the slot's visuals
			
	scan_ammo_reserves() # Recalculate global.reserve_ammo with the new numbers
	return amount_taken
	
# --- ITEM USAGE ---
func use_item(slot):
	var item = slot.current_item

	# 1. HEALING LOGIC
	if item.item_type == "healing":
		# Only heal if Arthur is actually hurt
		if global.player_health < global.player_max_health:
			global.player_health += item.healing_amount
			item_use_sfx.play()
			
			# Clamp the health so it doesn't go over 1200
			if global.player_health > global.player_max_health:
				global.player_health = global.player_max_health
			
			print("Used ", item.name, "! Healed for ", item.healing_amount)
			
			# Delete the item and refresh UI
			slot.current_item = null
			slot.update_slot()
			update_condition() # Watch the bar turn green instantly!
		else:
			print("Health is already full.")

	# 2. AMMO LOGIC (Manual Reload from Inventory)
	elif item.item_type == "ammo":
		# Right now, we know Arthur is holding the m1911, so we check for pistol ammo.
		if item.ammo_type == "pistol":
			var max_mag = global.pistol_stats.mag_size
			var missing_ammo = max_mag - global.current_ammo
			
			if missing_ammo > 0:
				# Take only what we need, or whatever is left in the box
				var take = min(item.count, missing_ammo)
				
				item.count -= take
				global.current_ammo += take
				item_use_sfx.play()

				print("Manually reloaded ", take, " bullets.")
				
				# If the ammo box is empty, throw it away
				if item.count <= 0:
					slot.current_item = null
					
				# Refresh the visuals
				slot.update_slot()
				scan_ammo_reserves() # Updates the 10/5 label
				
				# Update the equipped weapon slot to show the new current ammo
				# (Assuming the pistol is in slot 0)
				if item_grid.get_child(0).current_item != null:
					item_grid.get_child(0).update_slot()
			else:
				print("Gun is already fully loaded.")
		else:
			print("This ammo doesn't fit the equipped weapon.")

	consolidate_inventory()
	
func consolidate_inventory():
	var active_items = []
	
	# 1. Scoop up all existing items
	for slot in item_grid.get_children():
		if slot.current_item != null:
			active_items.append(slot.current_item)
			
	# 2. Wipe the grid entirely
	for slot in item_grid.get_children():
		slot.current_item = null
		
	# 3. Put the items back in order
	for i in range(active_items.size()):
		item_grid.get_child(i).current_item = active_items[i]
		
	# 4. Force all slots to update their visuals
	for slot in item_grid.get_children():
		slot.update_slot()

# --- PICKUP LOGIC ---
# Returns true if the item was successfully added, false if inventory is full
func add_item(new_item: Item) -> bool:
	# 1. Check if we can stack it with an existing item
	if new_item.is_stackable:
		for slot in item_grid.get_children():
			if slot.current_item != null and slot.current_item.name == new_item.name:
				slot.current_item.count += new_item.count
				slot.update_slot()
				scan_ammo_reserves()
				return true # Successfully stacked!
				
	# 2. If not stackable (or no existing stack found), find the first empty slot
	for slot in item_grid.get_children():
		if slot.current_item == null:
			# CRITICAL: We must duplicate() the item. 
			# Otherwise, picking up two ammo boxes links them in memory!
			slot.current_item = new_item.duplicate()
			slot.update_slot()
			scan_ammo_reserves()
			return true # Successfully placed in a new slot!
			
	# 3. If we get here, the grid is full
	print("Inventory is full!")
	return false
	
	
