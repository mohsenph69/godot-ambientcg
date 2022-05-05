tool
extends ScrollContainer

onready var http = $http
onready var mes = $V/H/mes

var tmp = "res://addons/ambientcg/asset/list-copy.csv"
var csv_path = "res://addons/ambientcg/asset/list.csv"

func _on_back_button_up():
	visible = false
	get_parent().get_node("V").visible = true



func get_tex_path():
	return final_slash($V/tex_path.text)

func get_mat_path():
	return final_slash($V/mat_path.text)

func get_unzip_program():
	return $V/unzip_program.text

func get_unzip_args():
	return $V/unzip_arg.text

func final_slash(input:String):
	input = input.strip_edges()
	if input[input.length() -1 ] != "/":
		input += "/"
	return input


func _on_update_csv_button_up():
	set_process(true)
	http.download_file = tmp
	http.request("https://ambientcg.com/api/v2/downloads_csv")
	mes.text = "Downloading"

func _on_http_request_completed(result, response_code, headers, body):
	set_process(false)
	var dir = Directory.new()
	if result != 0:
		mes.text = "Fail"
		dir.remove(tmp)
		return
	mes.text = "Updated"
	dir.copy(tmp, csv_path)
	dir.remove(tmp)
