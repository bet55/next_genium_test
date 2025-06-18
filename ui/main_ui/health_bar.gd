extends ProgressBar

@onready var label: Label = $Label


func _ready() -> void:
	GloabalLinks.player.hp_changed.connect(Callable(self, "_on_player_hp_changed"))
	max_value = GloabalLinks.player.max_health
	value = GloabalLinks.player.health
	label.text = str(int(value))


func _on_player_hp_changed(amount):
	value -= amount
	label.text = str(int(value))
