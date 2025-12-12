extends Node2D

enum ScarfState {
	SWING,
	PULL,
	ATTACK
}

var scarf_state : ScarfState

@onready var ray = $RayCast2D
@onready var scarf_renderer = $ScarfRenderer
@onready var player_collision_shape = $"../CollisionShape2D"
@onready var player_camera = $"../PlayerCamera"
@onready var player = get_parent()

@export var grapple_sensitivity := 4.0
@export var swing_softness := 1.0
@export var max_swing := 5.0

# Pull variables
var _swipe_threshold := 50.0 
var _proximity_threshold := 60.0 
var _previous_mouse_pos := Vector2.ZERO
var _pull_time_left := 0.0

# Launch variables
var is_grappling = false
var grapple_point : Vector2
var scarf_length: float
var swing_body : RigidBody2D
var swing_collision_shape : CollisionShape2D
var pin : PinJoint2D

func _physics_process(delta: float) -> void:
	if _pull_time_left > 0.0:
		_pull_time_left -= delta
		if _pull_time_left <= 0.0:
			_retract()
	
	ray.look_at(get_global_mouse_position())
	
	if Input.is_action_just_pressed("grapple") :
		_launch()
	if Input.is_action_just_released("grapple") and not player.is_on_floor() and is_grappling:
		_retract()
	
	if is_grappling or scarf_renderer.extending or scarf_renderer.retracting:
		scarf_renderer.update_line(player.global_position, grapple_point)
	
	if is_grappling:
		_check_scarf_state()
		match scarf_state:
			ScarfState.SWING:
				_handle_swing_physics()
			ScarfState.PULL:
				_handle_pull_physics()
		
func _check_scarf_state():
	# If pull is active, keep it active
	if _pull_time_left > 0.0:
		scarf_state = ScarfState.PULL
		return

	if _is_swiping_from_grapple_to_player():
		_start_pull()
	else:
		scarf_state = ScarfState.SWING

func _is_swiping_from_grapple_to_player() -> bool:
	var delta = get_global_mouse_position() - _previous_mouse_pos
	
	# Player must move mouse fast
	var speed = delta.length()
	if speed < _swipe_threshold:
		_previous_mouse_pos = get_global_mouse_position()
		return false
		
	# Must start the swipe near the grapple point
	if get_global_mouse_position().distance_to(grapple_point) > _proximity_threshold:
		_previous_mouse_pos = get_global_mouse_position()
		return false
		
	# Check direction: must point roughly toward the player
	var dir_to_player = (player.global_position - get_global_mouse_position()).normalized()
	var swipe_dir = delta.normalized()
	
	var alignment = swipe_dir.dot(dir_to_player)
	_previous_mouse_pos = get_global_mouse_position()
	
	# Dot > 0.6 = same direction
	return alignment > 0.6

func _launch():
	# Handle raycasting
	if ray.is_colliding():
		grapple_point = ray.get_collision_point()
		
		# Check if mouse is hovering the collision point
		scarf_length = player.global_position.distance_to(grapple_point)
		var mouse_dist = player.global_position.distance_to(get_global_mouse_position())
		if mouse_dist >= scarf_length:
			player_camera.set_camera_state(player_camera.CameraState.PLAYER_GRAPPLING)
			
			# Setting up swing with rigidbody and pinjoint
			_setup_swing_body()
			_setup_pin()
			scarf_renderer.start_scarf_extend(player.global_position)
			is_grappling = true
		
func _setup_swing_body():
	swing_body = RigidBody2D.new()
	# Setting properties for bug advoidance
	player_collision_shape.disabled = true
	# Adding Collisionshape
	swing_collision_shape = CollisionShape2D.new()
	swing_collision_shape.shape = player_collision_shape.shape
	# Managing nodetree
	swing_body.add_child(swing_collision_shape)
	player.get_parent().add_child(swing_body)
	swing_body.global_position = player.global_position
	
func _setup_pin():
	var anchor_point = ray.get_collider()
	pin = PinJoint2D.new()
	pin.disable_collision = false
	pin.softness = swing_softness
	pin.set_angular_limit_enabled(true)
	pin.set_angular_limit_upper(max_swing)
	# Managing nodetree
	player.get_parent().add_child(pin)
	pin.global_position = grapple_point
	pin.node_a = anchor_point.get_path()
	pin.node_b = swing_body.get_path()

func _retract():
	_lauch_off()
	player_collision_shape.disabled = false
	scarf_renderer.start_scarf_retract()
	is_grappling = false
	
	# Delete existent nodes
	_free_node(pin)
	_free_node(swing_body)
	_free_node(swing_collision_shape)
	
func _lauch_off():
	if not swing_body:
		return
	
	player.velocity = swing_body.linear_velocity

func _free_node(node):
	if node:
		node.queue_free()

func _handle_swing_physics():
	# Handle player input
	var tanget = Vector2(Input.get_axis("ui_left", "ui_right"), 0)
	swing_body.apply_central_impulse(tanget * grapple_sensitivity)
	
	# Set player position to next swing position
	player.global_position = swing_body.global_position
	player.global_rotation = lerp(player.global_rotation, swing_body.global_rotation, 0.1)

func _handle_pull_physics():
	# distance between mouse and grapple point
	var dist = grapple_point.distance_to(get_global_mouse_position())
	# optional scaling to tune power
	var force = dist * 2
	var pull_dir = (grapple_point - player.global_position).normalized()

	swing_body.apply_central_impulse(pull_dir * force)

	player.global_position = swing_body.global_position
	player.global_rotation = lerp(player.global_rotation, swing_body.global_rotation, 0.1)

func _start_pull():
	_pull_time_left = 0.4   # duration of the pull, adjust as needed
