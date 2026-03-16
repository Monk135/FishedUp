extends Node2D

var fish_count: int = 0

func _ready() -> void:
	fish_count = get_tree().get_nodes_in_group("fish").size()
	_spawn_players()

func on_fish_died() -> void:
	fish_count -= 1
	if fish_count <= 1:
		await get_tree().create_timer(2.0).timeout
		_end_combat()

func _end_combat() -> void:
	GameState.combat_count += 1
	
	if GameState.has_winner():
		# game over screen later
		return
	
	if GameState.combat_count >= GameState.COMBATS_PER_SEQUENCE:
		GameState.combat_count = 0
		get_tree().change_scene_to_file("res://scenes/Menus_&_UI/PerkSelection.tscn")
	else:
		get_tree().reload_current_scene()

func _spawn_players() -> void:
	var devices: Array = []
	for p in PlayerData.players:
		devices.append(p["device_id"])
		var slot: int = p["slot"]
		var device_id: int = p["device_id"]
		print("spawning fish for device: ", device_id)
		if PlayerData.pending_perks.has(device_id):
			print("applying perk: ", PlayerData.pending_perks[device_id])
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
		
		if PlayerData.pending_perks.has(device_id):
			var perk_path: String = PlayerData.pending_perks[device_id]
			print("applying perk from path: ", perk_path)
			var perk_scene: PackedScene = load(perk_path)
			var perk: Node = perk_scene.instantiate()
			perk.apply(fish)
			perk.queue_free()
			
		print("pending perks: ", PlayerData.pending_perks)
		
		
		GameState.initialize_players(devices)
