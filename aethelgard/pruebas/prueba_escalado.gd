extends SceneTree
# Escalado de los enemigos (V9, hito 7: «Enemigos con escalado de nivel» y 3.6 «Escalado de jefes»; combate_escalado.gd).
#   1. Tabla: cada región × nivel del grupo (por debajo, igual, +3, +10 y +30 sobre la base) × cada enemigo de ENEMIGOS,
#      como enemigo normal y en un combate fijo. El nivel del encuentro nunca baja de la base ni pasa del tope (jefes:
#      base..base+2); en la base o por debajo, el enemigo queda EXACTAMENTE como en ENEMIGOS; PV, ataque, experiencia y
#      oro nunca bajan del diseño, suben de forma monótona con el nivel del grupo y tienen techo; la velocidad, la
#      personalidad y lo demás no cambian; las recompensas suben en proporción a los PV (la experiencia igual, el oro
#      menos).
#   2. Combates de verdad («-- auto»), con datos aislados y la partida en memoria:
#      base  · llanura, grupo de nivel 1: los enemigos del combate son los de ENEMIGOS, número a número.
#      medio · bosque, grupo de nivel 7 (+3, sin «zona limpia»): dos Grimfang escalados; ganan los héroes y el reparto
#              da la experiencia y el oro escalados (2 × 35 y 2 × 21).
#      alto  · bosque, grupo de nivel 34 (+30): el encuentro se queda en su tope (8); a mitad del combate el grupo «sube»
#              a 50 y el nivel del encuentro no cambia; el combate termina sin errores.
#      jefe  · el Guardián del Bosque (combate fijo de Pastos Verdes, llanura) con el grupo a nivel 34: nivel 4 (base + 2),
#              487 PV y 19 de ataque (diseño: 420 y 17); fase 2, victoria y reparto sin errores.
#      En cada fotograma, como prueba_combate_seguro: ATB y PV en rango, nadie dos veces en la cola, estado conocido.

const E := preload("res://combate_escalado.gd")
const P := preload("res://progreso.gd")
const LIMITE := 4000                                  # fotogramas por combate (unos 130 s de juego con --fixed-fps 30)
const ESTADOS := ["esperando", "menu", "objetivo", "magia", "pocion", "enemigo", "accion", "decision", "fin"]
const CASOS := ["base", "medio", "alto", "jefe"]

var C                                                 # combate.gd (sus tablas)
var G
var I
var c: Node
var caso_i := -1
var frames := 0
var f_fin := -1
var fallos := 0
var avisados := {}
var datos := {}


func _initialize() -> void:
	if not "auto" in OS.get_cmdline_user_args():
		print("FALLO: falta «-- auto» (los héroes no actuarían solos)")
		quit(1)
		return
	Engine.set_meta("archivo_partida_prueba", "user://prueba_escalado.save")
	C = load("res://combate.gd")
	G = load("res://grupo.gd")
	I = load("res://inventario.gd")
	_tabla()
	_siguiente()


func _fallo(t: String) -> void:
	if avisados.has(t):
		return
	avisados[t] = true
	fallos += 1
	print("FALLO: [%s] %s" % [CASOS[caso_i] if caso_i >= 0 and caso_i < CASOS.size() else "tabla", t])


# ================================================================= 1. tabla

func _tabla() -> void:
	var regiones: Array = E.SUBIDA.keys() + ["otra_region"]
	var claves := ["hp", "atk", "exp", "oro"]
	print("región      base  tope  tope jefe | grupo → nivel del encuentro (PV ×, ataque ×, exp ×, oro ×)")
	for zona in regiones:
		var b: int = E.base(zona)
		var tope: int = b + E.subida(zona, false)
		var tope_j: int = b + E.subida(zona, true)
		if tope_j > b + E.SUBIDA_JEFE or tope_j > tope:
			_fallo("%s: el tope de los jefes (%d) pasa del margen (%d) o del de la región (%d)" % [zona, tope_j, b + E.SUBIDA_JEFE, tope])
		var niveles := [maxi(1, b - 3), b, b + 3, b + 10, b + 30]
		var fila := PackedStringArray()
		for ng in niveles:
			var n: int = E.nivel_encuentro(zona, ng, false)
			var s := n - b
			fila.append("%d→%d (%.2f, %.2f, %.2f, %.2f)" % [ng, n, E.multiplicador("hp", s), E.multiplicador("atk", s),
				E.multiplicador("exp", s), E.multiplicador("oro", s)])
		print("%-11s %4d  %4d  %9d | %s" % [zona, b, tope, tope_j, " · ".join(fila)])
		for jefe_fijo in ["", "combate_fijo_de_prueba"]:
			for clave in C.ENEMIGOS:
				var diseno: Dictionary = C.ENEMIGOS[clave]
				var previo := {}
				for ng in niveles:
					var e: Dictionary = diseno.duplicate(true)
					E.aplicar(e, zona, ng, jefe_fijo)
					var jefe: bool = E.es_jefe(diseno, jefe_fijo)
					var n: int = e.get("nivel_encuentro", -1)
					var donde := "%s, %s%s, grupo %d" % [zona, clave, " (fijo)" if jefe_fijo != "" else "", ng]
					if n < b:
						_fallo("%s: nivel del encuentro %d por debajo de la base %d" % [donde, n, b])
					if n > (tope_j if jefe else tope):
						_fallo("%s: nivel del encuentro %d por encima del tope %d" % [donde, n, tope_j if jefe else tope])
					if n != clampi(ng, b, tope_j if jefe else tope):
						_fallo("%s: nivel del encuentro %d y debía ser %d" % [donde, n, clampi(ng, b, tope_j if jefe else tope)])
					var sin_nivel := e.duplicate(true)
					sin_nivel.erase("nivel_encuentro")
					if ng <= b and sin_nivel != diseno:
						_fallo("%s: en la base o por debajo, el enemigo cambia (%s)" % [donde, sin_nivel])
					for k in diseno:                          # nada más que PV, ataque, exp y oro
						if not k in claves and str(e[k]) != str(diseno[k]):
							_fallo("%s: cambia «%s» (%s → %s)" % [donde, k, diseno[k], e[k]])
					for k in claves:
						if not diseno.has(k):
							continue
						var d0 := int(diseno[k])
						var v := int(e[k])
						if v < d0:
							_fallo("%s: %s %d por debajo del diseño %d" % [donde, k, v, d0])
						if v > int(ceil(d0 * float(E.MULT_MAX[k]))) + 1:
							_fallo("%s: %s %d pasa del techo (%d × %.2f)" % [donde, k, v, d0, E.MULT_MAX[k]])
						if previo.has(k) and v < int(previo[k]):
							_fallo("%s: %s baja al subir el grupo (%d → %d)" % [donde, k, previo[k], v])
						previo[k] = v
	# Recompensas en proporción: la experiencia sube como los PV y el oro no más que los PV (y ninguna sin techo).
	for s in range(0, 40):
		var mh: float = E.multiplicador("hp", s)
		var mx: float = E.multiplicador("exp", s)
		var mo: float = E.multiplicador("oro", s)
		if absf(mx - mh) > 0.001 or mo > mh + 0.001 or mo < 1.0 or mx < 1.0:
			_fallo("recompensas sin proporción con %d niveles: PV ×%.2f, exp ×%.2f, oro ×%.2f" % [s, mh, mx, mo])
		for k in claves:
			if E.multiplicador(k, s) > float(E.MULT_MAX[k]) + 0.0001:
				_fallo("%s ×%.2f pasa de su techo con %d niveles" % [k, E.multiplicador(k, s), s])
	# Ejemplos que se citan en la cabecera y en el informe.
	_igual(_escalado("grimfang", "bosque", 7, ""), {"hp": 136, "atk": 17, "exp": 35, "oro": 21, "nivel_encuentro": 7}, "Grimfang +3 en el bosque")
	_igual(_escalado("grimfang", "bosque", 34, ""), {"hp": 145, "atk": 18, "exp": 37, "oro": 22, "nivel_encuentro": 8}, "Grimfang en el tope del bosque")
	_igual(_escalado("guardian_bosque", "llanura", 34, "pastos_guardian"), {"hp": 487, "atk": 19, "exp": 104, "oro": 0, "nivel_encuentro": 4}, "Guardián del Bosque en su tope")
	_igual(_escalado("gorthor", "garganta", 7, "garganta_gorthor"), {"hp": 460, "atk": 22, "exp": 60, "oro": 150, "nivel_encuentro": 7}, "Gorthor en la base")
	_igual(_escalado("zarzalin", "llanura", 1, ""), {"hp": 80, "atk": 11, "exp": 20, "oro": 12, "nivel_encuentro": 2}, "Zarzalín con Kael a nivel 1")


func _escalado(clave: String, zona: String, ng: int, fijo: String) -> Dictionary:
	var e: Dictionary = C.ENEMIGOS[clave].duplicate(true)
	E.aplicar(e, zona, ng, fijo)
	return {"hp": e["hp"], "atk": e["atk"], "exp": e["exp"], "oro": e["oro"], "nivel_encuentro": e["nivel_encuentro"]}


func _igual(a: Dictionary, b: Dictionary, que: String) -> void:
	print("%s: %s" % [que, a])
	if a != b:
		_fallo("%s: %s y se esperaba %s" % [que, a, b])


# ================================================================= 2. combates de verdad

func _preparar(nivel: int, zona: String, grupo: int, fijo: String) -> void:
	for k in P.CLAVES + ["grupo_combate", "combate_fijo", "tipo_combate", "zona", "desde_mapa", "escena_retorno"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	G.datos()
	for n in G.EN_EL_GRUPO:
		G.datos()[n]["nivel"] = nivel
		G.datos()[n]["pv"] = -1
		G.datos()[n]["pm"] = -1
	Engine.set_meta("zona", zona)
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", grupo)
	if fijo != "":
		Engine.set_meta("combate_fijo", fijo)
	Engine.set_meta("desde_mapa", false)


func _siguiente() -> void:
	if c != null:
		c.queue_free()
		c = null
	caso_i += 1
	Engine.time_scale = 1.0
	if caso_i >= CASOS.size():
		print("FALLOS: %d" % fallos)
		quit(1 if fallos > 0 else 0)
		return
	frames = 0
	f_fin = -1
	avisados = {}
	datos = {}
	match CASOS[caso_i]:
		"base":
			_preparar(1, "llanura", 0, "")
		"medio":
			_preparar(7, "bosque", 0, "")
		"alto":
			_preparar(34, "bosque", 0, "")
		"jefe":
			_preparar(34, "llanura", 11, "pastos_guardian")
	datos["oro"] = I.oro()
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)


func _comprobar_inicio(esperado: Dictionary) -> void:
	for e in c.enemigos:
		var clave: String = e["clave"]
		if not esperado.has(clave):
			_fallo("enemigo inesperado %s" % clave)
			continue
		var x: Dictionary = esperado[clave]
		var hay := {"hp": e["hp"], "hp_max": e["hp_max"], "atk": e["atk"], "exp": e["exp"], "oro": e["oro"],
			"vel": e["vel"], "nivel_encuentro": e.get("nivel_encuentro", -1)}
		print("[%s] al empezar: %s %s" % [CASOS[caso_i], e["nombre"], hay])
		for k in x:
			if str(hay[k]) != str(x[k]):
				_fallo("%s al empezar: %s = %s y debía ser %s" % [e["nombre"], k, hay[k], x[k]])


func _process(_d: float) -> bool:
	if c == null or not is_instance_valid(c) or c.is_queued_for_deletion():
		return false
	frames += 1
	var caso: String = CASOS[caso_i]
	if frames == 3:
		var d: Dictionary = C.ENEMIGOS
		match caso:
			"base":
				_comprobar_inicio({"grimfang": {"hp": d["grimfang"]["hp"], "hp_max": d["grimfang"]["hp"], "atk": d["grimfang"]["atk"],
					"exp": d["grimfang"]["exp"], "oro": d["grimfang"]["oro"], "vel": d["grimfang"]["vel"], "nivel_encuentro": 2}})
				_siguiente()                          # no hace falta jugarlo: es el combate de siempre (prueba_combate_huella)
				return false
			"medio":
				_comprobar_inicio({"grimfang": {"hp": 136, "hp_max": 136, "atk": 17, "exp": 35, "oro": 21, "vel": 13.0, "nivel_encuentro": 7}})
			"alto":
				_comprobar_inicio({"grimfang": {"hp": 145, "hp_max": 145, "atk": 18, "exp": 37, "oro": 22, "vel": 13.0, "nivel_encuentro": 8}})
			"jefe":
				_comprobar_inicio({"guardian_bosque": {"hp": 487, "hp_max": 487, "atk": 19, "exp": 104, "oro": 0, "vel": 9.0, "nivel_encuentro": 4}})
	_invariantes()
	if caso == "alto" and frames == 60:                # el grupo «sube» a mitad: el encuentro sigue igual
		for n in G.EN_EL_GRUPO:
			G.datos()[n]["nivel"] = 50
	if caso == "jefe":
		_empujar_jefe()
	if c.estado == "fin" and f_fin < 0:
		f_fin = frames
		var dan: Dictionary = load("res://combate_recompensas.gd").de_enemigos(c.enemigos)
		datos["dan"] = dan
		datos["vivos_h"] = c.heroes.filter(func(h): return int(h["hp"]) > 0).size()
		for e in c.enemigos:
			if caso in ["alto", "medio"] and int(e.get("nivel_encuentro", -1)) != (8 if caso == "alto" else 7):
				_fallo("%s: el nivel del encuentro cambió a mitad (%s)" % [e["nombre"], e.get("nivel_encuentro")])
			if caso == "jefe" and int(e.get("nivel_encuentro", -1)) != 4:
				_fallo("%s: el nivel del encuentro cambió a mitad (%s)" % [e["nombre"], e.get("nivel_encuentro")])
	if f_fin >= 0 and c.menu.heroe_actual.get("nombre", "") == "Fin":
		_cerrar()
	elif f_fin >= 0 and frames - f_fin > 900:
		_fallo("tras «fin» no sale el menú del final")
		_cerrar()
	elif frames >= LIMITE:
		_fallo("el combate no termina en %d fotogramas (estado «%s»)" % [LIMITE, c.estado])
		_siguiente()
	return false


func _empujar_jefe() -> void:
	var g: Dictionary = {}
	for e in c.enemigos:
		if e["clave"] == "guardian_bosque":
			g = e
	if g.is_empty():
		return
	var paso: int = datos.get("paso", 0)
	if paso == 0 and frames > 40 and c.estado != "accion":
		c._quitar_pv(g, g["hp"] - int(g["hp_max"] * 0.45))    # baja del 50 %: fase 2
		datos["paso"] = 1
	elif paso == 1 and g.get("fase2", false) and not g.get("fase2_pendiente", false) and c.estado != "accion" and frames > 200:
		c._quitar_pv(g, g["hp"])
		c._comprobar_fin()
		datos["paso"] = 2


func _invariantes() -> void:
	var vistos := {}
	for f in c.cola:
		var id: String = "%s/%s" % [f["nombre"], f["hero"]]
		if vistos.has(id):
			_fallo("%s está dos veces en la cola de turnos" % f["nombre"])
		vistos[id] = true
	for f in c.heroes + c.enemigos:
		if float(f["atb"]) < 0.0 or float(f["atb"]) > c.ATB_MAX + 0.001:
			_fallo("la barra ATB de %s se sale (%.2f)" % [f["nombre"], f["atb"]])
		if int(f["hp"]) < 0 or int(f["hp"]) > int(f["hp_max"]):
			_fallo("los PV de %s se salen (%d de %d)" % [f["nombre"], f["hp"], f["hp_max"]])
	if not c.estado in ESTADOS:
		_fallo("estado desconocido «%s»" % c.estado)


func _cerrar() -> void:
	var caso: String = CASOS[caso_i]
	var dan: Dictionary = datos.get("dan", {})
	var ganado: int = I.oro() - int(datos["oro"])
	print("[%s] fin en %d fotogramas: héroes en pie %d, recompensas %s, oro ganado %d" % [caso, frames, datos.get("vivos_h", -1), dan, ganado])
	if int(datos.get("vivos_h", 0)) == 0:
		_fallo("los héroes pierden")
	match caso:
		"medio":                                   # nadie huye (no es zona limpia): las dos recompensas enteras
			if dan != {"exp": 70, "oro": 42}:
				_fallo("recompensas %s y debían ser 70 de experiencia y 42 de oro" % dan)
			if ganado != 42:
				_fallo("el reparto da %d monedas y no 42" % ganado)
		"alto":                                    # en zona limpia pueden huir: solo lo que dan los que no huyeron
			if ganado != int(dan.get("oro", -1)):
				_fallo("el reparto da %d monedas y los enemigos %s" % [ganado, dan])
		"jefe":
			if not Engine.get_meta("combates_ganados", {}).get("pastos_guardian", false):
				_fallo("el combate fijo del Guardián no queda ganado")
			if dan.get("exp", -1) != 104:
				_fallo("el Guardián da %s de experiencia y no 104" % dan.get("exp"))
	_siguiente()
