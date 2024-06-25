extends Node2D
class_name MapRoom

@export var roomSprite: Sprite2D
@export var roomTextures: Array[Texture2D]
var hasNorthernRoom: bool = false
var hasEasternRoom: bool = false
var hasSouthernRoom: bool = false
var hasWesternRoom: bool = false
var relativeRoomPosition: Vector2
var roomType: Room.RoomType = Room.RoomType.REGULAR
var spriteIndex: int = 0

func _ready():
	updateSprite()

func addNorthernRoom():
	hasNorthernRoom = true
	spriteIndex += 1
	updateSprite()

func addEasternRoom():
	hasEasternRoom = true
	spriteIndex += 2
	updateSprite()
	
func addSouthernRoom():
	hasSouthernRoom = true
	spriteIndex += 4
	updateSprite()

func addWesternRoom():
	hasWesternRoom = true
	spriteIndex += 8
	updateSprite()

func updateSprite():
	roomSprite.texture = roomTextures[spriteIndex]
	match roomType:
		Room.RoomType.REGULAR:
			roomSprite.set_modulate(Color8(255, 255, 255))
		Room.RoomType.SPAWN:
			roomSprite.set_modulate(Color8(0, 255, 0))
		Room.RoomType.BOSS:
			pass # for debugging
			#roomSprite.set_modulate(Color8(255, 0, 0))
		Room.RoomType.KEY:
			pass # for debugging
			#roomSprite.set_modulate(Color8(255, 255, 0))
