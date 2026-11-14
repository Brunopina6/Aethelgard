extends RefCounted
# Encargos del Mar de Cristal (V12, fase 7; formato de encargos.gd). «La caravana perdida» se juega en
# zonas3d/mar_cristal/mision.gd (hitos mc_*, en orden); aquí solo se describe para el Diario, como Pastos Verdes.
# Estaba prevista en docs/v12/DISENO_V12.md §2 («datos en datos/encargos_desierto.gd») y faltaba: la misión se jugaba
# pero el Diario no la recordaba. Nombres aprobados el 11/11 (Ismena y Oren); los textos de pasos y pistas salen de los
# avisos de la región (mision.gd TEXTOS) y del mural (dialogos/mar_cristal/mc_ruinas_mural*.dtl), sin nada nuevo.
# «recompensa» va vacía: el premio (150 monedas, el buscador a nivel 2 y la Aguja de Resonancia) lo da mision.gd.
# El Mar de Cristal sigue EN PRUEBAS (modo3d.gd): sin entrar en él no hay mc_inicio y el encargo no sale.

const NOMBRE_LUGAR := "Mar de Cristal"

const MISIONES := [
	{"id": "mc_caravana_perdida", "nombre": "La caravana perdida", "quien": "ismena",
		"resumen": "La caravana de Oren, el hermano de Ismena, no llegó al campamento. Ismena te ha prestado su buscador.",
		"empieza": "hito:mc_inicio", "fin": "hito:mc_fin",
		"pasos": [
			{"id": "restos", "texto": "Examina los restos del carro, en medio del desierto.", "hecho": "hito:mc_caravana"},
			{"id": "sello", "texto": "Busca con el buscador junto al carro: algo de metal habrá quedado.", "hecho": "hito:mc_sello"},
			{"id": "norte", "texto": "Sigue hacia el norte, adonde mira el sello.", "hecho": "hito:mc_tormenta"},
			{"id": "cobijo", "texto": "La tormenta: ve al cobijo del cañón, al oeste, y espera a que amaine.",
				"hecho": "hito:mc_ruinas"},
			{"id": "llave", "texto": "Busca con el buscador en las ruinas que ha destapado la arena.", "hecho": "hito:mc_llave"},
			{"id": "trampilla", "texto": "Abre la trampilla de vidrio de las ruinas.", "hecho": "hito:mc_superviviente"},
			{"id": "volver", "texto": "Vuelve con Ismena, al campamento.", "hecho": "hito:mc_fin"}],
		"pistas": [
			{"texto": "El sello de la caravana: un disco de bronce con una flecha. Alguien lo dejó mirando al norte.",
				"si": "hito:mc_sello"},
			{"texto": "Una llave de vidrio con el ojo de bronce. Por eso cantaba el buscador.", "si": "hito:mc_llave"},
			{"texto": "En el mural de las ruinas, a una figura le rasparon el nombre. Solo queda «…de los Espejismos».",
				"si": "hito:mc_superviviente"}],
		"recompensa": {}, "pago": "Oren está a salvo. Ismena os pagó, y el buscador se queda con Kael."},
]
