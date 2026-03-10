extends Node2D

var fish_count: int = 0

func _ready() -> void:
	fish_count = get_tree().get_nodes_in_group("fish").size()
	_spawn_players()

func on_fish_died() -> void:
	fish_count -= 1
	if fish_count <= 1:
		await get_tree().create_timer(3.0).timeout
		get_tree().reload_current_scene()

func _spawn_players() -> void:
	for p in PlayerData.players:
		var slot: int = p["slot"]
		var device_id: int = p["device_id"]
		var color: Color = p["color"]
		var spawn: Marker2D = get_node("SpawnPoint%d" % slot)
		var fish: CharacterBody2D = load("res://scenes/characters/fish.tscn").instantiate()
		fish.global_position = spawn.global_position
		fish.set("joypad_id", device_id)
		for child in fish.get_children():
			if child is Polygon2D:
				child.color = color
		add_child(fish)
		fish_count += 1
