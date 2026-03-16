extends "res://scripts/Perks/perk_card.gd"

func _ready() -> void:
	perk_name = "Damage Increase"
	perk_description = "Increases Damage by 50%"
	border_color = Color(0.953, 0.116, 0.38, 1.0)
	super._ready()  # call parent _ready to apply the name/description to labels

func apply(fish: CharacterBody2D) -> void:
	fish.damage_bonus += 10
