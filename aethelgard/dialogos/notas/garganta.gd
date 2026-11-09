extends RefCounted
# Notas para encontrar en la Garganta del Diablo (narrativa, 09/11): cosas escritas o dejadas por otros —una tabla, un
# aviso, unas cintas— que cuentan algo del sitio sin canon nuevo. Se leen al examinarlas y van al Diario, sección
# «Notas» (progreso.gd, CIUDADES: este módulo es el del lugar 2; se apuntan en «lore_visto», sin clave nueva).
#
# ENGANCHE (garganta_3d.gd es de gráficos: no lo toco). Para cada nota, en su «pos» (coordenadas de
# zonas3d/garganta/trazado.gd, ya en la cornisa): un objeto pequeño que se vea (una tabla, un papel clavado…) y, a menos
# de RADIO metros, el botón «Examinar»; al pulsarlo:
#     _mostrar_aviso(n["texto"], 4.5)
#     if Progreso.ver_nota(n["id"]): _mostrar_aviso("Nueva nota en el Diario: «%s»" % n["nombre"]) (con Sonido «pagina»)
# Lo mismo que hace zonas3d/pastos_verdes_3d.gd con dialogos/notas/pastos_verdes.gd. «casilla_2d»: dónde iría en la
# Garganta 2D (garganta.gd), por la equivalencia que anota trazado.gd; pendiente de quien lleve esa escena.

const INDICE := 2                          # mapa.gd, LUGARES (INDICE_GARGANTA)
const NOMBRE_LUGAR := "Garganta del Diablo"
const RADIO := 2.2                         # metros, como RADIO_ACCION de las zonas 3D

const NOTAS := [
	{"id": "nota_gar_puenteros", "nombre": "Tabla de los puenteros",
		"pos": Vector3(-14.2, 0.0, 20.2), "donde": "al pie del primer puente colgante, en el lado del muro",
		"texto": "Tabla de los puenteros: «Cuerdas nuevas en primavera. Si cruje, nada. Si canta, corre.»"},
	{"id": "nota_gar_ascensor", "nombre": "Aviso del ascensor",
		"pos": Vector3(-13.4, 0.0, 24.6), "donde": "en el muro, antes del ascensor de arriba (ASCENSOR_ARRIBA), sin tapar su botón",
		"texto": "Papel clavado: «El ascensor solo sube si abajo tiran de la palanca. El que esperó dos horas.»"},
	{"id": "nota_gar_nido", "nombre": "Escamas de ámbar",
		"pos": Vector3(6.2, -14.0, 11.6), "donde": "al pie de la bajada al nido (cerca de VUELTA_NIDO)",
		"texto": "Escamas de ámbar en la piedra, grandes como platos. Algo duerme aquí. Mejor no despertarlo."},
	{"id": "nota_gar_cintas", "nombre": "Cintas de los peregrinos",
		"pos": Vector3(10.2, -8.0, -28.6), "donde": "antes del pilar del peregrino (PILAR_PEREGRINO), sin pisar su botón",
		"texto": "Cintas de colores atadas a una piedra, al pie del pilar. Una por cada viajero que pasó."},
]
# Dónde irían en la Garganta 2D (garganta.gd), APROXIMADO con la equivalencia que anota trazado.gd (x 2D ≈ 3 + (37 − z);
# y 2D, la de la cornisa: 10,8 arriba, 34,2 abajo, 44 en el nido). Pendiente: que su responsable las ponga y las ajuste.
const CASILLA_2D := {
	"nota_gar_puenteros": Vector2(19.8, 10.8), "nota_gar_ascensor": Vector2(15.4, 10.8),
	"nota_gar_nido": Vector2(29.7, 44.0), "nota_gar_cintas": Vector2(68.6, 34.2),
}
