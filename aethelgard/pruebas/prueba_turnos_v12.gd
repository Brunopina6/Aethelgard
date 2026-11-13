extends SceneTree
# Línea de turnos V12 (combate_turnos_v12.gd, 13/11/2026). Con «-- auto semilla=7», sin ventana, varios combates de
# verdad seguidos en el mismo proceso, con la línea ENCENDIDA (y uno apagado, para ver que no aparece):
#   tres: el combate de tres de siempre (protagonistas originales); tres_v2: el mismo con los héroes v2 y la animación
#   v12; brama: Bramavidrio (grupo 13); centinela: el Guardián de piedra con Grimfang (grupo 4, enemigos_v12);
#   golem: el Gólem de ámbar con Grimfang (grupo 6, enemigos_v12).
# Comprueba en cada uno:
#   1. Apagada no existe; encendida está en la interfaz, dentro de 1280 × 720 y sin tapar el menú ni el cartel.
#   2. Acierta: cada vez que empieza un turno, quien actúa es el primero que la línea daba como siguiente justo antes
#      (FALLO si acierta menos del 90 %; un empate exacto de barras puede caer de cualquier lado).
#   3. Avisos: cuando un enemigo anuncia un ataque cargado («⚠» en su rótulo), la línea lo marca y lo escribe.
#   4. Coste: solo se vuelve a dibujar cuando cambia algo (FALLO si se redibuja en más de 1 de cada 3 fotogramas).
# Con «fotos=<carpeta>» (y ventana) guarda capturas: al empezar, con un aviso y cada 150 fotogramas; con «video=<carpeta>»,
# un JPG cada 2 fotogramas. «casos=a,b»: solo esos.

const CASOS := [
	{"n": "apagada", "grupo": -1, "v12e": false, "v2": false, "linea": false, "turnos": 3},
	{"n": "tres", "grupo": -1, "v12e": false, "v2": false, "linea": true, "turnos": 14},
	{"n": "tres_v2", "grupo": -1, "v12e": false, "v2": true, "linea": true, "turnos": 10},
	{"n": "brama", "grupo": 13, "v12e": false, "v2": false, "linea": true, "turnos": 12},
	{"n": "centinela", "grupo": 4, "v12e": true, "v2": false, "linea": true, "turnos": 12},
	{"n": "golem", "grupo": 6, "v12e": true, "v2": false, "linea": true, "turnos": 12},
]
const LIMITE := 4200

var c: Node
var caso := -1
var frames := 0
var fallos := 0
var fotos := ""
var prevision = null                 # el siguiente que daba la línea en el fotograma anterior a empezar un turno
var estado_ant := ""
var aciertos := 0
var turnos := 0
var avisos_vistos := 0
var avisos_marcados := 0
var foto_aviso := false
var resumen: Array = []
var video := ""                      # «video=<carpeta>»: un JPG cada 2 fotogramas (para montar un vídeo)
var n_video := 0
var solo: PackedStringArray = []      # «casos=brama,golem»: solo esos


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("fotos="):
			fotos = a.substr(6)
			DirAccess.make_dir_recursive_absolute(fotos)
		elif a.begins_with("video="):
			video = a.substr(6)
			DirAccess.make_dir_recursive_absolute(video)
		elif a.begins_with("casos="):
			solo = a.substr(6).split(",")
	_siguiente.call_deferred()


func _fallo(t: String) -> void:
	fallos += 1
	print("FALLO: [%s] %s" % [CASOS[caso]["n"], t])


func _siguiente() -> void:
	caso += 1
	while caso < CASOS.size() and not solo.is_empty() and not CASOS[caso]["n"] in solo:
		caso += 1
	if caso >= CASOS.size():
		for r in resumen:
			print(r)
		print("FALLOS: %d" % fallos)
		quit(1 if fallos > 0 else 0)
		return
	var k: Dictionary = CASOS[caso]
	frames = 0
	prevision = null
	estado_ant = ""
	aciertos = 0
	turnos = 0
	avisos_vistos = 0
	avisos_marcados = 0
	foto_aviso = false
	Engine.set_meta("turnos_v12", k["linea"])
	Engine.set_meta("heroes_v2", k["v2"])
	Engine.set_meta("combate_anim_v12", k["v2"])
	Engine.set_meta("enemigos_v12", k["v12e"])
	if k["grupo"] >= 0:
		Engine.set_meta("grupo_combate", k["grupo"])
	seed(7)
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)


func _process(_d: float) -> bool:
	if c == null:
		return false
	frames += 1
	var k: Dictionary = CASOS[caso]
	var linea = c.capa.get_node_or_null("LineaTurnosV12") if c.capa != null else null
	if frames == 5:
		if not k["linea"] and linea != null:
			_fallo("apagada y la línea existe")
		if k["linea"]:
			if linea == null:
				_fallo("encendida y no está")
			else:
				var r: Rect2 = linea.get_global_rect()
				if r.position.x < 0 or r.end.x > 1280 or r.position.y < 0 or r.end.y > 720:
					_fallo("se sale de la pantalla: %s" % str(r))
				if r.intersects(Rect2(c.registro.position, c.registro.size)) and r.position.y < c.registro.position.y + c.registro.size.y - 4:
					_fallo("tapa el cartel: %s y %s" % [str(r), str(Rect2(c.registro.position, c.registro.size))])
		_foto("inicio")
	if linea != null and frames > 5:
		# 2. ¿acierta quién actúa?
		var empieza: bool = c.estado in ["menu", "enemigo"] and not estado_ant in ["menu", "enemigo", "objetivo", "accion"]
		if empieza and prevision != null:
			turnos += 1
			var quien = c.actor if c.estado == "menu" else c.atacante_actual
			if quien is Dictionary and is_same(quien, prevision):
				aciertos += 1
			else:
				print("  [%s] previsto %s, actúa %s" % [k["n"], prevision["nombre"], quien["nombre"] if quien is Dictionary else "?"])
		if c.estado == "esperando":
			var p: Array = linea.prever()
			prevision = p[0]["f"] if not p.is_empty() else null
		# 3. avisos
		var hay := false
		for e in c.enemigos:
			if e["hp"] > 0 and e.has("lbl_estado") and "⚠" in e["lbl_estado"].text:
				hay = true
		if hay:
			avisos_vistos += 1
			if linea._aviso != "":
				avisos_marcados += 1
			if not foto_aviso and linea._aviso != "":
				foto_aviso = true
				_foto("aviso")
	if frames % 150 == 0:
		_foto("f%04d" % frames)
	if video != "" and frames % 2 == 0:
		root.get_viewport().get_texture().get_image().save_jpg(video.path_join("%05d.jpg" % n_video), 0.88)
		n_video += 1
	estado_ant = c.estado
	if turnos >= k["turnos"] or c.estado == "fin" or frames >= LIMITE:
		_cerrar(linea)
	return false


func _cerrar(linea) -> void:
	var k: Dictionary = CASOS[caso]
	var txt := "CASO %s: %d fotogramas, %d turnos" % [k["n"], frames, turnos]
	if linea != null:
		var pct: float = 100.0 * aciertos / maxf(turnos, 1)
		txt += ", acierta %d de %d (%.0f %%), avisos marcados %d de %d fotogramas, dibujos %d (1 de cada %.1f fotogramas)" % [
			aciertos, turnos, pct, avisos_marcados, avisos_vistos, linea.dibujos, float(frames) / maxf(linea.dibujos, 1)]
		if turnos >= 3 and pct < 90.0:
			_fallo("acierta poco: %.0f %%" % pct)
		if avisos_vistos > 0 and avisos_marcados < avisos_vistos * 0.8:
			_fallo("no marca los avisos (%d de %d)" % [avisos_marcados, avisos_vistos])
		if linea.dibujos * 3 > frames:
			_fallo("se redibuja demasiado: %d veces en %d fotogramas" % [linea.dibujos, frames])
	resumen.append(txt)
	print(txt)
	c.queue_free()
	c = null
	_siguiente.call_deferred()


func _foto(etiqueta: String) -> void:
	if fotos == "":
		return
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(fotos.path_join("%s_%s.png" % [CASOS[caso]["n"], etiqueta]))
