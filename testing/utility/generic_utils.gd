@tool


const FunLib = preload("res://addons/dreadpon.spatial_gardener/utility/fun_lib.gd")




static func get_idx_msg(prefix = "", list_index:int = 0, suffix = ""):
	var string = ""
	prefix = str(prefix)
	suffix = str(suffix)
	
	if prefix.length() > 0:
		string = prefix + string + " "
	
	if list_index >= 0:
		string += "#_%d" % [list_index]
	else:
		string += "ALL"
	
	if suffix.length() > 0:
		string = string + " " + suffix
	
	return string


# This will hang if there is a circular object ref
static func gather_properties(prop_val, allowed_nested_classes:Array):
	var element_to_add = null
	
	if is_instance_of(prop_val, Object):
		if prop_val.has_meta("class") && allowed_nested_classes.has(prop_val.get_meta("class")):
			element_to_add = {}
			for nested_prop in prop_val._get_prop_dictionary():
				element_to_add[nested_prop] = gather_properties(prop_val.get(nested_prop), allowed_nested_classes)
		else:
			element_to_add = str(prop_val)
	elif prop_val is Array:
		element_to_add = []
		for element in prop_val:
			element_to_add.append(gather_properties(element, allowed_nested_classes))
	elif prop_val is Dictionary:
		element_to_add = {}
		for key in prop_val.keys():
			var val = prop_val[key]
			element_to_add[key] = gather_properties(val, allowed_nested_classes)
	else:
		element_to_add = prop_val
	
	return element_to_add




static func find_discrepancies(list_index:int, given:Dictionary, ref:Dictionary, logger, text) -> bool:
	var discrepancies := check_values(given, ref)
	
	logger.info(get_idx_msg("", list_index, "found '%d' discrepancies %s" % [discrepancies.size(), text]))
	
	if !discrepancies.is_empty():
		for discrepancy in discrepancies:
			logger.info(get_idx_msg("", list_index, discrepancy))
		return true
	return false


static func check_values(given, ref) -> Array:
	var discrepancies = []
	
	if typeof(ref) != typeof(given):
		discrepancies.append(
			Discrepancy.new("'given' and 'ref' have unmatching types"))
	
	elif ref is Array:
		if !(given is Array):
			discrepancies.append(
				Discrepancy.new("'given' has wrong type (should be 'Array')"))
		else:
			if ref.size() != given.size():
				discrepancies.append(
					Discrepancy.new("'given' has wrong array size '%d' (should be '%d')" % [given.size(), ref.size()]))
			for i in range(0, ref.size()):
				if given.size() <= i: continue
				
				var ref_element = ref[i]
				var given_element = given[i]
				var inner_discrepancies = check_values(ref_element, given_element)
				for inner_discrepancy in inner_discrepancies:
					inner_discrepancy.prepend_path("[%d]" % [i])
				discrepancies.append_array(
					inner_discrepancies)
	
	elif ref is Dictionary:
		if !(given is Dictionary):
			discrepancies.append(
				Discrepancy.new("'given' has wrong type (should be 'Dictionary')"))
		else:
			if ref.size() != given.size():
				discrepancies.append(
					Discrepancy.new("'given' has wrong dictionary size '%d' (should be '%d')" % [given.size(), ref.size()]))
			for key in given.keys():
				if !ref.has(key):
					discrepancies.append(
						Discrepancy.new("'given' has an extra dictionary key '%s'" % [str(key)]))
			for key in ref.keys():
				if !given.has(key):
					discrepancies.append(
						Discrepancy.new("'given' doesn't have a dictionary key '%s'" % [str(key)]))
					continue
				var ref_element = ref[key]
				var given_element = given[key]
				var inner_discrepancies = check_values(ref_element, given_element)
				for inner_discrepancy in inner_discrepancies:
					inner_discrepancy.prepend_path("[%s]" % [str(key)])
				discrepancies.append_array(
					inner_discrepancies)
	
	else:
		if ref != given:
			discrepancies.append(
				Discrepancy.new("'given' is not equal to 'ref' ('%s' != '%s')" % [str(given), str(ref)]))
	
	return discrepancies


static func load_sequential_resources_in_array(load_path:String, base_filename:String):
	var resources = []
	
	var i = 0
	var full_path = "%s/%s%d.tres" % [load_path, base_filename, i]
	while ResourceLoader.exists(full_path):
		resources.append(FunLib.load_res(load_path, base_filename + "%d.tres" % [i]))
		i += 1
		full_path = "%s/%s%d.tres" % [load_path, base_filename, i]
	
	return resources


static func get_action_intervals(action_count:int) -> Array:
	var intervals := []
	if action_count == 0:
		intervals = []
	elif action_count == 1:
		intervals = [0, 1]
	elif action_count == 2:
		intervals = [1, 0, 2]
	else:
		intervals = [floor(action_count / 3.0), floor(action_count / 3.0 * 2.0), 0, action_count]
	
	return intervals




class Discrepancy extends RefCounted:
	var error:String = ""
	var path:String = ""
	
	
	func _init(_error:String = "", _path:String = ""):
		error = _error
		path = _path
	
	
	func prepend_path(_path:String):
		if path != "":
			path = path.insert(0, _path + "->")
		else:
			path = path.insert(0, _path)
	
	
	func _to_string():
		return "[%s:\n	%s]" % [path, error]
