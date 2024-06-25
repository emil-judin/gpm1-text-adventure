extends Node
class_name KeyWarden

@export var animationPlayer: AnimationPlayer
var hasKey: bool = true

func _ready():
	animationPlayer.play("idle")
