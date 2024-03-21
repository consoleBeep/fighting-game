extends ProgressBar

@export var player: Player

func _ready():
	player.HealthChanged.connect(update)
	update()
	
func update():
	value = player.HEALTH * 100.0 / player.MAX_HEALTH
