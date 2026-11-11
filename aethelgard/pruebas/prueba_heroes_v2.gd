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
	for h in ORIGINAL:
		if ResourceLoader.exists(HeroesV2.GLB[h]):
			await _heroe(h)
		else:
			print("== ", h, ": sin GLB todavía (se salta)")
	print("COMPROBACIONES: %d · FALLOS: %d" % [comprobaciones, fallos])
	quit(1 if fallos > 0 else 0)


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
	else:
		_ok(n.v2 != null and n.v2.tiene_cara(), "cara expresiva")
		if n.v2 != null and n.v2.tiene_cara():
			n.v2.poner_expresion("sonrisa")
			_ok(n.v2.cara.visible and n.v2.mat_cara.uv1_offset.is_equal_approx(Vector3(0.5, 0, 0)), "expresión «sonrisa»: loseta 2")
			n.v2.poner_expresion("grito")
			_ok(n.v2.mat_cara.uv1_offset.is_equal_approx(Vector3(0, 0.5, 0)), "expresión «grito»: loseta 4")
			n.v2.poner_expresion("normal")
			_ok(not n.v2.cara.visible, "expresión «normal»: la cara original (malla oculta)")
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
