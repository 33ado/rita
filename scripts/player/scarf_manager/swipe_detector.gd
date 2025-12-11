extends Node2D

# Holds swipe detection values exactly as in your original file.
var _swipe_threshold := 50.0
var _proximity_threshold := 60.0
var _previous_mouse_pos := Vector2.ZERO

# Return `true` when player swipes from the grapple point TOWARD the player.
# Parameters:
# - grapple_point: global grapple Vector2
# - player_pos: player's global position Vector2
func is_swiping_from_grapple_to_player(grapple_point: Vector2, player_pos: Vector2) -> bool:
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
	var dir_to_player = (player_pos - get_global_mouse_position()).normalized()
	var swipe_dir = delta.normalized()

	var alignment = swipe_dir.dot(dir_to_player)
	_previous_mouse_pos = get_global_mouse_position()

	# Dot > 0.6 = same direction
	return alignment > 0.6
