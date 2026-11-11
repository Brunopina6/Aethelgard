extends RefCounted
# Rincones de Pastos Verdes 3D (narrativa y exploración, 12/11/2026): los textos de zonas3d/pastos_rincones.gd.
# Pequeños detalles fuera de la misión: el montón de piedras de los peregrinos, el nido de la urraca y el centro del
# puente. Nada de esto es canon nuevo: los peregrinos ya están en el juego (pv_05: «Los peregrinos lo saludaban antes de
# cruzar»; las notas del mojón y de la cinta) y lo demás es paisaje. Ni Érebo, ni lo que guarda, ni otras sagas.
#
# Comentarios: con el formato de dialogos/comentarios.gd (quien, texto, intencion, gesto, espera y, si acaso,
# respuesta), 70 letras como mucho cada uno. Se elige la variante según quién esté en el grupo:
#   «solo»  Kael (antes de PV-03)
#   «lya»   Kael y Lya (de PV-03 a PV-05)
#   «grupo» con Garon (desde PV-05)
# Voces: docs/narrativa/voces_heroes.md.

const TEXTOS := {
	"piedra_dejar": "Dejas una piedra en lo alto del montón, como los peregrinos.",
	"piedra_ya": "Tu piedra sigue arriba del todo.",
	"nido_lejos": "Algo brilla en un nido, en lo alto del árbol seco. No llegas.",
	"nido_premio": "Bajas con %d monedas y una moneda antigua. El botón se queda en el nido.",
	"nido_vacio": "El nido de la urraca. Solo queda su botón.",
}

const BOTONES := {
	"piedra": "Dejar una piedra",
	"piedra_ya": "Mirar el montón",
	"nido": "Mirar arriba",
	"puente": "Asomarse",
}

# La recompensa del nido (modesta: un cofre de la región da de 40 a 120 monedas). «Moneda antigua» ya existe
# (buscador.gd, material del buscador de metales de Kael).
const NIDO_MONEDAS := 25
const NIDO_OBJETO := "Moneda antigua"

const COMENTARIOS := {
	# Al dejar la piedra en el montón de los peregrinos.
	"piedra": {
		"solo": {"quien": "Kael", "texto": "Una piedra más. Ahora tendré que volver a por ella.",
			"intencion": "Se hace una promesa en broma", "gesto": "ligero", "espera": "espera_brazalete"},
		"lya": {"quien": "Lya", "texto": "Los peregrinos dejaban una al irse y la recogían al volver.",
			"intencion": "Lo sabe de los libros y se lo regala", "gesto": "duda", "espera": "espera_flor",
			"respuesta": {"quien": "Kael", "texto": "Entonces esa es mía. Que nadie me la quite.",
				"intencion": "Se apunta a volver sin decirlo en serio", "gesto": "ligero", "espera": "espera_brazalete"}},
		"grupo": {"quien": "Garon", "texto": "Muchas piedras. Pocos vuelven a por ellas.",
			"intencion": "El veterano que ha contado ausencias", "gesto": "", "espera": "espera_hombros",
			"respuesta": {"quien": "Kael", "texto": "Yo volveré. Aunque sea por llevarte la contraria.",
				"intencion": "Le da la luz a lo oscuro con una provocación", "gesto": "decidido",
				"espera": "espera_empunadura"}},
	},
	# Al mirar el nido sin Garon (nadie llega).
	"nido_lejos": {
		"solo": {"quien": "Kael", "texto": "Un palmo más y era mío. Un palmo, nada más.",
			"intencion": "Se ríe de su propia altura", "gesto": "ligero", "espera": "espera_impaciencia"},
		"lya": {"quien": "Lya", "texto": "Es de urraca. Se llevan todo lo que brilla.",
			"intencion": "Nombra lo que ve, precisa", "gesto": "duda", "espera": "espera_cetro",
			"respuesta": {"quien": "Kael", "texto": "Hoy no llego. Volveré con alguien más alto.",
				"intencion": "Deja la puerta abierta a volver", "gesto": "ligero", "espera": "espera_vigilar"}},
	},
	# Tras bajar del nido (siempre con Garon, que aúpa a Kael), si Lya también está.
	"nido_premio": {
		"grupo": {"quien": "Lya", "texto": "Le has dejado el botón. Bien hecho.",
			"intencion": "Le premia lo tierno que no admite", "gesto": "", "espera": "espera_pelo",
			"respuesta": {"quien": "Kael", "texto": "Era feo. No te emociones.",
				"intencion": "Lo niega para que no se note", "gesto": "ligero", "espera": "espera_brazalete"}},
	},
	# En el centro del puente, mirando la cascada.
	"puente": {
		"solo": {"quien": "Kael", "texto": "Agua arriba, agua abajo. Y yo en medio, seco. De momento.",
			"intencion": "Se quita el vértigo con una broma", "gesto": "ligero", "espera": "espera_vigilar"},
		"lya": {"quien": "Lya", "texto": "Mira la cascada. Desde aquí parece que no cae: que cuelga.",
			"intencion": "Le enseña algo bonito con precisión de estudiosa", "gesto": "", "espera": "espera_pelo",
			"respuesta": {"quien": "Kael", "texto": "Mientras no caigamos nosotros.",
				"intencion": "Le quita solemnidad al asombro", "gesto": "ligero", "espera": "espera_vigilar"}},
		"grupo": {"quien": "Kael", "texto": "Podría quedarme aquí toda la tarde.",
			"intencion": "Se le escapa que este sitio le gusta", "gesto": "", "espera": "espera_vigilar",
			"respuesta": {"quien": "Garon", "texto": "Cruje. …Cinco minutos.",
				"intencion": "Protege y cede a la vez", "gesto": "", "espera": "espera_apoyarse"}},
	},
}

# Diálogo del nido con Garon (Dialogic, abierto por su ruta: no hace falta registrarlo en project.godot).
const DIALOGO_NIDO := "res://dialogos/pastos/rincon_nido.dtl"
