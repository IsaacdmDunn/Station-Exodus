extends CharacterBody2D

@onready var tilemap = $"../TileMapLayer"
var currentPath: Array[Vector2i]
var moveSpeed = 1.33
func _process(delta: float) -> void:
	moveCharacter()
	

func _unhandled_input(event: InputEvent) -> void:
	var clickPos = get_global_mouse_position()
	if event.is_action_pressed("MovePawn"):
		
		if tilemap.CheckPointWalkable(clickPos):
			currentPath = tilemap.aStar.get_id_path(tilemap.local_to_map(global_position), tilemap.local_to_map(clickPos)).slice(1)

func moveCharacter():
	#if path is empty do nothing
	if currentPath.is_empty():
		return
	#move to next tile
	var targetPos = tilemap.map_to_local(currentPath.front())
	global_position = global_position.move_toward(targetPos, moveSpeed)
	
	#if at destination get next tile
	if global_position == targetPos:
		currentPath.pop_front()
	pass
	
