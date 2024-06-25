extends Node
class_name StatsManager

@export var healLabel: Label
@export var bombLabel: Label
@export var key: TextureRect
@export var life1: TextureRect
@export var life2: TextureRect
@export var life3: TextureRect

func updateHeal(healCount: int):
	healLabel.text = "x " + str(healCount)

func updateBombs(bombCount: int):
	bombLabel.text = "x " + str(bombCount)
	
func updateHealth(health: int):
	if health < 0 or health > 3:
		print("health outside of usual range")
		return

	life1.modulate.a8 = 255 if health > 0 else 25
	life2.modulate.a8 = 255 if health > 1 else 25
	life3.modulate.a8 = 255 if health > 2 else 25

func updateKey(hasKey: bool):
	key.visible = hasKey
