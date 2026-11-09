extends SceneTree
# C0 · Huella del combate: la red de seguridad de T-091, T-092 y T-093 (docs/diseno/combate_ampliaciones.md, §6).
#
# Juega, con una semilla fija, nueve combates de 1, 2 y 3 héroes conducidos por un guion (ataques, las 12 magias de
# siempre, defensa, objetos, Esgrima, Embuir, Érebo, huida, derrota y Gorthor con su decisión) y anota su «huella»:
# cada turno, cada texto del cartel, cada cambio de PV y PM con su fotograma, el final, la experiencia, el oro y los
# objetos. Comprueba que la huella es la de pruebas/referencias/huella_combate.txt y, con «dos_pasadas», que dos
# pasadas seguidas en el mismo proceso dan la misma.
#
# Determinismo sin tocar combate.gd: su _ready llama a randomize() y reparte al azar el ATB inicial de los enemigos.
# La prueba siembra el generador global justo después de _ready (add_child lo ejecuta entero) y vuelve a repartir ese
# ATB con la semilla, igual que combate.gd (randf() × 30). Lo demás avanza por fotogramas (--fixed-fps 30).
# Antes del primer combate espera a que el paso de tiempo sea fijo: con --fixed-fps 30, los fotogramas 4 a 6 del
# proceso aún dan pasos de 0,0292, 0,0300 y 0,0325 s (comprobado el 09/11). Si el primer combate los pilla, su ATB y
# sus partículas (que tiran del generador global) cuentan otro tiempo y la huella sale distinta.
# Cada combate tiene su propia semilla (semilla + 1000 × su número): «solo=E3» da la misma huella de E3 que la lista
# entera.
# Infierno (Fuego III) y Cólera del Cielo (Rayo III) van en E9, desde C0 (09/11). Antes se quedaban fuera: sus
# meteoros y rayos de adorno caían en momentos que sorteaba un RandomNumberGenerator nuevo (en Godot 4.7 empieza al azar
# si no se le da semilla), y sus partículas y el rayo 3D tiran del generador global: con Infierno, 3 huellas distintas
# en 6 pasadas. Con C0, combate.gd siembra ese generador con randi() (docs/diseno/combate_enganches.md, §1): en el
# juego siguen al azar y aquí salen de la semilla. E1 a E8 no cambian con C0: ninguno lanza esas dos magias.
#
# Argumentos (después de --): semilla=N · salida=<carpeta> (escribe ahí huella_combate.txt) · dos_pasadas o
# pasadas=N (para buscar lo que no es fijo) · solo=E1,E3 · sin_referencia (para sacar una referencia nueva) ·
# con_enganches (añade una pasada, la última, con pruebas/combate_con_artes.gd: los enganches de M1 y M2 sin tocar
# combate.gd; sin usar las artes, su huella tiene que ser la misma).
# La huella cambia si cambian las reglas, el orden de las tiradas del generador global (también las de los efectos
# visuales, como _temblor) o lo que duran las animaciones. Entonces se revisa la diferencia y, si es la esperada, se
# saca otra referencia (cómo, en la cabecera de pruebas/referencias/huella_combate.txt).
# No toca la partida de verdad: sin «desde_mapa», combate.gd no vuelve al mapa ni guarda; y apunta a su propio archivo.

const REFERENCIA := "res://pruebas/referencias/huella_combate.txt"
const ARCHIVO := "user://prueba_combate_huella.save"
const SEMILLA := 20261109
const MAX_FOTOGRAMAS := 9000                     # 300 s de juego por combate como mucho
const MAX_FIN := 900                             # de «fin» al menú «Fin» (reparto y vuelta): 30 s como mucho

# Guion: por héroe, lo que hace en cada uno de sus turnos (cuando se acaba, ataca al primer enemigo en pie).
#   ["atacar", i] · ["defender"] · ["huir"] · ["magia", "Fuego", nivel, i]: i es el enemigo; en Cura de uno, "herido"
#   ["objeto", "Poción" | "Éter", "yo" | "herido"] · ["esgrima", "Juicio" | "Giro", i] · ["embuir", "Fuego"]
#   ["invocar", i]: llena la Armonía y Lya invoca a Érebo (como «-- invocar»)
# i = índice entre los enemigos en pie, en el orden de combate.gd. Si no se puede (sin PM, sin objeto, sin nadie a
# quien dárselo...), ataca, y la huella lo dice.
const ESCENARIOS := [
	{"id": "E1_kael_solo", "activos": ["Kael"], "grupo": 9, "nivel": 1, "zona": "llanura",
		"guion": {"Kael": [["magia", "Fuego", 1, 0], ["defender"], ["magia", "Rayo", 1, 0], ["objeto", "Éter", "yo"],
			["objeto", "Poción", "yo"]]}},
	{"id": "E2_kael_lya", "activos": ["Kael", "Lya"], "grupo": 2, "nivel": 1, "zona": "llanura",
		"guion": {"Kael": [["atacar", 1], ["defender"], ["atacar", 0]],
			"Lya": [["magia", "Agua", 1, 0], ["magia", "Cura", 1, "herido"], ["magia", "Fuego", 1, 1],
				["magia", "Rayo", 1, 0], ["objeto", "Poción", "herido"]]}},
	{"id": "E3_grupo_de_tres", "activos": ["Kael", "Lya", "Garon"], "grupo": 0, "nivel": 1, "zona": "llanura",
		"guion": {"Kael": [["atacar", 0], ["defender"], ["atacar", 1]],
			"Lya": [["invocar", 0], ["magia", "Cura", 1, "herido"], ["magia", "Agua", 1, 0]],
			"Garon": [["esgrima", "Juicio", 0], ["objeto", "Éter", "yo"], ["esgrima", "Giro", 0]]}},
	{"id": "E4_nivel10_grupales", "activos": ["Kael", "Lya"], "grupo": 4, "nivel": 10, "zona": "desierto",
		"guion": {"Kael": [["magia", "Fuego", 2, 0], ["defender"]],
			"Lya": [["magia", "Fuego", 2, 0], ["magia", "Rayo", 2, 0], ["magia", "Agua", 2, 0], ["objeto", "Éter", "yo"],
				["magia", "Cura", 2, 0]]}},
	{"id": "E5_nivel10_maremoto", "activos": ["Kael", "Lya"], "grupo": 6, "nivel": 10, "zona": "desierto",
		"guion": {"Kael": [["magia", "Fuego", 2, 0], ["magia", "Rayo", 1, 0], ["defender"]],
			"Lya": [["magia", "Agua", 3, 0], ["defender"], ["magia", "Cura", 3, 0], ["objeto", "Éter", "yo"]]}},
	{"id": "E6_huida", "activos": ["Kael", "Lya"], "grupo": 8, "nivel": 1, "zona": "llanura",
		"guion": {"Kael": [["atacar", 0], ["huir"]], "Lya": [["magia", "Agua", 1, 1]]}},
	{"id": "E7_derrota", "activos": ["Kael", "Lya"], "grupo": 0, "nivel": 1, "zona": "llanura",
		"pv": {"Kael": 24, "Lya": 18}, "guion": {}},
	{"id": "E8_gorthor", "activos": ["Kael", "Lya", "Garon"], "grupo": 5, "nivel": 7, "zona": "garganta",
		"tipo": "jefe", "fijo": "garganta_gorthor", "decision": "perdonar",
		"guion": {"Kael": [["magia", "Fuego", 1, 0], ["atacar", 0], ["magia", "Rayo", 2, 0], ["defender"]],
			"Lya": [["magia", "Agua", 1, 0], ["magia", "Cura", 1, "herido"], ["invocar", 0], ["magia", "Cura", 2, 0]],
			"Garon": [["embuir", "Fuego"], ["esgrima", "Juicio", 0], ["esgrima", "Giro", 0]]}},
	# Desde C0: las dos magias de nivel III que faltaban (con sus adornos sacados de la semilla del combate).
	{"id": "E9_nivel10_supremas", "activos": ["Kael", "Lya"], "grupo": 4, "nivel": 10, "zona": "desierto",
		"guion": {"Kael": [["magia", "Fuego", 3, 0], ["defender"]],
			"Lya": [["defender"], ["magia", "Rayo", 3, 0], ["magia", "Cura", 2, 0]]}},
]

var P
var G
var I
var semilla := SEMILLA
var salida := ""
var pasadas := 1                                 # «dos_pasadas» = 2; «pasadas=N» para buscar lo que no es fijo
var con_referencia := true
var solo: Array = []
var con_enganches := false                       # «con_enganches»: combate.gd con los enganches de M1 y M2 (pruebas)

var pendientes: Array = []                       # [{"pasada", "indice"}]
var actual := {}
var pasada := 1
var indice := 0
var c = null
var frames := 0
var f_inicio := 0
var f_fin := -1
var fase := "calentar"                           # calentar · siguiente · combate · cerrar
var espera := 0
var pasos_fijos := 0                             # fotogramas seguidos con el paso de 1/30 s
var lineas := PackedStringArray()
var registro_previo := ""
var estado_previo := ""
var vida_previa := {}
var guion := {}
var decidido := false
var bolsa_antes := {}
var huellas := {}                                # pasada → id → texto
var fallos: Array = []
var deltas_raros := 0


func _initialize() -> void:
	P = load("res://progreso.gd")
	G = load("res://grupo.gd")
	I = load("res://inventario.gd")
	for a in OS.get_cmdline_user_args():
		if a.begins_with("semilla="):
			semilla = int(a.substr(8))
		elif a.begins_with("salida="):
			salida = a.substr(7)
		elif a == "dos_pasadas":
			pasadas = 2
		elif a.begins_with("pasadas="):
			pasadas = maxi(1, int(a.substr(8)))
		elif a == "sin_referencia":
			con_referencia = false
		elif a.begins_with("solo="):
			solo = Array(a.substr(5).split(",", false))
		elif a == "con_enganches":
			con_enganches = true
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	if con_enganches:                             # una pasada más, la última, con los enganches de M1 y M2
		pasadas += 1
	for p in range(1, pasadas + 1):
		huellas[p] = {}
		for i in ESCENARIOS.size():
			var id: String = ESCENARIOS[i]["id"]
			if solo.is_empty() or id in solo or id.get_slice("_", 0) in solo:
				pendientes.append({"pasada": p, "indice": i, "enganches": con_enganches and p == pasadas})
	print("Huella del combate · semilla %d · %d combates%s%s" % [semilla, pendientes.size(),
		(" (%d pasadas)" % pasadas) if pasadas > 1 else "", "; la última, con los enganches de M1 y M2" if con_enganches else ""])


func _process(delta: float) -> bool:
	frames += 1
	var fijo: bool = absf(delta - 1.0 / 30.0) <= 0.0005
	if fase == "combate" and Engine.time_scale == 1.0 and not fijo:
		deltas_raros += 1                         # sin «--fixed-fps 30», la huella no vale
		if deltas_raros <= 5:
			print("  paso raro: %s, fotograma %d del combate, %.6f s" % [actual.get("id", "-"), frames - f_inicio, delta])
	match fase:
		"calentar":                              # hasta que el paso es fijo (15 fotogramas seguidos)
			pasos_fijos = pasos_fijos + 1 if fijo else 0
			if pasos_fijos >= 15:
				print("paso fijo desde el fotograma %d" % (frames - 14))
				fase = "siguiente"
			elif frames > 300:
				fallos.append("en 300 fotogramas el paso no es fijo: la huella pide «--fixed-fps 30»")
				_terminar()
		"siguiente":
			if pendientes.is_empty():
				_terminar()
				return false
			_empezar(pendientes.pop_front())
		"combate":
			_observar()
			if fase == "combate":
				_conducir()
		"cerrar":
			espera -= 1
			if espera <= 0:
				fase = "siguiente"
	return false


# ---------------------------------------------------------------- preparar cada combate

func _limpiar() -> void:
	for k in P.CLAVES:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	for k in ["grupo_combate", "combate_fijo", "tipo_combate", "zona", "desde_mapa", "escena_retorno", "prueba_curar"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)


func _empezar(item: Dictionary) -> void:
	pasada = item["pasada"]
	indice = item["indice"]
	actual = ESCENARIOS[indice]
	_limpiar()
	G.datos()
	Engine.set_meta("grupo_activo", actual["activos"].duplicate())
	if int(actual["nivel"]) != 1:                # como «-- nivel=N» de combate.gd: todos al nivel, con la vida llena
		for n in G.EN_EL_GRUPO:
			G.datos()[n]["nivel"] = int(actual["nivel"])
			G.datos()[n]["pv"] = -1
			G.datos()[n]["pm"] = -1
	for n in actual.get("pv", {}):               # llegan heridos (la vida se guarda entre combates)
		G.estadisticas(n)
		G.datos()[n]["pv"] = int(actual["pv"][n])
	Engine.set_meta("zona", actual["zona"])
	Engine.set_meta("tipo_combate", actual.get("tipo", "normal"))
	Engine.set_meta("grupo_combate", actual["grupo"])
	if actual.has("fijo"):
		Engine.set_meta("combate_fijo", actual["fijo"])
	Engine.time_scale = 1.0
	bolsa_antes = {"oro": I.oro(), "Poción": I.cantidad("Poción"), "Éter": I.cantidad("Éter")}
	guion = actual["guion"].duplicate(true)
	decidido = false
	if item.get("enganches", false):             # combate.tscn es un Node2D con combate.gd: lo mismo, con los enganches
		c = Node2D.new()
		c.name = "combate"
		c.set_script(load("res://pruebas/combate_con_artes.gd"))
	else:
		c = load("res://combate.tscn").instantiate()
	root.add_child(c)                            # aquí se ejecuta su _ready entero (con randomize())
	var s: int = semilla + 1000 * (indice + 1)
	seed(s)                                      # desde aquí, todo lo que tira el generador global es fijo
	for e in c.enemigos:
		e["atb"] = randf() * 30.0                # el ATB inicial, como en combate.gd, pero con la semilla
	lineas = PackedStringArray()
	lineas.append("== %s · grupo %d · nivel %d · zona %s · %s · semilla %d" % [actual["id"], actual["grupo"],
		actual["nivel"], actual["zona"], actual.get("tipo", "normal"), s])
	f_inicio = frames
	f_fin = -1
	_anotar("inicio · " + _estado_texto(true))
	registro_previo = c.registro.text
	estado_previo = c.estado
	vida_previa = _vida()
	var nombres: Array = c.heroes.map(func(h): return h["nombre"])
	if nombres != actual["activos"]:
		fallos.append("%s: en el combate están %s y no %s" % [actual["id"], nombres, actual["activos"]])
	fase = "combate"


# ---------------------------------------------------------------- observar

func _anotar(texto: String) -> void:
	lineas.append(("%05d " % (frames - f_inicio)) + texto.strip_edges(false, true))


func _vida() -> Dictionary:
	var r := {}
	for f in c.heroes + c.enemigos:
		r[f["nombre"]] = [int(f["hp"]), int(f.get("mp", 0))]
	return r


func _estado_texto(con_atb: bool) -> String:
	var partes := PackedStringArray()
	for h in c.heroes:
		partes.append("%s PV %d/%d PM %d/%d ATQ %d VEL %d DEF %d" % [h["nombre"], h["hp"], h["hp_max"], h["mp"],
			h["mp_max"], h["atk"], int(h["vel"]), int(h.get("def", 0))])
	for e in c.enemigos:
		var t := "%s PV %d/%d ATQ %d VEL %d" % [e["nombre"], e["hp"], e["hp_max"], e["atk"], int(e["vel"])]
		if con_atb:
			t += " ATB %.3f" % e["atb"]
		if e.get("huido", false):
			t += " (huido)"
		partes.append(t)
	return " · ".join(partes)


func _observar() -> void:
	if c.estado != estado_previo:
		match c.estado:
			"enemigo":
				_anotar("▷ turno de " + _enemigo_que_actua())
			"fin":
				_anotar("■ fin del combate")
			"decision":
				_anotar("◆ decisión")
		estado_previo = c.estado
	if c.registro.text != registro_previo:
		registro_previo = c.registro.text
		_anotar("· " + (registro_previo if registro_previo != "" else "(cartel vacío)"))
	var v := _vida()
	var cambios := PackedStringArray()
	for n in v:
		var a: Array = vida_previa.get(n, [0, 0])
		var b: Array = v[n]
		if a != b:
			var t: String = n
			if a[0] != b[0]:
				t += " PV %d→%d" % [a[0], b[0]]
			if a[1] != b[1]:
				t += " PM %d→%d" % [a[1], b[1]]
			cambios.append(t)
	if not cambios.is_empty():
		_anotar("  Δ " + " · ".join(cambios))
	vida_previa = v
	if c.estado == "fin" and f_fin < 0:
		f_fin = frames
	if f_fin >= 0 and c.menu.heroe_actual.get("nombre", "") == "Fin":
		_cerrar_escenario()
	elif f_fin >= 0 and frames - f_fin > MAX_FIN:
		fallos.append("%s (pasada %d): tras «fin» no sale el menú del final en %d fotogramas" % [actual["id"], pasada, MAX_FIN])
		_cerrar_escenario()
	elif frames - f_inicio > MAX_FOTOGRAMAS:
		fallos.append("%s (pasada %d): el combate no terminó en %d fotogramas (estado %s)" % [actual["id"], pasada,
			MAX_FOTOGRAMAS, c.estado])
		_cerrar_escenario()


# El enemigo al que le toca: el que salió de la cola con la barra llena (los que esperan siguen en ella).
func _enemigo_que_actua() -> String:
	for e in c.enemigos:
		if e["hp"] > 0 and e["atb"] >= c.ATB_MAX and not e in c.cola:
			return e["nombre"]
	return "un enemigo"


# ---------------------------------------------------------------- conducir

func _conducir() -> void:
	if c.estado == "menu" and c.actor is Dictionary and c.actor.get("hero", false):
		_turno_heroe(c.actor)
	elif c.estado == "decision" and not decidido and c.menu.filas.size() == 2 \
			and c.menu.filas[0]["item"].get("texto", "") == "PERDONAR":
		for e in c.enemigos:
			if e.get("rendido", false):
				decidido = true
				var que: String = actual.get("decision", "perdonar")
				_anotar("◆ Kael decide: " + que)
				if que == "acabar":
					c._acabar(e)
				else:
					c._perdonar(e)
				break


func _turno_heroe(h: Dictionary) -> void:
	var n: String = h["nombre"]
	_anotar("▶ turno de %s (PV %d/%d PM %d/%d)" % [n, h["hp"], h["hp_max"], h["mp"], h["mp_max"]])
	var lista: Array = guion.get(n, [])
	var a: Array = lista.pop_front() if not lista.is_empty() else ["atacar", 0]
	var hecho := _hacer(h, a)
	if hecho == "":
		hecho = "(no puede: %s) %s" % [" ".join(a.map(func(x): return str(x))), _hacer(h, ["atacar", 0])]
	_anotar("  %s: %s" % [n, hecho])


func _vivos() -> Array:
	return c.enemigos.filter(func(e): return e["hp"] > 0)


func _enemigo(i) -> Dictionary:
	var vivos := _vivos()
	return vivos[clampi(int(i), 0, vivos.size() - 1)]


# Aliado al que se le da algo: «yo», «herido» (el de menos PV, o PM, en proporción) o un nombre. Solo los que
# combate.gd acepta: en pie y sin ese valor lleno (si «lleno_vale», también con él lleno, como la Cura).
func _aliado(h: Dictionary, quien: String, campo: String, lleno_vale: bool) -> Variant:
	var validos: Array = c.heroes.filter(func(x): return x["hp"] > 0 and (lleno_vale or x[campo] < x[campo + "_max"]))
	if validos.is_empty():
		return null
	if quien == "yo":
		return h if h in validos else null
	if quien == "herido":
		var mejor: Dictionary = validos[0]
		for x in validos:
			if float(x[campo]) / x[campo + "_max"] < float(mejor[campo]) / mejor[campo + "_max"]:
				mejor = x
		return mejor
	for x in validos:
		if x["nombre"] == quien:
			return x
	return null


# Hace la acción por el mismo camino que el menú (abrir el submenú, elegir y confirmar el objetivo). Devuelve qué hizo,
# o "" si no se puede: entonces no ha tocado nada.
func _hacer(h: Dictionary, a: Array) -> String:
	if _vivos().is_empty():
		return ""
	match a[0]:
		"atacar":
			var obj := _enemigo(a[1])
			c._menu_objetivo("atacar", "")
			c._confirmar_objetivo(obj)
			return "ataca a " + obj["nombre"]
		"defender":
			c._defender()
			return "defiende"
		"huir":
			if Engine.get_meta("tipo_combate", "normal") != "normal":
				return ""
			c._escapar()
			return "huye"
		"magia":
			var fam: String = a[1]
			var nv: int = a[2]
			var sabe := false
			for x in c._hechizos(h):
				if x[0] == fam and x[1] == nv:
					sabe = true
			if not sabe:
				return ""
			var d: Dictionary = c.NIVELES_MAGIA[fam][nv - 1]
			if not c._puede_pagar(d["coste"]):
				return ""
			if c.MAGIAS[fam].get("cura", false) and not d["todos"]:
				var aliado: Variant = _aliado(h, str(a[3]), "hp", true)
				if aliado == null:
					return ""
				c._menu_magia(nv)
				c._elegir_hechizo(fam, nv)            # → elegir aliado
				c._confirmar_objetivo(aliado)
				return "%s → %s" % [d["nombre"], aliado["nombre"]]
			c._menu_magia(nv)
			if d["todos"]:
				c._elegir_hechizo(fam, nv)
				return d["nombre"] + " (a todos)"
			var obj := _enemigo(a[3])
			c._elegir_hechizo(fam, nv)                # → elegir enemigo
			c._confirmar_objetivo(obj)
			return "%s → %s" % [d["nombre"], obj["nombre"]]
		"objeto":
			var nombre: String = a[1]
			if c._cantidad_objeto(nombre) <= 0:
				return ""
			var campo := "hp" if c.OBJETOS_COMBATE[nombre]["que"] == "PV" else "mp"
			var aliado: Variant = _aliado(h, str(a[2]), campo, false)
			if aliado == null:
				return ""
			c._menu_pocion()
			c._menu_objeto_aliado(nombre)
			c._confirmar_objetivo(aliado)
			return "%s → %s" % [nombre, aliado["nombre"]]
		"esgrima":
			if not c._es_garon(h):
				return ""
			var t: Dictionary = c.TECNICAS_GARON[a[1]]
			if not c._puede_pagar(t["coste"]):
				return ""
			c._menu_esgrima()
			if t["todos"]:
				c._elegir_tecnica(a[1])
				return a[1] + " (a todos)"
			var obj := _enemigo(a[2])
			c._elegir_tecnica(a[1])
			c._confirmar_objetivo(obj)
			return "%s → %s" % [a[1], obj["nombre"]]
		"embuir":
			if not c._es_garon(h) or not c._puede_pagar(c.EMBUIR["coste"]):
				return ""
			c._menu_embuir()
			c._embuir(a[1])
			return "Embuir " + a[1]
		"invocar":
			if h["nombre"] != "Lya":
				return ""
			var obj := _enemigo(a[1])
			c.armonia = 1.0                           # como «-- invocar»: la Armonía, llena
			c.menu.poner_armonia(1.0)
			c._invocar()
			c._confirmar_objetivo(obj)
			return "invoca a Érebo sobre %s (Armonía llenada por la prueba)" % obj["nombre"]
	return ""


# ---------------------------------------------------------------- cerrar cada combate

func _cerrar_escenario() -> void:
	var res := "victoria"
	if c.heroes.all(func(x): return x["hp"] <= 0):
		res = "derrota"
	elif not c.enemigos.all(func(e): return e["hp"] <= 0):
		res = "huida"
	lineas.append("fin · %s · fotograma %d (%.1f s de juego)" % [res, f_fin - f_inicio if f_fin >= 0 else -1,
		(f_fin - f_inicio) / 30.0 if f_fin >= 0 else -1.0])
	lineas.append("final · " + _estado_texto(false))
	var grupo := PackedStringArray()
	for n in G.EN_EL_GRUPO:
		var d: Dictionary = G.datos()[n]
		grupo.append("%s%s nivel %d exp %d pv %d pm %d puntos %d" % [n, "" if n in actual["activos"] else " (ausente)",
			d["nivel"], d["exp"], d["pv"], d["pm"], d["puntos"]])
	lineas.append("grupo · " + " · ".join(grupo))
	lineas.append("bolsa · oro %d→%d · Poción %d→%d · Éter %d→%d" % [bolsa_antes["oro"], I.oro(), bolsa_antes["Poción"],
		I.cantidad("Poción"), bolsa_antes["Éter"], I.cantidad("Éter")])
	lineas.append("partida · combates_ganados %s · decisiones %s · Armonía %.2f · velocidad %.2f" % [
		Engine.get_meta("combates_ganados", {}), Engine.get_meta("decisiones", {}), c.armonia, Engine.time_scale])
	var texto := "\n".join(lineas)
	huellas[pasada][actual["id"]] = texto
	print("  %-22s pasada %d · %-8s · %4d líneas · %s" % [actual["id"], pasada, res, lineas.size(),
		texto.sha256_text().substr(0, 16)])
	c.queue_free()
	c = null
	Engine.time_scale = 1.0
	fase = "cerrar"
	espera = 3


# ---------------------------------------------------------------- comparar y terminar

# Bloques de una huella escrita: id → líneas (sin comentarios «#» ni líneas vacías).
func _bloques(texto: String) -> Dictionary:
	var r := {}
	var id := ""
	for l in texto.split("\n"):
		l = l.strip_edges(false, true)
		if l == "" or l.begins_with("#"):
			continue
		if l.begins_with("== "):
			id = l.substr(3).get_slice(" ", 0)
			r[id] = PackedStringArray()
		if id != "":
			r[id].append(l)
	return r


func _comparar(id: String, a: PackedStringArray, b: PackedStringArray, que: String) -> void:
	for i in maxi(a.size(), b.size()):
		var la: String = a[i] if i < a.size() else "(nada)"
		var lb: String = b[i] if i < b.size() else "(nada)"
		if la != lb:
			fallos.append("%s: %s, línea %d: «%s» y «%s»" % [id, que, i + 1, la, lb])
			return


func _texto_huella(pas: int) -> String:
	var bloques := PackedStringArray()
	for e in ESCENARIOS:
		if huellas[pas].has(e["id"]):
			bloques.append(huellas[pas][e["id"]])
	return "\n\n".join(bloques) + "\n"


func _terminar() -> void:
	fase = "terminada"
	if deltas_raros > 0:
		fallos.append("%d fotogramas sin el paso fijo de 1/30 s: la huella pide «--fixed-fps 30»" % deltas_raros)
	if pasadas > 1:
		var antes := fallos.size()
		for pas in range(2, pasadas + 1):
			for id in huellas[1]:
				var a := _bloques(huellas[1][id])
				var b := _bloques(huellas[pas].get(id, ""))
				if not b.has(id):
					fallos.append("%s: falta la pasada %d" % [id, pas])
					continue
				if con_enganches and pas == pasadas:
					_comparar(id, a[id], b[id], "los enganches de M1 y M2 (combate_con_artes.gd) cambian el combate sin usar las artes")
				else:
					_comparar(id, a[id], b[id], "la pasada 1 y la %d difieren (¿algo no determinista?)" % pas)
		if fallos.size() == antes:
			print("OK: las %d pasadas dan la misma huella (%d combates)%s" % [pasadas, huellas[1].size(),
				"; también con los enganches de M1 y M2" if con_enganches else ""])
	if salida != "":
		DirAccess.make_dir_recursive_absolute(salida)
		for pas in range(1, pasadas + 1):
			var nombre := "huella_combate.txt" if pas == 1 else "huella_combate_pasada%d.txt" % pas
			if con_enganches and pas == pasadas:
				nombre = "huella_combate_enganches.txt"
			var f := FileAccess.open(salida.path_join(nombre), FileAccess.WRITE)
			if f == null:
				fallos.append("no se pudo escribir la huella en %s" % salida)
			else:
				f.store_string(_texto_huella(pas))
				f.close()
				print("huella escrita en ", salida.path_join(nombre))
	if con_referencia:
		if not FileAccess.file_exists(REFERENCIA):
			fallos.append("no existe la referencia %s (sácala con «sin_referencia salida=<carpeta>»)" % REFERENCIA)
		else:
			var ref := _bloques(FileAccess.get_file_as_string(REFERENCIA))
			var iguales := 0
			for id in huellas[1]:
				if not ref.has(id):
					fallos.append("%s: no está en la referencia" % id)
					continue
				var antes := fallos.size()
				_comparar(id, _bloques(huellas[1][id])[id], ref[id], "distinta de la referencia (revisar la diferencia)")
				if fallos.size() == antes:
					iguales += 1
			print("referencia: %d de %d combates iguales a %s" % [iguales, huellas[1].size(), REFERENCIA])
	print("huella completa: ", _texto_huella(1).sha256_text())
	_limpiar()
	Engine.remove_meta("archivo_partida_prueba")
	for f in fallos:
		print("FALLO: ", f)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)
