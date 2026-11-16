extends RefCounted
# Arboleda Mítica, tramo «La escalera de la Hospedería» (EXPERIMENTAL, 16/11): la actividad «Una flor para Lumi»
# [P v2 n.º 1] (docs/diseno/ciudades_y_lugares.md §2.3, «Pequeñas misiones»).
#
# - Lumi pide una flor de abajo (su frase [P] se AÑADE a las tres [C] de isla.gd, que no cambian) y la abuela Nívea [P],
#   en la misma plaza, da contexto.
# - En el banco de pruebas, llevar la flor es un interruptor de la SESIÓN («Llevar una flor de abajo»: Engine META_FLOR).
#   Qué flor es está por decidir [D] (la lavanda de los Pastos ya la lleva Rosa en oak_lavanda): aquí se dice «una flor
#   de abajo», sin nombrarla.
# - Al dársela: «Entonces abajo no es gris.» y el dibujo de Lumi aparece clavado en la pared de la Hospedería. El hito
#   HITO se guarda SOLO en la partida aislada del banco (banco_pruebas.gd, en_banco()). No se da la Cinta de Lumi [D]
#   (hallazgos.gd la sigue teniendo en FUERA).

const META_FLOR := "arboleda_flor"           # interruptor de sesión del banco (METAS_SESION)
const HITO := "isla_flor_lumi"
const PIDE := "¿Me traes una flor de abajo? Una de verdad, de las que huelen."     # [P] ciudades_y_lugares §2.3
const GRACIAS := "Entonces abajo no es gris."                                       # [P] el pago emocional
const AL_DAR := "Kael le da a Lumi la flor de abajo. Lumi la huele con los ojos cerrados."
const DESPUES := "Le he hecho un dibujo a Yedra para la pared. ¡Para que lo vean los que suban!"   # [P] nueva
const NIVEA := {"nombre": "Abuela Nívea", "imagen": "res://zonas3d/arboleda_tramo/piezas/nivea.png",
	"pos": Vector2(1772, 2016),
	"frases": ["Subí de niña con los peregrinos. Bajar no me ha hecho falta.",                    # [P] §2.3
		"Le dije a Lumi que abajo todo es gris. Hace tanto que no bajo que ya no sé si es verdad.",   # [P] contexto de la flor
		"Lumi repite todo lo que digo. Hasta lo que no debería.",                                  # [P] §2.3
		"Subí con un niño muy serio que encendía todos los faroles."]}                            # [P] §2.3 (pista de Tilo)


static func lleva_flor() -> bool:
	return bool(Engine.get_meta(META_FLOR, false))


var _entregada_aqui := false                 # fuera del banco (editor, pruebas sin banco): solo en memoria, sin hito


func entregada() -> bool:
	return _entregada_aqui or load("res://progreso.gd").hito(HITO)


# Las frases de Lumi con la petición: las tres [C] de isla.gd sin cambiar, y la [P] tras «Mi abuela dice…».
static func frases_lumi(canon: Array) -> Array:
	var f := canon.duplicate()
	f.insert(mini(2, f.size()), PIDE)
	return f


# Hablar con Lumi: si lleva la flor y aún no se la ha dado, se la da (devuelve los avisos a mostrar); si no, [].
func dar(escena: String) -> Array:
	if entregada() or not lleva_flor():
		return []
	var BP = load("res://banco_pruebas.gd")
	if BP.en_banco():                            # el hito, solo en la partida aislada del banco
		var P = load("res://progreso.gd")
		P.poner_hito(HITO)
		P.guardar(escena)
	else:
		_entregada_aqui = true
	Sonido.efecto("ui_tic")
	return [AL_DAR, "Niña Lumi: «%s»" % GRACIAS]
