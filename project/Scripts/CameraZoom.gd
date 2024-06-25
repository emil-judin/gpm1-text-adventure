extends Camera2D

@export var player: Node2D
@export var zoomSpeed: float

func _process(delta):
	if Input.is_action_pressed("zoom_in"):
		zoom += zoomSpeed * Vector2.ONE
		
	if Input.is_action_pressed("zoom_out"):
		zoom -= zoomSpeed * Vector2.ONE
