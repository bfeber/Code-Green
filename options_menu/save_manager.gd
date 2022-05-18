extends Node


@onready var config = ConfigFile.new()


func _ready():
	config.load("user://options.cfg")


func get_config_value(tab: String, option: String, default_value: Variant) -> Variant:
	if not config.has_section_key(tab, option):
		if default_value == null:
			return null
		else:
			config.set_value(tab, option, default_value)
	return config.get_value(tab, option)


func remove_config_value(tab: String, option: String):
	config.erase_section_key(tab, option)
	save_config_file()


func set_config_value(new_value: Variant, tab: String, option: String):
	config.set_value(tab, option, new_value)
	save_config_file()


func save_config_file():
	config.save("user://options.cfg")


func restore_defaults(tab: String):
	if config.has_section(tab):
		config.erase_section(tab)
