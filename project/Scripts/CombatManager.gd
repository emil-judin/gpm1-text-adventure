extends Node

@export var sceletonScene: PackedScene
@export var spawnProbabiblity: float
@export var spawnPoints: Array[Node2D]
#var sceletonInstances: Array[Sceleton]
#
#func _input(event):
	#if Input.is_action_just_pressed("ui_accept"):
		#spawnEnemies()
#
#func spawnEnemies():
	#for spawnPoint in spawnPoints:
		#var rng = RandomNumberGenerator.new()
		#var randomNumber = rng.randf_range(0, 1)
		#if randomNumber <= spawnProbabiblity:
			#print("Info: Spawning enemy")
			#spawnEnemyAtSpawnPoint(spawnPoint)
			#
#func spawnEnemyAtSpawnPoint(spawnPoint: Node2D):
	#var sceletonInstance = sceletonScene.instantiate() as Sceleton
	#sceletonInstance.global_position = spawnPoint.global_position
	#get_tree().current_scene.add_child(sceletonInstance)
	## TODO: append to some kind of group instead of array?
	#sceletonInstances.append(sceletonInstance)
