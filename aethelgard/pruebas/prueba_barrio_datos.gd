extends SceneTree
# V12 (16/11): BARRIO EXPERIMENTAL de Oakhaven, agente C: los DATOS de la vida, la misión «Antes de que se enfríe» y el
# conocimiento (ciudades/oakhaven_barrio.gd, dialogos/oakhaven/barrio/, dialogos/personajes/oakhaven/barrio/). Sin ventana.
#   0. Controles: los comprobadores de texto y de condiciones detectan casos malos a propósito.
#   1. Apagado (fuera del banco) no cambia nada: la misión sale en el registro pero OCULTA (aunque la partida traiga sus
#      claves), las señales y las piezas no tocan la partida, no hay diálogos y la guardia del prólogo sigue en puerta().
#   2. Datos: condiciones bien escritas (error_condicion), anclas del contrato, piezas de fuera a ≥ 2,5 m entre sí,
#      puestos de fuera andables y fuera de umbrales y caminos, ids únicos con el resto de encargos.
#   3. Texto: nada reservado (D-033, D-073 y además niebla, sello, Érebo, tapiz, corona, olvid-, aldea y niño), frases al
#      pasar ≤ 48, globos y avisos ≤ 110, pistas del Diario ≤ 15 palabras; los rumores solo de caravanas, caminos, precios
#      y guardia.
#   4. Conocimiento: SABER coherente («oído» con su fuente, nadie sabe algo falso), cada diálogo dice lo que su vecino
#      sabe, ha oído o cree (con su «si»), y sus señales «bar:<modo>:<af>:<npc>» casan con lo que declara.
#   5. La misión con partidas sintéticas: en orden normal, galga primero, taller primero y medir antes del taller;
#      guardar y cargar (volcar/escribir/leer/restaurar) en CADA paso; el premio (Éter ×2) una sola vez; sin pv_02 o sin
#      el prólogo no empieza; partida antigua (sin el diccionario): oculta; el Diario no adelanta pasos.
#   6. Dialogic: registrar_dialogic() da a conocer los 6 personajes sin tocar project.godot; cada diálogo y cada opción se
#      recorre entero: habla solo su vecino, cada frase con su .dch, ≤ 110 letras, y llegan sus señales.
# Imprime «FALLOS: n».

const B := preload("res://ciudades/oakhaven_barrio.gd")
const T := preload("res://zonas3d/barrio/trazado.gd")
const ARCHIVO := "user://prueba_barrio_datos.save"
const CARPETA := "res://dialogos/oakhaven/barrio/"
const CARPETA_PJ := "res://dialogos/personajes/oakhaven/barrio/"
const MAX_FRASE := 48
const MAX_GLOBO := 110
const MAX_PALABRAS := 15
const MIN_DISTANCIA := 2.5
# Lo reservado (se compara sin tildes y en minúsculas, por SUBCADENA): D-033, D-073 y lo del plan §6.
const PROHIBIDO := ["erebo", "corazon", "recuerd", "record", "memoria", "olvid", "rocio", "cripta", "trampilla", "conclave",
	"crio", "hermano", "diecisiete", "alcantarilla", "niebla", "sello", "tapiz", "corona", "aldea"]
const PROHIBIDO_PALABRA := ["nino", "ninos"]          # (como palabra: «camino» no es «niño»)
const TEMAS_RUMOR := ["caravana", "camino", "peaje", "precio", "guardia", "ronda", "portes", "harina", "hilo"]

var P
var E
var Inv
var D
var fallos := 0
var silencio := false                     # (los controles: sus fallos a propósito no se imprimen)
var re_etiquetas := RegEx.create_from_string("\\[[^\\]]*\\]")


func _initialize() -> void:
	P = load("res://progreso.gd")
	E = load("res://encargos.gd")
	Inv = load("res://inventario.gd")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_correr.call_deferred()


func _ok(cond: bool, t: String) -> void:
	if not cond:
		fallos += 1
		if not silencio:
			print("FALLO: ", t)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _correr() -> void:
	await _frames(3)
	D = root.get_node_or_null("Dialogic")
	_controles()
	_apagado()
	_datos()
	_textos()
	_conocimiento()
	_mision()
	await _dialogic()
	_limpiar()
	for extra in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


func _limpiar() -> void:
	for k in P.CLAVES + ["partida_lista", "pos_3d", "banco_pruebas", "barrio_v12", "prologo_visto"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)


# La partida del banco: dentro de él, el barrio puesto, el prólogo visto y pv_02.
func _encender(con_prologo := true, con_pv02 := true) -> void:
	_limpiar()
	Engine.set_meta("banco_pruebas", true)
	Engine.set_meta("barrio_v12", true)
	Engine.set_meta("prologo_visto", con_prologo)
	if con_pv02:
		P.poner_hito("pv_02")
	Engine.set_meta("inventario", {"objetos": {"Éter": 3}, "oro": 100, "equipables": [], "equipo": {}})


# ================================================================= utilidades de texto

static func _plano(t: String) -> String:
	var r := t.to_lower()
	for par in [["á", "a"], ["é", "e"], ["í", "i"], ["ó", "o"], ["ú", "u"], ["ü", "u"], ["ñ", "n"]]:
		r = r.replace(par[0], par[1])
	return r


func _visible(t: String) -> String:
	return re_etiquetas.sub(t, "", true).strip_edges()


func _palabras(t: String) -> int:
	var n := 0
	for p in t.replace("«", " ").replace("»", " ").split(" ", false):
		if p.strip_edges().lstrip("¿¡").rstrip(".,;:!?…") != "":
			n += 1
	return n


func _revisar(t: String, donde: String, maximo := MAX_GLOBO) -> void:
	var p := _plano(t)
	for x in PROHIBIDO:
		if x in p:
			_ok(false, "texto: «%s» en %s: «%s»" % [x, donde, t])
	for x in PROHIBIDO_PALABRA:
		if RegEx.create_from_string("\\b%s\\b" % x).search(p) != null:
			_ok(false, "texto: «%s» en %s: «%s»" % [x, donde, t])
	_ok(t.length() <= maximo, "texto: %s tiene %d letras (máximo %d): «%s»" % [donde, t.length(), maximo, t])


func _leer(ruta: String) -> String:
	return FileAccess.get_file_as_string(ruta) if FileAccess.file_exists(ruta) else ""


func _archivos(carpeta: String, ext: String) -> Array:
	var r: Array = []
	var d := DirAccess.open(carpeta)
	if d == null:
		return r
	for f in d.get_files():
		if f.get_extension() == ext:
			r.append(carpeta + f)
	return r


# [[quien, texto visible, en_opcion]] de un .dtl («quien» = "" en las opciones).
func _frases_dtl(texto: String) -> Array:
	var r: Array = []
	for l in texto.split("\n"):
		var s := l.strip_edges()
		if s == "" or s.begins_with("#") or s.begins_with("["):
			continue
		if s.begins_with("- "):
			r.append(["", _visible(s.substr(2))])
			continue
		var i := s.find(":")
		r.append([s.substr(0, i).strip_edges() if i > 0 else "?", _visible(s.substr(i + 1))])
	return r


func _senales_dtl(texto: String) -> Array:
	var r: Array = []
	for m in RegEx.create_from_string("\\[signal arg=\"([^\"]+)\"\\]").search_all(texto):
		r.append(m.get_string(1))
	return r


# ================================================================= 0

func _controles() -> void:
	var casos := [
		["Érebo", func(): _revisar("Érebo pasó por aquí.", "control"), true],
		["la niebla", func(): _revisar("Viene la niebla del norte.", "control"), true],
		["«se le olvidó»", func(): _revisar("Se le olvidó la galga.", "control"), true],
		["el sello", func(): _revisar("Sin el sello no vale.", "control"), true],
		["un niño", func(): _revisar("Un niño juega en la calle.", "control"), true],
		["una aldea", func(): _revisar("Vengo de una aldea.", "control"), true],
		["demasiado largo", func(): _revisar("Una frase al pasar que es bastante más larga de lo que cabe.", "control", MAX_FRASE), true],
		["«se dejó la galga»", func(): _revisar("Se dejó la galga en casa.", "control"), false],
		["«camino»", func(): _revisar("El camino del este, embarrado.", "control"), false],
	]
	for c in casos:
		var antes := fallos
		silencio = true
		c[1].call()
		silencio = false
		var detecta := fallos > antes
		fallos = antes
		_ok(detecta == c[2], "0: control «%s»: %s" % [c[0], "no lo detecta" if c[2] else "lo da por malo"])
	for mal in ["estado:inventado", "cond:inventada", "hitos:pv_02", "estado_de:sin_barra", "nada"]:
		_ok(B.error_condicion(mal) != "", "0: error_condicion() da por buena «%s»" % mal)
	for bien in ["estado:enf_galga", "!cond:vivienda_cerrada", "hito:pv_02", "estado_de:oak_barrio/enf_fin", ""]:
		_ok(B.error_condicion(bien) == "", "0: error_condicion() da por mala «%s»" % bien)


# ================================================================= 1

func _apagado() -> void:
	_limpiar()
	Engine.set_meta("prologo_visto", true)
	P.poner_hito("pv_02")
	_ok(not B.activado(), "1: fuera del banco el barrio está activado")
	Engine.set_meta("barrio_v12", true)                       # (aunque alguien deje la meta: sin el banco, no)
	_ok(not B.activado(), "1: con barrio_v12 pero sin el banco, activado")
	var m: Dictionary = E.de(B.MISION)
	_ok(not m.is_empty() and m["lugar"] == B.NOMBRE_LUGAR, "1: la misión no está en el registro de encargos")
	_ok(E.estado(m) == "oculto", "1: apagado, la misión no está oculta")
	for k in B.ESTADOS:                                        # una partida que trajera las claves: sigue oculta
		P.poner_estado(B.NOMBRE, k)
	_ok(E.estado(m) == "oculto", "1: apagado y con todas las claves, la misión sale (%s)" % E.estado(m))
	_limpiar()
	Engine.set_meta("prologo_visto", true)
	P.poner_hito("pv_02")
	for s in ["bar:carro", "bar:galga", "bar:taller", "bar:sabe:pasador_roto:maela", "bar:fin"]:
		_ok(B.aplicar(s) == "", "1: apagado, «%s» devuelve algo" % s)
	_ok(not Engine.get_meta("mazmorras", {}).has(B.NOMBRE), "1: apagado, las señales escriben en la partida")
	var r: Dictionary = B.accion("carro_horno")
	_ok(not r.get("guardar", true) and not Engine.get_meta("mazmorras", {}).has(B.NOMBRE), "1: apagado, el carro cambia algo")
	_ok(B.dialogo_de("maela") == "" and B.frase("maela") != "", "1: apagado, Maela tiene diálogo o no tiene frase")
	_ok(B.puerta("vivienda") == "" and not Engine.get_meta("mazmorras", {}).has(B.NOMBRE),
		"1: apagado, la puerta de la vivienda apunta la llamada")
	Engine.set_meta("prologo_visto", false)
	_ok(B.puerta("horno") == B.TEXTO_PROLOGO, "1: sin el prólogo, la guardia de la puerta no está")
	_limpiar()


# ================================================================= 2

func _ancla_exterior(a: String) -> bool:
	return not a.begins_with("int_")


func _datos() -> void:
	# condiciones
	var conds: Array = []
	for id in B.NPCS:
		for d in B.NPCS[id]["dialogos"]:
			conds.append([d.get("si", ""), "%s/%s" % [id, d["dialogo"]]])
	for pid in B.PIEZAS:
		conds.append([B.PIEZAS[pid].get("si", ""), "pieza " + pid])
	for s in B.SABER:
		conds.append([s.get("si", ""), "SABER %s/%s" % [s["npc"], s["af"]]])
	for m in B.MISIONES:
		conds.append([m["empieza"], m["id"] + " empieza"])
		conds.append([m["fin"], m["id"] + " fin"])
		for p in m["pasos"]:
			conds.append([p["hecho"], m["id"] + "/" + p["id"]])
			conds.append([p.get("saltado_si", ""), m["id"] + "/" + p["id"] + " saltado_si"])
		for p in m["pistas"]:
			conds.append([p["si"], m["id"] + " pista"])
	for c in conds:
		_ok(B.error_condicion(c[0]) == "", "2: %s en %s" % [B.error_condicion(c[0]), c[1]])
		for x in (c[0] if c[0] is Array else [c[0]]):
			var s := str(x).trim_prefix("!")
			if s.begins_with("estado_de:"):
				_ok(s.get_slice("/", 0) == "estado_de:" + B.NOMBRE, "2: %s mira otro lugar (%s)" % [c[1], s])
	# ids únicos en el registro
	var ids := {}
	for e in E.todos():
		_ok(not ids.has(e["m"]["id"]), "2: id de misión repetido «%s»" % e["m"]["id"])
		ids[e["m"]["id"]] = true
	# anclas de las piezas: del contrato (exteriores en el trazado; las de dentro con el prefijo de B)
	var interiores_anclas := ["int_horno_entrada", "int_horno_salida", "int_horno_boca", "int_horno_artesa",
		"int_horno_estante", "int_horno_mesa", "int_horno_maela", "int_taller_entrada", "int_taller_salida", "int_taller_clavo",
		"int_taller_potro", "int_taller_banco_corte", "int_taller_paso_trastienda", "int_taller_damian",
		"int_vivienda_entrada", "int_vivienda_salida", "int_vivienda_repisa", "int_vivienda_mesa", "int_vivienda_rincon",
		"int_vivienda_odila", "int_vivienda_nela"]
	var fuera: Array = []
	for pid in B.PIEZAS:
		var a: String = B.PIEZAS[pid]["ancla"]
		if _ancla_exterior(a):
			_ok(T.ANCLAS.has(a), "2: la pieza %s usa el ancla «%s», que no está en el trazado" % [pid, a])
			fuera.append([pid, T.ancla(a)])
		else:
			_ok(a in interiores_anclas, "2: la pieza %s usa «%s», que no es del contrato de los interiores" % [pid, a])
		for k in ["radio", "boton", "si", "senal", "texto", "texto_sin"]:
			_ok(B.PIEZAS[pid].has(k), "2: a la pieza %s le falta «%s»" % [pid, k])
	for pd in B.PUESTOS:
		var q: Dictionary = B.PUESTOS[pd]
		_ok(q["ancla"] in interiores_anclas, "2: el puesto de %s usa «%s», fuera del contrato" % [pd, q["ancla"]])
		var f: Vector3 = q["fuera"]
		_ok(T.andable(f.x, f.z) and T.en_paso(f.x, f.z) == "", "2: el puesto de fuera de %s no es andable o cae en un umbral" % pd)
		_ok(absf(f.y - T.altura(f.x, f.z)) < 0.05, "2: el puesto de fuera de %s no está a la altura del suelo" % pd)
		for pu in T.PUERTAS:
			_ok(Vector2(f.x - T.PUERTAS[pu]["fuera"].x, f.z - T.PUERTAS[pu]["fuera"].z).length() > 1.6,
				"2: el puesto de fuera de %s tapa la puerta de %s" % [pd, pu])
		fuera.append(["puesto " + pd, f])
	for i in fuera.size():
		for j in range(i + 1, fuera.size()):
			var a: Vector3 = fuera[i][1]
			var b: Vector3 = fuera[j][1]
			_ok(Vector2(a.x - b.x, a.z - b.z).length() >= MIN_DISTANCIA, "2: %s y %s a menos de %.1f m" % [fuera[i][0], fuera[j][0], MIN_DISTANCIA])
	# los vecinos: los seis del contrato, con su .dch
	for id in ["maela", "tobias", "brena", "damian", "odila", "nela"]:
		_ok(B.NPCS.has(id) and B.PERSONAJES.has(id), "2: falta el vecino %s" % id)
	_ok(B.NPCS.size() == 6, "2: hay %d vecinos (el contrato dice 6)" % B.NPCS.size())
	_ok(B.NOMBRE == "oak_barrio" and B.PREFIJO == "bar:", "2: mazmorra o prefijo distintos del contrato")
	_ok(B.PREMIO == {"objetos": {"Éter": 2}}, "2: el premio no es Éter ×2 (%s)" % [B.PREMIO])
	_ok(load("res://tienda.gd").OBJETOS.has("Éter"), "2: «Éter» no está en el catálogo real")
	_ok(B.paso_interno("cortina_horno") and B.paso_interno("alcoba"), "2: la cortina o la alcoba cerradas")
	# archivos: cada diálogo existe; ninguno sobra; cada .dch está en PERSONAJES
	var usados := {}
	for n in B.dialogos():
		usados[n] = true
		_ok(FileAccess.file_exists(B.ruta_dialogo(n)), "2: falta el diálogo %s" % n)
	for ruta in _archivos(CARPETA, "dtl"):
		_ok(usados.has(ruta.get_file().get_basename()), "2: %s no lo usa nadie" % ruta.get_file())
	for ruta in _archivos(CARPETA_PJ, "dch"):
		_ok(B.PERSONAJES.has(ruta.get_file().get_basename()), "2: %s no está en PERSONAJES" % ruta.get_file())
	for id in B.PERSONAJES:
		_ok(FileAccess.file_exists(B.PERSONAJES[id]), "2: falta %s" % B.PERSONAJES[id])


# ================================================================= 3

func _textos() -> void:
	for id in B.NPCS:
		for f in B.NPCS[id]["frases"]:
			_revisar(f, "frase de " + id, MAX_FRASE)
		_revisar(B.NPCS[id]["nombre"], "nombre de " + id)
	for pid in B.PIEZAS:
		for k in ["texto", "texto_sin", "boton"]:
			_revisar(str(B.PIEZAS[pid][k]), "%s de la pieza %s" % [k, pid])
	for k in B.CARRO:
		_revisar(B.CARRO[k], "texto del carro (%s)" % k)
	_revisar(B.LLAMAR, "llamar a la puerta")
	for af in B.AFIRMACIONES:
		_revisar(B.AFIRMACIONES[af]["texto"], "afirmación " + af)
	for m in B.MISIONES:
		for k in ["nombre", "resumen", "pago"]:
			_revisar(m[k], "%s de la misión" % k)
		for p in m["pasos"]:
			_revisar(p["texto"], "paso " + p["id"])
		for p in m["pistas"]:
			_revisar(p["texto"], "pista")
			_ok(_palabras(p["texto"]) <= MAX_PALABRAS, "3: la pista «%s» tiene %d palabras" % [p["texto"], _palabras(p["texto"])])
	for ruta in _archivos(CARPETA, "dtl"):
		for f in _frases_dtl(_leer(ruta)):
			_revisar(f[1], ruta.get_file())
	for ruta in _archivos(CARPETA_PJ, "dch"):
		var t := _leer(ruta)
		_ok(t.contains("PROPUESTA"), "3: %s no está marcado como PROPUESTA" % ruta.get_file())
		_revisar(t.get_slice("&\"description\": \"", 1).get_slice("\"", 0), "descripción de " + ruta.get_file(), 400)
	# los rumores (lo que no es de la misión): solo caravanas, caminos, precios y guardia
	for af in B.AFIRMACIONES:
		if af in ["pasador_roto", "galga_en_casa", "culpa_caballo"]:
			continue
		var p := _plano(B.AFIRMACIONES[af]["texto"])
		var tema := false
		for x in TEMAS_RUMOR:
			tema = tema or x in p
		_ok(tema, "3: el rumor «%s» no es de caravanas, caminos, precios ni guardia" % af)
	# los avisos que da la misión (aplicar y accion) en un recorrido completo
	_encender()
	var avisos: Array = []
	avisos.append(B.puerta("vivienda"))
	for s in ["bar:sabe:pasador_roto:maela", "bar:oido:pasador_roto:tobias", "bar:cree:culpa_caballo:brena", "bar:no_culpa",
			"bar:taller", "bar:clavo", "bar:galga", "bar:medida", "bar:pasador", "bar:reparado", "bar:cesta", "bar:entrega", "bar:fin"]:
		avisos.append(B.aplicar(s))
	_encender()
	for pid in ["carro_horno", "avena", "galga", "carro_horno", "carro_horno"]:
		avisos.append(str(B.accion(pid).get("texto", "")))
	B.aplicar("bar:pasador")
	avisos.append(str(B.accion("carro_horno").get("texto", "")))
	_encender()                                               # (la galga primero: medir empieza la misión)
	for pid in ["galga", "carro_horno", "clavo_galga"]:
		avisos.append(str(B.accion(pid).get("texto", "")))
	for a in avisos:
		if a != "":
			_revisar(a, "aviso")


# ================================================================= 4

# Pone el estado que hace verdad una condición (lo que se pueda: estado: y cond: sencillas).
func _hacer_verdad(c) -> void:
	for x in (c if c is Array else [c]):
		var s := str(x)
		var neg := s.begins_with("!")
		s = s.trim_prefix("!")
		if s.begins_with("estado:"):
			P.poner_estado(B.NOMBRE, s.trim_prefix("estado:"), not neg)


func _conocimiento() -> void:
	var conocidos := {}
	for s in B.SABER:
		_ok(B.NPCS.has(s["npc"]), "4: SABER habla de «%s», que no es un vecino" % s["npc"])
		_ok(B.AFIRMACIONES.has(s["af"]), "4: SABER usa la afirmación «%s», que no existe" % s["af"])
		_ok(s["modo"] in B.MODOS, "4: modo desconocido «%s»" % s["modo"])
		if s["modo"] == "oido":
			var de := str(s.get("de", ""))
			_ok(de != "" and (B.NPCS.has(de) or de in B.FUENTES_OIDO), "4: %s ha oído «%s» sin fuente válida («%s»)" % [s["npc"], s["af"], de])
			_ok(de != s["npc"], "4: %s lo ha oído de sí mismo" % s["npc"])
		if s["modo"] == "sabe" and B.AFIRMACIONES.has(s["af"]):
			_ok(B.AFIRMACIONES[s["af"]]["verdad"], "4: %s SABE algo falso («%s»)" % [s["npc"], s["af"]])
		conocidos[s["af"]] = true
	for af in B.AFIRMACIONES:
		_ok(conocidos.has(af), "4: nadie conoce «%s»" % af)
	_ok(not B.AFIRMACIONES["culpa_caballo"]["verdad"], "4: lo que cree Brena debería ser falso")
	# cada diálogo: lo que declara casa con modo_de en su «si», y sus señales con lo que declara
	for id in B.NPCS:
		for d in B.NPCS[id]["dialogos"]:
			_encender()
			_hacer_verdad(d.get("si", ""))
			var dice: Dictionary = d.get("dice", {})
			for af in dice:
				_ok(B.modo_de(id, af) == dice[af], "4: %s/%s dice «%s» de %s, pero modo_de da «%s»" % [
					id, d["dialogo"], dice[af], af, B.modo_de(id, af)])
			var senales := {}
			for sn in _senales_dtl(_leer(B.ruta_dialogo(d["dialogo"]))):
				var p: PackedStringArray = sn.split(":")
				_ok(sn.begins_with("bar:"), "4: %s: señal sin el prefijo bar: («%s»)" % [d["dialogo"], sn])
				if p.size() == 4 and p[1] in B.MODOS:
					_ok(p[3] == id, "4: %s: la señal %s no es de su vecino (%s)" % [d["dialogo"], sn, id])
					senales[p[2]] = p[1]
			_ok(senales == dice, "4: %s: las señales dicen %s y el diálogo declara %s" % [d["dialogo"], senales, dice])
	# el conocimiento cambia con lo que pasa
	_encender()
	_ok(B.modo_de("brena", "culpa_caballo") == "cree", "4: Brena no cree que fue Avena")
	_ok(B.modo_de("tobias", "pasador_roto") == "oido" and B.fuente_de("tobias", "pasador_roto") == "maela",
		"4: Tobías no lo ha oído de Maela")
	_ok(B.modo_de("damian", "pasador_roto") == "oido" and B.fuente_de("damian", "pasador_roto") == "rumor",
		"4: Damián no lo ha oído por la rampa")
	B.aplicar("bar:no_culpa")
	_ok(B.modo_de("brena", "culpa_caballo") == "", "4: tras ver los cascos, Brena sigue creyéndolo")
	_ok(B.dialogo_de("brena").ends_with("bar_brena_avena.dtl"), "4: Brena no cambia de frase al saber que no fue Avena")
	P.poner_estado(B.NOMBRE, "enf_medida")
	_ok(B.modo_de("damian", "pasador_roto") == "sabe", "4: con la medida, Damián no lo sabe")
	P.poner_estado(B.NOMBRE, "enf_reparado")
	_ok(B.modo_de("tobias", "pasador_roto") == "sabe", "4: con el carro arreglado, Tobías no lo sabe")
	# lo oído o lo creído no avanza la misión; lo sabido de primera mano, sí
	_encender()
	B.aplicar("bar:oido:pasador_roto:tobias")
	B.aplicar("bar:cree:culpa_caballo:brena")
	_ok(not B.cumple("cond:enf_empieza") and P.estado(B.NOMBRE, "j_oido_pasador_roto_tobias"),
		"4: lo oído a Tobías empieza la misión (o no se apunta)")
	B.aplicar("bar:sabe:pasador_roto:maela")
	_ok(B.cumple("cond:enf_empieza") and P.estado(B.NOMBRE, "enf_carro_visto"), "4: lo que sabe Maela no empieza la misión")
	_limpiar()


# ================================================================= 5

func _guardar_y_cargar(donde: String) -> void:
	var d: Dictionary = P.volcar("res://zonas3d/barrio/barrio.tscn")
	_ok(P.escribir(d, ARCHIVO), "5: no se pudo escribir la partida (%s)" % donde)
	var antes: Dictionary = Engine.get_meta("mazmorras", {}).get(B.NOMBRE, {}).duplicate()
	_limpiar()
	var leida = P.leer(ARCHIVO)
	_ok(leida is Dictionary, "5: no se pudo leer la partida (%s)" % donde)
	if leida is Dictionary:
		P.restaurar(leida)
	Engine.set_meta("banco_pruebas", true)
	Engine.set_meta("barrio_v12", true)
	var despues: Dictionary = Engine.get_meta("mazmorras", {}).get(B.NOMBRE, {})
	_ok(despues == antes, "5: tras cargar (%s) el barrio no es el mismo: %s → %s" % [donde, antes, despues])
	for k in despues:
		_ok(despues[k] is bool, "5: «%s» no es bool en la partida" % k)


func _paso(e: Dictionary) -> String:
	return str(E.paso_actual(e).get("id", ""))


# Una señal o una pieza y, después, guardar y cargar.
func _hacer(que: String, donde: String) -> String:
	var t := ""
	if que.begins_with("bar:"):
		t = B.aplicar(que)
	else:
		t = str(B.accion(que).get("texto", ""))
	_guardar_y_cargar(donde)
	return t


func _eter() -> int:
	return Inv.cantidad("Éter")


func _diario_sin_adelantar(e: Dictionary, donde: String) -> void:
	var conocidos: Array = E.pasos_conocidos(e)
	var actual := _paso(e)
	var ids: Array = conocidos.map(func(p): return p["id"])
	var orden: Array = e["m"]["pasos"].map(func(p): return p["id"])
	if actual != "":
		_ok(ids.has(actual), "5: %s: el Diario no enseña el paso actual «%s»" % [donde, actual])
		for i in range(orden.find(actual) + 1, orden.size()):
			if not B.cumple(e["m"]["pasos"][i]["hecho"]):
				_ok(not ids.has(orden[i]), "5: %s: el Diario adelanta «%s»" % [donde, orden[i]])


func _mision() -> void:
	var e: Dictionary = E.de(B.MISION)
	# --- sin pv_02 o sin el prólogo: nada
	_encender(true, false)
	_ok(B.aplicar("bar:sabe:pasador_roto:maela") == "" and not P.estado(B.NOMBRE, "enf_carro_visto"), "5: sin pv_02, Maela cambia algo")
	_ok(not B.accion("carro_horno").get("guardar", true) and E.estado(e) == "oculto", "5: sin pv_02, el carro empieza la misión")
	_ok(B.dialogo_de("maela") == "" and B.puerta("horno") == B.TEXTO_PROLOGO, "5: sin pv_02 hay diálogo o se pasa por la puerta")
	_encender(false, true)
	_ok(B.aplicar("bar:carro") == "" and E.estado(e) == "oculto", "5: sin el prólogo, el carro empieza la misión")
	# --- partida antigua (sin el diccionario del barrio)
	_encender()
	var d: Dictionary = P.volcar("res://zonas3d/barrio/barrio.tscn")
	d["mazmorras"] = {"oakhaven": {"cerradura_abierta": true}}
	P.escribir(d, ARCHIVO)
	_limpiar()
	P.restaurar(P.leer(ARCHIVO))
	Engine.set_meta("banco_pruebas", true)
	Engine.set_meta("barrio_v12", true)
	_ok(E.estado(e) == "oculto" and not B.estado("enf_galga") and B.programa("maela") == "normal",
		"5: partida antigua: la misión no está oculta o hay estado")
	_ok(B.dialogo_de("maela").ends_with("bar_maela_carro.dtl"), "5: partida antigua: Maela no empieza por el carro")

	# --- orden normal, guardando y cargando en cada paso
	_encender()
	var eter0 := _eter()
	_ok(E.estado(e) == "oculto", "5N: antes de empezar, la misión sale")
	_ok(B.dialogo_de("maela").ends_with("bar_maela_carro.dtl"), "5N: Maela no empieza por el carro")
	var t := _hacer("bar:sabe:pasador_roto:maela", "N carro")
	_ok(t.begins_with("Misión: Antes de que se enfríe."), "5N: Maela no avisa de la misión («%s»)" % t)
	_ok(E.estado(e) == "activo" and _paso(e) == "taller", "5N: tras Maela, paso %s (%s)" % [_paso(e), E.estado(e)])
	_ok(B.programa("maela") == "carro_parado" and B.programa("tobias") == "carro_parado", "5N: Maela y Tobías no esperan junto al carro")
	_diario_sin_adelantar(e, "N1")
	t = _hacer("carro_horno", "N examinar el carro")
	_ok(B.estado("j_visto_carro") and not t.begins_with("Misión"), "5N: examinar el carro no se apunta o vuelve a avisar")
	_ok(B.dialogo_de("damian").ends_with("bar_damian_encargo.dtl"), "5N: Damián no recibe el encargo (%s)" % B.dialogo_de("damian"))
	_ok(not B.paso_interno("trastienda"), "5N: la trastienda abierta antes de hablar con Damián")
	_hacer("bar:sabe:galga_en_casa:damian", "N galga en casa")
	_hacer("bar:taller", "N taller")
	_ok(_paso(e) == "galga" and B.paso_interno("trastienda"), "5N: tras el taller, paso %s / trastienda cerrada" % _paso(e))
	_ok(B.dialogo_de("damian").ends_with("bar_damian_galga.dtl"), "5N: Damián no pide la galga")
	_diario_sin_adelantar(e, "N2")
	_ok(B.puerta("vivienda") == B.LLAMAR and B.estado("viv_llamado") and B.puerta("vivienda") == "", "5N: la primera vez no se llama a la puerta")
	t = _hacer("galga", "N galga")
	_ok(B.estado("enf_galga") and _paso(e) == "medir", "5N: coger la galga no avanza (paso %s)" % _paso(e))
	_ok(B.accion("galga")["texto"] == B.PIEZAS["galga"]["texto_sin"], "5N: la galga se puede coger dos veces")
	_ok(B.boton("carro_horno") == "Medir el eje con la galga", "5N: el carro no ofrece medir")
	t = _hacer("carro_horno", "N medir")
	_ok(t.begins_with(B.CARRO["medir"]) and B.estado("enf_medida") and _paso(e) == "pasador", "5N: medir no va («%s», %s)" % [t, _paso(e)])
	_ok(B.dialogo_de("damian").ends_with("bar_damian_pasador.dtl"), "5N: Damián no corta el pasador")
	_ok(B.accion("carro_horno")["texto"] == B.CARRO["medido"], "5N: el carro se mide dos veces")
	_hacer("bar:sabe:pasador_roto:damian", "N Damián lo sabe")
	_hacer("bar:pasador", "N pasador")
	_ok(_paso(e) == "reparar" and B.boton("carro_horno") == "Poner el pasador", "5N: tras el pasador, paso %s" % _paso(e))
	t = _hacer("carro_horno", "N reparar")
	_ok(t.begins_with(B.CARRO["poner"]) and B.estado("enf_reparado") and _paso(e) == "entrega", "5N: reparar no va (%s)" % _paso(e))
	_ok(B.programa("maela") == "reparto" and B.programa("tobias") == "reparto", "5N: sin reparto tras reparar")
	_ok(B.dialogo_de("maela").ends_with("bar_maela_cesta.dtl"), "5N: Maela no da la cesta")
	_ok(not B.dialogo_de("odila").ends_with("bar_odila_entrega.dtl"), "5N: Odila recibe la cesta antes de tenerla")
	_ok(B.aplicar("bar:entrega") == "", "5N: la entrega sin la cesta")
	_hacer("bar:cesta", "N cesta")
	_ok(B.dialogo_de("odila").ends_with("bar_odila_entrega.dtl"), "5N: Odila no recibe la cesta")
	_ok(B.aplicar("bar:fin") == "" and _eter() == eter0, "5N: el premio antes de la entrega")
	_hacer("bar:entrega", "N entrega")
	_ok(_paso(e) == "volver" and B.dialogo_de("maela").ends_with("bar_maela_fin.dtl"), "5N: tras la entrega, paso %s" % _paso(e))
	t = _hacer("bar:fin", "N fin")
	_ok(t.contains("2 Éter") and _eter() == eter0 + 2, "5N: el premio no es Éter ×2 («%s», %d → %d)" % [t, eter0, _eter()])
	_ok(B.aplicar("bar:fin") == "" and _eter() == eter0 + 2, "5N: el premio se da dos veces")
	_ok(E.estado(e) == "hecho", "5N: la misión no está hecha")
	_guardar_y_cargar("N al final")
	_ok(E.estado(e) == "hecho" and _eter() == eter0 + 2, "5N: tras cargar al final, la misión o el premio cambian")
	_ok(B.dialogo_de("maela").ends_with("bar_maela_despues.dtl"), "5N: Maela no dice lo de después")
	for k in B.ESTADOS:
		if k in ["j_visto_clavo", "j_sabe_no_culpa_caballo"]:
			continue
		_ok(B.estado(k), "5N: al final falta «%s»" % k)

	# --- la galga PRIMERO (antes de empezar): se guarda y NO empieza; su pista sale al empezar
	_encender()
	t = _hacer("galga", "G galga")
	_ok(B.estado("enf_galga") and E.estado(e) == "oculto" and not t.contains("Misión"), "5G: la galga suelta empieza la misión")
	_ok(not t.contains("Diario"), "5G: la galga suelta habla del Diario («%s»)" % t)
	_ok(B.dialogo_de("damian").ends_with("bar_damian_galga_traida.dtl"), "5G: Damián no reconoce su galga")
	t = _hacer("carro_horno", "G medir antes del taller")
	_ok(B.estado("enf_medida") and B.estado("enf_carro_visto") and E.estado(e) == "activo" and t.contains("Misión"),
		"5G: medir con la galga no empieza la misión («%s»)" % t)
	_ok(E.pistas_conocidas(e).has("Tienes la galga del carretero."), "5G: la pista de la galga no sale al empezar")
	_ok(_paso(e) == "taller", "5G: tras medir sin taller, paso %s" % _paso(e))
	_ok(B.dialogo_de("damian").ends_with("bar_damian_pasador.dtl"), "5G: Damián no corta con la medida")
	_hacer("bar:pasador", "G pasador")
	_ok(B.estado("enf_taller") and _paso(e) == "reparar", "5G: el pasador no cuenta como taller (paso %s)" % _paso(e))
	_hacer("carro_horno", "G reparar")
	_hacer("bar:cesta", "G cesta")
	_hacer("bar:entrega", "G entrega")
	var eter1 := _eter()
	_hacer("bar:fin", "G fin")
	_ok(E.estado(e) == "hecho" and _eter() == eter1 + 2, "5G: la galga primero no acaba bien")
	_diario_sin_adelantar(e, "G fin")

	# --- el TALLER primero (Damián lo ha oído): empieza la misión
	_encender()
	_ok(B.dialogo_de("damian").ends_with("bar_damian_oido.dtl"), "5T: Damián no lo ha oído (%s)" % B.dialogo_de("damian"))
	_hacer("bar:oido:pasador_roto:damian", "T oído")
	t = _hacer("bar:taller", "T taller")
	_ok(E.estado(e) == "activo" and t.begins_with("Misión"), "5T: el taller primero no empieza la misión («%s»)" % t)
	_ok(_paso(e) == "carro", "5T: tras el taller primero, paso %s" % _paso(e))
	_diario_sin_adelantar(e, "T1")
	_ok(B.aplicar("bar:pasador") == "" and not B.estado("enf_pasador"), "5T: el pasador sin la medida")
	_ok(B.aplicar("bar:medida") == "", "5T: medir sin la galga")
	_hacer("galga", "T galga")
	_hacer("carro_horno", "T medir")
	_ok(_paso(e) == "pasador", "5T: tras medir, paso %s" % _paso(e))
	_ok(B.aplicar("bar:cesta") == "", "5T: la cesta sin el carro arreglado")
	_hacer("bar:pasador", "T pasador")
	_hacer("carro_horno", "T reparar")
	_hacer("bar:cesta", "T cesta")
	_hacer("bar:entrega", "T entrega")
	_hacer("bar:fin", "T fin")
	_ok(E.estado(e) == "hecho", "5T: el taller primero no acaba")

	# --- MEDIR antes del taller con la galga y sin hablar con Maela; y repetir señales sin efecto
	_encender()
	_hacer("galga", "M galga")
	_hacer("carro_horno", "M medir")
	_ok(E.estado(e) == "activo" and B.cumple("cond:enf_galga_o_mas") and B.cumple("cond:enf_medida_o_mas"), "5M: medir primero")
	_ok(not B.cumple("cond:enf_taller_o_mas") and _paso(e) == "taller", "5M: el taller dado por hecho")
	for s in ["bar:medida", "bar:galga", "bar:carro"]:
		var antes: Dictionary = Engine.get_meta("mazmorras", {})[B.NOMBRE].duplicate()
		B.aplicar(s)
		B.aplicar(s)
		var ahora: Dictionary = Engine.get_meta("mazmorras", {})[B.NOMBRE]
		for k in ahora:
			_ok(antes.get(k, false) == ahora[k] or k.begins_with("j_"), "5M: repetir %s cambia «%s»" % [s, k])
	_ok(not B.cumple("cond:enf_galga_saltada"), "5M: la galga saltada sin motivo")
	_limpiar()


# ================================================================= 6

func _dialogic() -> void:
	var util = load("res://addons/dialogic/Core/DialogicResourceUtil.gd")
	if D == null or util == null:
		_ok(false, "6: Dialogic no está cargado")
		return
	var antes: Dictionary = ProjectSettings.get_setting("dialogic/directories/dch_directory", {})
	B.registrar_dialogic()
	B.registrar_dialogic()
	var despues: Dictionary = ProjectSettings.get_setting("dialogic/directories/dch_directory", {})
	_ok(despues.keys() == antes.keys(), "6: registrar_dialogic() cambia los ajustes del proyecto")
	for id in B.PERSONAJES:
		var ch = util.get_character_resource(id)
		_ok(ch != null and ch.resource_path == B.PERSONAJES[id], "6: Dialogic no encuentra a «%s»" % id)
	var vistas := {}
	var recorridos := 0
	for id in B.NPCS:
		for d in B.NPCS[id]["dialogos"]:
			var ruta := B.ruta_dialogo(d["dialogo"])
			var texto := _leer(ruta)
			var opciones := 1
			var j := 1
			while j <= opciones:
				var r: Dictionary = await _recorrer(ruta, j)
				if r["frases"].is_empty():                    # (la primera vez Dialogic prepara su interfaz: otra vez)
					r = await _recorrer(ruta, j)
				recorridos += 1
				opciones = maxi(opciones, int(r["opciones"]))
				var donde := "%s (opción %d)" % [d["dialogo"], j]
				_ok(not r["atasco"], "6: %s se atasca" % donde)
				_ok(r["frases"].size() >= 2 and r["frases"].size() <= 5, "6: %s: %d frases (2-5)" % [donde, r["frases"].size()])
				for f in r["frases"]:
					_ok(f["quien"] == id, "6: %s: habla «%s», no %s" % [donde, f["quien"], id])
					_ok(f["ruta"] == B.PERSONAJES.get(id, ""), "6: %s: la frase no sale de su .dch" % donde)
					_ok(str(f["texto"]).length() <= MAX_GLOBO, "6: %s: frase de %d letras" % [donde, str(f["texto"]).length()])
				for sn in r["senales"]:
					vistas[sn] = true
					_ok(sn in _senales_dtl(texto), "6: %s: señal que no está en el archivo: %s" % [donde, sn])
				j += 1
	for n in B.dialogos():
		for sn in _senales_dtl(_leer(B.ruta_dialogo(n))):
			_ok(vistas.has(sn), "6: la señal %s de %s no llegó nunca" % [sn, n])
	print("OK Dialogic: %d recorridos" % recorridos)


# Recorre un diálogo con Dialogic eligiendo la opción «elegir» en su pregunta. {frases, senales, opciones, atasco}.
func _recorrer(ruta: String, elegir: int) -> Dictionary:
	var r := {"frases": [], "senales": [], "opciones": 0, "atasco": false}
	var al_evento := func(ev):
		if ev is DialogicTextEvent:
			var ch = ev.character
			r["frases"].append({"quien": ch.get_identifier() if ch != null else "", "ruta": ch.resource_path if ch != null else "",
				"texto": _visible(ev.text)})
	var al_senal := func(arg): r["senales"].append(str(arg))
	var pregunta := [false]
	var al_pregunta := func(info: Dictionary):
		pregunta[0] = true
		r["opciones"] = info["choices"].filter(func(c): return c.get("visible", true)).size()
	D.event_handled.connect(al_evento)
	D.signal_event.connect(al_senal)
	D.Choices.question_shown.connect(al_pregunta)
	D.start(ruta)
	var f := 0
	while D.current_timeline != null and f < 900:
		await process_frame
		f += 1
		if pregunta[0]:
			await _frames(6)
			pregunta[0] = false
			D.Choices.select_choice(mini(elegir, maxi(1, int(r["opciones"]))))
			continue
		if f % 4 == 0 and D.current_state in [D.States.IDLE, D.States.REVEALING_TEXT]:
			D.Inputs.handle_input()
	if D.current_timeline != null:
		r["atasco"] = true
		D.end_timeline(true)
	D.event_handled.disconnect(al_evento)
	D.signal_event.disconnect(al_senal)
	D.Choices.question_shown.disconnect(al_pregunta)
	await _frames(3)
	return r
