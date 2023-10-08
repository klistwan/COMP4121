extends Control

signal generate_button_pressed


func _on_generate_pressed():
	generate_button_pressed.emit()
