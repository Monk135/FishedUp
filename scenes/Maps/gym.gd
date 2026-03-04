extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _create_walls() -> void:
	var size := get_viewport_rect().size
	var thickness := 50.0

	_add_wall(Vector2(size.x / 2, -thickness / 2), size.x, thickness)
	_add_wall(Vector2(size.x / 2, size.y + thickness / 2), size.x, thickness)
	_add_wall(Vector2(-thickness / 2, size.y / 2), thickness, size.y)
	_add_wall(Vector2(size.x + thickness / 2, size.y / 2), thickness, size.y)

func _add_wall(pos: Vector2, width: float, height: float) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, height)
	col.shape = shape
	body.add_child(col)
	add_child(body)
