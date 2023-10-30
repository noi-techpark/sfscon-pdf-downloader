extends Control

@onready var website_data_file_dialog:FileDialog = $WebsiteFileDialog
@onready var progress_label:Label = $Progress/ProgressLabel
@onready var progress_bar:ProgressBar = $Progress/ProgressBar
@onready var http:HTTPRequest = $HTTPRequest


# can't be csv, because Godot treats csv files as translations
const MAPPING_FILE = "res://SFSCON-mapping.txt"

const WEBSITE_ID_INDEX = 0
const WEBSITE_DATE_INDEX = 2
const WEBSITE_TIME_INDEX = 3
const WEBSITE_TITLE_INDEX = 4
const WEBSITE_STATUS_INDEX = 6
const WEBSITE_NAME_INDEX = 8
const WEBSITE_PDF_LINK_INDEX = 14

const MAPPING_ID_INDEX = 0
const MAPPING_ROOM_INDEX = 4
const MAPPING_TRACK_INDEX = 5
const MAPPING_TITLE_INDEX = 6

var pdf_path:String

# stores the csv combined data
var data:Dictionary = {}
var counter_done:int = 0
var counter_all:int = 0

func _ready() -> void:
	_read_mapping()

func _process(delta) -> void:
	if counter_done < counter_all:
		progress_label.text = "Downloading %d of %d..."%[counter_done, counter_all]
	else:
		progress_label.text = "Finished! Happy SFSCON :-)"
	progress_bar.value = counter_done

func _read_mapping() -> void:
	var file:FileAccess = FileAccess.open(MAPPING_FILE, FileAccess.READ)
	
	while not file.eof_reached():
		var line:Array = file.get_csv_line()
		if line.size() > 1:
			var id:String = line[MAPPING_ID_INDEX]
			data[id] = {}
			data[id]["title"] = line[MAPPING_TITLE_INDEX]
			data[id]["room"] = line[MAPPING_ROOM_INDEX]
			data[id]["track"] = line[MAPPING_TRACK_INDEX]

func _on_website_file_dialog_file_selected(path) -> void:
	# get directory of path for final pdf export location
	var base_path:String = path.substr(0, path.rfind("/"))
	_prepare_dir(base_path , "/PDF")
	pdf_path = base_path + "/PDF/"
	
	var file:FileAccess = FileAccess.open(path, FileAccess.READ)
	while not file.eof_reached():
		var line:Array = file.get_csv_line()
		if line.size() > 1:
			var pdf_link:String = line[WEBSITE_PDF_LINK_INDEX]
			var title:String = line[WEBSITE_TITLE_INDEX]
			var id:String = line[WEBSITE_ID_INDEX]
			if not data.has(id):
				print("No match found for: ", title)
			elif pdf_link.begins_with("https://www.sfscon.it/wp-content/uploads/"):
				data[id]["pdf_link"] = pdf_link
				data[id]["name"] = line[WEBSITE_NAME_INDEX]
				data[id]["time"] = line[WEBSITE_TIME_INDEX].substr(0,5)
				counter_all += 1
	progress_bar.max_value = counter_all
	_download_pdfs()

func _download_pdfs() -> void:
	var counter = 0
	for id in data.keys():
		if data[id].has("pdf_link") and data[id]["pdf_link"].begins_with("https://www.sfscon.it/wp-content/uploads/"):
			http.request_completed.connect(_request_completed.bind(data[id]))
			var error = http.request(data[id]["pdf_link"])
			if error != OK:
				print(error)
			counter += 1
			await http.request_completed
		else:
			print("No PDF found for: ", data[id]["title"])

func _request_completed(result, response_code, headers, body, talk:Dictionary) -> void:
	if talk["track"].length() == 0:
		print("Talk with no room assigned: ", talk["title"])
		counter_done += 1
		return
	var dir_name:String = talk["room"] + " - " + talk["track"]
	_prepare_dir(pdf_path, dir_name)

	# 1030 - Simon Dalvai - Developers track
	var file_name:String = pdf_path + dir_name + "/" + talk["time"] + " - " + talk["name"] + " - " + talk["title"]
	print("Save PDF of " + talk.title + " to " + file_name)
	var file:FileAccess = FileAccess.open(file_name, FileAccess.WRITE)
	file.store_buffer(body)
	file.flush()
	counter_done += 1

func _prepare_dir(base_path:String, path:String) -> void:
	var dir = DirAccess.open(base_path)
	if not dir.dir_exists(base_path + path):
		dir.make_dir(base_path + path)
	dir.change_dir(base_path + path)
