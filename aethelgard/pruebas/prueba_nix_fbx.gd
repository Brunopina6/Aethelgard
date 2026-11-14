extends SceneTree
# V12 (14/11): piloto de Nix desde el FBX del usuario (personajes/nix/fbx/, interruptor «nix_fbx», APAGADO).
# Comprueba, sin ventana:
#   1. sin el interruptor, nix_3d.gd carga su nix.glb de siempre (con su cara y sus LOD) y no crea cetro;
#   2. con él: el GLB nuevo (48 huesos, los 6 de los mechones y el socket arma_d), los 23 clips del JSON, la malla de
#      11.968 triángulos con 4 huesos por vértice como mucho, la textura de 1024, el cetro en su socket y la altura
#      normalizada; concentrarse pasa por «canalizar» y llega al bucle con los mechones levantados; al volver a la
#      guardia los mechones bajan; morir y revivir.
# No toca la partida (no guarda) ni deja encendido el interruptor.

const NixFBX := preload("res://personajes/nix/fbx/nix_fbx.gd")
var fallos := 0
var paso := -1
var t := 0.0
var nix: Node3D
var vieja: Node3D
var raiz: Node3D
var marca := 0.0


func _ok(c: bool, que: String) -> void:
	print(("OK    " if c else "FALLO ") + que)
	if not c:
		fallos += 1


func _initialize() -> void:
	raiz = Node3D.new()
	root.add_child(raiz)
	if Engine.has_meta("nix_fbx"):
		Engine.remove_meta("nix_fbx")
	_ok(not NixFBX.activo(), "el interruptor nix_fbx está apagado por defecto")
	var viejo: Node3D = load("res://personajes/nix/nix_3d.gd").new()
	_ok(viejo.ruta_modelo == "res://personajes/nix/nix.glb" and not viejo.usa_vara, "sin interruptor: nix.glb y sin cetro")
	raiz.add_child(viejo)
	vieja = viejo
	Engine.set_meta("nix_fbx", true)
	nix = load("res://personajes/nix/nix_3d.gd").new()
	Engine.remove_meta("nix_fbx")                     # se lee en _init: no hace falta dejarlo encendido
	raiz.add_child(nix)


# (los _ready de los nodos añadidos en _initialize corren al empezar el primer fotograma: se mira después)
func _comprobar_vieja() -> void:
	_ok(vieja.find_child("cara_nix", true, false) != null and vieja.find_child("cuerpo_nix_lod1", true, false) != null,
		"sin interruptor: la Nix de siempre (cara_nix y LOD)")
	_ok(vieja.vara == null, "sin interruptor: no se crea cetro")
	vieja.queue_free()


# Godot cambia «:» por «_» en los nombres de hueso del GLB: se busca con y sin prefijo
func _hueso(n: String) -> int:
	var sk: Skeleton3D = nix.skel
	for c in ["mixamorig:" + n, "mixamorig_" + n, n]:
		if sk.find_bone(c) >= 0:
			return sk.find_bone(c)
	return -1


func _comprobar_modelo() -> void:
	_ok(nix.ruta_modelo == NixFBX.GLB, "con interruptor: carga nix_fbx.glb")
	var sk: Skeleton3D = nix.skel
	_ok(sk != null and nix.anim != null, "esqueleto y AnimationPlayer")
	if sk == null:
		return
	_ok(sk.get_bone_count() == 48, "48 huesos (%d)" % sk.get_bone_count())
	for n in ["mechon_i_1", "mechon_i_2", "mechon_d_1", "mechon_d_2", "mechon_sup_1", "mechon_sup_2", "arma_d",
			"Hips", "RightHandMiddle1", "HeadTop_End"]:
		_ok(_hueso(n) >= 0, "hueso " + n)
	var d = JSON.parse_string(FileAccess.get_file_as_string(NixFBX.JSON_CLIPS))
	var faltan := []
	for c in d["clips"]:
		if not nix.anim.has_animation(c):
			faltan.append(c)
	_ok(d["clips"].size() == 23 and faltan.is_empty(), "23 clips del JSON en el GLB (faltan %s)" % str(faltan))
	var mi: MeshInstance3D = nix.find_child("cuerpo_nix", true, false)
	_ok(mi != null, "malla cuerpo_nix")
	if mi != null:
		var a := mi.mesh.surface_get_arrays(0)
		var tri: int = a[Mesh.ARRAY_INDEX].size() / 3
		var nv: int = a[Mesh.ARRAY_VERTEX].size()
		var nb: int = a[Mesh.ARRAY_BONES].size()
		_ok(tri == 11968, "11.968 triángulos (%d)" % tri)
		_ok(nb == nv * 4, "4 huesos por vértice (%d / %d)" % [nb, nv])
		var w: PackedFloat32Array = a[Mesh.ARRAY_WEIGHTS]
		var mal := 0
		for i in nv:
			var s := w[i * 4] + w[i * 4 + 1] + w[i * 4 + 2] + w[i * 4 + 3]
			if absf(s - 1.0) > 0.02:
				mal += 1
		_ok(mal == 0, "pesos normalizados (%d vértices mal)" % mal)
		var m = mi.mesh.surface_get_material(0)
		var tex: Texture2D = m.albedo_texture if m is BaseMaterial3D else null
		_ok(tex != null and tex.get_width() == 1024, "color de 1024 (%s)" % (str(tex.get_size()) if tex else "sin textura"))
		var im: Image = tex.get_image() if tex else null
		_ok(im != null and im.is_compressed() and im.has_mipmaps(), "color comprimido en VRAM y con mipmaps (formato %s)" % (str(im.get_format()) if im else "-"))
		_ok(mi.get_surface_override_material(0) is ShaderMaterial, "material de los héroes v2 (heroe_v2.gdshader)")
	_ok(nix.vara != null, "cetro creado en el socket")
	var h: float = nix.ajuste.scale.y
	_ok(h > 0.5 and h < 1.5, "altura normalizada (escala %.3f)" % h)


func _angulo_mechon() -> float:
	var sk: Skeleton3D = nix.skel
	var b := sk.get_bone_global_pose(sk.find_bone("mechon_i_2")).basis
	var b0 := sk.get_bone_global_pose(_hueso("Neck")).basis
	# respecto al cuello (que también se mueve con el clip)
	var r := (b0.inverse() * b).orthonormalized()
	return rad_to_deg(Quaternion(r).angle_to(Quaternion(_rel_rest())))


func _rel_rest() -> Basis:
	var sk: Skeleton3D = nix.skel
	return (sk.get_bone_global_rest(_hueso("Neck")).basis.inverse()
		* sk.get_bone_global_rest(sk.find_bone("mechon_i_2")).basis).orthonormalized()


func _process(delta: float) -> bool:
	t += delta
	if nix == null or (paso >= 0 and nix.skel == null):
		print("FALLOS: %d" % (fallos + 1))
		quit(1)
		return true
	match paso:
		-1:
			if t > 0.2:
				_comprobar_vieja()
				_comprobar_modelo()
				paso = 0
		0:
			if t > 0.8:
				var dv: float = nix.vara.global_position.distance_to(nix.skel.global_transform * nix.skel.get_bone_global_pose(nix.skel.find_bone("arma_d")).origin) if nix.vara else 99.0
				_ok(dv < 0.01, "el cetro sigue al hueso arma_d (%.3f m)" % dv)
				_ok(_angulo_mechon() < 3.0, "en guardia los mechones están en reposo (%.1f°)" % _angulo_mechon())
				nix.concentrar()
				marca = t
				paso = 1
		1:
			if t - marca > 0.3:
				_ok(String(nix.anim.assigned_animation) == "canalizar", "concentrarse empieza por «canalizar» (%s)" % nix.anim.assigned_animation)
				paso = 2
		2:
			if t - marca > 1.6:
				_ok(String(nix.anim.assigned_animation) == "magia_concentrar", "y sigue en el bucle (%s)" % nix.anim.assigned_animation)
				var a := _angulo_mechon()
				_ok(a > 8.0, "los mechones delanteros están levantados (%.1f°)" % a)
				nix.reposo()
				marca = t
				paso = 3
		3:
			if t - marca > 1.0:
				var a := _angulo_mechon()
				_ok(a < 3.0, "al volver a la guardia bajan (%.1f°)" % a)
				nix.morir()
				marca = t
				paso = 4
		4:
			if t - marca > 2.2:
				_ok(String(nix.anim.assigned_animation) == "derrota", "morir: derribo y derrota (%s)" % nix.anim.assigned_animation)
				nix.revivir()
				marca = t
				paso = 5
		5:
			if t - marca > 1.8:
				_ok(not nix._muerta and String(nix.anim.assigned_animation) == "guardia", "revivir: vuelve a la guardia (%s)" % nix.anim.assigned_animation)
				nix.queue_free()
				print("FALLOS: %d" % fallos)
				quit(1 if fallos > 0 else 0)
				return true
	return false
