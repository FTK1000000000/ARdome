extends Node2D

@onready var player = $player


func _ready():
	pass


func _on_inventory_closeed():
	get_tree().paused = false


func _on_inventory_opened():
	get_tree().paused = true
