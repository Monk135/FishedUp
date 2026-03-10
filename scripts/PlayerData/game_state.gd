extends Node

const WINNING_SCORE: int = 10
const COMBATS_PER_SEQUENCE: int = 3

var scores: Dictionary = {}       # device_id : kill_count
var combat_count: int = 0
var perk_selection_order: Array = []  # device_ids in pick order for perk screen

func initialize_players(devices: Array) -> void:
	for device_id in devices:
		if not scores.has(device_id):
			scores[device_id] = 0

func reset_game() -> void:
	scores.clear()
	combat_count = 0

func add_kill(killer_device_id: int) -> void:
	if not scores.has(killer_device_id):
		scores[killer_device_id] = 0
	scores[killer_device_id] += 1

func has_winner() -> bool:
	for device_id in scores:
		if scores[device_id] >= WINNING_SCORE:
			return true
	return false

func get_sorted_scores() -> Array:
	var sorted := scores.keys()
	sorted.sort_custom(func(a, b): return scores[a] > scores[b])
	return sorted
