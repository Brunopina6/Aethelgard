extends RefCounted
# Encargos nuevos de Oakhaven (V10; formato de encargos.gd). Se juegan en la ciudad 2D (vecinos, piezas y señales de
# ciudades/oakhaven.gd) y en la Garganta 3D (la veta de hierro: zonas3d/garganta_3d.gd). Diseño: docs/v10/DISENO_V10.md.

const NOMBRE_LUGAR := "Oakhaven"

const MISIONES := [
	{"id": "enc_herrero", "nombre": "El pedido de Maese Ferro", "quien": "ferro",
		"resumen": "Maese Ferro busca un hierro «que canta». Dice que lo había en la Falla, en la Garganta.",
		"empieza": "hito:enc_herrero_pedido", "fin": "hito:enc_herrero_fin",
		"pasos": [
			{"id": "pista", "texto": "En la Garganta, examina el pilar del peregrino: Garon sabrá leerlo.",
				"hecho": "hito:enc_herrero_pista"},
			{"id": "veta", "texto": "Busca la veta de hierro en la Garganta, cerca del pilar.", "hecho": "hito:enc_herrero_veta"},
			{"id": "decidir", "texto": "Vuelve con Ferro y decide qué hacer con el hierro.", "hecho": "hito:enc_herrero_fin"}],
		# V12 (fase 7): lo que el jugador ya sabe, para el Diario (los textos que vio en la Garganta y lo que decidió).
		"pistas": [
			{"texto": "Garon: «Las letras del pilar las grabaron con el hierro de aquí. Mirad: la veta brilla.»",
				"si": ["hito:enc_herrero_pista", "grupo:Garon"]},
			{"texto": "Al pie del pilar del peregrino, la roca tiene vetas oscuras que brillan como el metal.",
				"si": ["hito:enc_herrero_pista", "!grupo:Garon"]},
			{"texto": "Sin el hierro no hay nada que decidir. En la veta de la Falla, junto al pilar, aún queda.",
				"si": ["hito:enc_herrero_veta", "!hito:enc_herrero_fin", "!material:Hierro de la Falla=1"]},   # 15/11
			{"texto": "Decidisteis entregarle el hierro a Ferro: lo venderá en su forja.", "si": "decision:hierro_ferro=entregado"},
			{"texto": "Kael se quedó el hierro. Ferro le enseñará a templarlo en la forja.", "si": "decision:hierro_ferro=kael"}],
		"recompensa": {}, "pago": "El hierro de la Falla ya tiene dueño: lo que decidisteis lo recuerda Ferro."},
	{"id": "enc_formula", "nombre": "La fórmula desaparecida", "quien": "mirta",
		"resumen": "Mirta, la boticaria, perdió las páginas de su mejor fórmula.",
		"empieza": "hito:enc_formula_pedido", "fin": "hito:enc_formula_fin",
		"pasos": [
			{"id": "pip", "texto": "Pregunta por la ciudad: alguien tuvo que ver algo. Pip lo ve todo.",
				"hecho": "hito:enc_formula_pip"},
			{"id": "paginas", "texto": "Encuentra las tres páginas que se llevó el viento.", "hecho": "hito:enc_formula_paginas"},
			{"id": "volver", "texto": "Vuelve con Mirta, con Lya en el grupo: ella puede rehacer la fórmula.",
				"hecho": "hito:enc_formula_fin"}],
		# V12 (fase 7): cada página, con lo que dice, en cuanto se recoge (los textos de ciudades/oakhaven.gd, PIEZAS).
		"pistas": [
			{"texto": "Página de Mirta: «…dos de hierba lunar, nunca tres…».", "si": "estado_de:oakhaven/pagina_1"},
			{"texto": "Página de Mirta: «…la savia, clara, al final…».", "si": "estado_de:oakhaven/pagina_2"},
			{"texto": "Página de Mirta: «…y removerlo como quien acuna». Firmado: M.", "si": "estado_de:oakhaven/pagina_3"}],
		"recompensa": {"oro": 40, "objetos": {"Bálsamo de Mirta": 2}},
		"pago": "Mirta vuelve a preparar su bálsamo y lo vende en la botica."},
	# V12, fase 7 (PROPUESTA): la cerradura rúnica del arcón del Concejo (ciudades/oakhaven.gd CERRADURA). Empieza al
	# mirar la cerradura; la pista es la inscripción (lo que se ha leído), nunca la combinación.
	{"id": "enc_arcon", "nombre": "El arcón del Concejo", "quien": "",
		"resumen": "Bajo el pórtico del Concejo hay un arcón cerrado con tres anillos de runas.",
		"empieza": "estado_de:oakhaven/cerradura_vista", "fin": "estado_de:oakhaven/cerradura_abierta",
		"pasos": [{"id": "abrir", "texto": "Gira los anillos hasta que la marca señale lo que pide la tapa.",
			"hecho": "estado_de:oakhaven/cerradura_abierta"}],
		"pistas": [{"texto": "Grabado en la tapa: «De fuera adentro: lo que arde, lo que sana y lo que vela de noche».",
			"si": "estado_de:oakhaven/cerradura_vista"}],
		"recompensa": {}, "pago": "El arcón está abierto. Dentro había monedas, un Éter y un trozo de mineral rúnico."},
]
