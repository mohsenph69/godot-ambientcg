tool
extends TextureRect

var mat_path = ""

func get_drag_data(position):
	return {"files":[mat_path], "from":"", "type":"files"}
