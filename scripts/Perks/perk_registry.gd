extends Node

const AVAILABLE_PERKS: Array = [
	"res://scenes/Menus_&_UI/perk_speed_increase.tscn",
	"res://scenes/Menus_&_UI/perk_damage_increase.tscn",
	"res://scenes/Menus_&_UI/perk_health_increase.tscn",
	# add more perk scenes here as you make them
]

func get_random_perks(count: int) -> Array:
	var pool := AVAILABLE_PERKS.duplicate()
	# If not enough perks, fill with duplicates
	while pool.size() < count:
		pool.append_array(AVAILABLE_PERKS)
	pool.shuffle()
	return pool.slice(0, count)
