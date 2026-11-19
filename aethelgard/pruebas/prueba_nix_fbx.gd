extends SceneTree
# V12 (14/11): piloto de Nix desde el FBX del usuario (personajes/nix/fbx/, interruptor «nix_fbx», APAGADO).
# Comprueba, sin ventana:
#   1. sin el interruptor, nix_3d.gd carga su nix.glb de siempre (con su cara y sus LOD) y no crea cetro;
#   2. con él: el GLB nuevo (54 huesos: los 6 de los mechones, el socket arma_d y, desde el vestuario del 14/11, los 6
#      de la ropa), los 23 clips del JSON, el cuerpo de 11.968 triángulos y la ROPA como malla aparte («ropa_nix»: un
#      material, atlas de 1024 comprimido, pesos de 4 huesos normalizados, los huesos de faldones, capa y capucha con
#      peso, total por debajo de 20.000 triángulos), ninguna malla ni nodo de sobra, el cetro PROPIO en su socket y la
#      altura normalizada; concentrarse pasa por «canalizar» y llega al bucle con los mechones levantados y los faldones
#      ABIERTOS; al volver a la guardia bajan y se cierran; morir y revivir.
#   3. (14/11, tarde) con él, el cuerpo lleva la emisión del iris (nix_fbx_cuerpo.gdshader, con sus texturas) y la
#      ropa no; sin él, ningún material la lleva.
#   4. (19/11, C-6) con él, la ropa lleva la emisión de los ornamentos (nix_fbx_ropa.gdshader), APAGADA en guardia; el
#      uniforme del material sigue a la habilidad: canalizar fuerte (y volver a la guardia no la corta: sigue
#      preparando), Ascuas y Aguja básica, Colapso suprema, al acabar (fin_magia) 0; y la limpieza: a 0 en el acto al
#      romperse el conjuro (apagar_emision, lo llama combate.gd), al morir, en pausa (SceneTree.paused y la de la
#      aplicación), al ganar (victoria) y al salir de la escena, sin volver a subir. Sin él, nada de eso hace nada.
#      (prueba_nix_emision.gd lo comprueba además en un combate de verdad.)
# No toca la partida (no guarda) ni deja encendido el interruptor.

const NixFBX := preload("res://personajes/nix/fbx/nix_fbx.gd")
var fallos := 0
var paso := -1
var t := 0.0
var nix: Node3D
var vieja: Node3D
var raiz: Node3D
var marca := 0.0
var mat_ropa: ShaderMaterial = null


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
	var con_iris := 0
	for m in vieja.find_children("*", "MeshInstance3D", true, false):
		for s in m.get_surface_override_material_count():
			var sm := m.get_surface_override_material(s) as ShaderMaterial
			if sm != null and sm.shader != null and sm.shader.resource_path == NixFBX.SHADER_CUERPO:
				con_iris += 1
	_ok(con_iris == 0, "sin interruptor: ningún material con la emisión del iris (%d)" % con_iris)
	var con_orn := 0
	for m in vieja.find_children("*", "MeshInstance3D", true, false):
		for s in m.get_surface_override_material_count():
			var sm := m.get_surface_override_material(s) as ShaderMaterial
			if sm != null and sm.shader != null and sm.shader.resource_path == NixFBX.SHADER_ROPA:
				con_orn += 1
	_ok(con_orn == 0 and vieja.get("_mat_ropa") == null, "sin interruptor: ningún material con la emisión de los ornamentos (%d)" % con_orn)
	vieja.concentrar()
	_ok(vieja.has_method("apagar_emision") and vieja.has_method("nivel_emision"), "nix_3d.gd tiene apagar_emision y nivel_emision")
	if vieja.has_method("apagar_emision"):
		vieja.apagar_emision()
		_ok(vieja.nivel_emision() == 0.0, "sin interruptor: concentrarse y apagar no mueven ninguna emisión")
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
	_ok(sk.get_bone_count() == 54, "54 huesos (%d)" % sk.get_bone_count())
	for n in ["mechon_i_1", "mechon_i_2", "mechon_d_1", "mechon_d_2", "mechon_sup_1", "mechon_sup_2", "arma_d",
			"Hips", "RightHandMiddle1", "HeadTop_End", "faldon_i_1", "faldon_i_2", "faldon_d_1", "faldon_d_2", "capa",
			"capucha"]:
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
		# 15/11 (revisión de personajes, p12_mano.py): la mano del cetro cierra los dedos. Antes RightHandMiddle1 no
		# movía ningún vértice y los dedos iban con la palma (mano abierta con el asta atravesándola).
		var dedos := {}
		var bb: PackedInt32Array = a[Mesh.ARRAY_BONES]
		for i in nv:
			for k in 4:
				if w[i * 4 + k] > 0.3:
					var bi: int = bb[i * 4 + k]
					var nombre: String = String(mi.skin.get_bind_name(bi)) if mi.skin != null and mi.skin.get_bind_name(bi) != &"" \
						else nix.skel.get_bone_name(mi.skin.get_bind_bone(bi) if mi.skin != null else bi)
					for hb in ["RightHandMiddle1", "RightHandMiddle2", "LeftHandMiddle1"]:
						if nombre.ends_with(hb):
							dedos[hb] = dedos.get(hb, 0) + 1
		_ok(dedos.get("RightHandMiddle1", 0) >= 15 and dedos.get("RightHandMiddle2", 0) >= 15,
			"dedos de la mano del cetro con peso (vértices > 0,3: %s)" % str(dedos))
		var m = mi.mesh.surface_get_material(0)
		var tex: Texture2D = m.albedo_texture if m is BaseMaterial3D else null
		_ok(tex != null and tex.get_width() == 1024, "color de 1024 (%s)" % (str(tex.get_size()) if tex else "sin textura"))
		var im: Image = tex.get_image() if tex else null
		_ok(im != null and im.is_compressed() and im.has_mipmaps(), "color comprimido en VRAM y con mipmaps (formato %s)" % (str(im.get_format()) if im else "-"))
		_ok(mi.get_surface_override_material(0) is ShaderMaterial, "material de los héroes v2 (heroe_v2.gdshader)")
		# 14/11 (tarde): el cuerpo, con la emisión suave del iris; conserva sus texturas y ajustes de los v2
		var sm := mi.get_surface_override_material(0) as ShaderMaterial
		_ok(sm != null and sm.shader != null and sm.shader.resource_path == NixFBX.SHADER_CUERPO
			and sm.get_shader_parameter("albedo_tex") == tex and sm.get_shader_parameter("tiene_normal") == true,
			"cuerpo: material de los v2 con la emisión del iris (%s) y sus texturas" % (sm.shader.resource_path if sm and sm.shader else "-"))
	_comprobar_ropa(mi)
	_ok(nix.vara != null, "cetro creado en el socket")
	_ok(nix.vara != null and nix.vara.find_child("cetro_nix", true, false) != null, "es su cetro propio (cetro_nix.glb)")
	var h: float = nix.ajuste.scale.y
	_ok(h > 0.5 and h < 1.5, "altura normalizada (escala %.3f)" % h)


# La ropa (vestuario canónico, 14/11): malla aparte con su material, pesos y huesos; sin restos en el modelo.
func _comprobar_ropa(cuerpo: MeshInstance3D) -> void:
	var ropa: MeshInstance3D = nix.find_child("ropa_nix", true, false)
	_ok(ropa != null, "malla ropa_nix (vestuario)")
	if ropa == null:
		return
	_ok(ropa.mesh.get_surface_count() == 1 and cuerpo != null and cuerpo.mesh.get_surface_count() == 1,
		"dos materiales de personaje: cuerpo y ropa (%d + %d superficies)" % [cuerpo.mesh.get_surface_count() if cuerpo else -1, ropa.mesh.get_surface_count()])
	var a := ropa.mesh.surface_get_arrays(0)
	var tri: int = a[Mesh.ARRAY_INDEX].size() / 3
	var nv: int = a[Mesh.ARRAY_VERTEX].size()
	var tri_c: int = cuerpo.mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX].size() / 3 if cuerpo else 0
	_ok(tri > 5000 and tri + tri_c <= 20000, "ropa %d triángulos; con el cuerpo %d (<= 20.000)" % [tri, tri + tri_c])
	_ok(a[Mesh.ARRAY_BONES].size() == nv * 4, "ropa: 4 huesos por vértice")
	var w: PackedFloat32Array = a[Mesh.ARRAY_WEIGHTS]
	var b: PackedInt32Array = a[Mesh.ARRAY_BONES]
	var mal := 0
	for i in nv:
		if absf(w[i * 4] + w[i * 4 + 1] + w[i * 4 + 2] + w[i * 4 + 3] - 1.0) > 0.02:
			mal += 1
	_ok(mal == 0, "ropa: pesos normalizados (%d vértices mal)" % mal)
	# los huesos nuevos mueven vértices de verdad (índices de la piel -> nombre)
	var sk: Skeleton3D = nix.skel
	var skin: Skin = ropa.skin
	var usados := {}
	for i in nv:
		for k in 4:
			if w[i * 4 + k] > 0.3:
				var bi: int = b[i * 4 + k]
				var nombre := String(skin.get_bind_name(bi)) if skin != null and skin.get_bind_name(bi) != &"" 					else sk.get_bone_name(skin.get_bind_bone(bi) if skin != null else bi)
				usados[nombre] = usados.get(nombre, 0) + 1
	for n in ["faldon_i_1", "faldon_i_2", "faldon_d_1", "faldon_d_2", "capa", "capucha"]:
		_ok(usados.get(n, 0) > 10, "la ropa tiene peso en %s (%d vértices)" % [n, usados.get(n, 0)])
	var m = ropa.mesh.surface_get_material(0)
	var tex: Texture2D = m.albedo_texture if m is BaseMaterial3D else null
	var im: Image = tex.get_image() if tex else null
	_ok(im != null and tex.get_width() == 1024 and im.is_compressed() and im.has_mipmaps(),
		"ropa: atlas de 1024 comprimido en VRAM (%s)" % (str(im.get_format()) if im else "sin textura"))
	_ok(ropa.get_surface_override_material(0) is ShaderMaterial, "ropa con el material de los héroes v2")
	var smr := ropa.get_surface_override_material(0) as ShaderMaterial
	# 19/11 (C-6): la ropa, con la emisión de los ornamentos (apagada) y sin la del iris; conserva sus texturas
	_ok(smr != null and smr.shader != null and smr.shader.resource_path == NixFBX.SHADER_ROPA
		and smr.get_shader_parameter("albedo_tex") == tex and smr.get_shader_parameter("tiene_metal") == true,
		"ropa: material de los v2 con la emisión de los ornamentos (%s), sin la del iris, y sus texturas" % (smr.shader.resource_path if smr and smr.shader else "-"))
	_ok(smr != null and smr.get_shader_parameter("ornamentos") != null and float(smr.get_shader_parameter("ornamentos")) == 0.0,
		"ropa: ornamentos apagados al cargar")
	# sin restos: solo las dos mallas bajo el esqueleto y ninguna cámara ni luz del archivo de Blender
	var mallas := []
	for c in sk.get_children():
		if c is MeshInstance3D:
			mallas.append(String(c.name))
	_ok(mallas.size() == 2 and "cuerpo_nix" in mallas and "ropa_nix" in mallas, "solo cuerpo_nix y ropa_nix (%s)" % str(mallas))
	_ok(nix.find_children("*", "Camera3D", true, false).is_empty() and nix.find_children("*", "Light3D", true, false).is_empty(),
		"sin cámaras ni luces en el modelo")


# Apertura del faldón izquierdo respecto a la cadera (0 en reposo).
func _angulo_faldon() -> float:
	var sk: Skeleton3D = nix.skel
	var h := _hueso("Hips")
	var f := sk.find_bone("faldon_i_1")
	var r := (sk.get_bone_global_pose(h).basis.inverse() * sk.get_bone_global_pose(f).basis).orthonormalized()
	var r0 := (sk.get_bone_global_rest(h).basis.inverse() * sk.get_bone_global_rest(f).basis).orthonormalized()
	return rad_to_deg(Quaternion(r).angle_to(Quaternion(r0)))


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


# El uniforme «ornamentos» del material de la ropa (lo que de verdad se dibuja; -1 si no hay material).
func _orn() -> float:
	if mat_ropa == null and is_instance_valid(nix):
		var ropa := nix.find_child("ropa_nix", true, false) as MeshInstance3D
		if ropa != null:
			mat_ropa = ropa.get_surface_override_material(0) as ShaderMaterial
	if mat_ropa == null or mat_ropa.get_shader_parameter("ornamentos") == null:
		return -1.0
	return float(mat_ropa.get_shader_parameter("ornamentos"))


func _es(nivel: int) -> bool:
	return absf(_orn() - NixFBX.NIVELES[nivel]) < 0.02


func _lanzamiento(clip: String) -> float:
	return nix.instante(clip, "lanzamiento", 0.7)


# El gesto de un hechizo (lo que pide combate.gd _resolver_negra), sin esperar a que salga.
func _lanzar(fam: String) -> void:
	marca = t
	nix.lanzar_negra(fam)


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
				_ok(_angulo_faldon() < 13.0, "en guardia los faldones caen (%.1f°)" % _angulo_faldon())
				_ok(_orn() == 0.0, "en guardia, ornamentos apagados (%.2f)" % _orn())
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
				var fa := _angulo_faldon()
				_ok(fa > 14.0, "los faldones se abren al canalizar (%.1f°)" % fa)
				_ok(_es(NixFBX.FUERTE), "canalizando: ornamentos en la FUERTE (%.2f)" % _orn())
				nix.reposo()
				marca = t
				paso = 3
		3:
			if t - marca > 1.0:
				var a := _angulo_mechon()
				_ok(a < 3.0, "al volver a la guardia bajan (%.1f°)" % a)
				var fa := _angulo_faldon()
				_ok(fa < 13.0, "y los faldones se cierran (%.1f°)" % fa)
				_ok(_es(NixFBX.FUERTE), "volver a la guardia no corta la canalización: sigue fuerte (%.2f)" % _orn())
				if nix.has_method("apagar_emision"):
					nix.apagar_emision()         # lo que hace combate.gd _conjuro_roto
				_ok(_orn() == 0.0, "apagar_emision (lo que llama _conjuro_roto; el camino real está en prueba_nix_emision): a 0 en el acto (%.2f)" % _orn())
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
				_ok(_orn() == 0.0, "tras la interrupción, la muerte y revivir sigue a 0 (%.2f)" % _orn())
				_lanzar("nix_ascuas")
				paso = 6
		6:
			if t - marca > _lanzamiento("magia_lanzar") + 0.1:
				_ok(_es(NixFBX.BASICA), "Ascuas de Nácar: BÁSICA en el lanzamiento (%.2f)" % _orn())
				nix.fin_magia()
				marca = t
				paso = 7
		7:
			if t - marca > 0.7:
				_ok(_orn() == 0.0, "al acabar el hechizo (fin_magia), a 0 (%.2f)" % _orn())
				_lanzar("nix_aguja")
				paso = 8
		8:
			if t - marca > _lanzamiento("magia_estado") + 0.1:
				_ok(_es(NixFBX.BASICA), "Aguja de Invierno: BÁSICA (%.2f)" % _orn())
				nix.concentrar()
				marca = t
				paso = 9
		9:
			if t - marca > 0.8:
				_ok(_es(NixFBX.FUERTE), "canalizar el Colapso: FUERTE (%.2f)" % _orn())
				_lanzar("nix_colapso")
				paso = 10
		10:
			if t - marca > _lanzamiento("magia_culminante") + 0.1:
				_ok(_es(NixFBX.SUPREMA), "Colapso del Firmamento al soltarlo: SUPREMA (%.2f)" % _orn())
				paused = true
				_ok(_orn() == 0.0, "PAUSA (SceneTree.paused): a 0 en el acto (%.2f)" % _orn())
				marca = t
				paso = 11
		11:
			if t - marca > 0.4:
				_ok(_orn() == 0.0, "y quieta mientras dura la pausa (%.2f)" % _orn())
				paused = false
				_lanzar("nix_ascuas")
				paso = 12
		12:
			if t - marca > 0.4:
				_ok(_orn() > 0.1, "de nuevo encendida (%.2f)" % _orn())
				nix.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
				_ok(_orn() == 0.0, "PAUSA de la aplicación (Android en segundo plano): a 0 en el acto (%.2f)" % _orn())
				_lanzar("nix_aguja")
				paso = 13
		13:
			if t - marca > 0.4:
				_ok(_orn() > 0.1, "encendida otra vez (%.2f)" % _orn())
				nix.morir()
				_ok(_orn() == 0.0, "MUERTE: a 0 en el acto (%.2f)" % _orn())
				marca = t
				paso = 14
		14:
			if t - marca > 1.0:
				_ok(_orn() == 0.0, "muerta no vuelve a subir aunque siga el gesto (%.2f)" % _orn())
				nix.revivir()
				marca = t
				paso = 15
		15:
			if t - marca > 1.8:
				_lanzar("nix_colapso")
				paso = 16
		16:
			if t - marca > 0.8:
				_ok(_orn() > 0.5, "subiendo hacia la suprema (%.2f)" % _orn())
				nix.victoria()
				_ok(_orn() == 0.0, "FIN DEL COMBATE (victoria): a 0 en el acto (%.2f)" % _orn())
				marca = t
				paso = 17
		17:
			if t - marca > 1.0:
				_ok(_orn() == 0.0, "tras la victoria sigue a 0 (%.2f)" % _orn())
				_lanzar("nix_ascuas")
				paso = 18
		18:
			if t - marca > 0.4:
				_ok(_orn() > 0.1, "encendida antes de salir (%.2f)" % _orn())
				raiz.remove_child(nix)
				_ok(_orn() == 0.0, "SALIDA de la escena: a 0 en el acto (%.2f)" % _orn())
				nix.queue_free()
				print("FALLOS: %d" % fallos)
				quit(1 if fallos > 0 else 0)
				return true
	return false
