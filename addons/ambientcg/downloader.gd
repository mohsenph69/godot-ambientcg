tool
extends HBoxContainer

var resource_filesystem:EditorFileSystem = null

onready var label = $Label
onready var progressBar = $ProgressBar
onready var http = $HTTPRequest
onready var mes = $message

var setting = null


var extract_path = "res://textures/"
var material_path = "res://mat/"

var unzip_program = "unzips"
var unzip_arg = "input -d output"

func update_setting():
	extract_path = setting.get_tex_path()
	material_path = setting.get_mat_path()
	unzip_program = setting.get_unzip_program()
	unzip_arg = setting.get_unzip_args()

var id = ""
var attribute = ""
var file_name = ""
var filesize = 0
var filetype = ""
var downloading = false
var extracting = false
var exist = false


var download_link = ""
var content = []

func start():
	var fs = filesize/1024.0/1000 
	$size_label.text = "%0.1f MB" % fs
	if filetype == "zip":
		$drag.mat_path = material_path + id + "_" + attribute + ".material"
	else:
		$drag.mat_path = extract_path + file_name
	update_setting()
	label.text = "%8s" % attribute
	content = valid_content(content)
	if filetype != "zip":
		if check_content():
			go2_not_zip()
			return
	if has_material():
		go2has_material()
	elif check_content():
		resource_filesystem.scan()
		go2import()
	elif filetype == "zip":
		if check_zip():
			unextract_zip_mode()

func go2has_material():
	mes.text = ""
	$action.visible = false
	progressBar.visible = false
	$open_dir.visible = false
	$import.visible = true
	$import.text = "reimport"
	$drag.visible = true

func go2import():
	mes.text = "Downloaded"
	$action.visible = false
	progressBar.visible = false
	$open_dir.visible = false
	$import.visible = true
	if filetype == "exr":
		mes.text = "Downloaded"
		$import.visible = false

func go2_not_zip():
	mes.text = ""
	$action.visible = false
	progressBar.visible = false
	$open_dir.visible = false
	$import.visible = false
	$import.text = "reimport"
	$drag.visible = true

func unextract_zip_mode():
	mes.text = "Please extract Zip manually"
	$action.visible = false
	progressBar.visible = false
	$open_dir.visible = true
	$import.visible = false
	$file_exist_checker.start()

func _ready():
	set_process(false)

func _on_action_button_up():
	update_setting()
	if not downloading:
		set_process(true)
		downloading = true
		$action.text = "Cancel"
		mes.text = "Downloading"
		var dir = Directory.new()
		var abs_extract_path = ""
		if filetype == "zip":
			abs_extract_path = extract_path + id + "/"
		else:
			abs_extract_path = extract_path
		if not dir.dir_exists(abs_extract_path):
			dir.make_dir_recursive(abs_extract_path)
		http.download_file = abs_extract_path + file_name
		http.request(download_link)
	else:
		downloading = false
		$action.text = "Download"
		mes.text = "Canceled"
		progressBar.value = 0
		http.cancel_request()
		remove_zip()


func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	set_process(false)
	if filetype != "zip":
		resource_filesystem.scan()
		go2_not_zip()
		return
	if result != 0:
		mes.text = "Fail"
	else:
		mes.text = "Downloaded"
		progressBar.value = 100
		extract()
		resource_filesystem.scan()
		if check_content():
			call_deferred("import")
			mes.text = ""
			clear_files()
		else:
			unextract_zip_mode()
	downloading = false

func extract():
	var out = []
	OS.execute(unzip_program, get_unzip_arg(), true, out)
	print("Extraxting " + unzip_program + str(unzip_arg))
	print(out)

func get_unzip_arg():
	var path = ProjectSettings.globalize_path(extract_path + id + "/" + file_name)
	var dir = ProjectSettings.globalize_path(extract_path + id)
	var args = []
	var raw = unzip_arg.split(" ")
	for a in raw:
		a = a.strip_edges()
		if a == "": continue
		if a == "input":
			a = path
		elif a == "output":
			a = dir
		args.push_back(a)
	return args
	

func update_progressBar():
	if http.get_body_size() != -1:
		progressBar.value = (float(http.get_downloaded_bytes())/http.get_body_size())*100

func _process(delta):
	update_progressBar()

func check_content():
	if filetype == "zip":
		var list = list_files(extract_path + id)
		for item in content:
			if not list.has(item):
				return false
		return true
	elif filetype == "exr":
		var file = File.new()
		return file.file_exists(extract_path + file_name)
			


func check_zip():
	var file = File.new()
	if not file.file_exists(extract_path + id +"/" + file_name):
		return false
	file.open(extract_path + id +"/" + file_name, File.READ)
	var size = file.get_len()
	file.close()
	return size == filesize

func clear_files():
	var list = list_files(extract_path + id)
	var valid_contents = valid_content(list)
	var dir = Directory.new()
	for item in list:
		if not valid_contents.has(item) and not is_zip(item):
			dir.remove(extract_path + id + "/" + item)

func remove_zip():
	var path = extract_path + id + "/" + file_name
	var f = File.new()
	var dir = Directory.new()
	if f.file_exists(path):
		dir.remove(path)

func list_files(path):
	var files = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			files.append(file)
	dir.list_dir_end()
	return files

func import():
	$import_timer.start()
	yield($import_timer, "timeout")
	if not check_content(): return false
	var mat = null
	if has_material():
		mat = load(material_path + id + "_" + attribute + ".material")
	else:
		mat = SpatialMaterial.new()
	var albedo = null
	var normal = null
	var ambient = null
	var roughness = null
	for item in content:
		var item_tex = load(extract_path + id + "/" + item)
		if item.findn("Color") != -1:
			albedo = item_tex
		elif item.findn("normal") != -1:
			normal = item_tex
		elif item.findn("AmbientOcclusion") != -1:
			ambient = item_tex
		elif item.findn("Roughness") != -1:
			roughness = item_tex
	if albedo != null:
		mat.albedo_texture = albedo
	if normal != null:
		mat.normal_enabled = true
		mat.normal_texture = normal
	if ambient != null:
		mat.ao_enabled = true
		mat.ao_texture = ambient
	if roughness != null:
		mat.roughness_texture = roughness
	var dir = Directory.new()
	if not dir.dir_exists(material_path):
		dir.make_dir_recursive(material_path)
	ResourceSaver.save(material_path + id + "_" + attribute + ".material", mat)
	dir.remove(extract_path + id + "/" + file_name)
	go2has_material()
	return true

func valid_content(input):
	var out = []
	for item in input:
		if item.findn("color") != -1:
			out.push_back(item)
		elif item.findn("roughness") != -1:
			out.push_back(item)
		elif item.findn("normal") != -1:
			out.push_back(item)
		elif item.findn("ambient") != -1:
			out.push_back(item)
	return out

func _on_import_button_up():
	call_deferred("import")


func _on_open_dir_button_up():
	var absoult_path = ProjectSettings.globalize_path(extract_path + id)
	OS.shell_open(absoult_path)

func _on_file_exist_checker_timeout():
	if check_content():
		resource_filesystem.scan()
		$file_exist_checker.stop()
		clear_files()
		call_deferred("import")
		go2has_material()


func has_material():
	var file = File.new()
	var path = material_path + id + "_" + attribute + ".material"
	return file.file_exists(path)

func is_zip(input:String):
	if input.length() < 4:
		return false
	var ext = ""
	for i in range(input.length() -4 , input.length()):
		ext += input[i]
	return ext == ".zip"
