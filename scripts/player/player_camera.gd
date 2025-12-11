extends Camera2D

enum CameraState { PLAYER_GRAPPLING, DEFAULT }
var camera_state := CameraState.DEFAULT

@onready var player := get_parent()
@onready var scarf_manager := $"../ScarfManager"

@export var min_zoom: float = 0.5
@export var max_zoom: float = 1.2
@export var max_speed: float = 800.0
@export var zoom_speed: float = 2.0

func _process(delta):
	match camera_state:
		CameraState.PLAYER_GRAPPLING:
			_handle_player_grappling(delta)
		_:
			_handle_default(delta)

func set_camera_state(cs: CameraState):
	camera_state = cs

func _handle_default(delta):
	global_position = lerp(global_position, player.global_position, zoom_speed / 100)
	var target_zoom = _adapt_zoom_to_player_velocity()
	zoom = zoom.lerp(Vector2(target_zoom, target_zoom), delta * zoom_speed)

func _handle_player_grappling(delta):
	global_position = lerp(global_position, scarf_manager.grapple_point, zoom_speed / 100)
	var target_zoom = _adapt_zoom_to_player_velocity()
	zoom = zoom.lerp(Vector2(target_zoom, target_zoom), delta * zoom_speed)

func _adapt_zoom_to_player_velocity():
	if not player:
		return zoom
	var speed = player.velocity.length()
	var t = clamp(speed / max_speed, 0.0, 1.0)
	return lerp(max_zoom, min_zoom, t)
