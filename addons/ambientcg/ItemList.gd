tool
extends ItemList

onready var get_asset_root = $get_asset_root
onready var get_thumbnail_root = $get_thumbnail
onready var timer = $Timer
var icon_round = preload("res://addons/ambientcg/asset/Icon-round_small.png")
var download_same_time_limit = 10
var thumnail_num_req = 30

var item_ids = [] # This will send by master node

var thumbnail_uri = {} # A list of thumbnails that should be download with download url
var item_no_uri = []
var downloading = [] # A list of currently downloading thumbnails

var textures_dic = {} # A dictionary with all avilable thumbnail textures

var thumbnail_path = "res://ambientCG/thumbnails/"
var thumnnail_format = ".jpg"

var stop = false

func start():
	stop = false
	thumbnail_uri = {}
	update_icons()
	update_icons_uri()
	get_thumbnail_uri()

func stop():
	stop = true
	for child in get_thumbnail_root.get_children():
		child.queue_free()
	downloading = []

#Update Icone according to texture dictionary
func update_icons():
	var index = -1
	for i in item_ids:
		index += 1
		if get_item_icon(index) != icon_round:
			continue
		elif textures_dic.has(i):
			set_item_icon(index, textures_dic[i])
		

func update_icons_uri():
	item_no_uri = []
	for i in item_ids:
		if not thumbnail_uri.has(i) and not textures_dic.has(i):
			item_no_uri.append(i)

func get_thumbnail_uri():
	if stop:
		return
	var id = "id="
	var i = 0
	var limit = thumnail_num_req
	if item_no_uri.size() < limit:
		limit = item_no_uri.size()
	if limit == 0:
		return
	while i < limit:
		var n = item_no_uri[i]
		if i == limit - 1:
			id += n
		else:
			id += n + ","
		i += 1
	if id == "id=":
		return
	var req = "https://ambientcg.com/api/v2/full_json?limit=100&include=imageData&" + id
	last_req = req
	var http = HTTPRequest.new()
	get_asset_root.add_child(http)
	http.connect("request_completed", self, "_on_get_asset_request_completed", [http])
	http.request(req)

var last_req = ""

func _on_get_asset_request_completed(result, response_code, headers, body, http_obj):
	if result !=0:
		print("Failed connection with result " + str(result))
		print(last_req)
	else:
		var json = JSON.parse(body.get_string_from_utf8())
		if json.result != null:
			if json.result.has("foundAssets"):
				for asset in json.result.foundAssets:
					var id = asset.assetId
					var pre_img = asset.previewImage
					var keys = pre_img.keys()
					thumbnail_uri[id] = pre_img[keys[0]]
		call_deferred("update_icons_uri")
	call_deferred("get_thumbnail_uri")
	http_obj.queue_free()


func update_download_req():
	var keys = thumbnail_uri.keys()
	for k in keys:
		if downloading.size() >= download_same_time_limit:
				return
		elif downloading.has(k) or textures_dic.has(k):
			continue
		else:
			downloading.append(k)
			var http = HTTPRequest.new()
			get_thumbnail_root.add_child(http)
			http.connect("request_completed", self, "download_request_completed", [http, k])
			#http.download_file = thumbnail_path + k + thumnnail_format
			http.request(thumbnail_uri[k])

func download_request_completed(result, response_code, headers, body, http_obj, id):
	if result != 0:
		downloading.erase(id)
		print("Fail to download")
		return
	var img = Image.new()
	var error = img.load_jpg_from_buffer(body)
	if error != OK:
		push_error("Can not load IMG")
	else:
		var t = ImageTexture.new()
		t.create_from_image(img)
		textures_dic[id] = t
		update_icons()
	downloading.erase(id)
	#print("Finish downloading " + id)
	http_obj.queue_free()
	

func _on_Timer_timeout():
	update_download_req()
	#print(downloading)


func _on_get_button_up():
	print("thumbnails URI " + str(thumbnail_uri.size()))
