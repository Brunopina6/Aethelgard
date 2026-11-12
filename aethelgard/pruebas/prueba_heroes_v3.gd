extends SceneTree
# Héroes v3 (V12): prueba automática (sin ventana, --fixed-fps 30).
#   - la elección (heroes_v2.gd): por defecto los originales; «v3» da los scripts v3 de quien tenga su v3 (y el v2 de
#     quien aún no lo tenga); se guarda en Ajustes ([heroes] version) sin romper la opción v2 de antes;
#   - cada héroe v3 carga su GLB con GEOMETRÍA PROPIA y el MISMO esqueleto que su v2 (nombres, padres y reposo), los
#     mismos clips con las mismas duraciones e instantes, huesos de arma, cara con formas clave de cejas, material con
#     contorno y detalle, y responde al combate como el v2 (impacto 0,64 de Kael, magia, golpe, KO, levantarse, victoria);
#   - la cara: ojos y boca independientes (el parpadeo solo toca los ojos) y las cejas llegan a su sitio sin saltos;
#   - deformación medida en la CPU (piel del esqueleto aplicada a mano) en varios instantes de cada clip: ningún
#     vértice se escapa ni ninguna arista se estira de más (codos, hombros, caderas, cuello, faldones y pelo);
#   - presupuesto: triángulos del cuerpo y de la cara frente a los del v2 (se imprime).
# No carga partidas ni el juego. Imprime «FALLOS: n» al final.

const HeroesV2 := preload("res://personajes/heroes_v2/heroes_v2.gd")
const HeroesV3 := preload("res://personajes/heroes_v3/heroes_v3.gd")
const ORIGINAL := {"Kael": ["res://kael_3d.gd", "res://kael.fbx"],
	"Lya": ["res://maga_3d.gd", "res://Meshy_AI_Anime_Girl_10k_Remesh_biped_Meshy_Merged_Animations.fbx"],
	"Garon": ["res://garon_3d.gd", "res://garon.fbx"]}
const MAX_ESTIRON := 3.2          # una arista no puede alargarse más de ×3,2 respecto al reposo
const MAX_TRIANGULOS := 16000     # presupuesto del cuerpo (v2: ~10 300 + cara)

var fallos := 0
var comprobaciones := 0


func _ok(cond: bool, texto: String) -> void:
	comprobaciones += 1
	if cond:
		print("  ok  ", texto)
	else:
		fallos += 1
		print("  FALLO ", texto)


func _initialize() -> void:
	_principal.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _segundos(t: float) -> void:
	await _frames(int(round(t * 30.0)))


func _principal() -> void:
	await _frames(5)
	_eleccion()
	for h in ORIGINAL:
		if HeroesV3.listo(h):
			await _heroe(h)
		else:
			print("== ", h, ": sin v3 todavía (se salta)")
	print("COMPROBACIONES: %d · FALLOS: %d" % [comprobaciones, fallos])
	quit(1 if fallos > 0 else 0)


func _limpiar_metas() -> void:
	for m in ["heroes_v2", "heroes_v3", "heroes_version"]:
		if Engine.has_meta(m):
			Engine.remove_meta(m)


func _eleccion() -> void:
	print("== elección de protagonistas")
	_limpiar_metas()
	var c := ConfigFile.new()
	var habia := c.load("user://ajustes.cfg") == OK and c.has_section("heroes")
	var args := OS.get_cmdline_user_args()
	if not habia and not ("heroes_v2" in args or "heroes_v3" in args):
		_ok(HeroesV2.version() == "originales" and not HeroesV2.activado(), "por defecto: originales")
		for h in ORIGINAL:
			_ok(HeroesV2.script_de(ORIGINAL[h][0]) == ORIGINAL[h][0], "%s: por defecto, su script de siempre" % h)
	Engine.set_meta("heroes_v3", true)
	for h in ORIGINAL:
		var r: String = ORIGINAL[h][0]
		var esperado: String = HeroesV3.SCRIPTS[r] if HeroesV3.listo(h) else (HeroesV2.SCRIPTS[r] if ResourceLoader.exists(HeroesV2.GLB[h]) else r)
		_ok(HeroesV2.script_de(r) == esperado, "%s con «v3»: %s" % [h, esperado.get_file()])
	_ok(HeroesV2.script_de("res://goblin_3d.gd") == "res://goblin_3d.gd", "un enemigo no cambia")
	_limpiar_metas()
	Engine.set_meta("heroes_v2", true)
	_ok(HeroesV2.version() == "v2" and HeroesV2.script_de("res://kael_3d.gd") == HeroesV2.SCRIPTS["res://kael_3d.gd"],
		"la meta de los v2 sigue dando los v2")
	_limpiar_metas()
	# Ajustes (user:// aislado)
	HeroesV2.elegir_version("v3")
	_limpiar_metas()
	var c2 := ConfigFile.new()
	_ok(c2.load("user://ajustes.cfg") == OK and c2.get_value("heroes", "version", "") == "v3"
		and not bool(c2.get_value("heroes", "v2", true)), "elegir v3: se guarda [heroes] version = v3 (y v2 = false)")
	_ok(HeroesV2.version() == "v3", "al abrir otra vez el juego (sin meta), lo guardado manda: v3")
	HeroesV2.elegir_en_ajustes(true)          # la opción de antes (v2) sigue valiendo
	_limpiar_metas()
	_ok(HeroesV2.version() == "v2", "elegir v2 con la función de antes: v2")
	HeroesV2.elegir_version("originales")
	_limpiar_metas()
	_ok(HeroesV2.version() == "originales" and HeroesV2.script_de("res://kael_3d.gd") == "res://kael_3d.gd",
		"elegir originales: vuelve el de siempre")
	var c3 := ConfigFile.new()
	if c3.load("user://ajustes.cfg") == OK:
		c3.erase_section("heroes")
		c3.save("user://ajustes.cfg")


func _huesos(sk: Skeleton3D) -> Dictionary:
	var d := {}
	for i in sk.get_bone_count():
		var p := sk.get_bone_parent(i)
		d[sk.get_bone_name(i)] = [sk.get_bone_name(p) if p >= 0 else "", sk.get_bone_rest(i)]
	return d


func _heroe(h: String) -> void:
	print("== ", h)
	var n: Node3D = load(HeroesV3.SCRIPTS[ORIGINAL[h][0]]).new()
	n.ruta_modelo = ORIGINAL[h][1]                  # como lo crea el combate: el script v3 lo cambia por su GLB
	root.add_child(n)
	await _frames(6)
	_ok(n.es_v3 and n.es_v2, "carga el GLB v3 (%s)" % n.ruta_modelo.get_file())
	if not n.es_v3:
		n.queue_free()
		return
	# esqueleto: el mismo que el v2 (nombres, padres y reposo)
	var v2: Node = (load(HeroesV2.GLB[h]) as PackedScene).instantiate()
	var sk2: Skeleton3D = v2.find_children("*", "Skeleton3D", true, false)[0]
	var a := _huesos(n.skel)
	var b := _huesos(sk2)
	var iguales := 0
	var distintos := []
	for k in b:
		if a.has(k) and a[k][0] == b[k][0] and (a[k][1] as Transform3D).is_equal_approx(b[k][1]):
			iguales += 1
		elif k.begins_with("mixamorig") or k.begins_with("arma"):
			distintos.append(k)
	_ok(distintos.is_empty(), "esqueleto común: %d huesos iguales al v2 (nombre, padre y reposo)%s" % [iguales,
		"" if distintos.is_empty() else ", distintos: %s" % str(distintos)])
	var extra := []
	for k in a:
		if not b.has(k):
			extra.append(k)
	print("  huesos añadidos: ", extra)
	v2.free()
	# clips
	var c3 := HeroesV3.contrato(h)
	var c2 := HeroesV2.contrato(h)
	_ok(not c3.is_empty() and c3.size() == c2.size(), "contrato de clips: %d (v2: %d)" % [c3.size(), c2.size()])
	for c in c2:
		var tiene: bool = n.anim.has_animation(c)
		_ok(tiene, "clip «%s»" % c)
		if tiene and c3.has(c):
			_ok(absf(float(c3[c]["duracion"]) - float(c2[c]["duracion"])) < 0.001 and c3[c]["eventos"] == c2[c]["eventos"],
				"  «%s»: misma duración e instantes que el v2 (%.2f s %s)" % [c, float(c3[c]["duracion"]), str(c3[c]["eventos"])])
	# presupuesto
	var cuerpo: MeshInstance3D = n.find_child("cuerpo_v3", true, false)
	var cara: MeshInstance3D = n.find_child("cara_v3", true, false)
	_ok(cuerpo != null, "malla cuerpo_v3")
	if cuerpo != null:
		var tri := _triangulos(cuerpo.mesh)
		print("  triángulos: cuerpo %d, cara %d, superficies %d" % [tri, _triangulos(cara.mesh) if cara else 0, cuerpo.mesh.get_surface_count()])
		_ok(tri <= MAX_TRIANGULOS, "presupuesto: %d triángulos ≤ %d" % [tri, MAX_TRIANGULOS])
		var arr := cuerpo.mesh.surface_get_arrays(0)
		_ok(arr[Mesh.ARRAY_COLOR] != null and arr[Mesh.ARRAY_TEX_UV] != null, "color por vértice y UV de detalle")
		var sm = cuerpo.get_surface_override_material(0)
		_ok(sm is ShaderMaterial and sm.shader.resource_path.ends_with("heroe_v3.gdshader") and sm.next_pass != null
			and sm.get_shader_parameter("detalle") != null, "material v3 con contorno y textura de detalle")
	# cara
	if h != "Garon":
		_ok(cara != null and n.v2.tiene_cara() and n.v2.get_script().resource_path.ends_with("heroe_v3_ayudante.gd"),
			"cara v3 con su ayudante")
		if cara != null:
			_ok(cara.mesh.get_blend_shape_count() == 3, "cejas con 3 formas clave")
			var m: ShaderMaterial = n.v2.mat_cara_v3
			n.v2.poner_expresion("sonrisa")
			_ok(int(m.get_shader_parameter("ojos")) == 2 and int(m.get_shader_parameter("boca")) == 2, "«sonrisa»: ojos y boca 2")
			await _segundos(0.4)
			_ok(n.v2.cejas_actuales().x > 0.4, "«sonrisa»: las cejas suben (%.2f)" % n.v2.cejas_actuales().x)
			n.v2.poner_expresion("grito")
			await _frames(1)
			var media: float = n.v2.cejas_actuales().y
			_ok(media > 0.0 and media < 0.9, "las cejas van a su sitio sin saltar (al primer fotograma %.2f de 1)" % media)
			await _segundos(0.4)
			_ok(n.v2.cejas_actuales().y > 0.95, "«grito»: ceño (%.2f)" % n.v2.cejas_actuales().y)
			n.v2.poner_expresion("decidido")
			# parpadeo: solo los ojos
			n.v2._t_parpadeo = 0.0
			var vio_cerrados := false
			var boca_quieta := true
			for i in 12:
				await _frames(1)
				if int(m.get_shader_parameter("ojos")) == 1:
					vio_cerrados = true
				if int(m.get_shader_parameter("boca")) != 7:
					boca_quieta = false
			_ok(vio_cerrados and boca_quieta, "parpadeo: los ojos se cierran y la boca sigue («decidido»)")
			n.v2._t_parpadeo = 99.0                # sin otro parpadeo (a veces es doble) antes de mirar
			await _segundos(0.45)
			_ok(int(m.get_shader_parameter("ojos")) == 7, "tras el parpadeo, los ojos vuelven a «decidido»")
	else:
		_ok(cara != null and n.v2.tiene_cara(), "Garon: la mirada en la sombra de la visera (cara v3)")
	# combate
	await _segundos(0.3)
	_ok(String(n.anim.current_animation) == "guardia", "en combate su reposo es la guardia (%s)" % n.anim.current_animation)
	var t0 := Engine.get_process_frames()
	var golpe := {"t": -1.0}
	var cb := func(): golpe["t"] = float(Engine.get_process_frames() - t0) / 30.0
	if h == "Kael":
		n.ataque_salto(cb)
		await _segundos(1.5)
		_ok(absf(golpe["t"] - 0.64) <= 0.07, "Kael: impacto a %.2f s (0,64)" % golpe["t"])
	elif h == "Garon":
		n.atacar_juicio(cb)
		await _segundos(2.6)
		_ok(absf(golpe["t"] - 1.10) <= 0.07, "Garon: Juicio, impacto a %.2f s (1,10)" % golpe["t"])
	else:
		n.preparar_golpe()
		await _segundos(0.5)
		n.golpear()
		await _segundos(0.1)
		_ok(n.anim.current_animation_position >= 0.4, "Lya: golpea (%.2f s del clip)" % n.anim.current_animation_position)
		n.fin_golpe()
		await _segundos(0.8)
	if h != "Garon":
		t0 = Engine.get_process_frames()
		await n.lanzar_magia()
		var t := float(Engine.get_process_frames() - t0) / 30.0
		var esperado := 0.85 if h == "Kael" else 0.5
		_ok(absf(t - esperado) <= 0.07, "%s: la magia sale a %.2f s (%.2f)" % [h, t, esperado])
		n.fin_magia()
		await _segundos(0.4)
	n.herida()
	await _segundos(0.1)
	_ok(String(n.anim.current_animation) == "recibir_golpe", "golpe recibido")
	if h != "Garon":
		_ok(n.v2.expresion == "dolor" or int(n.v2.mat_cara_v3.get_shader_parameter("boca")) == 3, "con cara de dolor")
	await _segundos(1.0)
	n.morir()
	await _segundos(1.8)
	_ok(String(n.anim.current_animation) == "derrota", "KO en el suelo (derrota en bucle)")
	_ok(n.v2.expresion == "cerrados", "KO: ojos cerrados (%s)" % n.v2.expresion)
	n.revivir()
	await _segundos(1.8)
	_ok(not n._muerta and String(n.anim.current_animation) == "guardia", "se levanta y vuelve a la guardia")
	n.victoria()
	await _segundos(0.2)
	_ok(String(n.anim.current_animation) == "victoria", "victoria")
	_ok(n.v2.expresion == "sonrisa", "con sonrisa")
	await _segundos(2.0)
	# deformación de cada clip (en la CPU)
	if cuerpo != null:
		await _deformacion(n, cuerpo)
	n.queue_free()
	await _frames(2)


func _triangulos(m: Mesh) -> int:
	var t := 0
	for s in m.get_surface_count():
		var arr := m.surface_get_arrays(s)
		t += (arr[Mesh.ARRAY_INDEX].size() if arr[Mesh.ARRAY_INDEX] != null else arr[Mesh.ARRAY_VERTEX].size()) / 3
	return t


# Aplica la piel a mano (pesos y matrices de unión del GLB) en 5 instantes de cada clip y mide: la arista más
# estirada respecto al reposo y el vértice más lejano de la cadera. Así se ven uniones rotas (hombros, codos, caderas,
# cuello) y piezas que se escapan (faldones, pelo).
func _deformacion(n: Node3D, mi: MeshInstance3D) -> void:
	print("== deformación (piel en la CPU)")
	var sk: Skeleton3D = n.skel
	var skin: Skin = mi.skin
	var arr := mi.mesh.surface_get_arrays(0)
	var V: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var B = arr[Mesh.ARRAY_BONES]
	var W = arr[Mesh.ARRAY_WEIGHTS]
	var I: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var por: int = B.size() / V.size()
	var bind_hueso := []
	for k in skin.get_bind_count():
		var bn := skin.get_bind_name(k)
		bind_hueso.append(sk.find_bone(bn) if bn != "" else skin.get_bind_bone(k))
	# aristas únicas (muestra de 1 de cada 3 triángulos para no tardar)
	var aristas := PackedInt32Array()
	for t in range(0, I.size(), 9):
		aristas.append_array([I[t], I[t + 1], I[t + 1], I[t + 2], I[t + 2], I[t]])
	var rep := _posar(V, B, W, por, skin, bind_hueso, sk, true)
	var largo0 := PackedFloat32Array()
	for e in range(0, aristas.size(), 2):
		largo0.append(rep[aristas[e]].distance_to(rep[aristas[e + 1]]))
	n.set_process(false)
	var peor_clip := ""
	var peor := 0.0
	for clip in n.anim.get_animation_list():
		if clip == "RESET":
			continue
		var anim: Animation = n.anim.get_animation(clip)
		var max_e := 0.0
		var max_d := 0.0
		for f in 5:
			n.anim.play(clip, 0.0)
			n.anim.seek(anim.length * f / 4.0, true)
			sk.force_update_all_bone_transforms()
			var P := _posar(V, B, W, por, skin, bind_hueso, sk, false)
			var cad := sk.get_bone_global_pose(sk.find_bone("mixamorig_Hips")).origin
			for e in range(0, aristas.size(), 2):
				if largo0[e / 2] > 0.002:
					max_e = maxf(max_e, P[aristas[e]].distance_to(P[aristas[e + 1]]) / largo0[e / 2])
			for i in range(0, P.size(), 7):
				max_d = maxf(max_d, P[i].distance_to(cad))
		print("  %-16s estirón máx ×%.2f · lejos de la cadera %.2f m" % [clip, max_e, max_d])
		if max_e > peor:
			peor = max_e
			peor_clip = clip
		_ok(max_e <= MAX_ESTIRON and max_d < 1.6, "  «%s» sin deformaciones rotas" % clip)
	print("  peor estirón: ×%.2f en «%s»" % [peor, peor_clip])
	n.set_process(true)


func _posar(V: PackedVector3Array, B, W, por: int, skin: Skin, bind_hueso: Array, sk: Skeleton3D, reposo: bool) -> PackedVector3Array:
	var mats := []
	for k in skin.get_bind_count():
		var bi: int = bind_hueso[k]
		var g: Transform3D = sk.get_bone_global_rest(bi) if reposo else sk.get_bone_global_pose(bi)
		mats.append(g * skin.get_bind_pose(k))
	var P := PackedVector3Array()
	P.resize(V.size())
	for i in V.size():
		var p := Vector3.ZERO
		for j in por:
			var w: float = W[i * por + j]
			if w > 0.0:
				p += (mats[B[i * por + j]] * V[i]) * w
		P[i] = p
	return P
