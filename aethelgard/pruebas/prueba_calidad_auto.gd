extends SceneTree
# Calidad adaptable (encargo del 09/11: «30 FPS estables en calidad baja y media»; prototipos/calidad_auto.gd,
# prototipos/regulador_calidad.gd y las filas de Ajustes de menus.gd). Sin ventana, con datos aislados
# (ejecutar_pruebas.ps1): escribe user://prueba_calidad.cfg y user://ajustes.cfg y deja este como estaba.
#   1. Detección con datos simulados: el Redmi (Mali-G57) y un móvil modesto → bajo a 30; un móvil intermedio fuerte →
#      medio a 30; un QHD con poca memoria → bajo; PC con GPU dedicada → alto (60 solo como candidato a medir), con
#      integrada → medio, por software → bajo. Nunca alto en un móvil; nunca 60 con bajo o medio.
#   2. Escalones: el alto no tiene ninguno (no se rebaja); el bajo se salta las sombras (no tiene); el orden es
#      resolución, sombras, hierba y partículas, distancias; la resolución no baja de 0,6.
#   3. Persistencia y compatibilidad: un ajustes.cfg antiguo sin [calidad] da el comportamiento de antes (alto en PC)
#      sin escribir nada; guardar [calidad] no toca las otras secciones; valores raros se ignoran.
#   4. Lo manual manda: con el perfil fijado, el del jugador (sin recortes) aunque el sistema eligiera otro; con
#      CAL (Engine), el perfil tal cual; los botones de Ajustes (Automática / Baja / Media / Alta y 30 / 60) guardan
#      lo que dicen y calidad_proto lo usa.
#   5. Regulador con tiempos simulados: el bajo del Redmi (p95 34 ms) se calibra y no cambia nada; el medio del
#      Redmi (p95 54,5 ms) pide el bajo; tirones sueltos no bajan nada; ventanas malas sueltas no bajan; carga
#      alterna durante una hora: pocos cambios y luego quieto (histéresis, sin oscilar); nunca sube a 60 solo (un
#      alto a 60 que no llega se queda en 30 para siempre); a mano solo avisa una vez; si no llega ni en bajo, se
#      registra una vez.
#   6. En la región de verdad (Pastos Verdes 3D) con el regulador forzado: los escalones se aplican en vivo
#      (resolución, sombras, hierba y su distancia) y se guardan; al recargar, la escena se construye con ellos.

const PRUEBA_CFG := "user://prueba_calidad.cfg"
const AJUSTES := "user://ajustes.cfg"
const REGION := "res://zonas3d/pastos_verdes_3d.tscn"

var fallos := 0
var Auto
var Cal
var Reg
var _copia_ajustes := ""
var _habia_ajustes := false
var _habia_registro := false


func _initialize() -> void:
	_probar.call_deferred()


func _fallo(t: String) -> void:
	fallos += 1
	print("FALLO: ", t)


func _ok(cond: bool, t: String) -> void:
	if not cond:
		_fallo(t)


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _probar() -> void:
	Auto = load("res://prototipos/calidad_auto.gd")
	Cal = load("res://prototipos/calidad_proto.gd")
	Reg = load("res://prototipos/regulador_calidad.gd")
	_habia_ajustes = FileAccess.file_exists(AJUSTES)
	if _habia_ajustes:
		_copia_ajustes = FileAccess.get_file_as_string(AJUSTES)
	_habia_registro = FileAccess.file_exists(Auto.REGISTRO)
	_deteccion()
	_escalones()
	_persistencia()
	await _manual()
	_regulador()
	await _en_la_region()
	_dejar_como_estaba()
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


func _dejar_como_estaba() -> void:
	for m in ["calidad_proto", "calidad_extra", "calidad_regulador_forzado"]:
		if Engine.has_meta(m):
			Engine.remove_meta(m)
	if _habia_ajustes:
		var f := FileAccess.open(AJUSTES, FileAccess.WRITE)
		f.store_string(_copia_ajustes)
		f.close()
	elif FileAccess.file_exists(AJUSTES):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(AJUSTES))
	if FileAccess.file_exists(PRUEBA_CFG):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PRUEBA_CFG))
	if not _habia_registro and FileAccess.file_exists(Auto.REGISTRO):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Auto.REGISTRO))


# ================================================================= 1. detección

func _deteccion() -> void:
	var casos := [
		# [nombre, datos, perfil esperado, fps esperado]
		["Redmi A7 Pro", {"movil": true, "gpu": "Mali-G57 MC2", "fabricante": "ARM", "nucleos": 8, "memoria_mb": 3800,
			"pantalla": Vector2i(720, 1600)}, "bajo", 30],
		["móvil modesto", {"movil": true, "gpu": "Adreno (TM) 506", "fabricante": "Qualcomm", "nucleos": 8,
			"memoria_mb": 3000, "pantalla": Vector2i(720, 1520)}, "bajo", 30],
		["móvil desconocido", {"movil": true, "gpu": "", "fabricante": "", "nucleos": -1, "memoria_mb": -1,
			"pantalla": Vector2i.ZERO}, "bajo", 30],
		["móvil intermedio fuerte", {"movil": true, "gpu": "Adreno (TM) 660", "fabricante": "Qualcomm", "nucleos": 8,
			"memoria_mb": 7600, "pantalla": Vector2i(1080, 2400)}, "medio", 30],
		["móvil fuerte con poca memoria", {"movil": true, "gpu": "Adreno (TM) 730", "fabricante": "Qualcomm",
			"nucleos": 8, "memoria_mb": 4000, "pantalla": Vector2i(1080, 2400)}, "bajo", 30],
		["móvil QHD con 6 GB", {"movil": true, "gpu": "Mali-G710 MC10", "fabricante": "ARM", "nucleos": 8,
			"memoria_mb": 6000, "pantalla": Vector2i(1440, 3200)}, "bajo", 30],
		["puntero QHD", {"movil": true, "gpu": "Adreno (TM) 750", "fabricante": "Qualcomm", "nucleos": 8,
			"memoria_mb": 11500, "pantalla": Vector2i(1440, 3120)}, "medio", 30],
		["PC con GPU dedicada", {"movil": false, "gpu": "NVIDIA GeForce RTX 3060 Laptop GPU", "fabricante": "NVIDIA",
			"nucleos": 16, "memoria_mb": 16000, "pantalla": Vector2i(1920, 1080)}, "alto", 60],
		["PC con integrada", {"movil": false, "gpu": "Intel(R) UHD Graphics 620", "fabricante": "Intel", "nucleos": 8,
			"memoria_mb": 8000, "pantalla": Vector2i(1920, 1080)}, "medio", 30],
		["PC con Intel Arc", {"movil": false, "gpu": "Intel(R) Arc(TM) A770 Graphics", "fabricante": "Intel",
			"nucleos": 12, "memoria_mb": 16000, "pantalla": Vector2i(2560, 1440)}, "alto", 60],
		["PC por software", {"movil": false, "gpu": "llvmpipe (LLVM 15.0.7, 256 bits)", "fabricante": "Mesa",
			"nucleos": 4, "memoria_mb": 8000, "pantalla": Vector2i(1280, 720)}, "bajo", 30],
		["PC de 2 núcleos", {"movil": false, "gpu": "AMD Radeon RX 580", "fabricante": "AMD", "nucleos": 2,
			"memoria_mb": 8000, "pantalla": Vector2i(1920, 1080)}, "medio", 30],
	]
	for c in casos:
		var r: Dictionary = Auto.detectar(c[1])
		_ok(r["perfil"] == c[2] and r["fps"] == c[3], "1: %s → %s a %d FPS (se esperaba %s a %d; %s)" % [c[0],
			r["perfil"], r["fps"], c[2], c[3], r["motivo"]])
		if c[1]["movil"]:
			_ok(r["perfil"] != "alto", "1: %s: alto en un móvil" % c[0])
		if r["perfil"] != "alto":
			_ok(r["fps"] == 30, "1: %s: 60 FPS con %s" % [c[0], r["perfil"]])
	# los datos reales se leen sin errores (en este PC sin ventana; solo se mira la forma)
	var reales: Dictionary = Auto.datos_del_aparato()
	for k in ["movil", "gpu", "fabricante", "nucleos", "memoria_mb", "pantalla"]:
		_ok(reales.has(k), "1: datos_del_aparato sin «%s»" % k)
	print("1. detección: %d casos" % casos.size())


# ================================================================= 2. escalones

func _escalones() -> void:
	_ok(Auto.escalones_utiles("alto").is_empty(), "2: el alto tiene escalones (no se rebaja nunca)")
	_ok(Auto.recortes("alto", 5).is_empty(), "2: el alto tiene recortes")
	var bajo: Array = Auto.escalones_utiles("bajo")
	_ok(not 2 in bajo, "2: el bajo tiene el escalón de sombras (no tiene sombras): %s" % [bajo])
	_ok(bajo == [0, 1, 3, 4], "2: escalones del bajo %s (se esperaba [0, 1, 3, 4])" % [bajo])
	_ok(Cal.PERFILES["medio"]["escala_3d"] == 0.8 and Cal.PERFILES["medio"]["sombra_tramos"] == 1 and Cal.PERFILES["medio"]["hierba"] == 3000,
		"2: el medio no es el candidato B (decisión del coordinador, 09/11)")
	# (las cifras salen de PERFILES: si el coordinador fija otro medio, la prueba sigue valiendo)
	var m: Dictionary = Cal.PERFILES["medio"]
	var medio: Array = Auto.escalones_utiles("medio")
	_ok(medio.slice(0, 2) == [0, 1] and medio.has(3) and medio.has(4) and (medio.has(2) == m["sombras"]),
		"2: escalones del medio %s" % [medio])
	var r1: Dictionary = Auto.recortes("medio", 1)
	var paso: float = Auto.ESCALONES[0]["escala_3d"]
	var esc1 := maxf(Auto.ESCALA_MIN, m["escala_3d"] + paso)
	_ok(r1.keys() == ["escala_3d"] and is_equal_approx(r1["escala_3d"], esc1), "2: medio nivel 1: %s" % r1)
	var r2: Dictionary = Auto.recortes("medio", 2)
	_ok(is_equal_approx(r2["escala_3d"], maxf(Auto.ESCALA_MIN, esc1 + paso)) and not r2.has("sombra_tramos"),
		"2: medio nivel 2: %s" % r2)
	var con_sombras: bool = m["sombras"]
	var n_hierba := 4 if con_sombras else 3
	if con_sombras:
		var r3: Dictionary = Auto.recortes("medio", 3)
		_ok(r3.get("sombra_tramos", m["sombra_tramos"]) == 1 and is_equal_approx(r3["dist_sombras"], m["dist_sombras"] * 0.7)
			and not r3.has("hierba"), "2: medio nivel 3 (sombras): %s" % r3)
	var r4: Dictionary = Auto.recortes("medio", n_hierba)
	_ok(r4.get("hierba", 0) == int(round(m["hierba"] * 0.7)) and r4.get("flores", 0) == int(round(m["flores"] * 0.7))
		and r4.get("espuma", 0) == int(round(m["espuma"] * 0.7)) and not r4.has("dist_hierba"),
		"2: medio, escalón de hierba y partículas: %s" % r4)
	var r5: Dictionary = Auto.recortes("medio", n_hierba + 1)
	_ok(is_equal_approx(r5.get("dist_hierba", 0.0), m["dist_hierba"] * 0.75), "2: medio, escalón de distancias: %s" % r5)
	if con_sombras:
		_ok(is_equal_approx(r5["dist_sombras"], snappedf(m["dist_sombras"] * 0.7, 0.01) * 0.8), "2: medio, sombra final: %s" % r5)
	_ok(Auto.recortes("medio", 9) == r5, "2: más niveles que escalones cambia algo más")
	var b9: Dictionary = Auto.recortes("bajo", 9)
	_ok(b9["escala_3d"] >= Auto.ESCALA_MIN - 0.001, "2: la resolución del bajo baja de 0,6: %s" % b9)
	_ok(is_equal_approx(Auto.recortes("medio", 1)["escala_3d"], 0.75) and is_equal_approx(Auto.recortes("medio", 2)["escala_3d"], 0.7),
		"2: el medio no baja la resolución 0,8 → 0,75 → 0,7 (lo pedido el 09/11)")
	_ok(not Auto.recortes("bajo", 4).has("sombras"), "2: los recortes encienden o apagan sombras")
	print("2. escalones: medio %s, bajo %s" % [medio, bajo])


# ================================================================= 3. persistencia y compatibilidad

func _persistencia() -> void:
	var viejo := ConfigFile.new()                      # un ajustes.cfg de antes: volumen y regiones, sin [calidad]
	viejo.set_value("audio", "Musica", 70)
	viejo.set_value("regiones", "garganta3d", true)
	viejo.save(PRUEBA_CFG)
	var antes := FileAccess.get_file_as_string(PRUEBA_CFG)
	var e: Dictionary = Auto.estado(PRUEBA_CFG)
	_ok(not e["existe"] and e["auto"] and Auto.perfil_de(e) == "", "3: un archivo antiguo da [calidad]: %s" % e)
	_ok(Auto.perfil_en_uso("alto", PRUEBA_CFG) == "alto", "3: sin [calidad] y sin ventana no es el de antes (alto)")
	_ok(Auto.perfil_en_uso("bajo", PRUEBA_CFG) == "bajo", "3: sin [calidad] y sin ventana no es el de antes (bajo)")
	_ok(FileAccess.get_file_as_string(PRUEBA_CFG) == antes, "3: leer la calidad sin ventana escribe el archivo")
	_ok(Auto.fps_de("alto", e, 60) == 60 and Auto.fps_de("bajo", e, 30) == 30, "3: FPS de antes cambiados")
	_ok(Auto.guardar({"auto": true, "perfil": "medio", "perfil_auto": "medio", "fps_auto": 30, "calibrado": true},
		PRUEBA_CFG) == OK, "3: no se guarda [calidad]")
	var c := ConfigFile.new()
	c.load(PRUEBA_CFG)
	_ok(c.get_value("audio", "Musica", 0) == 70 and c.get_value("regiones", "garganta3d", false) == true,
		"3: guardar [calidad] tocó las otras secciones")
	e = Auto.estado(PRUEBA_CFG)
	_ok(e["existe"] and Auto.perfil_de(e) == "medio" and e["calibrado"], "3: no se lee lo guardado: %s" % e)
	_ok(Auto.perfil_en_uso("alto", PRUEBA_CFG) == "medio", "3: lo guardado no manda sobre el de antes")
	# primer inicio en el juego de verdad (datos del Redmi simulados): detecta, guarda [calidad] y deja lo demás
	viejo.save(PRUEBA_CFG)
	var redmi := {"movil": true, "gpu": "Mali-G57 MC2", "fabricante": "ARM", "nucleos": 8, "memoria_mb": 3800,
		"pantalla": Vector2i(720, 1600)}
	_ok(Auto.perfil_en_uso("alto", PRUEBA_CFG, redmi) == "bajo", "3: el primer inicio en el Redmi no da bajo")
	var tras: Dictionary = Auto.estado(PRUEBA_CFG)
	_ok(tras["existe"] and tras["auto"] and tras["perfil_auto"] == "bajo" and tras["perfil"] == "bajo"
		and tras["fps_auto"] == 30 and not tras["calibrado"] and tras["fps"] == 0, "3: el primer inicio guarda %s" % tras)
	var c0 := ConfigFile.new()
	c0.load(PRUEBA_CFG)
	_ok(c0.get_value("audio", "Musica", 0) == 70, "3: el primer inicio tocó el volumen")
	_ok(FileAccess.file_exists(Auto.REGISTRO) and FileAccess.get_file_as_string(Auto.REGISTRO).contains("detección: bajo"),
		"3: la detección no queda en user://calidad.log")
	# con el perfil ya fijado a mano, el primer inicio no lo cambia (solo apunta el del sistema)
	viejo.set_value("calidad", "auto", false)
	viejo.set_value("calidad", "perfil", "medio")
	viejo.save(PRUEBA_CFG)
	_ok(Auto.perfil_en_uso("alto", PRUEBA_CFG, redmi) == "medio", "3: la detección pisa el perfil fijado a mano")
	viejo.erase_section("calidad")
	Auto.guardar({"auto": true, "perfil": "medio", "perfil_auto": "medio", "fps_auto": 30, "calibrado": true}, PRUEBA_CFG)
	# valores raros: se ignoran (perfil desconocido, FPS que no son 30 ni 60, texto donde va un número)
	c.set_value("calidad", "perfil_auto", "ultra")
	c.set_value("calidad", "fps", 45)
	c.set_value("calidad", "nivel", "mucho")
	c.set_value("calidad", "auto", "quizá")
	c.set_value("calidad", "calibrado", 1)
	c.save(PRUEBA_CFG)
	e = Auto.estado(PRUEBA_CFG)
	_ok(e["perfil_auto"] == "" and e["fps"] == 0 and e["nivel"] == 0 and e["auto"] == true and e["calibrado"] == false,
		"3: valores raros no se ignoran: %s" % e)
	_ok(Auto.fps_de("medio", e, 30) == 30, "3: con un FPS raro, medio no va a 30")
	# borrar una clave con null
	Auto.guardar({"fps": 60}, PRUEBA_CFG)
	_ok(Auto.estado(PRUEBA_CFG)["fps"] == 60, "3: el FPS elegido no se guarda")
	Auto.guardar({"fps": null}, PRUEBA_CFG)
	_ok(Auto.estado(PRUEBA_CFG)["fps"] == 0, "3: null no borra la clave")
	# el escalón guardado solo vale para su perfil y en automática
	var e2 := {"auto": true, "nivel": 3, "nivel_de": "medio"}
	_ok(Auto.nivel_de("medio", e2) == 3 and Auto.nivel_de("bajo", e2) == 0, "3: escalón de otro perfil aplicado")
	e2["auto"] = false
	_ok(Auto.nivel_de("medio", e2) == 0, "3: escalón aplicado con el perfil fijado a mano")
	print("3. persistencia y compatibilidad")


# ================================================================= 4. lo manual manda

func _escribir_ajustes(claves: Dictionary) -> void:
	var c := ConfigFile.new()
	c.set_value("audio", "Musica", 80)
	for k in claves:
		c.set_value("calidad", k, claves[k])
	c.save(AJUSTES)


func _manual() -> void:
	# el sistema eligió medio (con dos escalones), el jugador fijó bajo
	_escribir_ajustes({"auto": false, "perfil": "bajo", "perfil_auto": "medio", "fps_auto": 30, "calibrado": true,
		"nivel": 2, "nivel_de": "medio"})
	_ok(Cal.actual() == "bajo", "4: con el perfil fijado no manda el del jugador (%s)" % Cal.actual())
	_ok(Cal.fijado_a_mano(), "4: fijado_a_mano no lo ve")
	var d: Dictionary = Cal.datos()
	_ok(is_equal_approx(d["escala_3d"], Cal.PERFILES["bajo"]["escala_3d"]) and d["fps"] == 30,
		"4: el perfil fijado lleva recortes o FPS raros: %s" % d)
	# en automática: el del sistema, con sus escalones
	_escribir_ajustes({"auto": true, "perfil": "medio", "perfil_auto": "medio", "fps_auto": 30, "calibrado": true,
		"nivel": 2, "nivel_de": "medio"})
	d = Cal.datos()
	_ok(Cal.actual() == "medio" and not Cal.fijado_a_mano(), "4: en automática no es el del sistema")
	_ok(is_equal_approx(d["escala_3d"], Auto.recortes("medio", 2)["escala_3d"]) and d["fps"] == 30,
		"4: en automática, sin los escalones: %s" % d)
	# CAL o un banco (Engine) mandan sobre todo y van sin recortes
	Engine.set_meta("calidad_proto", "alto")
	d = Cal.datos()
	_ok(Cal.actual() == "alto" and d["fps"] == 60 and is_equal_approx(d["escala_3d"], 1.0) and Cal.fijado_a_mano(),
		"4: con CAL no es el alto tal cual: %s" % d)
	Engine.remove_meta("calidad_proto")
	# el jugador pide 60 con el medio: lo manual manda (y sin pedirlo, 30)
	_escribir_ajustes({"auto": false, "perfil": "medio", "fps": 60})
	_ok(Cal.datos()["fps"] == 60, "4: el límite de 60 elegido no se usa")
	_escribir_ajustes({"auto": false, "perfil": "alto", "fps_auto": 30})
	_ok(Cal.datos()["fps"] == 30, "4: alto a mano en un aparato medido a 30 sube a 60 solo")
	await _botones_ajustes()
	print("4. lo manual manda")


func _boton(menu: Node, clave: String) -> Button:
	for b in menu.find_children("*", "Button", true, false):
		if b.has_meta("clave") and b.get_meta("clave") == clave and b.is_inside_tree():
			return b
	return null


func _pulsar(menu: Node, clave: String) -> void:
	var b := _boton(menu, clave)
	if b == null:
		_fallo("4: Ajustes sin el botón «%s»" % clave)
		return
	b.pressed.emit()
	await _esperar(2)


func _botones_ajustes() -> void:
	if not load("res://modo3d.gd").activo():
		_fallo("4: la exploración 3D no está activa (falta «-- 3d»): no salen las filas de calidad")
		return
	_escribir_ajustes({"auto": true, "perfil": "medio", "perfil_auto": "medio", "fps_auto": 30, "calibrado": true})
	var menu = load("res://menus.gd").new()
	menu.pestana = "Ajustes"
	root.add_child(menu)
	await _esperar(3)
	for k in ["calidad:auto", "calidad:bajo", "calidad:medio", "calidad:alto", "fps:30", "fps:60"]:
		_ok(_boton(menu, k) != null, "4: Ajustes sin el botón «%s»" % k)
	var b := _boton(menu, "calidad:auto")
	_ok(b != null and b.text.begins_with("●"), "4: con [calidad] automática, Automática no sale elegida")
	await _pulsar(menu, "calidad:alto")
	var e: Dictionary = Auto.estado()
	_ok(not e["auto"] and e["perfil"] == "alto" and e["perfil_auto"] == "medio", "4: Alta no se guarda así: %s" % e)
	_ok(Cal.actual() == "alto", "4: tras pulsar Alta, el perfil en uso es %s" % Cal.actual())
	b = _boton(menu, "calidad:alto")
	_ok(b != null and b.text.begins_with("●"), "4: Alta no sale elegida tras pulsarla")
	await _pulsar(menu, "fps:60")
	_ok(Auto.estado()["fps"] == 60 and Cal.datos()["fps"] == 60, "4: 60 FPS no se guarda o no se usa")
	await _pulsar(menu, "calidad:auto")
	e = Auto.estado()
	_ok(e["auto"] and Cal.actual() == "medio", "4: Automática no vuelve al perfil del sistema: %s" % e)
	_ok(Cal.datos()["fps"] == 60, "4: al volver a Automática se pierde el límite elegido")
	await _pulsar(menu, "fps:30")
	_ok(Cal.datos()["fps"] == 30, "4: 30 FPS no se usa")
	var c := ConfigFile.new()
	c.load(AJUSTES)
	_ok(c.get_value("audio", "Musica", 0) == 80, "4: Ajustes de calidad tocó el volumen")
	menu.queue_free()
	await _esperar(2)


# ================================================================= 5. regulador con tiempos simulados

# Da «segundos» de fotogramas: f(t) devuelve los ms del fotograma que empieza en t. Devuelve las acciones.
func _alimentar(r, f: Callable, segundos: float, t0 := 0.0) -> Array:
	var acciones: Array = []
	var t := t0
	while t < t0 + segundos:
		var ms: float = f.call(t)
		var a: Dictionary = r.muestra(ms)
		if not a.is_empty():
			a["t"] = t
			acciones.append(a)
		t += maxf(ms, 1.0) / 1000.0
	return acciones


func _tipos(acciones: Array) -> Array:
	return acciones.map(func(a): return a["accion"])


# Los fotogramas repiten la lista, en orden.
func _ciclo(lista: Array) -> Callable:
	var k := [0]
	return func(_t: float) -> float:
		k[0] += 1
		return lista[k[0] % lista.size()]


# Un fotograma de cada «periodo» tarda «largo»; los demás, «normal».
func _patron(normal: float, largo: float, cada: int) -> Callable:
	var n := [0]
	return func(_t: float) -> float:
		n[0] += 1
		return largo if n[0] % cada == 0 else normal


func _regulador() -> void:
	var c: Array
	# el bajo del Redmi (v293, TOPE): 33,4 ms de mediana y p95 34,0
	var r = Reg.new("bajo", 30, 30, true, true, 0, Auto.escalones_utiles("bajo").size())
	c = _alimentar(r, _patron(33.4, 34.0, 4), 300.0)
	_ok(_tipos(c) == ["calibrado"], "5: el bajo del Redmi no se calibra limpio: %s" % [_tipos(c)])
	_ok(r.nivel == 0 and r.fps == 30, "5: el bajo del Redmi cambió algo")
	# el medio del Redmi: p95 54,5 ms (uno de cada 6 fotogramas pierde dos refrescos)
	r = Reg.new("medio", 30, 30, true, true, 0, Auto.escalones_utiles("medio").size())
	c = _alimentar(r, _patron(36.0, 54.5, 6), 12.0)
	_ok(_tipos(c) == ["perfil"] and c[0]["perfil"] == "bajo", "5: el medio del Redmi no pide el bajo: %s" % [c])
	# y si sigue mal en esta escena, baja escalones de uno en uno, separados (6 s malos + 4 de asentarse)
	c = _alimentar(r, _patron(36.0, 54.5, 6), 120.0, 12.0)
	var niveles: Array = c.filter(func(a): return a["accion"] == "nivel")
	_ok(niveles.size() == r.max_nivel, "5: el medio no recorre sus %d escalones: %s" % [r.max_nivel, _tipos(c)])
	for i in range(1, niveles.size()):
		_ok(niveles[i]["t"] - niveles[i - 1]["t"] >= 9.5, "5: dos escalones seguidos en %.1f s" % (niveles[i]["t"] - niveles[i - 1]["t"]))
	_ok(not "perfil" in _tipos(c), "5: pide el perfil de debajo dos veces")
	# el medio nuevo (cand B, Redmi v336): a 20 m (mediana 33,3, p95 34,3) se calibra y no cambia nada; a 34 m
	# (mediana 36,0, p95 39,0) baja primero la resolución, 0,8 → 0,75 → 0,7, de uno en uno
	var b20 := [33.3, 33.3, 33.3, 33.3, 33.3, 33.3, 33.3, 33.3, 33.3, 34.3]
	var b34 := [33.3, 33.3, 33.3, 33.3, 36.0, 36.0, 36.0, 37.0, 38.0, 39.0]
	r = Reg.new("medio", 30, 30, true, true, 0, Auto.escalones_utiles("medio").size())
	c = _alimentar(r, _ciclo(b20), 300.0)
	_ok(_tipos(c) == ["calibrado"] and r.nivel == 0, "5: el medio nuevo a 20 m cambia algo: %s" % [c])
	c = _alimentar(r, _ciclo(b34), 25.0, 300.0)
	_ok(_tipos(c) == ["nivel", "nivel"] and r.nivel == 2, "5: el medio nuevo a 34 m no baja dos escalones de resolución: %s" % [c])
	_ok(is_equal_approx(Auto.recortes("medio", r.nivel).get("escala_3d", 0.0), 0.7), "5: a 34 m no acaba en 0,7")
	# tirones sueltos (uno de 120 ms cada 2 s) no bajan nada
	r = Reg.new("medio", 30, 30, true, false, 0, 5)
	c = _alimentar(r, _patron(33.3, 120.0, 60), 600.0)
	_ok(c.is_empty(), "5: tirones sueltos bajan la calidad: %s" % [_tipos(c)])
	# ventanas malas sueltas (0,4 s pesados cada 6 s: como mucho dos ventanas malas seguidas) tampoco
	r = Reg.new("medio", 30, 30, true, false, 0, 5)
	c = _alimentar(r, func(t: float) -> float: return 50.0 if fmod(t, 6.0) < 0.4 else 33.3, 600.0)
	_ok(c.is_empty(), "5: ventanas malas sueltas bajan la calidad: %s" % [_tipos(c)])
	# histéresis: una hora con 8 s pesados cada 100 s. Pocos cambios y luego quieto.
	r = Reg.new("medio", 30, 30, true, false, 0, 5)
	c = _alimentar(r, func(t: float) -> float: return 50.0 if fmod(t, 100.0) < 8.0 else 33.3, 3600.0)
	var cambios: Array = c.filter(func(a): return a["accion"] in ["nivel", "fps", "perfil"])
	# cada escalón se vuelve a subir una vez como mucho: max bajadas iniciales + (subida y bajada) por escalón, y una
	# sola petición del perfil de debajo al acabarse los escalones
	_ok(cambios.size() <= 3 * r.max_nivel + 1, "5: oscila: %d cambios en una hora" % cambios.size())
	_ok(cambios.filter(func(a): return a["accion"] == "perfil").size() <= 1, "5: pide el perfil de debajo más de una vez")
	_ok(cambios.is_empty() or cambios[-1]["t"] < 2400.0, "5: sigue cambiando al final de la hora (%.0f s)" % (cambios[-1]["t"] if cambios.size() > 0 else 0.0))
	var subidas := cambios.filter(func(a): return a.get("subir", false))
	print("5. histéresis: %d cambios en una hora (%d subidas), nivel final %d" % [cambios.size(), subidas.size(), r.nivel])
	# una bajada y vuelta a la calma: sube una vez tras 90 s, y si vuelve a fallar se queda abajo
	r = Reg.new("medio", 30, 30, true, false, 0, 5)
	c = _alimentar(r, func(t: float) -> float: return 50.0 if t < 20.0 or (t > 130.0 and t < 150.0) else 33.3, 400.0)
	_ok(_tipos(c).count("nivel") >= 2 and r.nivel >= 1, "5: tras volver a fallar subió otra vez: %s, nivel %d" % [_tipos(c), r.nivel])
	# nunca sube a 60 solo: un bajo o un medio muy holgados no cambian sus 30
	for p in ["bajo", "medio"]:
		r = Reg.new(p, 30, 30, true, true, 0, Auto.escalones_utiles(p).size())
		c = _alimentar(r, func(_t: float) -> float: return 5.0, 900.0)
		_ok(_tipos(c) == ["calibrado"] and c[0]["fps"] == 30 and r.fps == 30, "5: %s holgado: %s" % [p, c])
	# un alto a 60 (candidato del PC) que no llega: 30, se vuelve a medir, y nunca vuelve a 60
	r = Reg.new("alto", 60, 60, true, true, 0, 0)
	c = _alimentar(r, func(t: float) -> float: return 25.0 if t < 60.0 else 5.0, 900.0)
	_ok(_tipos(c) == ["fps", "calibrado"] and c[0]["fps"] == 30 and c[1]["fps"] == 30 and r.fps == 30,
		"5: el alto a 60 que no llega: %s" % [c])
	# un alto a 60 que llega se queda en 60 (lo justifica la medida)
	r = Reg.new("alto", 60, 60, true, true, 0, 0)
	c = _alimentar(r, func(_t: float) -> float: return 12.0, 60.0)
	_ok(_tipos(c) == ["calibrado"] and c[0]["fps"] == 60, "5: el alto a 60 que llega: %s" % [c])
	# el alto no se rebaja: sin escalones, si no llega pide el medio para la próxima carga
	r = Reg.new("alto", 30, 30, true, false, 0, 0)
	c = _alimentar(r, func(_t: float) -> float: return 50.0, 120.0)
	_ok(_tipos(c) == ["perfil"] and c[0]["perfil"] == "medio" and r.nivel == 0, "5: el alto se rebajó: %s" % [c])
	# a mano: nada cambia; un aviso, una vez
	r = Reg.new("medio", 30, 30, false, true, 2, 5)
	c = _alimentar(r, func(_t: float) -> float: return 55.0, 600.0)
	_ok(_tipos(c) == ["aviso"] and r.nivel == 0 and r.max_nivel == 0 and r.fps == 30, "5: a mano: %s" % [c])
	# no llega ni en bajo: todos los escalones y luego se registra una vez
	r = Reg.new("bajo", 30, 30, true, true, 0, Auto.escalones_utiles("bajo").size())
	c = _alimentar(r, func(_t: float) -> float: return 60.0, 600.0)
	_ok(_tipos(c).count("no_llega") == 1 and _tipos(c).count("nivel") == r.max_nivel and r.nivel == r.max_nivel,
		"5: no llega ni en bajo: %s" % [_tipos(c)])
	_ok(not "perfil" in _tipos(c) and not "fps" in _tipos(c), "5: en bajo pide otro perfil o cambia FPS")
	# pausas largas (cargas, segundo plano) no cuentan
	r = Reg.new("medio", 30, 30, true, true, 0, 5)
	c = _alimentar(r, func(t: float) -> float: return 900.0 if int(t) % 3 == 0 else 33.3, 120.0)
	_ok(_tipos(c) == ["calibrado"], "5: las pausas largas cuentan como fotogramas lentos: %s" % [_tipos(c)])
	print("5. regulador")


# ================================================================= 6. en la región de verdad

func _en_la_region() -> void:
	if not load("res://modo3d.gd").activo():
		_fallo("6: la exploración 3D no está activa (falta «-- 3d»)")
		return
	_escribir_ajustes({"auto": true, "perfil": "medio", "perfil_auto": "medio", "fps_auto": 30, "calibrado": true,
		"nivel": 0, "nivel_de": "medio"})
	Engine.set_meta("calidad_regulador_forzado", true)
	Engine.set_meta("pos_3d_ok", false)
	Engine.set_meta("hitos", {"pv_02": true, "pv_03": true})
	change_scene_to_file(REGION)
	var R = root.get_node("Recursos")
	for i in 600:
		await process_frame
		if current_scene != null and current_scene.scene_file_path == REGION and not R.cambiando and i > 10:
			break
	var esc = current_scene
	if esc == null or esc.scene_file_path != REGION:
		_fallo("6: no se entra en Pastos Verdes 3D")
		return
	if esc.regulador == null:
		_fallo("6: la región no tiene regulador con el forzado puesto")
		return
	_ok(esc.regulador.perfil == "medio" and esc.regulador.auto and not esc.regulador.calibrar and esc.perfil_fps == 30,
		"6: regulador de la región: %s, auto %s, calibrar %s, %d FPS" % [esc.regulador.perfil, esc.regulador.auto,
		esc.regulador.calibrar, esc.perfil_fps])
	var m: Dictionary = Cal.PERFILES["medio"]
	var tope: int = Auto.escalones_utiles("medio").size()
	var fin: Dictionary = m.duplicate()
	fin.merge(Auto.recortes("medio", tope), true)
	var vp: Viewport = esc.get_viewport()
	_ok(is_equal_approx(vp.scaling_3d_scale, m["escala_3d"]), "6: el medio no entra a %.2f (%.2f)" % [m["escala_3d"], vp.scaling_3d_scale])
	var hierba := _hierba(esc, m["dist_hierba"])
	_ok(hierba.size() > 0, "6: no se encuentran los trozos de hierba (distancia %.1f m)" % m["dist_hierba"])
	var luz := _sol(esc)
	_ok(luz == null or luz.shadow_enabled == m["sombras"], "6: la sombra del sol no es la del medio")
	var dist0: float = luz.directional_shadow_max_distance if luz != null else 0.0
	for n in range(1, tope + 1):
		esc.regulador.nivel = n
		esc._atender_regulador({"accion": "nivel", "nivel": n, "medida": {"p95": 50.0, "mediana": 40.0, "n": 60}})
	await _esperar(3)
	var e: Dictionary = Auto.estado()
	_ok(e["nivel"] == tope and e["nivel_de"] == "medio", "6: el escalón no se guarda: %s" % e)
	_ok(is_equal_approx(vp.scaling_3d_scale, fin["escala_3d"]), "6: la resolución no baja en vivo (%.2f)" % vp.scaling_3d_scale)
	if luz != null and m["sombras"]:
		_ok(luz.shadow_enabled and luz.directional_shadow_mode == DirectionalLight3D.SHADOW_ORTHOGONAL,
			"6: las sombras no pasan a un tramo en vivo (o se apagan)")
		_ok(absf(luz.directional_shadow_max_distance - dist0 * fin["dist_sombras"] / m["dist_sombras"]) < 0.05,
			"6: distancia de sombra %.2f (de %.1f; se esperaba %.2f)" % [luz.directional_shadow_max_distance, dist0,
			dist0 * fin["dist_sombras"] / m["dist_sombras"]])
	_ok(_hierba(esc, m["dist_hierba"]).is_empty() and _hierba(esc, fin["dist_hierba"]).size() == hierba.size(),
		"6: la hierba no acorta su distancia en vivo")
	var con_menos := 0
	for mmi in _hierba(esc, fin["dist_hierba"]):
		var mm: MultiMesh = mmi.multimesh
		if mm.visible_instance_count >= 0 and mm.visible_instance_count < mm.instance_count:
			con_menos += 1
	_ok(con_menos > 0, "6: la hierba no se aclara en vivo")
	# al volver a cargar, la escena se construye ya con los recortes
	esc.guardar_posicion()
	change_scene_to_file(REGION)
	for i in 600:
		await process_frame
		if current_scene != null and current_scene != esc and current_scene.scene_file_path == REGION and i > 10:
			break
	esc = current_scene
	_ok(esc.regulador != null and esc.regulador.nivel == tope, "6: al recargar no sigue en el escalón %d" % tope)
	_ok(is_equal_approx(esc.get_viewport().scaling_3d_scale, fin["escala_3d"]), "6: al recargar, resolución %.2f" % esc.get_viewport().scaling_3d_scale)
	_ok(_hierba(esc, fin["dist_hierba"]).size() > 0, "6: al recargar, la hierba no se construye a %.2f m" % fin["dist_hierba"])
	var d: Dictionary = Cal.datos()
	_ok(d["hierba"] == fin["hierba"] and d["espuma"] == fin["espuma"], "6: al recargar, hierba y espuma sin recortar: %s" % d)
	print("6. en la región: escalones en vivo y al recargar")
	change_scene_to_file("res://mapa.tscn")
	await _esperar(30)


func _hierba(esc: Node, dist: float) -> Array:
	return esc.find_children("*", "MultiMeshInstance3D", true, false).filter(func(m):
		return absf(m.visibility_range_end - dist) < 0.01)


func _sol(esc: Node) -> DirectionalLight3D:
	for l in esc.find_children("*", "DirectionalLight3D", true, false):
		return l
	return null
