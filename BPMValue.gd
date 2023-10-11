extends Label

func _ready():
	text = str(get_parent().get_node("BPM").value)


func _on_bpm_value_changed(value):
	text = str(value)
