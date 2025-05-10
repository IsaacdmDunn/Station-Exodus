extends Node

enum ResourceIDs {
	Water, Hydrogen, Oxygen, Iron, Uranium, Carbon,
}
var items = []

func _ready() -> void:
	items.resize(1000)
