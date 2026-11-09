extends RefCounted
# Notas para encontrar en Pastos Verdes (narrativa, 09/11): cosas escritas o dejadas por otros que cuentan algo del
# sitio sin canon nuevo. Se leen al examinarlas y van al Diario, sección «Notas» (progreso.gd, CIUDADES: este módulo es
# el del lugar 10, LUGAR_PASTOS de mapa.gd; se apuntan en «lore_visto», sin clave nueva).
# Enganchadas en zonas3d/pastos_verdes_3d.gd: cada una, junto al camino cerca de su «cerca» (como el ramito de
# lavanda), con un poste y un destello pequeños; a RADIO_ACCION, «Examinar».

const INDICE := 10                         # mapa.gd: LUGAR_PASTOS (pastos_verdes_3d.gd, INDICE)
const NOMBRE_LUGAR := "Pastos Verdes"

const NOTAS := [
	{"id": "nota_pv_libreta", "nombre": "Libreta del farolero",
		"cerca": Vector3(13.0, 0.0, -6.0), "donde": "pasado el puente, camino del mirador (a Tilo se le cayó)",
		"texto": "Libreta de Tilo: «Mecha nueva. Aceite, poco. El viejo del mirador, con el ojo apagado.»"},
	{"id": "nota_pv_mojon", "nombre": "Mojón del camino",
		"cerca": Vector3(-2.0, 0.0, 0.0), "donde": "junto al camino, antes del puesto de Tilo",
		"texto": "Mojón gastado: «A Oakhaven, medio día. A la Garganta, uno y medio. A casa, siempre.»"},
	{"id": "nota_pv_cinta", "nombre": "Cinta en una rama",
		"cerca": Vector3(-10.0, 0.0, 13.0), "donde": "en un arbusto junto al camino, al poco de entrar",
		"texto": "Una cinta de colores atada a una rama, como las de los peregrinos. Desteñida por el sol."},
]
