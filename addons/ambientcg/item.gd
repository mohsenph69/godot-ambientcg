tool
extends HBoxContainer

var resource_filesystem:EditorFileSystem = null

onready var get_info_http = $get_info
onready var get_img_http = $get_img
onready var label = $V/Label
onready var label_anim = $V/Label/anim
onready var preview_img_rect = $TextureRect
onready var downloader_root = $V
var downloader_res = preload("res://addons/ambientcg/downloader.tscn")
var icon_round = preload("res://addons/ambientcg/asset/Icon-round.png")

var setting = null
var id = ""


var preview_img_link = ""

func get_item():
	get_info()
	label.text = "Loading ..."
	label_anim.play("loading")
	preview_img_rect.texture = icon_round



func get_info():
	var req = "https://ambientcg.com/api/v2/full_json?include=downloadData,imageData&id=" + id 
	get_info_http.request(req)

func _on_get_info_request_completed(result, response_code, headers, body):
	if result != 0:
		print("Fail connection with result " + str(result))
		get_info()
		return
	label_anim.stop()
	label.percent_visible = 1
	label.text = id
	var json = JSON.parse(body.get_string_from_utf8())
	var download_folder = json.result.foundAssets[0].downloadFolders.default.downloadFiletypeCategories
	var downloads = []
	if download_folder.has("exr"):
		downloads = download_folder.exr.downloads
	elif download_folder.has("zip"):
		downloads = download_folder.zip.downloads
	for d in downloads:
		create_downloader(d)
	preview_img_link = json.result.foundAssets[0].previewImage['512-PNG']
	get_img_http.request(preview_img_link)


func _on_get_img_request_completed(result, response_code, headers, body):
	if result != 0:
		print("Fail connection with result " + str(result))
		get_img_http.request(preview_img_link)
		return
	var img = Image.new()
	var err = img.load_png_from_buffer(body)
	if err != OK:
		print("Can not load Image")
		return
	var tex = ImageTexture.new()
	tex.create_from_image(img)
	preview_img_rect.texture = tex
	
func create_downloader(info):
	var downloader = downloader_res.instance()
	downloader.resource_filesystem = resource_filesystem
	downloader.setting = setting
	downloader.id = id
	downloader.attribute = info.attribute
	downloader.download_link = info.fullDownloadPath
	downloader.file_name = info.fileName
	downloader.filetype = info.filetype
	if info.has("zipContent"):
		downloader.content = info.zipContent
	downloader.filesize = info.size
	downloader_root.add_child(downloader)
	downloader.start()

func has_active_download():
	for i in range(1, downloader_root.get_child_count()):
		if downloader_root.get_child(i).downloading:
			return true
	return false
