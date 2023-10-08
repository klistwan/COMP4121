extends Node

@onready var map = $Map


func _on_gui_generate_button_pressed():
	map.generate()
