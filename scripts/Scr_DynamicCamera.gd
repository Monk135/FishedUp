extends Camera2D

@export var map_size: Vector2 = Vector2(1920, 1080)
@export var min_zoom: float = 0.3
@export var max_zoom: float = 2.0
@export var zoom_margin: float = 200.0
@export var follow_speed: float = 5.0

var map_start: Vector2
var map_end: Vector2

func _ready() -> void:
	anchor_mode = AnchorMode.ANCHOR_MODE_DRAG_CENTER
	# Use camera's initial position as the map center
	map_start = global_position - map_size / 2.0
	map_end = global_position + map_size / 2.0

func _physics_process(delta: float) -> void:
	var fish := get_tree().get_nodes_in_group("fish")
	if fish.is_empty():
		return

	var min_pos := Vector2(INF, INF)
	var max_pos := Vector2(-INF, -INF)
	for f in fish:
		var pos: Vector2 = f.global_position
		min_pos.x = min(min_pos.x, pos.x)
		min_pos.y = min(min_pos.y, pos.y)
		max_pos.x = max(max_pos.x, pos.x)
		max_pos.y = max(max_pos.y, pos.y)

	var target_pos := (min_pos + max_pos) / 2.0

	var spread := max_pos - min_pos + Vector2(zoom_margin, zoom_margin) * 2.0
	var viewport_size := get_viewport_rect().size
	var target_zoom_value : float = min(
		viewport_size.x / spread.x,
		viewport_size.y / spread.y
	)
	target_zoom_value = clamp(target_zoom_value, min_zoom, max_zoom)

	var half_view := viewport_size / (2.0 * target_zoom_value)
	target_pos.x = clamp(target_pos.x, map_start.x + half_view.x, map_end.x - half_view.x)
	target_pos.y = clamp(target_pos.y, map_start.y + half_view.y, map_end.y - half_view.y)

	global_position = global_position.lerp(target_pos, follow_speed * delta)
	zoom = zoom.lerp(Vector2.ONE * target_zoom_value, follow_speed * delta)
