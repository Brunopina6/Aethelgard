extends RefCounted
# Afinidades de los enemigos (V12, fase E, 12/11): qué les hace más daño, menos o nada, y qué estados no les entran.
# Datos y consultas, sin escena. Lo usa magia_negra.gd (las escuelas de magia negra) y, a través de él, combate.gd.
#
# Lo que NO cambia (D-048, la huella C0 de prueba_combate_huella): las 12 magias de siempre, los golpes físicos, Esgrima,
# Embuir, Érebo y los dúos no leen esta tabla. Solo las escuelas nuevas. Si algún día se quiere que también la lean
# las de siempre, es una decisión del usuario (cambia el equilibrio y la huella): APLICAR_A_LAS_DE_SIEMPRE.
# Los ganchos de cada jefe (combate_bosque.gd, combate_coloso.gd, combate_bramavidrio.gd) siguen siendo suyos: esta tabla
# se suma a ellos, no los sustituye. Por eso el Guardián del Bosque no repite aquí su debilidad al fuego de la fase 2
# (la pone combate_bosque.gd a las de siempre): aquí la tiene en las dos fases para las escuelas nuevas.
#
# Elementos: Fuego, Hielo, Rayo, Sombras y Gravedad (las escuelas de magia negra). Debilitamiento no tiene elemento.
# Estados: lento, prision, def_baja, res_baja, atk_baja, marca, maldicion y vulnerable (magia_negra.gd, ESTADOS).
# Nada de aquí tira del generador aleatorio: la huella del combate no cambia por consultarla.

const APLICAR_A_LAS_DE_SIEMPRE := false

const DEBIL := 1.5
const RESISTE := 0.5
const INMUNE := 0.0
# Con «Resiste» a un estado, dura la mitad (redondeando hacia arriba): un turno de Prisión se queda en uno.
const TEXTO := {"debil": "Débil", "resiste": "Resiste", "inmune": "Inmune"}
const COLOR := {"debil": Color("FFC46A"), "resiste": Color("A9B8CC"), "inmune": Color("8A8F99")}

# Por enemigo (la clave de combate.gd ENEMIGOS): elementos débiles, resistidos e inmunes, y estados resistidos e inmunes.
# «por qué»: una frase para el Diario y el informe (no sale en combate).
const TABLA := {
	"slime": {"debil": ["Hielo", "Rayo"], "resiste": ["Gravedad"], "inmune": [],
		"estados_resiste": [], "estados_inmune": [],
		"por_que": "Gelatina: el frío la endurece y el rayo la recorre entera; el peso se le escurre."},
	"grimfang": {"debil": ["Fuego"], "resiste": ["Sombras"], "inmune": [],
		"estados_resiste": [], "estados_inmune": [],
		"por_que": "Pelaje seco que prende; vive en cuevas y ve en la penumbra."},
	"zarzalin": {"debil": ["Fuego"], "resiste": ["Rayo"], "inmune": [],
		"estados_resiste": [], "estados_inmune": [],
		"por_que": "Zarza viva: arde; la tierra húmeda de sus pezuñas descarga el rayo."},
	"guardian": {"debil": ["Gravedad"], "resiste": ["Fuego", "Hielo"], "inmune": [],
		"estados_resiste": ["lento"], "estados_inmune": ["prision"],
		"por_que": "Piedra tallada: ni el fuego ni el hielo la cambian; su propio peso la agrieta."},
	"golem_ambar": {"debil": ["Hielo"], "resiste": ["Fuego"], "inmune": ["Rayo"],
		"estados_resiste": [], "estados_inmune": [],
		"por_que": "El ámbar aísla del rayo y aguanta el calor; el frío lo vuelve quebradizo."},
	# V12, bestiario (13/11; propuesta coherente con su ficha de docs/v12/BESTIARIO_V12.md, revisable por el usuario)
	"peon_linde": {"debil": ["Fuego"], "resiste": ["Gravedad"], "inmune": [],
		"estados_resiste": [], "estados_inmune": [],
		"por_que": "Barro seco y fibras: el fuego lo cuartea; pegado a la tierra, el peso apenas lo mueve."},
	"velador_corteza": {"debil": ["Fuego"], "resiste": ["Hielo", "Rayo"], "inmune": [],
		"estados_resiste": ["lento", "def_baja"], "estados_inmune": ["prision"],
		"por_que": "Leño vivo: arde; la savia aguanta el frío y la madera no conduce el rayo; con raíces, no se le encierra."},
	# V12 (14/11), meshy_e01 Custodio de Porcelana (piloto, APAGADO): el paquete de los cuatro enemigos NO trae
	# afinidades; fila NEUTRA hasta que el usuario las decida (no se inventan).
	"meshy_e01": {"debil": [], "resiste": [], "inmune": [],
		"estados_resiste": [], "estados_inmune": [],
		"por_que": "Porcelana animada: sus afinidades están por decidir (el paquete no las trae)."},
	"gorthor": {"debil": ["Hielo"], "resiste": ["Fuego"], "inmune": [],
		"estados_resiste": ["lento", "atk_baja"], "estados_inmune": ["prision"],
		"por_que": "Bestia de la Garganta, hecha al calor de la roca: el frío le entumece."},
	"guardian_bosque": {"debil": ["Fuego"], "resiste": ["Hielo", "Sombras"], "inmune": [],
		"estados_resiste": ["def_baja"], "estados_inmune": ["prision", "lento"],
		"por_que": "Raíces: arden, pero no se mueven ni se dejan encerrar; la sombra del bosque es suya."},
	"coloso_falla": {"debil": ["Rayo"], "resiste": ["Fuego", "Hielo"], "inmune": ["Gravedad"],
		"estados_resiste": ["lento", "def_baja"], "estados_inmune": ["prision"],
		"por_que": "Una montaña que anda: el peso no la mueve; sus runas conducen el rayo."},
	"bramavidrio": {"debil": ["Hielo"], "resiste": ["Fuego", "Rayo"], "inmune": [],
		"estados_resiste": ["lento", "atk_baja"], "estados_inmune": ["prision"],
		"por_que": "Cristal nacido del calor del desierto: el frío lo agrieta; el rayo resbala por el vidrio."},
	# V12, encuentro del desierto (12/11): Vidracrán (combate_vidracran.gd; demostración apagada). Solo escuelas nuevas.
	"vidracran": {"debil": ["Hielo"], "resiste": ["Fuego"], "inmune": [], "estados_resiste": [], "estados_inmune": [],
		"por_que": "Vidrio de arena fundida: el frío lo agrieta; el fuego lo templó."},
	# V12 (12/11): Humbaba (combate_humbaba.gd; jefe apagado). Solo escuelas nuevas (a las de siempre, su fuego ×1,4).
	"humbaba": {"debil": ["Fuego"], "resiste": ["Hielo", "Sombras"], "inmune": [], "estados_resiste": ["def_baja"],
		"estados_inmune": ["prision", "lento"], "por_que": "Madera maldita: arde; la sombra del bosque muerto es suya y nada lo encierra."},
}
# Lo que se aplica a un enemigo que no está en la tabla (o a uno nuevo): nada especial. Los jefes nuevos, como poco,
# son inmunes a la Prisión (JEFE_POR_DEFECTO), para que ningún jefe pierda turnos encadenados por descuido.
const POR_DEFECTO := {"debil": [], "resiste": [], "inmune": [], "estados_resiste": [], "estados_inmune": []}
const JEFE_POR_DEFECTO := {"debil": [], "resiste": [], "inmune": [], "estados_resiste": ["lento"],
	"estados_inmune": ["prision"]}


static func es_jefe(f: Dictionary) -> bool:
	return f.get("personalidad", "") in ["jefe", "bosque", "coloso", "bramavidrio"] or f.get("fases", false) \
		or f.get("ultimo_aliento", false) or f.get("titulo", false)


static func de(f: Dictionary) -> Dictionary:
	var clave := str(f.get("clave", ""))
	if TABLA.has(clave):
		return TABLA[clave]
	return JEFE_POR_DEFECTO if es_jefe(f) else POR_DEFECTO


# «debil», «resiste», «inmune» o "" (normal) de un elemento contra un enemigo. Con «vulnerable» (Herida Elemental):
# lo resistido pasa a normal y lo normal a débil; lo inmune sigue inmune (y lo débil, débil: no se suma).
static func clase(f: Dictionary, elemento: String) -> String:
	if elemento == "" or f.get("hero", false):
		return ""
	var t := de(f)
	if elemento in t["inmune"]:
		return "inmune"
	var vulnerable: bool = int(f.get("mn", {}).get("vulnerable", 0)) > 0
	if elemento in t["debil"]:
		return "debil"
	if elemento in t["resiste"]:
		return "" if vulnerable else "resiste"
	return "debil" if vulnerable else ""


static func mult(f: Dictionary, elemento: String) -> float:
	match clase(f, elemento):
		"debil":
			return DEBIL
		"resiste":
			return RESISTE
		"inmune":
			return INMUNE
	return 1.0


# «resiste», «inmune» o "" de un estado contra un enemigo (los héroes no tienen afinidades: "").
static func clase_estado(f: Dictionary, estado: String) -> String:
	if f.get("hero", false):
		return ""
	var t := de(f)
	if estado in t.get("estados_inmune", []):
		return "inmune"
	if estado in t.get("estados_resiste", []):
		return "resiste"
	return ""


# Turnos que de verdad dura un estado: 0 si es inmune; la mitad (hacia arriba) si lo resiste.
static func turnos_estado(f: Dictionary, estado: String, turnos: int) -> int:
	match clase_estado(f, estado):
		"inmune":
			return 0
		"resiste":
			return maxi(1, ceili(turnos / 2.0))
	return turnos


# Una línea para el panel de objetivos (combate.gd _info_objetivo) con la escuela que se va a lanzar: «Débil al Fuego»,
# «Resiste el Hielo», «Inmune a la Gravedad» o "".
static func linea(f: Dictionary, elemento: String) -> String:
	match clase(f, elemento):
		"debil":
			return "Débil: %s" % elemento
		"resiste":
			return "Resiste: %s" % elemento
		"inmune":
			return "Inmune: %s" % elemento
	return ""


# La tabla legible (para el informe y el Diario): [[enemigo, débil, resiste, inmune, estados que resiste, inmunes]].
static func filas_tabla() -> Array:
	var r: Array = []
	for clave in TABLA:
		var t: Dictionary = TABLA[clave]
		r.append([clave, ", ".join(t["debil"]), ", ".join(t["resiste"]), ", ".join(t["inmune"]),
			", ".join(t["estados_resiste"]), ", ".join(t["estados_inmune"])])
	return r
