extends "res://scripts/Perks/perk_card.gd"

func _ready() -> void:
	perk_name = "Turn Speed Increase"
	perk_description = "Increases Turn Speed by 100%"
	border_color = Color(0.0, 0.526, 0.918, 1.0)
	super._ready()  # call parent _ready to apply the name/description to labels

func apply(fish: CharacterBody2D) -> void:
	fish.turn_speed *= 1.5
	fish.max_rotation_speed *= 1.5
