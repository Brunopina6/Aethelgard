extends RefCounted
# Encargos de Pastos Verdes (V9; formato de encargos.gd, el mismo que ciudades/oakhaven.gd MISIONES). Se juegan en
# zonas3d/bosque_pastos.gd; aquí solo se describen para el Diario.

const NOMBRE_LUGAR := "Pastos Verdes"

const MISIONES := [
	{"id": "bq_bosque", "nombre": "El bosque que no recuerda", "quien": "tilo",
		"resumen": "El árbol junto al puesto de Tilo amaneció marcado. Algo hace olvidar al bosque.",
		"empieza": "hito:bq_inicio", "fin": "hito:bq_resuelto",
		"pasos": [
			{"id": "arbol", "texto": "Examina el árbol marcado.", "hecho": "hito:bq_arbol"},
			{"id": "pistas", "texto": "Busca las tres señales del olvido: junto al río, al este y en las ruinas.",
				"hecho": "hito:bq_pistas"},
			{"id": "guardian", "texto": "Ve al claro del noreste. Lya puede preparar antes un elixir.",
				"hecho": "hito:bq_resuelto"}],
		"recompensa": {}, "pago": "Según lo que decidisteis con el Guardián, el bosque florece o calla."},
	{"id": "bq_futuros", "nombre": "Los dos futuros del orbe", "quien": "lya",
		"resumen": "En las ruinas hay un altar con un orbe que muestra lo que aún no ha pasado.",
		"empieza": "hito:bq_senda", "fin": "hito:bq_futuros",
		"pasos": [
			{"id": "a", "texto": "Mira el orbe del altar.", "hecho": "hito:bq_orbe_a"},
			{"id": "b", "texto": "Vuelve a mirarlo: hay otro futuro.", "hecho": "hito:bq_orbe_b"}],
		"recompensa": {}, "pago": "Lya entiende mejor la savia: su investigación avanza."},
	{"id": "bq_encina", "nombre": "Noticias para Encina", "quien": "encina",
		"resumen": "Doña Encina, en las raíces del Árbol de Oakhaven, querrá saber qué pasó en el bosque.",
		"empieza": "hito:bq_resuelto", "fin": "estado_de:oakhaven/encina_bosque",
		"pasos": [{"id": "hablar", "texto": "Habla con Doña Encina en Oakhaven.", "hecho": "estado_de:oakhaven/encina_bosque"}],
		"recompensa": {}, "pago": "Encina pone hierbas del bosque a la venta."},
	{"id": "enc_perro", "nombre": "Canela se ha perdido", "quien": "pip",
		"resumen": "Pip, en Oakhaven, ha perdido a su perra Canela. Dice que se fue corriendo hacia Pastos Verdes.",
		"empieza": "hito:enc_perro_pedido", "fin": "hito:enc_perro_devuelto",
		"pasos": [
			{"id": "huellas", "texto": "Busca huellas de Canela en Pastos Verdes.", "hecho": "hito:enc_perro_huellas"},
			{"id": "encontrar", "texto": "Sigue el rastro hasta las ruinas (Garon puede apartar las ramas).",
				"hecho": "hito:enc_perro_encontrado"},
			{"id": "volver", "texto": "Devuélvesela a Pip, en Oakhaven.", "hecho": "hito:enc_perro_devuelto"}],
		"recompensa": {"oro": 40, "objetos": {"Poción": 2}}, "pago": "Pip y Canela, juntos otra vez."},
]
