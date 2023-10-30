extends Control

@onready var file_dialog:FileDialog = $WebsiteFileDialog
@onready var progress_label:Label = $Result/ProgressLabel
@onready var progress_bar:ProgressBar = $Result/ProgressBar
@onready var http:HTTPRequest = $HTTPRequest
@onready var errors:RichTextLabel = $Result/Errors

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
	file_dialog.show()

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
	pdf_path = _prepare_dir(path.substr(0, path.rfind("/")) , "/PDF/")
	
	var file:FileAccess = FileAccess.open(path, FileAccess.READ)
	while not file.eof_reached():
		var line:Array = file.get_csv_line()
		if line.size() > 1:
			var pdf_link:String = line[WEBSITE_PDF_LINK_INDEX]
			var title:String = line[WEBSITE_TITLE_INDEX]
			var id:String = line[WEBSITE_ID_INDEX]
			if not data.has(id):
				log_error("No match found for: \n" + title)
			elif pdf_link.begins_with("https://www.sfscon.it/wp-content/uploads/"):
				data[id]["pdf_link"] = pdf_link
				data[id]["name"] = line[WEBSITE_NAME_INDEX]
				data[id]["time"] = line[WEBSITE_TIME_INDEX].substr(0,5)
				counter_all += 1
	progress_bar.max_value = counter_all
	_download_pdfs()

func _download_pdfs() -> void:
	for id in data.keys():
		if data[id].has("pdf_link") and data[id]["pdf_link"].begins_with("https://www.sfscon.it/wp-content/uploads/"):
			if http.request_completed.is_connected(_request_completed):
				http.request_completed.disconnect(_request_completed)
			http.request_completed.connect(_request_completed.bind(data[id]))
			var error = http.request(data[id]["pdf_link"])
			if error != OK:
				log_error(error)
			await http.request_completed
		else:
			log_error("No PDF found for: \n" + data[id]["title"])

func _request_completed(result, response_code, headers, body, talk:Dictionary) -> void:
	if talk["track"].length() == 0:
		log_error("Talk with no room assigned: \n" + talk["title"])
		counter_done += 1
		return
	var dir_name:String = talk["room"] + " - " + talk["track"]
	_prepare_dir(pdf_path, dir_name)

	# 1030 - Simon Dalvai - Developers track
	var file_name:String = pdf_path + dir_name + "/" + talk["time"] + " - " + talk["name"] + " - " + talk["title"]
	var file:FileAccess = FileAccess.open(file_name, FileAccess.WRITE)
	file.store_buffer(body)
	file.flush()
	counter_done += 1

func _prepare_dir(base_path:String, path:String) -> String:
	var dir = DirAccess.open(base_path)
	if not dir.dir_exists(base_path + path):
		dir.make_dir(base_path + path)
	dir.change_dir(base_path + path)
	return base_path + path

func log_error(error:String) -> void:
	errors.append_text(error + "\n\n")
