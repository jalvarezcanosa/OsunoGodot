extends Area2D

signal card_dropped(card)

func _on_area_entered(area):
	if area is Area2D and area.has_method("return_to_hand"):
		emit_signal("card_dropped", area)
