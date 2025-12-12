extends Node2D

@onready var scarf = $"../Scarf"

@export var extend_speed := 30.0
var current_point := Vector2.ZERO
var extending := false
var retracting := false

func start_scarf_extend(player_pos):
	current_point = player_pos
	scarf.visible = true
	retracting = false
	extending = true
	
func start_scarf_retract():
	retracting = true
		
func update_line(player_pos: Vector2, grapple_point: Vector2):
	scarf.points = [player_pos, current_point]
	if extending:
		var dir = current_point.direction_to(grapple_point)
		var dist = current_point.distance_to(grapple_point)
	
		if dist <= 20.0:
			current_point = grapple_point
			extending = false
		else:
			current_point += dir * extend_speed
	elif retracting:
		var dir = current_point.direction_to(player_pos)
		var dist = current_point.distance_to(player_pos)

		if extend_speed >= dist:
			current_point = player_pos
			retracting = false
			scarf.visible = false
		else:
			current_point += dir * extend_speed
