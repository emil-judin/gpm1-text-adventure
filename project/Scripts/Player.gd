extends Node2D
class_name Player

@export var animationPlayer: AnimationPlayer
@export var statsManager: StatsManager
@export var baseDamage: float
@export var healthManager: HealthManager
var healCount: int = 0
var bombCount: int = 0
var hasKey: bool = false

func _ready():
	statsManager.updateHeal(healCount)
	statsManager.updateBombs(bombCount)
	statsManager.updateHealth(healthManager.currentHealth)
	statsManager.updateKey(hasKey)
	animationPlayer.play("idle")
	
func calculateDamage():
	return baseDamage

func addHeal():
	healCount += 1
	statsManager.updateHeal(healCount)

func addBomb():
	bombCount += 1
	statsManager.updateBombs(bombCount)
	
func addKey():
	hasKey = true
	statsManager.updateKey(hasKey)
	
func removeKey():
	hasKey = false
	statsManager.updateKey(hasKey)
	
func removeHeal():
	if healCount > 0:
		healCount -= 1
		statsManager.updateHeal(healCount)

func removeBomb():
	if bombCount > 0:
		bombCount -= 1
		statsManager.updateBombs(bombCount)
	
func receiveDamage(damage):
	healthManager.receiveDamage(damage)
	statsManager.updateHealth(healthManager.currentHealth)
	
func hasFullLife():
	return healthManager.hasFullLife()

func healSelf():
	removeHeal()
	healthManager.healSelf(1)
	statsManager.updateHealth(healthManager.currentHealth)
	
func die():
	statsManager.updateHealth(healthManager.currentHealth)
	get_tree().reload_current_scene()
