extends "res://scripts/Perks/perk_card.gd"

func _ready() -> void:
	perk_name = "Speed Boost"
	perk_description = "Increases max speed and passive thrust"
	super._ready()  # call parent _ready to apply the name/description to labels

func apply(fish: CharacterBody2D) -> void:
	print("applying speed perk to fish, before: ", fish.max_speed)
	print("applying speed perk to fish, before: ", fish.thrust_force)
	fish.max_speed += 2000.0
	fish.thrust_force += 1000.0
	print("after: ", fish.max_speed)
	print("after: ", fish.thrust_force)
