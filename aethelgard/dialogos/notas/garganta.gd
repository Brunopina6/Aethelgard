extends RefCounted
# Notas para encontrar en la Garganta del Diablo (narrativa, 09/11): cosas escritas o dejadas por otros —una tabla, un
# aviso, unas cintas— que cuentan algo del sitio sin canon nuevo. Se leen al examinarlas y van al Diario, sección
# «Notas» (progreso.gd, CIUDADES: este módulo es el del lugar 2; se apuntan en «lore_visto», sin clave nueva).
#
# ENGANCHE (garganta_3d.gd es de gráficos: no lo toco). Cada nota va en su «pos» (coordenadas de
# zonas3d/garganta/trazado.gd, ya sobre la cornisa) con un objeto pequeño que se vea (una tabla, un papel clavado, unas
# cintas: piezas.gd) y, mientras no se ha leído, un destello. Con el estilo de garganta_3d.gd de hoy:
#     const NotasGar := preload("res://dialogos/notas/garganta.gd")
#     # en _piezas_al_alcance(), al final de «lista»:
#     for n in NotasGar.NOTAS:
#         lista.append(["nota:" + n["id"], n["pos"], "Examinar"])
#     # en _accion(), una rama más del match (por defecto):
#     _:
#         if cerca.begins_with("nota:"):
#             _leer_nota(cerca.trim_prefix("nota:"))
#     # y _leer_nota(id), como la de zonas3d/pastos_verdes_3d.gd: _mostrar_aviso(texto, 4.5) y Sonido «examinar»; si
#     # Progreso.ver_nota(id) (true solo la primera vez), a los 4,6 s Sonido «pagina» y
#     # _mostrar_aviso("Nueva nota en el Diario: «%s»" % nombre, 2.4); y se apaga su destello.
# Las posiciones están a más de RADIO + 0,5 m de lo que ya se usa allí (ascensores, palanca, pilar, cofre, detalle de
# los puentes, puerta y guardados) y entre sí: lo comprueba prueba_notas_exploracion. Ajústalas a tu gusto si cambia el
# trazado (el texto no depende del sitio exacto). «CASILLA_2D»: dónde irían en la Garganta 2D (garganta.gd),
# aproximado; pendiente de quien lleve esa escena.

const INDICE := 2                          # mapa.gd, LUGARES (INDICE_GARGANTA)
const NOMBRE_LUGAR := "Garganta del Diablo"
const RADIO := 2.2                         # metros: RADIO_ACCION de Pastos Verdes 3D (en garganta_3d.gd, RADIO_PIEZA = 2,0)

const NOTAS := [
	{"id": "nota_gar_puenteros", "nombre": "Tabla de los puenteros",
		"pos": Vector3(-14.2, 0.0, 20.2), "donde": "al pie del primer puente colgante, en el lado del muro",
		"texto": "Tabla de los puenteros: «Cuerdas nuevas en primavera. Si cruje, nada. Si canta, corre.»"},
	{"id": "nota_gar_ascensor", "nombre": "Aviso del ascensor",
		"pos": Vector3(-13.4, 0.0, 24.6), "donde": "en el muro, antes del ascensor de arriba (ASCENSOR_ARRIBA), sin tapar su botón",
		"texto": "Papel clavado: «El ascensor no baja si nadie tira de la palanca de abajo. El que esperó dos horas.»"},
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
