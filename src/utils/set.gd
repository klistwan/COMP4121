class_name Set
extends RefCounted

var elements: Dictionary = {}


# Add an element to the set
func add(element: Variant):
	elements[element] = true


# Remove an element from the set
func remove(element: Variant):
	if element in elements:
		elements.erase(element)


# Check if an element is in the set
func contains(element: Variant) -> bool:
	return element in elements


# Get the number of elements in the set
func size() -> int:
	return elements.size()


# Get a list of all elements in the set
func to_list() -> Array[Variant]:
	return elements.keys()


# Clear the set
func clear() -> void:
	elements = {}


# Union of two sets
func union(other_set: Set) -> Set:
	var new_set: Set = Set.new()
	new_set.elements = elements.duplicate()
	for element in other_set.to_list():
		new_set.add(element)
	return new_set


# Intersection of two sets
func intersection(other_set: Set) -> Set:
	var new_set: Set = Set.new()
	for element in other_set.to_list():
		if contains(element):
			new_set.add(element)
	return new_set


# Difference of two sets
func difference(other_set: Set) -> Set:
	var new_set: Set = Set.new()
	for element in to_list():
		if not other_set.contains(element):
			new_set.add(element)
	return new_set


# Check if this set is a subset of another set
func is_subset(other_set: Set) -> bool:
	for element in to_list():
		if not other_set.contains(element):
			return false
	return true


# Check if this set is equal to another set
func equals(other_set: Set) -> bool:
	return is_subset(other_set) and other_set.is_subset(self)


func _to_string() -> String:
	var elements_str = []
	for element in elements.keys():
		elements_str.append(str(element))
	return "Set{" + ", ".join(elements_str) + "} with size " + str(len(elements_str))
