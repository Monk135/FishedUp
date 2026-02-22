extends RigidBody2D

@export var bend_force: float = 5000.0
@export var max_angle_degrees: float = 45.0

@onready var head = get_parent().get_node("Head")
@onready var tail = get_parent().get_node("Tail")

func _physics_process(_delta):
	var angle_deg = rad_to_deg(rotation)
	
	if Input.is_action_pressed("belly_up"):
		if angle_deg > -max_angle_degrees:
			apply_central_force(Vector2(0, -bend_force))
	elif Input.is_action_pressed("belly_down"):
		if angle_deg < max_angle_degrees:
			apply_central_force(Vector2(0, bend_force))
