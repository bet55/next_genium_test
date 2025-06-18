extends CharacterBody2D

@export var speed: float = 200
@export var gravity: float = 980
@export var jump_velocity: float = -320
@export var dmg: int = 1
@export var max_health: int = 10

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var attack_area: Area2D = $AttackArea
@onready var hitbox_area: Area2D = $HitboxArea
@onready var collision_shape: CollisionShape2D = $CollisionShape


enum State {
	IDLE,
	RUN,
	JUMP,
	ATTACK,
	HURT
}

var current_state = State.IDLE
var move_direction = 0
var health = max_health

var is_facing_right = true

signal hp_changed
signal player_died


func _ready() -> void:
	GloabalLinks.player = self


# используем стейт машину, код персонажа будет состоять из 3 блоков
# 1. Выполнение состояния
# 2. Функции, описывающие поведение в каждом состоянии
# 3. Функции переходов между состояниями
# За тригеры переходов будут отвечать функции поведния в состоянии

# Выполнение состояний
func _physics_process(delta):
	match current_state:
		State.IDLE:
			idle_state(delta)
		State.RUN:
			run_state(delta)
		State.JUMP:
			jump_state(delta)
		State.ATTACK:
			attack_state(delta)
		State.HURT:
			hurt_state(delta)
		
	move_direction = Input.get_axis("left", "right")
	
	# Поворачиваем спрайты и зоны
	if move_direction != 0:
		sprite.flip_h = move_direction < 0
		attack_area.get_child(0).position.x = abs(attack_area.get_child(0).position.x) * sign(move_direction)
		hitbox_area.get_child(0).position.x = abs(hitbox_area.get_child(0).position.x) * -sign(move_direction)
		collision_shape.position.x = abs(collision_shape.position.x) * -sign(move_direction)
	
	# Двигаемся во всех состояниях, тк хотелось сделать подвижного и свободного чара
	velocity.y += gravity * delta
	velocity.x = move_direction * speed
	move_and_slide()


# Блок функций поведения в состоянии
func idle_state(delta):
	if Input.is_action_just_pressed("jump"):
		enter_jump()
	elif not is_on_floor():
		enter_jump(true)
	elif Input.is_action_just_pressed("attack"):
		enter_attack()
	elif Input.is_action_pressed("left") or Input.is_action_pressed("right"):
		enter_run()


func run_state(delta):
	move_direction = Input.get_axis("left", "right")
	
	if Input.is_action_just_pressed("jump"):
		enter_jump()
	elif Input.is_action_just_pressed("attack"):
		enter_attack()
	elif move_direction == 0:
		enter_idle()
	elif not is_on_floor():
		enter_jump(true)


func jump_state(delta):
	if Input.is_action_just_pressed("attack"):
		enter_attack()
	
	if is_on_floor() and velocity.y >= 0:
		enter_idle()


func attack_state(delta):
	if not sprite.is_playing():
		enter_idle()


func hurt_state(delta):
	if not sprite.is_playing():
		enter_idle()
# Блок функций поведения в состоянии


# Блок функций перехода в состояние
func enter_idle():
	current_state = State.IDLE
	sprite.play("idle")


func enter_run():
	current_state = State.RUN
	sprite.play("run")


func enter_jump(is_falling: bool = false):
	# Ограничиваемся одинарным прыжком и добавляем скорости по вертикали для прыжка
	if current_state != State.JUMP:
		current_state = State.JUMP
		if not is_falling:
			sprite.play("jump")
			velocity.y = jump_velocity
			velocity.x = move_direction * speed


func enter_attack():
	current_state = State.ATTACK
	sprite.play("attack")
	# Бьем всех перед собой (получится аое)
	for area in attack_area.get_overlapping_areas():
		if area.get_parent().is_in_group("mob"):
			area.get_parent().enter_hurt(dmg)


func enter_hurt(dmg):
	current_state = State.HURT
	sprite.play("hurt")
	# При получении урона оповещаем хп бар, при смерти оповещаем уровень
	hp_changed.emit(dmg)
	health -= dmg
	if health <= 0:
		health = 0
		player_died.emit()
		queue_free()
# Блок функций перехода в состояние


# Получаем урон от касания с мобом
func _on_hitbox_area_area_entered(area: Area2D) -> void:
	if area.get_parent().is_in_group("mob"):
		enter_hurt(area.get_parent().dmg)
