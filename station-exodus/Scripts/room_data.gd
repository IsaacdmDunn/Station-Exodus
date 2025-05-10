extends Node2D

var roomID = -1
var roomType
var subRoom = [] #subrooms have start and end location also a tilesize
var area: int = 0 #tile count
var contents: Array[Vector2] #represnts liquid/ gas contents and the amount with 1 atmos per tile (max of 2?)
var totalContent = 0
var buildings = []
var walls = []
var doors = []
var airlocks =[]

func _ready() -> void:
	contents.append(Vector2(GameResources.ResourceIDs.Water,0))
	contents.append(Vector2(GameResources.ResourceIDs.Hydrogen,0))
	contents.append(Vector2(GameResources.ResourceIDs.Oxygen,0))
	contents.append(Vector2(GameResources.ResourceIDs.Carbon,0))
	print(self)
