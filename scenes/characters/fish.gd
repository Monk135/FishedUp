extends RigidBody2D

@export var flip_force: float = 500.0
@export var push_force: float = 300.0
@export var max_velocity: float = 1000.0

@onready var ground_ray: RayCast2D = $RayCast2D
@onready var sprite: Sprite2D = $Sprite2D

var flip_tween: Tween
var can_flip: bool = true
var flip_cooldown: float = 0.2
var flip_timer: float = 0.0
var original_scale: Vector2

func _ready():
	# Set up the RayCast2D for ground detection
	ground_ray.target_position = Vector2(0, 50)  # Adjust length as needed
	ground_ray.enabled = true
	
	original_scale = sprite.scale
	
	# Connect to input events
	contact_monitor = true
	max_contacts_reported = 10

func _physics_process(delta):
	flip_timer -= delta
	if flip_timer <= 0:
		can_flip = true
	
	# Handle input
	handle_input()
	
	# Limit velocity to prevent crazy speeds
	if linear_velocity.length() > max_velocity:
		linear_velocity = linear_velocity.normalized() * max_velocity

func handle_input():
	if Input.is_action_just_pressed("flip") and can_flip:
		perform_flip()

func perform_flip():
	can_flip = false
	flip_timer = flip_cooldown
	
	# Get mouse position for directional flipping
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - global_position).normalized()
	
	# Apply force in the direction of mouse
	apply_central_impulse(direction * flip_force)
	
	# Add some spin for effect
	apply_torque_impulse(randf_range(-100, 100))
	
	# Visual feedback
	animate_flip()

func animate_flip():
	if flip_tween:
		flip_tween.kill()
	# Simple scale animation for flip feedback
	sprite.scale = original_scale # Reset before animating
	flip_tween = create_tween()
	flip_tween.tween_property(sprite, "scale", original_scale * Vector2(1.2, 0.8), 0.1)
	flip_tween.tween_property(sprite, "scale", original_scale * Vector2.ONE, 0.1)

func is_touching_ground() -> bool:
	return ground_ray.is_colliding()

# Optional: Add surface pushing mechanics
func _on_body_entered(body):
	if body.is_in_group("pushable"):
		var push_direction = (body.global_position - global_position).normalized()
		body.apply_central_impulse(push_direction * push_force)
