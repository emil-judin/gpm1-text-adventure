extends Node2D
class_name GameManager

@export_file("*.tscn") var winScreenScene
@export var roomTransition: RoomTransition
@export var player: Player
@export var pin: Control
@export var mapNode: Control
@export var textParser: TextParser
# TODO: Add currentRelativePlayerPosition to the player not the game manager?
@export var roomManager: RoomManager
@export var attackTyper: AttackTyper
@export var camera: Camera2D
@export var sceletonsScene: PackedScene
@export var sceletonBossScene: PackedScene
@export var sceletonsSpawnProbabiblity: float
@export var enemyDropHealProbability: float = 0.2
@export var enemyDropBombProbability: float = 0.2
var sceletonsInstance: Sceletons
var currentRelativePlayerPosition: Vector2
var isInCombat: bool = false
var isInBossFight: bool = false

signal enemyDeath
signal bombSound

func _ready():
	roomManager.clearMap()
	roomManager.generateMap()
	
	# spawn player into map
	var dungeonSpawnRoom: DungeonRoom = roomManager.getDungeonSpawnRoom()
	var mapSpawnRoom: MapRoom = roomManager.getMapSpawnRoom()
	currentRelativePlayerPosition = dungeonSpawnRoom.relativeRoomPosition
	player.global_position = dungeonSpawnRoom.getAbsolutePlayerSpawnPosition()
	var pinToNewSpawnRoom = pin.global_position - mapSpawnRoom.global_position
	mapNode.position += pinToNewSpawnRoom
	camera.global_position = player.global_position
	textParser.inputLineEdit.grab_focus()
	
func _input(event):
	if event.is_action_pressed("regenerate_map"):
		roomManager.clearMap()
		roomManager.generateMap()
		
		# spawn player into map
		var dungeonSpawnRoom: DungeonRoom = roomManager.getDungeonSpawnRoom()
		var mapSpawnRoom: MapRoom = roomManager.getMapSpawnRoom()
		currentRelativePlayerPosition = dungeonSpawnRoom.relativeRoomPosition
		player.global_position = dungeonSpawnRoom.getAbsolutePlayerSpawnPosition()
		var pinToNewSpawnRoom = pin.global_position - mapSpawnRoom.global_position
		mapNode.position += pinToNewSpawnRoom
		camera.global_position = player.global_position
		textParser.inputLineEdit.grab_focus()
		
func showWinScreen():
	get_tree().call_deferred("change_scene_to_file", winScreenScene)
	
func parseInput(inputParts: Array[String]):
	# structure should be: <command> <thing>
	var command = inputParts[0]
	
	match command:
		# TODO: add synonyms
		"talk":
			handleTalk()
		"go":
			handleGo(inputParts)
		"pick":
			handlePick(inputParts)
		"drop":
			handleDrop(inputParts)
		"use":
			handleUse(inputParts)
		"attack":
			handleAttack()
		"help":
			handleHelp()
		"quit":
			get_tree().quit()
		_:
			# unknown command
			textParser.printOutput("Unknown command")

func handleHelp():
	var helpOutput = "go <direction>: move room into specified direction\n" + \
		"pick <object>: pick up specified object\n" + \
		"use <object> (<direction>): use specified object\n" + \
		"drop <object>: drop specified object\n" + \
		"attack: attack current enemy\n" + \
		"talk: talk to someone in current room\n" + \
		"help: print this help\n" + \
		"quit: quit game"
	textParser.printOutput(helpOutput)

func handleTalk():
	var currentDungeonRoom: DungeonRoom = roomManager.dungeonGrid.get(currentRelativePlayerPosition)
	
	if isInCombat && !isInBossFight:
		# talk to sceletons
		textParser.printOutput("The sceletons don't seem up for much conversation")
	elif isInCombat && isInBossFight:
		textParser.printOutput("Sceleton boss is angry and says some evil swearwords")
	elif !isInCombat && currentDungeonRoom.hasKeyWarden():
		if currentDungeonRoom.keyWardenHasKey():
			textParser.printOutput("You can get a key if you win my challenge")
			# short delay to read
			await get_tree().create_timer(2).timeout
			attackTyper.initAttackTyper(currentDungeonRoom.roomType)
			attackTyper.visible = true
			textParser.visible = false
		else:
			textParser.printOutput("Good luck with the boss")
	elif !isInCombat && !currentDungeonRoom.hasKeyWarden():
		textParser.printOutput("There is no one here to talk to")
	else:
		# should not happen
		textParser.printOutput("Who are you talking to?")

func handleAttack():
	var currentDungeonRoom: DungeonRoom = roomManager.dungeonGrid.get(currentRelativePlayerPosition)
	# start attack
	if !isInCombat:
		textParser.printOutput("Nothing to combat right now")
		return
	
	attackTyper.initAttackTyper(currentDungeonRoom.roomType)
	# hide prompt edit and history
	attackTyper.visible = true
	textParser.visible = false

func handleAttackTyperFeedback(successful: bool):
	var currentDungeonRoom: DungeonRoom = roomManager.dungeonGrid.get(currentRelativePlayerPosition)
	
	if successful:
		if isInCombat:
			# deal damage to sceletons
			var damage = player.calculateDamage()
			var remainingHealth = sceletonsInstance.receiveDamage(damage)
		
			if remainingHealth <= 0:
				enemyDeath.emit()
				
				# won against enemy
				if isInBossFight:
					# won game
					showWinScreen()
				
				# potentially drop bombs
				if RandomNumberGenerator.new().randf() <= enemyDropBombProbability:
					player.addBomb()
					textParser.printOutput("Dropped 1 bomb")
				
				# potentially drop heal
				if RandomNumberGenerator.new().randf() <= enemyDropHealProbability:
					player.addHeal()
					textParser.printOutput("Dropped 1 heal")
				
				sceletonsInstance = null
				isInCombat = false
		else:
			# doing the npc challenge
			# player receives key
			player.addKey()
			# remove key from npc
			currentDungeonRoom.removeKeyFromKeyWarden()
			textParser.printOutput("You got the key, good luck with the boss")
			pass
	else:
		if isInCombat:
			# player receives damage
			player.receiveDamage(1)
			textParser.printOutput("You failed, the enemy counterattacked")
		else:
			# failed npc challenge
			textParser.printOutput("If you can't even beat me how do you want to beat the boss?")
	
	attackTyper.visible = false
	textParser.visible = true
	if get_tree() != null:
		await get_tree().process_frame
		textParser.inputLineEdit.grab_focus()

func handleUse(inputParts):
	# use command
	if inputParts.size() <= 1:
		textParser.printOutput("Use what?")
		return
		
	var object = inputParts[1]
	match object:
		"heal":
			if player.healCount > 0:
				if player.hasFullLife():
					textParser.printOutput("You are already at full life")
					return
				player.removeHeal()
				player.healSelf()
				textParser.printOutput("You healed yourself")
			else:
				textParser.printOutput("No heal to use")
		"key":
			if player.hasKey:
				var currentDungeonRoom: DungeonRoom = roomManager.dungeonGrid.get(currentRelativePlayerPosition)
				var blockedBossDoors = currentDungeonRoom.getDoorsByBlocked(true).filter(func(d): return d.isBossDoor)
				if blockedBossDoors.size() == 0:
					textParser.printOutput("No doors to use a key on")
					return
				
				player.removeKey()
				
				# get boss room and open all doors
				var bossRoom = roomManager.getDungeonBossRoom()
				for d in bossRoom.getDoorsByBlocked(true):
					bossRoom.bombDoor(d)
				
				textParser.printOutput("You opened the boss room")
			else:
				textParser.printOutput("No key to use")
		"bomb":
			if player.bombCount > 0:
				var currentDungeonRoom: DungeonRoom = roomManager.dungeonGrid.get(currentRelativePlayerPosition)
				var blockedDoorsCount = currentDungeonRoom.getDoorsByBlocked(true).size()
				match blockedDoorsCount:
					0:
						textParser.printOutput("No blocked doors to bomb")
					1:
						# bomb door open
						var blockedDoors = currentDungeonRoom.getDoorsByBlocked(true)
						if blockedDoors[0].isBossDoor:
							textParser.printOutput("You cannot bomb a boss door")
							return
							
						currentDungeonRoom.bombDoor(blockedDoors[0])
						bombSound.emit()
						player.removeBomb()
						textParser.printOutput("Bombed the remaining door")
					2, 3, 4:
						# specify direction
						if inputParts.size() < 3:
							textParser.printOutput("No direction specified")
							return
						
						var direction: String = inputParts[2]
						match direction:
							"north", "up":
								var northernDoor = currentDungeonRoom.northernDoor
								if northernDoor != null && northernDoor.blocked && !northernDoor.isBossDoor:
									bombSound.emit()
									currentDungeonRoom.bombDoor(northernDoor)
									player.removeBomb()
									textParser.printOutput("Bombed the northern door")
								else:
									textParser.printOutput("Cannot bomb north")
									return
							"east", "left":
								var easternDoor = currentDungeonRoom.easternDoor
								if easternDoor != null && easternDoor.blocked && !easternDoor.isBossDoor:
									bombSound.emit()
									currentDungeonRoom.bombDoor(easternDoor)
									player.removeBomb()
									textParser.printOutput("Bombed the eastern door")
								else:
									textParser.printOutput("Cannot bomb east")
									return
							"south", "down":
								var southernDoor = currentDungeonRoom.southernDoor
								if southernDoor != null && southernDoor.blocked && !southernDoor.isBossDoor:
									bombSound.emit()
									currentDungeonRoom.bombDoor(southernDoor)
									player.removeBomb()
									textParser.printOutput("Bombed the southern door")
								else:
									textParser.printOutput("Cannot bomb south")
									return
							"west", "right":
								var westernDoor = currentDungeonRoom.westernDoor
								if westernDoor != null && westernDoor.blocked && !westernDoor.isBossDoor:
									bombSound.emit()
									currentDungeonRoom.bombDoor(westernDoor)
									player.removeBomb()
									textParser.printOutput("Bombed the western door")
								else:
									textParser.printOutput("Cannot bomb west")
									return
							_:
								textParser.printOutput("Unknown direction: " + direction)
								return
					_:
						textParser.printOutput("What is this sorcery?! There are " + str(blockedDoorsCount) + " blocked rooms")
						return
			else:
				textParser.printOutput("No bombs to use")
		_:
			textParser.printOutput("No " + object + " to drop")

func handleGo(inputParts):
	if isInCombat:
		textParser.printOutput("You are currently in combat and cannot flee")
		return
	
	# walk command
	if inputParts.size() <= 1:
		textParser.printOutput("Go where?")
		return

	var location = inputParts[1]
	match location:
		"north", "up":
			if roomManager.canPlayerWalkNorth(currentRelativePlayerPosition):
				textParser.printOutput("Going north")
				walkPlayerNorth()
				textParser.printOutput("Cannot go north")
		"east", "right":
			if roomManager.canPlayerWalkEast(currentRelativePlayerPosition):
				textParser.printOutput("Going east")
				walkPlayerEast()
				textParser.printOutput("Cannot go east")
		"south", "down":
			if roomManager.canPlayerWalkSouth(currentRelativePlayerPosition):
				textParser.printOutput("Going south")
				walkPlayerSouth()
				textParser.printOutput("Cannot go south")
		"west", "left":
			if roomManager.canPlayerWalkWest(currentRelativePlayerPosition):
				textParser.printOutput("Going west")
				walkPlayerWest()
			else:
				textParser.printOutput("Cannot go west")
		_:
			textParser.printOutput("Unknown direction")
	# potentially spawn enemies
	var currentDungeonRoom: DungeonRoom = roomManager.dungeonGrid.get(currentRelativePlayerPosition)	
	if currentDungeonRoom.roomType == Room.RoomType.BOSS:
		spawnBoss()
		print(str(currentDungeonRoom.relativeRoomPosition))
	elif currentDungeonRoom.roomType == Room.RoomType.REGULAR:
		# potentially spawn random encounters
		spawnEnemies()

func spawnBoss():
	var currentDungeonRoom: DungeonRoom = roomManager.dungeonGrid.get(currentRelativePlayerPosition)
	sceletonsInstance = sceletonBossScene.instantiate() as Sceletons
	roomManager.enemyParentNode.add_child(sceletonsInstance)
	sceletonsInstance.global_position = currentDungeonRoom.getAbsolutePlayerSpawnPosition()
	isInCombat = true
	isInBossFight = true

func spawnEnemies():
	if RandomNumberGenerator.new().randf() <= sceletonsSpawnProbabiblity:
		var currentDungeonRoom: DungeonRoom = roomManager.dungeonGrid.get(currentRelativePlayerPosition)
		sceletonsInstance = sceletonsScene.instantiate() as Sceletons
		roomManager.enemyParentNode.add_child(sceletonsInstance)
		sceletonsInstance.global_position = currentDungeonRoom.getAbsolutePlayerSpawnPosition()
		isInCombat = true
	
func handlePick(inputParts):
	# Pick up bomb or heal
	if inputParts.size() <= 1:
		textParser.printOutput("Pick up what?")
		return
	
	var currentDungeonRoom: DungeonRoom = roomManager.dungeonGrid.get(currentRelativePlayerPosition)
	var object = inputParts[1]
	match object:
		"heal":
			if currentDungeonRoom.hasHeal():
				currentDungeonRoom.pickUpHeal()
				player.addHeal()
				textParser.printOutput("Picking up heal")
			else:
				textParser.printOutput("No heal to pick up")
		"bomb":
			if currentDungeonRoom.hasBomb():
				currentDungeonRoom.pickUpBomb()
				player.addBomb()
				textParser.printOutput("Picking up bomb")
			else:
				textParser.printOutput("No bombs to pick up")
		_:
			textParser.printOutput("No " + object + " to pick up")
	
func handleDrop(inputParts):
	# drop bomb or heal
	if inputParts.size() <= 1:
		textParser.printOutput("Drop what?")
		return
	
	var object = inputParts[1]
	match object:
		"heal":
			if player.healCount > 0:
				# TODO: re-add dropped heal to room?
				player.removeHeal()
				textParser.printOutput("Dropping heal")
			else:
				textParser.printOutput("No heal to drop")
		"bomb":
			if player.bombCount > 0:
				# TODO: re-add dropped bomb to room?
				player.removeBomb()
				textParser.printOutput("Dropping bomb")
			else:
				textParser.printOutput("No bombs to drop")
		"key":
			if player.hasKey:
				textParser.printOutput("I think dropping the key would be a bad idea")
			else:
				textParser.printOutput("I don't have a key")
		_:
			textParser.printOutput("No " + object + " to drop")

func walkPlayer(direction: Vector2):
	var newPosition: Vector2 = currentRelativePlayerPosition + direction
	var newDungeonRoom: DungeonRoom = roomManager.dungeonGrid.get(newPosition)
	var newMapRoom: MapRoom = roomManager.mapGrid.get(newPosition)
	
	if newDungeonRoom == null || newMapRoom == null:
		# no room in that direction, should not happen
		print("Error: There is no dungeon or map room in direction (" + str(direction.x) + "," + str(direction.y) + ")")
		return
	
	currentRelativePlayerPosition = newPosition
	roomTransition.walkToDoor(direction, newDungeonRoom.getAbsolutePlayerSpawnPosition())
	var pinToNewMapRoom = pin.global_position - newMapRoom.global_position
	mapNode.position += pinToNewMapRoom

func walkPlayerNorth():
	walkPlayer(Vector2(0, -1))
	
func walkPlayerEast():
	walkPlayer(Vector2(1, 0))
	
func walkPlayerSouth():
	walkPlayer(Vector2(0, 1))
	
func walkPlayerWest():
	walkPlayer(Vector2(-1, 0))
