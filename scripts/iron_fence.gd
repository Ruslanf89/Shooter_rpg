class_name IronFence
extends RefCounted
## Victorian railings (after the brick-and-iron fence reference): a red-brick plinth with stone
## coping, brick piers with stone caps, wrought-iron spear bars between them, and gateways with two
## scrolled iron leaves that open (HouseDoor, iron style).

const PLINTH_H := 0.6
const PLINTH_D := 0.42
const PIER := 0.5
const PIER_H := 2.3
const BAR_TOP := 2.0
const BAR_GAP := 0.14


static func brick() -> Material:
	return MeshKit.textured("Bricks066", Color(0.62, 0.26, 0.18), 1.6, 0.6, 0.95)


static func cap_stone() -> Material:
	return Props.stone(Color(0.72, 0.7, 0.68), 0.5)


static func iron() -> Material:
	return MeshKit.mat(Color(0.07, 0.07, 0.075), 0.45, 0.75)


## A straight run of railings from a to b (on the ground), with a pier about every 3 m.
## pier_a / pier_b: whether to put piers at the ends (off where a gate or another run has one).
static func run(w: Node3D, a: Vector3, b: Vector3, pier_a := true, pier_b := true) -> Node3D:
	var d := Vector3(b.x - a.x, 0, b.z - a.z)
	var length := d.length()
	var n := Props.pivot(w, (a + b) * 0.5, rad_to_deg(atan2(d.x, d.z)))
	var spans := maxi(1, int(round(length / 3.0)))
	var step := length / spans
	var bricks := brick()
	var cap := cap_stone()
	var ir := iron()
	MeshKit.box(n, Vector3(PLINTH_D, PLINTH_H, length), Vector3(0, PLINTH_H * 0.5, 0), bricks)
	MeshKit.box(n, Vector3(PLINTH_D + 0.08, 0.07, length), Vector3(0, PLINTH_H + 0.035, 0), cap)
	MeshKit.collider_box(n, Vector3(PLINTH_D, BAR_TOP, length), Vector3(0, BAR_TOP * 0.5, 0))
	for i in spans + 1:
		if (i == 0 and not pier_a) or (i == spans and not pier_b):
			continue
		pier(n, Vector3(0, 0, -length * 0.5 + step * i), PIER, PIER_H)
	var bars: Array[Transform3D] = []
	var tips: Array[Transform3D] = []
	var bar_h := BAR_TOP - PLINTH_H
	for i in spans:
		var z0 := -length * 0.5 + step * i + PIER * 0.5 + 0.06
		var z1 := -length * 0.5 + step * (i + 1) - PIER * 0.5 - 0.06
		if z1 <= z0:
			continue
		var count := maxi(1, int((z1 - z0) / BAR_GAP))
		for k in count + 1:
			var z := lerpf(z0, z1, float(k) / count)
			bars.append(Transform3D(Basis(), Vector3(0, PLINTH_H + bar_h * 0.5, z)))
			tips.append(Transform3D(Basis(), Vector3(0, BAR_TOP + 0.06, z)))
		for y in [0.78, 1.78]:
			MeshKit.box(n, Vector3(0.03, 0.045, z1 - z0 + 0.12), Vector3(0, y, (z0 + z1) * 0.5), ir)
	var bar := CylinderMesh.new()
	bar.top_radius = 0.012
	bar.bottom_radius = 0.012
	bar.height = bar_h
	bar.radial_segments = 6
	bar.rings = 1
	var tip := CylinderMesh.new()
	tip.top_radius = 0.0
	tip.bottom_radius = 0.032
	tip.height = 0.12
	tip.radial_segments = 4
	tip.rings = 1
	_multi(n, bar, ir, bars)
	_multi(n, tip, ir, tips)
	return n


## A brick pier with a stone band, cap and pyramid top (with its own collider).
static func pier(n: Node3D, p: Vector3, size: float, h: float, ball := false) -> void:
	var cap := cap_stone()
	MeshKit.box(n, Vector3(size, h, size), p + Vector3(0, h * 0.5, 0), brick())
	MeshKit.box(n, Vector3(size + 0.06, 0.08, size + 0.06), p + Vector3(0, PLINTH_H, 0), cap)
	MeshKit.box(n, Vector3(size + 0.14, 0.12, size + 0.14), p + Vector3(0, h + 0.06, 0), cap)
	if ball:
		MeshKit.box(n, Vector3(size * 0.6, 0.12, size * 0.6), p + Vector3(0, h + 0.18, 0), cap)
		MeshKit.sphere(n, size * 0.32, p + Vector3(0, h + 0.24 + size * 0.3, 0), cap)
	else:
		MeshKit.cyl(n, 0.0, (size + 0.08) * 0.72, 0.3, p + Vector3(0, h + 0.27, 0), cap, Vector3(0, 45, 0), 4)
	MeshKit.collider_box(n, Vector3(size, h, size), p + Vector3(0, h * 0.5, 0))


## A gateway centred at p, across local x (yaw turns it): two tall piers with stone balls and two
## scrolled iron leaves that swing inwards (towards local -z).
static func gate(w: Node3D, p: Vector3, yaw_deg: float, width: float, leaf_h := 2.3, start_open := true) -> Node3D:
	var n := Props.pivot(w, p, yaw_deg)
	var half := width * 0.5
	for s in [-1.0, 1.0]:
		pier(n, Vector3(s * (half + 0.38), 0, 0), 0.75, leaf_h + 0.6, true)
		var d := HouseDoor.new()
		d.style = "iron"
		d.width = half
		d.height = leaf_h
		d.start_open = start_open
		d.position = Vector3(s * -half, 0, 0)
		if s < 0:
			d.rotation.y = PI
			d.open_angle = -100.0
		else:
			d.open_angle = 100.0
		n.add_child(d)
	return n


static func _multi(n: Node3D, mesh: Mesh, mat: Material, xforms: Array[Transform3D]) -> void:
	if xforms.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = mat
	mi.visibility_range_end = 140.0
	n.add_child(mi)
