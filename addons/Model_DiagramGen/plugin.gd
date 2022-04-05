tool
extends EditorPlugin

# resource_infos = {"path":"","type":"","node":""}
var Node2Script

# node_infos = {"name":"","type":"","parent":""}
# signal_infos = {"signal":"","from":"","to":"","method":""}
var parsed_lines

var parent_of_nodes_in_file
var current_file
var current_node
var md_file

#------------------------
const KEY_NODES = 0
const KEY_SIGNALS = 1

const TYPE_NODE = 2
const TYPE_SIGNAL = 3
const TYPE_DYNAMIC_NODE = 4
const TYPE_RESOURCE = 5
const TYPE_SCRIPT = 6

const DICT_TYPE_DYNAMIC_NODE = "Dynamic_Node"

const FORMAT_NODE = 8
const FORMAT_SIGNAL = 9
const FORMAT_DYNAMIC_NODE = 10
const FORMAT_MAIN_NODE = 11


func _enter_tree():
	Reset_Parameters()

func _input(event):
	var key_pressed_once = false
	if Input.is_key_pressed(KEY_CONTROL) and Input.is_key_pressed(KEY_G) and not key_pressed_once:
		# Initialization of the plugin goes here.
		key_pressed_once = true
		var parsed_files = Collect_ModelFiles("res://")
		Reset_Parameters()
		
		Parse_ModelFiles(parsed_files)
		Draw_Nodes()
		Draw_Signals()
		Close_MarkdownFile()
		
		print ("res://ModelDocumentation.md generated ")
	key_pressed_once = false

func Reset_Parameters():
	parsed_lines = {KEY_NODES: [],KEY_SIGNALS: []}
	parent_of_nodes_in_file = ""
	Node2Script = []
	current_node = ""
	current_file = ""

func Collect_ModelFiles(scan_dir : String) -> Array:
	var All_files : Array = []
	var Files_tscn : Array = []
	var Files_gd : Array = []
	
	var dir := Directory.new()
	
	if dir.open(scan_dir) != OK:
		printerr("Warning: could not open directory: ", scan_dir)
		return []

	if dir.list_dir_begin(true, true) != OK:
		printerr("Warning: could not list contents of: ", scan_dir)
		return []

	var file_name := dir.get_next()
	while file_name != "":
		if not file_name.begins_with(".") and not file_name==("addons"):
			if dir.current_is_dir():
				All_files += Collect_ModelFiles(dir.get_current_dir() + "/" + file_name)
			else:
				if file_name.ends_with(".tscn") or file_name.ends_with(".gd"):
					All_files.append(dir.get_current_dir() + "/" + file_name)		
		file_name = dir.get_next()
	
	#Sort All_files to process tscn files first then gd files
	for file in All_files:
		if file.ends_with(".tscn"):
			Files_tscn.append(file)
		elif file.ends_with(".gd"):
			Files_gd.append(file)
	
	All_files.clear()
	All_files.append_array(Files_tscn)
	All_files.append_array(Files_gd)
	

	return All_files


func Parse_ModelFiles(parsed_files):
	for file_name in parsed_files:
		var parsed_file = File.new()
		var valid_nodes_info = []
		var valid_signals_info = []

		current_file = file_name		
		parsed_file.open(file_name, File.READ)
			
		while not parsed_file.eof_reached(): # iterate through all lines until the end of file is reached
			var line = parsed_file.get_line()

			if line.begins_with("[ext_resource path="):
				var line_info = Get_LineInfo(line,TYPE_RESOURCE)
				Node2Script.append(line_info)
				
			elif line.begins_with("[node name="):
				var line_info = Get_LineInfo(line,TYPE_NODE)
				if line_info:
					valid_nodes_info.append(line_info)
					current_node = line_info["name"]

			elif line.begins_with("script = ExtResource"):
				Get_LineInfo(line,TYPE_SCRIPT) # update the info inside array Node2Script
				
			elif line.begins_with("[connection signal="):
				var line_info = Get_LineInfo(line,TYPE_SIGNAL)
				if line_info:
					valid_signals_info.append(line_info)

			elif  "add_child(" in line: #to parse Dynamicly created nodes
				var line_info = Get_LineInfo(line,TYPE_DYNAMIC_NODE)
				if line_info:
					valid_nodes_info.append(line_info)

		# Node shall be handled before signals, such that the parent_of_nodes_in_file will get a value
		parsed_lines[KEY_NODES].append_array(Clean_Info(valid_nodes_info,KEY_NODES))
		parsed_lines[KEY_SIGNALS].append_array(Clean_Info(valid_signals_info,KEY_SIGNALS))
		
		parent_of_nodes_in_file = ""
		parsed_file.close()


func Get_LineInfo(line : String, type : int) -> Dictionary:

	if type == TYPE_NODE:
		var node_infos = {"name":"","type":"","parent":""}
		var regex = RegEx.new()
		regex.compile("node name=\"(.*?)\" type=\"(.*?)\"( parent=\"(.*?)\")?")
		var result = regex.search(line)
		if result:
			node_infos["name"] = result.get_string(1)
			node_infos["type"] = result.get_string(2)
			node_infos["parent"] = result.get_string(4)			
			return node_infos
		
		else:
			var regex2 = RegEx.new()
			regex2.compile("node name=\"(.*?)\" parent=\"(.*?)\" instance=(ExtResource(.*))]")
			var result2 = regex2.search(line)

			if result2:
				node_infos["name"] = result2.get_string(1)
				node_infos["parent"] = result2.get_string(2)
				node_infos["type"] = result2.get_string(3)			
				return node_infos
			
	elif type == TYPE_DYNAMIC_NODE:
		var node_infos = {"name":"","type":"","parent":""}
		var regex = RegEx.new()
		regex.compile("\\W?add_child\\((.*?)\\)")
		var result = regex.search(line)

		if result:
			node_infos["name"] = result.get_string(1)
			node_infos["parent"] = "."
			node_infos["type"] = DICT_TYPE_DYNAMIC_NODE
			return node_infos
		
	elif  type == TYPE_SIGNAL:
		var signal_infos = {"signal":"","from":"","to":"","method":""}
		var regex = RegEx.new()
		regex.compile("connection signal=\"(.*?)\" from=\"(.*?)\" to=\"(.*?)\" method=\"(.*?)\"")
		var result = regex.search(line)
		if result:
			signal_infos["signal"] = result.get_string(1)
			signal_infos["from"] = result.get_string(2)
			signal_infos["to"] = result.get_string(3)
			signal_infos["method"] = result.get_string(4)
			return signal_infos
			
	elif  type == TYPE_RESOURCE:
		var resource_infos = {"path":"","type":"","node":""}
		var regex = RegEx.new()
		regex.compile("ext_resource path=\"(.*?)\" type=\"(.*?)\" id=(\\d+)")
		var result = regex.search(line)
		if result:
			resource_infos["path"] = result.get_string(1)
			resource_infos["type"] = result.get_string(2)
			resource_infos["node"] = result.get_string(3)
			return resource_infos
			
	elif type == TYPE_SCRIPT:	
		var regex = RegEx.new()
		regex.compile("script = ExtResource\\( (\\d+) \\)")
		var result = regex.search(line)
		if result:
			for n2s in Node2Script:
				if n2s["node"] == result.get_string(1) and current_node:
					n2s["node"] = current_node
			
	return {}


func Clean_Info(info : Array, key_type : int) -> Array:
	
	if key_type == KEY_NODES:
		for node in info:
			if node["type"] == DICT_TYPE_DYNAMIC_NODE:
				if node["parent"] == "." and current_file != "":
					for n2s in Node2Script:
						if current_file.rsplit("/")[-1] in n2s["path"]:
							node["parent"] = n2s["node"]


			if node["parent"] == "":
				parent_of_nodes_in_file = node["name"]
			elif node["parent"] == "." and parent_of_nodes_in_file != "":
				node["parent"] = parent_of_nodes_in_file
			
			node["parent"] = node["parent"].rsplit("/")[-1]
	
	elif  key_type == KEY_SIGNALS:
		for signal_var in info:
			if signal_var["to"] == "." and parent_of_nodes_in_file != "":
				signal_var["to"] = parent_of_nodes_in_file
			if signal_var["from"] == "." and parent_of_nodes_in_file != "":
				signal_var["from"] = parent_of_nodes_in_file
				
			signal_var["from"] = signal_var["from"].rsplit("/")[-1]
			signal_var["to"] = signal_var["to"].rsplit("/")[-1]

	return info


func Draw_Nodes():
	for node in parsed_lines[KEY_NODES]:
		if node["type"] == DICT_TYPE_DYNAMIC_NODE:
			Draw_MarkdownFile(node["parent"],node["name"],FORMAT_DYNAMIC_NODE,"child")	
		else:	
			Draw_MarkdownFile(node["parent"],node["name"],FORMAT_NODE,"child")	


func Draw_Signals():
	for signal_var in parsed_lines[KEY_SIGNALS]:
		Draw_MarkdownFile(signal_var["from"],signal_var["to"],FORMAT_SIGNAL,signal_var["method"])	


func Create_MarkdownFile():
	md_file = File.new()
	if md_file.file_exists("res://ModelDocumentation.md"):
		printerr("WARNING! ModelDocumentation.md will be overwritten!!!! ")
	md_file.open("res://ModelDocumentation.md", File.WRITE_READ)

	var Heading = """
# **Model Architecture**
## Block Diagram
<style>.mermaid svg { height: auto; }</style> <br>
"""
			
	md_file.store_string(Heading)
	md_file.store_string("\n```mermaid \n flowchart LR \n ")

func Draw_MarkdownFile(from:String, to:String, format:int, text:String):
	var arrow = "--->"
	var from_block_style =""
	var to_block_style ="" #TODO style id2 fill:#bbf,stroke:#f66,stroke-width:2px,color:#fff,stroke-dasharray: 5 5

	if from and to:
		if format == FORMAT_NODE:
			to_block_style = "style "+to+" stroke:#f66,stroke-width:2px"
		elif format == FORMAT_SIGNAL:
			arrow =  "-.->"
		elif format == FORMAT_DYNAMIC_NODE:
			to_block_style = "style "+to+" stroke:#f66,stroke-width:2px,color:#fff,stroke-dasharray: 5 5"
			
		var content = from + "("+ from + ")"  + arrow + " |" + text + "| " + to +  "(" + to + ")" 
		if not md_file or  not md_file.is_open() : Create_MarkdownFile()
		md_file.seek_end()
		md_file.store_string("\n")
		md_file.store_string(content)
		md_file.store_string("\n")
		md_file.store_string(to_block_style)


func Close_MarkdownFile():
	md_file.seek_end()
	md_file.store_string("\n```")
	md_file.close()
	
	Reset_Parameters()


func _exit_tree():
	Reset_Parameters()
