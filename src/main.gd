extends Node

@onready var map = $Map
@onready var gui = $GUI


func _ready():
	map.generation_finished.connect(_on_map_generation_finished)


func _on_gui_generate_button_pressed():
	map.generate()


func _on_map_generation_finished():
	gui.enable_generate_button()
