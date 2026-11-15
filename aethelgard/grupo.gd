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
	# V12: Naira, la Astrónoma del Eclipse (PROPUESTA, NO CANON: docs/v12/NAIRA.md §5.2). Solo existe en una partida
	# tras su hito («nr_union») o con el interruptor de desarrollo «naira_v12» (APAGADO): ver disponible(). No aprende
	# ninguna de las 12 magias de siempre: su magia va por magia_negra.gd (las seis escuelas y su firma, el Eclipse).
	# La defensa más baja, la magia más alta y PM que hay que administrar (hechizos caros). Golpe físico flojo (0,3).
	"Naira": {"clase": "Astrónoma", "arma": "cetro", "mult_fisico": 0.3, "mult_magia": 1.0, "magias": [],
		"atributos": {"fuerza": 5, "magia": 18, "defensa": 3, "velocidad": 19, "vitalidad": 6, "espiritu": 12},
		"provisional": true},
	# V12: Nix, cuarta heroína y maga negra (PROTOTIPO: docs/v12/NIX_V12.md; especificación del usuario
	# Aethelgard_Nix_Maga_Negra.pdf). Solo con el interruptor de desarrollo «nix_v12» (APAGADO): ver disponible(). Su
	# magia va por magia_negra.gd (piloto de tres hechizos y su Eclipse de sellos). No invoca. PV y defensa algo por
	# debajo de Kael (≈ 87 % y 83 %: 104 y 5 frente a 120 y 6), la magia más alta del grupo; golpe físico flojo (0,3).
	# Si sustituye a Naira o conviven lo decide el usuario.
	"Nix": {"clase": "Maga negra", "arma": "cetro", "mult_fisico": 0.3, "mult_magia": 1.0, "magias": [],
		"atributos": {"fuerza": 5, "magia": 18, "defensa": 5, "velocidad": 20, "vitalidad": 8, "espiritu": 14},
		"provisional": true},
}
# Los tres de siempre: tienen datos en toda partida (datos() los crea si faltan, como siempre) y son el grupo cuando
# la partida no dice nada («grupo_activo»). No cambia: las regiones 3D la leen para crear a los acompañantes.
const EN_EL_GRUPO := ["Kael", "Lya", "Garon"]

# ---------------------------------------------------------------- V12: grupo con reserva (12/11)
# «Miembros del grupo» (en_el_grupo): quién va con el grupo. «Activos» (activos): los que exploran y combaten,
# MAX_ACTIVOS como mucho. «Reserva» (reserva): los miembros que no son activos; conservan sus datos, se curan con el
# grupo y ganan PARTE_EXP_RESERVA de la experiencia de los combates ganados. Los AUSENTES (aún no se han unido, como Lya
# antes de PV-03) no son miembros ni reserva: sus datos esperan sin cambiar.
# Compatibilidad: sin «grupo_activo» (la versión estable y las partidas de antes) los activos son los tres de siempre;
# sin «grupo_miembros» (todas las partidas de antes de la reserva) los miembros son los activos. Con solo los tres de
# siempre nunca hay reserva («grupo_miembros» ni se escribe): el juego es exactamente el de antes.
const RECLUTAS := ["Naira", "Nix"]               # los que se unen después (detrás de un hito o de un interruptor)
const ORDEN := ["Kael", "Lya", "Garon", "Naira", "Nix"]   # orden de los menús, del combate y de la fila en la exploración
const MAX_ACTIVOS := 3                           # preferencia del usuario: tres combatientes y reservas
# V12 (15/11): SOLO en el banco de pruebas de Auditoría (banco_pruebas.gd, caso «Grupo de cuatro»), un permiso de sesión
# deja cuatro activos para probar el combate con Nix. El usuario no ha decidido si el grupo pasa a cuatro: MAX_ACTIVOS,
# la incorporación, la Formación, los menús y la exploración siguen con tres (docs/v12/NIX_GRUPO_CUATRO.md).
const MAX_ACTIVOS_BANCO := 4
const META_GRUPO4 := "banco_grupo4"


# Cuántos activos caben ahora: MAX_ACTIVOS, salvo con el permiso de sesión del banco (su meta Y la del banco, y solo en
# la APK de Auditoría o en el editor). Ninguna partida guarda esas metas.
static func max_activos() -> int:
	if bool(Engine.get_meta(META_GRUPO4, false)) and bool(Engine.get_meta("banco_pruebas", false)) \
			and (OS.has_feature("auditoria") or OS.has_feature("editor")):
		return MAX_ACTIVOS_BANCO
	return MAX_ACTIVOS
# NAIRA.md §4.6 propone «Kael siempre activo» (protagonista, brazalete, escenas fijas). Pendiente del usuario: con
# false, la Formación deja pasar a Kael a la reserva.
const KAEL_SIEMPRE_ACTIVO := true
# Parte de la experiencia que gana la reserva al ganar un combate (NAIRA.md §4.6, «la mitad» [D]; pendiente).
const PARTE_EXP_RESERVA := 0.5
# Nivel con el que llega un recluta. La nivelación automática al unirse sigue retirada (D-062, pendiente): llega al 1,
# con su plantilla, y progreso.gd le da más experiencia mientras vaya por debajo del nivel de la zona.
const NIVEL_AL_UNIRSE := 1
# Crecimiento recomendado (NAIRA.md §5.2): 3 puntos por nivel, alternando las dos listas. Solo lo usa el botón
# «Repartir» de su ficha (menú Grupo); los puntos se siguen pudiendo repartir a mano como siempre.
const CRECIMIENTO := {"Naira": [["magia", "espiritu", "velocidad"], ["magia", "espiritu", "vitalidad"]],
	"Nix": [["magia", "espiritu", "velocidad"], ["magia", "vitalidad", "espiritu"]]}   # V12, Nix (prototipo)
# Interruptor de desarrollo de Naira (APAGADO): Engine «naira_v12» = true o el argumento «-- naira_v12».
const NAIRA_POR_DEFECTO := false
# V12: interruptor de desarrollo de Nix (APAGADO): Engine «nix_v12» = true o el argumento «-- nix_v12». Con él puede
# unirse (Grupo.unir("Nix")); sin él no existe en ninguna partida ni combate.
const NIX_POR_DEFECTO := false


static func nix_v12() -> bool:
	if Engine.has_meta("nix_v12"):
		return bool(Engine.get_meta("nix_v12"))
	# V12 (14/11): y, SOLO en la APK de Auditoría o en el editor, la opción de Ajustes ([calidad_pruebas] nix_v12)
	return "nix_v12" in OS.get_cmdline_user_args() or NIX_POR_DEFECTO \
		or load("res://prototipos/calidad_proto.gd").extra_activo("nix_v12")


static func naira_v12() -> bool:
	if Engine.has_meta("naira_v12"):
		return bool(Engine.get_meta("naira_v12"))
	return "naira_v12" in OS.get_cmdline_user_args() or NAIRA_POR_DEFECTO


# ¿Existe este héroe en esta partida y en esta versión? Los tres de siempre, sí; un recluta, solo tras su hito o con su
# interruptor. Si una partida trae sus datos sin eso, se conservan, pero no sale en ningún sitio.
static func disponible(n: String) -> bool:
	if n in EN_EL_GRUPO:
		return true
	if not n in RECLUTAS:
		return false
	if n == "Naira" and naira_v12():
		return true
	if n == "Nix":                                 # V12: Nix no tiene hito todavía: solo su interruptor
		return nix_v12()
	return SE_UNE_EN.has(n) and load("res://progreso.gd").hito(SE_UNE_EN[n])


static func datos() -> Dictionary:
	if not Engine.has_meta("grupo"):
		Engine.set_meta("grupo", {})
	var g: Dictionary = Engine.get_meta("grupo")
	for n in EN_EL_GRUPO:                          # también entra en partidas guardadas antes de que llegara
		if not g.has(n):                           # (solo los de siempre: un recluta nace al unirse, en unir())
			var nivel := 1
			for otro in g:                         # llega al nivel medio del grupo
				nivel = maxi(nivel, int(g[otro]["nivel"]))
			var a: Dictionary = HEROES[n]["atributos"].duplicate()
			g[n] = {"nivel": nivel, "exp": 0, "puntos": (nivel - 1) * PUNTOS_POR_NIVEL, "atributos": a, "pv": -1, "pm": -1}
	return g


# Los héroes con datos en esta partida que existen en esta versión (los de siempre y los reclutas disponibles), en
# ORDEN. No dice quién va con el grupo: eso es en_el_grupo().
static func miembros() -> Array:
	var g := datos()
	return ORDEN.filter(func(n): return g.has(n) and disponible(n))


# ---------------------------------------------------------------- quién está ahora en el grupo
# El grupo ACTIVO es el que explora, combate y sale en los menús y en la tienda. Lo guarda la partida («grupo_activo»):
# en la versión experimental, la misión de Pastos Verdes empieza con Kael solo, Lya se une en PV-03 y Garon en PV-05
# (zonas3d/pastos_verdes_3d.gd). Sin esa clave (la versión estable y las partidas de antes de que existiera) están
# los tres de siempre, como siempre. Los datos de los ausentes (nivel, equipo, vida) se conservan: solo no participan.
const SE_UNE_EN := {"Lya": "pv_03", "Garon": "pv_05", "Naira": "nr_union"}


static func activos() -> Array:
	var todos := miembros()
	if not Engine.has_meta("grupo_activo"):
		return EN_EL_GRUPO.filter(func(n): return n in todos)   # los de siempre (un recluta hay que unirlo)
	var a: Array = Engine.get_meta("grupo_activo")
	var r: Array = ORDEN.filter(func(n): return n in a and n in todos)
	if r.size() > max_activos():                   # (una partida tocada a mano): los primeros, Kael delante
		r = r.slice(0, max_activos())             # (V12: cuatro solo con el permiso de sesión del banco)
	return r if not r.is_empty() else ["Kael"]       # nunca sin nadie


# Quién va con el grupo: los activos y la reserva («grupo_miembros»; sin la clave, solo los activos). Los activos están
# siempre, aunque una versión antigua haya cambiado «grupo_activo» sin conocer «grupo_miembros».
static func en_el_grupo() -> Array:
	var a := activos()
	if not Engine.has_meta("grupo_miembros"):
		return a
	var m: Array = Engine.get_meta("grupo_miembros")
	var todos := miembros()
	return ORDEN.filter(func(n): return n in a or (n in m and n in todos))


static func reserva() -> Array:
	var a := activos()
	return en_el_grupo().filter(func(n): return not n in a)


# Fija activos y miembros. «grupo_miembros» solo se guarda si hay reserva: sin ella, la partida queda como antes.
static func _poner(act: Array, miem: Array) -> void:
	var a: Array = ORDEN.filter(func(n): return n in act)
	var m: Array = ORDEN.filter(func(n): return n in miem or n in a)
	Engine.set_meta("grupo_activo", a)
	if m == a:
		if Engine.has_meta("grupo_miembros"):
			Engine.remove_meta("grupo_miembros")
	else:
		Engine.set_meta("grupo_miembros", m)


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
	if Engine.has_meta("grupo_miembros"):
		Engine.remove_meta("grupo_miembros")


# Alguien se une al grupo (en la misión: Lya en PV-03 y Garon en PV-05; Naira, tras su hito o con su interruptor). Entra
# entre los activos si hay sitio (MAX_ACTIVOS) y, si no, en la reserva. Conserva sus datos tal cual (nivel,
# experiencia, atributos, vida y PM) y sube como siempre en el juego: con la experiencia de los combates en que lucha
# (progreso.gd da más a quien va por debajo del nivel de la zona). Subirlo al nivel del grupo al unirse es una
# propuesta pendiente del usuario (DECISIONS.md, D-062). Un recluta que no tenía datos nace aquí (NIVEL_AL_UNIRSE, su
# plantilla y su equipo inicial: inventario.gd). API para la misión de Naira: Grupo.unir("Naira").
# Devuelve «activo», «reserva» o "" (no se une: no existe, no está disponible o ya iba con el grupo).
static func unir(n: String) -> String:
	if not n in ORDEN or not disponible(n):
		return ""
	if n in RECLUTAS and not datos().has(n):
		_crear_recluta(n)
	if n in en_el_grupo():
		return ""
	if not Engine.has_meta("grupo_activo"):
		if n in EN_EL_GRUPO:
			return ""                              # versión estable: los de siempre ya están todos
		Engine.set_meta("grupo_activo", activos()) # se fija el grupo de siempre antes de añadir a alguien más
	var a := activos()
	var m := en_el_grupo()
	m.append(n)
	var donde := "reserva"
	if a.size() < MAX_ACTIVOS:
		a.append(n)
		donde = "activo"
	_poner(a, m)
	return donde


static func _crear_recluta(n: String) -> void:
	var nivel := clampi(NIVEL_AL_UNIRSE, 1, NIVEL_MAX)
	datos()[n] = {"nivel": nivel, "exp": 0, "puntos": (nivel - 1) * PUNTOS_POR_NIVEL,
		"atributos": HEROES[n]["atributos"].duplicate(), "pv": -1, "pm": -1}
	if ResourceLoader.exists("res://inventario.gd"):
		load("res://inventario.gd").preparar_recluta(n)


# ---------------------------------------------------------------- Formación (menú Grupo, fuera del combate)

# Por qué no se puede poner esta formación ("" si se puede).
static func motivo_formacion(lista: Array) -> String:
	var m := en_el_grupo()
	for n in lista:
		if not n in m:
			return "%s no va con el grupo" % n
	if lista.is_empty():
		return "Hace falta al menos un héroe"
	if lista.size() > MAX_ACTIVOS:
		return "Solo caben %d en el grupo activo" % MAX_ACTIVOS
	if KAEL_SIEMPRE_ACTIVO and "Kael" in m and not "Kael" in lista:
		return "Kael va siempre en el grupo"
	return ""


# Pone los activos (de entre los miembros). Devuelve "" si se pudo o el motivo.
static func formar(lista: Array) -> String:
	var motivo := motivo_formacion(lista)
	if motivo == "":
		_poner(lista, en_el_grupo())
	return motivo


# Pasa a un héroe de los activos a la reserva o al revés (el botón de la Formación). "" si se pudo o el motivo.
static func alternar(n: String) -> String:
	var a := activos()
	if n in a:
		a.erase(n)
	else:
		a.append(n)
	return formar(a)


# Cambia a uno de los activos por uno de la reserva (ocupa su puesto). "" si se pudo o el motivo.
static func cambiar(activo: String, de_reserva: String) -> String:
	var a := activos()
	if not activo in a or not de_reserva in reserva():
		return "No se puede cambiar a %s por %s" % [activo, de_reserva]
	a[a.find(activo)] = de_reserva
	return formar(a)


# ¿Hace falta la Formación? (alguien en la reserva, o más miembros que sitios)
static func hay_formacion() -> bool:
	var m := en_el_grupo()
	return m.size() > MAX_ACTIVOS or not reserva().is_empty()


# Gasta los puntos de un héroe con su crecimiento recomendado (CRECIMIENTO). Devuelve cuántos gastó.
static func repartir_recomendado(heroe: String) -> int:
	if not CRECIMIENTO.has(heroe) or not datos().has(heroe):
		return 0
	var h: Dictionary = datos()[heroe]
	var gastados := 0
	while int(h["puntos"]) > 0:
		var plan: Array = CRECIMIENTO[heroe][(gastados / PUNTOS_POR_NIVEL) % 2]
		if not subir_atributo(heroe, plan[gastados % plan.size()]):
			break
		gastados += 1
	return gastados


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
		var mj: Dictionary = inv.datos().get("mejoras", {}).get(heroe, {})   # mejoras de su taller (V9: oficios)
		for k in mj:
			if k == "ataque":
				ataque += int(mj[k])
			else:
				a[k] = a.get(k, 0) + int(mj[k])
	if ResourceLoader.exists("res://equipo_extra.gd"):   # Hoja sin Nombre (C2): +1 de ataque por recuerdo visto
		var X = load("res://equipo_extra.gd")
		ataque += X.ataque_recuerdo(X.efectos_de(heroe), Engine.get_meta("lore_visto", {}))
	# V12, Firmamento de los Ecos (firmamento/orbes.gd; interruptor «orbes_v12», APAGADO): los nodos desbloqueados se
	# suman aquí, al vuelo, a los atributos finales (nunca a los guardados). Apagado o sin nodos, bonos() da {}.
	if ResourceLoader.exists("res://firmamento/orbes.gd"):
		var bo: Dictionary = load("res://firmamento/orbes.gd").bonos(heroe)
		for k in bo.get("atributos", {}):
			a[k] = a.get(k, 0) + int(bo["atributos"][k])
		ataque += int(bo.get("ataque", 0))
		magia_extra += int(bo.get("magia_extra", 0))
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


static func curar_todos() -> void:                # los que van con el grupo, reserva incluida (los ausentes no cambian)
	for n in en_el_grupo():
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
