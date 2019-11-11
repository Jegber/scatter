tool
extends PolygonPath

# --
# Scatter Base
# --
# The common parameters shared by ScatterMultimesh and ScatterDuplicate
# are defined here.
# --
#
# --

class_name ScatterBase

## --
## Imported libraries
## --

# TODO : Implement these, but check if this approach couldn't be replaced by a better one first
var UniformDistribution = load("res://addons/scatter/src/distributions/uniform.gd")
var NormalDistribution = load("res://addons/scatter/src/distributions/normal.gd")
var SimplexNoiseDistribution = load("res://addons/scatter/src/distributions/simplex_noise.gd")

## -- 
## Exported variables
## --
export(int) var amount : int = 10 setget _set_amount
export(int, "Uniform", "Normal", "Simplex noise") var distribution : int = 0 setget _set_distribution
export(int) var custom_seed : int = 0 setget _set_seed
export(bool) var project_on_floor : bool = false
export(float) var ray_down_length : float = 10.0
export(float) var ray_up_length : float = 0.0
export(Vector3) var rotation_randomness : Vector3 = Vector3(0.0, 1.0, 0.0) setget _set_rotation_randomness
export(Vector3) var scale_randomness : Vector3 = Vector3.ONE setget _set_scale
export(Vector3) var global_scale : Vector3 = Vector3.ONE setget _set_global_scale

## --
## Internal variables
## --
var _items : Array = Array()
var _exclusion_areas : Array = Array()
var _total_proportion : int
var _distribution : Distribution

## --
## Public methods
## --

# Called from any children when their exported parameters changes
func update():
	pass

## --
## Internal methods
## --

func _ready():
	self.connect("curve_updated", self, "_on_curve_update")
	update()

func _on_curve_update():
	update()

# Loop through children to find all the ScatterItem and ScatterExclude nodes within
func _discover_items_info():
	_items.clear()
	_exclusion_areas.clear()
	_total_proportion = 0
	
	for c in get_children():
		if c.get_class() == "ScatterItem":
			_items.append(c)
			_total_proportion += c.proportion
		elif c.get_class() == "ScatterExclude":
			_exclusion_areas.append(c)

func _setup_distribution():
	match distribution:
		0:
			_distribution = UniformDistribution.new()
		1:
			_distribution = NormalDistribution.new()
		2:
			_distribution = SimplexNoiseDistribution.new()
	_distribution.init(custom_seed)

func _get_ground_position(pos):
	var space_state = get_world().get_direct_space_state()
	var top = pos
	var bottom = pos
	top.y = ray_up_length
	bottom.y = -ray_down_length
	
	top = to_global(top)
	bottom = to_global(bottom)
	
	var hit = space_state.intersect_ray(top, bottom)
	if hit:
		return to_local(hit.position).y
	else:
		return 0.0

func _get_next_valid_pos(item_excludes):
	var pos = _distribution.get_vector3() * size * 0.5 + center
	var attempts = 0
	var max_attempts = 200
	while not _is_point_valid(pos, item_excludes) and (attempts < max_attempts):
		pos = _distribution.get_vector3() * size * 0.5 + center
		attempts += 1
	return pos

func _is_point_valid(pos, item_excludes):
	if not is_point_inside(pos):
		return false
	if _is_point_in_exclusion_area(pos, _exclusion_areas):
		return false
	if _is_point_in_exclusion_area(pos, item_excludes):
		return false
	return true

func _is_point_in_exclusion_area(pos, exclusion_areas):
	var inside = false
	for i in range(0, exclusion_areas.size()):
		var a = exclusion_areas[i]
		if a.is_point_inside(a.to_local(to_global(pos))):
			inside = true
	return inside

func _set_amount(val):
	amount = val
	update()

func _set_distribution(val):
	distribution = val
	update()

func _set_seed(val):
	custom_seed = val
	update()

func _set_rotation_randomness(val):
	rotation_randomness = val
	update()

func _set_scale(val):
	scale_randomness = val
	update()

func _set_global_scale(val):
	global_scale = val
	update()

# Avoid certain errors during tool developpement
func _is_ready():
	set_process(true)
	return get_tree()

func _process(_delta):
	pass
