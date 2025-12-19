extends CharacterBody2D

@onready var scarf_manager = $ScarfManager
@onready var grapple_physics  = $ScarfManager/GrapplePhysics
@onready var player_camera = $PlayerCamera

const SPEED = 350.0
const JUMP_VELOCITY = -350.0
const ACCELERATION = 0.1

# NOTE: Input managment for grappling hook is in scarf_manager.gd, because of bug avoidance
func _physics_process(delta: float) -> void:
	if scarf_manager.is_grappling:
		player_camera.set_camera_state(player_camera.CameraState.PLAYER_GRAPPLING)
		_handle_grapple_movement(delta)
	else:
		player_camera.set_camera_state(player_camera.CameraState.DEFAULT)
		_handle_normal_movement(delta)
	
	move_and_slide()


func _handle_normal_movement(delta):
	if is_on_floor():
		global_rotation = lerp(global_rotation, 0.0, 0.7)
	else:
		global_rotation = lerp(global_rotation, 0.0, 0.05)
		velocity.y += get_gravity().y * delta
	
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = lerp(velocity.x, direction * SPEED, ACCELERATION)
	else:
		velocity.x = lerp(velocity.x, 0.0, ACCELERATION)		
	
func _handle_grapple_movement():
	if not is_on_floor():
		var direction = Input.get_axis("ui_left", "ui_right")
		var tanget = Vector2(direction, 0)
		grapple_physics.swing_body.apply_central_impulse(tanget * grapple_physics.grapple_sensitivity)
