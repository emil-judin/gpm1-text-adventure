extends Control
class_name TextParser

@export var gameManager: GameManager
@export var inputLineEdit: LineEdit
@export var outputContainer: Container
@export var labelPreset: PackedScene
@export var focusColor: Color
@export var unfocusedColor: Color

func inputSubmitted(input: String):
	if input == "":
		return
	
	# make everything lowercase
	input = input.to_lower()
	
	# structure should be: <command> <thing>
	var inputParts = input.split(" ", false)
	if inputParts.size() == 0:
		# nothing supplied
		return
	
	printOutput(input, false)
	gameManager.parseInput(inputParts)
	inputLineEdit.text = ""

func printOutput(output: String, isFocus: bool = true):
	var outputLabel: LabelPreset = labelPreset.instantiate() as LabelPreset
	var color = focusColor if isFocus else unfocusedColor
	outputLabel.text = "[color='" + color.to_html() + "']" + output + "[/color]"
	outputContainer.add_child(outputLabel)
