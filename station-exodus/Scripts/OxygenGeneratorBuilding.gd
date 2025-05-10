extends ProductionBuilding

var outputToRoom: Array[int]
var outputLimit = 2
func _ready() -> void:
	#adds to group for buildings
	buildingID = get_tree().get_nodes_in_group("Buildings").size()
	add_to_group("Buildings")
	outputToRoom.append(GameResources.ResourceIDs.Oxygen)
	buildingSize = Vector2i(1,1) #sets size to 1x1
	workingPosition.append(Vector2i(0,1)) #working pos is relative to beneath the building
	input.append(Vector2(GameResources.ResourceIDs.Water,.01)) #water input
	output.append(Vector2(GameResources.ResourceIDs.Hydrogen,.005)) #oxygen output
	output.append(Vector2(GameResources.ResourceIDs.Oxygen,.005))
	
	
func _process(delta: float) -> void:
	var roomData = get_tree().get_nodes_in_group("Rooms")[roomID]
	if roomData.contents[2].y < (roomData.area * outputLimit):
		get_tree().get_nodes_in_group("Rooms")[roomID].contents[2].y += output[1].y
		print(get_tree().get_nodes_in_group("Rooms")[roomID].contents)
	
