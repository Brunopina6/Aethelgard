extends RefCounted
# Magia negra (V12, fase E, 12/11): seis escuelas asignables con el patrón de artes.gd (familias, niveles, umbrales,
# libros, filas del menú e iconos), pensadas para el cuarto protagonista (Naira, propuesta NO canon:
# docs/v12/NAIRA.md). Hoy no las tiene nadie (DE_HEROE vacío): solo se prueban con el interruptor de desarrollo
# «magia_negra_v12», APAGADO (Engine.set_meta("magia_negra_v12", "Kael") o «-- magia_negra_v12=Kael»), que se las
# da a un héroe de prueba SIN quitarle nada de lo suyo. Lya conserva su magia y no es maga negra.
#
# Lo que no cambia (D-048, D-037): las 12 magias de siempre (MAGIAS y NIVELES_MAGIA de combate.gd) siguen su camino;
# ninguna escuela pasa por _animar_golpe, _lanzar ni _magia_grupal, ni entra en esas tablas. Garon no aprende ninguna.
# Esgrima, Embuir, Érebo, la Armonía, el ATB y los dúos, igual. Los ids de las escuelas («negra_fuego»…) no coinciden
# con los de siempre («Fuego»…): sus libros (grupo.gd «libros») no se pisan.
# Nada de aquí tira del generador aleatorio global: la huella del combate (C0) no cambia por cargar este archivo.
#
# Datos de cada hechizo (HECHIZOS):
#   nombre, coste (PM), dano (como las de siempre: × magia del héroe, combate_formulas.gd), a («enemigo» o «enemigos»),
#   prep (preparación, en barras ATB: 0 = al momento; 0,35 = un tercio de barra más; 0,7 = casi otra barra). Mientras
#   prepara, el héroe tiene el estado «conjuro» y, si recibe de una vez o en varias UMBRAL_ROTURA de sus PV máximos,
#   el conjuro se rompe y pierde los PM (como las cargas interrumpibles de los enemigos, combate.gd _vigilar_carga).
#   forma (su efecto en combate.gd _vfx_negra), estado {tipo, turnos}, quema (rondas de quemadura, la de siempre),
#   saltos (Rayo Encadenado: parte del daño en cada salto), pozo (Pozo Gravitatorio: + por cada otro enemigo),
#   pct / tope_jefe / minimo (Colapso Astral: parte de la vida actual), atb_propio (Aguja Glacial: barra que conserva),
#   atraviesa (no le frena la guardia), rompe_carga (corta siempre un golpe preparado), investigacion (id de
#   datos/investigaciones que hay que completar), mejora (lo que podría mejorar más adelante: sin implementar).

const Afinidades := preload("res://combate_afinidades.gd")

const ESCUELAS := ["negra_fuego", "negra_hielo", "negra_rayo", "negra_sombras", "negra_gravedad", "negra_debilitamiento"]
const NOMBRE_ESCUELA := {"negra_fuego": "Fuego", "negra_hielo": "Hielo", "negra_rayo": "Rayo",
	"negra_sombras": "Sombras", "negra_gravedad": "Gravedad", "negra_debilitamiento": "Debilitamiento",
	"naira_eclipse": "Eclipse"}
const ELEMENTO := {"negra_fuego": "Fuego", "negra_hielo": "Hielo", "negra_rayo": "Rayo", "negra_sombras": "Sombras",
	"negra_gravedad": "Gravedad", "negra_debilitamiento": "", "naira_eclipse": ""}
# Colores propios, distintos de los de siempre (Fuego FF7A3C, Rayo F2E36B) para que no se confundan en pantalla.
const COLOR := {"negra_fuego": Color("E8572A"), "negra_hielo": Color("7FD8FF"), "negra_rayo": Color("B49CFF"),
	"negra_sombras": Color("8A63E0"), "negra_gravedad": Color("C8924A"), "negra_debilitamiento": Color("B9C96A"),
	"naira_eclipse": Color("E8D9A0")}               # oro pálido de corona de eclipse (NAIRA.md §6.1)
const COLOR_NEGRA := Color("A98BE8")              # la pestaña «Magia negra» y su icono
const DESC_ESCUELA := {
	"negra_fuego": "Brasas y soles de ceniza. Queman.",
	"negra_hielo": "Agujas, escarcha y prisiones de hielo. Frenan.",
	"negra_rayo": "Chispas que saltan de un enemigo a otro.",
	"negra_sombras": "Tapan la luz del enemigo: menos fuerza, marcas.",
	"negra_gravedad": "Peso que frena, junta y aplasta.",
	"negra_debilitamiento": "Maldiciones breves: menos defensa, menos resistencia.",
	"naira_eclipse": "Su firma: tapa la luz de todos y los deja en penumbra.",
}
# Para agruparlas más adelante con los nombres de la propuesta de Naira (docs/v12/NAIRA.md: Umbra, Gravedad, Maldición
# y Astros). Solo un dato: hoy no cambia nada. Su magia «tapa y pesa; nunca borra»: ninguna descripción dice borrar.
const GRUPO_NAIRA := {"negra_sombras": "Umbra", "negra_gravedad": "Gravedad", "negra_debilitamiento": "Maldición",
	"negra_fuego": "Astros", "negra_hielo": "Astros", "negra_rayo": "Astros", "naira_eclipse": "Firma"}

# Quién las usa. DE_HEROE: los que las tienen siempre (hoy nadie). DE_RECLUTA (V12, grupo con reserva, 12/11): las de un
# recluta, solo mientras grupo.gd lo tiene disponible (Naira: tras su hito «nr_union» o con el interruptor «naira_v12»,
# APAGADO). Así, sin Naira, nadie sabe magia negra y todo queda como antes.
const DE_HEROE := {}
const PARA_NAIRA := ["negra_fuego", "negra_hielo", "negra_rayo", "negra_sombras", "negra_gravedad", "negra_debilitamiento"]
# V12: la firma de Naira, el Eclipse (NAIRA.md §5.5, PROPUESTA): una «escuela» de un solo hechizo, fuera de ESCUELAS (el
# interruptor de pruebas magia_negra_v12 no la da; las 24 de la fase E no cambian). Va por la misma ruta de la magia
# negra: preparación interrumpible, afinidades, sonido una vez y el estado nuevo «penumbra».
const FIRMAS := ["naira_eclipse"]
const TODAS := ["naira_eclipse", "negra_fuego", "negra_hielo", "negra_rayo", "negra_sombras", "negra_gravedad",
	"negra_debilitamiento"]                          # la firma primero: a mano en la primera página de Naira
const DE_RECLUTA := {"Naira": ["negra_fuego", "negra_hielo", "negra_rayo", "negra_sombras", "negra_gravedad",
	"negra_debilitamiento", "naira_eclipse"]}

const UMBRAL_ROTURA := 0.25                      # parte de sus PV máximos que rompe un conjuro en preparación
const PREP_MAX := 0.9

const HECHIZOS := {
	"negra_fuego": [
		{"nombre": "Ascua", "coste": 5, "dano": 40, "a": "enemigo", "prep": 0.0, "forma": "ascua", "quema": 2,
			"umbral": 1, "mejora": "Ascua doble: dos brasas a enemigos distintos."},
		{"nombre": "Llama Voraz", "coste": 14, "dano": 95, "a": "enemigo", "prep": 0.35, "forma": "llama_voraz",
			"quema": 2, "umbral": 6, "mejora": "Si el enemigo ya arde, la explosión hace más."},
		{"nombre": "Lluvia de Brasas", "coste": 20, "dano": 60, "a": "enemigos", "prep": 0.35, "forma": "lluvia_brasas",
			"quema": 2, "umbral": 10, "mejora": "Más brasas: alarga la quemadura."},
		{"nombre": "Sol de Ceniza", "coste": 38, "dano": 150, "a": "enemigos", "prep": 0.7, "forma": "sol_ceniza",
			"quema": 3, "umbral": 16, "investigacion": "arcano_sol_ceniza",
			"mejora": "Deja el suelo en brasas un turno."}],
	"negra_hielo": [
		{"nombre": "Aguja Glacial", "coste": 5, "dano": 38, "a": "enemigo", "prep": 0.0, "forma": "aguja_glacial",
			"atb_propio": 20.0, "umbral": 1, "mejora": "Dos agujas seguidas."},
		{"nombre": "Escarcha Profunda", "coste": 12, "dano": 55, "a": "enemigo", "prep": 0.0, "forma": "escarcha_profunda",
			"estado": {"tipo": "lento", "turnos": 2}, "umbral": 5, "mejora": "La lentitud dura un turno más."},
		{"nombre": "Prisión de Hielo", "coste": 16, "dano": 20, "a": "enemigo", "prep": 0.35, "forma": "prision_hielo",
			"estado": {"tipo": "prision", "turnos": 1}, "umbral": 9,
			"mejora": "Al romperse, la prisión hace daño."},
		{"nombre": "Invierno Eterno", "coste": 40, "dano": 135, "a": "enemigos", "prep": 0.7, "forma": "invierno_eterno",
			"estado": {"tipo": "lento", "turnos": 2}, "umbral": 17, "investigacion": "arcano_invierno_eterno",
			"mejora": "Congela a los que ya iban lentos."}],
	"negra_rayo": [
		{"nombre": "Chispa", "coste": 4, "dano": 32, "a": "enemigo", "prep": 0.0, "forma": "chispa", "umbral": 1,
			"mejora": "Salta una vez a otro enemigo."},
		{"nombre": "Rayo Encadenado", "coste": 13, "dano": 60, "a": "enemigo", "prep": 0.0, "forma": "rayo_encadenado",
			"saltos": [0.7, 0.5], "umbral": 6, "mejora": "Un salto más."},
		{"nombre": "Tormenta del Cielo Roto", "coste": 22, "dano": 70, "a": "enemigos", "prep": 0.35,
			"forma": "tormenta_cielo_roto", "umbral": 11, "mejora": "Los rayos sobrantes caen sobre el más débil."},
		{"nombre": "Juicio del Relámpago", "coste": 36, "dano": 210, "a": "enemigo", "prep": 0.7,
			"forma": "juicio_relampago", "rompe_carga": true, "umbral": 15, "investigacion": "arcano_juicio_relampago",
			"mejora": "Aturde a quien estaba preparando un golpe."}],
	"negra_sombras": [
		{"nombre": "Aguja Umbría", "coste": 6, "dano": 42, "a": "enemigo", "prep": 0.0, "forma": "aguja_umbria",
			"atraviesa": true, "umbral": 2, "mejora": "Atraviesa también corazas."},
		{"nombre": "Manto del Eclipse", "coste": 15, "dano": 0, "a": "enemigos", "prep": 0.35, "forma": "manto_eclipse",
			"estado": {"tipo": "atk_baja", "turnos": 3}, "umbral": 7, "mejora": "También ralentiza."},
		{"nombre": "Marca del Vacío", "coste": 12, "dano": 0, "a": "enemigo", "prep": 0.0, "forma": "marca_vacio",
			"estado": {"tipo": "marca", "turnos": 3}, "umbral": 10,
			"mejora": "La marca guarda más de lo que recibe."},
		{"nombre": "Noche Absoluta", "coste": 42, "dano": 120, "a": "enemigos", "prep": 0.7, "forma": "noche_absoluta",
			"estado": {"tipo": "res_baja", "turnos": 2}, "umbral": 18, "investigacion": "arcano_noche_absoluta",
			"mejora": "Los enemigos pierden su próximo golpe preparado."}],
	"negra_gravedad": [
		{"nombre": "Peso del Abismo", "coste": 9, "dano": 30, "a": "enemigo", "prep": 0.0, "forma": "peso_abismo",
			"estado": {"tipo": "lento", "turnos": 3}, "umbral": 3, "mejora": "A todos, con menos daño."},
		{"nombre": "Pozo Gravitatorio", "coste": 18, "dano": 50, "a": "enemigos", "prep": 0.35, "forma": "pozo_gravitatorio",
			"pozo": 0.2, "umbral": 8, "mejora": "Los que quedan juntos pierden la guardia."},
		{"nombre": "Colapso Astral", "coste": 40, "dano": 0, "a": "enemigos", "prep": 0.7, "forma": "colapso_astral",
			"pct": 0.25, "tope_jefe": 0.1, "minimo": 40, "umbral": 15, "investigacion": "arcano_colapso_astral",
			"mejora": "Más daño cuanto más lentos estén."}],
	"negra_debilitamiento": [
		{"nombre": "Quebranto", "coste": 5, "dano": 0, "a": "enemigo", "prep": 0.0, "forma": "sello",
			"estado": {"tipo": "def_baja", "turnos": 3}, "umbral": 2, "mejora": "A todos."},
		{"nombre": "Velo Roto", "coste": 7, "dano": 0, "a": "enemigo", "prep": 0.0, "forma": "sello",
			"estado": {"tipo": "res_baja", "turnos": 3}, "umbral": 4, "mejora": "A todos."},
		{"nombre": "Paso Torcido", "coste": 10, "dano": 0, "a": "enemigos", "prep": 0.0, "forma": "sello",
			"estado": {"tipo": "lento", "turnos": 2}, "umbral": 7, "mejora": "También retrasa su barra."},
		{"nombre": "Maldición Menguante", "coste": 9, "dano": 0, "a": "enemigo", "prep": 0.0, "forma": "sello",
			"estado": {"tipo": "maldicion", "turnos": 3}, "umbral": 9, "mejora": "Pasa a otro enemigo si cae."},
		{"nombre": "Herida Elemental", "coste": 14, "dano": 0, "a": "enemigo", "prep": 0.35, "forma": "sello",
			"estado": {"tipo": "vulnerable", "turnos": 3}, "umbral": 12, "investigacion": "arcano_herida_elemental",
			"mejora": "Dura hasta que reciba un golpe débil."}],
	# V12: la firma de Naira (NAIRA.md §5.5: 30 PM, a todos, daño 90, un turno de preparación y «Penumbra» 2 turnos).
	# La forma es la del Manto del Eclipse (un eclipse tapa la luz). Se aprende al unirse (umbral 1).
	"naira_eclipse": [
		{"nombre": "Eclipse", "coste": 30, "dano": 90, "a": "enemigos", "prep": 0.7, "forma": "manto_eclipse",
			"estado": {"tipo": "penumbra", "turnos": 2}, "umbral": 1,
			"mejora": "Observaciones: +10 % cada tres (NAIRA.md §5.5)."}],
}
const DESCRIPCION := {
	"Ascua": "Una brasa rápida a un enemigo. Quema.",
	"Llama Voraz": "Prepara y estalla en un enemigo. Quema.",
	"Lluvia de Brasas": "Prepara y llueven brasas sobre todos. Queman.",
	"Sol de Ceniza": "Prepara mucho: un sol que cae sobre todos y quema tres rondas.",
	"Aguja Glacial": "Rápida: conserva parte de tu barra.",
	"Escarcha Profunda": "Daño y frío: el enemigo va lento dos turnos.",
	"Prisión de Hielo": "Prepara: el enemigo pierde su próximo turno. Los jefes, no.",
	"Invierno Eterno": "Prepara mucho: hielo a todos y los deja lentos.",
	"Chispa": "Barata y al momento. Corta golpes como toda magia.",
	"Rayo Encadenado": "Golpea a uno y salta a dos más (70 % y 50 %).",
	"Tormenta del Cielo Roto": "Prepara: rayos del cielo sobre todos.",
	"Juicio del Relámpago": "Prepara mucho: un rayo enorme. Corta siempre un golpe preparado.",
	"Aguja Umbría": "Sombra que atraviesa la guardia del enemigo.",
	"Manto del Eclipse": "Prepara: tapa su fuerza. Pegan un 25 % menos tres turnos.",
	"Marca del Vacío": "Guarda un 30 % del daño que reciba; al acabar, le pesa. Si cae, pesa a los demás.",
	"Noche Absoluta": "Prepara mucho: oscuridad a todos; su resistencia mágica baja.",
	"Peso del Abismo": "Un peso lo frena: lento tres turnos.",
	"Pozo Gravitatorio": "Prepara: junta a los enemigos; más daño cuantos más haya.",
	"Colapso Astral": "Prepara mucho: un cuarto de su vida actual. A los jefes, menos.",
	"Quebranto": "Defensa ↓: los golpes le hacen un 25 % más (3 turnos).",
	"Velo Roto": "Resistencia mágica ↓: la magia le hace un 25 % más (3 turnos).",
	"Paso Torcido": "Todos los enemigos van lentos dos turnos.",
	"Maldición Menguante": "Cada vez que actúe pierde un poco de vida (3 turnos).",
	"Herida Elemental": "Prepara: lo que resiste deja de resistirlo y lo demás le hace más daño.",
	"Eclipse": "Prepara mucho: tapa la luz de todos. En penumbra, todo les hace un 20 % más (2 turnos).",
}
# Sonido al resolverse (una vez por hechizo, aunque alcance a varios): [la clave que pedirá el especialista de sonido,
# la que existe hoy en sonido.gd y se usa mientras tanto]. combate.gd usa la primera si existe y si no, la segunda.
const SONIDO := {
	"negra_fuego": ["negra_fuego", "brasa"], "negra_hielo": ["negra_hielo", "congelar"],
	"negra_rayo": ["negra_rayo", "golpe_critico"], "negra_sombras": ["negra_sombras", "arte_ocaso"],
	"negra_gravedad": ["negra_gravedad", "arte_ocaso"], "negra_debilitamiento": ["negra_maldicion", "arte_ocaso"],
	"naira_eclipse": ["naira_eclipse", "arte_ocaso"],
}
const SONIDO_FORMA := {"prision_hielo": ["negra_prision", "arte_escarcha"], "invierno_eterno": ["negra_invierno", "arte_escarcha"],
	"sol_ceniza": ["negra_sol_ceniza", "brasa"], "juicio_relampago": ["negra_juicio", "golpe_critico"],
	"colapso_astral": ["negra_colapso", "golpe_critico"], "noche_absoluta": ["negra_noche", "arte_ocaso"]}
const SONIDO_PREPARAR := ["negra_preparar", "embuir"]
const SONIDO_ROTO := ["negra_conjuro_roto", "barrera_rota"]

# Estados nuevos (en el diccionario del luchador, f["mn"] = {tipo: turnos}; acaban con el combate y no se guardan).
# Los turnos se cuentan al empezar el turno de quien lo lleva. Volver a ponerlo renueva, no suma (el mayor).
const ESTADOS := {
	"lento": {"texto": "Lento", "corto": "Lento", "color": Color("8FB8FF"), "vel": 0.6},
	"prision": {"texto": "Prisión de hielo", "corto": "Prisión", "color": Color("BFE6FF")},
	"def_baja": {"texto": "Defensa ↓", "corto": "Def ↓", "color": Color("FF9A6A"), "fisico": 1.25},
	"res_baja": {"texto": "Resistencia mágica ↓", "corto": "Res ↓", "color": Color("C9A6FF"), "magia": 1.25},
	"atk_baja": {"texto": "Ataque ↓", "corto": "Atq ↓", "color": Color("A99BD6"), "ataque": 0.75},
	"marca": {"texto": "Marca del Vacío", "corto": "Marca", "color": Color("8A63E0"), "guarda": 0.3},
	"maldicion": {"texto": "Maldición", "corto": "Maldito", "color": Color("B9C96A"), "pierde": 0.06},
	"vulnerable": {"texto": "Vulnerable", "corto": "Vulnerable", "color": Color("FFC46A")},
	# V12, el Eclipse de Naira (PROPUESTA): golpes y magia le hacen un 20 % más (NAIRA.md dice «los demás héroes»; aquí,
	# por sencillez, también los de Naira: anotado en el informe).
	"penumbra": {"texto": "Penumbra", "corto": "Penumbra", "color": Color("E8D9A0"), "fisico": 1.2, "magia": 1.2},
}
const ORDEN_ESTADOS := ["prision", "lento", "def_baja", "res_baja", "atk_baja", "marca", "maldicion", "vulnerable",
	"penumbra"]


# ================================================================= interruptor de desarrollo (APAGADO)

# El héroe de prueba que recibe las escuelas ("" = nadie, lo normal). Engine «magia_negra_v12» o «-- magia_negra_v12=X».
static func heroe_de_prueba() -> String:
	var m = Engine.get_meta("magia_negra_v12", "")
	if m is String and m != "":
		return m
	for a in OS.get_cmdline_user_args():
		if a.begins_with("magia_negra_v12="):
			return a.substr(16)
	return ""


# Con «magia_negra_v12_todo» (Engine o «-- magia_negra_todo») el héroe de prueba sabe todo (capturas).
static func todo_de_prueba() -> bool:
	return bool(Engine.get_meta("magia_negra_v12_todo", false)) or "magia_negra_todo" in OS.get_cmdline_user_args()


# ================================================================= datos y aprendizaje

static func es_negra(fam: String) -> bool:
	return HECHIZOS.has(fam)


static func datos(fam: String, nv: int) -> Dictionary:
	var lista: Array = HECHIZOS[fam]
	return lista[clampi(nv, 1, lista.size()) - 1]


static func cuantos(fam: String) -> int:
	return HECHIZOS[fam].size()


static func familias_de(heroe: String) -> Array:
	if heroe != "" and heroe == heroe_de_prueba():
		return ESCUELAS.duplicate()
	if DE_RECLUTA.has(heroe) and ResourceLoader.exists("res://grupo.gd") and load("res://grupo.gd").disponible(heroe):
		return DE_RECLUTA[heroe].duplicate()
	return DE_HEROE.get(heroe, [])


# ¿Ya lo desbloqueó una investigación completada? (investigacion.gd: «magia:<escuela>:<nivel>» en su «desbloquea»).
static func _desbloqueado(fam: String, nv: int) -> bool:
	if not HECHIZOS[fam][nv - 1].has("investigacion"):
		return true
	return load("res://investigacion.gd").magia_desbloqueada(fam, nv)


# Nivel (0 a N) que sabe un héroe de una escuela: los hechizos cuyo umbral ya alcanza (o que enseñó un libro: «libros»),
# en orden, hasta el primero que pide una investigación sin completar. Se calcula, no se guarda: una partida antigua
# sin estas claves no sabe nada nuevo, y una con nivel alto lo sabe al cargarla (como las artes).
static func nivel_de(heroe: String, fam: String, d: Dictionary) -> int:
	if not fam in familias_de(heroe):
		return 0
	if heroe == heroe_de_prueba() and todo_de_prueba():
		return cuantos(fam)
	var libro := int(d.get("libros", {}).get(fam, 0))
	var n := 0
	for i in cuantos(fam):
		var h: Dictionary = HECHIZOS[fam][i]
		if int(d.get("nivel", 1)) < int(h["umbral"]) and libro < i + 1:
			break
		if not _desbloqueado(fam, i + 1):
			break
		n += 1
	return n


static func _datos_grupo(heroe: String) -> Dictionary:
	if not ResourceLoader.exists("res://grupo.gd"):
		return {}
	return load("res://grupo.gd").datos().get(heroe, {})


static func nivel(heroe: String, fam: String) -> int:
	return nivel_de(heroe, fam, _datos_grupo(heroe))


# Con la forma de combate.gd _hechizos(): [escuela, nivel, datos].
static func hechizos_de(heroe: String, d: Dictionary) -> Array:
	var r: Array = []
	for fam in familias_de(heroe):
		for i in nivel_de(heroe, fam, d):
			r.append([fam, i + 1, HECHIZOS[fam][i]])
	return r


static func hechizos(heroe: String) -> Array:
	return hechizos_de(heroe, _datos_grupo(heroe))


# Un libro o un tomo enseña un hechizo antes de tiempo (se apunta en «libros», como los de siempre). La investigación
# que pida sigue haciendo falta. false si no usa la escuela o ya lo sabía.
static func aprender_en(heroe: String, fam: String, nv: int, d: Dictionary) -> bool:
	if not fam in familias_de(heroe) or int(d.get("libros", {}).get(fam, 0)) >= nv:
		return false
	if not d.has("libros"):
		d["libros"] = {}
	d["libros"][fam] = clampi(nv, 1, cuantos(fam))
	return true


# Lo que se aprende al subir de «antes» a «ahora» (para el aviso «X aprende…»): [escuela, nivel].
static func nuevas_al_subir(heroe: String, d: Dictionary, antes: int, ahora: int) -> Array:
	var r: Array = []
	for fam in familias_de(heroe):
		var n := nivel_de(heroe, fam, d)
		if n > 0:
			var umbral: int = int(HECHIZOS[fam][n - 1]["umbral"])
			if umbral > antes and umbral <= ahora:
				r.append([fam, n])
	return r


# ================================================================= investigación («estudiar hechizos»)

# investigacion.gd desbloquea con «magia:<escuela>:<nivel>» en el campo «desbloquea» de su .tres (el mismo campo que las
# recetas). ¿Es un desbloqueo de magia que existe?
static func es_desbloqueo(id: String) -> bool:
	return id.begins_with("magia:")


static func desbloqueo_valido(id: String) -> bool:
	var p := id.split(":")
	return p.size() == 3 and p[0] == "magia" and es_negra(p[1]) and p[2].is_valid_int() \
		and int(p[2]) >= 1 and int(p[2]) <= cuantos(p[1])


# El nombre del hechizo que desbloquea (para los talleres): «Sol de Ceniza».
static func nombre_desbloqueo(id: String) -> String:
	if not desbloqueo_valido(id):
		return id
	var p := id.split(":")
	return str(datos(p[1], int(p[2]))["nombre"])


# ================================================================= menú

# Filas de la pestaña «Magia negra»: una por escuela que puede usar (con cuántos hechizos sabe).
static func filas_escuelas(sabe: Dictionary) -> Array:
	var r: Array = []
	for fam in TODAS:                                 # (la firma de Naira, primero; nadie más la sabe)
		if int(sabe.get(fam, 0)) <= 0:
			continue
		r.append({"texto": NOMBRE_ESCUELA[fam], "icono": fam, "escuela": fam,
			"derecha": "%d/%d" % [int(sabe[fam]), cuantos(fam)], "desc": DESC_ESCUELA[fam]})
	return r


# Filas de una escuela: un hechizo por fila, con coste y, si prepara, «◷» delante del coste.
static func filas_escuela(fam: String, nv_usable: int, actor: Dictionary, enemigos: Array, modo_pruebas := false) -> Array:
	var r: Array = []
	var vivos := enemigos.filter(func(e): return e["hp"] > 0 and not e.get("huido", false))
	for n in range(1, mini(nv_usable, cuantos(fam)) + 1):
		var d := datos(fam, n)
		var paga: bool = modo_pruebas or int(actor.get("mp", 0)) >= int(d["coste"])
		var motivo := ""
		if vivos.is_empty():
			motivo = "No hay a quién."
		elif not paga:
			motivo = "Necesitas %d PM: tienes %d." % [int(d["coste"]), int(actor.get("mp", 0))]
		var coste := "PM ∞" if modo_pruebas else "%d PM" % int(d["coste"])
		r.append({"texto": d["nombre"], "icono": fam, "familia": fam, "nivel": n,
			"derecha": ("◷ " if float(d.get("prep", 0.0)) > 0.0 else "") + coste,
			"apagado": motivo != "", "falta_pm": not paga,
			"area_enemigos": d["a"] == "enemigos",
			"desc": motivo if motivo != "" else texto_desc(d)})
	return r


static func texto_desc(d: Dictionary) -> String:
	var t: String = DESCRIPCION.get(d["nombre"], "")
	var p := float(d.get("prep", 0.0))
	if p > 0.0:
		t += " ◷ %s." % ("Larga" if p >= 0.6 else "Prepara")
	return t


# ================================================================= estados

static func turnos(f: Dictionary, tipo: String) -> int:
	return int(f.get("mn", {}).get(tipo, 0))


# Pone un estado (renueva, no suma). Devuelve "" si entra, «resiste» si entra más corto, o «inmune».
static func aplicar_estado(f: Dictionary, tipo: String, n: int) -> String:
	var real := Afinidades.turnos_estado(f, tipo, n)
	var clase := Afinidades.clase_estado(f, tipo)
	if real <= 0:
		return "inmune"
	if not f.has("mn"):
		f["mn"] = {}
	f["mn"][tipo] = maxi(turnos(f, tipo), real)
	if tipo == "marca" and not f["mn"].has("marca_guardado"):
		f["mn"]["marca_guardado"] = 0
	return clase


# Al empezar el turno de quien lleva estados: la Maldición le quita vida, todos bajan un turno y los que llegan a 0 se
# quitan. Devuelve {"maldicion": PV, "marca": PV que estallan (la marca que acaba), "acaban": [tipos], "prision": bool}.
# «prision»: pierde este turno (se gasta aquí).
static func al_empezar_turno(f: Dictionary) -> Dictionary:
	var r := {"maldicion": 0, "marca": 0, "acaban": [], "prision": false}
	if not f.has("mn") or f["hp"] <= 0:
		return r
	var m: Dictionary = f["mn"]
	if int(m.get("prision", 0)) > 0:
		r["prision"] = true
	if int(m.get("maldicion", 0)) > 0:
		r["maldicion"] = maxi(1, int(f["hp_max"] * float(ESTADOS["maldicion"]["pierde"])))
	for tipo in ORDEN_ESTADOS:
		if int(m.get(tipo, 0)) > 0:
			m[tipo] = int(m[tipo]) - 1
			if int(m[tipo]) <= 0:
				m.erase(tipo)
				r["acaban"].append(tipo)
				if tipo == "marca":
					r["marca"] = int(m.get("marca_guardado", 0))
					m.erase("marca_guardado")
	return r


# Lo que guarda la Marca del Vacío de cada golpe que llega a los PV.
static func al_recibir(f: Dictionary, d: int) -> void:
	if d > 0 and turnos(f, "marca") > 0:
		f["mn"]["marca_guardado"] = int(f["mn"].get("marca_guardado", 0)) + int(round(d * float(ESTADOS["marca"]["guarda"])))


# Si el marcado cae, lo guardado pesa sobre los demás enemigos en pie (a partes iguales). Devuelve [[enemigo, PV]].
static func reparto_marca(f: Dictionary, otros: Array) -> Array:
	var r: Array = []
	if not f.has("mn") or not f["mn"].has("marca_guardado"):
		return r
	var total := int(f["mn"]["marca_guardado"])
	f["mn"].erase("marca")
	f["mn"].erase("marca_guardado")
	var vivos := otros.filter(func(e): return not is_same(e, f) and e["hp"] > 0 and not e.get("huido", false))
	if total <= 0 or vivos.is_empty():
		return r
	var parte := maxi(1, int(total / float(vivos.size())))
	for e in vivos:
		r.append([e, parte])
	return r


static func mult_vel(f: Dictionary) -> float:
	return float(ESTADOS["lento"]["vel"]) if turnos(f, "lento") > 0 else 1.0


static func mult_fisico_recibido(f: Dictionary) -> float:
	var m := float(ESTADOS["def_baja"]["fisico"]) if turnos(f, "def_baja") > 0 else 1.0
	if turnos(f, "penumbra") > 0:                   # V12, el Eclipse de Naira
		m *= float(ESTADOS["penumbra"]["fisico"])
	return m


static func mult_magia_recibida(f: Dictionary) -> float:
	var m := float(ESTADOS["res_baja"]["magia"]) if turnos(f, "res_baja") > 0 else 1.0
	if turnos(f, "penumbra") > 0:                   # V12, el Eclipse de Naira
		m *= float(ESTADOS["penumbra"]["magia"])
	return m


static func mult_ataque(f: Dictionary) -> float:
	return float(ESTADOS["atk_baja"]["ataque"]) if turnos(f, "atk_baja") > 0 else 1.0


static func tiene_estados(f: Dictionary) -> bool:
	if not f.has("mn"):
		return false
	for t in ORDEN_ESTADOS:
		if int(f["mn"].get(t, 0)) > 0:
			return true
	return false


# Para la línea de estados encima de la vida del enemigo: «Lento 2», «Def ↓ 3»…
static func textos_estado(f: Dictionary) -> Array:
	var r: Array = []
	if not f.has("mn"):
		return r
	for t in ORDEN_ESTADOS:
		var n := turnos(f, t)
		if n > 0:
			r.append("%s %d" % [ESTADOS[t]["corto"], n])
	return r


# ================================================================= daño

# Daño base de un hechizo sobre un objetivo antes de afinidades: el de siempre (lo calcula combate.gd con
# combate_formulas.gd y lo pasa como «base»), o el Colapso Astral, que es parte de la vida actual (con tope en los jefes).
static func dano_base(d: Dictionary, base: int, f: Dictionary, cuantos_alcanza := 1) -> int:
	if d.has("pct"):
		var x := maxi(int(d.get("minimo", 1)), int(f["hp"] * float(d["pct"])))
		if Afinidades.es_jefe(f):
			x = mini(x, maxi(1, int(f["hp_max"] * float(d["tope_jefe"]))))
		return x
	if d.has("pozo"):
		return int(base * (1.0 + float(d["pozo"]) * maxi(0, cuantos_alcanza - 1)))
	return base


# Afinidad y resistencia mágica ↓. Devuelve {"dano", "clase"} (clase: «debil», «resiste», «inmune» o "").
static func con_afinidad(dano: int, fam: String, f: Dictionary) -> Dictionary:
	var el: String = ELEMENTO.get(fam, "")
	var clase := Afinidades.clase(f, el)
	if clase == "inmune":
		return {"dano": 0, "clase": clase}
	var m := Afinidades.mult(f, el) * mult_magia_recibida(f)
	if dano <= 0:
		return {"dano": 0, "clase": clase}
	return {"dano": maxi(1, int(round(dano * m))), "clase": clase}


# Rayo Encadenado: el primero y, después, los más cercanos al anterior que aún no ha tocado. [[enemigo, parte]].
static func cadena(primero: Dictionary, enemigos: Array, saltos: Array) -> Array:
	var r: Array = [[primero, 1.0]]
	var quedan := enemigos.filter(func(e): return not is_same(e, primero) and e["hp"] > 0 and not e.get("huido", false))
	var ultimo := primero
	for parte in saltos:
		if quedan.is_empty():
			break
		var pos_u: Vector2 = ultimo.get("pos", Vector2.ZERO)
		quedan.sort_custom(func(a, b): return pos_u.distance_squared_to(a.get("pos", Vector2.ZERO)) \
			< pos_u.distance_squared_to(b.get("pos", Vector2.ZERO)))
		ultimo = quedan.pop_front()
		r.append([ultimo, float(parte)])
	return r


# ================================================================= preparación (conjuro de un héroe)

# El héroe empieza a preparar: f["conjuro"] y la barra que le queda. Devuelve la barra con la que se queda (ATB).
static func preparar(f: Dictionary, fam: String, nv: int, objs: Array, atb_max := 100.0) -> float:
	var d := datos(fam, nv)
	f["conjuro"] = {"familia": fam, "nivel": nv, "objs": objs, "recibido": 0}
	return atb_max * (1.0 - clampf(float(d.get("prep", 0.0)), 0.0, PREP_MAX))


# Un golpe al héroe que prepara: suma y devuelve true si rompe el conjuro (y lo quita). Caer también lo rompe.
static func golpe_en_conjuro(f: Dictionary, d: int) -> bool:
	if not f.has("conjuro"):
		return false
	f["conjuro"]["recibido"] = int(f["conjuro"]["recibido"]) + maxi(0, d)
	if f["hp"] <= 0 or int(f["conjuro"]["recibido"]) >= ceili(f["hp_max"] * UMBRAL_ROTURA):
		f.erase("conjuro")
		return true
	return false


# A quién va de verdad al resolverse: los que sigan en pie (si el elegido cayó, el primero que quede).
static func objetivos_al_resolver(d: Dictionary, elegidos: Array, enemigos: Array) -> Array:
	var vivos := enemigos.filter(func(e): return e["hp"] > 0 and not e.get("huido", false))
	if d["a"] == "enemigos":
		return vivos
	for e in elegidos:
		if e["hp"] > 0 and not e.get("huido", false):
			return [e]
	return [vivos[0]] if not vivos.is_empty() else []


static func sonido(fam: String, forma: String, existe: Callable) -> String:
	var par: Array = SONIDO_FORMA.get(forma, SONIDO[fam])
	return par[0] if existe.call(par[0]) else par[1]


static func sonido_de(par: Array, existe: Callable) -> String:
	return par[0] if existe.call(par[0]) else par[1]


# ================================================================= iconos (dibujados por código)

# Icono de una escuela (o «Negra», la pestaña) en un recuadro «tam». false si no es suyo.
static func dibujar_icono(c: CanvasItem, fam: String, tam: Vector2) -> bool:
	if fam != "Negra" and not COLOR.has(fam):
		return false
	var col: Color = COLOR_NEGRA if fam == "Negra" else COLOR[fam]
	var m := tam * 0.5
	match fam:
		"Negra":                                  # eclipse: disco oscuro sobre una corona
			c.draw_circle(m, 13.0, Color(col, 0.9))
			c.draw_circle(m + Vector2(3, -2), 11.0, Color(0.06, 0.04, 0.12))
			c.draw_arc(m, 15.5, 0.0, TAU, 32, Color(col, 0.6), 1.5, true)
		"negra_fuego":                            # sol de brasa con tres lenguas
			c.draw_circle(m + Vector2(0, 4), 7.0, col)
			for i in 3:
				var x := -7.0 + 7.0 * i
				c.draw_colored_polygon(PackedVector2Array([m + Vector2(x - 3.5, 0), m + Vector2(x, -12 - 3 * (i % 2)),
					m + Vector2(x + 3.5, 0)]), col)
		"negra_hielo":                            # aguja de hielo inclinada y su punta
			c.draw_colored_polygon(PackedVector2Array([m + Vector2(-12, 12), m + Vector2(10, -13), m + Vector2(13, -10),
				m + Vector2(-9, 14)]), col)
			c.draw_line(m + Vector2(-6, -6), m + Vector2(6, 6), Color(col, 0.6), 1.5)
			c.draw_line(m + Vector2(-8, 0), m + Vector2(8, 0), Color(col, 0.6), 1.5)
		"negra_rayo":                             # dos chispas unidas por un arco quebrado
			c.draw_circle(m + Vector2(-11, 8), 3.5, col)
			c.draw_circle(m + Vector2(11, -8), 3.5, col)
			c.draw_polyline(PackedVector2Array([m + Vector2(-11, 8), m + Vector2(-3, -3), m + Vector2(2, 4),
				m + Vector2(11, -8)]), col, 2.5)
		"negra_sombras":                          # media luna tapada
			c.draw_circle(m, 12.0, col)
			c.draw_circle(m + Vector2(6, -3), 10.5, Color(0.06, 0.04, 0.12))
		"negra_gravedad":                         # anillos que se cierran sobre un punto
			c.draw_arc(m, 13.0, 0.0, TAU, 28, col, 1.5, true)
			c.draw_arc(m, 8.5, 0.0, TAU, 24, col, 2.0, true)
			c.draw_circle(m, 3.5, col)
			c.draw_line(m + Vector2(0, -16), m + Vector2(0, -9), col, 2.0)
		"naira_eclipse":                          # V12: eclipse total, el disco oscuro dentro de su corona
			c.draw_arc(m, 13.5, 0.0, TAU, 32, col, 2.5, true)
			c.draw_circle(m, 11.0, Color(0.06, 0.04, 0.12))
			for i in 8:
				var a := TAU * i / 8.0
				c.draw_line(m + Vector2.from_angle(a) * 15.0, m + Vector2.from_angle(a) * 18.5, Color(col, 0.7), 1.5)
		"negra_debilitamiento":                   # sello con una flecha hacia abajo
			c.draw_arc(m, 13.0, 0.0, TAU, 28, col, 2.0, true)
			c.draw_line(m + Vector2(0, -8), m + Vector2(0, 8), col, 2.5)
			c.draw_colored_polygon(PackedVector2Array([m + Vector2(-6, 3), m + Vector2(6, 3), m + Vector2(0, 10)]), col)
	return true
