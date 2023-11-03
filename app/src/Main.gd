# SPDX-FileCopyrightText: (c) NOI Techpark <digital@noi.bz.it>

# SPDX-License-Identifier: AGPL-3.0-or-later

extends Control

@onready var file_dialog:FileDialog = $WebsiteFileDialog
@onready var progress_label:Label = $Result/ProgressLabel
@onready var progress_bar:ProgressBar = $Result/ProgressBar
@onready var http:HTTPRequest = $HTTPRequest
@onready var errors:RichTextLabel = $Result/Errors

# can't be .csv, because Godot treats csv files as translations
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

const DAY_MAPPING:Dictionary = { 
	"10/11/2023" : "Day 1",
	"11/11/2023" : "Day 2",
}

	# not valid characters in windows paths
const WINDOWS_NONVALID_CHARS:Array[String] = [
		'<',
		'>',
		':',
		'"',
		'\\',
		'|',
		'?',
		'*',
		'(',
		')',
]


var pdf_path:String

# stores the csv combined data
var data:Dictionary = {}
var counter_done:int = 0
var counter_all:int = 0

var config:ConfigFile

func _ready() -> void:
	# load last used path, if exists
	config = ConfigFile.new()
	config.load("user://settings.cfg")
	pdf_path = config.get_value("settings", "pdf_path", "")
	
	_read_mapping()
	
	if not pdf_path.is_empty():
		file_dialog.current_path = pdf_path
	file_dialog.show()

func _process(delta) -> void:
	if counter_done < counter_all:
		progress_label.text = "Downloading %d of %d..."%[counter_done, counter_all]
	elif counter_all == 0:
		progress_label.text = "Something went wrong, restart please"
	else:
		progress_label.text = "Finished! Happy SFSCON :-)"
	progress_bar.value = counter_done

func _read_mapping() -> void:
	var file:FileAccess = FileAccess.open(MAPPING_FILE, FileAccess.READ)
	# skip first line
	file.get_csv_line()
	while not file.eof_reached():
		var line:Array = file.get_csv_line()
		if line.size() > 1:
			var id:String = line[MAPPING_ID_INDEX]
			data[id] = {}
			data[id]["title"] = line[MAPPING_TITLE_INDEX]
			data[id]["room"] = line[MAPPING_ROOM_INDEX]
			data[id]["track"] = line[MAPPING_TRACK_INDEX]

func _on_website_file_dialog_file_selected(path:String) -> void:
	_save_pdf_path(path.get_base_dir())
	
	var file:FileAccess = FileAccess.open(path, FileAccess.READ)
	# skip first line
	file.get_csv_line()
	while not file.eof_reached():
		var line:Array = file.get_csv_line()
		if line.size() > 1 and line[WEBSITE_STATUS_INDEX] == "approved":
			var pdf_link:String = line[WEBSITE_PDF_LINK_INDEX]
			var title:String = line[WEBSITE_TITLE_INDEX]
			var id:String = line[WEBSITE_ID_INDEX]
			var day:String = line[WEBSITE_DATE_INDEX]
			
			if not data.has(id):
				log_error("No match found for: \n" + title)
			elif pdf_link.begins_with("https://www.sfscon.it/wp-content/uploads/"):
				data[id]["pdf_link"] = pdf_link
				data[id]["name"] = line[WEBSITE_NAME_INDEX]
				data[id]["time"] = line[WEBSITE_TIME_INDEX].substr(0,5).replace(":", "")
				data[id]["day"] = _get_day(day)
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
				print(error)
				log_error(error)
			await http.request_completed
		else:
			log_error("No PDF found for: \n" + data[id]["title"])

func _request_completed(result, response_code, headers, body:PackedByteArray, talk:Dictionary) -> void:
	if talk["track"].length() == 0:
		log_error("Talk with no room assigned: \n" + talk["title"])
		counter_done += 1
		return
	
	var dir_name:String = talk["day"]  + " - " + talk["room"] + " - " + talk["track"]
	var path:String = _prepare_dir(pdf_path, dir_name)
	var title:String = talk["title"]
	
#	var regex = RegEx.new()
#	regex.compile("[a-zA-Z\\d\\s:]")
#	title = regex.search(title).get_string()
	
	var file_name:String = "%s/%s - %s.pdf"%[path, talk["time"], talk["name"]]

	
	file_name = file_name.replace("..",".")
	file_name = file_name.replace("\n"," ")
	file_name = file_name.replace("\t","")
	
#	for char in WINDOWS_NONVALID_CHARS:
#		file_name = file_name.replace(char,"")

	
	
	file_name = file_name.simplify_path()
	print(file_name)
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

func _get_day(day:String) -> String:
	if DAY_MAPPING.has(day):
		return DAY_MAPPING[day]
	return "TBD"

func log_error(error:String) -> void:
	errors.append_text(error + "\n\n")

func _save_pdf_path(path:String) -> void:
	pdf_path = path + "/"
	config.set_value("settings", "pdf_path", pdf_path)
	config.save("user://settings.cfg")

func _on_restart_pressed():
	get_tree().change_scene_to_file("res://src/Main.tscn")
