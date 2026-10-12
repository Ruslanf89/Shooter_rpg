class_name KidProportions
extends SkeletonModifier3D
## Makes an adult model look like a child: applied after the animation, scales the head bone up
## (the whole model is scaled down by the Kid itself).

var head_scale := 1.35
var _head := -2


func _process_modification_with_delta(_delta: float) -> void:
	var sk := get_skeleton()
	if sk == null:
		return
	if _head == -2:
		_head = sk.find_bone("Head")
		if _head < 0:
			for i in sk.get_bone_count():
				var n := sk.get_bone_name(i).to_lower()
				if n.ends_with("head"):
					_head = i
					break
	if _head < 0:
		return
	sk.set_bone_pose_scale(_head, Vector3.ONE * head_scale)
