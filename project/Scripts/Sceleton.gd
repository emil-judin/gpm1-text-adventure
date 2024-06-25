extends Node

@export var animationPlayer: AnimationPlayer

func _ready():
	animationPlayer.play("idle")
