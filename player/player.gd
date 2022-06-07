extends CharacterBody3D

class_name Player


@export var speed: float

@onready var anim_tree := $AnimationTree as AnimationTree
@onready var state_machine = anim_tree["parameters/playback"] as AnimationNodeStateMachinePlayback
@onready var camera := $Camera3D as Camera3D
@onready var health_label := %HealthValue as Label
@onready var suit_power_label := %SuitValue as Label
@onready var use_raycast := $Camera3D/UseRayCast3D as RayCast3D
@onready var sound_cannot_use := $SoundCannotUse as AudioStreamPlayer
@onready var sound_flashlight := $SoundFlashlight as AudioStreamPlayer

const AIR_ACCELERATION = 2.0
const FALL_DAMAGE_THRESHOLD = 20.0
const FALL_DAMAGE_MULTIPLIER = 15.0
const GROUND_ACCELERATION = 20.0
const JUMP_VELOCITY = 6.0

var health: int:
	set(value):
		health = clamp(value, 0, 100)
		health_label.text = str(health)
		if health < 20:
			$Indicators/Health.modulate = Color(1.0, 0.25, 0.25)
		else:
			$Indicators/Health.modulate = Color.WHITE

var suit_power: int:
	set(value):
		suit_power = clamp(value, 0, 100)
		suit_power_label.text = str(suit_power)

var current_interactable: Interactable

var acceleration: float
var fall_velocity: float
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var joypad_look: Vector2
var movement: Vector2

var joypad_look_curve: float
var joypad_look_inverted_x: bool
var joypad_look_inverted_y: bool
var joypad_look_outer_threshold: float
var joypad_look_sensitivity_x: float
var joypad_look_sensitivity_y: float

var mouse_look_inverted_x: bool
var mouse_look_inverted_y: bool
var mouse_look_sensitivity: float


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	health = 10
	suit_power = 0


func _process(_delta):
	look()


func _input(event):
	if event is InputEventMouseMotion:
		var input = event.relative
		if mouse_look_inverted_x:
			input.x *= -1
		if mouse_look_inverted_y:
			input.y *= -1
		
		rotate_y(-input.x * mouse_look_sensitivity / 500)
		camera.rotate_x(-input.y * mouse_look_sensitivity / 500)


func _physics_process(delta):
	move(delta)
	interact()
	flashlight()


func flashlight():
	if Input.is_action_just_pressed("flashlight"):
		%Flashlight.visible = !%Flashlight.visible
		sound_flashlight.play()


func interact():
	var interactable := use_raycast.get_collider() as Interactable
	
	if Input.is_action_just_released("use") or interactable != current_interactable:
		if current_interactable:
			current_interactable.stop_interact()
			current_interactable = null
	
	if interactable:
		if Input.is_action_pressed("use"):
			interactable.interact(self)
			current_interactable = interactable
	elif Input.is_action_just_pressed("use"):
		sound_cannot_use.play()


func look():
	var look_input = Input.get_vector("look_left", "look_right", "look_up", "look_down")
	
	if joypad_look_inverted_x:
		look_input.x *= -1
	if joypad_look_inverted_y:
		look_input.y *= -1
	
	if abs(look_input.x) > 1 - joypad_look_outer_threshold:
		look_input.x = round(look_input.x)
	joypad_look.x = abs(look_input.x) ** joypad_look_curve * joypad_look_sensitivity_x / 10
	if look_input.x < 0:
		joypad_look.x *= -1
	
	if abs(look_input.y) > 1 - joypad_look_outer_threshold:
		look_input.y = round(look_input.y)
	joypad_look.y = abs(look_input.y) ** joypad_look_curve * joypad_look_sensitivity_y / 10
	if look_input.y < 0:
		joypad_look.y *= -1
	
	rotate_y(-joypad_look.x)
	camera.rotate_x(-joypad_look.y)
	
	# Clamp vertical camera rotation for both mouse and joypad
	camera.rotation.x = clamp(camera.rotation.x, -PI / 2, PI / 2)


func move(delta):
	# Gravity and jumping
	if is_on_floor():
		if fall_velocity < -FALL_DAMAGE_THRESHOLD:
			health += int((fall_velocity + FALL_DAMAGE_THRESHOLD) * FALL_DAMAGE_MULTIPLIER)
		fall_velocity = 0
		acceleration = GROUND_ACCELERATION
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY
	else:
		velocity.y -= gravity * delta
		fall_velocity = velocity.y
		acceleration = AIR_ACCELERATION
	
	# Crouching and sprinting
	if Input.is_action_pressed("crouch"):
		state_machine.travel("Crouch")
	elif not test_move(transform, Vector3.UP):
		if Input.is_action_pressed("sprint"):
			state_machine.travel("Sprint")
		else:
			state_machine.travel("RESET")
	
	# Get input and move with acceleration/deceleration
	var move_input = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	move_input = move_input.rotated(-rotation.y)
	movement = movement.lerp(move_input * speed, acceleration * delta)
	velocity.x = movement.x
	velocity.z = movement.y
	move_and_slide()
