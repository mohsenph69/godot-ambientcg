tool
extends EditorPlugin

const dock_res = preload("res://addons/ambientcg/gdasset.tscn")
var dock

var ff:FileSystemDock = null
func _enter_tree():
	dock = dock_res.instance()
	get_editor_interface().get_editor_viewport().add_child(dock)
	var filesystem = get_editor_interface().get_resource_filesystem()
	dock.resource_filesystem = filesystem


func find_import_node(base_node:Node):
	if base_node.is_class("Button"):
		if base_node.text.findn("Reimport") != -1:
			take_info(base_node)
			return true
	for child in base_node.get_children():
		var res = find_import_node(child)
		if res: return
	return false


func file_selected(file_selected):
	print("Select --> " + file_selected)

func find_fileDialog(base_node:Node):
	if base_node.is_class("FileSystemDock"):
		ff = base_node
		return true
	for child in base_node.get_children():
		var res = find_fileDialog(child)
		if res: return
	return false

func take_info_2(cnode:FileSystemDock):
	cnode.get_signal_connection_list("instance")

func take_info(cnode:Button):
	print(cnode.get_signal_connection_list("pressed")[0])
	var t = cnode.get_signal_connection_list("pressed")[0].target
	var path = "res://textures/WoodFloor051/WoodFloor051_1K_Roughness.jpg"
	var dir = Directory.new()
	dir.copy(path, "res://0000001.jpg")
	ff.navigate_to_path("res://0000001.jpg")
	t._reimport()
func _exit_tree():
	if dock:
		dock.queue_free()

func has_main_screen():
	return true


func make_visible(visible):
	if dock:
		dock.visible = visible


func get_plugin_name():
	return "AbmientCG"


func get_plugin_icon():
	return load("res://addons/ambientcg/asset/plugin-icon.png")


