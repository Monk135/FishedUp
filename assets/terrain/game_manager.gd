extends Node2D
## Main arena scene. Add this as your root scene.
## Spawns fish for each connected controller + keyboard player 1.

const PLAYER_COLORS := [
	Color(0.2, 0.6, 1.0),    # blue
	Color(1.0, 0.3, 0.3),    # red
	Color(0.3, 1.0, 0.4),    # green
	Color(1.0, 0.85, 0.1),   # yellow
]

const SPAWN_POINTS := [
	Vector2(200, 200),
	Vector2(600, 200),
	Vector2(200, 500),
	Vector2(600, 500),
]

var fish_players: Array = []

func _ready() -> void:
	_spawn_players()

func _spawn_players() -> void:
	# Always spawn keyboard player
	_spawn_fish(0, -1)   # device_id -1 = keyboard

	# Spawn one fish per connected joypad
	var joypads := Input.get_connected_joypads()
	for i in min(joypads.size(), 3):   # max 4 total
		_spawn_fish(i + 1, joypads[i])

func _spawn_fish(index: int, device_id: int) -> void:
	var fish: Node2D = _build_fish_node()
	fish.global_position = SPAWN_POINTS[index % SPAWN_POINTS.size()]

	# Set color and device via script properties
	fish.set("device_id", device_id)
	fish.set("player_color", PLAYER_COLORS[index % PLAYER_COLORS.size()])

	# Tint all Polygon2D children
	for child in fish.get_children():
		if child is Polygon2D:
			child.color = PLAYER_COLORS[index % PLAYER_COLORS.size()]

	add_child(fish)
	fish_players.append(fish)
	print("Spawned player %d (device %d)" % [index, device_id])

func _build_fish_node() -> Node2D:
	# Build the fish programmatically
	var root := Node2D.new()
	root.set_script(load("res://fish_player.gd"))
	root.name = "Fish"
	root.add_to_group("fish")

	# Bill visual
	var bill := Polygon2D.new()
	bill.name = "BillVisual"
	bill.polygon = PackedVector2Array([Vector2(28,0), Vector2(-2,4), Vector2(-2,-4)])
	root.add_child(bill)

	# Head visual
	var head := Polygon2D.new()
	head.name = "HeadVisual"
	head.polygon = PackedVector2Array([
		Vector2(14,0), Vector2(10,8), Vector2(0,12), Vector2(-10,8),
		Vector2(-14,0), Vector2(-10,-8), Vector2(0,-12), Vector2(10,-8)
	])
	root.add_child(head)

	# Body visual
	var body := Polygon2D.new()
	body.name = "BodyVisual"
	body.polygon = PackedVector2Array([
		Vector2(12,0), Vector2(8,14), Vector2(-8,14),
		Vector2(-12,0), Vector2(-8,-14), Vector2(8,-14)
	])
	root.add_child(body)

	# Tail visual
	var tail := Polygon2D.new()
	tail.name = "TailVisual"
	tail.polygon = PackedVector2Array([
		Vector2(6,0), Vector2(-6,12), Vector2(-18,8),
		Vector2(-10,0), Vector2(-18,-8), Vector2(-6,-12)
	])
	root.add_child(tail)

	# Bill Area2D (what stabs)
	var bill_area := Area2D.new()
	bill_area.name = "BillArea"
	var bill_col := CollisionShape2D.new()
	var bill_shape := CapsuleShape2D.new()
	bill_shape.radius = 5.0
	bill_shape.height = 18.0
	bill_col.shape = bill_shape
	bill_area.add_child(bill_col)
	root.add_child(bill_area)

	# Body Area2D (what gets stabbed)
	var body_area := Area2D.new()
	body_area.name = "BodyArea"
	body_area.add_to_group("fish_body_area")
	var body_col := CollisionShape2D.new()
	var body_shape := CapsuleShape2D.new()
	body_shape.radius = 14.0
	body_shape.height = 36.0
	body_col.shape = body_shape
	body_area.add_child(body_col)
	root.add_child(body_area)

	return root

func _input(event: InputEvent) -> void:
	# Press R to respawn all (debug)
	if event.is_action_pressed("ui_accept"):
		for fish in fish_players:
			fish.queue_free()
		fish_players.clear()
		_spawn_players()
