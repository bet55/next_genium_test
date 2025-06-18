extends CharacterBody2D

@export var speed: float = 50
@export var gravity: float = 980
@export var patrol_path: Path2D
@export var patrol_speed: float = 50
@export var dmg: int = 1
@export var max_health: int = 3

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var detection_area: Area2D = $DetectArea
@onready var attack_area: Area2D = $AttackArea
@onready var edge_detector: RayCast2D = $EdgeDetector
@onready var hitbox_area: Area2D = $HitboxArea
@onready var collision_shape: CollisionShape2D = $CollisionShape
@onready var alarm_1: ColorRect = $Alarm1

enum State {
	PATROL,
	CHASE,
	ATTACK,
	HURT
}

var current_state = State.PATROL
var target = null
var health = max_health
var patrol_points = []
var patrol_index = 0


func _ready():
	if patrol_path:
		patrol_points = patrol_path.curve.get_baked_points()
		if patrol_points.size() > 0:
			global_position = patrol_points[0]
			enter_patrol()


# Моб сделан по аналогии с персонажам, см комменты в нем
# Выполнение состояний
func _physics_process(delta):
	match current_state:
		State.PATROL:
			patrol_state(delta)
		State.CHASE:
			chase_state(delta)
		State.ATTACK:
			attack_state(delta)
		State.HURT:
			hurt_state(delta)
	
	# Поворачиваем спрайт и зоны
	if velocity.x != 0:
		attack_area.get_child(0).position.x = abs(attack_area.get_child(0).position.x) * sign(velocity.x)
		hitbox_area.get_child(0).position.x = abs(hitbox_area.get_child(0).position.x) * -sign(velocity.x)
		collision_shape.position.x = abs(collision_shape.position.x) * -sign(velocity.x)
	
	# Всегда падаем
	velocity.y += gravity * delta
	move_and_slide()
	
	check_platform_edge()


# Блок функций поведения в состоянии
func patrol_state(delta):
	# Патруль берет точки из Path2D
	if patrol_points.size() == 0:
		return
	
	# Двигаемся всегда к следующей точке
	var target_point = patrol_points[patrol_index]
	var direction = (target_point - global_position).normalized()
	
	velocity.x = direction.x * patrol_speed
	sprite.flip_h = direction.x > 0
	
	# Зацикливаем индексы точек, после последней пойдем к первой
	if global_position.distance_to(target_point) < 5:
		patrol_index = (patrol_index + 1) % patrol_points.size()
	
	for body in detection_area.get_overlapping_bodies():
		if body.is_in_group("player"):
			target = body
			enter_chase()


func chase_state(delta):
	if not target:
		enter_patrol()
		return
	
	# Пока преследуем, двигаемся за целью
	var direction = (target.global_position - global_position).normalized()
	velocity.x = direction.x * speed
	sprite.flip_h = direction.x > 0
	
	# Если дотягиваемся ударить - бьем
	if not detection_area.get_overlapping_bodies().has(target):
		target = null
		enter_patrol()
	elif attack_area.get_overlapping_bodies().has(target):
		enter_attack()


func attack_state(delta):
	velocity.x = 0
	
	if not sprite.is_playing():
		if target:
			enter_chase()
		else:
			enter_patrol()


func hurt_state(delta):
	velocity.x = 0
	
	if not sprite.is_playing():
		if health <= 0:
			queue_free()
		elif target:
			enter_chase()
		else:
			enter_patrol()
# Блок функций поведения в состоянии


# Блок функций перехода в состояние
func enter_patrol():
	current_state = State.PATROL
	sprite.play("run")
	# Выключаем видимую отметку состояния преследования
	alarm_1.visible = false


func enter_chase():
	current_state = State.CHASE
	sprite.play("run")
	# Включаем видимую отметку состояния преследования
	alarm_1.visible = true


func enter_attack():
	current_state = State.ATTACK
	sprite.play("attack")
	target.enter_hurt(dmg)


func enter_hurt(damage: int):
	health -= damage
	current_state = State.HURT
	sprite.play("hurt")
# Блок функций перехода в состояние


# Чтобы не падать с платформ, смотрим под ноги с помощью рейкаста
func check_platform_edge():
	if current_state == State.PATROL or current_state == State.CHASE:
		if not edge_detector.is_colliding():
			velocity.x *= -1
			sprite.flip_h = not sprite.flip_h
			if current_state == State.PATROL and patrol_points.size() > 0:
				patrol_index = (patrol_index - 1) % patrol_points.size()
				if patrol_index < 0:
					patrol_index = patrol_points.size() - 1
