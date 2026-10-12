class_name Tactics
extends Node3D
## Where an enemy should stand during a fight, found with GEQO environment queries (marrero171,
## MIT; GDExtension in addons/geqo). GEQO samples candidate spots around the target and scores
## them (close to me, far from my packmates, at a good range); the best few are then checked here
## with real line-of-sight rays.
##   "fire"  - casters and archers: a spot at shooting range that can see the target
##   "flank" - pack hunters: a spot beside or behind the target, away from the rest of the pack
##   "cover" - a badly hurt fighter: a spot nearby the target can't see
## Without the addon nothing changes (the old chase AI is used).

var enemy: Enemy
var _queries := {}          # mode -> [EnvironmentQuery3D, ContextTargetNode3D]
var _busy := false
var spot := Vector3.INF
var spot_mode := ""
var _next := 0.0


static func available() -> bool:
	return ClassDB.class_exists("EnvironmentQuery3D") and ClassDB.class_exists("GeneratorCircleShape3D")


func _curve(rising: bool) -> Curve:
	var c := Curve.new()
	c.add_point(Vector2(0, 0.0 if rising else 1.0))
	c.add_point(Vector2(1, 1.0 if rising else 0.0))
	return c


func _distance_test(gen: Node3D, ctx: Node3D, prefer_far: bool, range_m: float, factor := 1.0) -> void:
	var t: Node3D = ClassDB.instantiate("TestDistanceTo3D")
	t.set("distance_to", ctx)
	t.set("test_purpose", 2)            # score only
	t.set("score_curve", _curve(prefer_far))
	t.set("score_clamp_max_type", 1)
	t.set("score_clamp_max", range_m)
	t.set("score_factor", factor)
	gen.add_child(t)


func _build(mode: String) -> Array:
	var q: Node3D = ClassDB.instantiate("EnvironmentQuery3D")
	q.set("querier", enemy)
	q.set("time_budget_ms", 0.5)
	add_child(q)
	var me: Node3D = ClassDB.instantiate("ContextQuerier3D")
	q.add_child(me)
	var tgt: Node3D = ClassDB.instantiate("ContextTargetNode3D")
	q.add_child(tgt)
	var pack: Node3D = ClassDB.instantiate("ContextInGroup3D")
	pack.set("group", "enemies")
	q.add_child(pack)
	var gen: Node3D = ClassDB.instantiate("GeneratorCircleShape3D")
	gen.set("use_casting", false)
	gen.set("use_vertical_projection", true)
	gen.set("project_up", 8.0)
	gen.set("project_down", 16.0)
	gen.set("post_projection_vertical_offset", 0.4)
	q.add_child(gen)
	match mode:
		"fire":
			gen.set("circle_center", tgt)
			gen.set("circle_radius", clampf(enemy.attack_range * 0.7, 8.0, 18.0))
			gen.set("space_between", 2.5)
			_distance_test(gen, me, false, 30.0, 1.0)
			_distance_test(gen, pack, true, 8.0, 0.6)
		"flank":
			gen.set("circle_center", tgt)
			gen.set("circle_radius", 4.5 + enemy.attack_range)
			gen.set("space_between", 1.6)
			_distance_test(gen, me, false, 20.0, 0.8)
			_distance_test(gen, pack, true, 6.0, 1.4)
		"cover":
			gen.set("circle_center", me)
			gen.set("circle_radius", 12.0)
			gen.set("space_between", 2.0)
			_distance_test(gen, tgt, true, 30.0, 1.0)
			_distance_test(gen, me, false, 14.0, 0.5)
	return [q, tgt]


## Starts a query (time-sliced by GEQO); `spot` is set when it finishes.
func request(mode: String, target: Node3D) -> void:
	if _busy or not is_instance_valid(target):
		return
	if not _queries.has(mode):
		_queries[mode] = _build(mode)
	var entry: Array = _queries[mode]
	(entry[1] as Node3D).set("target_node", target)
	_busy = true
	var q: Node3D = entry[0]
	q.call("request_query")
	await q.query_finished
	_busy = false
	if not is_instance_valid(enemy) or enemy.state == Enemy.State.DEAD or not is_instance_valid(target):
		return
	var res: RefCounted = q.call("get_result")
	if res == null or not res.call("has_result"):
		spot = Vector3.INF
		return
	var items: Array = res.call("get_all_results")
	items.sort_custom(func(a, b): return float(a.get("score")) > float(b.get("score")))
	spot = Vector3.INF
	for it in items.slice(0, 8):
		var p: Vector3 = it.get("projection_position")
		if _valid(mode, p, target):
			spot = p
			spot_mode = mode
			return


func _valid(mode: String, p: Vector3, target: Node3D) -> bool:
	# stay on walkable ground near our own height, inside the map
	if absf(p.y - enemy.global_position.y) > 3.0 or maxf(absf(p.x), absf(p.z)) > enemy.world.half - 15.0:
		return false
	var space := enemy.get_world_3d().direct_space_state
	var eye := Vector3(0, enemy._eye_height, 0)
	# the way there must not run through a wall
	var walk := PhysicsRayQueryParameters3D.create(enemy.global_position + Vector3(0, 0.8, 0), p + Vector3(0, 0.8, 0), 1)
	if not space.intersect_ray(walk).is_empty():
		return false
	if mode == "flank":
		return true
	var look := PhysicsRayQueryParameters3D.create(p + eye, target.global_position + Vector3(0, 1.3, 0), 1)
	var blocked := not space.intersect_ray(look).is_empty()
	return blocked if mode == "cover" else not blocked
