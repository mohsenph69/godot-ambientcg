tool
extends Control

var resource_filesystem:EditorFileSystem = null

onready var items = $V/scroll/ItemList
onready var query = $V/H/query
onready var item_scroll = $V/scroll
onready var vertical_root = $V
onready var setting = $setting

var item_box_res = preload("res://addons/ambientcg/item.tscn")
var hide_item = {}
var current_item = null


var csv_path = "res://addons/ambientcg/asset/list.csv"
var thumbnails_save_path = "res://ambientCG/thumbnails/"
var round_icon = preload("res://addons/ambientcg/asset/Icon-round_small.png")
var image_save_path = ""
var image_name_to_save = ""

var item_names = []
var item_ids = []
var is_in_cat = true
var is_show_item = false


func _ready():
	item_ids = []
	items.clear()
	item_names = []
	get_categories()
	update_items()


func update_items():
	items.clear()
	items.item_ids = item_ids
	for i in item_names:
		items.add_item(i, round_icon)
	items.start()


func _on_ItemList_item_selected(index):
	if is_in_cat:
		is_in_cat = false
		var n = item_names[index]
		search(n , true)
		update_items()
	else:
		is_show_item = true
		item_scroll.visible = false
		if hide_item.has(item_ids[index]):
			current_item = hide_item[item_ids[index]]
			current_item.visible = true
		else:
			var item_box = item_box_res.instance()
			item_box.resource_filesystem = resource_filesystem
			item_box.setting = setting
			vertical_root.add_child(item_box)
			item_box.id = item_ids[index]
			item_box.get_item()
			current_item = item_box
		items.stop()

func _on_search_button_up():
	var q = query.text
	is_in_cat = false
	if q == "":
		return
	search(q, false)
	update_items()

func _on_back_button_up():
	items.unselect_all()
	if is_show_item:
		item_scroll.visible = true
		if not current_item.has_active_download():
			current_item.queue_free()
			if hide_item.has(current_item.id):
				hide_item.erase(current_item.id)
			current_item = null
		else:
			hide_item[current_item.id] = current_item
			current_item.visible = false
			current_item = null
			print(hide_item)
		is_show_item = false
		items.start()
		return
	if not is_in_cat:
		is_in_cat = true
		get_categories()
		update_items()

func get_categories():
	item_names = []
	item_ids = []
	var file = File.new()
	file.open(csv_path, File.READ)
	var reg = RegEx.new()
	reg.compile("^[a-zA-Z]+")
	var cat = []
	var cat_t = []
	var i = 0
	while !file.eof_reached():
		var csv = file.get_csv_line()
		var result = reg.search(csv[0])
		if result:
			var cat_name = result.get_string()
			if not cat.has(cat_name):
				cat.append(cat_name)
				cat_t.append(csv[0])
	
	cat.remove(0)
	cat_t.remove(0)
	item_names = cat
	item_ids = cat_t
	file.close()


func search(query:String, start_with = false):
	item_ids = []
	item_names = []
	var file = File.new()
	file.open(csv_path, File.READ)
	var reg = RegEx.new()
	if start_with:
		reg.compile("^"+query.to_lower()+".*")
	else:
		reg.compile(".*"+query.to_lower()+".*")
	var i = 0
	while !file.eof_reached():
		var csv = file.get_csv_line()
		var result = reg.search(csv[0].to_lower())
		if result and not item_ids.has(csv[0]) and csv[0] != "assetId":
			item_ids.append(csv[0])
	item_names = item_ids
	file.close()


func _on_setting_button_up():
	$setting.visible = true
	$V.visible = false
