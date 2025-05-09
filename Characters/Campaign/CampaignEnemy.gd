extends CharacterBase


@onready var state_machine := $StateMachine
@onready var nav_agent := $NavAgent
@export var guard_path : Node3D

var target : CharacterBase = null
var target_seek_time = 8.0
var enemies_vis : Array[bool] = []
var alert := false
var damage_mod := 1.5

@export var starting_weapon : Globals.WEAPONS
var shoot_speed_mod := 1.0/2.5
var shoot_speed_variance := Vector2(0.3, 1.0)

const GUARD_SPEED := 3.0
const TURN_SPEED := 6.0
const AIM_SPEED := 1.0
var move_speed_mod := 0.8

var update_interval := 10
var update_offset := randi_range(0, update_interval-1)


func _ready() -> void:
	super()
	
	enemies_vis.resize(enemies.size())
	enemies_vis.fill(false)
	
	add_weapon(Globals.weapons[starting_weapon].instantiate())
	
	state_machine.set_physics_process(false)
	await NavigationServer3D.map_changed
	state_machine.set_physics_process(true)


func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("EmoteWave"):
		anim_tree["parameters/Wave/request"] = \
									AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE


func _process(delta: float) -> void:
	super(delta)


func _physics_process(delta):
	super(delta)


func guard(delta) -> void:
	if !guard_path:
		return
	if guard_path is Path3D:
		nav_agent.target_position = guard_path.path_follow.global_position
	else:
		nav_agent.target_position = guard_path.global_position
	var next_path_pos : Vector3 = nav_agent.get_next_path_position()
	next_path_pos.y = global_position.y
	
	var new_transform : Transform3D
	if nav_agent.is_navigation_finished() and !(guard_path is Path3D):
		new_transform = guard_path.transform
		transform = transform.interpolate_with(new_transform, TURN_SPEED * delta)
		#if is_on_floor():
			#return
	elif !global_position.is_equal_approx(next_path_pos):
		new_transform = transform.looking_at(next_path_pos)
		transform = transform.interpolate_with(new_transform, TURN_SPEED * delta)

	# Move
	var input_dir := Vector2.ZERO
	if !nav_agent.is_navigation_finished():
		input_dir = Vector2.UP
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var tween := create_tween().set_parallel()
	var weapon_blend_pos : String = "parameters/Upper/" + \
			Globals.WEAPON_NAMES[weapon_held.weapon_type] + "/Guard/blend_position"
	if direction:
		speed = GUARD_SPEED
		var dir2 := Vector2(input_dir.x, (GUARD_SPEED / FORE_SPEED) * input_dir.y)
		tween.tween_property(anim_tree, lower_blend_pos, dir2, 0.1)
		tween.tween_property(anim_tree, weapon_blend_pos, 1, 0.1)
		
		velocity.x = move_toward(velocity.x, direction.x * speed, accel * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, accel * delta)
	else:
		tween.tween_property(anim_tree, lower_blend_pos, Vector2.ZERO, 0.1)
		tween.tween_property(anim_tree, weapon_blend_pos, -1, 0.1)
		
		velocity.x = move_toward(velocity.x, 0, deaccel * delta)
		velocity.z = move_toward(velocity.z, 0, deaccel * delta)
	velocity.x *= move_speed_mod
	velocity.z *= move_speed_mod
	
	move_and_slide()


func aim(delta) -> void:
	if target and enemies_vis[enemies.find(target)]:
		var target_pos = target.global_position + Vector3(0, 1.2, 0)
		var new_trans : Transform3D = $AimHelper.global_transform.looking_at(target_pos)
		$AimHelper.global_transform = $AimHelper.global_transform.interpolate_with \
													(new_trans, AIM_SPEED * delta)
	else:
		$AimHelper.rotation = $AimHelper.rotation.lerp(Vector3.ZERO, AIM_SPEED * delta)
	$AimHelper.rotation.x = clamp($AimHelper.rotation.x, deg_to_rad(-90), rad_to_deg(90))
	$AimHelper.rotation.y = clamp($AimHelper.rotation.y, deg_to_rad(-80), rad_to_deg(80))
	$AimHelper.rotation.z = 0


func move_to_target(delta) -> void:
	if !target:
		return
	if is_enemy_visible(target) and $ShootTimer.is_stopped():
		trigger_pulled = true
	
	# Start timer to switch to GuardState if no target visible
	if !is_enemy_visible(target) and $TargetTimer.is_stopped() and !alert:
		$TargetTimer.start(target_seek_time)
	
	# Set the desired destination
	var next_path_pos := Vector3.ZERO
	nav_agent.target_position = target.global_position
	next_path_pos = nav_agent.get_next_path_position()
	next_path_pos.y = global_position.y
	
	# Set Input_dir based on direction to next_path_pos
	var input_dir := Vector2.ZERO
	var range = Vector2(.75, 1.0)
	if weapon_held.weapon_type != Globals.WEAPONS.SLAPPER:
		range = Vector2(weapon_held.properties.dmg_falloff[0] / 2, \
										weapon_held.properties.dmg_falloff[1] / 4)
	var dist_to = global_position.distance_to(target.global_position)
	if ((dist_to > range[1]) and is_enemy_visible(target)) or \
														!is_enemy_visible(target):
		input_dir = Vector2.UP
	elif dist_to < range[0] and is_enemy_visible(target):
		input_dir = Vector2.DOWN
	
	# Turn to look at the target
	var new_transform : Transform3D
	#if transform.origin.is_equal_approx(next_path_pos):
		#breakpoint
	new_transform = transform.looking_at(next_path_pos)
	transform = transform.interpolate_with(new_transform, TURN_SPEED * delta)

	# Move
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var tween = create_tween()
	var weapon_blend_pos : String = "parameters/Upper/" + \
			Globals.WEAPON_NAMES[weapon_held.weapon_type] + "/Alert/blend_position"
	_set_speed(input_dir)
	if direction:
		tween.tween_property(anim_tree, lower_blend_pos, input_dir, 0.1)
		tween.tween_property(anim_tree, weapon_blend_pos, 1, 0.1)
		
		velocity.x = move_toward(velocity.x, direction.x * speed, accel * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, accel * delta)
	else:
		tween.tween_property(anim_tree, lower_blend_pos, Vector2.ZERO, 0.1)
		tween.tween_property(anim_tree, weapon_blend_pos, -1, 0.1)
		
		velocity.x = move_toward(velocity.x, 0, deaccel * delta)
		velocity.z = move_toward(velocity.z, 0, deaccel * delta)
	velocity.x *= move_speed_mod
	velocity.z *= move_speed_mod
	
	move_and_slide()


func target_lost() -> void:
	target = null


func check_enemies_visible() -> bool:
	%TargetCast.target_position = Vector3.FORWARD
	enemies_vis.fill(false)
	var bodies = %VisionCone.get_bodies()
	for body in bodies:
		if enemies.has(body):
			%TargetCast.target_position = %TargetCast.to_local(\
										body.global_position + (Vector3.UP*1.5))
			%TargetCast.force_raycast_update()
			if %TargetCast.is_colliding() and %TargetCast.get_collider() == body:
				enemies_vis[enemies.find(body)] = true
	if enemies_vis.has(true):
		$TargetTimer.stop()
	return enemies_vis.has(true)


func set_closest_to_target() -> void:
	if enemies.size() == 0:
		return
		
	target = enemies[0]
	var dist = global_position.distance_squared_to(target.global_position)
	for enemy in enemies:
		if enemy == target:
			continue
		var temp_dist = global_position.distance_squared_to(enemy.global_position)
		if temp_dist < dist:
			target = enemy
			dist = temp_dist


func is_enemy_visible(enemy) -> bool:
	return enemies.has(enemy) and enemies_vis[enemies.find(enemy)]


func _fire() -> void:
	super()
	trigger_pulled = false
	var speed_variance := randf_range(shoot_speed_variance.x , shoot_speed_variance.y)
	var shoot_speed := 0.25 * speed_variance
	if weapon_held.weapon_type != Globals.WEAPONS.SLAPPER:
		shoot_speed = weapon_held.properties.shots_per_second * \
												shoot_speed_mod * speed_variance
	$ShootTimer.start(1.0 / shoot_speed)


func _swing() -> void:
	slap()


func _jump() -> void:
	velocity.y = JUMP_VELOCITY


func take_damage(damage : Damage) -> void:
	if state_machine.current_state.name == "GuardState" and \
									state_machine.current_state.active == true:
		damage.damage_amount *= damage_mod
		target = damage.attacker
		state_machine.current_state.alert()
	super(damage)


func die() -> void:
	target_lost()
	if weapon_held.weapon_type != Globals.WEAPONS.SLAPPER:
		var weapon_info := [weapon_held.weapon_type,
								weapon_held.extra_ammo,
								weapon_held.ammo_in_mag]
		current_level.spawn_weapon_pick_up(global_position, weapon_info)
	
	# Connected to EnemySpawner
	defeated.emit(self)
	await super()
	queue_free.call_deferred()


func _unequip_weapon(old_weapon) -> void:
	if old_weapon == null:
		return
	old_weapon.visible = false


func _equip_weapon(new_weapon) -> void:
	new_weapon.visible = true
