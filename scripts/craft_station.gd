class_name CraftStation
extends Node3D
## A crafting station (press F): "forge", "workbench" or "alchemy". With `build_visual` it builds
## its own furniture (towns); village smithies just get an invisible forge station at their forge.

var world: Node
var kind := "forge"
var build_visual := true


func _ready() -> void:
	add_to_group("interactables")
	add_to_group("stations")
	if not build_visual:
		return
	var wood := Props.wood()
	var dark := Props.dark_wood()
	var iron := MeshKit.mat(Color(0.14, 0.14, 0.15), 0.45, 0.85)
	match kind:
		"forge":
			var brick := Props.stone(Color(0.8, 0.5, 0.4), 0.6)
			MeshKit.static_box(self, Vector3(1.8, 0.95, 1.2), Vector3(-0.8, 0.47, 0), brick)
			MeshKit.box(self, Vector3(1.3, 0.08, 0.8), Vector3(-0.8, 0.97, 0), MeshKit.mat(Color(1.0, 0.35, 0.05), 0.8, 0.0, 2.5))
			MeshKit.cyl(self, 0.7, 0.35, 1.0, Vector3(-0.8, 1.6, -0.1), brick, Vector3.ZERO, 4)
			MeshKit.static_box(self, Vector3(0.5, 2.6, 0.5), Vector3(-0.8, 3.2, -0.2), brick)
			var fire := OmniLight3D.new()
			fire.light_color = Color(1.0, 0.5, 0.2)
			fire.omni_range = 6.0
			fire.position = Vector3(-0.8, 1.4, 0.5)
			add_child(fire)
			world.fire_lights.append(fire)
			if PropKit.enabled():
				PropKit.put(self, "Anvil_Log", Vector3(0.9, 0, 0.2), 90.0, Vector3.ONE, true)
				PropKit.put(self, "Bucket_Metal", Vector3(0.6, 0, 0.9), 20.0)
				if Arms.enabled():
					Arms.upright(self, Vector3(1.5, 0.05, -0.35), 0.0, -12.0, 0.95)
				else:
					PropKit.put(self, "Sword_Bronze", Vector3(1.55, 0.6, -0.3), 0.0, Vector3.ONE, false, false)
			else:
				MeshKit.static_cyl(self, 0.32, 0.6, Vector3(0.9, 0.3, 0.2), MeshKit.mat(Color(0.4, 0.28, 0.16)), 10)
				MeshKit.box(self, Vector3(0.3, 0.25, 0.25), Vector3(0.9, 0.72, 0.2), iron)
				MeshKit.box(self, Vector3(0.6, 0.12, 0.28), Vector3(0.95, 0.9, 0.2), iron)
		"workbench":
			if PropKit.enabled():
				PropKit.put(self, "Workbench", Vector3.ZERO, 0.0, PropKit.fit("Workbench", Vector3(2.0, 0.9, 0.9)), true)
				PropKit.put(self, "Workbench_Drawers", Vector3.ZERO, 0.0, PropKit.fit("Workbench", Vector3(2.0, 0.9, 0.9)))
			else:
				MeshKit.static_box(self, Vector3(2.0, 0.08, 0.9), Vector3(0, 0.88, 0), wood)
				for x in [-0.9, 0.9]:
					for z in [-0.38, 0.38]:
						MeshKit.box(self, Vector3(0.08, 0.86, 0.08), Vector3(x, 0.43, z), dark)
				MeshKit.box(self, Vector3(1.9, 0.05, 0.8), Vector3(0, 0.3, 0), dark)
			MeshKit.box(self, Vector3(0.2, 0.15, 0.15), Vector3(-0.75, 1.0, 0.25), iron)
			MeshKit.box(self, Vector3(0.05, 0.05, 0.3), Vector3(-0.75, 1.1, 0.25), iron)
			var part := TechProps.drone_model(self, false)
			part.position = Vector3(0.1, 0.93, 0.0)
			part.scale = Vector3.ONE * 1.6
			for i in 5:
				MeshKit.box(self, Vector3(0.1, 0.06, 0.18), Vector3(0.5 + randf() * 0.35, 0.95, randf_range(-0.3, 0.3)), MeshKit.mat(Color(0.5, 0.5, 0.52), 0.5, 0.7), Vector3(0, randf() * 90, 0))
			MeshKit.static_box(self, Vector3(2.0, 1.2, 0.08), Vector3(0, 1.5, -0.5), dark)
			for i in 6:
				MeshKit.box(self, Vector3(0.04, 0.3, 0.02), Vector3(-0.8 + i * 0.3, 1.6, -0.44), iron)
			var lamp := OmniLight3D.new()
			lamp.light_color = Color(1.0, 0.9, 0.7)
			lamp.light_energy = 0.8
			lamp.omni_range = 3.0
			lamp.position = Vector3(0, 1.8, 0.2)
			add_child(lamp)
		"alchemy":
			if PropKit.enabled():
				PropKit.put(self, "Table_Large", Vector3.ZERO, 0.0, PropKit.fit("Table_Large", Vector3(1.8, 0.86, 0.8)), true)
				var arng := RandomNumberGenerator.new()
				arng.seed = int(global_position.x * 7.0)
				for i in 7:
					PropKit.put(self, ["Potion_1", "Potion_2", "Potion_4", "SmallBottles_1", "Bottle_1"][i % 5], Vector3(-0.75 + i * 0.22, 0.86, arng.randf_range(-0.2, 0.2)), arng.randf() * 360.0, Vector3.ONE, false, false)
				PropKit.put(self, "Book_7", Vector3(0.5, 0.86, 0.15), 20.0, Vector3.ONE, false, false)
				PropKit.put(self, "Cauldron", Vector3(1.45, 0, 0.0), 0.0, Vector3.ONE, true)
				MeshKit.cyl(self, 0.38, 0.38, 0.02, Vector3(1.45, 0.72, 0.0), MeshKit.mat(Color(0.3, 1.0, 0.4), 0.3, 0.0, 2.0), Vector3.ZERO, 14)
			else:
				MeshKit.static_box(self, Vector3(1.8, 0.08, 0.8), Vector3(0, 0.86, 0), dark)
				for x in [-0.8, 0.8]:
					for z in [-0.33, 0.33]:
						MeshKit.box(self, Vector3(0.08, 0.84, 0.08), Vector3(x, 0.42, z), dark)
				var cols := [Color(0.9, 0.2, 0.2), Color(0.3, 0.5, 1.0), Color(0.3, 0.9, 0.4), Color(0.9, 0.8, 0.2)]
				for i in 7:
					var c: Color = cols[i % cols.size()]
					MeshKit.cyl(self, 0.04, 0.06, 0.18, Vector3(-0.75 + i * 0.16, 0.99, randf_range(-0.2, 0.2)), MeshKit.mat(c, 0.15, 0.0, 0.6), Vector3.ZERO, 8)
				# cauldron beside the table
				MeshKit.static_cyl(self, 0.45, 0.6, Vector3(1.4, 0.35, 0.0), iron, 14)
				MeshKit.cyl(self, 0.4, 0.4, 0.02, Vector3(1.4, 0.66, 0.0), MeshKit.mat(Color(0.3, 1.0, 0.4), 0.3, 0.0, 2.0), Vector3.ZERO, 14)
			var glow := OmniLight3D.new()
			glow.light_color = Color(0.4, 1.0, 0.5)
			glow.light_energy = 1.0
			glow.omni_range = 3.0
			glow.position = Vector3(1.4, 1.0, 0.0)
			add_child(glow)
			var steam := CPUParticles3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.06
			sm.height = 0.12
			sm.radial_segments = 6
			sm.rings = 3
			sm.material = MeshKit.glow(Color(0.5, 1.0, 0.6, 0.15))
			steam.mesh = sm
			steam.amount = 12
			steam.lifetime = 2.0
			steam.direction = Vector3.UP
			steam.spread = 15.0
			steam.gravity = Vector3(0, 0.3, 0)
			steam.initial_velocity_min = 0.2
			steam.initial_velocity_max = 0.4
			steam.scale_amount_max = 2.5
			steam.position = Vector3(1.4, 0.7, 0.0)
			add_child(steam)


func prompt() -> String:
	return Loc.t("Use") + " " + Loc.t(Crafting.STATION_NAMES[kind])


func interact() -> void:
	world.open_craft(kind)
