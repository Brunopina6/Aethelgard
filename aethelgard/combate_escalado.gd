extends RefCounted
# Escalado de los enemigos (directiva V9, hito 7: «Enemigos con escalado de nivel» y 3.6 «Escalado de jefes»; 10/11).
# Solo cuentas, sin estado ni escena, como combate_formulas.gd. combate.gd lo llama una vez por enemigo al crearlo
# (_elegir_enemigos), así que el nivel del encuentro se fija al empezar el combate y no cambia a mitad.
#
# Idea: los enemigos mejoran de forma CONTROLADA cuando el grupo progresa, sin igualar nunca su nivel.
#   nivel del encuentro = nivel del grupo (progreso.gd nivel_grupo, la media de los activos), acotado entre
#                         la base de la región (progreso.gd NIVEL_ZONA) y la base + su subida máxima (SUBIDA).
#   Con el grupo al nivel de la región o por debajo, el nivel del encuentro es la base y el enemigo queda EXACTAMENTE
#   como en ENEMIGOS (no se toca ni un número; prueba_combate_huella).
#   Por cada nivel por encima de la base: más PV, ataque, experiencia y oro (POR_NIVEL), con un techo (MULT_MAX).
#   La velocidad no cambia (el ATB es el de siempre) ni la personalidad, ni los patrones, ni las fases.
# Jefes (personalidad «jefe» o «bosque», «fases», «ultimo_aliento», o cualquier enemigo de un combate fijo): margen más
#   estrecho (como mucho SUBIDA_JEFE niveles sobre la base) y nunca por debajo de sus valores de diseño.
# Lo que ya existía sigue igual: la experiencia por héroe (progreso.gd mult_exp: ponerse al día, x0,1 con 5 niveles o
# más por encima, jefes x10) se aplica DESPUÉS, sobre la experiencia ya escalada; y en una «zona limpia» (5 niveles por
# encima) los enemigos débiles siguen huyendo solos.

const Progreso := preload("res://progreso.gd")

# Subida máxima de los encuentros normales sobre la base de cada región (niveles). La base es NIVEL_ZONA de
# progreso.gd: una sola tabla de niveles para el ritmo, la experiencia y el escalado.
#   región      base  subida  nivel del encuentro
#   llanura       2     +3     2..5    (Pastos Verdes: Kael viaja solo al principio; margen corto)
#   bosque        4     +4     4..8
#   montana       7     +4     7..11
#   garganta      7     +4     7..11
#   desierto     10     +4    10..14
#   nieve        15     +5    15..20
#   yermo        18     +5    18..23
#   ceniza       34     +4    34..38   (final del acto IV: el techo de la tabla de actos es 38)
#   ciudad        0      0     sin escalado (no hay combates)
const SUBIDA := {"llanura": 3, "bosque": 4, "montana": 4, "garganta": 4, "desierto": 4, "nieve": 5, "yermo": 5,
	"ceniza": 4, "ciudad": 0}
const SUBIDA_OTRA := 4          # una región que no esté en la tabla
const SUBIDA_JEFE := 2          # jefes: como mucho 2 niveles sobre la base (y nunca más que la subida de su región)
const PERSONALIDAD_JEFE := ["jefe", "bosque"]

# Cuánto sube cada valor por nivel del encuentro sobre la base, y su techo (multiplicador máximo).
# Moderado a propósito: un héroe gana por nivel +6 PV y 3 puntos de atributo (con Fuerza, ~+15 % de golpe); el enemigo,
# +8 % de PV y +5 % de ataque. Con la subida máxima normal (+4): PV x1,32, ataque x1,20, experiencia x1,32, oro x1,20.
const POR_NIVEL := {"hp": 0.08, "atk": 0.05, "exp": 0.08, "oro": 0.05}
const MULT_MAX := {"hp": 1.40, "atk": 1.25, "exp": 1.40, "oro": 1.25}


static func es_jefe(e: Dictionary, combate_fijo: String) -> bool:
	return combate_fijo != "" or str(e.get("personalidad", "")) in PERSONALIDAD_JEFE or e.get("fases", false) \
		or e.get("ultimo_aliento", false)


static func base(zona: String) -> int:
	return Progreso.nivel_zona(zona)


# Niveles que puede subir un encuentro en esa región (jefes: el margen estrecho).
static func subida(zona: String, jefe: bool) -> int:
	var s: int = maxi(0, int(SUBIDA.get(zona, SUBIDA_OTRA)))
	return mini(SUBIDA_JEFE, s) if jefe else s


# Nivel del encuentro: el del grupo, nunca por debajo de la base de la región ni por encima de su tope.
static func nivel_encuentro(zona: String, nivel_grupo: int, jefe: bool) -> int:
	var b := base(zona)
	return clampi(nivel_grupo, b, b + subida(zona, jefe))


# Multiplicador de un valor («hp», «atk», «exp» u «oro») con «niveles» por encima de la base. 1,0 si no hay ninguno.
static func multiplicador(clave: String, niveles: int) -> float:
	if niveles <= 0:
		return 1.0
	return minf(1.0 + float(POR_NIVEL[clave]) * niveles, float(MULT_MAX[clave]))


# Ajusta un enemigo recién copiado de ENEMIGOS (antes de fijar sus PV máximos). Apunta su nivel en «nivel_encuentro».
# En la base no cambia ningún número. Nunca deja un valor por debajo del de diseño.
static func aplicar(e: Dictionary, zona: String, nivel_grupo: int, combate_fijo: String) -> void:
	var jefe := es_jefe(e, combate_fijo)
	var nivel := nivel_encuentro(zona, nivel_grupo, jefe)
	e["nivel_encuentro"] = nivel
	var sobre := nivel - base(zona)
	if sobre <= 0:
		return
	for k in POR_NIVEL:
		if e.has(k):
			var diseno := int(e[k])
			e[k] = maxi(diseno, int(round(diseno * multiplicador(k, sobre))))
