extends CharacterBody3D

const starting_pos: Vector3 = Vector3(-270, 5830, 690)

@onready var _camera_base: Node3D = $CameraBase
@onready var _mesh: Node3D = $MeshInstance3D
@onready var _coll_shape_1: Node3D = $CollisionShapeBody
@onready var _coll_shape_2: Node3D = $CollisionShapeBody2
@onready var _boing_player: AudioStreamPlayer = $BoingPlayer
@onready var _pop_player: AudioStreamPlayer = $PopPlayer
@onready var _land_player: AudioStreamPlayer = $LandPlayer
@onready var _splash_player: AudioStreamPlayer = $SplashPlayer
@onready var _escaped_player: AudioStreamPlayer = $EscapedPlayer
@onready var _death_timer: Timer = $DeathTimer
@onready var _escaped_timer: Timer = $EscapedTimer

const SPEED = 100.0
const JUMP_VELOCITY = 145.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var _last_frames_on_floor: Array = [false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false]
var _last_frames_on_floor_index: int = 0
var _on_floor_last_frame: bool = false
var _frontflipping: bool = false
var _frontflip_end_rotation: float = 3 * PI / 2
var _backflipping: bool = false
var _backflip_end_rotation: float = -5 * PI / 2
var _jumping: bool = false
var _was_on_floor: bool = false
var _souped: bool = false
var _escaped: bool = false
var _hud: Node
var _music: AudioStreamPlayer

func _ready() -> void:
	_death_timer.connect("timeout", _done_death)
	_escaped_timer.connect("timeout", _done_death)
	_hud = get_node("../HUD")
	_music = get_node("../AudioStreamPlayer")


func _input(event):
	if event is InputEventMouseMotion:
		_camera_base.rotation.x -= event.relative.y * 0.005
		_camera_base.rotation.x = clamp(_camera_base.rotation.x, deg_to_rad(-35), deg_to_rad(35))
		_camera_base.rotation.y -= deg_to_rad(event.relative.x) * 0.2


func _physics_process(delta):
	if _souped or _escaped:
		return
	
	if _frontflipping:
		_mesh.rotation.x += delta * 15
		if _mesh.rotation.x >= _frontflip_end_rotation:
			_frontflipping = false
			_mesh.rotation.x = deg_to_rad(-90)
	if _backflipping:
		_mesh.rotation.x -= delta * 15
		if _mesh.rotation.x <= _backflip_end_rotation:
			_backflipping = false
			_mesh.rotation.x = deg_to_rad(-90)
	
	# Add the gravity.
	if not is_on_floor():
		var multiplier = 40 if Input.is_action_pressed("jump") else 70
		if velocity.y < 0:
			multiplier = 40
		velocity.y -= gravity * multiplier * delta

	if is_on_floor() and !_was_on_floor and _jumping:
		_jumping = false
		_land_player.play()
	_was_on_floor = is_on_floor()
	

	# Get input
	var input_dir_before = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var input_dir = input_dir_before.rotated(-_camera_base.rotation.y)

	# Handle jump.
	var on_floor: bool = is_on_floor()
	for was_floored: bool in _last_frames_on_floor:
		on_floor = on_floor || was_floored
	if Input.is_action_just_pressed("jump") and on_floor:
		jump(input_dir_before.y <= 0, JUMP_VELOCITY)

	_last_frames_on_floor[_last_frames_on_floor_index] = is_on_floor()
	_last_frames_on_floor_index = (_last_frames_on_floor_index + 1) % _last_frames_on_floor.size()

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	_mesh.rotation.y = _camera_base.rotation.y + PI
	_coll_shape_1.rotation.y = _mesh.rotation.y
	_coll_shape_2.rotation.y = _mesh.rotation.y + (PI / 2.0)
	move_and_slide()


func jump(forward: bool, vel: float) -> void:
	velocity.y = vel
	_pop_player.play()
	if forward:
		_frontflipping = true
	else:
		_backflipping = true
	_jumping = true


func boing() -> void:
	if _souped:
		return
	_boing_player.play()
	jump(true, JUMP_VELOCITY * 2.5)


func souped() -> void:
	_splash_player.play()
	_souped = true
	_hud.souped()
	_death_timer.start()


func _done_death() -> void:
	_hud.reset()
	position = starting_pos
	if !_music.playing:
		_music.play()
	_jumping = false
	_last_frames_on_floor = [false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false]
	_frontflipping = false
	_backflipping = false
	_on_floor_last_frame = false
	_mesh.rotation.x = deg_to_rad(-90)
	_souped = false
	_escaped = false


func _on_end_body_entered(body):
	if "escaped" in body:
		body.escaped()


func escaped() -> void:
	_hud.escaped()
	_music.stop()
	_escaped = true
	_escaped_timer.start()
	_escaped_player.play()
	
