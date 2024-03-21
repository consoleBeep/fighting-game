extends CharacterBody2D

class_name Player

signal HealthChanged

enum ControlScheme {
	PLAYER_1,
	PLAYER_2,
}

enum ActionType {
	KICK,
	PUNCH,
	JUMP,
}

const COMBOS = {
	[ ActionType.PUNCH ]: 5,
	[ ActionType.KICK ]: 10,
	[ ActionType.JUMP ]: 0,
	[ ActionType.JUMP, ActionType.KICK]: 15,
	[ ActionType.PUNCH, ActionType.PUNCH, ActionType.KICK ]: 50, # Aerial.
	[ ActionType.PUNCH, ActionType.KICK, ActionType.KICK ]: 50, # Body slam.
	[ ActionType.KICK, ActionType.KICK, ActionType.KICK ]: 25, # kick kick.
	[ ActionType.PUNCH, ActionType.PUNCH, ActionType.PUNCH, ActionType.KICK, ActionType.KICK ]: 100,
	[ ActionType.JUMP, ActionType.KICK, ActionType.KICK, ActionType.KICK, ActionType.JUMP, ActionType.PUNCH]: 500,
}

@export var NAME: String 
@export var MAX_HEALTH = 500
@export var CONTROL_SCHEME = ControlScheme.PLAYER_1
@export var SPEED = 300.0
@export var JUMP_VELOCITY = -400.0
@export var OPPONENT: Player = null
@export var knockback_distance = 10.0

@onready var HEALTH:int = MAX_HEALTH 
@onready var _animated_sprite = $AnimatedSprite2D
@onready var combo_timer = $ComboTimer
@onready var _partical = $Colliders/Punch/CollisionShape2D/GPUParticles2D
@onready var cooldown_timer = $Cooldown

var kick_target = null
var punch_target = null
var attack_sequence = [] 
#
var is_player_crouching = false
var is_blocking = false



var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


func control_scheme_string(control_scheme: ControlScheme):
	match control_scheme:
		ControlScheme.PLAYER_1:
			return "player_1"
		ControlScheme.PLAYER_2:
			return "player_2"


func map_action(control_scheme: String, action: String):
	return control_scheme + "_" + action


func _ready():
	pass


func _process(delta):
	handle_combat()
	handle_direction()

func handle_combat():
	
	if cooldown_timer.is_stopped() == false:
		return
		
	if is_blocking:
		_animated_sprite.play("block")
		return
		
	var animation = "default"
	var control_scheme = control_scheme_string(CONTROL_SCHEME)
	var action_type
	
	if Input.is_action_just_pressed(map_action(control_scheme, "kick")):
		if is_player_crouching == true:
			return
		animation = "kick"
		action_type = ActionType.KICK
	
	if Input.is_action_just_pressed(map_action(control_scheme, "punch")):
		animation = "punch"
		action_type = ActionType.PUNCH
	
	
	if action_type == null:
		return
	
	register_attack(action_type)
	detect_hit(action_type)
		
	_animated_sprite.play(animation)


func _physics_process(delta):
	handle_gravity(delta)
	handle_movement()



func handle_movement():
	var control_scheme = control_scheme_string(CONTROL_SCHEME)
	is_player_crouching = false
	$FullBody.disabled = false
	$Colliders/Punch/CollisionShape2D.disabled = false
	
	#_animated_sprite.play("default")
	var animation = "default"
	
	
	if Input.is_action_just_pressed(map_action(control_scheme, "jump")) and is_on_floor():
		animation = "jump"
		velocity.y = JUMP_VELOCITY
		register_attack(ActionType.JUMP)

	
	var direction = Input.get_axis(map_action(control_scheme, "move_left"), map_action(control_scheme, "move_right"))
	if direction:
		animation = "walk"
		velocity.x = direction * SPEED 
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	if Input.is_action_pressed(map_action(control_scheme, "crouch")):
		animation = "down"
		$FullBody.disabled = true
		$Colliders/Punch/CollisionShape2D.disabled = true
		is_player_crouching = true
	
	if Input.is_action_pressed(map_action(control_scheme, "block")):
		is_blocking = true
		animation = "block"
	else:
		is_blocking = false
		
		
	move_and_slide()
	
	_animated_sprite.play(animation)


func handle_gravity(delta):
	# Accelerate towards ground whilst not touching.
	if not is_on_floor():
		velocity.y += gravity * delta


func handle_orientation():
	var direction 


func detect_hit(action_type: ActionType):
	var target = null
	match action_type:
		ActionType.KICK:
			target = kick_target
		ActionType.PUNCH:
			target = punch_target
			
	if target != null:
		print(action_type, "hit ", target.name)  
		damage(target, action_type)
	else:
		print(action_type, "missed")


func damage(target: Player, last_attack: ActionType):
	if target.is_blocking:
		print("Blocked the attack!")
		return

	var last_attack_damage = COMBOS.get([last_attack])
	
	var damage_amount = COMBOS.get(attack_sequence)
	if damage_amount == null:
		damage_amount = last_attack_damage
		
	
	OPPONENT.HEALTH -= damage_amount
	OPPONENT.HealthChanged.emit()
	knockback()
	
	if damage_amount > 15:
		attack_sequence.clear()
		cooldown_timer.start()
		$FireParticle.restart()

	
	print(OPPONENT.HEALTH)
	print(damage_amount)


func register_attack(action_type: ActionType):
	combo_timer.start()  
	
	attack_sequence.append(action_type)
	if attack_sequence.size() > 6:
		attack_sequence.pop_front()
		
	print("Current attack sequence: ", attack_sequence)


func is_opponent_body(body) -> bool:
	if !body is Player:
		return false
	
	return body == OPPONENT


func _on_punch_body_entered(body):
	if !is_opponent_body(body):
		return
	
	punch_target = body


func _on_punch_body_exited(body):
	if !is_opponent_body(body):
		return
		
	punch_target = null


func _on_kick_body_entered(body):
	if !is_opponent_body(body):
		return
		
	kick_target = body


func _on_kick_body_exited(body):
	if !is_opponent_body(body):
		return
		
	kick_target = null


func _on_combo_timer_timeout():
	attack_sequence.clear()


var has_flipped = false
func handle_direction():
	if position.x < OPPONENT.position.x:
		return
	
	if !has_flipped:
		scale.x = -1
		has_flipped = true


func knockback():
	var direction = sign(global_position.x - OPPONENT.global_position.x)
	
	OPPONENT.global_position.x += direction * -knockback_distance


func block_timer():
	pass
