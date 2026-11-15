extends SceneTree
# V12, Érebo híbrida (15/11): la invocación híbrida de Érebo (invocacion_erebo_hibrida.gd, opción de Auditoría APAGADA
# por defecto, valor «hibrida» del selector de la invocación cinematográfica) en combates de verdad, con datos aislados.
#   selector   → «hibrida» enciende la híbrida y apaga el vídeo; «abreviada» al revés; «no», las dos apagadas
#   apagada    → todo como hoy: el teatro de siempre (inv_erebo es el de siempre) y no se crea nada de la híbrida
#   objetivos  → pequeño 2D (Slime, GRUPOS[7]), humanoide 3D (Grimfang, [9]), sin pecho humano (Zarzalín, [10]) y
#                grande sin pecho (Bramavidrio, [13], núcleo en la garganta), y dos JEFES (Guardián de piedra [18], 2D, y
#                Gorthor [5], 3D): todas las fases en orden, la punta de la mano en el contacto, el corazón (o el trozo)
#                en la mano, el orbe solo si hay éxito, el vídeo del ritual arranca, el estado en «accion» todo el rato,
#                la música apartada y devuelta, el resultado UNA vez (muerte / 20 % del jefe / nada), el ATB igual que la
#                invocación de siempre (V.ATB_TEATRO), sin restos (capas, escenario, tiempo, ventanas 3D del combate)
#   enemigo    → el enemigo de verdad (su nodo 3D, mallas y materiales) igual antes y después
#   saltos     → en la señal, en el acercamiento, en la extracción y en el ritual (vídeo): resultado una vez, vuelve
#                en < 3 s, sin restos
#   sin vídeo  → con el ritual sustituido por un vídeo que no arranca: ritual en tiempo real, resultado una vez
#   3d         → «hibrida_3d»: todo en tiempo real
#   azar       → la tirada randi() siguiente es la MISMA con la opción apagada (teatro) y encendida (misma semilla)
# Con «erebo=fallo» (prueba_erebo_hibrida_fallo): resistida contra Grimfang y Zarzalín (el corazón se escapa, sin orbe,
# «sale vacía» una vez, sin daño) y un jefe (siempre 20 %).
# Semillas: «semilla_hibrida=N». No toca la partida real: archivo de partida de prueba y user:// aislado del ejecutor.

const ARCHIVO := "user://prueba_erebo_hibrida.save"

var P
var G
var V
var H
var NU
var A12
var c = null
var fallos: Array = []
var hechos: Array = []
var avisos: Array = []
var reloj := 0.0
var forzado := ""
var semilla := 5151
var _falsos: Array = []
var _randi := {}


func _initialize() -> void:
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	V = load("res://invocacion_erebo_video.gd")
	H = load("res://invocacion_erebo_hibrida.gd")
	NU = load("res://invocacion_erebo_nueva.gd")
	A12 = load("res://combate_anim_v12.gd")
	for a in OS.get_cmdline_user_args():
		if a.begins_with("erebo="):
			forzado = a.substr(6)
		elif a.begins_with("semilla_hibrida="):
			semilla = int(a.get_slice("=", 1))
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_probar.call_deferred()


func _ok(cond: bool, texto: String) -> void:
	if not cond:
		fallos.append(texto)
		print("FALLO: ", texto)


func _esperar(n: int) -> void:
	for i in n:
		await process_frame
		reloj += root.get_process_delta_time()
		if c != null and is_instance_valid(c) and c.estado != "accion":
			for e in c.enemigos:
				e["atb"] = 0.0


func _probar() -> void:
	await _esperar(10)
	_ok(V.permitido(), "la opción solo existe en Auditoría o editor y esta prueba corre en el editor")
	_ok(not H.activa() and V.modo() == "no", "sin ajuste la híbrida y el vídeo deben estar apagados (%s / %s)" % [H.modo(), V.modo()])
	_ok(forzado == "exito" or forzado == "fallo", "falta «erebo=exito» o «erebo=fallo» (%s)" % forzado)
	_ok(not NU.elegida(), "la invocación nueva no debe estar elegida al empezar")
	print("SEMILLA %d · erebo=%s" % [semilla, forzado])
	if forzado == "fallo":
		await _invocar("apagada, fallo", "no", "", 9)
		await _invocar("Grimfang, resistida", "hibrida_breve", "", 9)
		await _invocar("Zarzalín, resistida", "hibrida_breve", "", 10)
		await _invocar("jefe con fallo forzado (Guardián)", "hibrida_breve", "", 18)
		await _invocar("resistida, saltada en la extracción", "hibrida_breve", "saltar:agarra", 9)
	else:
		_selector()
		await _invocar("apagada (teatro de siempre)", "no", "", 9)
		await _invocar("Grimfang, humanoide 3D", "hibrida", "", 9)
		await _invocar("apagada otra vez (control del azar)", "no", "", 9)
		await _invocar("Slime, pequeño 2D", "hibrida_breve", "", 7)
		await _invocar("Zarzalín, sin pecho humano", "hibrida_breve", "", 10)
		await _invocar("Bramavidrio, grande con núcleo", "hibrida_breve", "", 13)
		await _invocar("JEFE Guardián de piedra (2D)", "hibrida", "", 18)
		await _invocar("JEFE Gorthor (3D)", "hibrida_breve", "", 5)
		await _invocar("saltar en la señal", "hibrida_breve", "saltar:senalar", 9)
		await _invocar("saltar en el acercamiento", "hibrida_breve", "saltar:acercamiento", 9)
		await _invocar("saltar en la extracción", "hibrida_breve", "saltar:agarra", 9)
		await _invocar("saltar en el ritual (vídeo)", "hibrida", "saltar:video_arranca", 9)
		await _invocar("todo en tiempo real (hibrida_3d)", "hibrida_3d", "", 9)
		await _sin_video()
		var a: int = _randi.get("apagada (teatro de siempre)", -1)
		var b: int = _randi.get("Grimfang, humanoide 3D", -2)
		var a2: int = _randi.get("apagada otra vez (control del azar)", -3)
		_ok(a == a2, "control: las dos apagadas no dan la misma tirada siguiente (%d / %d)" % [a, a2])
		_ok(a == b, "azar: la tirada randi() siguiente cambia con la híbrida (apagada %d, encendida %d)" % [a, b])
		print("AZAR randi() tras la invocación: apagada %d · híbrida %d · apagada (control) %d" % [a, b, a2])
	H.elegir_modo("no")
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "tipo_combate", "zona", "grupo_activo"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.remove_meta("archivo_partida_prueba")
	print("OK: ", "; ".join(hechos))
	for x in avisos:
		print("AVISO: ", x)
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


func _selector() -> void:
	H.elegir_modo("hibrida")
	_ok(H.modo() == "hibrida" and H.activa() and V.modo() == "no" and V.ruta_para_ahora() == "" and H.valor_selector() == "hibrida",
		"selector «hibrida»: %s / vídeo %s" % [H.modo(), V.modo()])
	H.elegir_modo("abreviada")
	_ok(not H.activa() and V.modo() == "abreviada" and H.valor_selector() == "abreviada", "selector «abreviada»: %s / %s" % [H.modo(), V.modo()])
	H.elegir_modo("no")
	_ok(not H.activa() and V.modo() == "no" and H.valor_selector() == "no", "selector «no»: %s / %s" % [H.modo(), V.modo()])
	_ok(H.ruta_ritual("hibrida") == H.RITUAL and H.ruta_ritual("hibrida_breve") == H.RITUAL_BREVE and H.ruta_ritual("hibrida_3d") == "",
		"rutas del ritual")
	for par in [[H.RITUAL, 12.0], [H.RITUAL_BREVE, 5.0]]:
		var s = load(par[0])
		_ok(s is VideoStreamTheora, "%s no es VideoStreamTheora" % par[0])
	hechos.append("selector y vídeos del ritual")


func _combate(grupo: int) -> Dictionary:
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "tipo_combate", "zona"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	G.datos()
	Engine.set_meta("grupo_activo", ["Kael", "Lya"])
	for n in ["Kael", "Lya"]:
		G.datos()[n]["nivel"] = 5
		G.datos()[n]["pv"] = -1
	Engine.set_meta("zona", "ceniza")
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", grupo)
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)                                 # (aquí su _ready hace randomize())
	seed(semilla)
	for e in c.enemigos:
		e["atb"] = randf() * 30.0
	for i in 3000:
		if c.estado == "menu" and c.menu.activo and c.actor is Dictionary:
			if c.actor["nombre"] == "Lya":
				break
			c._defender()
		await _esperar(1)
	return c.enemigos[0]


func _restos() -> Array:
	var r := []
	for n in ["EreboHibrida", "EreboHibridaEscenario", "EreboHibridaSenal", "EreboCinematica"]:
		if root.find_child(n, true, false) != null:
			r.append(n)
	return r


# Huella del enemigo de verdad: su nodo 3D (o sus dibujos), mallas, materiales y sus valores.
func _huella(obj: Dictionary) -> String:
	var p3d = obj.get("p3d", null)
	var txt := ""
	var raiz: Node = p3d if p3d != null else obj["rig"]
	if p3d != null:
		txt += "pos %s rot %s esc %s vis %s par %s|" % [p3d.position, p3d.rotation, p3d.scale, p3d.visible, p3d.get_parent().get_instance_id()]
	for n in raiz.find_children("*", "", true, false):
		if n is MeshInstance3D:
			txt += "%s m%d o%s v%s|" % [n.name, n.mesh.get_instance_id() if n.mesh else 0, n.material_override, n.material_overlay]
			if n.mesh != null:
				for s in n.mesh.get_surface_count():
					var m = n.get_active_material(s)
					txt += " s%d:%s" % [s, m]
					if m is StandardMaterial3D:
						txt += " %s %s %s" % [m.albedo_color, m.transparency, m.emission_enabled]
					elif m is ShaderMaterial:
						txt += " sh%d" % (m.shader.get_instance_id() if m.shader else 0)
		elif n is Sprite2D or n is AnimatedSprite2D:
			txt += "%s %s|" % [n.name, n.material]
	return txt


func _ventanas() -> Dictionary:
	var r := {}
	for vp in c.find_children("*", "SubViewport", true, false):
		r[vp.get_instance_id()] = vp.render_target_update_mode
	return r


# modo_inv: "no" (apagada) o un valor de la híbrida; accion: "" o "saltar:<fase>".
func _invocar(caso: String, modo_inv: String, accion: String, grupo: int) -> void:
	H.elegir_modo(modo_inv)
	var obj: Dictionary = await _combate(grupo)
	if not (c.actor is Dictionary and c.actor["nombre"] == "Lya"):
		_ok(false, "%s: no llega el turno de Lya" % caso)
		c.queue_free()
		await _esperar(5)
		return
	var hibrida := modo_inv != "no"
	var es_jefe: bool = obj.get("personalidad", "") == "jefe" or obj.get("fases", false) or obj.get("ultimo_aliento", false)
	var exito := es_jefe or forzado == "exito"
	var nueva_sel: bool = NU.elegida()
	var pausa: bool = A12.pausa_atb()
	var i_mus := AudioServer.get_bus_index("Musica")
	var db0 := AudioServer.get_bus_volume_db(i_mus)
	c.armonia = 1.0
	for f in c.heroes + c.enemigos:
		f["vel"] = 2.0
		f["atb"] = 0.0
	var pv0: int = obj["hp"]
	var huella0 := _huella(obj)
	var ventanas0 := _ventanas()
	var hp_previo := pv0
	var cambios := 0
	seed(semilla + 1)
	var t_ini := reloj
	c._invocar_sobre(obj)
	var atb0 := {}
	for h in c.heroes:
		atb0[h["nombre"]] = h["atb"]
	var inv = null
	var vio_hibrida := false
	var vio_teatro := false
	var siempre_accion := true
	var bajo := false
	var vio_orbe := false
	var vio_video := false
	var saltado := false
	var t_salto := -1.0
	var t_fin := -1.0
	var registro: Array = []
	var anuncios := {"corazon": 0, "roba": 0, "vacia": 0}
	var reg_previo := ""
	var fase_salto := accion.get_slice(":", 1) if accion.begins_with("saltar:") else ""
	for i in 6000:
		var n = c.get_node_or_null("EreboHibrida")
		if n != null:
			inv = n
			vio_hibrida = true
			registro = n.registro.duplicate()
			# (el orbe, visto de verdad: después del agarre; al precalentar se enciende un instante en otra capa)
			if n.erebo != null and is_instance_valid(n.erebo) and n.erebo.orbe.visible and n.erebo.orbe.layers & 1 \
					and registro.any(func(r): return r[0] == "agarra"):
				vio_orbe = true
		elif vio_hibrida and t_fin < 0.0:
			t_fin = reloj
		if c.inv_erebo != null and c.inv_erebo.get_script() != H:
			if not vio_teatro:
				vio_teatro = true
				if not hibrida:
					await _esperar(30)
					if c.inv_erebo != null:
						c.inv_erebo.saltar()
		if root.find_child("EreboCinematica", true, false) != null:
			vio_video = true
		if c.estado != "accion" and (inv == null or is_instance_valid(inv)) and t_fin < 0.0 and vio_hibrida:
			siempre_accion = false
		if i_mus >= 0 and AudioServer.get_bus_volume_db(i_mus) < db0 - 1.0:
			bajo = true
		if fase_salto != "" and not saltado and inv != null and is_instance_valid(inv):
			for r in registro:
				if r[0] == fase_salto and inv._t_juego > r[1] + (0.9 if fase_salto == "video_arranca" else 0.25):
					saltado = true
					t_salto = reloj
					await _saltar()
					break
		if obj["hp"] != hp_previo:
			cambios += 1
			hp_previo = obj["hp"]
		if c.registro.text != reg_previo:
			reg_previo = c.registro.text
			if "arranca el corazón" in reg_previo:
				anuncios["corazon"] += 1
			if "roba parte de su vida" in reg_previo:
				anuncios["roba"] += 1
			if "sale vacía" in reg_previo:
				anuncios["vacia"] += 1
		if c.estado == "esperando" or c.estado == "menu" or c.estado == "fin":
			break
		await _esperar(1)
	_randi[caso] = randi()                             # la tirada siguiente (después del seed() del combate)
	var t_vuelta := reloj
	var atb1 := {}
	for h in c.heroes:
		atb1[h["nombre"]] = h["atb"]
	await _esperar(5)
	if obj["hp"] != hp_previo:
		cambios += 1
	var fases: Array = registro.map(func(r): return r[0])
	_ok(c.estado in ["esperando", "menu", "fin"], "%s: el combate no vuelve (estado «%s»)" % [caso, c.estado])
	# ¿qué se vio?
	if not hibrida:
		_ok(vio_teatro and not vio_hibrida, "%s: apagada debe salir el teatro de siempre (teatro %s, híbrida %s)" % [caso, vio_teatro, vio_hibrida])
	else:
		_ok(vio_hibrida and not vio_teatro, "%s: híbrida %s, teatro %s" % [caso, vio_hibrida, vio_teatro])
		_ok(siempre_accion, "%s: el estado sale de «accion» durante la híbrida" % caso)
		_ok(bajo, "%s: la música no se aparta" % caso)
		if fase_salto == "":
			var esperadas := ["senalar", "objetivo", "aparece", "acercamiento", "mano", "contacto", "agarra"]
			if not exito:
				esperadas += ["se_escapa", "fallo"]
			elif es_jefe:
				esperadas += ["trozo", "en_la_mano", "orbe"]
			else:
				esperadas += ["sale", "en_la_mano", "orbe"]
			if exito:
				esperadas += ["ritual_video", "video_arranca"] if modo_inv != "hibrida_3d" else ["ritual_3d"]
			var k := 0
			for f in fases:
				if k < esperadas.size() and f == esperadas[k]:
					k += 1
			_ok(k == esperadas.size(), "%s: fases %s (faltan desde «%s»)" % [caso, fases, esperadas[k] if k < esperadas.size() else ""])
			_ok(vio_orbe == exito, "%s: orbe %s con %s" % [caso, vio_orbe, "éxito" if exito else "fallo"])
			_ok(vio_video == (exito and modo_inv != "hibrida_3d"), "%s: vídeo del ritual %s" % [caso, vio_video])
			for r in registro:
				if r[0] == "error_mano":
					_ok(r[1] < 0.15, "%s: la punta de la mano queda a %.3f m del contacto" % [caso, r[1]])
				if r[0] == "corazon_mano":
					_ok(r[1] < 0.12 and r[2], "%s: el corazón no está en la mano (%.3f m, visible %s)" % [caso, r[1], r[2]])
				if r[0] == "medida":
					print("%s: caja %s · contacto %s · escala de Érebo %.2f" % [caso, r[1], r[2], r[3]])
		else:
			_ok(saltado, "%s: no se llegó a la fase «%s» para saltar (%s)" % [caso, fase_salto, fases])
			var antes := ""                              # la fase en la que se saltó (sin las de diagnóstico)
			for f in fases:
				if f == "saltada":
					break
				if not f in ["medida", "error_mano", "corazon_mano"]:
					antes = f
			_ok(antes == fase_salto, "%s: se saltó en «%s» y no en «%s»" % [caso, antes, fase_salto])
			_ok(t_fin > 0.0 and t_fin - t_salto < 3.0, "%s: tras saltar tarda %.2f s en volver" % [caso, t_fin - t_salto])
		# ATB: el de la invocación de siempre
		if pausa:
			var presupuesto: float = V.atb_teatro(nueva_sel, exito)
			var t_post := t_vuelta - t_fin + 1.0 / 30.0
			for h in c.heroes:
				if h["hp"] <= 0 or h["nombre"] == "Lya":
					continue
				var esperado: float = minf(100.0, atb0[h["nombre"]] + 2.0 * (presupuesto + t_post))
				_ok(absf(atb1[h["nombre"]] - esperado) < 0.6, "%s: ATB de %s %.2f (esperado %.2f)" % [caso, h["nombre"], atb1[h["nombre"]], esperado])
		_ok(int(c.get_meta("c12_accion", 0)) == 0, "%s: queda la pausa del ATB puesta" % caso)
	# el resultado, una vez
	if exito:
		_ok(cambios == 1, "%s: los PV cambian %d veces (debe ser 1)" % [caso, cambios])
	else:
		_ok(cambios == 0 and obj["hp"] == pv0, "%s: con fallo cambian los PV (%d → %d)" % [caso, pv0, obj["hp"]])
	if es_jefe:
		var ej: int = maxi(1, int(round(pv0 * 0.2)))
		_ok(pv0 - int(obj["hp"]) == ej and obj["hp"] > 0, "%s: el jefe pierde %d (esperado %d)" % [caso, pv0 - int(obj["hp"]), ej])
		_ok(anuncios["roba"] == 1 and anuncios["corazon"] == 0 and anuncios["vacia"] == 0, "%s: registro %s" % [caso, anuncios])
		if hibrida:
			_ok(_huella(obj) == huella0, "%s: el enemigo de verdad (nodo, mallas o materiales) ha cambiado" % caso)
	elif exito:
		_ok(obj["hp"] <= 0, "%s: el éxito no mata (%d → %d)" % [caso, pv0, obj["hp"]])
		_ok(anuncios["corazon"] == 1 and anuncios["vacia"] == 0 and anuncios["roba"] == 0, "%s: registro %s" % [caso, anuncios])
	else:
		_ok(anuncios["vacia"] == 1 and anuncios["corazon"] == 0 and anuncios["roba"] == 0, "%s: registro %s" % [caso, anuncios])
		if hibrida:
			_ok(_huella(obj) == huella0, "%s: el enemigo de verdad (nodo, mallas o materiales) ha cambiado" % caso)
	_ok(is_equal_approx(AudioServer.get_bus_volume_db(i_mus), db0), "%s: la música no vuelve (%.1f / %.1f dB)" % [caso, AudioServer.get_bus_volume_db(i_mus), db0])
	_ok(_restos().is_empty(), "%s: quedan restos %s" % [caso, _restos()])
	_ok(is_equal_approx(Engine.time_scale, 1.0), "%s: el tiempo no vuelve a 1" % caso)
	_ok(c.inv_erebo == null, "%s: queda inv_erebo" % caso)
	_ok(c.escena.visible, "%s: los luchadores no vuelven a verse" % caso)
	var ventanas1 := _ventanas()
	for id in ventanas0:
		if ventanas1.has(id):
			_ok(ventanas1[id] == ventanas0[id], "%s: una ventana 3D del combate no vuelve a su modo (%d → %d)" % [caso, ventanas0[id], ventanas1[id]])
	print("%s: %.1f s · fases %s" % [caso, (t_fin if t_fin > 0 else t_vuelta) - t_ini, registro.map(func(r): return "%s %.2f" % [r[0], r[1]] if r[1] is float else r[0])])
	c.queue_free()
	c = null
	Engine.time_scale = 1.0
	await _esperar(5)
	hechos.append(caso)


func _saltar() -> void:
	var ac := InputEventAction.new()
	ac.action = "ui_cancel"
	ac.pressed = true
	root.push_input(ac)
	await _esperar(1)
	_ok(c.saltar_invocacion, "la entrada para saltar no llega al combate")


# El ritual sustituido (en la caché de recursos, solo en esta prueba) por un vídeo que no arranca y por un Theora que no
# se abre: la híbrida hace el ritual en tiempo real y el combate vuelve solo.
func _sin_video() -> void:
	for tipo in ["sin_reproduccion", "theora_sin_archivo"]:
		var real = ResourceLoader.load(H.RITUAL_BREVE, "", ResourceLoader.CACHE_MODE_IGNORE)
		var falso: Resource
		if tipo == "theora_sin_archivo":
			falso = VideoStreamTheora.new()
			falso.file = "res://videos/no_existe_prueba_hibrida.ogv"
		else:
			falso = VideoStream.new()
		falso.take_over_path(H.RITUAL_BREVE)
		_falsos.append(falso)
		var n0 := fallos.size()
		await _invocar_sin_video(tipo)
		if real is Resource:
			real.take_over_path(H.RITUAL_BREVE)
		if fallos.size() == n0:
			hechos.append("sin vídeo (%s): ritual en tiempo real" % tipo)


func _invocar_sin_video(tipo: String) -> void:
	H.elegir_modo("hibrida_breve")
	var obj: Dictionary = await _combate(9)
	c.armonia = 1.0
	var pv0: int = obj["hp"]
	seed(semilla + 1)
	c._invocar_sobre(obj)
	var reg: Array = []
	var cambios := 0
	var hp := pv0
	var t0 := reloj
	for i in 6000:
		var n = c.get_node_or_null("EreboHibrida")
		if n != null:
			reg = n.registro.map(func(r): return r[0])
		if obj["hp"] != hp:
			cambios += 1
			hp = obj["hp"]
		if c.estado == "esperando" or c.estado == "menu" or c.estado == "fin":
			break
		await _esperar(1)
	await _esperar(5)
	_ok(c.estado in ["esperando", "menu", "fin"], "sin vídeo (%s): el combate no vuelve" % tipo)
	_ok("ritual_3d" in reg, "sin vídeo (%s): no hace el ritual en tiempo real (%s)" % [tipo, reg])
	_ok(cambios == 1 and obj["hp"] <= 0, "sin vídeo (%s): resultado %d veces" % [tipo, cambios])
	_ok(_restos().is_empty(), "sin vídeo (%s): quedan restos %s" % [tipo, _restos()])
	print("sin vídeo (%s): %.1f s · %s" % [tipo, reloj - t0, reg])
	c.queue_free()
	c = null
	await _esperar(5)
