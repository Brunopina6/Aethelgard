extends RefCounted
# Grupo de héroes (Godot 4.x): nivel, experiencia, atributos, puntos para mejorarlos,
# PV/PM actuales y magias aprendidas. Se guarda en Engine.get_meta("grupo") para que dure
# al cambiar de escena (igual que inventario.gd, que guarda los objetos y el equipo).
# Uso desde otro script:  load("res://grupo.gd").estadisticas("Kael")...

const ATRIBUTOS := ["fuerza", "magia", "defensa", "velocidad", "vitalidad", "espiritu"]
const NOMBRES := {"fuerza": "Fuerza", "magia": "Magia", "defensa": "Defensa", "velocidad": "Velocidad",
	"vitalidad": "Vitalidad", "espiritu": "Espíritu"}
const AYUDA := {"fuerza": "+1 de daño con el arma", "magia": "+2,5 % de daño con las magias",
	"defensa": "-1 al daño recibido cada 2 puntos", "velocidad": "la barra ATB se llena antes",
	"vitalidad": "+8 PV máximos", "espiritu": "+3 PM máximos"}
const PUNTOS_POR_NIVEL := 3
const NIVEL_MAX := 50
# Nivel del personaje con el que aprende el nivel I, II y III de cada magia.
const NIVEL_MAGIA := [1, 5, 10]

# "arma" = qué tipo de arma puede llevar (espada o cetro).
# "mult_fisico" / "mult_magia" multiplican el daño de sus golpes y de sus magias. Ajustados para que,
# con su equipo inicial, el golpe de Kael sea 5 veces el de Lya y la magia de Lya 3 veces la de Kael.
const HEROES := {
	"Kael": {"clase": "Espadachín", "arma": "espada", "mult_fisico": 1.0, "mult_magia": 0.46, "magias": ["Fuego", "Rayo"],
		"atributos": {"fuerza": 18, "magia": 4, "defensa": 6, "velocidad": 22, "vitalidad": 10, "espiritu": 4}},
	"Lya": {"clase": "Maga blanca", "arma": "cetro", "mult_fisico": 0.36, "mult_magia": 1.0, "magias": ["Cura", "Agua", "Fuego", "Rayo"],
		"atributos": {"fuerza": 8, "magia": 14, "defensa": 4, "velocidad": 26, "vitalidad": 5, "espiritu": 12}},
	"Nyx": {"clase": "Mago negro", "arma": "cetro", "magias": ["Fuego", "Agua", "Rayo"],
		"atributos": {"fuerza": 6, "magia": 18, "defensa": 3, "velocidad": 24, "vitalidad": 5, "espiritu": 14}},
	"Garon": {"clase": "Tanque", "arma": "espada", "magias": [],
		"atributos": {"fuerza": 16, "magia": 2, "defensa": 12, "velocidad": 16, "vitalidad": 16, "espiritu": 2}},
}
const EN_EL_GRUPO := ["Kael", "Lya", "Garon"]


static func datos() -> Dictionary:
	if not Engine.has_meta("grupo"):
		Engine.set_meta("grupo", {})
	var g: Dictionary = Engine.get_meta("grupo")
	for n in EN_EL_GRUPO:                          # también entra en partidas guardadas antes de que llegara
		if not g.has(n):
			var nivel := 1
			for otro in g:                         # llega al nivel medio del grupo
				nivel = maxi(nivel, int(g[otro]["nivel"]))
			var a: Dictionary = HEROES[n]["atributos"].duplicate()
			g[n] = {"nivel": nivel, "exp": 0, "puntos": (nivel - 1) * PUNTOS_POR_NIVEL, "atributos": a, "pv": -1, "pm": -1}
	return g


static func miembros() -> Array:
	return datos().keys()


# ---------------------------------------------------------------- quién está ahora en el grupo
# El grupo ACTIVO es el que explora, combate y sale en los menús y en la tienda. Lo guarda la partida («grupo_activo»):
# en la versión experimental, la misión de Pastos Verdes empieza con Kael solo, Lya se une en PV-03 y Garon en PV-05
# (zonas3d/pastos_verdes_3d.gd). Sin esa clave (la versión estable y las partidas de antes de que existiera) están
# todos, como siempre. Los datos de los ausentes (nivel, equipo, vida) se conservan: solo no participan.
const SE_UNE_EN := {"Lya": "pv_03", "Garon": "pv_05"}


static func activos() -> Array:
	var todos := miembros()
	if not Engine.has_meta("grupo_activo"):
		return todos
	var a: Array = Engine.get_meta("grupo_activo")
	var r: Array = EN_EL_GRUPO.filter(func(n): return n in a and n in todos)
	return r if not r.is_empty() else ["Kael"]       # nunca sin nadie


# El grupo que corresponde a la misión de Pastos Verdes según sus hitos: Kael, Lya desde PV-03 y Garon desde PV-05.
static func segun_mision() -> Array:
	var P = load("res://progreso.gd")
	var r: Array = ["Kael"]
	for n in ["Lya", "Garon"]:
		if P.hito(SE_UNE_EN[n]):
			r.append(n)
	return r


# La misión empieza con Kael solo (partida nueva de la versión experimental, o una de antes que llega a la misión).
static func empezar_solo() -> void:
	Engine.set_meta("grupo_activo", ["Kael"])


# Alguien se une al grupo activo (en la misión: Lya en PV-03 y Garon en PV-05). Conserva sus datos tal cual (nivel,
# experiencia, atributos, vida y PM) y sube como siempre en el juego: con la experiencia de los combates en que lucha
# (progreso.gd da más a quien va por debajo del nivel de la zona). Subirlo al nivel del grupo al unirse es una
# propuesta pendiente del usuario (DECISIONS.md, D-062).
static func unir(n: String) -> void:
	if not Engine.has_meta("grupo_activo") or n in Engine.get_meta("grupo_activo") or not n in EN_EL_GRUPO:
		return
	var a: Array = Engine.get_meta("grupo_activo").duplicate()
	a.append(n)
	Engine.set_meta("grupo_activo", EN_EL_GRUPO.filter(func(x): return x in a))


# Experiencia que hace falta para pasar del nivel n al n + 1.
static func exp_para(n: int) -> int:
	return int(20.0 * pow(n, 1.5))


# Atributos finales (con el equipo) y valores de combate de un héroe.
static func estadisticas(heroe: String) -> Dictionary:
	var h: Dictionary = datos()[heroe]
	var a: Dictionary = h["atributos"].duplicate()
	var ataque := 0
	var magia_extra := 0
	if ResourceLoader.exists("res://inventario.gd"):
		var inv = load("res://inventario.gd")
		for id in inv.equipo_de(heroe).values():
			var o: Dictionary = inv.objeto(id)
			ataque += int(o.get("ataque", 0))
			magia_extra += int(o.get("magia", 0))
			for k in o.get("bonus", {}):
				a[k] = a.get(k, 0) + o["bonus"][k]
	if ResourceLoader.exists("res://equipo_extra.gd"):   # Hoja sin Nombre (C2): +1 de ataque por recuerdo visto
		var X = load("res://equipo_extra.gd")
		ataque += X.ataque_recuerdo(X.efectos_de(heroe), Engine.get_meta("lore_visto", {}))
	var nivel: int = h["nivel"]
	var e := {"nivel": nivel, "atributos": a,
		"pv_max": 40 + a["vitalidad"] * 8 + (nivel - 1) * 6,
		"pm_max": 4 + a["espiritu"] * 3 + (nivel - 1) * 2,
		"ataque": a["fuerza"] + ataque,
		"magia_mult": 1.0 + a["magia"] * 0.025,
		"magia_extra": magia_extra,
		"defensa": a["defensa"],
		"velocidad": float(a["velocidad"]),
		"mult_fisico": float(HEROES[heroe].get("mult_fisico", 1.0)),
		"mult_magia": float(HEROES[heroe].get("mult_magia", 1.0))}
	if h["pv"] < 0:                                # al empezar, con la vida llena
		h["pv"] = e["pv_max"]
		h["pm"] = e["pm_max"]
	e["pv"] = mini(h["pv"], e["pv_max"])
	e["pm"] = mini(h["pm"], e["pm_max"])
	return e


static func guardar_vida(heroe: String, pv: int, pm: int) -> void:
	datos()[heroe]["pv"] = pv
	datos()[heroe]["pm"] = pm


static func curar_todos() -> void:                # los que están ahora en el grupo (los ausentes no cambian)
	for n in activos():
		var e := estadisticas(n)
		guardar_vida(n, e["pv_max"], e["pm_max"])


static func subir_atributo(heroe: String, atributo: String) -> bool:
	var h: Dictionary = datos()[heroe]
	if h["puntos"] <= 0:
		return false
	h["puntos"] -= 1
	h["atributos"][atributo] += 1
	return true


# Suma experiencia. Devuelve cuántos niveles ha subido (al subir se cura del todo).
static func ganar_exp(heroe: String, cantidad: int) -> int:
	var h: Dictionary = datos()[heroe]
	h["exp"] += cantidad
	var subidos := 0
	while h["nivel"] < NIVEL_MAX and h["exp"] >= exp_para(h["nivel"]):
		h["exp"] -= exp_para(h["nivel"])
		h["nivel"] += 1
		h["puntos"] += PUNTOS_POR_NIVEL
		subidos += 1
	if subidos > 0:
		var e := estadisticas(heroe)
		guardar_vida(heroe, e["pv_max"], e["pm_max"])
	return subidos


# Nivel (0 a 3) que tiene un héroe en una magia según su nivel de personaje.
static func nivel_magia(heroe: String, magia: String) -> int:
	if not magia in HEROES[heroe]["magias"]:
		return 0
	var n := 0
	for umbral in NIVEL_MAGIA:
		if datos()[heroe]["nivel"] >= umbral:
			n += 1
	return maxi(n, int(datos()[heroe].get("libros", {}).get(magia, 0)))   # los libros de la tienda la enseñan antes


# Aprende un nivel de magia con un libro de la tienda. Devuelve false si ya lo sabía.
static func aprender(heroe: String, magia: String, nivel: int) -> bool:
	if not magia in HEROES[heroe]["magias"] or nivel_magia(heroe, magia) >= nivel:
		return false
	if not datos()[heroe].has("libros"):
		datos()[heroe]["libros"] = {}
	datos()[heroe]["libros"][magia] = nivel
	return true


static func tipo_arma(heroe: String) -> String:
	return HEROES[heroe]["arma"]
