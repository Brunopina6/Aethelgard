extends SceneTree
# Encuentros con los niveles REALES de incorporación (encargo del 08/11 por la noche, punto 3; sin la nivelación
# automática de e670a5d, que es la propuesta D-062). En una partida nueva, grupo.gd crea a los tres héroes a nivel 1, y
# los ausentes no ganan experiencia: Lya llega a nivel 1 en PV-03 y Garon a nivel 1 en PV-05. Solo Kael ha subido.
# Combates de verdad (combate.tscn) con «-- 3d sin_prologo auto»: cada héroe solo ataca en su turno (Lya no cura ni
# lanza magias) y los puntos de mejora sin gastar: es el caso PESIMISTA de un jugador.
#   A. De PV-03 a PV-05 (Kael y Lya): los grupos al azar de dos (combate.gd, AL_AZAR_POR_TAMANO[2]).
#   B. PV-06, el centinela (GRUPOS[0], dos Grimfang), justo después de que llegue Garon.
#   C. Después de PV-06 (los tres): los cinco grupos al azar del grupo de tres (0 a 4).
# Kael va a nivel 1 (el peor caso, sin ningún combate antes) y a un nivel típico; Lya, a 1 o al nivel típico al llegar
# Garon. Dos modelos de jugador: «solo ataques» (pesimista) y «con Cura» (quien sabe Cura la usa en el más herido si
# alguien baja del 50 %; Engine «prueba_curar», combate.gd). Cada combinación se juega varias veces. Imprime una tabla:
# victorias, duración, la vida más baja que queda y cuántos caen. FALLO si alguna combinación se pierde.

const MAX_FOTOGRAMAS := 9000                      # 300 s de juego por combate como mucho
const REPETICIONES := 2

var P
var G
var casos: Array = []
var caso := {}
var c
var frames := 0
var f_caso := 0
var f_fin := -1
var fallos: Array = []
var filas := {}                                   # clave de la combinación → resultados


func _initialize() -> void:
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	if not load("res://modo3d.gd").activo() or not "auto" in OS.get_cmdline_user_args():
		print("FALLO: faltan «-- 3d» o «auto»")
		quit(1)
		return
	var dos: Array = load("res://combate.gd").AL_AZAR_POR_TAMANO[2]
	for niveles in [{"Kael": 1, "Lya": 1}, {"Kael": 3, "Lya": 1}]:
		for g in dos:
			_anadir("A · PV-03 a PV-05", ["Kael", "Lya"], niveles, g)
	for niveles in [{"Kael": 1, "Lya": 1, "Garon": 1}, {"Kael": 4, "Lya": 2, "Garon": 1}]:
		_anadir("B · PV-06 centinela", ["Kael", "Lya", "Garon"], niveles, 0)
		for g in 5:
			_anadir("C · tras PV-06", ["Kael", "Lya", "Garon"], niveles, g)


func _anadir(fase: String, activos: Array, niveles: Dictionary, grupo: int) -> void:
	for modo in ["solo ataques", "con Cura"]:
		for i in REPETICIONES:
			casos.append({"fase": fase, "activos": activos, "niveles": niveles, "grupo": grupo, "modo": modo})


func _limpiar() -> void:
	for k in P.CLAVES:
		if Engine.has_meta(k):
			Engine.remove_meta(k)


func _siguiente_caso() -> void:
	if casos.is_empty():
		_terminar()
		return
	caso = casos.pop_front()
	_limpiar()
	var d: Dictionary = G.datos()                 # partida nueva: los tres a nivel 1
	for n in caso["niveles"]:
		var l: int = caso["niveles"][n]
		d[n]["nivel"] = l
		d[n]["exp"] = 0
		d[n]["puntos"] = (l - 1) * G.PUNTOS_POR_NIVEL   # sin gastar: el caso pesimista
		d[n]["pv"] = -1                           # con la vida llena
	Engine.set_meta("grupo_activo", caso["activos"])
	Engine.set_meta("grupo_combate", caso["grupo"])
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("zona", "llanura")            # la de Pastos Verdes (zonas3d/pastos_verdes_3d.gd, ZONA)
	Engine.set_meta("prueba_curar", caso["modo"] == "con Cura")
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	f_caso = frames
	f_fin = -1


func _process(_d: float) -> bool:
	frames += 1
	if frames == 1:
		_siguiente_caso()
		return false
	if c == null:
		return false
	if c.estado == "fin" and f_fin < 0:
		f_fin = frames
	if f_fin >= 0 and frames - f_fin >= 60:
		_apuntar()
		c.queue_free()
		c = null
		_siguiente_caso()
	elif frames - f_caso > MAX_FOTOGRAMAS:
		fallos.append("%s contra el grupo %d no terminó (¿atascado?)" % [_clave(), caso["grupo"]])
		c.queue_free()
		c = null
		_siguiente_caso()
	return false


func _clave() -> String:
	var partes: Array = []
	for n in caso["activos"]:
		partes.append("%s %d" % [n, caso["niveles"][n]])
	return "%s | %s | grupo %d | %s" % [caso["fase"], ", ".join(partes), caso["grupo"], caso["modo"]]


func _apuntar() -> void:
	var gana: bool = c.enemigos.all(func(e): return e["hp"] <= 0 or e.get("huido", false))
	var vida_min := 1.0
	var caidos := 0
	var k := _clave()
	if not filas.has(k):
		filas[k] = {"jugados": 0, "ganados": 0, "segundos": 0.0, "vida_min": 1.0, "caidos": 0, "quien": {}}
	var f: Dictionary = filas[k]
	for h in c.heroes:
		vida_min = minf(vida_min, float(h["hp"]) / float(maxi(1, h["hp_max"])))
		if h["hp"] <= 0:
			caidos += 1
			f["quien"][h["nombre"]] = f["quien"].get(h["nombre"], 0) + 1
	f["jugados"] += 1
	f["ganados"] += 1 if gana else 0
	f["segundos"] += (f_fin - f_caso) / 30.0
	f["vida_min"] = minf(f["vida_min"], vida_min)
	f["caidos"] = maxi(f["caidos"], caidos)
	if not gana:
		fallos.append("%s: perdido" % k)


func _terminar() -> void:
	print("Fase | niveles | grupo | jugador → ganados/jugados · segundos de media · vida más baja al acabar · caídos (máx.) · quién cae")
	for k in filas:
		var f: Dictionary = filas[k]
		var quien: Array = []
		for n in f["quien"]:
			quien.append("%s ×%d" % [n, f["quien"][n]])
		print("  %s → %d/%d · %.0f s · %d %% · %d · %s" % [k, f["ganados"], f["jugados"], f["segundos"] / f["jugados"],
			roundi(f["vida_min"] * 100.0), f["caidos"], ", ".join(quien) if not quien.is_empty() else "nadie"])
	Engine.remove_meta("prueba_curar")
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)
