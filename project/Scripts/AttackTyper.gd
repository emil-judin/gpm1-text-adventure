extends Control
class_name AttackTyper

@export var regularPrompts: AttackPrompt = preload('res://Resources/PromptsRegular.tres')
@export var keyWardenPrompts: AttackPrompt = preload('res://Resources/PromptsKeyWarden.tres')
@export var bossPrompts: AttackPrompt = preload('res://Resources/PromptsBoss.tres')
@export var attackPromptLabel: RichTextLabel
@export var maxFails: int = 3
@export var timerProgressBar: ProgressBar
# key speed is in characters per second
var keySpeed: int
var currentAttackPrompt: String
var currentCharIndex: int = 0
var currentFails: int = 0
var isActive: bool = false
var currentTimer: float

signal attack_typer_finished(successful: bool)

func _ready():
	attackPromptLabel.text = "[center]" + currentAttackPrompt + "[/center]"
	currentCharIndex = 0
	currentFails = 0

func _process(delta):
	# handle timer
	if isActive:
		print(currentTimer)
		if currentTimer <= 0:
			# player took too long
			# TODO: add some feedback
			isActive = false
			emit_signal("attack_typer_finished", false)
		
		currentTimer -= delta
		timerProgressBar.value += delta

func _input(event):
	if event is InputEventKey and event.is_pressed() and isActive:
		if currentCharIndex >= currentAttackPrompt.length():
			# attack typer is already finished
			return

		var inputCharacter = char(event.unicode)
		if currentAttackPrompt[currentCharIndex] == inputCharacter:
			# right key hit
			currentCharIndex += 1
			if currentCharIndex == currentAttackPrompt.length():
				# attack prompt finished
				attackPromptLabel.text = "[center][color=green]" + currentAttackPrompt + "[/color][/center]"
				emit_signal("attack_typer_finished", true)
				isActive = false
			else:
				# format prompt
				var newText = "[center][color=green]" + currentAttackPrompt.substr(0, currentCharIndex) + "[/color][/center]" \
			 		+ "[u]" + currentAttackPrompt[currentCharIndex] + "[/u]" + currentAttackPrompt.substr(currentCharIndex + 1)
				attackPromptLabel.text = newText
		else:
			# wrong key
			print(inputCharacter)
			currentFails += 1
			# TODO: maybe screen shake and sound
			if currentFails >= maxFails:
				emit_signal("attack_typer_finished", false)
				isActive = false
			
func initAttackTyper(roomType: Room.RoomType):
	match roomType:
		Room.RoomType.REGULAR, Room.RoomType.SPAWN:
			currentAttackPrompt = regularPrompts.attackPrompts.pick_random()
			keySpeed = 4
			pass
		Room.RoomType.KEY:
			currentAttackPrompt = keyWardenPrompts.attackPrompts.pick_random()
			keySpeed = 5
			pass
		Room.RoomType.BOSS:
			currentAttackPrompt = bossPrompts.attackPrompts.pick_random()
			keySpeed = 6
			pass
	
	attackPromptLabel.text = "[center]" + currentAttackPrompt + "[/center]"
	currentCharIndex = 0
	currentFails = 0
	currentTimer = currentAttackPrompt.length() / keySpeed
	timerProgressBar.max_value = currentTimer
	print(timerProgressBar.max_value)
	timerProgressBar.value = 0
	isActive = true
