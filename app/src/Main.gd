extends Control

@onready var website_file_dialog:FileDialog = $WebsiteFileDialog
@onready var schedule_file_dialog:FileDialog = $ScheduleFileDialog
@onready var pdf_file_dialog:FileDialog = $PdfFileDialog
@onready var progress_label:Label = $Progress/ProgressLabel
@onready var progress_bar:ProgressBar = $Progress/ProgressBar


const PDF_LINK_INDEX = 14

var website_csv:Array[String]
var schedule_csv:Array[String]
var pdf_path:String

# stores the csv combined data
var data:Dictionary = {}

# found errors
var errors:Array[String] = []

var counter_done:int = 0
var counter_all:int = 0


func _process(delta) -> void:
	if counter_done < counter_all:
		progress_label.text = "Downloading %d of %d..."%[counter_done, counter_all]
	else:
		progress_label.text = "Finished! Happy SFSCON :-)"
	progress_bar.value = counter_done

func _on_website_file_dialog_file_selected(path) -> void:
	print("website path ", path)
	
	var file:FileAccess = FileAccess.open(path, FileAccess.READ)
	# skip header lines
	data["pdf"] = []
	
	while not file.eof_reached():
		var line:Array = file.get_csv_line()
		if line.size() >= PDF_LINK_INDEX:
			var pdf_link:String = line[PDF_LINK_INDEX]
			if pdf_link.begins_with("https://www.sfscon.it/wp-content/uploads/"):
				data["pdf"].append(pdf_link)
				counter_all += 1
#		website_csv.append(line)

	progress_bar.max_value = counter_all
	schedule_file_dialog.show()


func _on_schedule_file_dialog_file_selected(path) -> void:
	print("schedule path ", path)
	
	var file:FileAccess = FileAccess.open(path, FileAccess.READ)
	# skip header lines
	while not file.eof_reached():
		var line:Array = file.get_csv_line()
#		schedule_csv.append(line)
	
	_match_csv()
	
	pdf_file_dialog.show()


func _on_pdf_file_dialog_dir_selected(dir) -> void:
	print("pdf path ", dir)
	_download_pdfs(dir)

	
func _match_csv() -> void:
	pass

func _download_pdfs(destination_path:String) -> void:
	print(data["pdf"])
	var counter = 0
	for link in data["pdf"]:
		print(link)
		var http:HTTPRequest = HTTPRequest.new()
		add_child(http)
		var data = http.request(link)
		http.request_completed.connect(_request_completed.bind(destination_path + "/" + str(counter) + ".pdf"))
		counter += 1

func _request_completed(result, response_code, headers, body, file) -> void:
	print("save ", file)
	var directory:FileAccess = FileAccess.open(file, FileAccess.WRITE)
	directory.store_buffer(body)
	directory.flush()
	counter_done += 1
