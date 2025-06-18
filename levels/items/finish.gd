extends Node2D

const WIN_SCREEN = preload("uid://bg86fejhi7pit")


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var win_screen = WIN_SCREEN.instantiate()
		GloabalLinks.main.canvas_layer.add_child(win_screen)
		GloabalLinks.player.queue_free()
