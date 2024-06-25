extends Node

@export var baseDamage: int

func dealDamage(target):
	# TODO: add randomizer to base damage
	
	if target.healthManager != null:
		var targetHealthManager = target.healthManager as HealthManager
		targetHealthManager.receiveDamage(baseDamage)
