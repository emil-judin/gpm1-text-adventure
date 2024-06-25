extends Node
class_name RoomTransition

@export var player: Player
@export var camera: Camera2D
@export var pixelationAnimationPlayer: AnimationPlayer
@export var walkTime: float = 2
var destinationPosition: Vector2
var nextRoomSpawnPosition: Vector2
var currentDirection: Vector2
var time: float = 0
var walkingToDoor: bool = false
var walkingToSpawn: bool = false

func walkToDoor(direction: Vector2, roomSpawnPosition: Vector2):
	pixelationAnimationPlayer.play("room_out")
	currentDirection = direction
	destinationPosition = player.global_position + currentDirection * 32
	nextRoomSpawnPosition = roomSpawnPosition
	walkingToDoor = true
	
func walkToSpawn():
	camera.global_position = nextRoomSpawnPosition
	pixelationAnimationPlayer.play("room_in")
	player.global_position = nextRoomSpawnPosition - currentDirection * 32
	destinationPosition = nextRoomSpawnPosition
	walkingToSpawn = true
	
func _process(delta):
	if walkingToDoor || walkingToSpawn:
		if time < walkTime:
			time += delta
			player.global_position = player.global_position.lerp(destinationPosition, time / walkTime)
		elif walkingToDoor:
			time = 0
			walkingToDoor = false
			walkToSpawn()
		elif walkingToSpawn:
			time = 0
			walkingToSpawn = false
