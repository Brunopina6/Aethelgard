extends SceneTree
# Héroes v2 (fase B, V12): prueba automática (sin ventana, --fixed-fps 30).
#   - el interruptor: apagado, todo devuelve lo original; encendido, los scripts v2;
#   - cada héroe v2 carga su GLB, tiene los clips del contrato (con la duración del JSON), sus huesos de arma, su cara
#     (Kael y Lya) y responde al combate: impacto del ataque y lanzamiento de la magia en su instante, golpe recibido,
#     derribo con KO en bucle, levantarse y victoria;
#   - la conversación no repite gesto dos veces seguidas y las expresiones cambian la loseta de la cara.
# No carga partidas ni el juego. Imprime «FALLOS: n» al final.

const HeroesV2 := preload("res://personajes/heroes_v2/heroes_v2.gd")
const ORIGINAL := {"Kael": ["res://kael_3d.gd", "res://kael.fbx"],
	"Lya": ["res://maga_3d.gd", "res://Meshy_AI_Anime_Girl_10k_Remesh_biped_Meshy_Merged_Animations.fbx"],
	"Garon": ["res://garon_3d.gd", "res://garon.fbx"]}

var fallos := 0
var comprobaciones := 0
var ritmos := {}          # 13/11: ritmo de parpadeo de cada héroe con cara


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
	print("== interruptor")
	if Engine.has_meta("heroes_v2"):
		Engine.remove_meta("heroes_v2")
	var apagado: bool = not HeroesV2.activado()
	_ok(apagado or "heroes_v2" in OS.get_cmdline_user_args(), "apagado por defecto (ACTIVO_POR_DEFECTO = %s)" % HeroesV2.ACTIVO_POR_DEFECTO)
	for h in ORIGINAL:
		_ok(HeroesV2.script_de(ORIGINAL[h][0]) == ORIGINAL[h][0] or not apagado, "%s: apagado, script original" % h)
	Engine.set_meta("heroes_v2", true)
	for h in ORIGINAL:
		var esperado: String = HeroesV2.SCRIPTS[ORIGINAL[h][0]] if ResourceLoader.exists(HeroesV2.GLB[h]) else ORIGINAL[h][0]
		_ok(HeroesV2.script_de(ORIGINAL[h][0]) == esperado, "%s: encendido -> %s" % [h, esperado.get_file()])
	_ok(HeroesV2.script_de("res://goblin_3d.gd") == "res://goblin_3d.gd", "un enemigo no cambia")
	Engine.remove_meta("heroes_v2")
	_ajustes()
	for h in ORIGINAL:
		if ResourceLoader.exists(HeroesV2.GLB[h]):
			await _heroe(h)
		else:
			print("== ", h, ": sin GLB todavía (se salta)")
	await _victoria_kael()
	if ritmos.size() == 2:
		print("== parpadeo")
		var k: Dictionary = ritmos["Kael"]
		var l: Dictionary = ritmos["Lya"]
		_ok((k["cada"].x + k["cada"].y) < (l["cada"].x + l["cada"].y) and k["duracion"] < l["duracion"],
			"ritmo distinto: Kael parpadea más a menudo y más rápido (%s, %.2f) que Lya (%s, %.2f)" % [k["cada"], k["duracion"], l["cada"], l["duracion"]])
	print("COMPROBACIONES: %d · FALLOS: %d" % [comprobaciones, fallos])
	quit(1 if fallos > 0 else 0)


# 13/11: la opción de Ajustes «Protagonistas» (heroes_v2.gd: en_ajustes, elegir_en_ajustes). user:// está aislado.
func _ajustes() -> void:
	print("== ajustes")
	var c := ConfigFile.new()
	var habia := c.load("user://ajustes.cfg") == OK and c.has_section_key("heroes", "v2")
	_ok(habia or not HeroesV2.en_ajustes(), "sin elegir: originales")
	HeroesV2.elegir_en_ajustes(true)
	_ok(Engine.has_meta("heroes_v2") and bool(Engine.get_meta("heroes_v2")), "elegir v2: Engine.set_meta(heroes_v2, true)")
	var c2 := ConfigFile.new()
	_ok(c2.load("user://ajustes.cfg") == OK and bool(c2.get_value("heroes", "v2", false)), "elegir v2: se guarda en ajustes.cfg [heroes] v2")
	Engine.remove_meta("heroes_v2")
	_ok(HeroesV2.activado() and HeroesV2.script_de("res://kael_3d.gd") == HeroesV2.SCRIPTS["res://kael_3d.gd"],
		"al abrir otra vez el juego (sin meta), lo guardado manda: v2")
	HeroesV2.elegir_en_ajustes(false)
	Engine.remove_meta("heroes_v2")
	_ok(not HeroesV2.activado() and HeroesV2.script_de("res://kael_3d.gd") == "res://kael_3d.gd", "elegir originales: vuelve el de siempre")
	var c3 := ConfigFile.new()
	if c3.load("user://ajustes.cfg") == OK:
		c3.erase_section("heroes")
		c3.save("user://ajustes.cfg")


# 13/11: la victoria de Kael con la cámara del combate: el sable no atraviesa la cabeza ni queda detrás de ella.
# Se mide en cada fotograma la distancia de la hoja (5 puntos) al centro de la cabeza y, al final, si la hoja queda
# tapada por la cabeza vista desde la cámara de combate (fotos_heroes_v2.gd: 12° desde arriba, de frente).
# El original (kael_3d.gd) se mide igual y solo se imprime: es el respaldo y no se toca.
func _victoria_kael() -> void:
	print("== victoria de Kael (sable y cabeza)")
	var dir_cam := Vector3(0, sin(deg_to_rad(12.0)), cos(deg_to_rad(12.0)))    # hacia la cámara
	for v2 in [false, true]:
		var n: Node3D = load(HeroesV2.SCRIPTS["res://kael_3d.gd"] if v2 else "res://kael_3d.gd").new()
		n.ruta_modelo = "res://kael.fbx"
		root.add_child(n)
		await _frames(8)
		if n.get("sable") == null or n.skel == null:
			_ok(not v2, "Kael %s: tiene sable" % ("v2" if v2 else "original"))
			n.queue_free()
			continue
		n.victoria()
		var min_dist := 10.0
		var tapado_final := 0
		var detras := 0
		var punta_y := 0.0
		var mano_y := 0.0
		for f in 66:                         # 2,2 s
			await _frames(1)
			var cab: Vector3 = n.skel.global_transform * n.skel.get_bone_global_pose(n.gestos.idx["cabeza"]).origin
			var centro := cab + Vector3(0, 0.13, 0)
			var o: Vector3 = n.sable.global_transform.origin
			var eje: Vector3 = n.sable.global_transform.basis.y.normalized()
			detras = 0
			for k in 6:
				var p := o + eje * (0.25 * k)
				min_dist = minf(min_dist, (p - centro).length())
				# tapado por la cabeza desde la cámara: cerca de la línea de visión y por detrás del centro
				var rel := p - centro
				var lateral := (rel - dir_cam * rel.dot(dir_cam)).length()
				if rel.dot(dir_cam) < 0.0 and lateral < 0.17:
					detras += 1
			if f == 65:
				tapado_final = detras
				punta_y = (o + eje * 1.3).y - n.global_position.y
				mano_y = o.y - n.global_position.y
		var nombre := "v2" if v2 else "original"
		print("  Kael %s: distancia mínima hoja-cabeza %.2f m · al final, %d de 6 puntos de la hoja tapados por la cabeza · punta a %.2f m del suelo (mano %.2f)" % [nombre, min_dist, tapado_final, punta_y, mano_y])
		if v2:
			_ok(min_dist > 0.17, "Kael v2: el sable no atraviesa la cabeza en la victoria (mín. %.2f m)" % min_dist)
			_ok(tapado_final == 0, "Kael v2: al final ningún tramo de la hoja queda detrás de la cabeza (%d)" % tapado_final)
			_ok(punta_y > 0.03 and punta_y < mano_y, "Kael v2: acaba con el sable bajado a un lado, sin tocar el suelo (punta %.2f m)" % punta_y)
		n.queue_free()
		await _frames(3)


func _heroe(h: String) -> void:
	print("== ", h)
	var n: Node3D = load(HeroesV2.SCRIPTS[ORIGINAL[h][0]]).new()
	n.ruta_modelo = ORIGINAL[h][1]                  # como lo crea el combate: el script v2 lo cambia por su GLB
	root.add_child(n)
	await _frames(6)
	_ok(n.es_v2, "carga el GLB v2 (%s)" % n.ruta_modelo.get_file())
	if not n.es_v2:
		n.queue_free()
		return
	var contrato := HeroesV2.contrato(h)
	_ok(not contrato.is_empty(), "contrato de clips (%d)" % contrato.size())
	for c in contrato:
		var tiene: bool = n.anim.has_animation(c)
		_ok(tiene, "clip «%s»" % c)
		if tiene and not contrato[c].get("captura", false):
			var dif: float = absf(n.anim.get_animation(c).length - float(contrato[c]["duracion"]))
			_ok(dif <= 1.0 / 30.0 + 0.001, "  «%s» dura %.3f s (contrato %.3f)" % [c, n.anim.get_animation(c).length, contrato[c]["duracion"]])
	var huesos := []
	for i in n.skel.get_bone_count():
		huesos.append(n.skel.get_bone_name(i))
	_ok("arma_d" in huesos, "hueso arma_d")
	if h == "Garon":
		_ok("arma_i" in huesos, "hueso arma_i")
		_ok(n.find_child("cara_v2", true, false) == null, "sin cara (yelmo cerrado)")
		# V12 (14/11): los pasos de doble espada del original le descolocaban la cadera; el v2 corre con su clip
		_ok(not n.nombres.has("AvanzarDoble") and not n.nombres.has("RetrocederDoble"), "Garon v2 sin los pasos del esqueleto original")
		n.avanzar()
		await _frames(4)
		_ok(n.anim.current_animation == str(n.nombres.get("Andar", "andar")) and n.anim.speed_scale > 0.0,
			"Garon v2 avanzando anda hacia delante con su clip («%s», %.2f)" % [n.anim.current_animation, n.anim.speed_scale])
		n.retroceder()
		await _frames(4)
		_ok(n.anim.current_animation == str(n.nombres.get("Andar", "andar")) and n.anim.speed_scale < 0.0,
			"Garon v2 retrocediendo anda hacia atrás (clip al revés; «%s», %.2f)" % [n.anim.current_animation, n.anim.speed_scale])
		n.reposo()
	else:
		_ok(n.v2 != null and n.v2.tiene_cara(), "cara expresiva")
		if n.v2 != null and n.v2.tiene_cara():
			n.v2.poner_expresion("sonrisa")
			_ok(n.v2.cara.visible and n.v2.mat_cara.uv1_offset.is_equal_approx(Vector3(0.5, 0, 0)), "expresión «sonrisa»: loseta 2")
			n.v2.poner_expresion("grito")
			_ok(n.v2.mat_cara.uv1_offset.is_equal_approx(Vector3(0, 0.5, 0)), "expresión «grito»: loseta 4")
			n.v2.poner_expresion("decidido")
			_ok(n.v2.cara.visible and n.v2.mat_cara.uv1_offset.is_equal_approx(Vector3(0.75, 0.5, 0)), "expresión «decidido»: loseta 8 (13/11)")
			n.v2.poner_expresion("normal")
			_ok(not n.v2.cara.visible, "expresión «normal»: la cara original (malla oculta)")
			# 13/11: la cara nueva solo cubre ojos y boca (transparente en lo demás) y se ilumina como la piel
			_ok(n.v2.mat_cara.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA, "cara: material con transparencia")
			_ok(n.v2.mat_cara.diffuse_mode == BaseMaterial3D.DIFFUSE_LAMBERT_WRAP and n.v2.mat_cara.rim_enabled,
				"cara: misma luz que la piel (envolvente y borde)")
			var img: Image = n.v2.mat_cara.albedo_texture.get_image()
			if img != null:
				if img.is_compressed():
					img.decompress()
				var tw := img.get_width() / 4
				var th := img.get_height() / 2
				var max_normal := 0.0
				var max_cerrados := 0.0
				var media_cerrados := 0.0
				for y in range(0, th, 4):
					for x in range(0, tw, 4):
						max_normal = maxf(max_normal, img.get_pixel(x, y).a)
						var a := img.get_pixel(tw + x, y).a
						max_cerrados = maxf(max_cerrados, a)
						media_cerrados += a
				media_cerrados /= float((th / 4) * (tw / 4))
				_ok(max_normal < 0.05, "atlas: la loseta «normal» es transparente (alfa máx. %.2f)" % max_normal)
				_ok(max_cerrados > 0.9 and media_cerrados < 0.5,
					"atlas: «cerrados» solo opaca en los ojos (alfa máx. %.2f, media %.2f)" % [max_cerrados, media_cerrados])
			ritmos[h] = n.v2.ritmo_parpadeo()
	# 13/11: materiales (heroe_v2.gdshader): todas las superficies del cuerpo con el material nuevo
	if n.v2 != null:
		_ok(n.v2.materiales.size() > 0, "materiales nuevos en %d superficies" % n.v2.materiales.size())
		var sm: ShaderMaterial = n.v2.materiales[0] if n.v2.materiales.size() > 0 else null
		_ok(sm != null and float(sm.get_shader_parameter("rugosidad_mate")) >= 0.7 and float(sm.get_shader_parameter("especular_mate")) <= 0.3,
			"piel, tela y cuero mates (rugosidad ≥ 0,7, especular ≤ 0,3)")
	_ok(String(n.anim.current_animation) == "guardia", "en combate su reposo es la guardia (%s)" % n.anim.current_animation)
	# ataque y su impacto
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
		_ok(absf(golpe["t"] - 1.10) <= 0.07, "Garon: Juicio, impacto a %.2f s (1,10, sin cambios)" % golpe["t"])
	else:
		n.preparar_golpe()
		await _segundos(0.5)
		_ok(n.anim.current_animation == "ataque" and n.anim.speed_scale == 0.0, "Lya: espera en la preparación del golpe")
		n.golpear()
		await _segundos(0.1)
		_ok(n.anim.current_animation_position >= 0.4, "Lya: golpea (%.2f s del clip)" % n.anim.current_animation_position)
		n.fin_golpe()
		await _segundos(0.8)
	_ok(String(n.anim.current_animation) == "guardia", "tras el ataque vuelve a la guardia (%s)" % n.anim.current_animation)
	# magia
	if h != "Garon":
		t0 = Engine.get_process_frames()
		await n.lanzar_magia()
		var t := float(Engine.get_process_frames() - t0) / 30.0
		var esperado := 0.85 if h == "Kael" else 0.5
		_ok(absf(t - esperado) <= 0.07, "%s: la magia sale a %.2f s (%.2f)" % [h, t, esperado])
		_ok(String(n.anim.current_animation) == "magia_lanzar", "  con el clip magia_lanzar")
		n.fin_magia()
		await _segundos(0.4)
	# golpe recibido
	n.herida()
	await _segundos(0.1)
	_ok(String(n.anim.current_animation) == "recibir_golpe", "golpe recibido")
	await _segundos(1.0)
	_ok(String(n.anim.current_animation) == "guardia", "vuelve a la guardia")
	# derribo, KO y levantarse
	n.morir()
	await _segundos(1.8)
	_ok(String(n.anim.current_animation) == "derrota", "KO en el suelo (derrota en bucle)")
	n.revivir()
	await _segundos(1.8)
	_ok(not n._muerta and String(n.anim.current_animation) == "guardia", "se levanta y vuelve a la guardia")
	# victoria
	n.victoria()
	await _segundos(0.2)
	_ok(String(n.anim.current_animation) == "victoria", "victoria")
	await _segundos(2.2)
	# exploración y conversación
	n.activar_esperas(true)
	await _segundos(0.4)
	_ok(String(n.anim.current_animation) == "reposo", "en la exploración su reposo es «reposo»")
	var antes := "-"
	var repite := false
	for i in 8:
		var c: String = n.hablar("alegre")
		if c != "" and c == antes:
			repite = true
		antes = c
		await _segundos(0.1)
	_ok(not repite, "conversación: no repite gesto seguido")
	await _segundos(2.6)
	_ok(n.saltar() > 0.0 and n.anim.current_animation == "saltar", "saltar")
	await _segundos(1.2)
	_ok(String(n.anim.current_animation) == "reposo", "tras saltar, reposo")
	n.activar_esperas(false)
	n.queue_free()
	await _frames(3)
