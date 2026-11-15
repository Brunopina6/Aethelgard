extends SceneTree
# V12 (14/11): la invocación cinematográfica de Érebo en vídeo (invocacion_erebo_video.gd), opción de Auditoría
# APAGADA por defecto, en un combate de verdad con datos aislados y «erebo=exito»:
#   apagado    → sin ajuste no hay vídeo: se usa el teatro de siempre (inv_erebo aparece)
#   vídeos     → los dos .ogv se cargan como VideoStreamTheora, duran ≈20,0 s y ≈6,8 s y se reproducen
#   abreviada  → el vídeo tapa el combate, el teatro NO se crea, el estado sigue en «accion» todo el rato (no se abre
#                otro turno), el resultado se aplica UNA vez al acabar, la música vuelve a su volumen y no quedan restos
#   saltar     → un toque de verdad corta el vídeo enseguida y el resultado se aplica igual, una vez; también si se toca
#                durante el fundido de entrada (no debe tomarse por fallo ni sacar el teatro)
#   ATB        → el vídeo da el MISMO tiempo de ATB que la invocación de siempre (V.ATB_TEATRO), sea cual sea su duración
#   primera    → «1.ª completa»: la primera vez el vídeo completo; después, el abreviado
# 15/11 (auditoría sobre da0e336), además:
#   no carga   → reproducir() con una ruta que no existe devuelve false sin crear nada; con un VideoStream que no
#                arranca, false en ≈1,5 s, sin restos y con la música en su sitio
#   no arranca → en el combate, con el vídeo abreviado sustituido (en la caché de recursos, solo en esta prueba) por uno
#                que no arranca: cae al teatro de siempre sin colgarse, el resultado una vez y sin restos
#   jefe       → con vídeo, el Guardián de piedra (GRUPOS[18]): siempre «éxito», quita maxi(1, round(PV × 0,2)), una vez
#   nueva      → «erebo_nueva» con vídeo: el ATB de V.ATB_TEATRO["nueva"]
#   completa   → el vídeo completo hasta el final
#   sin pausa  → con «pausa_atb» desactivado, el ATB corre durante todo el vídeo (como en la primera entrega)
# 16/11 (recuperación automática, autorizada): sin tocar nada,
#   theora que no abre → reproducir() sale solo en ≈1,5 s (antes esperaba al toque); en el combate, el teatro de
#                siempre, sin pantalla negra y SIN ATB de más por el intento (el ATB del vídeo empieza al avanzar)
#   se para    → el vídeo deja de avanzar a mitad: salida controlada en ≈1 s, resultado una vez, ATB de la invocación de
#                siempre, música, estado y capa en su sitio
# Con «erebo=fallo» (prueba_erebo_video_fallo): apagado y abreviada con fallo (ni daño ni «corazón»: «sale vacía»; ATB
# de fallo), la nueva con fallo y un jefe (los jefes siempre, aunque se fuerce el fallo).
# Azar: la semilla se pone DESPUÉS de root.add_child(c) (combate._ready hace randomize()) y otra justo antes de
# _invocar_sobre; «semilla_video=N» para reproducir otra.
# No toca la partida real: archivo de partida de prueba y user:// aislado del ejecutor.

const ARCHIVO := "user://prueba_erebo_video.save"
const NO_EXISTE := "res://videos/no_existe_prueba_erebo.ogv"
const NO_ARRANCA := "res://videos/no_arranca_prueba_erebo.ogv"   # (solo en la caché de recursos de esta prueba)
const NO_ARRANCA_THEORA := "res://videos/no_abre_prueba_erebo.ogv"   # (ídem)

var P
var G
var V
var NU
var A12
var c = null
var fallos: Array = []
var hechos: Array = []
var avisos: Array = []
var reloj := 0.0              # tiempo de juego (el ejecutor puede ir más rápido que el reloj real)
var forzado := ""
var semilla := 4242
var _falsos: Array = []
var _atb_teatro_base := -1.0          # ATB de Kael al empezar el teatro SIN vídeo (caso «apagado»): la referencia


func _initialize() -> void:
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	V = load("res://invocacion_erebo_video.gd")
	NU = load("res://invocacion_erebo_nueva.gd")
	A12 = load("res://combate_anim_v12.gd")
	for a in OS.get_cmdline_user_args():
		if a.begins_with("erebo="):
			forzado = a.substr(6)
		elif a.begins_with("semilla_video="):
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


func _capa() -> Node:
	return root.find_child("EreboCinematica", true, false)


func _probar() -> void:
	await _esperar(10)
	_ok(V.permitido(), "la opción solo existe en Auditoría o editor y esta prueba corre en el editor")
	_ok(V.modo() == "no", "sin ajuste la opción debe estar apagada (está «%s»)" % V.modo())
	_ok(V.ruta_para_ahora() == "", "apagada no debe elegir vídeo")
	_ok(forzado == "exito" or forzado == "fallo", "falta «erebo=exito» o «erebo=fallo» (%s)" % forzado)
	_ok(not NU.elegida(), "la invocación nueva no debe estar elegida al empezar")
	print("SEMILLA %d · erebo=%s" % [semilla, forzado])
	if forzado == "fallo":
		await _invocar("apagado, fallo", "", false)
		V.elegir("abreviada")
		await _invocar("abreviada, fallo", "", true)
		NU.elegir(true)
		await _invocar("nueva con vídeo, fallo", "", true)
		NU.elegir(false)
		await _invocar("jefe con fallo forzado", "", true, 18)
	else:
		await _no_carga()
		await _videos()
		await _invocar("apagado", "", false)
		V.elegir("abreviada")
		await _invocar("abreviada", "", true)
		await _invocar("saltar", "saltar", true)
		await _invocar("saltar durante el fundido", "saltar_pronto", true)
		await _invocar("jefe", "", true, 18)
		NU.elegir(true)
		await _invocar("nueva con vídeo", "", true)
		NU.elegir(false)
		Engine.set_meta("pausa_atb_v12", false)
		await _invocar("sin pausa del ATB", "", true)
		Engine.remove_meta("pausa_atb_v12")
		V.elegir("completa")
		await _invocar("completa hasta el final", "", true)
		V.elegir("primera")
		var r1: String = V.ruta_para_ahora()
		_ok(r1 == V.COMPLETA, "primera: la primera vez debe ser la completa (%s)" % r1)
		await _invocar("primera (completa, saltada)", "saltar", true)
		var r2: String = V.ruta_para_ahora()
		_ok(r2 == V.ABREVIADA, "primera: después debe ser la abreviada (%s)" % r2)
		V.elegir("abreviada")
		await _invocar("se para a mitad", "se_para", true)
		await _no_arranca_en_combate()
		await _theora_no_abre_en_combate()
	V.elegir("no")
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "tipo_combate", "zona", "grupo_activo"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.remove_meta("archivo_partida_prueba")
	print("OK: ", "; ".join(hechos))
	for a in avisos:
		print("AVISO: ", a)
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


func _videos() -> void:
	for par in [[V.COMPLETA, 20.0], [V.ABREVIADA, 6.8]]:
		var ruta: String = par[0]
		_ok(ResourceLoader.exists(ruta), "falta %s" % ruta)
		if not ResourceLoader.exists(ruta):
			continue
		var s = load(ruta)
		_ok(s is VideoStreamTheora, "%s no es VideoStreamTheora (%s)" % [ruta, s])
		var vp := VideoStreamPlayer.new()
		vp.stream = s
		root.add_child(vp)
		vp.play()
		await _esperar(20)
		var largo: float = vp.get_stream_length()
		_ok(absf(largo - par[1]) < 0.25, "%s dura %.2f s (esperado ≈%.1f)" % [ruta, largo, par[1]])
		_ok(vp.is_playing(), "%s no se reproduce" % ruta)
		var pos: float = vp.stream_position
		_ok(pos > 0.05, "%s no avanza (posición %.3f)" % [ruta, pos])
		print("VIDEO %s: %.2f s, posición %.3f tras 20 fotogramas" % [ruta.get_file(), largo, pos])
		vp.stop()
		vp.queue_free()
		await _esperar(2)
	hechos.append("vídeos")


# Un VideoStream que no arranca, puesto en la caché de recursos con la ruta pedida (load() lo devuelve de ahí). Nada de
# esto toca el juego: vive solo en este proceso.
#   «sin_reproduccion»: un VideoStream sin reproductor (play() no hace nada; is_playing() es falso): el caso que
#                       reproducir() espera («no arranca en 1,5 s»).
#   «theora_sin_archivo»: un Theora cuyo archivo no se abre (ver el HALLAZGO de _no_carga).
func _video_falso(ruta: String, tipo := "sin_reproduccion") -> Resource:
	var falso: Resource
	if tipo == "theora_sin_archivo":
		falso = VideoStreamTheora.new()
		falso.file = NO_EXISTE
	else:
		falso = VideoStream.new()
	falso.take_over_path(ruta)
	_falsos.append(falso)                           # (la caché no lo sujeta: sin otra referencia se borraría)
	return falso


# reproducir() a solas: sin vídeo (false, al momento, sin crear nada) y con un vídeo que no arranca (false en ≈1,5 s).
func _no_carga() -> void:
	var i_mus := AudioServer.get_bus_index("Musica")
	var db0 := AudioServer.get_bus_volume_db(i_mus) if i_mus >= 0 else 0.0
	var padre := Node.new()
	root.add_child(padre)
	var t0 := reloj
	var ok1: bool = await V.reproducir(padre, NO_EXISTE, func(): return false)
	_ok(not ok1, "no carga: con una ruta que no existe reproducir() devuelve true")
	_ok(reloj - t0 < 0.01 and padre.get_child_count() == 0, "no carga: sin vídeo tarda %.2f s o deja %d nodos" % [reloj - t0, padre.get_child_count()])
	# no arranca: un VideoStream sin reproductor
	_video_falso(NO_ARRANCA)
	var r: Dictionary = await _reproducir_a_solas(padre, NO_ARRANCA, -1.0)
	_ok(r["hecho"], "no arranca: reproducir() se queda colgado (%.1f s)" % r["dura"])
	_ok(r["ok"] == false, "no arranca: reproducir() no devuelve false (%s)" % str(r["ok"]))
	_ok(r["dura"] > 1.5 and r["dura"] < 3.0, "no arranca: tarda %.2f s (esperado ≈1,5 s más los fundidos)" % r["dura"])
	_ok(r["bajo"], "no arranca: la música no se aparta mientras lo intenta")
	_ok(_capa() == null and padre.get_child_count() == 0, "no arranca: quedan restos (%d nodos)" % padre.get_child_count())
	_ok(i_mus < 0 or is_equal_approx(AudioServer.get_bus_volume_db(i_mus), db0), "no arranca: la música no vuelve a su volumen")
	var dura_no_arranca: float = r["dura"]
	# Un Theora cuyo archivo no se abre da is_playing() = true y get_stream_length() = 0. Hasta el 16/11 reproducir()
	# esperaba al toque (pantalla negra); ahora debe salir SOLO, en ≈1,5 s y sin restos.
	_video_falso(NO_ARRANCA_THEORA, "theora_sin_archivo")
	r = await _reproducir_a_solas(padre, NO_ARRANCA_THEORA, 4.0)
	_ok(not r["colgado"] and r["ok"] == false and r["dura"] < 3.0,
		"theora sin archivo: no sale solo (colgado %s, ok %s, %.2f s)" % [r["colgado"], str(r["ok"]), r["dura"]])
	if r["colgado"]:
		avisos.append(("HALLAZGO sin arreglar (Érebo congelado): un vídeo Theora que no se abre deja reproducir() esperando " +
			"(is_playing() %s, posición %.3f, largo %.2f a los 4 s de juego) hasta que se toca para saltar; tocando sale " +
			"en %.2f s más y devuelve %s") % [r["jugando"], r["posicion"], r["largo"], r["dura"] - 4.0, str(r["ok"])])
	_ok(r["hecho"], "theora sin archivo: ni tocando para saltar sale de reproducir() (%.1f s)" % r["dura"])
	_ok(_capa() == null and padre.get_child_count() == 0, "theora sin archivo: quedan restos (%d nodos)" % padre.get_child_count())
	_ok(i_mus < 0 or is_equal_approx(AudioServer.get_bus_volume_db(i_mus), db0), "theora sin archivo: la música no vuelve a su volumen")
	padre.queue_free()
	await _esperar(2)
	hechos.append("no carga (al momento) y no arranca (%.2f s), sin restos; theora sin archivo: %s" % [dura_no_arranca,
		"espera al toque (AVISO)" if r["colgado"] else "corta solo"])


# Lanza reproducir() a solas y lo vigila (como mucho 10 s de juego). Con «saltar_a» >= 0, a ese tiempo (s de juego) se
# «toca» para saltar si aún no ha acabado.
func _reproducir_a_solas(padre: Node, ruta: String, saltar_a: float) -> Dictionary:
	var i_mus := AudioServer.get_bus_index("Musica")
	var db0 := AudioServer.get_bus_volume_db(i_mus) if i_mus >= 0 else 0.0
	var t0 := reloj
	var r := {"ok": null, "hecho": false, "bajo": false, "colgado": false, "jugando": false, "posicion": 0.0, "largo": 0.0}
	var saltar_ya := [false]
	var lanzar := func():
		r["ok"] = await V.reproducir(padre, ruta, func(): return saltar_ya[0])
		r["hecho"] = true
	lanzar.call()
	for i in 300:
		if r["hecho"]:
			break
		if i_mus >= 0 and AudioServer.get_bus_volume_db(i_mus) < db0 - 1.0:
			r["bajo"] = true
		if saltar_a >= 0.0 and not saltar_ya[0] and reloj - t0 >= saltar_a:
			r["colgado"] = true
			var vp = null
			for n in padre.find_children("*", "VideoStreamPlayer", true, false):
				vp = n
			if vp != null:
				r["jugando"] = vp.is_playing()
				r["posicion"] = vp.stream_position
				r["largo"] = vp.get_stream_length()
			saltar_ya[0] = true
		await _esperar(1)
	r["dura"] = reloj - t0
	await _esperar(2)
	return r


# En el combate: el vídeo abreviado sustituido por uno que no arranca → el teatro de siempre, el resultado una vez.
func _no_arranca_en_combate() -> void:
	V.elegir("abreviada")
	var real = ResourceLoader.load(V.ABREVIADA, "", ResourceLoader.CACHE_MODE_IGNORE)
	var falso := _video_falso(V.ABREVIADA)
	_ok(load(V.ABREVIADA) == falso and V.ruta_para_ahora() == V.ABREVIADA, "no arranca: la sustitución en la caché no vale")
	await _invocar("vídeo que no arranca", "no_arranca", true)
	if real is Resource:
		real.take_over_path(V.ABREVIADA)            # (el de verdad, otra vez en la caché)


# 16/11: en el combate, el abreviado sustituido por un Theora que no se abre: el teatro de siempre SIN tocar.
func _theora_no_abre_en_combate() -> void:
	V.elegir("abreviada")
	var real = ResourceLoader.load(V.ABREVIADA, "", ResourceLoader.CACHE_MODE_IGNORE)
	_video_falso(V.ABREVIADA, "theora_sin_archivo")
	await _invocar("theora que no abre", "theora_no_abre", true)
	if real is Resource:
		real.take_over_path(V.ABREVIADA)


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
	seed(semilla)                                     # desde aquí, el azar del combate es fijo
	for e in c.enemigos:
		e["atb"] = randf() * 30.0                     # el ATB inicial, como en combate.gd, ya con la semilla
	for i in 3000:
		if c.estado == "menu" and c.menu.activo and c.actor is Dictionary:
			if c.actor["nombre"] == "Lya":
				break
			c._defender()
		await _esperar(1)
	return c.enemigos[0]


func _tocar() -> void:
	# un toque de verdad en el centro de la pantalla (lo recoge «fuera», como en el juego)
	for pulsado in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = pulsado
		ev.position = Vector2(640, 360)
		ev.global_position = ev.position
		root.push_input(ev)
	await _esperar(2)
	if not c.saltar_invocacion:
		# sin ventana el toque no llega a «fuera»: se salta con Esc, la otra entrada real (_unhandled_input)
		print("AVISO: sin ventana el toque no llega; se salta con Esc (ui_cancel)")
		var ac := InputEventAction.new()
		ac.action = "ui_cancel"
		ac.pressed = true
		root.push_input(ac)
		await _esperar(1)
	_ok(c.saltar_invocacion, "la entrada para saltar no llega al combate")


# modo: "" (hasta el final), "saltar" (toque a los 0,9 s del vídeo), "saltar_pronto" (toque durante el fundido) o
# "no_arranca" (el vídeo no arranca y se usa el teatro).
func _invocar(caso: String, modo: String, video: bool, grupo := 9) -> void:
	var grim: Dictionary = await _combate(grupo)
	if not (c.actor is Dictionary and c.actor["nombre"] == "Lya"):
		_ok(false, "%s: no llega el turno de Lya" % caso)
		c.queue_free()
		await _esperar(5)
		return
	var es_jefe := grupo == 18
	var exito := es_jefe or forzado == "exito"
	var nueva_sel: bool = NU.elegida()
	var pausa: bool = A12.pausa_atb()
	var ruta: String = V.ruta_para_ahora()
	var largo: float = {V.COMPLETA: 20.0, V.ABREVIADA: 6.8}.get(ruta, 0.0)   # (medidos en _videos, ±0,25 s)
	var i_mus := AudioServer.get_bus_index("Musica")
	var db0 := AudioServer.get_bus_volume_db(i_mus)
	c.armonia = 1.0
	# ATB lento y desde cero para poder comprobar cuánto corre (sin llegar al tope)
	for f in c.heroes + c.enemigos:
		f["vel"] = 2.0
		f["atb"] = 0.0
	var pv0: int = grim["hp"]
	var quitados := [0]
	var hp_previo := [pv0]
	seed(semilla + 1)                                 # el azar de la invocación, fijo
	var t_ini := reloj
	c._invocar_sobre(grim)
	var atb0 := {}
	for h in c.heroes:
		atb0[h["nombre"]] = h["atb"]
	var vio_capa := false
	var vio_teatro := false
	var siempre_accion := true
	var bajo_musica := false
	var tocado := false
	var t_capa := -1.0
	var t_fin_capa := -1.0
	var f_capa := 0
	var pos_max := 0.0
	var pausado := false
	var atb_al_teatro := {}
	var anuncios := {"corazon": 0, "roba": 0, "vacia": 0}
	var reg_previo := ""
	for i in 3000:
		var capa := _capa()
		if capa != null:
			if not vio_capa:
				t_capa = reloj
			vio_capa = true
			f_capa += 1
			for n in capa.find_children("*", "VideoStreamPlayer", true, false):
				pos_max = maxf(pos_max, n.stream_position)
			if c.estado != "accion":
				siempre_accion = false
			if AudioServer.get_bus_volume_db(i_mus) < db0 - 1.0:
				bajo_musica = true
			if modo == "se_para" and not pausado and reloj - t_capa > 1.4:
				for n in capa.find_children("*", "VideoStreamPlayer", true, false):
					n.paused = true                         # (el vídeo deja de avanzar, como un fallo de decodificación)
					pausado = true
			if not tocado and ((modo == "saltar" and reloj - t_capa > 0.9) or (modo == "saltar_pronto" and f_capa == 2)):
				tocado = true
				await _tocar()
		elif vio_capa and t_fin_capa < 0:
			t_fin_capa = reloj
		if c.inv_erebo != null and not vio_teatro:
			vio_teatro = true
			for h in c.heroes:
				atb_al_teatro[h["nombre"]] = h["atb"]
			if not video or modo in ["no_arranca", "theora_no_abre"]:
				_ok(_capa() == null, "%s: el teatro sale con la capa del vídeo aún puesta" % caso)
				await _esperar(30)
				if c.inv_erebo != null:
					c.inv_erebo.saltar()
		if grim["hp"] != hp_previo[0]:
			quitados[0] += 1
			hp_previo[0] = grim["hp"]
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
	var t_vuelta := reloj
	var colgado: bool = not (c.estado == "esperando" or c.estado == "menu" or c.estado == "fin")
	var atb1 := {}
	for h in c.heroes:
		atb1[h["nombre"]] = h["atb"]
	await _esperar(5)
	if grim["hp"] != hp_previo[0]:
		quitados[0] += 1
	_ok(not colgado, "%s: el combate no vuelve (estado «%s»)" % [caso, c.estado])
	if modo in ["no_arranca", "theora_no_abre"]:
		_ok(vio_capa and vio_teatro, "%s: no intenta el vídeo (%s) o no cae al teatro (%s)" % [caso, vio_capa, vio_teatro])
		_ok(not tocado, "%s: hizo falta tocar" % caso)
		if pausa and atb_al_teatro.has("Kael") and _atb_teatro_base >= 0.0:   # (16/11) el intento fallido no corre ATB
			var extra_t: float = float(atb_al_teatro["Kael"]) - float(atb0.get("Kael", 0.0)) - _atb_teatro_base
			_ok(absf(extra_t) < 0.25, "%s: el intento de vídeo corre ATB (%.2f de más al empezar el teatro, frente al teatro sin vídeo)" % [caso, extra_t])
		_ok(int(c.get_meta("c12_accion", 0)) == 0, "%s: queda la pausa del ATB puesta (%d)" % [caso, int(c.get_meta("c12_accion", 0))])
		var extra: float = (atb1.get("Kael", 0.0) - atb0.get("Kael", 0.0)) / 2.0
		print("%s: capa %.2f s, ATB de Kael %.2f (≈%.2f s de ATB en total, el intento de vídeo incluido)" % [caso,
			t_fin_capa - t_capa, atb1.get("Kael", 0.0), extra])
	else:
		_ok(vio_capa == video, "%s: vídeo %s (esperado %s)" % [caso, vio_capa, video])
	if not video:
		_ok(vio_teatro, "%s: apagada debe usarse el teatro de siempre" % caso)
		if atb_al_teatro.has("Kael") and _atb_teatro_base < 0.0:
			_atb_teatro_base = float(atb_al_teatro["Kael"]) - float(atb0.get("Kael", 0.0))
		print("%s: teatro (saltado a los 30 fotogramas); ATB de Kael %.2f (≈%.2f s de ATB en total)" % [caso,
			atb1.get("Kael", 0.0), (atb1.get("Kael", 0.0) - atb0.get("Kael", 0.0)) / 2.0])
	elif not modo in ["no_arranca", "theora_no_abre"]:
		_ok(not vio_teatro, "%s: con vídeo no debe crearse el teatro 3D" % caso)
		_ok(siempre_accion, "%s: el estado sale de «accion» durante el vídeo (podría abrirse otro turno)" % caso)
		_ok(bajo_musica, "%s: la música no se aparta durante el vídeo" % caso)
		var dura := t_fin_capa - t_capa
		if modo.begins_with("saltar"):
			_ok(dura < 3.0, "%s: saltar no corta el vídeo (%.1f s)" % [caso, dura])
		elif modo == "se_para":
			_ok(pausado and not tocado and dura > 1.4 and dura < 4.5,
				"%s: parado a mitad no sale solo a tiempo (%.1f s en pantalla, parado %s, tocado %s)" % [caso, dura, pausado, tocado])
		else:
			_ok(largo > 0.0 and dura > largo - 0.2 and dura < largo + 5.0, "%s: el vídeo de %.1f s dura %.1f s en pantalla" % [caso, largo, dura])
		var presupuesto: float = V.atb_teatro(nueva_sel, exito)
		var t_post := t_vuelta - t_fin_capa + 1.0 / 30.0
		for h in c.heroes:
			if h["hp"] <= 0 or h["nombre"] == "Lya":         # (a quien invoca, su turno le deja el ATB a 0, como siempre)
				continue
			var esperado: float
			if pausa:
				# el mismo tiempo que la invocación de siempre con ese resultado, más lo que corre normal tras el vídeo
				esperado = minf(100.0, atb0[h["nombre"]] + 2.0 * (presupuesto + t_post))
			else:
				# sin la pausa, el ATB corre todo el rato, como en la primera entrega (ni más ni menos)
				esperado = minf(100.0, atb0[h["nombre"]] + 2.0 * (t_vuelta - t_ini))
			_ok(absf(atb1[h["nombre"]] - esperado) < 0.6, "%s: ATB de %s %.2f (esperado %.2f, %s)" % [caso, h["nombre"],
				atb1[h["nombre"]], esperado, "invocación de siempre" if pausa else "sin pausa"])
		print("%s: vídeo en pantalla %.2f s (posición alcanzada %.2f de %.1f s); ATB %s (%s; presupuesto %.2f s + %.2f s después)" % [
			caso, dura, pos_max, largo, atb1, "con pausa" if pausa else "sin pausa", presupuesto, t_post])
	# el resultado, una vez
	if exito:
		_ok(quitados[0] == 1, "%s: los PV del enemigo cambian %d veces (debe ser 1)" % [caso, quitados[0]])
	else:
		_ok(quitados[0] == 0 and grim["hp"] == pv0, "%s: con fallo los PV del enemigo cambian (%d → %d, %d veces)" % [caso, pv0, grim["hp"], quitados[0]])
	if es_jefe:
		var esperado_j: int = maxi(1, int(round(pv0 * 0.2)))
		_ok(pv0 - int(grim["hp"]) == esperado_j and grim["hp"] > 0, "%s: el jefe pierde %d (esperado %d = 20 %% de %d, sin morir)" % [
			caso, pv0 - int(grim["hp"]), esperado_j, pv0])
		_ok(anuncios["roba"] == 1 and anuncios["corazon"] == 0 and anuncios["vacia"] == 0, "%s: el registro anuncia %s (debe ser un «roba parte de su vida»)" % [caso, anuncios])
	elif exito:
		_ok(grim["hp"] <= 0 and pv0 > 0, "%s: el resultado (éxito forzado) no se aplica (%d → %d)" % [caso, pv0, grim["hp"]])
		_ok(anuncios["corazon"] == 1 and anuncios["vacia"] == 0 and anuncios["roba"] == 0, "%s: el registro anuncia el resultado %s (debe ser un «arranca el corazón»)" % [caso, anuncios])
	else:
		_ok(anuncios["vacia"] == 1 and anuncios["corazon"] == 0 and anuncios["roba"] == 0, "%s: el registro anuncia %s (debe ser un «sale vacía»)" % [caso, anuncios])
	_ok(is_equal_approx(AudioServer.get_bus_volume_db(i_mus), db0), "%s: la música no vuelve a su volumen (%.1f / %.1f dB)" % [caso, AudioServer.get_bus_volume_db(i_mus), db0])
	_ok(_capa() == null, "%s: queda la capa del vídeo" % caso)
	_ok(is_equal_approx(Engine.time_scale, 1.0), "%s: el tiempo no vuelve a 1" % caso)
	c.queue_free()
	c = null
	Engine.time_scale = 1.0
	await _esperar(5)
	hechos.append(caso)
