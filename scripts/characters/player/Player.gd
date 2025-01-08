extends Entity
class_name Player


@onready var state_chart: StateChart = $StateChart
@onready var hurt_box: Hurtbox = $Hurtbox
@onready var weapon_node: Node2D = $Weapon
@onready var body_texture: Node2D = $Texture/Body
@onready var interaction_icon: AnimatedSprite2D = $InteractionIcon
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hurt_effect_player: AnimationPlayer = $HurtEffectPlayer
@onready var endurance_recover_timer: Timer = $EnduranceRecoverTimer
@onready var end_recover_ready_timer: Timer = $EndRecoverReadyTimer
@onready var hurt_effect_timer: Timer = $HurtEffectTimer
@onready var run_endurance_consume_timer: Timer = $RunEnduranceConsumeTimer
@onready var camera: Camera2D = $Camera2D

@export var interactable_with: Array[Interactable]
@export var direction: Vector2 = Vector2.ZERO
@export var knockback_power: int = 3000
@export var move_speed_multiple: float = 1.0
@export var current_move_speed: int
@export var current_endurance: int
@export var endurance_recover_amount: int = 10
@export var endurance_recover_ready: int = 1
@export var endurance_recover_speed: float = 0.2
@export var endurance_recover_ready_speed: float = 0.5

@export var is_dead: bool = false
@export var is_hurt: bool = false
@export var is_idle: bool = false
@export var is_walk: bool = false
@export var is_run: bool = false
@export var is_weapon_attack: bool = false

@export var is_endurance_disable: bool = false
@export var is_flip: bool = false
@export var is_weapon_flip: bool = false
@export var is_resist: bool = false


func _ready():
	super()
	if GlobalPlayerState.player_classes:
		body_texture.texture = load(FileFunction.get_file_list("res://texture/characters/player/").get(GlobalPlayerState.player_classes))
	if GlobalPlayerState.player_weapon:
		weapon_node.add_child(load(Global.weapon_data.get(GlobalPlayerState.player_weapon).path).instantiate())
	
	GlobalPlayerState.player = self
	current_health = GlobalPlayerState.player_current_health
	current_endurance = GlobalPlayerState.player_current_endurance
	current_move_speed = GlobalPlayerState.player_move_speed
	endurance_recover_timer.wait_time = endurance_recover_speed
	end_recover_ready_timer.wait_time = endurance_recover_ready_speed
	
	GlobalPlayerState.weapon_update.emit()
	GlobalPlayerState.health_changed.emit()
	GlobalPlayerState.endurance_changed.emit()

func _process(_delta):
	if is_dead: return
	
	move_and_slide()
	get_move_direction()
	
	update_state()
	update_animation()
	
	headle_endurance()
	
	weapon_node.weapon_transform()
	weapon_node.weapon_special_attack()

func dead_handle():
	state_chart.send_event("dead")

func hurt_handle():
	state_chart.send_event("hurt")


func update_state():
	var is_still = velocity == Vector2.ZERO
	var shift: bool = false
	
	if Input.is_action_pressed("shift"):
		if shift:
			shift = false
		else:
			shift = true
	
	if !is_idle && is_still:
		state_chart.send_event("idle")
	
	if !is_still:
		if !is_walk && !is_still && !shift:
			state_chart.send_event("walk")
		elif !is_run && !is_still && shift && current_endurance > 0:
			state_chart.send_event("run")
	
	if Input.is_action_just_pressed("attack"):
		state_chart.send_event("weapon_attack")
	
	if Input.is_action_just_pressed("interaction") && interactable_with:
		interactable_with.back().interaction()
#更新状态
#受伤状态由 $HurtBox 发起

func register_interactable(object: Interactable):
	if object in interactable_with:
		return
	interactable_with.append(object)

func unregister_interactable(object: Interactable):
	interactable_with.erase(object)

func update_animation():
	interaction_icon.visible = !interactable_with.is_empty()
	
	var m = get_local_mouse_position()
	if m.x < 0:
		is_weapon_flip = true
		body_texture.flip_h = true
	else:
		is_weapon_flip = false
		body_texture.flip_h = false
	
	if m.y < 0: is_flip = true
	else: is_flip = false
	
	animation_tree["parameters/AnimationNodeStateMachine/idle/blend_position"] = m
	animation_tree["parameters/AnimationNodeStateMachine/walk/blend_position"] = m
	#纹理朝向和渲染索引

func headle_endurance():
	if (
		velocity == Vector2.ZERO && 
		!is_weapon_attack && 
		!is_resist &&
		current_endurance < GlobalPlayerState.player_max_endurance
		):
			is_endurance_disable = false
	
	if is_endurance_disable:
		end_recover_ready_timer.start()
	
	if current_endurance < 0:
		current_endurance = 0
	if current_endurance > GlobalPlayerState.player_max_endurance:
		current_endurance = GlobalPlayerState.player_max_endurance
		is_endurance_disable = true
	else:
		endurance_recover()
#处理耐力

func endurance_recover():
	if (
		end_recover_ready_timer.is_stopped() &&
		endurance_recover_timer.is_stopped()
		):
			if current_endurance <= GlobalPlayerState.player_max_endurance - endurance_recover_amount:
				endurance_recover_timer.start()
				await endurance_recover_timer.timeout
				
				current_endurance += endurance_recover_amount
				GlobalPlayerState.player_current_endurance = current_endurance
				GlobalPlayerState.endurance_changed.emit()
				print("current_endurance: ", current_endurance)
				endurance_recover()
			elif current_endurance != GlobalPlayerState.player_max_endurance:
				current_endurance = GlobalPlayerState.player_max_endurance
				GlobalPlayerState.player_current_endurance = current_endurance
				GlobalPlayerState.endurance_changed.emit()
				print("current_endurance: ", current_endurance)

func get_move_direction():
	direction = Input.get_vector("left", "right", "up", "down").normalized()
	if direction:
		velocity = direction * compute_move_speed()
	else:
		velocity = Vector2.ZERO
#移动

func compute_move_speed() -> float:
	return current_move_speed * move_speed_multiple
#计算最终速度

func knockback(enemy_velocity : Vector2):
	var knockback_direction = (enemy_velocity - velocity).normalized() * knockback_power
	velocity = knockback_direction
	move_and_slide()

func run_endurance_consume():
	if !is_run || current_endurance <= 0:
		state_chart.send_event("walk")
		return
	elif run_endurance_consume_timer.is_stopped():
		current_endurance -= 1
		GlobalPlayerState.player_current_endurance = current_endurance
		GlobalPlayerState.endurance_changed.emit()
		is_endurance_disable = true
		run_endurance_consume_timer.start()
		await run_endurance_consume_timer.timeout
		
		run_endurance_consume()


func _on_hurt_box_area_entered(area):
	if area.has_method("collect"):
		area.collect(GlobalPlayerState.player_card_inventory)
	
	print(name, " pickup: ", area.name, " => ", area)
#拾取物品


func _on_idle_state_entered() -> void:
	is_idle = true
	print(name, " state: idle")
	animation_tree["parameters/AnimationNodeStateMachine/conditions/is_idle"] = true
	animation_tree["parameters/AnimationNodeStateMachine/conditions/is_walk"] = false
	


func _on_idle_state_exited() -> void:
	is_idle = false


func _on_walk_stack_state_entered() -> void:
	animation_tree["parameters/AnimationNodeStateMachine/conditions/is_idle"] = false
	animation_tree["parameters/AnimationNodeStateMachine/conditions/is_walk"] = true
	#SoundManager.play_sfx("aa")


func _on_walk_state_entered() -> void:
	if !is_walk:
		is_walk = true
		print(name, " state: walk.walk")


func _on_walk_state_exited() -> void:
	is_walk = false


func _on_run_state_entered() -> void:
	if !is_run:
		is_run = true
		print(name, " state: walk.run")
	move_speed_multiple = GlobalPlayerState.player_run_move_speed_multiple
	GlobalPlayerState.player_current_move_speed_multiple = move_speed_multiple
	animation_tree["parameters/TimeScale/scale"] = move_speed_multiple
	run_endurance_consume()


func _on_run_state_exited() -> void:
	is_run = false
	move_speed_multiple = GlobalPlayerState.player_walk_move_speed_multiple
	GlobalPlayerState.player_current_move_speed_multiple = move_speed_multiple
	animation_tree["parameters/TimeScale/scale"] = move_speed_multiple


func _on_hurt_state_entered() -> void:
	is_hurt = true
	print(name, " state: hurt")
	GlobalPlayerState.player_current_health = current_health
	GlobalPlayerState.health_changed.emit()
	hurt_effect_player.play("hurt_blink")
	hurt_effect_timer.start()
	await hurt_effect_timer.timeout
	
	hurt_effect_player.play("RESET")


func _on_hurt_state_exited() -> void:
	is_hurt = false


func _on_dead_state_entered() -> void:
	if !is_dead:
		is_dead = true
		print(name, " state: dead")
		GlobalPlayerState.player_dead.emit()


func _on_weapon_attack_state_entered() -> void:
	print(name, " state: weapon_attack")
	weapon_node.weapon_attack()
#res://scripts/characters/player/weapon.gd
