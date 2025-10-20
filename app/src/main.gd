# SPDX-FileCopyrightText: (c) NOI Techpark <digital@noi.bz.it>

# SPDX-License-Identifier: AGPL-3.0-or-later

extends Control

# column keys are case-insensitive
const ID_KEY: String = "id"
const DATE_KEY: String = "date"
const TIME_KEY: String = "hour" 
const TITLE_KEY: String = "title"
const ROOM_KEY: String = "room"
const TRACK_KEY: String = "tracks"
const STATUS_KEY: String = "status"
const SPEAKER_KEY: String = "speakers"
const PDF_LINK_KEY: String = "pdf presentation"


@onready var file_dialog: FileDialog = $WebsiteFileDialog

@onready var progress_label: Label = $Result/ProgressLabel
@onready var statistics_label: Label = $Result/Statistics
@onready var progress_bar: ProgressBar = $Result/ProgressBar
@onready var http: HTTPRequest = $HTTPRequest
@onready var result_container: VBoxContainer = $Result

@onready var errors: RichTextLabel = $Result/Errors
@onready var event_log: RichTextLabel = $Result/Log

@onready var settings: VBoxContainer = $Settings
@onready var example: Label = $Settings/Example

@onready var time_checkbox: CheckBox = $Settings/PdfConfig/TimeCheckbox
@onready var title_checkbox: CheckBox = $Settings/PdfConfig/TitleCheckBox

@onready var submit: Button = $Settings/Submit

var keys_index: Dictionary = {
	ID_KEY: -1,
	DATE_KEY: -1,
	TIME_KEY: -1,
	TITLE_KEY: -1,
	ROOM_KEY: -1,
	TRACK_KEY: -1,
	STATUS_KEY: -1,
	SPEAKER_KEY: -1,
	PDF_LINK_KEY: -1,
}

var day_mapping: Dictionary = {}

var pdf_path: String

# stores the csv combined data
var data: Dictionary = {}
var counter_done: int = 0
var counter_pdf: int = 0
var counter_total: int = 0

var config: ConfigFile

var include_title: bool
var include_time: bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_load_config()
	
	time_checkbox.button_pressed = include_time
	title_checkbox.button_pressed = include_title
	
	# load saved pdf path, if exists
	if not pdf_path.is_empty():
		file_dialog.current_path = pdf_path
	
	_update_example()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if counter_done < counter_pdf:
		progress_label.text = "Downloading %d of %d..."%[counter_done, counter_pdf]
	elif counter_pdf == 0:
		progress_label.text = "No PDF generated, probably somehting went wrong.\nPlease restart."
	else:
		progress_label.text = "Finished! Happy SFSCON :-)"
	progress_bar.value = counter_done


func _load_config() -> void:
	config = ConfigFile.new()
	config.load("user://settings.cfg")
	pdf_path = config.get_value("settings", "pdf_path", "")
	include_title = config.get_value("settings", "include_title", true)
	include_time = config.get_value("settings", "include_time", true)


func _save_config(path: String) -> void:
	pdf_path = path + "/"
	config.set_value("settings", "pdf_path", pdf_path)
	config.set_value("settings", "include_title", include_title)
	config.set_value("settings", "include_time", include_time)
	config.save("user://settings.cfg")


func _on_website_file_dialog_file_selected(path: String) -> void:
	settings.hide()
	_save_config(path.get_base_dir())
	
	_read_csv(path)
	_assign_day_mapping()
	
	_download_pdfs()
	
	result_container.show()


func _read_csv(path: String) -> void:
	var file:FileAccess = FileAccess.open(path, FileAccess.READ)
	
	# search for key index values on header row
	var header_line: PackedStringArray = file.get_csv_line()
	
	var headers: Array[String] = []
	# transofrm to array and make lower case
	for header: String in header_line:
		headers.append(header.to_lower())
	
	for key: String in keys_index.keys():
		keys_index[key] = headers.find(key.to_lower())
	
	var line_number: int = 0
	while not file.eof_reached():
		var line: Array = file.get_csv_line()
		if line.size() > 1:
			# check if line is big enough
			# append next line
			while line.size() < headers.size():
				# stop if end of file
				if file.eof_reached():
					break
				line.append(file.get_csv_line())

			print("line number %d" % line_number)
			line_number += 1
			var id: String = line[keys_index[ID_KEY]]
			if _is_approved(line):
				var pdf_link: String = line[keys_index[PDF_LINK_KEY]]
				var title: String = line[keys_index[TITLE_KEY]]
				var date: String = line[keys_index[DATE_KEY]]
				
				counter_total += 1
				
				if pdf_link.begins_with("https://www.sfscon.it/wp-content/uploads/"):
					data[id] = {}
					data[id]["pdf_link"] = pdf_link
					data[id]["speaker"] = str(line[keys_index[SPEAKER_KEY]]).validate_filename()
					data[id]["time"] = line[keys_index[TIME_KEY]].substr(0,5).replace(":", "")
					data[id]["date"] = date
					data[id]["title"] = title
					data[id]["track"] = line[keys_index[TRACK_KEY]]
					data[id]["room"] = _clean_room(line[keys_index[ROOM_KEY]])
					counter_pdf += 1
				else:
					errors.append_text(str(errors.get_line_count()) + ") " + title + "\n")
			else:
				data.erase(id)


func _assign_day_mapping() -> void:
	# TREMENDOUS HACK, don't try this at home, these stunts are performed by trained professionals
	# convert dates into day 1, day 2, day 3...
	var dates_unix: Array[int] = []
	for talk_id: String in data.keys():
		var talk: Dictionary = data[talk_id]
		var date: String = talk["date"]
		var iso_date: String = _convert_to_iso_date(date)
		var date_unix: int = Time.get_unix_time_from_datetime_string(iso_date)
		
		if not dates_unix.has(date_unix):
			dates_unix.append(date_unix)
	
	# sort dates_unix to assign day_mapping with Day 1, Day 2...
	dates_unix.sort()
	var day_counter: int = 1
	for date_unix: int in dates_unix:
		var date_str: String = Time.get_date_string_from_unix_time(date_unix)
		day_mapping[date_str] = "Day " + str(day_counter)
		day_counter += 1

	# assign day
	for talk_id: String in data.keys():
		var talk: Dictionary = data[talk_id]
		var date: String = talk["date"]
		var iso_date: String = _convert_to_iso_date(date)
		talk["day"] = day_mapping[iso_date]


# removes all html tags
func _clean_room(room: String) -> String:
	if room.is_empty():
		return room

	# check if string contains <> <> tags
	if room.count("<") < 2 or room.count(">") < 2:
		return room

	var splitted_room: PackedStringArray = room.split(">")
	if splitted_room.size() < 2:
		return room
	splitted_room = splitted_room[1].split("<")

	return splitted_room[0]


# convert format in csv file 31/12/24 to ISO 8601 format 2024-12-31
func _convert_to_iso_date(date: String) -> String:
	var date_parts: PackedStringArray = date.split("/")
	var date_dict: Dictionary = {
		"day": int(date_parts[0]),
		"month": int(date_parts[1]),
		"year": int(date_parts[2]),
	}
	var unix_time: int = Time.get_unix_time_from_datetime_dict(date_dict)
	var iso_date: String = Time.get_date_string_from_unix_time(unix_time)
	return iso_date


func _download_pdfs() -> void:
	progress_bar.max_value = counter_pdf
	statistics_label.text = "Total: %d  -  Pdf: %d  -  No Pdf: %d"%[counter_total, counter_pdf, counter_total - counter_pdf]
	
	for id in data.keys():
		if data[id].has("pdf_link") and data[id]["pdf_link"].begins_with("https://www.sfscon.it/wp-content/uploads/"):
			if http.request_completed.is_connected(_request_completed):
				http.request_completed.disconnect(_request_completed)
			http.request_completed.connect(_request_completed.bind(data[id]))
			var error = http.request(data[id]["pdf_link"])
			if error != OK:
				print(error)
			await http.request_completed
		else:
			errors.append_text(str(errors.get_line_count()) + ") " + data[id]["title"] + "\n")


# callback when http request for PDF downlaod is finished
func _request_completed(_result, _response_code, _headers, body: PackedByteArray, talk: Dictionary) -> void:
	if talk["track"].length() == 0:
		print("Talk with no room assigned: \n" + talk["title"])
		counter_done += 1
		return
	
	var dir_name: String = talk["day"]  + " - " + talk["room"] + " - " + talk["track"]
	var base_path: String = _prepare_dir(pdf_path, dir_name)
	
	var file_name: String = _format_file_name(talk["time"], talk["title"], talk["speaker"])
	
	var file_path: String = "%s/%s"%[base_path, file_name]
	# remove new lines, double points and tabs
	file_path = file_path.replace("..",".")
	
	event_log.append_text(str(counter_done + 1) + ") Saving: " + file_path + "\n")
	
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		event_log.append_text(str(counter_done + 1) + ") ERROR while saving" + file_path + "\n")
		return

	file.store_buffer(body)
	file.flush()
	
	if not FileAccess.file_exists(file_path):
		event_log.append_text(str(counter_done + 1) + ") " + file_path + "\n")
	counter_done += 1


func _prepare_dir(base_path: String, path: String) -> String:
	var dir = DirAccess.open(base_path)
	if not dir.dir_exists(base_path + path):
		dir.make_dir(base_path + path)
	dir.change_dir(base_path + path)
	return base_path + path


func _get_day(day: String) -> String:
	if day_mapping.has(day):
		return day_mapping[day]
	return "TBD"


func _is_approved(line: Array) -> bool:
	var date: String = line[keys_index[DATE_KEY]]
	var time: String = line[keys_index[TIME_KEY]]
	if date == "✗":
		return false
	if time == "✗":
		return false
	return true


func _update_example() -> void:
	var time: String = "1030"
	var title: String = "Talk about $$$"
	var speaker: String = "Märio Rössi"
	
	example.text = _format_file_name(time, title, speaker)


func _format_file_name(time: String, title: String, speaker: String) -> String:
	if not include_time:
		time = ""
	if not include_title:
		title = ""
	else:
		title = title.validate_filename()
	
	speaker = speaker.validate_filename()
	
	var text: String = ""
	if include_time:
		text = time + " - "
	text += speaker
	if include_title:
		text  += " - " + title
	text += ".pdf"
	
	# other escapes
	text = text.replace("/"," ")
	text = text.strip_escapes()
	text = text.strip_edges()
	
	return text


func _is_valid_date(date: String) -> bool:
	var time: int = Time.get_unix_time_from_datetime_string(date)
	return time > 0


##########################
# buttons/checkboxes events
##########################

func _on_time_checkbox_toggled(button_pressed) -> void:
	include_time = button_pressed
	_update_example()


func _on_title_check_box_toggled(button_pressed) -> void:
	include_title = button_pressed
	_update_example()


func _on_submit_pressed() -> void:
	file_dialog.show()


func _on_restart_pressed() -> void:
	get_tree().change_scene_to_file("res://src/main.tscn")
