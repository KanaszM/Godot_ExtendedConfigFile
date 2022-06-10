# Godot_ExtendedConfigFile
This scene is designed to work as a singleton in the autoload section of the Godot Engine and can be used to store Variant values on the filesystem using INI-style formatting.

## Use-case examples:
```gdscript
# We must keep in mind that the Config scene is set as singleton in order to be called globally.
# The ConfigFile is already opened by default on startup before the code bellow assinged as the Main Scene is run.

var dTestDefaultConfig: Dictionary = {
	INVALID_SECTION = { # Will warn the user that this section is not supported and will be discarded
		Test01INV = 000},
	DEFAULT = {
		Test01 = 123,
		Test02 = 1.23,
		Test03 = "abc",
		Test04 = false,
		Test05 = Vector2(1.2, 3.4),
		Test06 = Transform2D(1.2, Vector2(3.4, 5.6)),
		Test07 = Rect2(Vector2(1.2, 3.4), Vector2(1.2, 3.4)),
		Test08 = [123, 1.23, "abc", false, Vector2(1.2, 3.4)],
		Test09 = PoolStringArray(["a", "b", "c"]),
		Test10 = PoolIntArray([1, 2, 3]),
		Test11 = PoolRealArray([1.2, 3.4, 5.6]),
		Test12 = Color.cyan,
		Test13 = PoolColorArray([Color.cyan, Color.aqua, Color.bisque]),
		Test14 = {1: "a", "2": 3, Vector2.ONE: 4},
		Test15 = PoolVector2Array([Vector2(1.2, 3.4), Vector2(1.2, 3.4)])},
	MAX = {
		Test01 = 10},
	MIN = {
		Test03 = "abc", # Will warn the user that this value is not numeric and will be discarded
		Test03MIN = 2.3, # Will warn the user that this key does not exist in the DEFAULT section and will be discarded
		Test01 = 1,
		Test02 = 0.0}}

func _ready() -> void:
	Config.Set_Default_SectionKeys(dTestDefaultConfig) # Register the default section / keys to the ConfigFile
	PrintAllConfigFileTestKeys(1, 20) # Output the ConfigFile contents
	Config.Set_Value("Test01", 9) # This call will set the number 9 to the key Test01
	Config.Set_Value("Test01", 3, Config.NUMERIC_ALTER_MODE.INCREMENT) # This call will increment the value stored on key Test01 by 3
	Config.Set_Value("Test01", 5, Config.NUMERIC_ALTER_MODE.DECREMENT) # This call will decrement the value stored on key Test01 by 5
	Config.Set_Value("Test01", "33") # This call will try to store a string value on a key that has an default int value store. It will be discarded
	Config.Set_Value("Test0100", "33") # This call will try to assign the "33" string value on a key that does not exist. It will be discarded
	Config.Reset_Values() # Reset all VALUES to their DEFAULT counterparts

func PrintAllConfigFileTestKeys(_min_key: int = 1, _max_key: int = dTestDefaultConfig.DEFAULT.size()) -> void:
	for _idx in range(1 if _min_key < 1 else _min_key, _max_key + 1):
		var _key: String = str("Test" + ("0" if _idx < 10 else "") + str(_idx))
		var _value = Config.Get_Value(_key)
		if _value != null:
			var _type: int = typeof(_value)
			print("Key: " + _key + " / Value: " + str(_value) + " / Type: " + str(_type))
```
