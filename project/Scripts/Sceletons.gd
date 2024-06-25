extends Node2D
class_name Sceletons

@export var healthManager: HealthManager
@export var animtationPlayer: AnimationPlayer

func _ready():
	if animtationPlayer != null:
		animtationPlayer.play("idle")

func receiveDamage(damage):
	healthManager.receiveDamage(damage)
	return healthManager.currentHealth

func die():
	queue_free()
	print("sceletons died")
