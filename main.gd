extends Node2D

@export var player: Player
@onready var winner_text = $WinnerText
@onready var restart_text = $RestartText
@onready var timer_left = $TimeLeftText

func _ready():
	restart_text.visible = false
	winner_text.visible = false
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	handle_restart_request()
	check_win_condition()
	timer_left.text = "%d:%02d" % [floor($Timer.time_left / 60), int($Timer.time_left) % 60]

func check_win_condition():
	if $Timer.time_left <= 0:
		calculate_winner()
		disable_players()
	
	if player.HEALTH > 0 and player.OPPONENT.HEALTH > 0:
		return
	else:
		calculate_winner()
	
	disable_players()
	

func winner_name(winner_name):
	winner_text.visible = true
	winner_text.text = "winner:" + " "+ winner_name
	
	restart_text.visible = true


func handle_restart_request():
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
	
func disable_players():
	$Player1.process_mode = 4
	$Player2.process_mode = 4
	
func calculate_winner():
	if player.HEALTH > player.OPPONENT.HEALTH:
		winner_name(player.NAME)
	
	if player.HEALTH < player.OPPONENT.HEALTH:
		winner_name(player.OPPONENT.NAME)
		
	if player.HEALTH == player.OPPONENT.HEALTH:
		winner_name("draw")


