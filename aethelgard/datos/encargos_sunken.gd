extends RefCounted
# Encargos de Sunken City (V12, 15/11; formato de encargos.gd). PROPUESTA sin aprobar: se juegan en Sunken City 3D
# (zonas3d/sunken_3d.gd, EN PRUEBAS y apagada; lógica en ciudades/sunken.gd). Con la región apagada no empiezan nunca.
# Estado en «mazmorras»["sunken"] (estado_de:sunken/<clave>): ninguna clave nueva de partida.

const NOMBRE_LUGAR := "Sunken City"

const MISIONES := [
	{"id": "sunk_sello", "nombre": "El sello de la capitana", "quien": "ulla", "tipo": "secundaria",
		"resumen": "La contramaestre Ulla necesita el sello de la capitana Brea para el contrato de amarre del muelle.",
		"empieza": "estado_de:sunken/sello_pedido", "fin": "estado_de:sunken/sello_fin",
		"pasos": [
			{"id": "brea", "texto": "Pregunta a la capitana Brea por su sello, en la Cubierta Mayor.",
				"hecho": "estado_de:sunken/sello_pista"},
			{"id": "sello", "texto": "Busca el sello donde Brea dice que lo dejó.", "hecho": "estado_de:sunken/sello_hallado"},
			{"id": "volver", "texto": "Lleva el sello a la contramaestre Ulla, en el Archivo del Águila.",
				"hecho": "estado_de:sunken/sello_fin"}],
		# Lo que el jugador ya sabe (lo que oyó y lo que encontró): nunca la respuesta antes de tiempo.
		"pistas": [
			{"texto": "Ulla: sin el sello de la capitana, el contrato de amarre no vale. Y Brea lo «deja en buenas manos».",
				"si": "estado_de:sunken/sello_pedido"},
			{"texto": "Brea: «Lo dejé con la única de este barco que nunca se arría».", "si": "estado_de:sunken/sello_pista"},
			{"texto": "El sello estaba atado a la driza de la bandera del Águila, en el palo mayor.",
				"si": "estado_de:sunken/sello_hallado"}],
		"recompensa": {"objetos": {"Bronce del Águila": 1}},
		"pago": "Contrato sellado. Ulla os dio una plancha de bronce del casco para la forja de Kael."},
]
