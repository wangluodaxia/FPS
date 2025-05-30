extends Node3D
class_name CampaignLevel


@export var player : Player

var rag_doll_ := load("res://Characters/RagDoll.tscn")
var shot_trail_ := load("res://Props/ShotTrail.tscn")
var bullet_hole_ := load("res://Props/BulletHole.tscn")
var grenade_ := load("res://Props/Weapons/Grenade/Grenade.tscn")
var explosion_ := load("res://Props/Weapons/Grenade/Explosion.tscn")
var damage_label_ := load("res://Maps/Utilities/DamageLabel.tscn")
var weapon_pick_up_ := load("res://Props/PickUps/WeaponPickUp.tscn")

var enemy_ := load("res://Characters/Campaign/CampaignEnemy.tscn")


func _ready() -> void:
	Debug.player = player
	HUD.setup_single_player()


func open() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	Engine.time_scale = 1.0
	$MusicPlayer.play()
	await HUD.fade_in()
	
	for char in $Players.get_children():
		char.set_processing(true)


# Called by LevelFinish.level_finished()
func level_finished() -> void:
	var post_time := 2.0
	var timer = get_tree().create_timer(post_time, false, false, true)
	HUD.fade_out()
	var tween = create_tween().set_parallel()
	tween.tween_property(Engine, "time_scale", 0.1, post_time)
	#tween.tween_property($FX/FadeLayer/FadeInOut, "color:a", 1.2, post_time)
	await tween.finished
	
	Globals.game.quit_single_player()


func end_game() -> void:
	for char in $Players.get_children():
		char.set_processing(false)


func spawn_shot_trail(nozzle_point, collision_point) -> void:
	var shot_trail = shot_trail_.instantiate()
	$FX.add_child(shot_trail)
	shot_trail.align_and_scale(nozzle_point, collision_point)


func spawn_bullet_hole(pos : Vector3, normal : Vector3, \
												parent : Node3D = $FX) -> void:
	var bullet_hole : Decal = bullet_hole_.instantiate()
	parent.add_child(bullet_hole)
	bullet_hole.global_position = pos
	bullet_hole.project_to(normal)


func spawn_grenade(thrower, spawn_basis : Basis, spawn_point : Vector3, \
								spawn_dir : Vector3, throw_strength : float) -> void:
	var grenade = grenade_.instantiate()
	grenade.thrower = thrower
	$FX.add_child(grenade)
	grenade.global_position = spawn_point
	grenade.global_basis = spawn_basis
	grenade.global_basis = grenade.global_basis.looking_at(spawn_dir)
	
	grenade.apply_central_impulse(-grenade.global_basis.z * throw_strength)


func spawn_explosion(thrower : CharacterBase, spawn_pos : Vector3) -> void:
	var explosion = explosion_.instantiate()
	$FX.add_child(explosion)
	explosion.thrower = thrower
	explosion.global_position = spawn_pos


func spawn_damage_label(damage : Damage, pos : Vector3) -> void:
	var damage_label = damage_label_.instantiate()
	$FX.add_child(damage_label)
	var color : Color
	match damage.body_seg_damaged.body_seg:
		Globals.BODY_SEGS.HEAD:
			color = Color.GOLD
		_:
			color = Color.BROWN
	damage_label.set_txt_pos_color(pos, str(damage.damage_amount), color)


# Called from CharacterBase.die()
func spawn_rag_doll(dead_skel : Skeleton3D, dead_trans : Transform3D, \
						damage : Damage, body_mat : BaseMaterial3D, \
									death_sfx : AudioStreamPlayer3D) -> void:
	var rag_doll = rag_doll_.instantiate()
	$FX.add_child(rag_doll)
	rag_doll.set_death_sfx(death_sfx)
	rag_doll.set_material(body_mat)
	await rag_doll.match_pose_transform(dead_skel, dead_trans)
	rag_doll.add_impulse(damage)
	return


func spawn_weapon_pick_up(dropped_position : Vector3, weapon_info : Array) -> void:
	var new_pick_up = weapon_pick_up_.instantiate()
	$Pickups.add_child(new_pick_up)
	new_pick_up.set_up_drop(dropped_position, weapon_info)


# Signaled by KillArea.body_exited
func character_out_of_bounds(body : Node3D) -> void:
	if body == player:
		HUD.update_health(player.MAX_HEALTH, player.MAX_ARMOR, player.MAX_HEALTH, 0)
		Globals.game.reset_single_player()
		return
		body.queue_free()
	elif body is CharacterBase:
		body.defeated.emit()
		body.queue_free()
