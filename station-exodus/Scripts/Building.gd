extends TileMapLayer

enum BuildState {
	None = 0, Room = 1, Door = 2, Hangar = 3, Pipe = 4, SmallBasicBuilding = 5, LargeBasicBuilding = 6, SmallUserBuilding = 7, LargeUserBuilding = 8
}
enum BuildDirection {
	Up = 0, Right = 1, Down = 2, Left = 3
}
var CurrentBuildState = BuildState.None
var CurrentBuildDirection = BuildDirection.Up

var roomDataPrefab = preload("res://room_data.tscn")
var subRoomScript = preload("res://Scripts/SubroomData.gd")

var startingPos: Vector2i = Vector2i(-1000,-1000)
var endingPos: Vector2i
var canBuild: bool = false
var roomAlreadyExists: bool = false
var buildSubroomToID = -1

var maxMapSize = Vector2i(256,256)

var aStar = AStarGrid2D.new()

func _ready() -> void:
	#update a star with init values
	UpdateAStar()
	
	
	pass

func _process(delta: float) -> void:
	#clear build tile map and set sursor
	$BuildUIMap.clear()
	$BuildUIMap.set_cell(local_to_map(get_global_mouse_position()) - Vector2i(0,0),0, Vector2i(0,0))
	
	#if building room show building UI
	if startingPos != Vector2i(-1000,-1000) and CurrentBuildState == BuildState.Room:
		buildingUI(Vector2i(mini(startingPos.x, local_to_map(get_global_mouse_position()).x), mini(startingPos.y, local_to_map(get_global_mouse_position()).y)), Vector2i(maxi(startingPos.x, local_to_map(get_global_mouse_position()).x), maxi(startingPos.y, local_to_map(get_global_mouse_position()).y)))
	#if building door show door building UI
	elif CurrentBuildState == BuildState.Door:
		CreateDoorUI(local_to_map(get_global_mouse_position()))

func _input(event: InputEvent) -> void:	
	#selects build options
	SelectBuildingState(event)
	#if build room attempted
	if CurrentBuildState == BuildState.Room and Input.is_action_just_pressed("Select"):
		#starting pos for the drag and build system
		if startingPos == Vector2i(-1000,-1000):
			startingPos = local_to_map(get_global_mouse_position())
			$BuildUIMap.clear()
		
		#if select while building room set end point and if can build room then fill floor
		elif startingPos != Vector2i(-1000,-1000):
			endingPos = local_to_map(get_global_mouse_position())
			#set_cell(local_to_map(get_global_mouse_position()),0, Vector2i(0,0))
			
			if canBuild or roomAlreadyExists:
				fillFloor(Vector2i(mini(startingPos.x, endingPos.x), mini(startingPos.y, endingPos.y)), Vector2i(maxi(startingPos.x, endingPos.x), maxi(startingPos.y, endingPos.y)))
			
			startingPos = Vector2i(-1000,-1000) # reset start pos
	#if can build door then create door at pos
	elif CurrentBuildState == BuildState.Door and Input.is_action_just_pressed("Select") and canBuild:
		CreateDoor(local_to_map(get_global_mouse_position()))
		
#creates new room	
func fillFloor(start, end):
	var size = Vector2i(end.x - start.x, end.y - start.y) #sets start for loop from left to right
	var tileCount = size.x * size.y
	
	#if theres no preexisting room at start pos make new room
	if !CheckRoomExists(startingPos):
		CreateNewRoom(size ,start, end)
		roomAlreadyExists = false
	else:
		roomAlreadyExists = true
	var tempID = buildSubroomToID
	
	#create tiles in area
	for x in size.x:
		for y in size.y:
			#create solid wall
			if x == 0 or y == 0 or x == size.x-1 or y == size.y-1:
				set_cell(Vector2i(start.x + x, start.y + y),0, Vector2i(1,0))
				aStar.set_point_solid(Vector2i(start.x + x, start.y + y), true)
				
				#room already exists remove walls
				if roomAlreadyExists and CheckRoomExists(Vector2i(start.x + x, start.y + y)) :
					set_cell(Vector2i(start.x + x, start.y + y),0, Vector2i(0,0))
					tileCount -= 1 #tile not counted as it is already in other subroom
					
					#sets tile as not solid
					aStar.set_point_solid(Vector2i(start.x + x, start.y + y), false)
					aStar.set_point_weight_scale(Vector2i(start.x + x, start.y + y), 1)
			#else set as floor and make tile unsolid
			else:
				set_cell(Vector2i(start.x + x, start.y + y),0, Vector2i(0,0))
				aStar.set_point_solid(Vector2i(start.x + x, start.y + y), false)
				aStar.set_point_weight_scale(Vector2i(start.x + x, start.y + y), 1)
	CheckRoomExists(startingPos) #resets room id????
	
	#if adding extension create new room as a subroom
	if roomAlreadyExists:
		CreateNewSubRoom(start,end,buildSubroomToID, tileCount)
	var endingPos = Vector2i(-1000, -1000) # reset endpos
	
	pass

#ui for building new room
func buildingUI(start, end):
	canBuild = true
	var size = Vector2i(end.x - start.x, end.y - start.y)
	var uiCoords
	CheckRoomExists(startingPos) #gets room id for temp use
	var tempID = buildSubroomToID 
	
	#loop for room ui
	for x in size.x:
		for y in size.y:
			uiCoords = Vector2i(start.x + x, start.y + y)
			
			#if in space or existing room and room is larger than 3x3 
			if (get_cell_tile_data(uiCoords) == null or CheckRoomExists(startingPos)) and size.x > 2 and size.y > 2:
				CheckRoomExists(Vector2i(uiCoords))
				#if tile is in same room as starting point tile is allowed
				if tempID == buildSubroomToID:# and get_cell_atlas_coords(Vector2i(start.x + x, start.y + y)) != Vector2i(1,0):
					$BuildUIMap.set_cell(uiCoords,0, Vector2i(0,roomAlreadyExists))
				#else tile is in other room and not eledgeable
				else:
					$BuildUIMap.set_cell(uiCoords,0, Vector2i(1,roomAlreadyExists))
					print(str(tempID) + " : " + str(buildSubroomToID))
					canBuild = false
			else:
				$BuildUIMap.set_cell(uiCoords,0, Vector2i(1,roomAlreadyExists))
				canBuild = false
	pass

#checks if rooms exists at point
func CheckRoomExists(start):
	var id = 0
	for rooms in get_tree().get_nodes_in_group("Rooms"):
		for subrooms in rooms.subRoom:
			if start.x > subrooms.startLocation.x and start.x < subrooms.endLocation.x and start.y > subrooms.startLocation.y and start.y < subrooms.endLocation.y:
				buildSubroomToID = id
				return true
			pass
		pass
	
		id+=1
	return false

#creates new room 
func CreateNewRoom(size, start, end):
	var newRoomData = roomDataPrefab.instantiate()
	self.add_child(newRoomData)  
	newRoomData.roomID = get_tree().get_node_count_in_group("Rooms")
	newRoomData.add_to_group("Rooms")
	CreateNewSubRoom(start, end, newRoomData.roomID, (size.x-2) * (size.y-2))
	pass
	
#create new subroom
func CreateNewSubRoom(start, end, id, tileCount):
	var newSubRoom = subRoomScript.new()
	newSubRoom.startLocation.x = start.x
	newSubRoom.startLocation.y = start.y
	newSubRoom.endLocation.x = end.x
	newSubRoom.endLocation.y = end.y
	newSubRoom.roomID = id
	newSubRoom.tileCount = tileCount
	get_tree().get_nodes_in_group("Rooms")[id].subRoom.append(newSubRoom)
	get_tree().get_nodes_in_group("Rooms")[id].area += tileCount
	roomAlreadyExists=false

#updates a star settings
func UpdateAStar():
	var mapRect = Rect2i(Vector2i.ZERO, maxMapSize)
	aStar.region = mapRect
	aStar.cell_size = tile_set.tile_size
	aStar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	aStar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	aStar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	aStar.update()
	pass

#checks if point is walkable for ai
func CheckPointWalkable(pos):
	var mapRect = Rect2i(Vector2i.ZERO, maxMapSize)
	var mapPosition = local_to_map(pos)
	
	if mapRect.has_point(mapPosition) and !aStar.is_point_solid(mapPosition) and get_cell_tile_data(mapPosition) != null:
		return true
	return false

#creates new door
func CreateDoor(pos):
	var offset
	
	set_cell(pos,0, Vector2i(0,0)) # airlock if no extra door
	
	#sets door orientation based on build dir
	if CurrentBuildDirection == BuildDirection.Left:
		offset = Vector2i(-1, 0)
		set_cell(pos,0, Vector2i(0,1))
	elif CurrentBuildDirection == BuildDirection.Right:
		offset = Vector2i(1, 0)
		set_cell(pos,0, Vector2i(0,1))
	elif CurrentBuildDirection == BuildDirection.Up:
		offset = Vector2i(0, 1)
		set_cell(pos,0, Vector2i(1,1))
	elif CurrentBuildDirection == BuildDirection.Down:
		offset = Vector2i(0, -1)
		set_cell(pos,0, Vector2i(1,1))
	
	#makes door not solid but slow to move through
	aStar.set_point_solid(pos, false)
	aStar.set_point_weight_scale(pos, 15)
	
	#if door set adj tile as a door
	if get_cell_atlas_coords(pos + offset) == Vector2i(1,0):
		set_cell(pos + offset,0, Vector2i(1,1))
		if offset.x != 0:
			set_cell(pos + offset,0, Vector2i(0,1))
		else:
			set_cell(pos + offset,0, Vector2i(1,1))
			
		aStar.set_point_solid(pos + offset, false)
		aStar.set_point_weight_scale(pos + offset, 15)
	
	canBuild = false #reset
	pass

#door ui
func CreateDoorUI(pos):
	$BuildUIMap.clear()
	#check orientation based on adj wall to door position
	if CheckDoorNeighbor(pos, Vector2i(1,0)):
		CurrentBuildDirection = BuildDirection.Right
		canBuild = true
		return
		pass
	elif CheckDoorNeighbor(pos, Vector2i(0,1)):
		CurrentBuildDirection = BuildDirection.Up
		canBuild = true
		pass
		return
	elif CheckDoorNeighbor(pos, Vector2i(-1,0)):
		CurrentBuildDirection = BuildDirection.Left
		canBuild = true
		pass
		return
	elif CheckDoorNeighbor(pos, Vector2i(0,-1)):
		CurrentBuildDirection = BuildDirection.Down
		canBuild = true
		pass
		return

#checks neighbour tile of door
func CheckDoorNeighbor(pos, offset):
	#set check room
	CheckRoomExists(pos)
	var roomID = buildSubroomToID
	#check if door on wall
	if get_cell_atlas_coords(pos) == Vector2i(1,0):
		#check if one side of door is floor and the other is space or wall
		if get_cell_atlas_coords(Vector2i(pos.x - offset.x, pos.y - offset.y)) == Vector2i(0,0):
			if get_cell_atlas_coords(Vector2i(pos.x + offset.x, pos.y + offset.y)) == Vector2i(1,0) and get_cell_atlas_coords(Vector2i(pos.x + (offset.x * 2), pos.y + (offset.y * 2))) == Vector2i(0,0):
				
				#door
				$BuildUIMap.set_cell(Vector2i(pos.x + offset.x, pos.y + offset.y),0, Vector2i(0,1))
				$BuildUIMap.set_cell(Vector2i(pos.x, pos.y),0, Vector2i(0,1))
				return true
				if roomID == buildSubroomToID:
					pass
				pass
			elif get_cell_tile_data(Vector2i(pos.x + offset.x, pos.y + offset.y)) == null:
				#airlock
				$BuildUIMap.set_cell(Vector2i(pos.x, pos.y),0, Vector2i(1,1))
				return true
				pass
			pass
		pass
	return false
	
	
#changes building state
func SelectBuildingState(event: InputEvent):
	if Input.is_action_just_pressed("CreateRoomShortcut"):
		CurrentBuildState = BuildState.Room
	elif Input.is_action_just_pressed("CreateDoorShortcut"):
		CurrentBuildState = BuildState.Door
	pass
	
