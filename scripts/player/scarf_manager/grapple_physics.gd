extends Node2D

# This node contains the physics-related functions originally in ScarfManager.
# Behaviour and numeric values preserved; no logic changes.

var swing_body : RigidBody2D
var swing_collision_shape : CollisionShape2D
var pin : PinJoint2D

# Create the swing body and duplicate the player's collision shape.
# Parameters:
# - player_node: the player node (CharacterBody2D)
# - player_collision_shape_node: CollisionShape2D node from the player (used for copying)
func _setup_swing_body(player_node: Node, player_collision_shape_node: CollisionShape2D) -> void:
	swing_body = RigidBody2D.new()

	# Prevent collision issues (match original behaviour)
	player_collision_shape_node.disabled = true

	# Duplicate collision shape (shape object reused exactly as original)
	swing_collision_shape = CollisionShape2D.new()
	swing_collision_shape.shape = player_collision_shape_node.shape

	# Add to scene exactly where you had it before
	swing_body.add_child(swing_collision_shape)
	player_node.get_parent().add_child(swing_body)
	swing_body.global_position = player_node.global_position

# Create the PinJoint2D between the anchor and the swing body.
# anchor_collider: the collider returned by RayCast2D.get_collider()
# grapple_point: global point to pin to
# swing_softness / max_swing: parameters (kept same names as ScarfManager)
func _setup_pin(anchor_collider: Object, grapple_point: Vector2, swing_softness := 1.0, max_swing := 5.0) -> void:
	pin = PinJoint2D.new()
	pin.disable_collision = false
	pin.softness = swing_softness
	pin.set_angular_limit_enabled(true)
	pin.set_angular_limit_upper(max_swing)

	get_parent().add_child(pin)
	pin.global_position = grapple_point

	# Match original node paths
	pin.node_a = anchor_collider.get_path()
	pin.node_b = swing_body.get_path()

# Free nodes (same behavior as original _free_node calls)
func _free_node(node: Node) -> void:
	if node:
		node.queue_free()

# Frees the pin, swing body and collision shape created earlier
func _free_all_nodes() -> void:
	_free_node(pin)
	_free_node(swing_body)
	_free_node(swing_collision_shape)
	pin = null
	swing_body = null
	swing_collision_shape = null

# Return the current linear_velocity of the swing_body (or null if none)
func _get_swing_linear_velocity():
	if swing_body:
		return swing_body.linear_velocity
	return null

# The original swing physics handler (unchanged behaviour)
# - sensitivity matches the variable you used earlier, so pass it in from ScarfManager.
# - player_node is used to assign player's global_position and rotation like before.
func _handle_swing_physics(sensitivity: float, player_node: Node) -> void:
	if not swing_body:
		return

	var tangent = Vector2(Input.get_axis("ui_left", "ui_right"), 0)
	swing_body.apply_central_impulse(tangent * sensitivity)

	# Keep player visually in sync (exact behaviour)
	player_node.global_position = swing_body.global_position
	player_node.global_rotation = lerp(player_node.global_rotation, swing_body.global_rotation, 0.1)

# The original pull physics handler (unchanged behaviour)
# - Uses current mouse pos & grapple_point for force calculation.
func _handle_pull_physics(grapple_point: Vector2, player_node: Node) -> void:
	if not swing_body:
		return

	var dist = grapple_point.distance_to(get_global_mouse_position())
	var force = dist * 2

	var pull_dir = (grapple_point - player_node.global_position).normalized()
	swing_body.apply_central_impulse(pull_dir * force)

	player_node.global_position = swing_body.global_position
	player_node.global_rotation = lerp(player_node.global_rotation, swing_body.global_rotation, 0.1)
