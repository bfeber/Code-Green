extends Node3D

class_name Weapon


@export var hit_range := 3.0

@onready var animation_player := $Model/AnimationPlayer as AnimationPlayer
@onready var cooldown := $Cooldown as Timer
@onready var sound_hit_concrete := $SoundHitConcrete as AudioStreamPlayer3D
@onready var sound_hit_metal := $SoundHitMetal as AudioStreamPlayer3D
@onready var sound_hit_wood := $SoundHitWood as AudioStreamPlayer3D
@onready var weapon_raycast := get_parent() as RayCast3D

const bullet_hole = preload("res://weapons/decals/bullet_hole.tscn")


func _ready():
	connect("visibility_changed", draw_weapon)
	animation_player.connect("animation_finished", play_idle)


func hit():
	var node := weapon_raycast.get_collider() as Node3D
	if node:
		if node.is_in_group("MetalMaterial"):
			sound_hit_metal.position = weapon_raycast.get_collision_point()
			sound_hit_metal.play()
		elif node.is_in_group("WoodMaterial"):
			sound_hit_wood.position = weapon_raycast.get_collision_point()
			sound_hit_wood.play()
		else:
			sound_hit_concrete.position = weapon_raycast.get_collision_point()
			sound_hit_concrete.play()
		var bullet_hole_instance = bullet_hole.instantiate()
		get_tree().get_root().add_child(bullet_hole_instance)
		bullet_hole_instance.position = weapon_raycast.get_collision_point()


func draw_weapon():
	weapon_raycast.target_position = Vector3.FORWARD * hit_range
	if visible:
		animation_player.play("draw")
	else:
		animation_player.play("holster")
		animation_player.advance(100)


func play_idle(anim_name: String):
	if anim_name != "holster":
		animation_player.play("idle01")
