extends "res://scripts/Perks/perk_card.gd"

func _ready() -> void:
	perk_name = "Dash Cooldown Decrease"
	perk_description = "Decreases Dash Cooldown by 50%"
	border_color = Color(0.697, 0.258, 1.0, 1.0)
	super._ready()  # call parent _ready to apply the name/description to labels

func apply(fish: CharacterBody2D) -> void:
	fish.dash_cooldown *= 0.5
