extends SceneTree
# Bramavidrio, pulido (12/11; informe docs/memory/agents/animaciones_v12_bramavidrio_pulido.md). Con ventana: combates
# de verdad que CORREN (no congelados) desde la cámara real del combate fijo «mc_bramavidrio» (grupo 13, Kael, Lya y
# Garon, la interfaz), con la versión y el perfil pedidos. No toca el combate ni el modelo: solo mira y saca fotos.
#   --script res://pruebas/fotos_bramavidrio_pulido.gd -- salida=<carpeta> version=<1|2|3> perfil=<bajo|medio|alto>
#        [movil]        (efectos y resolución del teléfono)  [sin_fotos] (solo las medidas)  [solo=1,2,3] (combates)
# Combate 1, «secuencia»: reposo, dos Embestidas, el aviso y la Fractura (defendida), el Aliento (defendido: succión,
#   descarga, barrido), los héroes atacándole, la derrota y la victoria. La vida del gusano la ajusta esta herramienta
#   para que el orden sea siempre el mismo (furia tras la Fractura, casi muerto tras el Aliento); la de los héroes, para
#   que nadie caiga.
# Combate 2, «corte»: el Aliento cortado a golpes (se atraganta) y el bucle de la succión que calla.
# Combate 3, «salir»: el combate se cierra mientras aspira (como salir a medias): ni bucle, ni efectos, ni nodos sueltos.
# En CADA fotograma mide el ORDEN DE DIBUJO frente a cada héroe con los huesos del modelo (cabeza, mandíbula, cuello y
# garras) proyectados con la cámara del combate y su sombra en la arena: un tramo que cae sobre el dibujo del héroe y
# está más cerca de la cámara que sus pies debería taparlo; uno más lejos, quedar detrás. Apunta los fotogramas en que
# el gusano queda detrás de un tramo que debería tapar («queda_detras») o tapa al héroe con tramos que están detrás
# («tapa_mal»), por fase, y guarda una foto del primero de cada clase. Imprime «RESUMEN_ORDEN …» y «LIMPIEZA …».
# No mide rendimiento.

const ARCHIVO := "user://fotos_bramavidrio_pulido.save"
const MAX_FOTOGRAMAS := 12000
const MOMENTOS := {
	"ataque": [[0.2, "1_anticipacion"], [0.55, "2_fija"], [0.85, "3_lanza"], [1.0, "4_impacto"], [1.3, "5_sacude"],
		[1.9, "6_recupera"]],
	"ataque_sismico": [[1.2, "1_aviso"], [2.2, "2_cae"], [2.56, "3_impacto"], [2.9, "4_placas"], [3.45, "5_recupera"]],
	"ataque_aliento": [[1.2, "1_succion"], [1.9, "2_descarga"], [2.25, "3_barrido"], [2.62, "4_fin_descarga"],
		[3.3, "5_recupera"]],
	"derrota": [[0.5, "1_dolor"], [1.65, "2_caida"], [3.3, "3_suelo"]],
	"herida": [[0.12, "golpe"]],
}
const FASE := {"ataque": "embestida", "ataque_sismico": "fractura", "ataque_aliento": "aliento", "derrota": "derrota",
	"herida": "herida", "reposo": "reposo", "emerger": "entrada", "rugido": "rugido"}
const RADIO_HEROE := 70.0               # medio ancho del dibujo de un héroe en la escena (px de escena)

var salida := ""
var version := 2
var perfil := "medio"
var fotos := true
var solo := "123"
var medir_giros := ""
var etiqueta_fija := ""
var B
var G
var P
var c = null
var z = null
var zp = null
var etiqueta := ""
var hechas := {}
var veces := {}                         # clip → cuántas veces ha empezado
var clip_ant := ""
var orden := {}                         # fase → {fotogramas, queda_detras, tapa_mal, mixto}
var foto_orden := {}
var _encima_ant := {}
var limpieza: Array = []
var fallos: Array = []
var lineas: Array = []


func _initialize() -> void:
	B = load("res://combate_bramavidrio.gd")
	G = load("res://grupo.gd")
	P = load("res://progreso.gd")
	for a in OS.get_cmdline_user_args():
		var k := a.get_slice("=", 0)
		var v := a.substr(k.length() + 1)
		match k:
			"salida": salida = v
			"version": version = int(v)
			"perfil": perfil = v
			"sin_fotos": fotos = false
			"solo": solo = v
			"giros": medir_giros = v
			"glb": Engine.set_meta("bramavidrio3_glb", v)
			"tex": Engine.set_meta("bramavidrio3_textura", v)
			"etiqueta": etiqueta_fija = v
	if salida == "":
		salida = OS.get_user_data_dir().path_join("fotos_bramavidrio_pulido")
	DirAccess.make_dir_recursive_absolute(salida)
	etiqueta = "v%d_%s%s" % [version, perfil, "_movil" if "movil" in OS.get_cmdline_user_args() else ""]
	if etiqueta_fija != "":
		etiqueta = etiqueta_fija
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	Engine.set_meta("bramavidrio_version", version)
	Engine.set_meta("calidad_proto", perfil)
	_correr.call_deferred()


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _foto(nombre: String) -> void:
	if not fotos:
		return
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	if img != null and not img.is_empty():
		img.save_png(salida.path_join("%s_%s.png" % [etiqueta, nombre]))
		print("  foto ", nombre)


func _combate(vida := 1.0, normales := 0) -> void:
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "combate_fijo", "tipo_combate", "zona", "desde_mapa"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	G.datos()
	Engine.set_meta("grupo_activo", ["Kael", "Lya", "Garon"])
	for n in ["Kael", "Lya", "Garon"]:
		G.datos()[n]["nivel"] = 10
		G.datos()[n]["exp"] = 0
		G.datos()[n]["pv"] = -1
		G.datos()[n]["pm"] = -1
	Engine.set_meta("combates_ganados", {})
	Engine.set_meta("zona", "desierto")
	Engine.set_meta("tipo_combate", "jefe")
	Engine.set_meta("grupo_combate", B.GRUPO)
	Engine.set_meta("combate_fijo", B.COMBATE)
	seed(20261112)
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	z = c.enemigos[0]
	zp = c._p3d(z)
	hechas.clear()
	_encima_ant.clear()
	veces.clear()
	clip_ant = ""
	if vida < 1.0:
		z["hp"] = int(z["hp_max"] * vida)
		z["normales"] = normales


func _correr() -> void:
	await _esperar(10)
	var huerfanos0: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	print("== %s · combate fijo %s · grupo %d" % [etiqueta, B.COMBATE, B.GRUPO])
	if medir_giros != "":
		await _medir_giros()
		quit(0)
		return
	if solo.contains("1"):
		await _secuencia()
	if solo.contains("2"):
		await _corte()
	if solo.contains("3"):
		await _salir()
	await _esperar(10)
	var h: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	limpieza.append("nodos huérfanos al acabar todo: %d (al empezar %d)" % [h, huerfanos0])
	if h > huerfanos0:
		fallos.append("nodos huérfanos: %d → %d" % [huerfanos0, h])
	for fase in orden:
		var o: Dictionary = orden[fase]
		print("RESUMEN_ORDEN %s %s: %d fotogramas · queda_detras %d · tapa_mal %d · mixto %d · cambios %d" % [etiqueta, fase,
			o["fotogramas"], o["queda_detras"], o["tapa_mal"], o["mixto"], o["cambios"]])
	for l in limpieza:
		print("LIMPIEZA ", l)
	for l in lineas:
		print(l)
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	Engine.remove_meta("archivo_partida_prueba")
	quit(1 if fallos.size() > 0 else 0)


# ================================================================= combate 1: la secuencia entera

func _secuencia() -> void:
	await _combate()
	var decidido := -1
	var f_fin := -1
	var reposo_hecho := false
	var acto := {}                                      # héroe → fotogramas actuando
	for fr in MAX_FOTOGRAMAS:
		await _esperar(1)
		if c == null:
			break
		_medir_orden()
		await _fotos_clip()
		if not reposo_hecho and c.estado == "menu" and zp != null and zp._clip == "reposo" and not zp._entrando:
			reposo_hecho = true
			await _esperar(10)
			await _foto("0_reposo")
		for h in c.heroes:                              # un héroe que actúa (z_index 5): su golpe, a los 16 fotogramas
			if h["rig"].z_index == 5 and c.estado == "accion":
				acto[h["nombre"]] = int(acto.get(h["nombre"], 0)) + 1
				if acto[h["nombre"]] == 16 and not hechas.has("heroe_" + h["nombre"]):
					hechas["heroe_" + h["nombre"]] = true
					await _foto("heroe_%s_golpea" % h["nombre"].to_lower())
			else:
				acto[h["nombre"]] = 0
		var cont: Dictionary = c.brama.contador if c.brama != null else {}
		if c.estado == "menu":                              # el guion de la secuencia
			for h in c.heroes:
				if h["hp"] > 0 and h["hp"] < h["hp_max"] * 0.55:
					h["hp"] = h["hp_max"]
				h["mp"] = h["mp_max"]
			if int(cont.get("fractura", 0)) >= 1 and int(cont.get("aliento", 0)) == 0 and z["hp"] > z["hp_max"] * 0.5:
				z["hp"] = int(z["hp_max"] * 0.45)
			if int(cont.get("aliento", 0)) >= 1 and int(cont.get("recupera", 0)) >= 1 and z["hp"] > 2:
				z["hp"] = 2
			c._actualizar()
			if c.actor is Dictionary and c.turnos_heroe != decidido:
				decidido = c.turnos_heroe
				_decidir(true)
		if c.estado == "fin" and f_fin < 0:
			f_fin = fr
			lineas.append("secuencia: acciones %s" % str(cont))
		if f_fin >= 0 and fr - f_fin == 75:
			await _foto("9_victoria")
		if f_fin >= 0 and fr - f_fin > 80:
			break
	if f_fin < 0:
		fallos.append("secuencia: el combate no acaba")
	await _cerrar("victoria")


func _decidir(defender_aliento: bool) -> void:
	var a: Dictionary = c.actor
	var esp: String = str(z.get("especial", "")) if z.get("cargando", false) else ""
	if esp == "sismico" or (esp == "aliento" and defender_aliento):
		c._defender()
		return
	if esp == "aliento":                                  # cortarlo: Lya con Fuego, Garon con Juicio, Kael a golpes
		if a["nombre"] == "Lya":
			c._elegir_hechizo("Fuego", 1, true)
		elif a["nombre"] == "Garon" and a["mp"] >= c.TECNICAS_GARON["Juicio"]["coste"]:
			c._tecnica_garon("Juicio", z)
		else:
			c._menu_objetivo("atacar", "")
			c._confirmar_objetivo(z)
		return
	if a["nombre"] == "Lya" and not hechas.has("lya_fuego"):
		hechas["lya_fuego"] = true
		c._elegir_hechizo("Fuego", 1, true)
		return
	c._menu_objetivo("atacar", "")
	c._confirmar_objetivo(z)


# Las fotos de cada clip en sus instantes (la primera vez; la Embestida, las dos primeras).
func _fotos_clip() -> void:
	if zp == null or zp.anim == null:
		return
	var clip := String(zp.anim.current_animation)
	if clip != clip_ant:
		if clip != "":
			veces[clip] = int(veces.get(clip, 0)) + 1
		clip_ant = clip
	if not MOMENTOS.has(clip):
		return
	var n: int = int(veces.get(clip, 1))
	if n > (2 if clip == "ataque" else 1):
		return
	var pos: float = zp.anim.current_animation_position
	for m in MOMENTOS[clip]:
		var clave := "%s_%d_%s" % [clip, n, m[1]]
		if pos >= m[0] and not hechas.has(clave):
			hechas[clave] = true
			var extra := ""
			if zp.has_method("angulo_boca"):
				extra = " · boca %.1f°" % zp.angulo_boca()
			lineas.append("  %s %s %.2f s%s · orden %s · sombra-pies %s" % [FASE[clip], m[1], pos, extra, _orden_texto(), _profundidades()])
			await _foto("%s%s_%s" % [FASE[clip], "" if n == 1 else str(n), m[1]])


func _orden_texto() -> String:
	var rig: Node2D = z["rig"]
	var t := "gusano[%d,z%d]" % [rig.get_index(), rig.z_index]
	for h in c.heroes:
		t += " %s[%d,z%d]" % [h["nombre"], h["rig"].get_index(), h["rig"].z_index]
	return t


# ================================================================= orden de dibujo, en cada fotograma

func _puntos() -> PackedVector3Array:
	var pts := PackedVector3Array()
	var sk: Skeleton3D = zp.skel if "skel" in zp else null
	if sk == null:
		return pts
	var nombres := ["cabeza", "mandibula", "mano_izq", "mano_der"]
	for i in range(1, 19):
		nombres.append("col_%02d" % i)
	for n in nombres:
		var i := sk.find_bone(n)
		if i >= 0:
			pts.append(sk.global_transform * sk.get_bone_global_pose(i).origin)
	return pts


func _medir_orden() -> void:
	if zp == null or not z.has("cam3d") or c.estado == "fin" and z["hp"] > 0:
		return
	var rig: Node2D = z["rig"]
	if not is_instance_valid(rig) or not rig.visible:
		return
	var clip := String(zp.anim.current_animation) if zp.anim != null else ""
	var fase: String = FASE.get(clip, clip)
	if c.estado == "accion" and c.heroes.any(func(h): return h["rig"].z_index == 5):
		fase = "heroe_ataca"
	if not orden.has(fase):
		orden[fase] = {"fotogramas": 0, "queda_detras": 0, "tapa_mal": 0, "mixto": 0, "cambios": 0}
	var o: Dictionary = orden[fase]
	o["fotogramas"] += 1
	var spr: Sprite2D = z["partes"]["sprite"]
	var cam: Camera3D = z["cam3d"]
	var suelo: float = zp.global_position.y
	var marcas: Array = []
	for w in _puntos():
		marcas.append([c.escena.to_local(spr.to_global(cam.unproject_position(w))),
			c.escena.to_local(spr.to_global(cam.unproject_position(Vector3(w.x, suelo, w.z))))])
	var mal := ""
	for h in c.heroes:                                  # cuántas veces cambia delante/detrás de cada héroe
		var hr0: Node2D = h["rig"]
		var enc0: bool = rig.z_index > hr0.z_index or (rig.z_index == hr0.z_index and rig.get_index() > hr0.get_index())
		if _encima_ant.has(h["nombre"]) and _encima_ant[h["nombre"]] != enc0:
			o["cambios"] += 1
		_encima_ant[h["nombre"]] = enc0
	for h in c.heroes:
		if h["hp"] <= 0 and h["rig"].modulate.a < 0.5:
			continue
		var pie: Vector2 = c._suelo_de(h)
		var alto: float = maxf(120.0, (pie.y - c._centro(h).y) * 2.1)
		var delante := false
		var detras := false
		for m in marcas:
			var s: Vector2 = m[0]
			if absf(s.x - pie.x) > RADIO_HEROE or s.y < pie.y - alto or s.y > pie.y + 10.0:
				continue
			var g: Vector2 = m[1]
			if g.y > pie.y + 4.0:
				delante = true
			elif g.y < pie.y - 4.0:
				detras = true
		if not delante and not detras:
			continue
		var hr: Node2D = h["rig"]
		var encima: bool = rig.z_index > hr.z_index or (rig.z_index == hr.z_index and rig.get_index() > hr.get_index())
		if delante and detras:
			o["mixto"] += 1
			if not encima:                                   # la parte de delante (la cabeza, casi siempre) manda
				o["queda_detras"] += 1
				mal = "queda_detras_" + h["nombre"]
		elif delante and not encima:
			o["queda_detras"] += 1
			mal = "queda_detras_" + h["nombre"]
		elif detras and encima:
			o["tapa_mal"] += 1
			mal = "tapa_mal_" + h["nombre"]
	if mal != "" and int(foto_orden.get(fase + mal, 0)) < 1:
		foto_orden[fase + mal] = 1
		lineas.append("  ORDEN %s %s (%s %.2f s) · %s" % [fase, mal, clip, zp.anim.current_animation_position, _orden_texto()])
		_foto("orden_%s_%s" % [fase, mal])


# ================================================================= combate 2: el Aliento cortado

func _corte() -> void:
	await _combate(0.45, 1)
	var decidido := -1
	var f_corte := -1
	for fr in 4000:
		await _esperar(1)
		_medir_orden()
		await _fotos_clip()
		var cont: Dictionary = c.brama.contador
		if c.estado == "menu" and c.actor is Dictionary and c.turnos_heroe != decidido:
			decidido = c.turnos_heroe
			_decidir(false)
		if int(cont.get("cortado", 0)) >= 1 and f_corte < 0:
			f_corte = fr
		if f_corte >= 0 and fr - f_corte == 6:
			await _foto("corte_1_atraganta")
		if f_corte >= 0 and fr - f_corte == 24:
			await _foto("corte_2_despues")
			var bucle := _suena("brama_succion_bucle")
			limpieza.append("corte: el bucle de la succión 0,8 s después: %s" % ("SUENA" if bucle else "callado"))
			if bucle:
				fallos.append("corte: el bucle de la succión sigue sonando")
		if f_corte >= 0 and fr - f_corte > 30:
			break
	if f_corte < 0:
		fallos.append("corte: el Aliento no se corta")
	await _cerrar("corte")


# ================================================================= combate 3: salir mientras aspira

func _salir() -> void:
	await _combate(0.45, 1)
	var decidido := -1
	var f_succion := -1
	for fr in 3000:
		await _esperar(1)
		if c.estado == "menu" and c.actor is Dictionary and c.turnos_heroe != decidido:
			decidido = c.turnos_heroe
			_decidir(true)
		if c.brama.succion != null and f_succion < 0:
			f_succion = fr
		if f_succion >= 0 and fr - f_succion == 30:
			limpieza.append("salir: aspirando, el bucle %s" % ("suena" if _suena("brama_succion_bucle") else "NO suena"))
			break
	if f_succion < 0:
		fallos.append("salir: no llega a aspirar")
	c.queue_free()                                      # se cierra a medias (como salir del combate)
	c = null
	await _esperar(12)
	var bucle := _suena("brama_succion_bucle")
	limpieza.append("salir: tras cerrar, el bucle %s · reproductores de Bramavidrio sonando: %s" % [
		"SUENA" if bucle else "callado", str(_brama_sonando())])
	if bucle:
		fallos.append("salir: el bucle de la succión sigue tras cerrar el combate")


# ================================================================= limpieza

func _suena(nombre: String) -> bool:
	return _brama_sonando().has(nombre)


func _brama_sonando() -> Array:
	var r: Array = []
	for p in root.get_node("Sonido")._todas():
		if is_instance_valid(p) and p.playing and String(p.get_meta("efecto", "")).begins_with("brama_") \
				and not p.get_meta("apagando", false):
			r.append(String(p.get_meta("efecto", "")))
	return r


func _cerrar(que: String) -> void:
	if c == null:
		return
	for i in 240:
		if c.brama == null or c.brama.efectos_vivos().is_empty():
			break
		await process_frame
	var vivos: Array = c.brama.efectos_vivos() if c.brama != null else []
	limpieza.append("%s: efectos de Bramavidrio que quedan %s · bucle %s · cartel %s · succión %s · marca %s" % [que,
		str(vivos), "SUENA" if _suena("brama_succion_bucle") else "callado", c.brama.cartel != null,
		c.brama.succion != null, c.brama.marca != null])
	if not vivos.is_empty():
		fallos.append("%s: quedan efectos %s" % [que, str(vivos)])
	if _suena("brama_succion_bucle"):
		fallos.append("%s: el bucle de la succión suena al acabar" % que)
	c.queue_free()
	c = null
	await _esperar(8)


# ================================================================= medir giros de la Fractura (combate quieto)

# «giros=0;-20;-35»: grados que gira hacia el fondo (desde FRENTE_ENEMIGO) antes de la Fractura. Para cada giro y en
# cada instante, dónde queda la cabeza en la pantalla, la caja del cuerpo y cuántos tramos caen delante de Garon.
func _medir_giros() -> void:
	await _combate()
	for i in 900:
		await process_frame
		if zp != null and zp.anim != null and i > 90 and not zp._entrando and zp._clip == "reposo":
			break
	await _esperar(10)
	c.process_mode = Node.PROCESS_MODE_DISABLED
	var rig: Node2D = z["rig"]
	var i0 := rig.get_index()
	var base: Vector3 = zp.FRENTE_ENEMIGO
	for g in medir_giros.split(";"):
		var ang := deg_to_rad(float(g))
		var dir := Vector3(base.x * cos(ang) + base.z * sin(ang), 0.0, -base.x * sin(ang) + base.z * cos(ang))
		zp.mirar(dir, 0.0)
		for t in [1.2, 1.6, 2.55, 2.9]:
			zp._clip = "ataque_sismico"
			zp._eventos = []
			zp._espera = []
			zp.anim.play("ataque_sismico", 0.0)
			zp.anim.seek(t, true)
			zp._process(0.0)
			await _esperar(3)
			var cab: Vector2 = c._a_pantalla(c.brama._en_escena(zp.cabeza()))
			var caja := Rect2(cab, Vector2.ZERO)
			for w in _puntos():
				caja = caja.expand(c._a_pantalla(c.brama._en_escena(w)))
			var garon: Array = c.heroes.filter(func(h): return h["nombre"] == "Garon")
			var tapa := 0
			if not garon.is_empty():
				var pie: Vector2 = c._suelo_de(garon[0])
				var alto: float = maxf(120.0, (pie.y - c._centro(garon[0]).y) * 2.1)
				for w in _puntos():
					var s: Vector2 = c.brama._en_escena(w)
					if absf(s.x - pie.x) < RADIO_HEROE and s.y > pie.y - alto and s.y < pie.y + 10.0:
						tapa += 1
			lineas.append("GIRO %s° t %.2f: cabeza en pantalla (%.0f, %.0f) · cuerpo x %.0f-%.0f, y %.0f-%.0f · tramos sobre Garon %d" % [
				g, t, cab.x, cab.y, caja.position.x, caja.end.x, caja.position.y, caja.end.y, tapa])
			c.escena.move_child(rig, i0)
			await _foto("giro_%s_%.2f" % [g, t])
	for l in lineas:
		print(l)


# Para cada héroe, cuánto queda por delante de sus pies (px de escena, + delante) la sombra del tramo que cae sobre su
# dibujo y está más cerca de la cámara («-» si ninguno le toca).
func _profundidades() -> String:
	var spr: Sprite2D = z["partes"]["sprite"]
	var cam: Camera3D = z["cam3d"]
	var suelo: float = zp.global_position.y
	var t := ""
	for h in c.heroes:
		var pie: Vector2 = c._suelo_de(h)
		var alto: float = maxf(120.0, (pie.y - c._centro(h).y) * 2.1)
		var mejor := -INF
		for w in _puntos():
			var s: Vector2 = c.escena.to_local(spr.to_global(cam.unproject_position(w)))
			if absf(s.x - pie.x) > RADIO_HEROE or s.y < pie.y - alto or s.y > pie.y + 10.0:
				continue
			var g: Vector2 = c.escena.to_local(spr.to_global(cam.unproject_position(Vector3(w.x, suelo, w.z))))
			mejor = maxf(mejor, g.y - pie.y)
		t += " %s:%s" % [h["nombre"], "-" if mejor == -INF else "%+.0f" % mejor]
	return t
