extends Node

@export_file("*.tscn") var gameScene

func _process(delta):
	if Input.is_anything_pressed():
		get_tree().call_deferred("change_scene_to_file", gameScene)
