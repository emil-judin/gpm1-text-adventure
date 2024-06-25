extends Node

@export_file("*.tscn") var gameScene
@export_file("*.tscn") var mainMenuScene

func playAgain():
	get_tree().call_deferred("change_scene_to_file", gameScene)
	
func goToMainMenu():
	get_tree().call_deferred("change_scene_to_file", mainMenuScene) 
