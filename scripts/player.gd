extends CharacterBody2D

@onready var jump_sound: AudioStreamPlayer = $AudioStreamPlayer
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var doublejump_sound: AudioStreamPlayer = $AudioStreamPlayer2
@onready var dash_sound: AudioStreamPlayer = $AudioStreamPlayer3

# --- HAREKET DEĞİŞKENLERİ ---
const SPEED = 350.0
const JUMP_VELOCITY = -320.0
const GRAVITY_WALL = 120.0
const WALL_JUMP_PUSHBACK = 300.0
const WALL_JUMP_LOCK_TIME = 0.12

# --- DASH DEĞİŞKENLERİ ---
const DASH_SPEED = 900.0
const DASH_DURATION = 0.10
const DASH_COOLDOWN = 0.7

var is_dashing = false
var dash_timer = 0.0
var can_dash = true
var dash_direction = 0

var dash_cooldown_timer = 0.0 # YENİ: Anlık geri sayım sayacı

var jump_count = 0
var wall_jump_lock := 0.0

func _physics_process(delta: float) -> void:
	
	# --- COOLDOWN SAYACI (YENİ) ---
	# Eğer bekleme süresi varsa, süreyi azalt
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

	# --- DASH MEKANİĞİ ---
	if is_dashing:
		dash_timer -= delta
		
		animated_sprite_2d.play("dash")
		dash_sound.play()
		
		if dash_timer <= 0:
			is_dashing = false
			velocity.x = move_toward(velocity.x, 0, SPEED)
		else:
			velocity.y = 0
			velocity.x = dash_direction * DASH_SPEED
			move_and_slide()
			return 

	# --- NORMAL FİZİKLER ---

	# Yere veya duvara değince "Havada Dash Hakkı"nı geri ver
	# (Ama cooldown süresi bitmeden yine de atamazsın)
	if is_on_floor() or is_on_wall():
		can_dash = true
		jump_count = 0 
	
	if not is_on_floor():
		velocity += get_gravity() * delta

	if wall_jump_lock > 0:
		wall_jump_lock -= delta

	# --- INPUT ---
	
	# DASH INPUT (GÜNCELLENDİ)
	# Dash atmak için 3 şart lazım:
	# 1. Tuşa basıldı mı?
	# 2. Havada hakkımız var mı? (can_dash)
	# 3. Bekleme süresi bitti mi? (dash_cooldown_timer <= 0)
	if Input.is_action_just_pressed("dash") and can_dash and dash_cooldown_timer <= 0:
		start_dash()
		

	# JUMP INPUT
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			jump_count = 1
			jump_sound.play(0.01)
			velocity.y = JUMP_VELOCITY

		elif is_on_wall() and wall_jump_lock <= 0:
			var wall_normal := get_wall_normal()
			jump_sound.play(0.01)
			velocity.y = JUMP_VELOCITY
			velocity.x = wall_normal.x * WALL_JUMP_PUSHBACK
			wall_jump_lock = WALL_JUMP_LOCK_TIME
			jump_count = 1 

		elif jump_count < 2:
			jump_count += 1
			doublejump_sound.play(0.01)
			velocity.y = JUMP_VELOCITY

	# WALL SLIDE
	if is_on_wall() and velocity.y > 0:
		velocity.y = min(velocity.y, GRAVITY_WALL)

	# HORIZONTAL MOVEMENT
	var direction := Input.get_axis("left", "right")
	
	if wall_jump_lock <= 0:
		if direction:
			velocity.x = direction * SPEED
			animated_sprite_2d.flip_h = direction < 0
			if is_on_floor():
				animated_sprite_2d.play("run")
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			if is_on_floor():
				animated_sprite_2d.play("idle")

	# AIR ANIMATION
	if not is_on_floor():
		animated_sprite_2d.play("jump")

	# Hız Sınırlama
	velocity.x = clamp(velocity.x, -DASH_SPEED, DASH_SPEED)

	move_and_slide()

func start_dash():
	is_dashing = true
	can_dash = false 
	dash_timer = DASH_DURATION
	
	# YENİ: Cooldown süresini başlat
	dash_cooldown_timer = DASH_COOLDOWN
	
	# Yön belirleme
	var direction = Input.get_axis("left", "right")
	if direction != 0:
		dash_direction = direction
	else:
		dash_direction = -1 if animated_sprite_2d.flip_h else 1
