extends Node2D

@onready var player = $"../.."
@onready var scarf_manager = get_parent()
@onready var player_collision_shape = $"../../CollisionShape2D"

var swing_body : RigidBody2D
var swing_collision_shape : CollisionShape2D
var pin : PinJoint2D

@export var grapple_sensitivity := 4.0
@export var swing_softness := 1.0
@export var max_swing := 5.0

func setup_swing_body():
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
	
func setup_pin(grapple_point: Vector2):
	var anchor_point = scarf_manager.ray.get_collider()
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

func handle_swing_physics():
	# Handle player input
	var tanget = Vector2(Input.get_axis("ui_left", "ui_right"), 0)
	swing_body.apply_central_impulse(tanget * grapple_sensitivity)
	
	# Set player position to next swing position
	player.global_position = swing_body.global_position
	player.global_rotation = lerp(player.global_rotation, swing_body.global_rotation, 0.1)

func handle_pull_physics(grapple_point: Vector2):
	# distance between mouse and grapple point
	var dist = grapple_point.distance_to(get_global_mouse_position())
	# optional scaling to tune power
	var force = dist * 2
	var pull_dir = (grapple_point - player.global_position).normalized()

	swing_body.apply_central_impulse(pull_dir * force)

	player.global_position = swing_body.global_position
	player.global_rotation = lerp(player.global_rotation, swing_body.global_rotation, 0.1)
	
func start_pull():
	player.scarf_manager._pull_time_left = 0.25   # duration of the pull, adjust as needed

func lauch_off():
	player_collision_shape.disabled = false
	if not swing_body:
		return
	
	player.velocity = swing_body.linear_velocity

func free_physics_nodes():
	_free_physic_node(pin)
	_free_physic_node(swing_body)
	_free_physic_node(swing_collision_shape)

func _free_physic_node(node):
	if node:
		node.queue_free() 
