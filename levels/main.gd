extends Node2D

@onready var canvas_layer: CanvasLayer = $CanvasLayer

const DIE_SCREEN = preload("uid://cn0enuet844im")


func _ready() -> void:
	GloabalLinks.main = self
	GloabalLinks.player.player_died.connect(Callable(self, "_on_player_died"))


func _on_player_died():
	var die_screen = DIE_SCREEN.instantiate()
	canvas_layer.add_child(die_screen)
	
