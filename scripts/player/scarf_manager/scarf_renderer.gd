extends Node2D

@onready var line := $"../Line2D"

@export var extend_speed := 20.0
var extending := false
var scarf_tip : Sprite2D
var scarf_segment : Sprite2D

func start_scarf_extend(player_pos):
	extending = true
	scarf_tip = Sprite2D.new()
	scarf_segment = Sprite2D.new()
	
	# Placeholder code
	var scarf_tip_texture = PlaceholderTexture2D.new()
	scarf_tip_texture.size = Vector2(20, 20)
	scarf_tip.texture = scarf_tip_texture
	var scarf_segment_texture = PlaceholderTexture2D.new()
	scarf_segment_texture.size = Vector2(10, 10)
	scarf_segment.texture = scarf_segment_texture
	
	scarf_tip.global_position = player_pos
	scarf_segment.global_position = player_pos
	
	var scene = get_parent().player.get_parent()
	scene.add_child(scarf_tip)
	scene.add_child(scarf_segment)
	print_tree_pretty()
	
func start_scarf_retract():
	_free_node(scarf_tip)
	_free_node(scarf_segment)

func _free_node(node):
	if node:
		node.queue_free()

func update_line(grapple_point: Vector2):
	if not extending: return
	
	var dist = scarf_tip.global_position.distance_to(grapple_point)
	var dir = scarf_tip.global_position.direction_to(grapple_point)

	if dist <= scarf_tip.texture.get_size().y: 
		scarf_tip.global_position = grapple_point
		extending = false
	else:
		scarf_tip.global_position = scarf_tip.global_position + (dir * extend_speed) 
		var displacement = dir * scarf_segment.global_position.distance_to(scarf_tip.global_position)
		print(displacement)
		scarf_segment.global_position = scarf_segment.global_position + (dir * extend_speed) - displacement
