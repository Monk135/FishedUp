extends Node2D

var fish_count: int = 0

func _ready() -> void:
	fish_count = get_tree().get_nodes_in_group("fish").size()
	_create_walls()
	_spawn_players()

func on_fish_died() -> void:
	fish_count -= 1
	if fish_count <= 1:
		await get_tree().create_timer(3.0).timeout
		get_tree().reload_current_scene()

func _create_walls() -> void:
	var size := get_viewport_rect().size
	var thickness := 50.0
	_add_wall(Vector2(size.x / 2, -thickness / 2), size.x, thickness)
	_add_wall(Vector2(size.x / 2, size.y + thickness / 2), size.x, thickness)
	_add_wall(Vector2(-thickness / 2, size.y / 2), thickness, size.y)
	_add_wall(Vector2(size.x + thickness / 2, size.y / 2), thickness, size.y)
	
	# Draw the inner border as a single Line2D
	var line := Line2D.new()
	line.default_color = Color.WHITE
	line.width = 3.0
	line.points = PackedVector2Array([
		Vector2(0, 0),
		Vector2(size.x, 0),
		Vector2(size.x, size.y),
		Vector2(0, size.y),
		Vector2(0, 0)
	])
	add_child(line)

func _add_wall(pos: Vector2, width: float, height: float) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 0
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, height)
	col.shape = shape
	body.add_child(col)
	add_child(body)
	
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
