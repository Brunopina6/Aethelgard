extends SceneTree
# El clímax musical de los grandes jefes (V12; combate_climax.gd y sus ganchos en combate.gd), en combates de verdad
# (combate.tscn) sin ventana y con datos aislados. El combate se congela (velocidades a 0: nadie actúa) y la vida del jefe
# se pone y se quita con el mismo _quitar_pv que usan los golpes. Las esperas de audio van en milisegundos reales: con
# --fixed-fps los fotogramas van más rápido que el reloj y el audio suena al ritmo del reloj.
#   1. Del 30 % al 21 %: no se activa.            2. Del 21 % al 20 %: se activa (una vez), tras acabar el golpe.
#   3. Del 50 % al 10 % de un golpe: se activa.    4. Muere de un golpe que cruza el umbral: no se activa.
#   5. Más golpes después: no reinicia (ni la canción ni el aviso).  6. Se cura por encima: sigue igual; al volver a
#      bajar, nada.                                 7. Victoria: suena la de siempre y la canción se apaga.
#   8. Derrota: suena la derrota y la canción se apaga.   9. Huida (permitida en un combate normal): cierre correcto.
#  10. Varios jefes autorizados: un solo clímax.  11. No autorizados (el Coloso; un élite): la música de siempre.
#  12. Cambio de escena: ningún reproductor se queda.  13. La vida mal puesta (hp_max 0) nunca lo activa; la fase 2 no
#      pisa la canción; la canción va por el bus Musica, en bucle desde 13,62 s, y la música de antes se quita.

const ARCHIVO := "user://prueba_climax.save"
var P
var G
var K                                  # combate_climax.gd
var c = null
var z = null
var fallos: Array = []
var hechos: Array = []
var empezados: Array = []               # [jefe, fotograma] de la señal climax_empezado
var sonidos: Array = []


func _initialize() -> void:
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	K = load("res://combate_climax.gd")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_probar.call_deferred()


func _ok(cond: bool, texto: String) -> void:
	if not cond:
		fallos.append(texto)
		print("FALLO: ", texto)


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _esperar_ms(ms: int) -> void:
	var fin := Time.get_ticks_msec() + ms
	while Time.get_ticks_msec() < fin:
		await process_frame


func _limpiar() -> void:
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "combate_fijo", "tipo_combate", "zona", "desde_mapa"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)


# Un combate congelado del grupo «grupo» (13: Bramavidrio; 12: el Coloso). «tipo»: «jefe» o «normal» (con HUIR).
func _combate(grupo: int, tipo := "jefe") -> void:
	_limpiar()
	G.datos()
	Engine.set_meta("grupo_activo", ["Kael", "Lya", "Garon"])
	for n in ["Kael", "Lya", "Garon"]:
		G.datos()[n]["nivel"] = 10
		G.datos()[n]["pv"] = -1
		G.datos()[n]["pm"] = -1
	Engine.set_meta("zona", "desierto")
	Engine.set_meta("tipo_combate", tipo)
	Engine.set_meta("grupo_combate", grupo)
	seed(7)
	c = load("res://combate.tscn").instantiate()
	empezados.clear()
	sonidos.clear()
	c.climax_empezado.connect(func(j): empezados.append([j, Engine.get_process_frames()]))
	c.sonido_pedido.connect(func(n): sonidos.append(n))
	root.add_child(c)
	z = c.enemigos[0]
	for f in c.heroes + c.enemigos:
		f["vel"] = 0.0
		f["atb"] = 0.0
	c.cola.clear()
	await _esperar(3)
	while c.estado != "esperando":                       # el título del jefe deja «accion» unos instantes
		await _esperar(1)


func _cerrar() -> void:
	if c != null:
		c.queue_free()
		c = null
	await _esperar(5)


# Quita a «f» hasta dejarle «parte» de su vida máxima, como un golpe (el mismo _quitar_pv del combate).
func _golpe_hasta(f: Dictionary, parte: float) -> void:
	var meta := int(floor(f["hp_max"] * parte))
	c._quitar_pv(f, maxi(1, int(f["hp"]) - meta))


func _vida(f: Dictionary, parte: float) -> void:
	f["hp"] = int(ceil(f["hp_max"] * parte))


func _reproductores() -> Array:
	return root.find_children("*", "AudioStreamPlayer", true, false).filter(func(p): return p.name == "MusicaClimax")


func _probar() -> void:
	await _esperar(10)
	await _uno_a_cinco()
	await _seis()
	await _victoria_derrota()
	await _huida()
	await _varios()
	await _no_autorizados()
	await _escena_y_datos()
	_limpiar()
	Engine.remove_meta("archivo_partida_prueba")
	print("OK: ", "; ".join(hechos))
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)


func _uno_a_cinco() -> void:
	# 1. del 30 % al 21 %
	await _combate(13)
	_ok(not K.de(z).is_empty(), "Bramavidrio no tiene clímax configurado")
	var antes = c.musica
	_ok(antes != null and antes.playing, "la música del jefe no suena al empezar")
	_vida(z, 0.30)
	_golpe_hasta(z, 0.21)
	await _esperar(20)
	_ok(empezados.is_empty() and not c.climax_hecho and c.musica == antes, "1: al 21 % se activa")
	# 2. del 21 % al 20 %, con el combate a mitad de una acción: espera a que acabe
	c.estado = "accion"
	_golpe_hasta(z, 0.20)
	_ok(c.climax_hecho and not c.climax_pendiente.is_empty(), "2: al 20 %% no queda pendiente (%d/%d)" % [z["hp"], z["hp_max"]])
	await _esperar(10)
	_ok(empezados.is_empty(), "2: empieza a mitad de la acción del golpe")
	c.estado = "esperando"
	await _esperar(2)
	_ok(empezados.size() == 1, "2: al acabar el golpe no empieza (%d)" % empezados.size())
	_ok(c.musica == c.musica_climax and c.musica_climax != null, "2: la canción no pasa a ser la música del combate")
	var avisos: Array = c.capa.find_children("*", "Label", false, false).filter(func(l): return l.text == "¡Momento decisivo!")
	_ok(avisos.size() == 1 and avisos[0].position.x + avisos[0].size.x <= 1280 * 0.6 + 0.5,
		"2: el aviso no está o pisa el menú de órdenes (el 40 % derecho)")
	_ok(sonidos.count(K.GOLPE) == 1, "2: el golpe de energía suena %d veces" % sonidos.count(K.GOLPE))
	var m: AudioStreamPlayer = c.musica_climax
	_ok(m.bus == &"Musica", "13: la canción no va por el bus Musica (%s)" % m.bus)
	_ok(m.stream.loop and is_equal_approx(m.stream.loop_offset, 13.62), "13: sin bucle o sin loop_offset 13,62")
	await _esperar_ms(int(K.FUNDIDO * 1000) + 600)
	await _esperar(int(K.FUNDIDO * 30) + 5)
	_ok(m.playing, "2: la canción no suena tras el fundido")
	_ok(not is_instance_valid(antes) or antes.is_queued_for_deletion(), "13: la música de antes se queda")
	await _esperar_ms(400)
	var pos1 := m.get_playback_position()
	_ok(pos1 > 0.05 and pos1 < 5.0, "2: no empieza desde el principio (%.2f s)" % pos1)
	# 5. más golpes: nada se reinicia
	_golpe_hasta(z, 0.15)
	_golpe_hasta(z, 0.10)
	await _esperar(10)
	await _esperar_ms(300)
	_ok(empezados.size() == 1 and c.musica_climax == m and _reproductores().size() == 1, "5: más golpes lo reinician")
	_ok(m.get_playback_position() > pos1, "5: la canción vuelve atrás (%.2f → %.2f)" % [pos1, m.get_playback_position()])
	await _esperar_ms(int(maxf(0.0, 1.4 - m.get_playback_position()) * 1000))
	await _esperar(2)
	_ok(c.climax_estallido < 0.0, "2: el destello no cae con el estallido de la canción (%.2f s)" % m.get_playback_position())
	# 13. la fase 2 no pisa la canción
	c._musica_fase2()
	await _esperar(40)
	_ok(c.musica == m and m.stream.resource_path.ends_with("volvera_a_amanecer_climax.ogg"), "13: la fase 2 cambia la canción")
	await _cerrar()
	hechos.append("1, 2, 5 y fase 2")
	# 3. del 50 % al 10 % de un golpe
	await _combate(13)
	_vida(z, 0.50)
	_golpe_hasta(z, 0.10)
	await _esperar(5)
	_ok(empezados.size() == 1, "3: del 50 %% al 10 %% no se activa (%d)" % empezados.size())
	await _cerrar()
	# 4. muere de un golpe que cruza el umbral
	await _combate(13)
	_vida(z, 0.30)
	c._quitar_pv(z, z["hp"] + 50)
	await _esperar(20)
	_ok(empezados.is_empty() and c.musica_climax == null and _reproductores().is_empty(), "4: muerto de un golpe, se activa")
	await _cerrar()
	hechos.append("3 y 4")


func _seis() -> void:
	await _combate(13)
	_vida(z, 0.40)
	_golpe_hasta(z, 0.18)
	await _esperar(5)
	var m = c.musica_climax
	z["hp"] = int(z["hp_max"] * 0.6)                   # se cura por encima
	c._actualizar()
	await _esperar(20)
	_ok(c.musica == m and empezados.size() == 1, "6: al curarse cambia la música")
	_golpe_hasta(z, 0.12)                               # vuelve a bajar: nada nuevo
	await _esperar(20)
	_ok(empezados.size() == 1 and _reproductores().size() == 1, "6: al volver a bajar se reactiva")
	await _cerrar()
	hechos.append("6")


func _victoria_derrota() -> void:
	for gana in [true, false]:
		await _combate(13)
		_vida(z, 0.40)
		_golpe_hasta(z, 0.15)
		await _esperar(5)
		await _esperar_ms(int(K.FUNDIDO * 1000) + 300)
		await _esperar(int(K.FUNDIDO * 30) + 5)
		var m: AudioStreamPlayer = c.musica_climax
		_ok(m != null and m.playing, "%s: la canción no suena antes del final" % ("7" if gana else "8"))
		var n0: int = int(root.get_node("Sonido").contador.get("victoria" if gana else "derrota", 0))
		if gana:
			c._quitar_pv(z, z["hp"])
		else:
			for h in c.heroes:
				h["hp"] = 0
		_ok(c._comprobar_fin(), "%s: el combate no acaba" % ("7" if gana else "8"))
		_ok(int(root.get_node("Sonido").contador.get("victoria" if gana else "derrota", 0)) == n0 + 1,
			"%s: no suena la %s de siempre" % ["7" if gana else "8", "victoria" if gana else "derrota"])
		await _esperar(70)                              # el fundido de siempre: 1,8 s de juego
		_ok(m.volume_db <= -30.0, "%s: la canción no se apaga (%.1f dB)" % ["7" if gana else "8", m.volume_db])
		await _cerrar()
	hechos.append("7 y 8")


func _huida() -> void:
	await _combate(13, "normal")                         # un combate normal: HUIR se puede
	_ok(not c._orden_huir()["apagado"], "9: HUIR apagado en un combate normal")
	_vida(z, 0.40)
	_golpe_hasta(z, 0.15)
	await _esperar(5)
	await _esperar_ms(int(K.FUNDIDO * 1000) + 300)
	await _esperar(int(K.FUNDIDO * 30) + 5)
	var m: AudioStreamPlayer = c.musica_climax
	c.actor = c.heroes[0]
	c._escapar()
	await _esperar(70)
	_ok(c.estado == "fin" and m.volume_db <= -30.0, "9: al huir la canción no se cierra (%.1f dB)" % m.volume_db)
	_ok(_reproductores().size() == 1, "9: reproductores de más al huir")
	await _cerrar()
	_ok(_reproductores().is_empty(), "9/12: tras huir y cerrar queda la canción")
	# y si se huye durante el fundido, la canción no llega a sonar
	await _combate(13, "normal")
	_vida(z, 0.40)
	_golpe_hasta(z, 0.15)
	await _esperar(2)
	c.actor = c.heroes[0]
	c._escapar()
	await _esperar_ms(int(K.FUNDIDO * 1000) + 300)
	await _esperar(int(K.FUNDIDO * 30) + 10)
	_ok(c.musica_climax == null or not c.musica_climax.playing, "9: huir durante el fundido y la canción empieza")
	await _cerrar()
	hechos.append("9")


func _varios() -> void:
	await _combate(13)
	var otro: Dictionary = {"nombre": "Bramavidrio B", "clave": "bramavidrio", "hero": false, "hp": 1000, "hp_max": 1000}
	_vida(z, 0.40)
	_golpe_hasta(z, 0.15)                               # los dos cruzan antes de empezar
	_golpe_hasta(otro, 0.15)
	await _esperar(5)
	_golpe_hasta(otro, 0.05)
	await _esperar(10)
	_ok(empezados.size() == 1 and _reproductores().size() == 1, "10: con dos jefes, %d clímax y %d canciones" % [empezados.size(), _reproductores().size()])
	await _cerrar()
	hechos.append("10")


func _no_autorizados() -> void:
	await _combate(12)                                  # el Coloso de la Falla: sin clímax
	_ok(K.de(z).is_empty(), "11: el Coloso tiene clímax")
	var antes = c.musica
	_vida(z, 0.40)
	_golpe_hasta(z, 0.10)
	await _esperar(30)
	_ok(empezados.is_empty() and c.musica == antes and antes.playing and _reproductores().is_empty(), "11: con el Coloso cambia la música")
	await _cerrar()
	var elite := {"clave": "bramavidrio", "hero": false, "elite": true}
	_ok(K.de(elite).is_empty(), "11: un élite tiene clímax")
	_ok(K.de({"clave": "slime", "hero": false}).is_empty(), "11: un enemigo normal tiene clímax")
	hechos.append("11")


func _escena_y_datos() -> void:
	_ok(not K.cruza(10, 5, 0), "13: con hp_max 0 se activa")
	_ok(not K.cruza(0, 0, 100), "13: sin vida puesta se activa")
	_ok(not K.cruza(15, 10, 100), "13: empezando por debajo se activa")
	_ok(K.cruza(21, 20, 100) and not K.cruza(30, 21, 100) and not K.cruza(30, 0, 100), "13: el umbral no es el 20 %")
	# 12. cambio de escena con la canción sonando
	await _combate(13)
	_vida(z, 0.40)
	_golpe_hasta(z, 0.15)
	await _esperar(5)
	await _esperar_ms(int(K.FUNDIDO * 1000) + 300)
	await _esperar(int(K.FUNDIDO * 30) + 5)
	_ok(_reproductores().size() == 1 and c.musica_climax.playing, "12: no suena antes de cambiar de escena")
	var vivos := func() -> int:
		return root.find_children("*", "AudioStreamPlayer", true, false).filter(func(p): return p.playing and p.bus == &"Musica" \
			and p.stream != null and p.stream.resource_path.contains("jefes/")).size()
	await _cerrar()
	_ok(_reproductores().is_empty() and vivos.call() == 0, "12: tras el combate queda la canción sonando")
	hechos.append("12 y 13")
