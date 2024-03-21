extends CharacterBody2D
@onready var _animated_sprite = $AnimatedSprite2D
@export var SPEED = 300.0
@export var JUMP_VELOCITY = -400.0


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_animated_sprite.play("default")
	if Input.is_action_just_pressed("jump") and is_on_floor():
		_animated_sprite.play("jump")
		velocity.y = JUMP_VELOCITY
		
	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		_animated_sprite.play("walk")
		velocity.x = direction * SPEED 
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	if Input.is_action_pressed("down"):
		_animated_sprite.play("down")
		$Body.disabled = true
		
		
		
	move_and_slide()
