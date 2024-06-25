extends Node2D
class_name DungeonRoom

@export var bombScene: PackedScene
@export var bombNode: Node2D
@export var healScene: PackedScene
@export var healNode: Node2D
@export var keyWardenScene: PackedScene
@export var keyWardenNode: Node2D
@export var dungeonTileMap: TileMap
@export var relativeSpawnPosition: Vector2
@export var northernDoorPosition: Vector2
@export var easternDoorPosition: Vector2
@export var southernDoorPosition: Vector2
@export var westernDoorPosition: Vector2
var northernDoor: Door = null
var easternDoor: Door = null
var southernDoor: Door = null
var westernDoor: Door = null
var relativeRoomPosition: Vector2
var roomType: Room.RoomType = Room.RoomType.REGULAR
var spriteIndex: int = 0

func setNorthernDoor(blocked: bool, destinationRoom: DungeonRoom):
	if northernDoor == null:
		northernDoor = Door.new()
	northernDoor.blocked = blocked
	northernDoor.destinationRoom = destinationRoom
	updateDoors()
	
func setEasternDoor(blocked: bool, destinationRoom: DungeonRoom):
	if easternDoor == null:
		easternDoor = Door.new()
	easternDoor.blocked = blocked
	easternDoor.destinationRoom = destinationRoom
	updateDoors()
	
func setSouthernDoor(blocked: bool, destinationRoom: DungeonRoom):
	if southernDoor == null:
		southernDoor = Door.new()
	southernDoor.blocked = blocked
	southernDoor.destinationRoom = destinationRoom
	updateDoors()
	
func setWesternDoor(blocked: bool, destinationRoom: DungeonRoom):
	if westernDoor == null:
		westernDoor = Door.new()
	westernDoor.blocked = blocked
	westernDoor.destinationRoom = destinationRoom
	updateDoors()
		
func updateDoors():
	# northern door
	if northernDoor != null:
		if northernDoor.blocked:
			if northernDoor.isBossDoor:
				dungeonTileMap.set_cell(0, northernDoorPosition, 0, Vector2i(3, 5))
			else:
				dungeonTileMap.set_cell(0, northernDoorPosition, 0, Vector2i(5, 3))
		else:
			dungeonTileMap.set_cell(0, northernDoorPosition, 0, Vector2i(3, 3))
		
	# eastern door
	if easternDoor != null:
		if easternDoor.blocked:
			if easternDoor.isBossDoor:
				dungeonTileMap.set_cell(0, easternDoorPosition, 0, Vector2i(4, 5))
			else:
				dungeonTileMap.set_cell(0, easternDoorPosition, 0, Vector2i(6, 3))
		else:
			dungeonTileMap.set_cell(0, easternDoorPosition, 0, Vector2i(4, 3))
		
	# southern door
	if southernDoor != null:
		if southernDoor.blocked:
			if southernDoor.isBossDoor:
				dungeonTileMap.set_cell(0, southernDoorPosition, 0, Vector2i(3, 6))
			else:
				dungeonTileMap.set_cell(0, southernDoorPosition, 0, Vector2i(5, 4))
		else:
			dungeonTileMap.set_cell(0, southernDoorPosition, 0, Vector2i(3, 4))
		
	# western door
	if westernDoor != null:
		if westernDoor.blocked:
			if westernDoor.isBossDoor:
				dungeonTileMap.set_cell(0, westernDoorPosition, 0, Vector2i(4, 6))
			else:
				dungeonTileMap.set_cell(0, westernDoorPosition, 0, Vector2i(6, 4))
		else:
			dungeonTileMap.set_cell(0, westernDoorPosition, 0, Vector2i(4, 4))

func getAbsolutePlayerSpawnPosition():
	return global_position + relativeSpawnPosition

func spawnKeyWarden():
	var keyWardenInstance = keyWardenScene.instantiate() as Node2D
	keyWardenNode.add_child(keyWardenInstance)
	keyWardenInstance.global_position = keyWardenNode.global_position
	
func hasKeyWarden():
	return keyWardenNode.get_child_count() > 0
	
func removeKeyFromKeyWarden():
	var keyWardenInstance = keyWardenNode.get_child(0) as KeyWarden
	keyWardenInstance.hasKey = false
	
func keyWardenHasKey():
	var keyWardenInstance = keyWardenNode.get_child(0) as KeyWarden
	return hasKeyWarden() && keyWardenInstance.hasKey

func spawnBomb():
	var bombInstance = bombScene.instantiate() as Node2D
	bombNode.add_child(bombInstance)
	bombInstance.global_position = getAbsolutePlayerSpawnPosition() + getRandomItemSpawnOffset()
	
func hasBomb():
	return bombNode.get_child_count() > 0

func pickUpBomb():
	bombNode.remove_child(bombNode.get_child(0))
	
func spawnHeal():
	var healInstance = healScene.instantiate() as Node2D
	healNode.add_child(healInstance)
	healInstance.global_position = getAbsolutePlayerSpawnPosition() + getRandomItemSpawnOffset()

func hasHeal():
	return healNode.get_child_count() > 0

func pickUpHeal():
	healNode.remove_child(healNode.get_child(0))
	
func blockDoor(door: Door, isBossDoor: bool = false):
	door.blocked = true
	door.isBossDoor = isBossDoor
	updateDoors()
	
	# also block the adjacent dungeon door
	var adjacentDoor = getAdjacentDungeonDoor(door)
	adjacentDoor.blocked = true
	adjacentDoor.isBossDoor = isBossDoor
	door.destinationRoom.updateDoors()
	
func getAdjacentDungeonDoor(door: Door):
	var destinationRoom: DungeonRoom = door.destinationRoom
	var adjacentDungeonDoors: Array[Door] = destinationRoom.getDoors().filter(func(d): return d.destinationRoom == self)
	if adjacentDungeonDoors.size() != 1:
		print("Found none or multiple adjacent dungeon doors")
		
	return adjacentDungeonDoors[0]

func bombDoor(door: Door):
	door.blocked = false
	updateDoors()
	
	# also block the adjacent dungeon door
	getAdjacentDungeonDoor(door).blocked = false
	door.destinationRoom.updateDoors()

func getDoors():
	var blockedDoors: Array[Door] = []
	if northernDoor != null:
		blockedDoors.append(northernDoor)
	if easternDoor != null:
		blockedDoors.append(easternDoor)
	if southernDoor != null:
		blockedDoors.append(southernDoor)
	if westernDoor != null:
		blockedDoors.append(westernDoor)
	
	return blockedDoors

func getDoorsByBlocked(blocked: bool):
	var blockedDoors: Array[Door] = []
	if northernDoor != null && northernDoor.blocked == blocked:
		blockedDoors.append(northernDoor)
	if easternDoor != null && easternDoor.blocked == blocked:
		blockedDoors.append(easternDoor)
	if southernDoor != null && southernDoor.blocked == blocked:
		blockedDoors.append(southernDoor)
	if westernDoor != null && westernDoor.blocked == blocked:
		blockedDoors.append(westernDoor)
	
	return blockedDoors

func getRandomItemSpawnOffset():
	var x = RandomNumberGenerator.new().randf_range(-16*1.2, 16*1.2)
	var y = RandomNumberGenerator.new().randf_range(-16*1.2, 16*1.2)
	
	return Vector2(x, y)
