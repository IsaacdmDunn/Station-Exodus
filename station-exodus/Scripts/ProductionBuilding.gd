extends Node2D
class_name ProductionBuilding
enum Directions {Left, Right, Up, Down}
var buildingPosition: Vector2i #top left
var roomID: int
var buildingID: int
var buildingRotation: Directions = Directions.Up
var buildingSize: Vector2i
var workingPosition: Array[Vector2i]
var connectedBuildingsID: Array[int]
var resourceContents: Array[Vector2]
var input: Array[Vector2]
var output: Array[Vector2]
