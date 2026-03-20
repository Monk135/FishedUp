extends Area2D

@export var current_direction: Vector2 = Vector2.RIGHT
@export var current_strength: float = 4000.0

var fishes_in_current: Array = []

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(delta):
	for fish in fishes_in_current:
		if is_instance_valid(fish):
			fish.external_force_GPI += current_direction.normalized() * current_strength

func _on_body_entered(body):
	if body.is_in_group("fish"):
		fishes_in_current.append(body)

func _on_body_exited(body):
	if body.is_in_group("fish"):
		fishes_in_current.erase(body)
