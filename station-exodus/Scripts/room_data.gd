extends Node2D

var roomID = -1
var roomType
var subRoom = [] #subrooms have start and end location also a tilesize
var area: int = 0 #tile count
var contents = [0, 0] #represnts liquid/ gas contents and the amount
var buildings = []
var walls = []
var doors = []
var airlocks =[]
