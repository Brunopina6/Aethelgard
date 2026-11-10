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
		"recompensa": {}, "pago": "El hierro de la Falla ya tiene dueño: lo que decidisteis lo recuerda Ferro."},
	{"id": "enc_formula", "nombre": "La fórmula desaparecida", "quien": "mirta",
		"resumen": "Mirta, la boticaria, perdió las páginas de su mejor fórmula.",
		"empieza": "hito:enc_formula_pedido", "fin": "hito:enc_formula_fin",
		"pasos": [
			{"id": "pip", "texto": "Pregunta por la ciudad: alguien tuvo que ver algo. Pip lo ve todo.",
				"hecho": "hito:enc_formula_pip"},
			{"id": "paginas", "texto": "Encuentra las tres páginas que se llevó el viento.", "hecho": "hito:enc_formula_paginas"},
			{"id": "volver", "texto": "Vuelve con Mirta: Lya puede ayudarla a rehacer la fórmula.", "hecho": "hito:enc_formula_fin"}],
		"recompensa": {"oro": 40, "objetos": {"Bálsamo de Mirta": 2}},
		"pago": "Mirta vuelve a preparar su bálsamo y lo vende en la botica."},
]
