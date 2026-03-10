extends Node2D

var joined_devices: Array = []
var ready_devices: Array = []

const COLORS := [
	Color(0.2, 0.6, 1.0),
	Color(0.3, 1.0, 0.4),
	Color(1.0, 0.85, 0.1),
	Color(0.8, 0.3, 1.0),
	Color(1.0, 0.6, 0.2),
]

@onready var join_label: Label = $JoinLabel

var device_color_index: Dictionary = {}

var ready_indicators: Dictionary = {}



func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			if joined_devices.has(-1):
				_try_ready(-1)
			else:
				_try_join(-1)
		if event.keycode == KEY_ESCAPE:
			_try_leave(-1)
		if event.keycode == KEY_A and joined_devices.has(-1):
			_cycle_color(-1, -1)
		if event.keycode == KEY_D and joined_devices.has(-1):
			_cycle_color(-1, 1)
	
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_A:
			if joined_devices.has(event.device):
				_try_ready(event.device)
			else:
				_try_join(event.device)
		if event.button_index == JOY_BUTTON_B:
			_try_leave(event.device)
		if event.button_index == JOY_BUTTON_DPAD_LEFT and joined_devices.has(event.device):
			_cycle_color(event.device, -1)
		if event.button_index == JOY_BUTTON_DPAD_RIGHT and joined_devices.has(event.device):
			_cycle_color(event.device, 1)


func _cycle_color(device_id: int, direction: int) -> void:
	var idx: int = device_color_index[device_id]
	idx = (idx + direction) % COLORS.size()
	if idx < 0:
		idx = COLORS.size() - 1
	device_color_index[device_id] = idx
	var fish: CharacterBody2D = fish_previews[device_id]
	for child in fish.get_children():
		if child is Polygon2D:
			child.color = COLORS[idx]
	print("device ", device_id, " color: ", idx)


var fish_previews: Dictionary = {}

func _try_join(device_id: int) -> void:
	if joined_devices.has(device_id):
		return
	joined_devices.append(device_id)
	
	var slot := joined_devices.size() - 1
	var spawn: Marker2D = get_node("PreviewPoint%d" % slot)
	
	var fish: CharacterBody2D = load("res://scenes/characters/fish.tscn").instantiate()
	fish.set("joypad_id", -99)
	fish.set("is_preview", true)
	fish.global_position = spawn.global_position
	fish.global_rotation_degrees += -90
	add_child(fish)
	fish_previews[device_id] = fish
	device_color_index[device_id] = joined_devices.size() - 1
	join_label.hide()
	fish.set("is_preview", true)

	var indicator := Polygon2D.new()
	indicator.color = Color(0.107, 0.107, 0.107, 1.0)  # grey = not ready
	# Small circle polygon
	var points := PackedVector2Array()
	for i in 16:
		var angle := i * TAU / 16
		points.append(Vector2(cos(angle), sin(angle)) * 15.0)
	indicator.polygon = points
	indicator.position = fish_previews[device_id].position + Vector2(0, 200)
	add_child(indicator)
	ready_indicators[device_id] = indicator

	device_color_index[device_id] = slot % COLORS.size()
	
	# Apply initial color immediately
	for child in fish.get_children():
		if child is Polygon2D:
			child.color = COLORS[device_color_index[device_id]]

func _try_ready(device_id: int) -> void:
	if ready_devices.has(device_id):
		ready_devices.erase(device_id)
		print("device ", device_id, " unreadied")
	else:
		ready_devices.append(device_id)
		print("device ", device_id, " ready! ready count: ", ready_devices.size())
	if ready_devices.has(device_id):
		ready_indicators[device_id].color = Color(0.3, 1.0, 0.4)  # green = ready
	else:
		ready_indicators[device_id].color = Color(0.3, 0.3, 0.3)
	
	_check_all_ready()

func _check_all_ready() -> void:
	if joined_devices.is_empty():
		return
	if ready_devices.size() == joined_devices.size():
		PlayerData.players.clear()
		for i in joined_devices.size():
			var device_id: int = joined_devices[i]
			PlayerData.players.append({
				"slot": i,
				"device_id": device_id,
				"color": COLORS[device_color_index[device_id]]
			})
		get_tree().change_scene_to_file("res://scenes/Gym_OLI.tscn")

func _try_leave(device_id: int) -> void:
	if not joined_devices.has(device_id):
		return
	joined_devices.erase(device_id)
	ready_devices.erase(device_id)
	if fish_previews.has(device_id):
		fish_previews[device_id].queue_free()
		fish_previews.erase(device_id)
	if joined_devices.is_empty():
		join_label.show()
	if ready_indicators.has(device_id):
		ready_indicators[device_id].queue_free()
		ready_indicators.erase(device_id)
