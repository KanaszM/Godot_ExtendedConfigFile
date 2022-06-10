extends Node

### THE DEFAULT DATA STRUCTURE TEMPLATE ###
# Used as argument in the Set_Default_SectionKeys method.
# But only after the ConfigFile is opened with the Open_ConfigFile method.
# The Set_Default_SectionKeys will automatically add the VALUES section based on the DEFAULT section.
# The Set_Value and Get_Value methods will read/write data from the VALUES section.
# The MIN and MAX optional sections and represents the bounding limits of int and/or real values
# that are also present in the DEFAULT section. They can be used to limit value setting with or without the NUMERIC_ALTER_MODE options.
# The DESC optional section is used to store additional information / descriptions of the values present in the ConfigFile.
# Default data structure template:
#const dDefaultData: Dictionary = {
#	DEFAULT = {},
#	MIN = {},
#	MAX = {},
#	DESC = {}}

### DATA ###
export(bool) var bEnableConfigFile: bool = true # If false, all methods present in this script will be ignored
onready var nCFG: ConfigFile = ConfigFile.new() # The object that will hold all the ConfigFile data on memory
var bSavedOnExit: bool = false # Needed so that the file won't be saved multiple times on quit

# Used to specify if the value set on the Set_Value method should be incremented or decremented instead of the default set behaviour.
enum NUMERIC_ALTER_MODE {INCREMENT, DECREMENT, NONE}

# ConfigFile method signals
signal value_changed(_key, _value)
signal values_reseted
signal default_keys_set
signal configfile_opened
signal configfile_saved

# File path data. By default, the directory where the ConfigFile will be saved is in the user data dir
export(String) var sConfigFileName: String = "config"
export(String) var sConfigExtension: String = "cfg"
onready var sPath: String = OS.get_user_data_dir().plus_file(sConfigFileName + "." + sConfigExtension.replace(".", ""))

### EXTENDED CONSTANTS ###
# By user dalexeev on GitHub (https://github.com/godotengine/godot-proposals/issues/2411)
const UINT8_MAX  = (1 << 8)  - 1 # 255
const UINT16_MAX = (1 << 16) - 1 # 65535
const UINT32_MAX = (1 << 32) - 1 # 4294967295

const INT8_MIN  = -(1 << 7)  # -128
const INT16_MIN = -(1 << 15) # -32768
const INT32_MIN = -(1 << 31) # -2147483648
const INT64_MIN = -(1 << 63) # -9223372036854775808

const INT8_MAX  = (1 << 7)  - 1 # 127
const INT16_MAX = (1 << 15) - 1 # 32767
const INT32_MAX = (1 << 31) - 1 # 2147483647
const INT64_MAX = (1 << 63) - 1 # 9223372036854775807

### INIT ###
# The ConfigFile will automatically be saved upon exit. Comment the _notification block to ignore this feature.
func _notification(_what: int) -> void:
	match _what:
		NOTIFICATION_CRASH, NOTIFICATION_WM_QUIT_REQUEST, NOTIFICATION_EXIT_TREE:
			if not bSavedOnExit:
				print("Config | Save result: ", Save_ConfigFile(), " ", _what) ; bSavedOnExit = true

# The ConfigFile will automatically be opened on launch. Comment the _ready block to ignore this feature.
func _ready() -> void:
	# Setup
	print("Config | Open result: ", Open_ConfigFile(), " ", sPath)

### CONFIG FILE SETUP METHODS ###
func Open_ConfigFile() -> bool:
	if bEnableConfigFile:
		var _dir: Directory = Directory.new()
		if not _dir.file_exists(sPath):
			var _file: File = File.new()
			if _file.open(sPath, _file.WRITE) != OK:
				printerr("Config | Open_ConfigFile | Could not open file at path: " + sPath) ; return false
			_file.close()
		if nCFG.load(sPath) != OK:
			printerr("Config | Open_ConfigFile | Could not load file at path: " + sPath) ; return false
	self.emit_signal("configfile_opened")
	return true

func Save_ConfigFile() -> bool:
	if bEnableConfigFile:
		if nCFG.save(sPath) != OK:
			printerr("Config | Open_ConfigFile | Could not save file at path: " + sPath) ; return false
	self.emit_signal("configfile_saved")
	return true

func Set_Default_SectionKeys(_default_sectionkeys: Dictionary) -> bool:
	if not bEnableConfigFile:
		push_warning("Config | Set_Default_SectionKeys | The config file is disabled") ; return false
	# Detect and add new section / key / value data
	if not "DEFAULT" in _default_sectionkeys:
		push_warning("Config | Set_Default_SectionKeys | Missing DEFAULT section") ; return false
	for _section in _default_sectionkeys:
		if not _section in PoolStringArray(["DEFAULT", "MIN", "MAX", "DESC"]):
			push_warning("Config | Set_Default_SectionKeys | Section not valid: " + _section) ; continue
		for _key in _default_sectionkeys[_section]:
			var _value = _default_sectionkeys[_section][_key]
			var _type: int = typeof(_value)
			if (_section == "MIN" or _section == "MAX"):
				if not (_type == TYPE_REAL or _type == TYPE_INT):
					push_warning("Config | Set_Default_SectionKeys | MIN/MAX value is not numeric. Key: " + _key + ", Value: " + str(_value) + ", Type: " + str(_type)) ; continue
				if not _key in _default_sectionkeys.DEFAULT:
					push_warning("Config | Set_Default_SectionKeys | Numeric value key not present in the DEFAULT section: " + _key) ; continue
			if not nCFG.has_section_key(_section, _key): nCFG.set_value(_section, _key, _value)
	# Create the VALUES section if not present
	for _key in _default_sectionkeys.DEFAULT:
		if not nCFG.has_section_key("VALUES", _key): nCFG.set_value("VALUES", _key, _default_sectionkeys.DEFAULT[_key])
	self.emit_signal("default_keys_set")
	return true

### CONFIG FILE VALUE METHODS ###
func Get_Value(_key: String, _from_section: String = "VALUES", _not_found_value = null):
	if not bEnableConfigFile:
		push_warning("Config | Get_Value | The config file is disabled") ; return _not_found_value
	if not nCFG.has_section_key(_from_section, _key):
		printerr("Config | Get_Value | Missing section / key: " + _from_section + " / " + _key) ; return _not_found_value
	return nCFG.get_value(_from_section, _key, _not_found_value)

func Set_Value(_key: String, _value, _alter_numeric_mode: int = -1) -> bool:
	if not bEnableConfigFile:
		push_warning("Config | Set_Value | The config file is disabled") ; return false
	if not nCFG.has_section_key("VALUES", _key):
		printerr("Config | Set_Value | Missing VALUES section and/or key: " + _key) ; return false
	var _type: int = typeof(_value)
	var _default_type: int = typeof(nCFG.get_value("VALUES", _key))
	if _type != _default_type:
		push_warning("Config | Set_Value | The value type: " + str(_type) + " does not match the VALUES type: " + str(_default_type) + " on key: " + _key) ; return false
	if _type == TYPE_INT or _type == TYPE_REAL:
		var _min_int: int = 0
		var _max_int: int = INT32_MAX
		var _min_real: float = 0.0
		var _max_real: float = float(INT32_MAX)
		if nCFG.has_section_key("MIN", _key):
			match _type:
				TYPE_INT:
					_min_int = nCFG.get_value("MIN", _key)
					if _value < _min_int:
						push_warning("Config | Set_Value | The integer value: " + str(_value) + " for key: " + _key + " is lower than MIN: " + str(_min_int)) ; return false
				TYPE_REAL:
					_min_real = nCFG.get_value("MIN", _key)
					if _value < _min_real:
						push_warning("Config | Set_Value | The real value: " + str(_value) + " for key: " + _key + " is lower than MIN: " + str(_min_real)) ; return false
		if nCFG.has_section_key("MAX", _key):
			match _type:
				TYPE_INT:
					_max_int = nCFG.get_value("MAX", _key)
					if _value > _max_int:
						push_warning("Config | Set_Value | The integer value: " + str(_value) + " for key: " + _key + " is higher than MAX: " + str(_max_int)) ; return false
				TYPE_REAL:
					_max_real = nCFG.get_value("MAX", _key)
					if _value > _max_real:
						push_warning("Config | Set_Value | The real value: " + str(_value) + " for key: " + _key + " is higher than MAX: " + str(_max_real)) ; return false
		match _type:
			TYPE_INT:
				var _new_int_value: int = nCFG.get_value("VALUES", _key)
				match _alter_numeric_mode:
					0: _new_int_value += _value
					1: _new_int_value -= _value
					_: _new_int_value = _value
				if _new_int_value < _min_int or _new_int_value > _max_int:
					push_warning("Config | Set_Value | The altered integer value: " + str(_new_int_value) + " for key: " + _key + " is out of bounds MIN: " + str(_min_int) + " / MAX: " + str(_max_int)) ; return false
				nCFG.set_value("VALUES", _key, _new_int_value)
				self.emit_signal("value_changed", _key, _new_int_value)
				return true
			TYPE_REAL:
				var _new_real_value: int = nCFG.get_value("VALUES", _key)
				match _alter_numeric_mode:
					0: _new_real_value += _value
					1: _new_real_value -= _value
					_: _new_real_value = _value
				if _new_real_value < _min_real or _new_real_value > _max_real:
					push_warning("Config | Set_Value | The altered real value: " + str(_new_real_value) + " for key: " + _key + " is out of bounds MIN: " + str(_min_real) + " / MAX: " + str(_max_real)) ; return false
				nCFG.set_value("VALUES", _key, _new_real_value)
				self.emit_signal("value_changed", _key, _new_real_value)
				return true
	nCFG.set_value("VALUES", _key, _value)
	self.emit_signal("value_changed", _key, _value)
	return true

func Reset_Values() -> bool:
	if not bEnableConfigFile:
		push_warning("Config | Reset_Values | The config file is disabled") ; return false
	for _section in PoolStringArray(["VALUES", "DEFAULT"]):
		if not nCFG.has_section(_section):
			printerr("Config | Reset_Values | Missing section: " + _section) ; return false
	for _key in nCFG.get_section_keys("DEFAULT"):
		nCFG.set_value("VALUES", _key, nCFG.get_value("DEFAULT", _key))
	self.emit_signal("values_reseted")
	return true
