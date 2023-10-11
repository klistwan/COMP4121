extends Node

@onready var map = $Map
@onready var gui = $GUI


func _ready():
	map.generation_finished.connect(_on_map_generation_finished)


func _on_gui_generate_button_pressed(algorithm_path: String) -> void:
	map.generate(algorithm_path)


func _on_map_generation_finished():
	gui.enable_generate_button()
