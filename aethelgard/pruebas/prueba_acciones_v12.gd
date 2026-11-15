extends SceneTree
# Esgrima de Garon y magia blanca de Lya (combate_acciones_v12.gd, pilotos del 13/11/2026). Sin ventana, el combate de
# tres de siempre con «semilla 7», manejado turno a turno (Kael se defiende; Garon y Lya hacen su guion):
#   apagado:  con los dos interruptores apagados no aparece nada (ni Compás, ni filas, ni pestaña).
#   original: los dos encendidos, con los protagonistas de siempre.
#   v2:       los dos encendidos, con los héroes v2 y la animación v12 (los clips c12_* de los pilotos).
# Comprueba, para cada acción: PM insuficientes (no se lanza ni se cobra), Compás insuficiente, objetivo (a quién deja
# elegir), una sola aplicación (se cobra una vez, el efecto se aplica una vez), multigolpe sin multiplicar recursos
# (la suma de los contactos es el daño de una tirada; el Compás sube 1 como mucho), el tope de 3, la espera de la
# Cadencia, la Guardia en Cruz (−20 % una vez), la Custodia (no se apila; se apaga a los 3 turnos), el Manantial (se
# renueva, no se suma) y Aurel (una vez por combate, solo Lya; levanta al caído).
# «fotos=<carpeta>» (con ventana): capturas del menú y de cada acción; «video=<carpeta>»: un JPG cada 2 fotogramas.
# «casos=a,b»: solo esos.
# AZAR (15/11): combate.gd hace randomize() en su _ready (salvo «-- semilla=N»), así que la semilla 7 se pone DESPUÉS de
# root.add_child(c) y se vuelve a tirar el ATB inicial de los enemigos con ella (como prueba_gorthor_v12.gd). Antes se
# sembraba antes de add_child y cada pasada era un combate distinto (hasta el grupo de enemigos: Grimfang ×2, Slime y
# Grimfang, Guardián de piedra y Grimfang…). El grupo se elige ahora con la misma semilla (grupo_al_azar de combate.gd)
# y se fija con «grupo_combate». Cada caso imprime «SEMILLA» y una «TRAZA» por turno de héroe (fotograma del caso,
# quién, pasos del guion y los PV).

const Acc := preload("res://combate_acciones_v12.gd")
const CASOS := [
	{"n": "apagado", "on": false, "v2": false},
	{"n": "original", "on": true, "v2": false},
	{"n": "v2", "on": true, "v2": true},
]
const LIMITE := 12000

var c: Node
var caso := -1
var frames := 0
var fallos := 0
var comprobaciones := 0
var estado_ant := ""
var pendiente: Callable = Callable()          # lo que se comprueba cuando acaba la acción lanzada
var paso := {"Garon": 0, "Lya": 0}
var fin := false
var fotos := ""
var video := ""
var n_video := 0
var fotos_pend: Array = []                   # [fotograma, nombre]
var menu_visto := {}                         # con fotos: el menú se enseña unos fotogramas antes del primer paso
var reanudar: Array = []                     # [fotograma, héroe]
var solo: PackedStringArray = []
var resumen: Array = []


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


func _ok(cond: bool, t: String) -> void:
	comprobaciones += 1
	if not cond:
		fallos += 1
		print("FALLO: [%s] %s" % [CASOS[caso]["n"], t])


func _siguiente() -> void:
	if c != null:
		if CASOS[caso]["on"]:                         # con los v2, las 8 acciones van por sus clips c12_*; sin ellos, ninguna
			var via: int = int(c.get_meta("c12_via_clip", 0))
			_ok(via == (9 if CASOS[caso]["v2"] else 0), "acciones con su clip v12: %d" % via)
		resumen.append("[%s] comprobaciones %d, pasos Garon %d, Lya %d, fotogramas %d" % [CASOS[caso]["n"], comprobaciones,
			paso["Garon"], paso["Lya"], frames])
		c.queue_free()
		c = null
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
	comprobaciones = 0
	estado_ant = ""
	pendiente = Callable()
	paso = {"Garon": 0, "Lya": 0}
	fin = false
	Engine.set_meta("esgrima_v12", k["on"])
	Engine.set_meta("magia_blanca_v12", k["on"])
	Engine.set_meta("heroes_v2", k["v2"])
	Engine.set_meta("combate_anim_v12", k["v2"])
	seed(7)                                           # el grupo de enemigos, al azar pero con la semilla (antes salía
	Engine.set_meta("grupo_combate", load("res://combate.gd").grupo_al_azar(load("res://grupo.gd").activos().size()))
	c = load("res://combate.tscn").instantiate()      # uno distinto en cada pasada: el randomize() de _ready)
	root.add_child(c)                                 # (aquí su _ready hace randomize())
	seed(7)                                           # desde aquí, el azar del combate es fijo
	for e in c.enemigos:
		e["atb"] = randf() * 30.0                     # el ATB inicial, como en combate.gd, ya con la semilla
	print("SEMILLA 7 · %s · %s" % [k["n"], ", ".join(c.enemigos.map(func(e): return e["nombre"]))])


func _process(_d: float) -> bool:
	if c == null:
		return false
	frames += 1
	if video != "" and frames % 2 == 0:
		root.get_viewport().get_texture().get_image().save_jpg(video.path_join("%05d.jpg" % n_video), 0.88)
		n_video += 1
	for fp in fotos_pend.duplicate():
		if frames >= fp[0]:
			_foto(fp[1])
			fotos_pend.erase(fp)
	if frames == 3:
		_preparar()
	if frames % 1500 == 0:
		print("  [%s] f%d estado %s actor %s | %s" % [CASOS[caso]["n"], frames, c.estado, c.actor["nombre"] if c.actor is Dictionary else "-",
			", ".join(c.heroes.map(func(h): return "%s %d/%d atb %d" % [h["nombre"], h["hp"], h["hp_max"], int(h.get("atb", 0))]))])
	if fin or frames > LIMITE:
		if not fin:
			_ok(false, "no acabó el guion en %d fotogramas (Garon paso %d, Lya paso %d)" % [LIMITE, paso["Garon"], paso["Lya"]])
		_siguiente()
		return false
	for r in reanudar.duplicate():
		if frames >= r[0]:
			reanudar.erase(r)
			_turno(r[1])
	var empieza: bool = c.estado == "menu" and estado_ant != "menu"
	estado_ant = c.estado
	if empieza and frames > 3:
		if pendiente.is_valid():
			var p := pendiente
			pendiente = Callable()
			p.call()
		_turno(c.actor)
	if c.has_method("_comprobar_fin") and c.estado in ["victoria", "derrota", "fin"]:
		_ok(false, "el combate acabó antes del guion (estado %s)" % c.estado)
		fin = true
	return false


func _foto(n: String) -> void:
	if fotos != "":
		root.get_viewport().get_texture().get_image().save_png(fotos.path_join("%s_%s.png" % [CASOS[caso]["n"], n]))


func _foto_en(n: String, f: int) -> void:
	if fotos != "":
		fotos_pend.append([frames + f, n])


# Datos de prueba (en memoria): enemigos y héroes aguantan para que el guion quepa en un combate.
func _preparar() -> void:
	for e in c.enemigos:
		e["hp_max"] = int(e["hp_max"]) * 30
		e["hp"] = e["hp_max"]
	for h in c.heroes:
		h["hp_max"] = int(h["hp_max"]) * 4
		h["hp"] = h["hp_max"]
	var k: Dictionary = CASOS[caso]
	var g := _heroe("Garon")
	_ok(g.has("c12_compas") == k["on"], "Compás de Garon %s" % ("presente" if k["on"] else "ausente"))
	_ok((c.capa.get_node_or_null("CompasGaron") != null) == k["on"], "indicador del Compás")
	if k["on"]:
		_ok(Acc.compas(g) == 0, "el Compás empieza a 0")


func _heroe(n: String) -> Dictionary:
	for h in c.heroes:
		if h["nombre"] == n:
			return h
	return {}


func _enemigo() -> Dictionary:                     # el enemigo vivo con más PV
	var r: Dictionary = {}
	for e in c._alcanzables():
		if r.is_empty() or e["hp"] > r["hp"]:
			r = e
	return r


func _turno(a) -> void:
	if not a is Dictionary:
		return
	var k: Dictionary = CASOS[caso]
	var pv := []
	for f in c.heroes + c.enemigos:
		pv.append("%s %d" % [f["nombre"], int(f["hp"])])
	print("TRAZA [%s] f%05d %s (Garon %d, Lya %d) · %s" % [k["n"], frames, a["nombre"], paso["Garon"], paso["Lya"], ", ".join(pv)])
	if not k["on"]:
		_apagado(a)
		return
	var vista: String = "%s_%d" % [a["nombre"], paso.get(a["nombre"], -1)]
	if fotos != "" and k["on"] and vista in ["Garon_0", "Lya_0", "Lya_5"] and not menu_visto.has(vista):
		menu_visto[vista] = true                   # (solo para la captura: el menú abierto, y luego el guion)
		if vista == "Garon_0":
			c._menu_esgrima()
		elif vista == "Lya_0":
			c._menu_magia(Acc.PESTANA_BLANCA)
		else:
			c._invocar()
		_foto_en({"Garon_0": "garon_menu", "Lya_0": "lya_menu", "Lya_5": "lya_invocacion"}[vista], 8)
		reanudar.append([frames + 10, a])
		return
	if a["nombre"] == "Garon" and paso["Garon"] < 6:
		_garon(a)
		paso["Garon"] += 1
	elif a["nombre"] == "Lya" and paso["Lya"] < 7:
		if paso["Lya"] > 0:                          # (PM de sobra para el guion: datos de prueba)
			a["mp_max"] = maxi(int(a["mp_max"]), 90)
			a["mp"] = a["mp_max"]
		_lya(a)
		paso["Lya"] += 1
	else:
		c._defender()
	if c.estado in ["menu", "magia", "objetivo"]:   # el paso no lanzó nada: se dice y se sigue
		_ok(false, "el paso de %s no lanzó ninguna acción (estado %s)" % [a["nombre"], c.estado])
		c._defender()
	if paso["Garon"] >= 6 and paso["Lya"] >= 7 and not pendiente.is_valid():
		fin = true


# ---------------------------------------------------------------- apagado: nada aparece y el menú es el de siempre
func _apagado(a: Dictionary) -> void:
	if a["nombre"] == "Garon":
		_ok(Acc.filas_esgrima(c, a).is_empty(), "apagado: sin filas de esgrima v12")
		var items := [{"texto": "x"}]
		_ok(Acc.con_esgrima(c, items) == items, "apagado: el menú de esgrima, el mismo")
		_ok(Acc.minimo_esgrima(a, 3) == 3, "apagado: el coste mínimo de ESGRIMA, el mismo")
		paso["Garon"] += 1
	elif a["nombre"] == "Lya":
		_ok(Acc.filas_blanca(c, a).is_empty(), "apagado: sin magia blanca")
		_ok(not Acc.pestana_pedida(Acc.PESTANA_BLANCA), "apagado: sin pestaña BLANCA")
		paso["Lya"] += 1
	c._defender()
	if paso["Garon"] >= 1 and paso["Lya"] >= 1:
		fin = true


# ---------------------------------------------------------------- Garon
func _garon(g: Dictionary) -> void:
	var obj := _enemigo()
	match paso["Garon"]:
		0:
			# menú: con la esgrima v12, las tres delante (página de 3 + «Más ›»), y la Cadencia apagada sin Compás
			var filas: Array = Acc.con_esgrima(c, [{"texto": "Juicio"}, {"texto": "Giro"}, {"texto": "Guardia"}])
			_ok(filas.size() == 4 and filas[0]["texto"] == "Punta Gemela" and filas[2]["texto"] == "Cadencia" and filas[3].get("pagina", false),
				"menú de esgrima: 3 nuevas + Más (%s)" % str(filas.map(func(x): return x["texto"])))
			_ok(filas[2]["apagado"], "Cadencia apagada (%s)" % filas[2]["desc"])
			var pm_antes: int = g["mp"]
			g["mp"] = 40                                 # (con PM de sobra, lo que falta es el Compás)
			_ok("Compás" in Acc.motivo_esgrima(c, g, "cadencia"), "Cadencia sin Compás: %s" % Acc.motivo_esgrima(c, g, "cadencia"))
			Acc.elegir_esgrima(c, "cadencia")
			_ok(not c.estado in ["objetivo", "accion"] and g["mp"] == 40 and Acc.compas(g) == 0, "Cadencia sin Compás (con PM): no se lanza ni cobra")
			g["mp"] = pm_antes
			c._menu_esgrima()
			# Compás insuficiente: elegirla no hace nada
			var pm0: int = g["mp"]
			Acc.elegir_esgrima(c, "cadencia")
			_ok(not c.estado in ["objetivo", "accion"] and g["mp"] == pm0 and Acc.compas(g) == 0, "Cadencia sin Compás: no se lanza ni cobra")
			# PM insuficientes: Guardia en Cruz con 0 PM
			g["mp"] = 0
			_ok("PM" in Acc.motivo_esgrima(c, g, "guardia_cruz"), "Guardia en Cruz sin PM: %s" % Acc.motivo_esgrima(c, g, "guardia_cruz"))
			Acc.elegir_esgrima(c, "guardia_cruz")
			_ok(not c.estado in ["objetivo", "accion"], "Guardia en Cruz sin PM: no pide objetivo")
			_ok(Acc.motivo_esgrima(c, g, "punta_gemela") == "", "Punta Gemela con 0 PM: se puede")
			g["mp"] = pm0
			# objetivo: Punta Gemela pide un enemigo alcanzable
			Acc.elegir_esgrima(c, "punta_gemela")
			_ok(c.estado == "objetivo" and c.objetivos_posibles.size() == c._alcanzables().size()
				and c.objetivos_posibles.all(func(x): return not x["hero"]), "Punta Gemela: elige entre los enemigos alcanzables")
			var hp0: int = obj["hp"]
			var ap0: int = int(c.get_meta("c12_aplicaciones_punta_gemela", 0))
			var ct0: int = int(c.get_meta("c12_contactos", 0))
			c._confirmar_objetivo(obj)
			_foto_en("garon_punta_gemela", 40)
			pendiente = func():
				_ok(int(c.get_meta("c12_aplicaciones_punta_gemela", 0)) == ap0 + 1, "Punta Gemela: una aplicación")
				_ok(int(c.get_meta("c12_contactos", 0)) == ct0 + 2, "Punta Gemela: dos contactos (%d)" % (int(c.get_meta("c12_contactos", 0)) - ct0))
				_ok(int(c.get_meta("c12_ultimo_real")) == int(c.get_meta("c12_ultimo_total")),
					"Punta Gemela: la suma de los contactos (%d) es una tirada (%d)" % [c.get_meta("c12_ultimo_real"), c.get_meta("c12_ultimo_total")])
				_ok(hp0 - obj["hp"] >= int(c.get_meta("c12_ultimo_real")), "Punta Gemela: llega al enemigo")
				_ok(g["mp"] == pm0, "Punta Gemela: 0 PM")
				_ok(Acc.compas(g) == 1, "Punta Gemela: +1 Compás, no +2 (%d)" % Acc.compas(g))
		1:
			var pm0: int = g["mp"]
			var cp0 := Acc.compas(g)
			var ap0: int = int(c.get_meta("c12_aplicaciones_guardia_cruz", 0))
			Acc.elegir_esgrima(c, "guardia_cruz")
			_ok(c.estado == "objetivo", "Guardia en Cruz: pide objetivo")
			c._confirmar_objetivo(obj)
			_foto_en("garon_guardia_cruz", 40)
			pendiente = func():
				_ok(int(c.get_meta("c12_aplicaciones_guardia_cruz", 0)) == ap0 + 1, "Guardia en Cruz: una aplicación")
				_ok(g["mp"] == pm0 - Acc.ESGRIMA["guardia_cruz"]["pm"], "Guardia en Cruz: cobra %d PM una vez (%d → %d)" % [Acc.ESGRIMA["guardia_cruz"]["pm"], pm0, g["mp"]])
				_ok(Acc.compas(g) == mini(3, cp0 + 1), "Guardia en Cruz: +1 Compás")
				# (el estado de la guardia se apaga al empezar el turno de Garon: aquí, con otro héroe, sigue o ya se gastó)
		2:
			# la Guardia en Cruz y el Compás de Defender, sobre una copia de Garon (no mueve el combate)
			var copia: Dictionary = g.duplicate()
			copia["c12_cruz"] = true
			copia["defendiendo"] = false
			_ok(Acc.reducir(c, copia, 100) == 80, "Guardia en Cruz: −20 % al primer golpe")
			_ok(Acc.reducir(c, copia, 100) == 100, "Guardia en Cruz: solo al primero")
			copia["defendiendo"] = true
			copia["c12_compas"] = 0
			Acc.reducir(c, copia, 50)
			Acc.reducir(c, copia, 50)
			_ok(Acc.compas(copia) == 1, "Defender: +1 Compás una vez, no por golpe (%d)" % Acc.compas(copia))
			_ok(not g.has("c12_cruz"), "Guardia en Cruz: se apagó al empezar el turno de Garon")
			# el ataque básico da 1 Compás
			var cp0 := Acc.compas(g)
			c._menu_objetivo("atacar", "")
			c._confirmar_objetivo(obj)
			pendiente = func():
				_ok(Acc.compas(g) == mini(3, cp0 + 1), "ataque básico: +1 Compás (%d → %d)" % [cp0, Acc.compas(g)])
		3:
			# tope 3
			g["c12_compas"] = 3
			_ok(Acc.ganar(c, g, 1) == 0 and Acc.compas(g) == 3, "tope del Compás: 3")
			# PM de la Cadencia (Garon tiene pocos: datos de prueba)
			g["mp_max"] = maxi(int(g["mp_max"]), 40)
			g["mp"] = 31
			_ok("PM" in Acc.motivo_esgrima(c, g, "cadencia"), "Cadencia con 31 PM: no (%s)" % Acc.motivo_esgrima(c, g, "cadencia"))
			g["mp"] = 40
			_ok(Acc.motivo_esgrima(c, g, "cadencia") == "", "Cadencia con 3 Compás y 40 PM: sí")
			obj["hp"] = obj["hp_max"]
			var ap0: int = int(c.get_meta("c12_aplicaciones_cadencia", 0))
			var ct0: int = int(c.get_meta("c12_contactos", 0))
			Acc.elegir_esgrima(c, "cadencia")
			c._confirmar_objetivo(obj)
			_foto_en("garon_cadencia_a", 70)
			_foto_en("garon_cadencia_b", 105)
			pendiente = func():
				_ok(int(c.get_meta("c12_aplicaciones_cadencia", 0)) == ap0 + 1, "Cadencia: una aplicación")
				_ok(int(c.get_meta("c12_contactos", 0)) == ct0 + 7, "Cadencia: siete contactos (%d)" % (int(c.get_meta("c12_contactos", 0)) - ct0))
				_ok(int(c.get_meta("c12_ultimo_real")) == int(c.get_meta("c12_ultimo_total")),
					"Cadencia: la suma de los siete (%d) es una tirada (%d)" % [c.get_meta("c12_ultimo_real"), c.get_meta("c12_ultimo_total")])
				_ok(g["mp"] == 40 - Acc.ESGRIMA["cadencia"]["pm"], "Cadencia: cobra %d PM una vez" % Acc.ESGRIMA["cadencia"]["pm"])
				_ok(Acc.compas(g) == 0, "Cadencia: gasta los 3 Compás y no gana por contacto (%d)" % Acc.compas(g))
		4:
			# la espera: 4 turnos de Garon
			g["c12_compas"] = 3
			g["mp"] = 40
			var m := Acc.motivo_esgrima(c, g, "cadencia")
			_ok("turno" in m, "Cadencia en espera: %s" % m)
			c._defender()
		5:
			g["c12_compas"] = 3
			g["mp"] = 40
			_ok("turno" in Acc.motivo_esgrima(c, g, "cadencia"), "Cadencia aún en espera (2.º turno)")
			c._defender()


# ---------------------------------------------------------------- Lya
func _lya(l: Dictionary) -> void:
	var kael := _heroe("Kael")
	var garon := _heroe("Garon")
	var M := Acc.potencia(l)
	match paso["Lya"]:
		0:
			_ok(Acc.filas_blanca(c, garon).is_empty() and Acc.motivo_blanca(c, garon, "aurel") == "Solo Lya.",
				"magia blanca: solo Lya")
			c._menu_magia(Acc.PESTANA_BLANCA)
			_ok(c.magia_nivel_menu.get("Lya", 0) == Acc.PESTANA_BLANCA, "la pestaña BLANCA se abre")
			var textos: Array = Acc.filas_blanca(c, l).map(func(x): return x["texto"])
			_ok(textos == ["Manantial Interior", "Custodia del Pulso", "Restitución Plena"], "BLANCA: %s" % str(textos))
			var pm0: int = l["mp"]
			l["mp"] = 5
			_ok("PM" in Acc.motivo_blanca(c, l, "manantial"), "Manantial sin PM: %s" % Acc.motivo_blanca(c, l, "manantial"))
			Acc.elegir_blanca(c, "manantial")
			_ok(not c.estado in ["objetivo", "accion"] and l["mp"] == 5, "Manantial sin PM: no se lanza ni cobra")
			l["mp"] = maxi(pm0, 60)
			l["mp_max"] = maxi(int(l["mp_max"]), l["mp"])
			var pm1: int = l["mp"]
			Acc.elegir_blanca(c, "manantial")
			_ok(c.estado == "objetivo" and c.objetivos_posibles.all(func(x): return x["hero"] and x["hp"] > 0),
				"Manantial: elige entre los aliados en pie")
			c._confirmar_objetivo(kael)
			_foto_en("lya_manantial", 40)
			pendiente = func():
				_ok(l["mp"] == pm1 - Acc.BLANCA["manantial"]["pm"], "Manantial: cobra una vez")
				_ok(int(kael.get("aliento", 0)) >= 2 and int(kael.get("aliento", 0)) <= 3, "Manantial: 3 turnos (quedan %d)" % int(kael.get("aliento", 0)))
				_ok(is_equal_approx(float(kael.get("aliento_regen", 0.0)), 0.45 * M / float(kael["hp_max"])), "Manantial: 0,45 M")
		1:
			# renovar, no sumar
			var pm1: int = l["mp"]
			kael["aliento"] = 2
			Acc.elegir_blanca(c, "manantial")
			c._confirmar_objetivo(kael)
			pendiente = func():
				_ok(int(kael.get("aliento", 0)) <= 3, "Manantial: se renueva, no se suma (%d)" % int(kael.get("aliento", 0)))
				_ok(l["mp"] == pm1 - Acc.BLANCA["manantial"]["pm"], "Manantial (2.ª): cobra una vez")
		2:
			var pm1: int = l["mp"]
			garon["barrera"] = 0
			Acc.elegir_blanca(c, "custodia")
			_ok(c.estado == "objetivo", "Custodia: pide aliado")
			c._confirmar_objetivo(garon)
			_foto_en("lya_custodia", 40)
			pendiente = func():
				_ok(l["mp"] == pm1 - Acc.BLANCA["custodia"]["pm"], "Custodia: cobra una vez")
				_ok(int(garon.get("barrera", 0)) <= int(1.6 * M) and garon.has("c12_barrera_turnos"),
					"Custodia: barrera de 1,60 M (%d de %d)" % [int(garon.get("barrera", 0)), int(1.6 * M)])
		3:
			# no se apila (queda la mayor) y se apaga a los 3 turnos del protegido (en Kael, con datos de prueba)
			var pm1: int = l["mp"]
			garon["barrera"] = 999
			garon.erase("c12_barrera_turnos")
			Acc.elegir_blanca(c, "custodia")
			c._confirmar_objetivo(garon)
			pendiente = func():
				_ok(int(garon["barrera"]) <= 999 and int(garon["barrera"]) > int(1.6 * M), "Custodia: no se apila, queda la mayor (%d)" % int(garon["barrera"]))
				_ok(l["mp"] == pm1 - Acc.BLANCA["custodia"]["pm"], "Custodia (2.ª): cobra una vez")
			kael["barrera"] = 40                       # (en Kael, con datos de prueba: tres comienzos de turno suyos)
			kael["c12_barrera_turnos"] = 3
			for i in 3:
				_ok(int(kael["barrera"]) == 40, "Custodia: sigue en el turno %d" % i)
				Acc.al_turno_heroe(c, kael)
			_ok(int(kael["barrera"]) == 0 and not kael.has("c12_barrera_turnos"), "Custodia: se apaga al 3.er turno")
		4:
			# Restitución Plena: toda la vida y la corrupción fuera; espera 3 turnos de Lya
			var pm1: int = l["mp"]
			garon["hp"] = maxi(1, int(garon["hp_max"]) / 3)
			garon["hb_corrupcion"] = 2
			var g0: int = garon["hp"]
			_ok(Acc.motivo_blanca(c, l, "restitucion") == "", "Restitución: se puede")
			Acc.elegir_blanca(c, "restitucion")
			_ok(c.estado == "objetivo", "Restitución: pide aliado")
			c._confirmar_objetivo(garon)
			_foto_en("lya_restitucion", 54)
			pendiente = func():
				_ok(l["mp"] == pm1 - Acc.BLANCA["restitucion"]["pm"], "Restitución: cobra una vez")
				_ok(int(c.get_meta("c12_ultima_cura", -1)) == int(garon["hp_max"]) - g0, "Restitución: hasta el máximo (+%d)" % int(c.get_meta("c12_ultima_cura", -1)))
				_ok(not garon.has("hb_corrupcion"), "Restitución: quita la corrupción")
				_ok("turno" in Acc.motivo_blanca(c, l, "restitucion"), "Restitución: en espera (%s)" % Acc.motivo_blanca(c, l, "restitucion"))
		5:
			# Aurel en INVOCACIÓN (debajo de Érebo): Kael cae; vuelve con el 25 %; Garon se cura; una vez por combate
			var pm1: int = l["mp"]
			_ok(Acc.invocacion_abierta(c, l, false), "INVOCACIÓN abierta con Aurel aunque la Armonía no esté llena")
			_ok(not Acc.invocacion_abierta(c, garon, false), "INVOCACIÓN: Aurel no abre la de otro")
			var filas: Array = Acc.filas_invocacion(c, l, [{"texto": "Érebo"}])
			_ok(filas.size() == 2 and filas[0]["texto"] == "Érebo" and filas[1]["texto"] == "Aurel", "INVOCACIÓN: Érebo y Aurel debajo")
			_ok(Acc.filas_invocacion(c, garon, [{"texto": "Érebo"}]).size() == 1, "INVOCACIÓN: solo Lya tiene a Aurel")
			_ok(Acc.filas_blanca(c, l).all(func(x): return x["texto"] != "Aurel"), "Aurel no está en la magia blanca")
			c._invocar()
			c._quitar_pv(kael, kael["hp"])
			_ok(kael["hp"] <= 0, "Kael cae (datos de prueba)")
			garon["hp"] = maxi(1, int(garon["hp_max"]) / 3)
			var g0: int = garon["hp"]
			var rv0: int = int(c.get_meta("c12_revividos", 0))
			Acc.elegir_blanca(c, "aurel")
			_ok(c.estado == "accion", "Aurel: va al grupo, sin elegir objetivo")
			_foto_en("lya_aurel_a", 60)
			_foto_en("lya_aurel_b", 76)
			_foto_en("lya_aurel_c", 100)
			pendiente = func():
				_ok(l["mp"] == pm1 - Acc.BLANCA["aurel"]["pm"], "Aurel: cobra una vez")
				_ok(int(c.get_meta("c12_revividos", 0)) == rv0 + 1, "Aurel: levanta a uno")
				_ok(kael["hp"] > 0, "Aurel: Kael en pie (%d)" % kael["hp"])
				_ok(garon["hp"] > g0 and garon["hp"] - g0 <= int(1.2 * M), "Aurel: cura 1,20 M como mucho (%d)" % (garon["hp"] - g0))
				_ok(Acc.motivo_blanca(c, l, "aurel") != "", "Aurel: una vez por combate")
				_ok(not Acc.invocacion_abierta(c, l, false), "INVOCACIÓN: cerrada otra vez sin Armonía (Aurel ya acudió)")
		6:
			_ok("turno" in Acc.motivo_blanca(c, l, "restitucion"), "Restitución: aún en espera (%s)" % Acc.motivo_blanca(c, l, "restitucion"))
			c._defender()
