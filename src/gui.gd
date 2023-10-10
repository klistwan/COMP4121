extends Control

signal generate_button_pressed

@onready var generate_button: Button = $CenterContainer/VBoxContainer/Generate


func _on_generate_pressed() -> void:
	generate_button_pressed.emit()
	generate_button.disabled = true


func _on_algorithm_options_item_selected(_index) -> void:
	generate_button.disabled = false


func enable_generate_button() -> void:
	generate_button.disabled = false
