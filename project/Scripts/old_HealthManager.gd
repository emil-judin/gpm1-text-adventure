extends Node
class_name HealthManager

@export var healthBar: ProgressBar
@export var maxHealth: int
var currentHealth: int

func _ready():
	currentHealth = maxHealth
	if healthBar != null:
		healthBar.max_value = maxHealth
		healthBar.value = maxHealth

func receiveDamage(damage):
	currentHealth -= damage
	
	if healthBar != null:
		healthBar.value = currentHealth
	
	if currentHealth <= 0:
		var parent = get_parent()
		if parent.has_method("die"):
			parent.die()
		else:
			print("Error: " + name + " could not find parent die() method")
			
func hasFullLife():
	return currentHealth == maxHealth
	
func healSelf(life: int):
	if currentHealth <= maxHealth:
		currentHealth += 1
