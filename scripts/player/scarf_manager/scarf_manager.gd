extends Node2D

enum ScarfState {
	SWING,
	PULL,
	ATTACK
}

var scarf_state : ScarfState

@onready var ray = $RayCast2D
@onready var scarf_renderer = $ScarfRenderer
@onready var swipe_detector = $SwipeDetector
@onready var grapple_physics = $GrapplePhysics
@onready var player = get_parent()

# Pull variables
var _pull_time_left := 0.0

# Launch variables
var is_grappling = false
var grapple_point : Vector2
var scarf_length: float

func _physics_process(delta: float) -> void:
	if _pull_time_left > 0.0:
		_pull_time_left -= delta
		if _pull_time_left <= 0.0 and is_grappling:
			retract()
	
	ray.look_at(get_global_mouse_position())
	if Input.is_action_just_pressed("grapple") :
		launch()
	if Input.is_action_just_released("grapple") and is_grappling:
		retract()
	
	if is_grappling or scarf_renderer.extending or scarf_renderer.retracting:
		scarf_renderer.update_line(player.global_position, grapple_point)
	
	if is_grappling:
		_check_scarf_state()
		match scarf_state:
			ScarfState.SWING:
				grapple_physics.handle_swing_physics()
			ScarfState.PULL:
				grapple_physics.handle_pull_physics(grapple_point)
		
func _check_scarf_state():
	# If pull is active, keep it active
	if _pull_time_left > 0.0:
		scarf_state = ScarfState.PULL
		return

	if swipe_detector.is_swiping_from_grapple_to_player(grapple_point):
		grapple_physics.start_pull()
	else:
		scarf_state = ScarfState.SWING

func launch():
	# Handle raycasting
	if ray.is_colliding():
		grapple_point = ray.get_collision_point()
		
		# Check if mouse is hovering the collision point
		scarf_length = player.global_position.distance_to(grapple_point)
		var mouse_dist = player.global_position.distance_to(get_global_mouse_position())
		if mouse_dist >= scarf_length:			
			# Setting up swing with rigidbody and pinjoint
			grapple_physics.setup_swing_body()
			grapple_physics.setup_pin(grapple_point)
			scarf_renderer.start_scarf_extend(player.global_position)
			is_grappling = true

func retract():
	grapple_physics.lauch_off()
	scarf_renderer.start_scarf_retract()
	is_grappling = false
	
	# Delete existent nodes
	grapple_physics.free_physics_nodes()
	
