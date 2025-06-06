@tool
extends PickUp


var pistol_ := load("res://Props/Weapons/Pistol/PistolBase.tscn")
var smg_ := load("res://Props/Weapons/SMG/SMGBase.tscn")
var rifle_ := load("res://Props/Weapons/Rifle/RifleBase.tscn")
var shotgun_ := load("res://Props/Weapons/Shotgun/ShotgunBase.tscn")
var sniper_ := load("res://Props/Weapons/Sniper/SniperBase.tscn")
var grenade_ := load("res://Props/Weapons/Grenade/GrenadeBase.tscn")

@export var weapon_type : Globals.WEAPONS : set = _set_model
@onready var weapon_model := get_child(0)
var weapon_info := []

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var rotate_rate := 2.0


func _process(delta) -> void:
	$Model.rotate_y(rotate_rate * delta)


func _set_model(new_weapon_type) -> void:
	weapon_type = new_weapon_type
	match weapon_type:
		Globals.WEAPONS.SLAPPER:
			weapon_type = Globals.WEAPONS.PISTOL
		Globals.WEAPONS.PISTOL:
			weapon_model = pistol_.instantiate()
		Globals.WEAPONS.SMG:
			weapon_model = smg_.instantiate()
		Globals.WEAPONS.RIFLE:
			weapon_model = rifle_.instantiate()
		Globals.WEAPONS.SHOTGUN:
			weapon_model = shotgun_.instantiate()
		Globals.WEAPONS.SNIPER:
			weapon_model = sniper_.instantiate()
		Globals.WEAPONS.GRENADE:
			weapon_model = grenade_.instantiate()
			
	if $Model.get_child_count() > 0:
		$Model.get_child(0).replace_by(weapon_model)


func picked_up() -> void:
	super()
	if weapon_info.size() > 0:
		await $PickUpAudio.finished
		queue_free()


func set_up_drop(new_pos, new_weapon_info) -> void:
	weapon_type = new_weapon_info[0]
	weapon_info = new_weapon_info
	
	global_position = new_pos
	$FloorSnap.force_raycast_update()
	global_position.y = $FloorSnap.get_collision_point().y + 0.25
	
	match weapon_info[0]:
		Globals.WEAPONS.PISTOL:
			name = "PistolPickUp"
		Globals.WEAPONS.SMG:
			name = "SMGPickUp"
		Globals.WEAPONS.RIFLE:
			name = "RiflePickUp"
		Globals.WEAPONS.SHOTGUN:
			name = "ShotgunPickUp"
		Globals.WEAPONS.SNIPER:
			name = "SniperPickUp"
		Globals.WEAPONS.GRENADE:
			name = "GrenadePickUp"
	$Despawn.start()


func despawn() -> void:
	#print(name, " despawned")
	queue_free()
