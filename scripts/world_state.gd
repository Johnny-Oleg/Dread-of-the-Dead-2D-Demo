extends Node
# WorldState.gd (Autoload)


# A dictionary to track everything
# Format: "RoomName": {"ItemName": is_picked_up}

# =========================
# ROOM DATABASE
# =========================

var rooms = {

	"MainHall": {
		"items": {
			"PistolAmmo_01": {
				"type": "ammo",
				"picked": false
			},
		},
		"enemies": {
			"Zombie_01": {
				"type": "zombie",
				"alive": true
			}
		}
	},

	"DiningRoom": {
		"items": {
			"PistolAmmo_01": {
				"type": "ammo",
				"picked": false
			},
			#"GreenMedicine_01": {
				#"type": "healing",
				#"picked": false
			#}
		},
		"enemies": {
			"Zombie_01": {
				"type": "zombie",
				"alive": true
			},
			"Zombie_02": {
				"type": "zombie",
				"alive": true
			}
		}
	},

	"Library": {
		"items": {
			"GreenMedicine_01": {
				"type": "healing",
				"picked": false
			},
			"PistolAmmo_01": {
				"type": "ammo",
				"picked": false
			}
		},
		"enemies": {
			"Zombie_01": {
				"type": "zombie",
				"alive": true
			},
			"Zombie_02": {
				"type": "zombie",
				"alive": true
			},
			"Zombie_03": {
				"type": "zombie",
				"alive": true
			}
		}
	},

	"SaveRoom": {
		"items": {
			"GreenMedicine_01": {
				"type": "healing",
				"picked": false
			},
			"PistolAmmo_01": {
				"type": "ammo",
				"picked": false
			},
		},
		"enemies": {
			# Save rooms usually empty
		}
	},

	"Corridor": {
		"items": {
			"PistolAmmo_01": {
				"type": "ammo",
				"picked": false
			}
		},
		"enemies": {
			"Zombie_01": {
				"type": "zombie",
				"alive": true
			},
			"Zombie_02": {
				"type": "zombie",
				"alive": true
			}
		}
	}
}

var current_room_name: String = ""

# =========================
# HELPERS
# =========================

func is_enemy_alive(room_name: String, enemy_id: String) -> bool:
	return rooms[room_name]["enemies"][enemy_id]["alive"]

func kill_enemy(room_name: String, enemy_id: String):
	rooms[room_name]["enemies"][enemy_id]["alive"] = false

func is_item_picked(room_name: String, item_id: String) -> bool:
	# Safely check if the keys exist before trying to read them
	if rooms.has(room_name) and rooms[room_name]["items"].has(item_id):
		return rooms[room_name]["items"][item_id]["picked"]
	else:
		push_error("WorldState Error: Missing item " + item_id + " in room " + room_name)
		return false # Default to not picked so the game doesn't crash

func pick_item(room_name: String, item_id: String):
	if rooms.has(room_name) and rooms[room_name]["items"].has(item_id):
		rooms[room_name]["items"][item_id]["picked"] = true
	
func reset_state():
	rooms = {

		"MainHall": {
			"items": {
				"PistolAmmo_01": {
					"type": "ammo",
					"picked": false
				},
			},
			"enemies": {
				"Zombie_01": {
					"type": "zombie",
					"alive": true
				}
			}
		},

		"DiningRoom": {
			"items": {
				"PistolAmmo_01": {
					"type": "ammo",
					"picked": false
				},
				#"GreenMedicine_01": {
					#"type": "healing",
					#"picked": false
				#}
			},
			"enemies": {
				"Zombie_01": {
					"type": "zombie",
					"alive": true
				},
				"Zombie_02": {
					"type": "zombie",
					"alive": true
				}
			}
		},

		"Library": {
			"items": {
				"GreenMedicine_01": {
					"type": "healing",
					"picked": false
				},
				"PistolAmmo_01": {
					"type": "ammo",
					"picked": false
				}
			},
			"enemies": {
				"Zombie_01": {
					"type": "zombie",
					"alive": true
				},
				"Zombie_02": {
					"type": "zombie",
					"alive": true
				},
				"Zombie_03": {
					"type": "zombie",
					"alive": true
				}
			}
		},

		"SaveRoom": {
			"items": {
				"GreenMedicine_01": {
					"type": "healing",
					"picked": false
				},
				"PistolAmmo_01": {
					"type": "ammo",
					"picked": false
				},
			},
			"enemies": {
				# Save rooms usually empty
			}
		},

		"Corridor": {
			"items": {
				"PistolAmmo_01": {
					"type": "ammo",
					"picked": false
				}
			},
			"enemies": {
				"Zombie_01": {
					"type": "zombie",
					"alive": true
				},
				"Zombie_02": {
					"type": "zombie",
					"alive": true
				}
			}
		}
	}
	
	current_room_name = ""
