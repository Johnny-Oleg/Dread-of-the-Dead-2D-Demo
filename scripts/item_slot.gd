extends Control

@export var current_item: Item 

@onready var icon_rect = $Icon 
@onready var amount_label = $AmountLabel
@onready var highlight = $ActiveHighLight # The gray cursor frame!

func _ready():
	# Sever the memory link so starting items don't edit the master .tres file!
	if current_item != null:
		current_item = current_item.duplicate()
	
	# Hide cursor by default
	highlight.visible = false
	
	# Connect Godot's built-in focus/mouse signals
	mouse_entered.connect(_on_mouse_entered)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	
	update_slot()

# If the mouse touches this slot, force the WASD system to select it too
func _on_mouse_entered():
	grab_focus()

func _on_focus_entered():
	highlight.visible = true
	# We will create this group and function in Phase 4!
	get_tree().call_group("inventory_ui", "update_description", current_item)

func _on_focus_exited():
	highlight.visible = false

func update_slot():
	if current_item != null:
		icon_rect.texture = current_item.icon
		icon_rect.visible = true
		
		# WEAPON LOGIC
		if current_item.item_type == "weapon":
			amount_label.text = str(global.current_ammo)
			amount_label.visible = true
			
		# AMMO LOGIC
		elif current_item.is_stackable:
			amount_label.text = str(current_item.count)
			amount_label.visible = true
			
		else:
			amount_label.visible = false
	else:
		icon_rect.visible = false
		amount_label.visible = false
		
# This built-in function listens for inputs directly on this specific slot
func _gui_input(event):
	# This now perfectly handles clicks, keyboard, and gamepads!
	if event.is_action_pressed("inventory_use"):
		if current_item != null:
			get_tree().call_group("inventory_ui", "use_item", self)
