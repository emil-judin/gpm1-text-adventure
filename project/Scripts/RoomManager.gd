extends Node2D
class_name RoomManager

# NORTH, EAST, SOUTH, WEST
const DIRECTIONS: Array[Vector2] = [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)]

const ROOM_TILE_SIZE = 16
@export var mapRoomScene: PackedScene
@export var dungeonRoomScene: PackedScene
@export var mapParentNode: Control
@export var dungeonParentNode: Node2D
@export var enemyParentNode: Node2D
# map size in one direction
@export var mapSize: int = 4
@export var roomSize: int = 7
@export var numberOfRooms: int = 16
@export var bombSpawnProbability: float = 1
@export var healSpawnProbability: float = 1
@export var blockedDoorProbability: float = 0.1
@export var maxBlockedDoors: int = 4
var mapGrid: Dictionary
var dungeonGrid: Dictionary
var takenPositions: Array[Vector2]

func clearMap():
	mapGrid.clear()
	dungeonGrid.clear()
	takenPositions.clear()
	for m in mapParentNode.get_children():
		m.queue_free()
	for d in dungeonParentNode.get_children():
		d.queue_free()

func generateMap():
	var success = false
	while !success:
		success = createRooms()
	setRoomDoors()

func createRooms():
	# place first room in the middle
	createNewRoom(Vector2.ZERO)
	var randomCompareStart: float = 0.2
	var randomCompareEnd: float = 0.01
	
	var keyRoomIndex = RandomNumberGenerator.new().randi_range(1, numberOfRooms - 2)
	for i in numberOfRooms:
		var randomPerc: float = i / (numberOfRooms - 1)
		var randomCompare: float = lerp(randomCompareStart, randomCompareEnd, randomPerc)
		var currentRelativePosition = null
		
		if RandomNumberGenerator.new().randf() > randomCompare:
			# Find instead an extending position so the dungeon becomes longer
			currentRelativePosition = newExtendingPosition()
		else:
			currentRelativePosition = newPosition()

		if currentRelativePosition == null:
			# No new position can be found
			return false
		
		if i == 0:
			createNewRoom(currentRelativePosition, Room.RoomType.SPAWN)
		elif i == keyRoomIndex:
			createNewRoom(currentRelativePosition, Room.RoomType.KEY)
		elif i == numberOfRooms - 1:
			createNewRoom(currentRelativePosition, Room.RoomType.BOSS)
		else:
			createNewRoom(currentRelativePosition)
	
	return true

func createNewRoom(relativeRoomPosition: Vector2, roomType: Room.RoomType = Room.RoomType.REGULAR):
	takenPositions.append(relativeRoomPosition)
	
	# add room to map
	var mapRoomInstance = mapRoomScene.instantiate() as MapRoom
	mapGrid[relativeRoomPosition] = mapRoomInstance
	# TODO adjust global position
	mapParentNode.add_child(mapRoomInstance)
	# TODO: remove hard code of map sprite size below
	mapRoomInstance.position = mapParentNode.position + relativeRoomPosition * 16
	mapRoomInstance.relativeRoomPosition = relativeRoomPosition
	mapRoomInstance.roomType = roomType
	
	# add room to dungeon
	var dungeonRoomInstance = dungeonRoomScene.instantiate() as DungeonRoom
	dungeonParentNode.add_child(dungeonRoomInstance)
	dungeonRoomInstance.position = relativeRoomPosition * 16 * ROOM_TILE_SIZE
	dungeonRoomInstance.relativeRoomPosition = relativeRoomPosition
	dungeonGrid[relativeRoomPosition] = dungeonRoomInstance
	dungeonRoomInstance.roomType = roomType
	
	if roomType == Room.RoomType.KEY:
		dungeonRoomInstance.spawnKeyWarden()
	
	if dungeonRoomInstance.roomType == Room.RoomType.SPAWN:
		# guranteed bomb and heal spawn in starting room
		dungeonRoomInstance.spawnHeal()
		dungeonRoomInstance.spawnBomb()
	elif dungeonRoomInstance.roomType == Room.RoomType.REGULAR:
		# potentially spawn bomb
		if RandomNumberGenerator.new().randf() <= bombSpawnProbability:
			dungeonRoomInstance.spawnBomb()
		# potentially spawn heal
		if RandomNumberGenerator.new().randf() <= healSpawnProbability:
			dungeonRoomInstance.spawnHeal()

func newPosition():
	# get random taken position
	var possibleTakenRooms = getPossibleTakenPositions()
	if possibleTakenRooms.size() == 0:
		return null
	var randomPosition = possibleTakenRooms.pick_random()
	var randomDirection = DIRECTIONS.pick_random()
	var newRoomPosition = randomPosition + randomDirection
	
	var inBounds: bool = newRoomPosition.x <= mapSize && newRoomPosition.x >= -mapSize && newRoomPosition.y <= mapSize && newRoomPosition.y >= -mapSize
	if !takenPositions.has(newRoomPosition) && inBounds:
		# found new valid position
		return newRoomPosition
	else:
		# retry
		return newPosition()

func newExtendingPosition():
	# get random taken position
	var possibleTakenPositions = getPossibleTakenPositions()
	var takenPositionsWithOneNeighbor = possibleTakenPositions.filter(func(p): return numberOfNeighbors(p) == 1)
	if takenPositionsWithOneNeighbor.size() == 0:
		# Couldn't find position with only one neighbor
		# Pick random new position
		return newPosition()
	
	var randomPosition = takenPositionsWithOneNeighbor.pick_random()
	var randomDirection = DIRECTIONS.pick_random()
	var newRoomPosition = randomPosition + randomDirection
	
	var inBounds: bool = abs(newRoomPosition.x) <= abs(mapSize) && abs(newRoomPosition.y) <= abs(mapSize)
	if !takenPositions.has(newRoomPosition) && inBounds:
		return newRoomPosition
	else:
		# position not valid: try again
		return newExtendingPosition()
		
func getPossibleTakenPositions():
	return takenPositions.filter(func(p): return hasPossibleNewPosition(p))
	
func hasPossibleNewPosition(relativeRoomPosition: Vector2):
	var hasPossibleNewRoom = false
	
	for direction in DIRECTIONS:
		var newPossiblePosition: Vector2 = relativeRoomPosition + direction
		var isInBounds = (abs(newPossiblePosition.x) <= abs(mapSize) && abs(newPossiblePosition.y) <= abs(mapSize))
		hasPossibleNewRoom = hasPossibleNewRoom || (isInBounds && !takenPositions.has(newPossiblePosition))
		
	return hasPossibleNewRoom
	
func numberOfNeighbors(checkPos):
	var neighborCount: int = 0
	if takenPositions.has(checkPos + Vector2(0, -1)):
		neighborCount += 1
	if takenPositions.has(checkPos + Vector2(1, 0)):
		neighborCount += 1
	if takenPositions.has(checkPos + Vector2(0, 1)):
		neighborCount += 1
	if takenPositions.has(checkPos + Vector2(-1, 0)):
		neighborCount += 1
		
	return neighborCount

func setRoomDoors():
	# first set all room doors
	for x in range(-mapSize, mapSize + 1):
		for y in range(-mapSize, mapSize + 1):
			var currentRoomPosition: Vector2 = Vector2(x, y)
			if !mapGrid.has(currentRoomPosition):
				continue
				
			var currentMapRoom: MapRoom = mapGrid[currentRoomPosition]
			var currentDungeonRoom: DungeonRoom = dungeonGrid[currentRoomPosition]
			
			if currentRoomPosition.y > -mapSize && mapGrid.has(Vector2(currentRoomPosition.x, currentRoomPosition.y - 1)):
				currentMapRoom.addNorthernRoom()
				currentDungeonRoom.setNorthernDoor(false, dungeonGrid[currentRoomPosition + Vector2(0, -1)])
			if currentRoomPosition.x < mapSize && mapGrid.has(Vector2(currentRoomPosition.x + 1, currentRoomPosition.y)):
				currentMapRoom.addEasternRoom()
				currentDungeonRoom.setEasternDoor(false, dungeonGrid[currentRoomPosition + Vector2(1, 0)])
			if currentRoomPosition.y < mapSize && mapGrid.has(Vector2(currentRoomPosition.x, currentRoomPosition.y + 1)):
				currentMapRoom.addSouthernRoom()
				currentDungeonRoom.setSouthernDoor(false, dungeonGrid[currentRoomPosition + Vector2(0, 1)])
			if currentRoomPosition.x > -mapSize && mapGrid.has(Vector2(currentRoomPosition.x - 1, currentRoomPosition.y)):
				currentMapRoom.addWesternRoom()
				currentDungeonRoom.setWesternDoor(false, dungeonGrid[currentRoomPosition + Vector2(-1, 0)])
	
	# block boss room	
	var bossRoom: DungeonRoom = getDungeonBossRoom()
	for door in bossRoom.getDoors():
		bossRoom.blockDoor(door, true)
	
	# block some of these doors in both direction
	for i in maxBlockedDoors:
		var randomDungeonRoom: DungeonRoom
		var randomUnblockedDoor: Door = null
		while(randomUnblockedDoor == null):
			# first get random room which is not connected to spawn
			randomDungeonRoom = dungeonGrid.values().pick_random()
			if randomDungeonRoom.roomType == Room.RoomType.SPAWN:
				continue
			if randomDungeonRoom.getDoors().filter(func(d): return d.destinationRoom.roomType == Room.RoomType.SPAWN).size() > 0:
				continue
				
			# then get random unblocked door in that room
			randomUnblockedDoor = randomDungeonRoom.getDoorsByBlocked(false).pick_random()
		randomDungeonRoom.blockDoor(randomUnblockedDoor)

func getDungeonSpawnRoom():
	var spawnRooms = dungeonGrid.values().filter(func(room): return room.roomType == Room.RoomType.SPAWN)
	if spawnRooms.size() > 1:
		# this should not happen
		print("More than one spawn room?")
	if spawnRooms.size() < 1:
		print("No spawn room found")
		return null
		
	return spawnRooms[0]

func getDungeonBossRoom():
	var bossRooms = dungeonGrid.values().filter(func(room): return room.roomType == Room.RoomType.BOSS)
	if bossRooms.size() > 1:
		# this should not happen
		print("More than one boss room?")
	if bossRooms.size() < 1:
		print("No boss room found")
		return null
		
	return bossRooms[0]

func getMapSpawnRoom():
	var spawnRooms = mapGrid.values().filter(func(room): return room.roomType == Room.RoomType.SPAWN)
	if spawnRooms.size() > 1:
		# this should not happen
		print("More than one spawn room?")
		return null
	if spawnRooms.size() < 1:
		print("No spawn room found")
		return null
	
	return spawnRooms[0]

func canPlayerWalkNorth(currentRelativePlayerPosition: Vector2):
	var currentDungeonRoom: DungeonRoom = dungeonGrid.get(currentRelativePlayerPosition)
	return currentDungeonRoom.northernDoor != null && !currentDungeonRoom.northernDoor.blocked
	
func canPlayerWalkEast(currentRelativePlayerPosition: Vector2):
	var currentDungeonRoom: DungeonRoom = dungeonGrid.get(currentRelativePlayerPosition)
	return currentDungeonRoom.easternDoor != null && !currentDungeonRoom.easternDoor.blocked
	
func canPlayerWalkSouth(currentRelativePlayerPosition: Vector2):
	var currentDungeonRoom: DungeonRoom = dungeonGrid.get(currentRelativePlayerPosition)
	return currentDungeonRoom.southernDoor != null && !currentDungeonRoom.southernDoor.blocked
	
func canPlayerWalkWest(currentRelativePlayerPosition: Vector2):
	var currentDungeonRoom: DungeonRoom = dungeonGrid.get(currentRelativePlayerPosition)
	return currentDungeonRoom.westernDoor != null && !currentDungeonRoom.westernDoor.blocked
