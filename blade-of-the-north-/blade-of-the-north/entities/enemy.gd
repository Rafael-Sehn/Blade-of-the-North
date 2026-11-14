extends CharacterBody2D
## Inimigo simples com máquina de estados: parado, perseguir e atacar.
## Cobre RF06 (comportamento) e RF08 (derrota do inimigo).

signal health_changed(current: int, max_value: int)
signal died

enum State { IDLE, CHASE, ATTACK }

const SPEED := 110.0
const DETECTION_RADIUS := 420.0
const ATTACK_RANGE := 70.0
const ATTACK_COOLDOWN := 1.0
const ATTACK_DAMAGE := 1
const KNOCKBACK_TIME := 0.2
const BASE_COLOR := Color(1.0, 0.4, 0.4)

@export var max_health := 3

var health := 0
var state: State = State.IDLE

var _attack_timer := 0.0
var _knockback_timer := 0.0
var _player: Node2D = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var bar_fill: ColorRect = $HealthBar/Fill


func _ready() -> void:
	add_to_group("enemy")
	health = max_health
	sprite.modulate = BASE_COLOR


func _physics_process(delta: float) -> void:
	_attack_timer = maxf(_attack_timer - delta, 0.0)
	_knockback_timer = maxf(_knockback_timer - delta, 0.0)

	if not is_on_floor():
		velocity += get_gravity() * delta

	if _player == null:
		_player = get_tree().get_first_node_in_group("player")

	if _knockback_timer <= 0.0:
		_update_behavior()

	move_and_slide()


func _update_behavior() -> void:
	if _player == null or _player.dead:
		state = State.IDLE
		velocity.x = 0.0
		return

	var distance := global_position.distance_to(_player.global_position)
	var direction := signf(_player.global_position.x - global_position.x)

	if distance > DETECTION_RADIUS:
		state = State.IDLE
		velocity.x = 0.0
	elif distance > ATTACK_RANGE:
		state = State.CHASE
		velocity.x = direction * SPEED
		sprite.flip_h = direction < 0.0
	else:
		state = State.ATTACK
		velocity.x = 0.0
		sprite.flip_h = direction < 0.0
		if _attack_timer <= 0.0:
			_attack_timer = ATTACK_COOLDOWN
			_player.take_damage(ATTACK_DAMAGE, global_position.x)


func take_damage(amount: int, from_x: float) -> void:
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	bar_fill.scale.x = float(health) / float(max_health)
	_knockback_timer = KNOCKBACK_TIME
	var away := 1.0 if global_position.x >= from_x else -1.0
	velocity = Vector2(away * 220.0, -180.0)
	# Efeito de clarão ao receber dano
	sprite.modulate = Color(3.0, 3.0, 3.0)
	create_tween().tween_property(sprite, "modulate", BASE_COLOR, 0.15)
	if health <= 0:
		died.emit()
		queue_free()
