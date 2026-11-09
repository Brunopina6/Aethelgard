extends SceneTree
# Prueba de los datos de Oakhaven (T-089, fase 1): ciudades/oakhaven.gd, sus diálogos (dialogos/oakhaven/) y sus
# personajes (dialogos/personajes/oakhaven/), más la versión de la propuesta (dialogos/oakhaven/propuesta/, fuera del
# juego). Sin ventana; con «-- 3d» para poder probar lo que solo existe con la exploración 3D (la lavanda de los Pastos).
#   0. Controles: antes de nada, los comprobadores de texto, casillas y condiciones detectan casos malos a propósito
#      (si no, la prueba no comprobaría nada).
#   1. Datos: identificadores que no se repiten (ni con los que ya hay: detalles de progreso.gd, personajes y diálogos
#      de Dialogic), condiciones bien escritas, claves de la partida que ya existen, casillas dentro de la ciudad y
#      pisables, lo que se examina a 2,5 casillas o más de lo demás, notas de 15 palabras o menos, recompensas
#      modestas con objetos que existen y el precio de la posada de zona.gd.
#   2. Archivos: cada .dtl y .dch nuevo existe y lo usa el módulo (sin huérfanos); la propuesta, aparte, marcada como
#      propuesta y fuera del juego (.gdignore).
#   3. Texto: ninguna frase revela lo de D-033 (Érebo y los corazones o recuerdos), ni nombra en la versión neutra lo
#      que espera decisión del usuario (D-073); frases de 110 caracteres o menos (dos líneas de ~55 en el móvil).
#   4. Lógica con partidas sintéticas: qué diálogo toca, misiones paso a paso, recompensas una sola vez, cofres, notas,
#      la noche gratis y la escena de la posada según el grupo.
#   5. Dialogic: registrar_dialogic() da a conocer los personajes nuevos sin tocar project.godot; cada diálogo nuevo, y
#      cada rama de sus opciones, se recorre entero: 2-4 frases por vecino (3-5 en la posada), cada frase con su .dch,
#      un solo vecino por diálogo, en la posada solo hablan los presentes, las señales llegan y el retrato provisional
#      lleva su tinte. Lo mismo con los diálogos de la propuesta. Las señales se apuntan, no se aplican.
# Imprime «FALLOS: n» y sale con 1 si hay alguno.

const Oak := preload("res://ciudades/oakhaven.gd")
const TENIDO := preload("res://dialogos/oakhaven/retrato_tenido.gd")
const CARPETA := "res://dialogos/oakhaven/"
const CARPETA_PJ := "res://dialogos/personajes/oakhaven/"
const PROPUESTA := "res://dialogos/oakhaven/propuesta/"
const MAX_CARACTERES := 110          # caja de 880 px y letra de 28 px: dos líneas de unos 55
const MAX_AVISO := 90                # avisos de zona.gd (900 px, letra de 32)
const MIN_DISTANCIA := 2.5           # casillas entre cosas que se examinan (RADIO_NPC 95 px y RADIO_DETALLE 90 px)
const MAX_VALOR_COFRE := 150         # un cofre normal da hasta 120
const MAX_VALOR_MISION := 100
const MAX_FOTOGRAMAS := 900          # por recorrido de un diálogo
# D-033: nada de Érebo, ni de corazones o recuerdos guardados (se compara sin tildes y en minúsculas).
const PROHIBIDO_D033 := ["erebo", "ladron de corazones", "corazones"]
# D-073: en la versión neutra no se nombra nada de lo que espera decisión del usuario.
const PROHIBIDO_NEUTRO := ["olvido", "rocio", "cripta", "trampilla", "conclave", "crio", "hermano", "diecisiete",
	"alcantarilla", "ceniza de los nombres"]
const SENTIDO := ["corazon", "recuerd", "record", "memoria"]
const SOMBRA := ["sombra", "lya"]

var D
var R
var util
var Prop                                  # datos de la propuesta (compilados desde su carpeta)
var fallos: Array = []
var frames := 0
var paso := 0
var cola: Array = []                      # recorridos pendientes: {ruta, id, tipo, opciones, recurso}
var actual = null
var f_inicio := 0
var f_input := 0
var f_pregunta := -1
var pregunta_abierta := false
var elegidas: Array = []                  # opciones elegidas en este recorrido (1, 2…)
var reg := {}
var recorridos := 0
var senales_vistas := {}
var rutas_con_opciones := {}
var tintes_ok := {}
var re_etiquetas := RegEx.create_from_string("\\[[^\\]]*\\]")


func _initialize() -> void:
	D = root.get_node_or_null("Dialogic")
	R = root.get_node_or_null("Recursos")
	util = load("res://addons/dialogic/Core/DialogicResourceUtil.gd")


func _fallo(t: String) -> void:
	fallos.append(t)


# ================================================================= utilidades de texto

static func _plano(t: String) -> String:
	var r := t.to_lower()
	for par in [["á", "a"], ["é", "e"], ["í", "i"], ["ó", "o"], ["ú", "u"], ["ü", "u"]]:
		r = r.replace(par[0], par[1])
	return r


func _visible(t: String) -> String:
	return re_etiquetas.sub(t, "", true).strip_edges()


func _palabras(t: String) -> int:
	var n := 0
	for p in t.replace("«", " ").replace("»", " ").split(" ", false):
		if p.strip_edges(true, true).lstrip("¿¡").rstrip(".,;:!?…") != "":
			n += 1
	return n


# Frases de un .dtl: [[quien, texto visible], ...]; quien = "" en las opciones.
func _frases_dtl(texto: String) -> Array:
	var r: Array = []
	for l in texto.split("\n"):
		var s := l.strip_edges()
		if s == "" or s.begins_with("#") or s.begins_with("[") or s.begins_with("join ") or s.begins_with("leave ") \
				or s.begins_with("update "):
			continue
		if s.begins_with("- "):
			r.append(["", _visible(s.substr(2))])
			continue
		var i := s.find(":")
		if i <= 0:
			r.append(["?", _visible(s)])
			continue
		r.append([s.substr(0, i).get_slice("(", 0).strip_edges(), _visible(s.substr(i + 1))])
	return r


func _senales_dtl(texto: String) -> Array:
	var r: Array = []
	var re := RegEx.create_from_string("\\[signal arg=\"([^\"]+)\"\\]")
	for m in re.search_all(texto):
		r.append(m.get_string(1))
	return r


# D-033 y, si es neutro, D-073. «donde» dice de dónde sale el texto.
func _revisar_texto(t: String, donde: String, neutro: bool) -> void:
	var p := _plano(t)
	for x in PROHIBIDO_D033:
		if x in p:
			_fallo("D-033: «%s» en %s: «%s»" % [x, donde, t])
	if RegEx.create_from_string("guarda\\w*\\s+(los\\s+|sus\\s+)?(corazon|recuerdo)").search(p) != null:
		_fallo("D-033: algo que guarda corazones o recuerdos en %s: «%s»" % [donde, t])
	var con_sombra := false
	for x in SOMBRA:
		con_sombra = con_sombra or RegEx.create_from_string("\\b%s\\b" % x).search(p) != null
	if con_sombra:
		for x in SENTIDO:
			if x in p:
				_fallo("D-033: la sombra o Lya junto a «%s» en %s: «%s»" % [x, donde, t])
	if neutro:
		for x in PROHIBIDO_NEUTRO:
			if RegEx.create_from_string("\\b%s\\b" % x).search(p) != null:
				_fallo("D-073: la versión neutra nombra «%s» en %s: «%s»" % [x, donde, t])


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


# ================================================================= 0. controles: los comprobadores sí detectan fallos

func _controles() -> void:
	var casos := [
		["D-033 con Érebo", func(): _revisar_texto("Érebo guarda los corazones.", "control", false), true],
		["D-033 con la sombra de Lya", func(): _revisar_texto("La sombra de Lya guarda recuerdos.", "control", false), true],
		["D-073 en la versión neutra", func(): _revisar_texto("Olvido te espera en la cripta.", "control", true), true],
		["texto sin nada raro", func(): _revisar_texto("Una frase sin nada raro.", "control", true), false],
		["casilla dentro de la taberna", func(): _casilla_valida("control", Vector2(15, 21)), true],
		["casilla fuera de calles y patios", func(): _casilla_valida("control", Vector2(5, 5)), true],
		["casilla en la plaza", func(): _casilla_valida("control", Oak.PLAZA), false],
	]
	for c in casos:
		var antes := fallos.size()
		c[1].call()
		var detecta := fallos.size() > antes
		fallos.resize(antes)
		if detecta != c[2]:
			_fallo("control «%s»: %s" % [c[0], "no lo detecta" if c[2] else "lo da por malo"])
	for mal in ["hitos:pv_02", "cond:inventada", "decision:pip_oak", "oro:mucho", "modo:4d"]:
		if Oak.error_condicion(mal) == "":
			_fallo("control: error_condicion() da por buena «%s»" % mal)


# ================================================================= 1-3. datos, archivos y texto

func _revisar_datos() -> void:
	var P = load("res://progreso.gd")
	for k in ["hitos", "decisiones", "mazmorras", "cofres_abiertos", "lore_visto", "inventario"]:
		if not k in P.CLAVES:
			_fallo("1: la clave «%s» no está en progreso.gd CLAVES" % k)

	# identificadores
	var vistos := {}
	for lista in [["npc", Oak.NPCS], ["mision", Oak.MISIONES], ["cofre", Oak.COFRES], ["secreto", Oak.SECRETOS],
			["pieza", Oak.PIEZAS], ["nota", Oak.NOTAS], ["lugar", Oak.LUGARES]]:
		for d in lista[1]:
			var id: String = d["id"]
			var clave: String = lista[0] + ":" + id if lista[0] in ["npc", "lugar"] else id
			if vistos.has(clave):
				_fallo("1: id repetido «%s» (%s y %s)" % [id, vistos[clave], lista[0]])
			vistos[clave] = lista[0]
			if lista[0] in ["mision", "cofre", "secreto", "pieza"] and not id.begins_with("oak_"):
				_fallo("1: el id «%s» no lleva el prefijo oak_" % id)
			if lista[0] == "nota" and not id.begins_with("nota_oak_"):
				_fallo("1: la nota «%s» no lleva el prefijo nota_oak_" % id)
	var detalles := {}
	for l in P.DETALLES:
		for d in P.DETALLES[l]:
			detalles[d["id"]] = true
	for n in Oak.NOTAS:
		if detalles.has(n["id"]):
			_fallo("1: la nota «%s» se llama igual que un detalle de progreso.gd" % n["id"])
	for id in Oak.SITIOS_DETALLE:
		if not id in P.detalles_de(Oak.INDICE).map(func(d): return d["id"]):
			_fallo("1: SITIOS_DETALLE mueve «%s», que no es un detalle de Oakhaven" % id)
	var dch: Dictionary = ProjectSettings.get_setting("dialogic/directories/dch_directory", {})
	var dtl: Dictionary = ProjectSettings.get_setting("dialogic/directories/dtl_directory", {})
	for id in Oak.PERSONAJES:
		if dch.has(id) and dch[id] != Oak.PERSONAJES[id]:
			_fallo("1: el personaje «%s» ya existe en Dialogic con otro archivo (%s)" % [id, dch[id]])
		if not ResourceLoader.exists(Oak.PERSONAJES[id]):
			_fallo("2: falta %s" % Oak.PERSONAJES[id])
	var nuevos: Array = Oak.dialogos_nuevos()
	for id in nuevos:
		if dtl.has(id) and dtl[id] != Oak.ruta_dialogo(id):
			_fallo("1: el diálogo «%s» ya existe en Dialogic con otro archivo (%s)" % [id, dtl[id]])
	for id in Oak.DIALOGOS_CANON:
		if not dtl.has(id):
			_fallo("1: «%s» ya no está en Dialogic" % id)

	# archivos: sin huérfanos
	for ruta in _archivos(CARPETA, "dtl"):
		if not ruta.get_file().get_basename() in nuevos:
			_fallo("2: %s no lo usa ningún vecino ni la posada" % ruta)
	for id in nuevos:
		if not FileAccess.file_exists(Oak.ruta_dialogo(id)):
			_fallo("2: falta el diálogo %s" % Oak.ruta_dialogo(id))
	for ruta in _archivos(CARPETA_PJ, "dch"):
		if not ruta.get_file().get_basename() in Oak.PERSONAJES:
			_fallo("2: %s no está en PERSONAJES" % ruta)

	# condiciones
	var conds: Array = []
	for n in Oak.NPCS:
		for d in n["dialogos"]:
			conds.append([d.get("si", ""), "%s/%s" % [n["id"], d["dialogo"]]])
	for m in Oak.MISIONES:
		conds.append([m["empieza"], m["id"]])
		conds.append([m["fin"], m["id"]])
		for p in m["pasos"]:
			conds.append([p["hecho"], "%s/%s" % [m["id"], p["id"]]])
	for c in Oak.COFRES:
		conds.append([c.get("si", ""), c["id"]])
	for p in Oak.PIEZAS:
		conds.append([p.get("si", ""), p["id"]])
	for s in Oak.SECRETOS:
		conds.append([s.get("estado", ""), s["id"]])
	for c in conds:
		var e: String = Oak.error_condicion(c[0])
		if e != "":
			_fallo("1: %s en %s" % [e, c[1]])

	# casillas: dentro, pisables y separadas
	var puntos: Array = []                         # [nombre, casilla] de lo que se examina
	for n in Oak.NPCS:
		puntos.append(["vecino " + n["id"], n["casilla"]])
	for c in Oak.COFRES:
		puntos.append(["cofre " + c["id"], c["casilla"]])
	for n in Oak.NOTAS:
		if n.has("casilla"):
			puntos.append(["nota " + n["id"], n["casilla"]])
		elif Oak.cofre(n.get("cofre", "")).is_empty():
			_fallo("1: la nota %s no tiene casilla ni cofre" % n["id"])
	for p in Oak.PIEZAS:
		puntos.append(["pieza " + p["id"], p["casilla"]])
		if p.has("lleva_a"):
			_casilla_valida("pieza %s (a dónde lleva)" % p["id"], p["lleva_a"])
	for id in Oak.SITIOS_DETALLE:
		puntos.append(["detalle " + id, Oak.SITIOS_DETALLE[id]])
	for pt in puntos:
		_casilla_valida(pt[0], pt[1])
	for s in Oak.SECRETOS:
		_casilla_valida("secreto " + s["id"], s["casilla"])
	_casilla_valida("INICIO", Oak.INICIO)
	_casilla_valida("PLAZA", Oak.PLAZA)
	for i in puntos.size():
		for j in range(i + 1, puntos.size()):
			var dist: float = (puntos[i][1] as Vector2).distance_to(puntos[j][1])
			if dist < MIN_DISTANCIA:
				_fallo("1: %s y %s, a %.1f casillas (mínimo %.1f): sus botones se pisan" % [puntos[i][0], puntos[j][0], dist, MIN_DISTANCIA])

	# notas
	for n in Oak.NOTAS:
		if _palabras(n["texto"]) > 15:
			_fallo("1: la nota %s tiene %d palabras (máximo 15)" % [n["id"], _palabras(n["texto"])])
	for c in Oak.COFRES:
		if c.has("nota") and Oak.nota(c["nota"]).is_empty():
			_fallo("1: el cofre %s apunta a una nota que no existe (%s)" % [c["id"], c["nota"]])

	# recompensas
	var precios: Dictionary = load("res://tienda.gd").get_script_constant_map()["OBJETOS"]
	var posada: int = load("res://zona.gd").get_script_constant_map()["PRECIO_POSADA"]
	if Oak.PRECIO_POSADA != posada:
		_fallo("1: PRECIO_POSADA %d no coincide con el de zona.gd (%d)" % [Oak.PRECIO_POSADA, posada])
	if ("treinta monedas" in _leer(Oak.ruta_dialogo("oak_posadera"))) != (Oak.PRECIO_POSADA == 30):
		_fallo("1: la posadera dice un precio que no es el de la posada")
	for c in Oak.COFRES:
		var v := _valor(c["premio"], precios, posada)
		if v <= 0 or v > MAX_VALOR_COFRE:
			_fallo("1: el cofre %s vale %d (de 1 a %d)" % [c["id"], v, MAX_VALOR_COFRE])
	for m in Oak.MISIONES:
		var v := _valor(m["recompensa"], precios, posada)
		if v > MAX_VALOR_MISION:
			_fallo("1: la misión %s da %d (máximo %d)" % [m["id"], v, MAX_VALOR_MISION])

	# frases de respaldo (sin Dialogic) que salen de sus diálogos
	for n in Oak.NPCS:
		var todo := ""
		for d in n["dialogos"]:
			for f in _frases_dtl(_leer(Oak.ruta_dialogo(d["dialogo"]))):
				todo += f[1] + "\n"
		for f in n["frases"]:
			if not f in todo:
				_fallo("1: la frase de respaldo de %s no está en sus diálogos: «%s»" % [n["id"], f])

	# señales: las que se usan, las conoce el módulo, y las que conoce, se usan
	var usadas := {}
	for id in nuevos:
		for s in _senales_dtl(_leer(Oak.ruta_dialogo(id))):
			usadas[s] = true
	for p in Oak.PIEZAS:
		if p["senal"] != "":
			usadas[p["senal"]] = true
	usadas[Oak.LAVANDA["senal"]] = true
	for s in usadas:
		if not s in Oak.SENALES:
			_fallo("1: la señal «%s» no la entiende aplicar_senal()" % s)
	for s in Oak.SENALES:
		if not usadas.has(s) and s != "oak:vista_raices":       # (esa la da la ciudad al llegar a las raíces)
			_fallo("1: nadie envía la señal «%s»" % s)

	# texto visible: D-033, D-073 y longitud
	for id in nuevos:
		for f in _frases_dtl(_leer(Oak.ruta_dialogo(id))):
			_revisar_texto(f[1], id, true)
			if f[1].length() > MAX_CARACTERES:
				_fallo("3: %s: frase de %d caracteres (máximo %d): «%s»" % [id, f[1].length(), MAX_CARACTERES, f[1]])
			if f[0] == "?":
				_fallo("3: %s: frase sin personaje: «%s»" % [id, f[1]])
	for t in _textos_de_datos():
		_revisar_texto(t[1], t[0], true)
		if t[1].length() > (MAX_AVISO if t[2] else MAX_CARACTERES):
			_fallo("3: %s: %d caracteres (máximo %d): «%s»" % [t[0], t[1].length(), MAX_AVISO if t[2] else MAX_CARACTERES, t[1]])
	for id in Oak.PERSONAJES:
		var ch = load(Oak.PERSONAJES[id])
		_revisar_texto(ch.display_name, "nombre de " + id, true)
		_revisar_texto(ch.description, "descripción de " + id, false)


# Lo que ve el jugador en los datos: [dónde, texto, es un aviso de zona.gd].
func _textos_de_datos() -> Array:
	var r: Array = []
	for n in Oak.NPCS:
		r.append(["nombre de " + n["id"], n["nombre"], false])
		for f in n["frases"]:
			r.append(["frase de " + n["id"], f, false])
	for m in Oak.MISIONES:
		for k in ["nombre", "resumen", "pago"]:
			r.append(["%s de %s" % [k, m["id"]], m[k], false])
		for p in m["pasos"]:
			r.append(["paso %s/%s" % [m["id"], p["id"]], p["texto"], false])
	for n in Oak.NOTAS:
		r.append(["nota " + n["id"], n["texto"], true])
	for p in Oak.PIEZAS:
		for k in ["texto", "texto_sin"]:
			if p[k] != "":
				r.append(["%s de %s" % [k, p["id"]], p[k], true])
	for c in Oak.COFRES:
		if c.has("bloqueado"):
			r.append(["bloqueado de " + c["id"], c["bloqueado"], true])
	r.append(["LAVANDA", Oak.LAVANDA["texto"], true])
	r.append(["TEXTO_ARBOL", Oak.TEXTO_ARBOL, true])
	return r


func _casilla_valida(que: String, c: Vector2) -> void:
	if c.x < 1 or c.y < 1 or c.x >= Oak.TAM.x - 1 or c.y >= Oak.TAM.y - 1:
		_fallo("1: %s en %s: fuera de la ciudad (o en la muralla)" % [que, c])
		return
	var pisable := false
	for l in Oak.LUGARES:
		var r: Rect2 = l["rect"]
		if r.has_point(c):
			if l["pisable"]:
				pisable = true
			else:
				_fallo("1: %s en %s: dentro de %s, que no se pisa" % [que, c, l["nombre"]])
				return
	if not pisable:
		_fallo("1: %s en %s: fuera de las calles y patios de LUGARES" % [que, c])


func _valor(premio: Dictionary, precios: Dictionary, posada: int) -> int:
	var v: int = premio.get("oro", 0)
	if premio.get("noche_gratis", false):
		v += posada
	var objetos: Dictionary = premio.get("objetos", {})
	for o in objetos:
		if not precios.has(o):
			_fallo("1: el objeto «%s» no existe en la tienda (tienda.gd)" % o)
			continue
		v += int(precios[o]) * int(objetos[o])
	return v


# ================================================================= 4. lógica con partidas sintéticas

func _partida(hitos := {}, grupo := ["Kael"], oro := 150) -> void:
	Engine.set_meta("hitos", hitos.duplicate())
	Engine.set_meta("mazmorras", {})
	Engine.set_meta("decisiones", {})
	Engine.set_meta("cofres_abiertos", {})
	Engine.set_meta("lore_visto", {})
	var inv: Dictionary = load("res://inventario.gd").INICIAL.duplicate(true)
	inv["oro"] = oro
	Engine.set_meta("inventario", inv)
	if grupo.is_empty():
		Engine.remove_meta("grupo_activo")
	else:
		Engine.set_meta("grupo_activo", grupo.duplicate())


func _espera(que: String, real: Variant, esperado: Variant) -> void:
	if real != esperado:
		_fallo("4: %s: %s (se esperaba %s)" % [que, real, esperado])


func _dlg(id: String) -> String:
	return Oak.ruta_dialogo(id)


func _revisar_logica() -> void:
	var Inv = load("res://inventario.gd")
	var P = load("res://progreso.gd")
	if not load("res://modo3d.gd").activo():
		_fallo("4: esta prueba se lanza con «-- 3d» (la lavanda solo existe con la exploración 3D)")
		return

	# cada vecino tiene diálogo en varias partidas, y existe
	for estado in [[{}, ["Kael"]], [{"pv_02": true, "pv_03": true}, ["Kael", "Lya"]], [{"pv_02": true}, []]]:
		_partida(estado[0], estado[1])
		for n in Oak.NPCS:
			for v in 3:
				var r := Oak.dialogo_de(n["id"], v)
				if r == "" or not ResourceLoader.exists(r):
					_fallo("4: %s no tiene diálogo (vez %d, hitos %s): «%s»" % [n["id"], v, estado[0], r])

	# Aldric: el guiño, solo cuando Kael ya ha salido (PV-02 en 3D)
	_partida()
	_espera("Aldric antes de PV-02, 2.ª vez", Oak.dialogo_de("aldric", 1), _dlg("npc_aldric"))
	_partida({"pv_02": true})
	_espera("Aldric tras PV-02, 2.ª vez", Oak.dialogo_de("aldric", 1), _dlg("oak_aldric_salida"))

	# Selene: lo de Lya, solo con Lya en el grupo
	_partida({}, ["Kael"])
	_espera("Selene sin Lya, 2.ª vez", Oak.dialogo_de("selene", 1), _dlg("npc_selene"))
	_partida({"pv_03": true}, ["Kael", "Lya"])
	_espera("Selene con Lya, 2.ª vez", Oak.dialogo_de("selene", 1), _dlg("oak_selene_lya"))

	# Pip: el secreto por una moneda
	_partida({}, ["Kael"], 0)
	_espera("Pip sin monedas, 2.ª vez", Oak.dialogo_de("pip", 1), _dlg("oak_pip_sin_monedas"))
	_espera("pagar a Pip sin monedas", Oak.aplicar_senal("oak:pip_pagar"), "")
	_espera("Pip cobra sin monedas", Oak.cumple("decision:pip_oak=pagado"), false)
	_partida({}, ["Kael"], 5)
	_espera("Pip, 1.ª vez", Oak.dialogo_de("pip", 0), _dlg("npc_pip"))
	_espera("Pip, 2.ª vez", Oak.dialogo_de("pip", 1), _dlg("oak_pip_secreto"))
	_espera("pagar a Pip", Oak.aplicar_senal("oak:pip_pagar"), "Le das una moneda a Pip.")
	_espera("pagar a Pip otra vez", Oak.aplicar_senal("oak:pip_pagar"), "")
	_espera("monedas tras pagar a Pip (dos veces)", Inv.oro(), 4)
	_espera("Pip tras pagar", Oak.dialogo_de("pip", 0), _dlg("oak_pip_despues"))
	_espera("Pip tras pagar, 2.ª vez", Oak.dialogo_de("pip", 1), _dlg("oak_pip_despues"))
	_espera("misión de Pip", Oak.estado_mision("oak_secreto_pip"), "hecha")

	# Tres favores para el Cuervo
	_partida()
	_espera("posadera, 1.ª vez", Oak.dialogo_de("posadera", 0), _dlg("oak_posadera"))
	_espera("posadera, 2.ª vez", Oak.dialogo_de("posadera", 1), _dlg("oak_posadera_favores"))
	_espera("favor antes de aceptar", Oak.aplicar_senal("oak:favor_flores"), "")
	_espera("favores hechos antes de empezar", Oak.aplicar_senal("oak:favores_hechos"), "")
	_espera("misión de los favores sin empezar", Oak.estado_mision("oak_favores"), "sin_empezar")
	_espera("aceptar los favores", Oak.aplicar_senal("oak:favores_aceptados"), "Misión: Tres favores para el Cuervo.")
	_espera("aceptar los favores otra vez", Oak.aplicar_senal("oak:favores_aceptados"), "")
	_espera("misión de los favores", Oak.estado_mision("oak_favores"), "en_curso")
	_espera("posadera con los favores a medias", Oak.dialogo_de("posadera", 0), _dlg("oak_posadera_favores_pendientes"))
	_espera("Pip con el cucharón", Oak.dialogo_de("pip", 0), _dlg("oak_pip_cucharon"))
	_espera("Rosa con las flores", Oak.dialogo_de("rosa", 0), _dlg("oak_rosa_flores"))
	_espera("el barril", Oak.aplicar_senal("oak:favor_barril"), "Favor hecho (1 de 3).")
	_espera("el barril otra vez", Oak.aplicar_senal("oak:favor_barril"), "")
	_espera("las flores", Oak.aplicar_senal("oak:favor_flores"), "Favor hecho (2 de 3).")
	_espera("favores hechos con dos", Oak.aplicar_senal("oak:favores_hechos"), "")
	_espera("el cucharón", Oak.aplicar_senal("oak:favor_cucharon"), "Favor hecho (3 de 3).")
	_espera("Pip tras devolver el cucharón", Oak.dialogo_de("pip", 0), _dlg("npc_pip"))
	_espera("posadera con los tres favores", Oak.dialogo_de("posadera", 3), _dlg("oak_posadera_favores_fin"))
	var pociones: int = Inv.cantidad("Poción")
	_espera("favores hechos", Oak.aplicar_senal("oak:favores_hechos"),
		"Tres favores para el Cuervo: una noche gratis en el Cuervo y 2 Pociones.")
	_espera("favores hechos otra vez", Oak.aplicar_senal("oak:favores_hechos"), "")
	_espera("Pociones de los favores (una sola vez)", Inv.cantidad("Poción"), pociones + 2)
	_espera("misión de los favores al acabar", Oak.estado_mision("oak_favores"), "hecha")
	_espera("posadera al acabar, 2.ª vez", Oak.dialogo_de("posadera", 1), _dlg("oak_posadera_niebla"))
	_espera("noche gratis", Oak.usar_noche_gratis(), true)
	_espera("noche gratis otra vez", Oak.usar_noche_gratis(), false)
	for p in Oak.pasos_mision("oak_favores"):
		if not p["hecho"]:
			_fallo("4: el paso %s de los favores no sale hecho" % p["id"])

	# Los faroles de la ronda
	_partida()
	_espera("Bastián, 1.ª vez", Oak.dialogo_de("bastian", 0), _dlg("oak_bastian"))
	_espera("Bastián, 2.ª vez", Oak.dialogo_de("bastian", 1), _dlg("oak_bastian_ronda"))
	_espera("farol sin la misión", Oak.aplicar_senal("oak:farol_1"), "")
	_espera("aceptar los faroles", Oak.aplicar_senal("oak:faroles_aceptados"), "Misión: Los faroles de la ronda.")
	_espera("Bastián esperando", Oak.dialogo_de("bastian", 0), _dlg("oak_bastian_ronda_pendiente"))
	_espera("primer farol", Oak.aplicar_senal("oak:farol_1"), "Farol encendido (1 de 3).")
	_espera("primer farol otra vez", Oak.aplicar_senal("oak:farol_1"), "")
	_espera("faroles hechos con uno", Oak.aplicar_senal("oak:faroles_hechos"), "")
	Oak.aplicar_senal("oak:farol_2")
	_espera("tercer farol", Oak.aplicar_senal("oak:farol_3"), "Farol encendido (3 de 3).")
	_espera("Bastián con los tres", Oak.dialogo_de("bastian", 2), _dlg("oak_bastian_ronda_fin"))
	_espera("faroles hechos", Oak.aplicar_senal("oak:faroles_hechos"), "Misión cumplida: Los faroles de la ronda.")
	_espera("Bastián contento", Oak.dialogo_de("bastian", 1), _dlg("oak_bastian_contento"))
	Oak.aplicar_senal("oak:torre")
	_espera("misión de los faroles", Oak.estado_mision("oak_faroles"), "hecha")

	# Lavanda para el Árbol (solo con la exploración 3D y tras llegar a los Pastos)
	_partida()
	_espera("Rosa antes de los Pastos, 2.ª vez", Oak.dialogo_de("rosa", 1), _dlg("npc_rosa"))
	_partida({"pv_02": true})
	_espera("lavanda sin pedirla", Oak.aplicar_senal("oak:lavanda_cogida"), "")
	_espera("Rosa tras los Pastos, 2.ª vez", Oak.dialogo_de("rosa", 1), _dlg("oak_rosa_lavanda"))
	_espera("pedir la lavanda", Oak.aplicar_senal("oak:lavanda_pedida"), "Misión: Lavanda para el Árbol.")
	_espera("lavanda disponible", Oak.lavanda_disponible(), true)
	_espera("Rosa sin lavanda aún, 2.ª vez", Oak.dialogo_de("rosa", 1), _dlg("npc_rosa"))
	_espera("entregar sin lavanda", Oak.aplicar_senal("oak:lavanda_entregada"), "")
	_espera("coger la lavanda", Oak.aplicar_senal("oak:lavanda_cogida"), Oak.LAVANDA["texto"])
	_espera("lavanda disponible tras cogerla", Oak.lavanda_disponible(), false)
	_espera("Rosa con la lavanda", Oak.dialogo_de("rosa", 0), _dlg("oak_rosa_lavanda_entrega"))
	var pociones2: int = Inv.cantidad("Poción")
	_espera("entregar la lavanda", Oak.aplicar_senal("oak:lavanda_entregada"), "Lavanda para el Árbol: 2 Pociones.")
	_espera("entregar la lavanda otra vez", Oak.aplicar_senal("oak:lavanda_entregada"), "")
	_espera("Pociones de la lavanda (una sola vez)", Inv.cantidad("Poción"), pociones2 + 2)
	_espera("Rosa tras la lavanda, 2.ª vez", Oak.dialogo_de("rosa", 1), _dlg("npc_rosa"))
	_espera("Doña Encina agradece", Oak.dialogo_de("encina", 1), _dlg("oak_encina_gracias"))
	Oak.aplicar_senal("oak:encina_gracias")
	_espera("Doña Encina después, 2.ª vez", Oak.dialogo_de("encina", 1), _dlg("oak_encina_anillo"))

	# cofres hechos a mano
	_partida({}, ["Kael"], 0)
	var r := Oak.abrir_cofre("oak_cofre_raices")
	_espera("cofre de las raíces", r.get("texto", ""), "¡Has encontrado 100 monedas y 1 Poción!")
	_espera("monedas del cofre", Inv.oro(), 100)
	_espera("cofre de las raíces otra vez", Oak.abrir_cofre("oak_cofre_raices"), {})
	_espera("monedas tras abrirlo dos veces", Inv.oro(), 100)
	_espera("cofre que no es de Oakhaven", Oak.abrir_cofre("2_10_10"), {})
	_espera("cofre de las velas", Oak.abrir_cofre("oak_cofre_velas").get("texto", ""),
		"¡Has encontrado 1 Éter y 1 Incienso de Ceniza!")
	r = Oak.abrir_cofre("oak_cofre_requisados")
	if not r.has("bloqueado") or Engine.get_meta("cofres_abiertos", {}).has("oak_cofre_requisados"):
		_fallo("4: los requisados se abren antes de que Kael salga de la ciudad (%s)" % r)
	_partida({"pv_02": true}, ["Kael"], 0)
	r = Oak.abrir_cofre("oak_cofre_requisados")
	_espera("requisados tras PV-02", r.get("nota", ""), "nota_oak_requisados")
	_espera("nota de los requisados en el Diario", P.visto("nota_oak_requisados"), true)
	_espera("cofres abiertos", Engine.get_meta("cofres_abiertos", {}).keys(), ["oak_cofre_requisados"])

	# notas: en lore_visto, sin páginas de actos
	_partida()
	_espera("nota nueva", Oak.ver_nota("nota_oak_bando"), true)
	_espera("nota repetida", Oak.ver_nota("nota_oak_bando"), false)
	_espera("nota que no existe", Oak.ver_nota("oak_sello"), false)
	_espera("lore_visto tras las notas", Engine.get_meta("lore_visto", {}).keys(), ["nota_oak_bando"])
	for a in P.ACTOS:
		if P.acto_completo(a):
			_fallo("4: una nota completa el acto «%s»" % a["nombre"])

	# escena de la posada: solo los presentes
	for caso in [[["Kael"], "oak_posada_solo"], [["Kael", "Lya"], "oak_posada_lya"],
			[["Kael", "Lya", "Garon"], "oak_posada_grupo"], [[], "oak_posada_grupo"]]:
		_partida({}, caso[0])
		_espera("posada con %s" % [caso[0]], Oak.escena_posada(), _dlg(caso[1]))

	# señales de fuera de Oakhaven: nada
	_espera("señal de otro sitio", Oak.aplicar_senal("pv:algo"), "")
	_espera("señal que no es texto", Oak.aplicar_senal({"a": 1}), "")


# ================================================================= 5-6. Dialogic

func _revisar_registro() -> void:
	var antes: Dictionary = ProjectSettings.get_setting("dialogic/directories/dch_directory", {})
	var claves_antes: Array = antes.keys()
	Oak.registrar_dialogic()
	Oak.registrar_dialogic()                       # dos veces: no cambia nada la segunda
	var despues: Dictionary = ProjectSettings.get_setting("dialogic/directories/dch_directory", {})
	if despues.keys() != claves_antes:
		_fallo("5: registrar_dialogic() ha cambiado los ajustes del proyecto (%d → %d personajes)" % [claves_antes.size(), despues.size()])
	for id in Oak.PERSONAJES:
		var ch = util.get_character_resource(id)
		if ch == null:
			_fallo("5: Dialogic no encuentra a «%s» tras registrar_dialogic()" % id)
			continue
		if ch.resource_path != Oak.PERSONAJES[id] or ch.get_identifier() != id:
			_fallo("5: «%s» apunta a %s (identificador «%s»)" % [id, ch.resource_path, ch.get_identifier()])


func _preparar_propuesta() -> void:
	if not FileAccess.file_exists(PROPUESTA + ".gdignore"):
		_fallo("6: la carpeta de la propuesta no lleva .gdignore (entraría en el juego y en Dialogic)")
	var s := GDScript.new()
	s.source_code = _leer(PROPUESTA + "oakhaven_propuesta.gd")
	if s.source_code == "" or s.reload() != OK:
		_fallo("6: no se puede leer oakhaven_propuesta.gd")
		return
	Prop = s
	var c: Dictionary = s.get_script_constant_map()
	if not s.source_code.begins_with("extends RefCounted\n# PROPUESTA"):
		_fallo("6: oakhaven_propuesta.gd no empieza marcado como PROPUESTA")
	# personajes de la propuesta, en tiempo de juego y por su ruta, como hace registrar_dialogic() (un recurso guardado
	# en los metadatos de Engine haría caer Godot al cerrar)
	var dir: Dictionary = util.get_directory("dch").duplicate()
	for id in c["PERSONAJES"]:
		if dir.has(id):
			_fallo("6: el personaje de la propuesta «%s» ya existe en Dialogic" % id)
			continue
		dir[id] = c["PERSONAJES"][id]
	util.set_directory("dch", dir)
	for id in c["PERSONAJES"]:
		var ruta: String = c["PERSONAJES"][id]
		var ch = util.get_character_resource(id)
		if ch == null:
			_fallo("6: Dialogic no puede leer %s" % ruta)
			continue
		if not ch.description.begins_with("PROPUESTA"):
			_fallo("6: %s no está marcado como PROPUESTA en su descripción" % ruta)
		_revisar_texto(ch.display_name, "nombre de " + id, false)
		_revisar_texto(ch.description, "descripción de " + id, false)
	for ruta in _archivos(PROPUESTA, "dch"):
		if not ruta.get_file().get_basename() in c["PERSONAJES"]:
			_fallo("6: %s no está en PERSONAJES de la propuesta" % ruta)
	# ids: no chocan con los neutros salvo lo que sustituyen
	var neutros := {}
	for lista in [Oak.MISIONES, Oak.COFRES, Oak.SECRETOS, Oak.PIEZAS, Oak.NOTAS]:
		for d in lista:
			neutros[d["id"]] = true
	for lista in [c["MISIONES"], c["SECRETOS"], c["PIEZAS"], c["NOTAS"]]:
		for d in lista:
			if neutros.has(d["id"]):
				_fallo("6: la propuesta repite el id neutro «%s»" % d["id"])
			if not c["DEPENDE_DE"].has(d["depende"]):
				_fallo("6: «%s» depende de «%s», que no está en DEPENDE_DE" % [d["id"], d["depende"]])
			if d.has("sustituye") and not neutros.has(d["sustituye"]):
				_fallo("6: «%s» sustituye a «%s», que no existe" % [d["id"], d["sustituye"]])
			for k in ["si", "empieza", "fin", "estado"]:
				if d.has(k) and Oak.error_condicion(d[k]) != "":
					_fallo("6: %s en %s" % [Oak.error_condicion(d[k]), d["id"]])
			if d.has("casilla"):
				_casilla_valida("propuesta " + d["id"], d["casilla"])
	for n in c["NOTAS"]:
		if _palabras(n["texto"]) > 15:
			_fallo("6: la nota %s tiene %d palabras" % [n["id"], _palabras(n["texto"])])
		_revisar_texto(n["texto"], "nota " + n["id"], false)
	for id in c["SUSTITUYE_NPC"]:
		if Oak.npc(id).is_empty():
			_fallo("6: SUSTITUYE_NPC cambia a «%s», que no es un vecino" % id)
		for d in c["SUSTITUYE_NPC"][id]["dialogos"]:
			if Oak.error_condicion(d.get("si", "")) != "":
				_fallo("6: %s en %s" % [Oak.error_condicion(d.get("si", "")), d["dialogo"]])
			if not FileAccess.file_exists(_ruta_propuesta(d["dialogo"])):
				_fallo("6: falta el diálogo %s" % d["dialogo"])
	for neutro in c["SUSTITUYE_DIALOGO"]:
		if not neutro in Oak.dialogos_nuevos():
			_fallo("6: SUSTITUYE_DIALOGO cambia «%s», que no es un diálogo de la ciudad" % neutro)
		if not FileAccess.file_exists(PROPUESTA + c["SUSTITUYE_DIALOGO"][neutro] + ".dtl"):
			_fallo("6: falta %s.dtl en la propuesta" % c["SUSTITUYE_DIALOGO"][neutro])
	# sus diálogos: marcados, sin revelar nada y a la cola para recorrerlos
	for ruta in _archivos(PROPUESTA, "dtl"):
		var texto := _leer(ruta)
		if not texto.begins_with("# PROPUESTA"):
			_fallo("6: %s no empieza marcado como PROPUESTA" % ruta.get_file())
		for f in _frases_dtl(texto):
			_revisar_texto(f[1], ruta.get_file(), false)
			if f[1].length() > MAX_CARACTERES:
				_fallo("6: %s: frase de %d caracteres: «%s»" % [ruta.get_file(), f[1].length(), f[1]])
		for sn in _senales_dtl(texto):
			if not sn in Oak.SENALES and not sn in c["SENALES"]:
				_fallo("6: %s: señal desconocida «%s»" % [ruta.get_file(), sn])
		var t := DialogicTimeline.new()
		t.from_text(texto)
		cola.append({"ruta": ruta, "id": ruta.get_file().get_basename(), "propuesta": true, "opciones": [], "recurso": t,
			"texto": texto})


func _ruta_propuesta(id: String) -> String:
	return PROPUESTA + id + ".dtl" if FileAccess.file_exists(PROPUESTA + id + ".dtl") else Oak.ruta_dialogo(id)


# Grupo de una escena de posada (neutra o de la propuesta), o [] si es de un vecino.
func _grupo_posada(id: String) -> Array:
	for e in Oak.ESCENAS_POSADA:
		if e["dialogo"] == id:
			return e["grupo"]
	if Prop != null:
		var sus: Dictionary = Prop.get_script_constant_map()["SUSTITUYE_DIALOGO"]
		for neutro in sus:
			if sus[neutro] == id:
				return _grupo_posada(neutro)
	return []


func _vecino_de(id: String) -> String:
	for n in Oak.NPCS:
		for d in n["dialogos"]:
			if d["dialogo"] == id:
				return n["personaje"]
	return ""


func _empezar_recorrido() -> void:
	actual = cola.pop_front()
	reg = {"frases": [], "senales": [], "preguntas": 0}
	elegidas = []
	f_pregunta = -1
	pregunta_abierta = false
	f_inicio = frames
	f_input = frames
	if actual.has("recurso"):
		D.start(actual["recurso"])
	else:
		D.start(actual["ruta"])


func _al_evento(ev) -> void:
	if actual == null or not ev is DialogicTextEvent:
		return
	var ch = ev.character
	var quien: String = ch.get_identifier() if ch != null else ""
	reg["frases"].append({"quien": quien, "nombre": ch.display_name if ch != null else "", "ruta": ch.resource_path if ch != null else "",
		"texto": _visible(ev.text)})
	if ch != null and ch.portraits.get("normal", {}).get("scene", "") == "res://dialogos/oakhaven/retrato_tenido.tscn":
		var tinte = str_to_var(ch.portraits["normal"]["export_overrides"].get("tinte", "Color(1, 1, 1, 1)"))
		for n in root.find_children("*", "Node2D", true, false):
			if n.get_script() == TENIDO and n.character == ch:
				var spr: Sprite2D = n.get_node("Portrait")
				if spr.texture != null and spr.self_modulate.is_equal_approx(tinte):
					tintes_ok[actual["id"]] = true


func _al_senal(arg) -> void:
	if actual != null:
		reg["senales"].append(str(arg))
		senales_vistas[str(arg)] = true


func _al_elegir(info: Dictionary) -> void:
	if actual != null and pregunta_abierta:
		pregunta_abierta = false
		elegidas.append(int(info.get("button_index", 0)))


func _al_pregunta(info: Dictionary) -> void:
	if actual == null:
		return
	f_pregunta = frames
	pregunta_abierta = true
	reg["preguntas"] += 1
	var n: int = elegidas.size()
	var k: int = info["choices"].filter(func(c): return c.get("visible", true)).size()
	rutas_con_opciones[actual["id"]] = maxi(k, rutas_con_opciones.get(actual["id"], 0))
	if n >= actual["opciones"].size():               # pregunta nueva en este camino: las otras opciones, a la cola
		for j in range(2, k + 1):
			var otro: Dictionary = actual.duplicate()
			otro["opciones"] = elegidas + [j]
			cola.push_front(otro)


func _acabar_recorrido() -> void:
	recorridos += 1
	var id: String = actual["id"]
	var donde := "%s%s" % [id, (" (opciones %s)" % [elegidas]) if not elegidas.is_empty() else ""]
	var frases: Array = reg["frases"]
	var grupo := _grupo_posada(id)
	var minimo := 3 if not grupo.is_empty() else 2
	var maximo := 5 if not grupo.is_empty() else 4
	if frases.size() < minimo or frases.size() > maximo:
		_fallo("5: %s: %d frases (de %d a %d)" % [donde, frases.size(), minimo, maximo])
	var hablan := {}
	for f in frases:
		hablan[f["quien"]] = true
		if f["quien"] == "" or f["nombre"] == f["quien"]:
			_fallo("5: %s: una frase sin su personaje de Dialogic (%s): «%s»" % [donde, f["quien"], f["texto"]])
		elif not actual.get("propuesta", false) and f["ruta"] == "":
			_fallo("5: %s: «%s» no sale de un .dch" % [donde, f["quien"]])
		if f["texto"].length() > MAX_CARACTERES:
			_fallo("5: %s: frase de %d caracteres" % [donde, f["texto"].length()])
		_revisar_texto(f["texto"], donde, not actual.get("propuesta", false))
	if grupo.is_empty():
		if hablan.size() != 1:
			_fallo("5: %s: hablan %s (un vecino por diálogo)" % [donde, hablan.keys()])
		elif not actual.get("propuesta", false) and not hablan.has(_vecino_de(id)):
			_fallo("5: %s: habla %s, no %s" % [donde, hablan.keys(), _vecino_de(id)])
	else:
		var permitidos: Array = grupo.map(func(x): return x.to_lower()) + ["posadera", "olvido"]
		for q in hablan:
			if not q in permitidos:
				_fallo("5: %s: habla %s, que no está en el grupo %s" % [donde, q, grupo])
		for q in grupo:
			if not hablan.has(q.to_lower()):
				_fallo("5: %s: %s está en el grupo y no dice nada" % [donde, q])
	# las señales de este camino: las del archivo fuera de las opciones, más las de la rama elegida
	var texto: String = actual.get("texto", _leer(actual["ruta"]))
	var esperadas: Array = _senales_dtl(texto)
	if reg["preguntas"] == 0 and reg["senales"] != esperadas:
		_fallo("5: %s: señales %s (se esperaban %s)" % [donde, reg["senales"], esperadas])
	for sn in reg["senales"]:
		if not sn in esperadas:
			_fallo("5: %s: señal que no está en el archivo: %s" % [donde, sn])
	print("  %s%s: %d frases (%s)%s" % ["[propuesta] " if actual.get("propuesta", false) else "", donde, frases.size(),
		", ".join(PackedStringArray(hablan.keys())), (" · señales %s" % [reg["senales"]]) if not reg["senales"].is_empty() else ""])
	actual = null


func _process(_d: float) -> bool:
	frames += 1
	match paso:
		0:
			if frames < 3:
				return false
			if D == null or util == null:
				_fallo("Dialogic no está cargado")
				return _terminar()
			_controles()
			_revisar_datos()
			_revisar_logica()
			_revisar_registro()
			if R != null and R.has_method("precalentar_dialogos"):
				R.precalentar_dialogos()
			D.event_handled.connect(_al_evento)
			D.signal_event.connect(_al_senal)
			D.Choices.question_shown.connect(_al_pregunta)
			D.Choices.choice_selected.connect(_al_elegir)
			for id in Oak.dialogos_nuevos():
				cola.append({"ruta": Oak.ruta_dialogo(id), "id": id, "opciones": []})
			_preparar_propuesta()
			paso = 1
		1:
			if actual == null:
				if cola.is_empty():
					paso = 2
					return false
				_empezar_recorrido()
				return false
			var f := frames - f_inicio
			if f > MAX_FOTOGRAMAS:
				_fallo("5: %s se atasca (estado %d, evento %d)" % [actual["id"], D.current_state, D.current_event_idx])
				D.end_timeline(true)
				actual = null
				return false
			if f > 2 and D.current_timeline == null:
				_acabar_recorrido()
				return false
			if pregunta_abierta:                    # opciones a la vista: se elige (y se reintenta), no se pulsa
				if frames - f_pregunta >= 10:
					var n: int = elegidas.size()
					var j: int = actual["opciones"][n] if n < actual["opciones"].size() else 1
					f_pregunta = frames
					D.Choices.select_choice(j)
					f_input = frames
				return false
			var esperando: Array = [D.States.IDLE, D.States.REVEALING_TEXT, D.States.AWAITING_CHOICE]
			if D.current_state in esperando and frames - f_input >= (4 if D.current_state != D.States.AWAITING_CHOICE else 10):
				D.Inputs.handle_input()
				f_input = frames
		2:
			# cobertura: cada señal de los diálogos ha llegado en algún recorrido; las opciones, todas recorridas
			for id in Oak.dialogos_nuevos():
				for sn in _senales_dtl(_leer(Oak.ruta_dialogo(id))):
					if not senales_vistas.has(sn):
						_fallo("5: la señal %s de %s no llegó nunca" % [sn, id])
			for id in rutas_con_opciones:
				if rutas_con_opciones[id] < 2:
					_fallo("5: %s: pregunta con menos de dos opciones" % id)
			for id in ["oak_pip_secreto", "oak_pip_trampilla"]:
				if not rutas_con_opciones.has(id):
					_fallo("5: no se llegó a las opciones de %s" % id)
			for id in Oak.dialogos_nuevos() + ["oak_olvido", "oak_posada_olvido_solo"]:
				var texto := _leer(_ruta_propuesta(id))
				if ("join posadera" in texto or "join bastian" in texto or "join olvido" in texto) and not tintes_ok.has(id):
					_fallo("5: %s: el retrato provisional no lleva su tinte" % id)
			return _terminar()
	return false


func _terminar() -> bool:
	print("OK datos de Oakhaven: %d vecinos, %d diálogos nuevos y %d recorridos con Dialogic (con la propuesta); " %
		[Oak.NPCS.size(), Oak.dialogos_nuevos().size(), recorridos] +
		"ids, casillas, condiciones, recompensas, notas, D-033 y versión neutra revisados")
	for t in fallos:
		print("FALLO: ", t)
	print("FALLOS: %d" % fallos.size())
	quit(1 if fallos.size() > 0 else 0)
	return true
