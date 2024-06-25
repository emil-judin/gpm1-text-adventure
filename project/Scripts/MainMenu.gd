extends Node

@export_file("*.tscn") var startGameScene

func startGame():
	get_tree().call_deferred("change_scene_to_file", startGameScene)
	
func quitGame():
	get_tree().quit()
