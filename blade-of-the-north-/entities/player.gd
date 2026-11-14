extends CharacterBody2D
## Jogador: movimento, salto, ataque e vida.
## Cobre RF02 (mover), RF03 (saltar), RF04 (atacar), RF05 (vida) e RF09 (derrota).

signal health_changed(current: int, max_value: int)
signal died

const SPEED := 300.0
const JUMP_VELOCITY := -480.0
const ATTACK_DURATION := 0.15   # tempo em que a área de ataque causa dano
const ATTACK_COOLDOWN := 0.35   # intervalo mínimo entre ataques
const ATTACK_DAMAGE := 1
const ATTACK_OFFSET := 52.0     # distância da área de ataque até o jogador
const INVULNERABLE_TIME := 0.8  # proteção após levar dano
const KNOCKBACK_TIME := 0.2

@export var max_health := 5

var health := 0
var facing := 1                 # 1 = direita, -1 = esquerda
var dead := false

var _attack_timer := 0.0
var _cooldown_timer := 0.0
var _invulnerable_timer := 0.0
var _knockback_timer := 0.0
var _hit_this_swing: Array = []

@onready var sprite: Sprite2D = $Sprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var attack_visual: ColorRect = $AttackArea/AttackVisual


func _ready() -> void:
	add_to_group("player")
	health = max_health
	attack_visual.hide()


func _physics_process(delta: float) -> void:
	_cooldown_timer = maxf(_cooldown_timer - delta, 0.0)
	_invulnerable_timer = maxf(_invulnerable_timer - delta, 0.0)
	_knockback_timer = maxf(_knockback_timer - delta, 0.0)

	# Gravidade
	if not is_on_floor():
		velocity += get_gravity() * delta

	if dead:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
	elif _knockback_timer <= 0.0:
		# Salto (RF03)
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
		# Movimento horizontal (RF02)
		var direction := Input.get_axis("move_left", "move_right")
		if direction != 0.0:
			velocity.x = direction * SPEED
			facing = 1 if direction > 0.0 else -1
		else:
			velocity.x = move_toward(velocity.x, 0.0, SPEED)
		# Ataque (RF04)
		if Input.is_action_just_pressed("attack") and _cooldown_timer <= 0.0:
			_start_attack()

	move_and_slide()
	_update_attack(delta)
	_update_visuals()


func _start_attack() -> void:
	_attack_timer = ATTACK_DURATION
	_cooldown_timer = ATTACK_COOLDOWN
	_hit_this_swing.clear()
	attack_visual.show()


func _update_attack(delta: float) -> void:
	attack_area.position.x = ATTACK_OFFSET * facing
	if _attack_timer <= 0.0:
		return
	_attack_timer -= delta
	# O dano é aplicado uma única vez por inimigo em cada golpe.
	for body in attack_area.get_overlapping_bodies():
		if body.is_in_group("enemy") and not _hit_this_swing.has(body):
			_hit_this_swing.append(body)
			body.take_damage(ATTACK_DAMAGE, global_position.x)
	if _attack_timer <= 0.0:
		attack_visual.hide()


func _update_visuals() -> void:
	sprite.flip_h = facing < 0
	var blink := _invulnerable_timer > 0.0 and int(_invulnerable_timer * 20.0) % 2 == 0
	sprite.modulate.a = 0.35 if blink else 1.0
	if dead:
		sprite.modulate = Color(0.4, 0.4, 0.4, 1.0)


func take_damage(amount: int, from_x: float) -> void:
	if dead or _invulnerable_timer > 0.0:
		return
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	_invulnerable_timer = INVULNERABLE_TIME
	_knockback_timer = KNOCKBACK_TIME
	var away := 1.0 if global_position.x >= from_x else -1.0
	velocity = Vector2(away * 260.0, -220.0)
	if health <= 0:
		dead = true
		attack_visual.hide()
		died.emit()
