extends RefCounted
# Artes (Godot 4.x): las tres familias de magia nuevas de T-091, que no hacen daño (docs/diseno/combate_ampliaciones.md,
# §3): Alba (Kael) mueve el ATB, Escarcha (Kael) pone corazas y Lumbre (Lya) levanta y sostiene.
# Datos y lógica sin escena: trabajan sobre los diccionarios de luchador de combate.gd («hp», «hp_max», «mp», «atb»,
# «hero»...) y sobre su cola de turnos. Enganchado el 09/11 (docs/diseno/combate_enganches.md): combate.gd (menú de
# magia, lanzar, Aliento y aviso al subir de nivel), menu_combate.gd (pestañas e iconos), menus.gd (Habilidades) y
# tienda.gd (libros). Falta el Diario (diario.gd, de narrativa): fichas_activas().
# Uso:  var Artes = load("res://artes.gd");  Artes.nivel("Kael", "Alba")...
#
# Lo que no cambia (D-048, D-037): las 12 magias de siempre siguen su camino (ninguna arte pasa por _animar_golpe,
# _golpe_visual, _lanzar ni _magia_grupal) y Garon no aprende ninguna. Las artes son acciones normales: gastan PM, acaban
# el turno y cargan la Armonía como cualquier acción (eso lo sigue haciendo combate.gd).
# Nada de aquí tira del generador aleatorio global: la huella del combate (C0) no cambia por usar este archivo.
# Los estados (barrera, aliento, brasa) viven en el diccionario del luchador: acaban con el combate y no se guardan.

const FAMILIAS := ["Alba", "Escarcha", "Lumbre"]
# Quién usa cada familia, en el orden de sus pestañas. Cada héroe, dos como mucho: no caben más pestañas (§3.6).
const DE_HEROE := {"Kael": ["Alba", "Escarcha"], "Lya": ["Lumbre"]}
# Nivel del personaje con el que aprende el I, el II y el III. Ninguna en el nivel 1: quien empieza en el 1 ve el menú
# como hoy. Las cuatro familias de siempre siguen con grupo.gd (NIVEL_MAGIA: 1, 5 y 10).
const UMBRALES := {"Alba": [3, 9, 16], "Escarcha": [6, 12, 20], "Lumbre": [4, 10, 18]}
const COLOR := {"Alba": Color("F2B5A0"), "Escarcha": Color("BFE6FF"), "Lumbre": Color("FFE3A3")}
# Niveles que ya tienen su enganche en el juego: los demás tienen datos y lógica (y sus pruebas), pero no salen en los
# menús. M1: Alba I (y el II, mismo mecanismo); M2: Lumbre I y II; M3: Escarcha I y II; M4: los III.
const ACTIVOS := {"Alba": 2, "Escarcha": 0, "Lumbre": 2}
const ROMANOS := ["I", "II", "III"]

# Cada nivel: «a» = a quién va; «todos» = a todos a la vez, sin elegir; «dano» 0, como pide la ruta propia (§3.1).
#   aliado_otro / aliados_otros: aliados en pie, menos quien lanza y los que ya esperan su turno
#   aliado / aliados: aliados en pie (también quien lanza) · caido: aliados con 0 PV · enemigos: enemigos en pie
const NIVELES := {
	"Alba": [
		{"nombre": "Compás del Alba", "coste": 6, "dano": 0, "todos": false, "a": "aliado_otro", "atb": 50.0},
		{"nombre": "Peso del Ocaso", "coste": 15, "dano": 0, "todos": true, "a": "enemigos", "atb": -40.0, "atb_jefe": -20.0},
		{"nombre": "Hora Dorada", "coste": 30, "dano": 0, "todos": true, "a": "aliados_otros", "atb_lleno": true}],
	"Escarcha": [
		{"nombre": "Coraza de Escarcha", "coste": 7, "dano": 0, "todos": false, "a": "aliado", "barrera": 0.30},
		{"nombre": "Muralla de Escarcha", "coste": 18, "dano": 0, "todos": true, "a": "aliados", "barrera": 0.20},
		{"nombre": "Invierno Guardián", "coste": 32, "dano": 0, "todos": true, "a": "aliados", "barrera": 0.30, "congela": true}],
	"Lumbre": [
		{"nombre": "Lumbre de Retorno", "coste": 14, "dano": 0, "todos": false, "a": "caido", "revive": 0.25},
		{"nombre": "Segundo Aliento", "coste": 16, "dano": 0, "todos": true, "a": "aliados", "aliento": 3, "regen": 0.08},
		{"nombre": "Última Brasa", "coste": 34, "dano": 0, "todos": true, "a": "aliados", "brasa": 0.30}],
}
# Línea de explicación del menú (dos líneas como mucho).
const DESCRIPCION := {
	"Compás del Alba": "Un aliado gana media barra: actuará antes.",
	"Peso del Ocaso": "Los enemigos pierden casi media barra. Los jefes, la mitad.",
	"Hora Dorada": "Llena la barra de los aliados: actúan en cuanto acabes.",
	"Coraza de Escarcha": "Una coraza de hielo absorbe golpes (30 % de sus PV).",
	"Muralla de Escarcha": "Hielo para todo el grupo: absorbe el 20 % de los PV de cada uno.",
	"Invierno Guardián": "Corazas de hielo para todos; quien las rompa, se congela.",
	"Lumbre de Retorno": "Devuelve al combate a un aliado caído con un cuarto de su vida.",
	"Segundo Aliento": "Tres turnos: cada aliado recupera vida al empezar su turno.",
	"Última Brasa": "Si un aliado cae, se levanta una vez con algo de vida.",
}
# Por qué una fila sale apagada (además de por los PM, que ya enseña el coste).
const MOTIVO := {"sin_otro": "Necesita a otro aliado en pie.", "esperan": "Ya esperan su turno.",
	"sin_caidos": "Nadie ha caído.", "sin_nadie": "No hay a quién."}
# Sonidos (sonido.gd, catálogo pendiente del especialista de sonido): uno por lanzamiento, cuando se aplica el efecto,
# y los de los estados. Hasta que existan, combate.gd no los pide.
const SONIDO_LANZAR := {"Alba": ["arte_alba", "arte_ocaso", "arte_hora_dorada"],
	"Escarcha": ["arte_escarcha", "arte_escarcha", "arte_escarcha"], "Lumbre": ["renacer", "arte_lumbre", "arte_lumbre"]}
const SONIDO_ESTADO := {"absorbe": "barrera_absorbe", "rota": "barrera_rota", "aliento": "aliento", "brasa": "brasa"}
# Libros de la tienda (nivel II) y tomos escondidos (nivel III antes de tiempo; los pondrá el código del mundo).
const LIBROS := [["Alba", 2, 350], ["Escarcha", 2, 400], ["Lumbre", 2, 450]]
const TOMOS := {"tomo_alba": ["Alba", 3], "tomo_escarcha": ["Escarcha", 3], "tomo_lumbre": ["Lumbre", 3]}
# Fichas del Diario (diario.gd): solo cómo funcionan, sin historia.
# Con el formato de diario.gd FICHAS ([título, texto]) más la familia y el nivel que la traen al juego.
const FICHAS := [
	["Ritmo", "El Alba adelanta el turno de un aliado o retrasa a los enemigos.", "Alba", 1],
	["Aliento", "Tres turnos: el aliado recupera vida al empezar cada uno de sus turnos.", "Lumbre", 2],
	["Barrera", "Una coraza de hielo absorbe el daño hasta romperse. No se suma.", "Escarcha", 1],
	["Brasa", "Si el aliado cae, se levanta una vez con algo de vida.", "Lumbre", 3],
]
# Estados de los héroes, en el orden en que se dibujan sus iconos junto al nombre.
const ESTADOS := ["barrera", "aliento", "brasa"]
const COLOR_ESTADO := {"barrera": Color("BFE6FF"), "aliento": Color("B8E07A"), "brasa": Color("FF9A4A")}


# ================================================================= datos y aprendizaje

static func es_arte(magia: String) -> bool:
	return NIVELES.has(magia)


static func datos(familia: String, nivel: int) -> Dictionary:
	return NIVELES[familia][clampi(nivel, 1, 3) - 1]


static func familias_de(heroe: String) -> Array:
	return DE_HEROE.get(heroe, [])


# Nivel (0 a 3) que sabe un héroe de una familia, con sus datos de grupo.gd («nivel» y «libros»). Se calcula, no se
# guarda: una partida antigua de un Kael de nivel 7 ya sabe Compás del Alba al cargarla (decisión del 09/11).
static func nivel_de(heroe: String, familia: String, d: Dictionary) -> int:
	if not familia in familias_de(heroe) or not UMBRALES.has(familia):
		return 0
	var n := 0
	for umbral in UMBRALES[familia]:
		if int(d.get("nivel", 1)) >= int(umbral):
			n += 1
	return clampi(maxi(n, int(d.get("libros", {}).get(familia, 0))), 0, 3)


# El nivel que puede usar en combate: el que sabe, hasta lo que ya está enganchado (ACTIVOS).
static func nivel_usable(heroe: String, familia: String, d: Dictionary) -> int:
	return mini(nivel_de(heroe, familia, d), int(ACTIVOS.get(familia, 0)))


static func _datos_grupo(heroe: String) -> Dictionary:
	if not ResourceLoader.exists("res://grupo.gd"):
		return {}
	var g: Dictionary = load("res://grupo.gd").datos()
	return g.get(heroe, {})


static func nivel(heroe: String, familia: String) -> int:
	return nivel_de(heroe, familia, _datos_grupo(heroe))


# Artes que puede usar, con la forma de combate.gd _hechizos(): [familia, nivel, datos del nivel].
static func hechizos_de(heroe: String, d: Dictionary) -> Array:
	var r: Array = []
	for familia in familias_de(heroe):
		for i in nivel_usable(heroe, familia, d):
			r.append([familia, i + 1, NIVELES[familia][i]])
	return r


static func hechizos(heroe: String) -> Array:
	return hechizos_de(heroe, _datos_grupo(heroe))


# Aprende un nivel con un libro o un tomo (se apunta en «libros», como los de siempre). Devuelve false si no usa esa
# familia o ya lo sabía. «d»: los datos del héroe en grupo.gd.
static func aprender_en(heroe: String, familia: String, nivel_nuevo: int, d: Dictionary) -> bool:
	if not familia in familias_de(heroe) or nivel_de(heroe, familia, d) >= nivel_nuevo:
		return false
	if not d.has("libros"):
		d["libros"] = {}
	d["libros"][familia] = clampi(nivel_nuevo, 1, 3)
	return true


static func aprender(heroe: String, familia: String, nivel_nuevo: int) -> bool:
	var d := _datos_grupo(heroe)
	return not d.is_empty() and aprender_en(heroe, familia, nivel_nuevo, d)


# Lo que se aprende al subir del nivel «antes» al «ahora» (para el aviso «Kael aprende…» de combate.gd): [familia,
# nivel]. Como con las de siempre, solo el nivel más alto de cada familia y solo si lo da el nivel, no un libro.
static func nuevas_al_subir(heroe: String, d: Dictionary, antes: int, ahora: int) -> Array:
	var r: Array = []
	for familia in familias_de(heroe):
		var n := nivel_usable(heroe, familia, d)
		if n > 0:
			var umbral: int = UMBRALES[familia][n - 1]
			if umbral > antes and umbral <= ahora:
				r.append([familia, n])
	return r


static func libros_en_venta() -> Array:
	return LIBROS.filter(func(l): return int(l[1]) <= int(ACTIVOS.get(l[0], 0)))


# Fichas del Diario de lo que ya está en el juego, como diario.gd FICHAS: [título, texto].
static func fichas_activas() -> Array:
	var r: Array = []
	for f in FICHAS:
		if int(f[3]) <= int(ACTIVOS.get(f[2], 0)):
			r.append([f[0], f[1]])
	return r


# ================================================================= a quién va y por qué no

static func es_jefe(f: Dictionary) -> bool:
	return f.get("personalidad", "") == "jefe" or f.get("fases", false) or f.get("ultimo_aliento", false)


static func _en(lista: Array, f: Dictionary) -> bool:
	for x in lista:
		if is_same(x, f):
			return true
	return false


# ¿Espera ya su turno? (está en la cola, o tiene la barra llena y aún no ha entrado)
static func esperando(f: Dictionary, cola: Array, atb_max := 100.0) -> bool:
	return _en(cola, f) or float(f.get("atb", 0.0)) >= atb_max


static func objetivos(familia: String, nv: int, actor: Dictionary, heroes: Array, enemigos: Array, cola: Array,
		atb_max := 100.0) -> Array:
	match String(datos(familia, nv)["a"]):
		"aliado_otro", "aliados_otros":
			return heroes.filter(func(h): return not is_same(h, actor) and h["hp"] > 0 and not esperando(h, cola, atb_max))
		"aliado", "aliados":
			return heroes.filter(func(h): return h["hp"] > 0)
		"caido":
			return heroes.filter(func(h): return h["hp"] <= 0)
		"enemigos":
			return enemigos.filter(func(e): return e["hp"] > 0 and not e.get("huido", false))
	return []


# Por qué no se puede lanzar ahora ("" si se puede, sin contar los PM).
static func motivo_apagado(familia: String, nv: int, actor: Dictionary, heroes: Array, enemigos: Array, cola: Array,
		atb_max := 100.0) -> String:
	if not objetivos(familia, nv, actor, heroes, enemigos, cola, atb_max).is_empty():
		return ""
	match String(datos(familia, nv)["a"]):
		"aliado_otro", "aliados_otros":
			var otros := heroes.filter(func(h): return not is_same(h, actor) and h["hp"] > 0)
			return MOTIVO["sin_otro"] if otros.is_empty() else MOTIVO["esperan"]
		"caido":
			return MOTIVO["sin_caidos"]
	return MOTIVO["sin_nadie"]


static func puede_pagar(actor: Dictionary, familia: String, nv: int, modo_pruebas := false) -> bool:
	return modo_pruebas or int(actor.get("mp", 0)) >= int(datos(familia, nv)["coste"])


# ================================================================= efectos

# Cambia la barra ATB una vez. Hacia arriba, nunca hasta 100: se queda en 99,9 y combate.gd la mete en la cola por el
# camino normal (_process); si ya esperaba turno, nada (tendría dos). Hacia abajo, quien esperaba pierde ese turno y
# vuelve a cargar. Devuelve cuánto ha cambiado de verdad.
static func sumar_atb(f: Dictionary, v: float, cola: Array, atb_max := 100.0) -> float:
	var antes := float(f.get("atb", 0.0))
	if v > 0.0:
		if esperando(f, cola, atb_max):
			return 0.0
		f["atb"] = minf(atb_max - 0.1, antes + v)
	else:
		for i in range(cola.size() - 1, -1, -1):
			if is_same(cola[i], f):
				cola.remove_at(i)
		f["atb"] = maxf(0.0, minf(antes, atb_max) + v)
	return float(f["atb"]) - antes


# Coraza: absorbe hasta «frac» de sus PV máximos. No se suma: se queda la mayor (y, con ella, si congela).
static func poner_barrera(f: Dictionary, frac: float, congela := false) -> int:
	var nueva := maxi(1, int(f["hp_max"] * frac))
	if nueva >= int(f.get("barrera", 0)):
		f["barrera"] = nueva
		f["barrera_escarcha"] = congela
	return int(f["barrera"])


# El daño pasa por la coraza antes que por los PV. Devuelve {"resto", "absorbido", "rota", "congela"}: «resto» es lo
# que llega a los PV; «congela», si quien la ha roto queda Congelado (Invierno Guardián).
static func absorber(f: Dictionary, dano: int) -> Dictionary:
	var r := {"resto": maxi(0, dano), "absorbido": 0, "rota": false, "congela": false}
	var b := int(f.get("barrera", 0))
	if b <= 0 or dano <= 0:
		return r
	var a := mini(b, dano)
	f["barrera"] = b - a
	r["absorbido"] = a
	r["resto"] = dano - a
	if f["barrera"] <= 0:
		r["rota"] = true
		r["congela"] = f.get("barrera_escarcha", false)
		f["barrera"] = 0
		f["barrera_escarcha"] = false
	return r


# Aliento: «turnos» turnos suyos; volver a lanzarlo lo renueva, no lo suma.
static func dar_aliento(f: Dictionary, turnos: int, regen: float) -> void:
	f["aliento"] = turnos
	f["aliento_regen"] = regen


# Al empezar el turno de un héroe, antes de abrir su menú: cura su Aliento (y lo gasta) más la regeneración de su
# equipo («regen_equipo», accesorio Cinta de Lumi). Devuelve los PV curados (0 si nada).
static func curar_al_empezar_turno(f: Dictionary, regen_equipo := 0.0) -> int:
	if f["hp"] <= 0:
		return 0
	var frac := maxf(0.0, regen_equipo)
	if int(f.get("aliento", 0)) > 0:
		frac += float(f.get("aliento_regen", 0.0))
		f["aliento"] = int(f["aliento"]) - 1
	if frac <= 0.0:
		return 0
	var cura := mini(maxi(1, int(f["hp_max"] * frac)), f["hp_max"] - f["hp"])
	f["hp"] += cura
	return cura


static func poner_brasa(f: Dictionary, frac: float) -> void:
	f["brasa"] = maxf(float(f.get("brasa", 0.0)), frac)


# Lo que pasa cuando un héroe llega a 0 PV (lo llamará _quitar_pv): con Brasa se levanta en ese instante y la gasta
# (devuelve true); si no, pierde la coraza y el Aliento (false).
static func al_llegar_a_cero(f: Dictionary) -> bool:
	if not f.get("hero", false) or f["hp"] > 0:
		return false
	if float(f.get("brasa", 0.0)) > 0.0:
		f["hp"] = maxi(1, int(f["hp_max"] * float(f["brasa"])))
		f["brasa"] = 0.0
		return true
	f["barrera"] = 0
	f["barrera_escarcha"] = false
	f["aliento"] = 0
	return false


# Lumbre de Retorno: vuelve con «frac» de sus PV y la barra vacía, fuera de la cola (si cayó con la barra llena, se
# quedaría sin turno) y sin guardia. Devuelve sus PV.
static func revivir(f: Dictionary, frac: float, cola: Array) -> int:
	f["hp"] = maxi(1, int(f["hp_max"] * frac))
	f["atb"] = 0.0
	for i in range(cola.size() - 1, -1, -1):
		if is_same(cola[i], f):
			cola.remove_at(i)
	f["defendiendo"] = false
	f["barrera"] = 0
	f["barrera_escarcha"] = false
	f["aliento"] = 0
	return int(f["hp"])


# Aplica un arte a sus objetivos (ya elegidos) y devuelve qué le pasó a cada uno, para los números y el sonido:
# [{"f": luchador, "atb": cambio} | {"f", "barrera": PV} | {"f", "pv": PV al volver} | {"f", "aliento": turnos} |
#  {"f", "brasa": fracción}]. «turnos_extra»: lo que alarga el Aliento el equipo de quien lanza (Báculo del Peregrino).
# No gasta PM ni acaba el turno: eso es de combate.gd.
static func aplicar(familia: String, nv: int, objs: Array, cola: Array, atb_max := 100.0, turnos_extra := 0) -> Array:
	var d := datos(familia, nv)
	var r: Array = []
	for f in objs:
		var x := {"f": f}
		if d.has("atb"):
			x["atb"] = sumar_atb(f, float(d.get("atb_jefe", d["atb"])) if es_jefe(f) else float(d["atb"]), cola, atb_max)
		elif d.get("atb_lleno", false):
			x["atb"] = sumar_atb(f, atb_max, cola, atb_max)
		elif d.has("barrera"):
			x["barrera"] = poner_barrera(f, float(d["barrera"]), d.get("congela", false))
		elif d.has("revive"):
			x["pv"] = revivir(f, float(d["revive"]), cola)
		elif d.has("aliento"):
			dar_aliento(f, int(d["aliento"]) + maxi(0, turnos_extra), float(d["regen"]))
			x["aliento"] = f["aliento"]
		elif d.has("brasa"):
			poner_brasa(f, float(d["brasa"]))
			x["brasa"] = f["brasa"]
		r.append(x)
	return r


static func estados_de(f: Dictionary) -> Array:
	var r: Array = []
	if int(f.get("hp", 1)) <= 0:                     # caído: sin iconos (el Aliento no cura a quien está en el suelo)
		return r
	if int(f.get("barrera", 0)) > 0:
		r.append("barrera")
	if int(f.get("aliento", 0)) > 0:
		r.append("aliento")
	if float(f.get("brasa", 0.0)) > 0.0:
		r.append("brasa")
	return r


static func sonido(familia: String, nv: int) -> String:
	return SONIDO_LANZAR[familia][clampi(nv, 1, 3) - 1]


# ================================================================= menú de magia (§3.6)

# Pestañas: las de nivel que tienen magias (I, II, III; 96 px) y, detrás, una con icono por familia nueva (64 px).
# «niveles_con_magias»: [bool, bool, bool]; «familias»: las que puede usar, en orden; «valor»: el que recuerda
# combate.gd (magia_nivel_menu): 1-3 = nivel, 4 y 5 = primera y segunda familia. Con una sola pestaña, ninguna (como
# hoy). Devuelve {"pestanas": [{"texto", "valor", "ancho", "icono"?}], "activa": índice, "valor": el corregido}.
static func pestanas_magia(niveles_con_magias: Array, familias: Array, valor: int) -> Dictionary:
	var todas: Array = []
	for n in 3:
		if n < niveles_con_magias.size() and niveles_con_magias[n]:
			todas.append({"texto": ROMANOS[n], "valor": n + 1, "ancho": 96.0})
	for i in familias.size():
		todas.append({"texto": "", "icono": familias[i], "valor": 4 + i, "ancho": 64.0})
	var valores: Array = todas.map(func(p): return p["valor"])
	if not valor in valores:
		valor = 1 if 1 in valores else (valores[0] if not valores.is_empty() else 1)
	var activa := maxi(0, valores.find(valor))
	if todas.size() < 2:
		return {"pestanas": [], "activa": 0, "valor": valor}
	return {"pestanas": todas, "activa": activa, "valor": valor}


# Dónde empieza cada pestaña (x en la pantalla de 1280): la primera en «x0» (808, como hoy) y 4 px entre una y otra.
static func posiciones_pestanas(pestanas: Array, x0 := 808.0, hueco := 4.0) -> Array:
	var r: Array = []
	var x := x0
	for p in pestanas:
		r.append(x)
		x += float(p["ancho"]) + hueco
	return r


# Filas de una pestaña de familia: una por nivel que puede usar, sin «accion» (la pone combate.gd con el Callable).
static func filas_familia(familia: String, nivel_usable_: int, actor: Dictionary, heroes: Array, enemigos: Array,
		cola: Array, modo_pruebas := false, atb_max := 100.0) -> Array:
	var r: Array = []
	for n in range(1, mini(nivel_usable_, 3) + 1):
		var d := datos(familia, n)
		var motivo := motivo_apagado(familia, n, actor, heroes, enemigos, cola, atb_max)
		# A la derecha, solo el coste, como las de siempre (con «I ·» delante, los nombres largos pisaban el coste: capturas
		# del 09/11); el nivel se ve por el orden de las filas, en Habilidades y en la tienda.
		r.append({"texto": d["nombre"], "icono": familia, "familia": familia, "nivel": n,
			"derecha": "PM ∞" if modo_pruebas else "%d PM" % d["coste"],
			"apagado": motivo != "" or not puede_pagar(actor, familia, n, modo_pruebas),
			"desc": motivo if motivo != "" else DESCRIPCION[d["nombre"]]})
	return r


# ================================================================= iconos (dibujados por código, sin fuentes)

# Icono de una familia en un recuadro «tam», desde el draw de un CanvasItem (menu_combate.gd _dibujar_icono).
# Devuelve false si no es una familia nueva (entonces dibuja el de siempre).
static func dibujar_icono(c: CanvasItem, familia: String, tam: Vector2) -> bool:
	if not COLOR.has(familia):
		return false
	var col: Color = COLOR[familia]
	var m := tam * 0.5
	match familia:
		"Alba":                                  # medio sol con rayos sobre el horizonte
			var base := m + Vector2(0, 5)
			var pts := PackedVector2Array()
			for i in 17:
				var a := PI + PI * i / 16.0
				pts.append(base + Vector2(cos(a), sin(a)) * 9.0)
			c.draw_colored_polygon(pts, col)
			for i in 5:
				var a := PI + PI * (i + 0.5) / 5.0
				c.draw_line(base + Vector2(cos(a), sin(a)) * 11.5, base + Vector2(cos(a), sin(a)) * 16.0, col, 2.0)
			c.draw_line(base + Vector2(-15, 0.5), base + Vector2(15, 0.5), col, 2.0)
		"Escarcha":                              # cristal hexagonal
			var pts := PackedVector2Array()
			for i in 6:
				var a := TAU * i / 6.0 - PI / 2.0
				pts.append(m + Vector2(cos(a), sin(a)) * 13.0)
			c.draw_colored_polygon(pts, Color(col, 0.45))
			pts.append(pts[0])
			c.draw_polyline(pts, col, 2.0)
			for i in 3:
				var a := TAU * i / 6.0 - PI / 2.0
				c.draw_line(m - Vector2(cos(a), sin(a)) * 8.0, m + Vector2(cos(a), sin(a)) * 8.0, col, 1.5)
		"Lumbre":                                # llama dentro de un farol
			c.draw_rect(Rect2(m + Vector2(-9, -11), Vector2(18, 23)), col, false, 2.0)
			c.draw_line(m + Vector2(-5, -15), m + Vector2(5, -15), col, 2.0)
			c.draw_line(m + Vector2(0, -15), m + Vector2(0, -11), col, 2.0)
			var llama := PackedVector2Array([m + Vector2(0, -6), m + Vector2(4, 1), m + Vector2(3, 6), m + Vector2(0, 8),
				m + Vector2(-3, 6), m + Vector2(-4, 1)])
			c.draw_colored_polygon(llama, col)
	return true


# Icono de un estado de héroe (18 px, junto a su nombre en el bloque del grupo). false si no existe.
static func dibujar_estado(c: CanvasItem, estado: String, tam: Vector2) -> bool:
	if not COLOR_ESTADO.has(estado):
		return false
	var col: Color = COLOR_ESTADO[estado]
	var m := tam * 0.5
	var r := minf(tam.x, tam.y) * 0.5
	match estado:
		"barrera":                               # cristal
			var pts := PackedVector2Array([m + Vector2(0, -r), m + Vector2(r * 0.8, -r * 0.3), m + Vector2(r * 0.5, r),
				m + Vector2(-r * 0.5, r), m + Vector2(-r * 0.8, -r * 0.3)])
			c.draw_colored_polygon(pts, Color(col, 0.6))
			pts.append(pts[0])
			c.draw_polyline(pts, col, 1.5)
		"aliento":                               # hoja
			var pts := PackedVector2Array()
			for i in 13:
				var t := float(i) / 12.0
				pts.append(m + Vector2(sin(t * PI) * r * 0.6, lerpf(-r, r, t)))
			for i in range(11, 0, -1):
				var t := float(i) / 12.0
				pts.append(m + Vector2(-sin(t * PI) * r * 0.6, lerpf(-r, r, t)))
			c.draw_colored_polygon(pts, col)
			c.draw_line(m + Vector2(0, -r * 0.8), m + Vector2(0, r), Color(0.1, 0.2, 0.05, 0.8), 1.0)
		"brasa":                                 # llama
			var pts := PackedVector2Array([m + Vector2(0, -r), m + Vector2(r * 0.6, 0), m + Vector2(r * 0.5, r * 0.7),
				m + Vector2(0, r), m + Vector2(-r * 0.5, r * 0.7), m + Vector2(-r * 0.6, 0)])
			c.draw_colored_polygon(pts, col)
			c.draw_circle(m + Vector2(0, r * 0.45), r * 0.3, Color(1.0, 0.9, 0.55))
	return true
