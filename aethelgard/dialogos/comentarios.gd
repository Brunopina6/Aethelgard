extends RefCounted
# Comentarios de los héroes al explorar (narrativa, 09/11): frases cortas que dicen solos, sin abrir un diálogo ni
# parar al jugador, al llegar a un sitio, al abrir un cofre, al ver la cascada de la Garganta o al quedarse quietos.
# La voz de cada uno sigue docs/narrativa/voces_heroes.md. Ninguna cambia la partida: solo se ven.
#
#   const Comentarios := preload("res://dialogos/comentarios.gd")
#   var c := Comentarios.elegir("cofre")                 # {} si no toca (nadie presente, ya dicho, sin datos)
#   if not c.is_empty(): Comentarios.mostrar(ui, c)      # ui: el CanvasLayer de la escena
#
# QUIÉN HABLA: solo los que están en el grupo activo (grupo.gd: Kael siempre; Lya desde PV-03 y Garon desde PV-05), y
# una respuesta solo si quien responde también está. Se turnan: habla quien lleva más tiempo callado.
# CUÁNTAS VECES: cada frase, una vez por sesión (Engine «comentarios_dichos», un diccionario de textos: no va a la
# partida). Los momentos «unico» (una llegada) salen una sola vez por sesión, diga quien diga.
# PARA ANIMACIONES (ver narrativa.md): «intencion» es lo que quiere decir; «gesto», la etiqueta del retrato vivo si
# algún día sale con retrato (ligero, firme, duda, sorpresa, decidido…); «espera», el clip de espera 3D que le pega
# (animaciones/esperas/<héroe>.res: espera_vigilar, espera_brazalete, espera_flor, espera_apoyarse…). En 2D no se usa.
#
# Dónde se enganchan (ver «ENGANCHES» abajo): en las zonas 2D (zona.gd) la llegada y los cofres; en Oakhaven
# (ciudad_oakhaven.gd), además, quedarse quieto; en 3D, Pastos Verdes (cofre y quieto), la Garganta (llegada, cofre y
# cascada), Ciclópea y el Gran Bosque (cofre). prueba_comentarios (1b) comprueba que ENGANCHES siga al día.

const META := "comentarios_dichos"
const COLORES := {"Kael": Color(0.5608, 0.8275, 1.0), "Lya": Color(0.9098, 0.7686, 0.4157), "Garon": Color(0.75, 0.82, 0.95)}
const SEGUNDOS_BASE := 2.4               # en pantalla: base + por letra (se lee sin prisa y sin estorbar)
const SEGUNDOS_LETRA := 0.045
const ANCHO := 470.0                     # caja abajo a la derecha (la cruceta táctil va a la izquierda y el botón de
const MARGEN_DERECHO := 24.0             # examinar, en el centro, a 600 px)
const BORDE_INFERIOR := 586.0

# Momentos. «unico»: una vez por sesión. Cada frase: quien, texto, intencion, gesto, espera; «respuesta» opcional.
const MOMENTOS := {
	"llegar:oakhaven": {"unico": true, "frases": [
		{"quien": "Kael", "texto": "Oakhaven. Huele a pan y a mecha recién encendida.",
			"intencion": "Alivio de volver; lo dice como quien no lo dice", "gesto": "ligero", "espera": "espera_vigilar"},
		{"quien": "Lya", "texto": "Mira cuántos faroles. Aquí la niebla lo tiene difícil.",
			"intencion": "Cálida; se tranquiliza a sí misma", "gesto": "", "espera": "espera_cetro"},
		{"quien": "Garon", "texto": "Puerta, muralla, guardia. Todo en su sitio.",
			"intencion": "Pasa revista sin pararse", "gesto": "firme", "espera": "espera_hombros"},
	]},
	"llegar:lugar_nuevo": {"unico": false, "frases": [
		{"quien": "Kael", "texto": "Sitio nuevo. Que alguien apunte que llegué primero.",
			"intencion": "Bravuconería de broma; curiosidad", "gesto": "ligero", "espera": "espera_vigilar"},
		{"quien": "Lya", "texto": "Nunca había estado aquí. Quédate cerca, ¿vale?",
			"intencion": "Curiosa y protectora a la vez", "gesto": "inquieta", "espera": "espera_pelo"},
		{"quien": "Garon", "texto": "Dos salidas. Recordadlas.",
			"intencion": "Instinto de soldado: primero, por dónde salir", "gesto": "firme", "espera": "espera_hombros"},
	]},
	"llegar:garganta": {"unico": true, "frases": [
		{"quien": "Kael", "texto": "La Garganta del Diablo. Con ese nombre, seguro que es acogedora.",
			"intencion": "Ironía para quitarse el miedo", "gesto": "ligero", "espera": "espera_empunadura"},
		{"quien": "Lya", "texto": "Se oye el agua desde aquí… Id despacio.",
			"intencion": "Atenta; pide prudencia sin dramatizar", "gesto": "preocupada", "espera": "espera_cetro"},
		{"quien": "Garon", "texto": "Cornisa estrecha. En fila. Yo, delante.",
			"intencion": "Órdenes cortas; se pone en el peligro", "gesto": "firme", "espera": "espera_apoyarse"},
	]},
	"cascada_garganta": {"unico": true, "frases": [
		{"quien": "Kael", "texto": "Vale. Lo admito. Es precioso.",
			"intencion": "Se le escapa el asombro y lo despacha rápido", "gesto": "sorpresa", "espera": "espera_vigilar"},
		{"quien": "Lya", "texto": "Quédate un momento. Hay cosas que no se ven dos veces.",
			"intencion": "Contemplativa; le pide que lo guarde", "gesto": "", "espera": "espera_pelo"},
		{"quien": "Garon", "texto": "Bonita. Y resbaladiza. Lejos del borde.",
			"intencion": "Lo admira a su modo y protege", "gesto": "firme", "espera": "espera_espalda"},
	]},
	"cofre": {"unico": false, "frases": [
		{"quien": "Kael", "texto": "¿Para mí? No hacía falta.",
			"intencion": "Broma de siempre; contento de verdad", "gesto": "ligero", "espera": "espera_brazalete",
			"respuesta": {"quien": "Garon", "texto": "No era para ti.", "intencion": "Seco; le sigue el juego",
				"gesto": "", "espera": "espera_hombros"}},
		{"quien": "Lya", "texto": "Lo apunto yo. Tú luego no te acuerdas.",
			"intencion": "Ordenada y con cariño burlón", "gesto": "decidida", "espera": "espera_cetro"},
		{"quien": "Garon", "texto": "Mira el fondo. Siempre queda algo.",
			"intencion": "Consejo de veterano", "gesto": "", "espera": "espera_apoyarse"},
	]},
	"quieto": {"unico": false, "frases": [
		{"quien": "Kael", "texto": "¿Seguimos? El mundo no se explora solo.",
			"intencion": "Impaciente; tira del grupo", "gesto": "decidido", "espera": "espera_impaciencia",
			"respuesta": {"quien": "Lya", "texto": "Kael… respira.", "intencion": "Le frena con ternura",
				"gesto": "duda", "espera": "espera_pelo"}},
		{"quien": "Kael", "texto": "Este brazalete pesa más cuando no hago nada.",
			"intencion": "Lo que le pesa, dicho de lado", "gesto": "brazalete", "espera": "espera_brazalete"},
		{"quien": "Lya", "texto": "Esta flor no viene en ningún libro. Me la apunto.",
			"intencion": "Curiosidad de estudiosa", "gesto": "duda", "espera": "espera_flor"},
		{"quien": "Garon", "texto": "Parar enfría los hombros. Andando.",
			"intencion": "Veterano; ni el descanso le gusta largo", "gesto": "firme", "espera": "espera_hombros"},
	]},
}

# ENGANCHES: dónde va cada momento y en qué archivo (el responsable de cada escena lo decide).
# Tramos separados por «;», uno por escena: «(hecho)» si ya lo pide y «(pendiente)» si falta (19/11, PC-12: puesto al
# día; prueba_comentarios 1b falla si una escena que ya lo pide no sale nombrada o sigue «pendiente»).
const ENGANCHES := {
	"llegar:oakhaven": "ciudad_oakhaven.gd, al entrar (hecho, con zona.gd _momento_llegada)",
	"cofre": "zona.gd _abrir_cofre (hecho); ciudad_oakhaven.gd (hecho); garganta_3d.gd tras el cofre raro, 1,2 s (hecho)"
		+ "; pastos_verdes_3d.gd tras el premio, 1,2 s (hecho); ciclopea_3d.gd y gran_bosque_3d.gd tras el premio y sus"
		+ " avisos (hecho)",
	"quieto": "ciudad_oakhaven.gd tras 14 s sin moverse (hecho); pastos_verdes_3d.gd tras 14 s sin moverse, QUIETO_COMENTARIO"
		+ " (hecho, prueba_comentarios_3d); en la Garganta, Ciclópea y el Gran Bosque 3D no se pide (pendiente: lo decide"
		+ " quien lleve esas escenas)",
	"llegar:lugar_nuevo": "zona.gd, la primera vez en la sesión que se entra en un lugar (hecho)",
	"llegar:garganta": "la Garganta 2D por zona.gd (hecho); garganta_3d.gd al entrar, a los 2,5 s (hecho)",
	"cascada_garganta": "garganta_3d.gd al acercarse a la cascada, a menos de 12 m de su eje (hecho)",
}


static func dichos() -> Dictionary:
	return Engine.get_meta(META, {})


# Un comentario para el momento, o {} si no toca. «presentes»: quién está (por defecto, el grupo activo).
static func elegir(momento: String, presentes: Array = []) -> Dictionary:
	if not MOMENTOS.has(momento):
		return {}
	if presentes.is_empty():
		presentes = load("res://grupo.gd").activos()
	var d := dichos()
	var m: Dictionary = MOMENTOS[momento]
	if m.get("unico", false) and d.has("@" + momento):
		return {}
	var libres: Array = m["frases"].filter(func(f): return f["quien"] in presentes and not d.has(f["texto"]))
	if libres.is_empty():
		return {}
	# habla quien lleva más tiempo callado (el turno se guarda con los dichos); a igualdad, el orden de la lista
	var turnos: Dictionary = d.get("@turnos", {})
	var elegida: Dictionary = libres[0]
	for x in libres:                               # (sort_custom no es estable: se busca a mano)
		if int(turnos.get(x["quien"], -1)) < int(turnos.get(elegida["quien"], -1)):
			elegida = x
	var f: Dictionary = elegida.duplicate(true)
	var r = f.get("respuesta")
	if r is Dictionary and not r["quien"] in presentes:
		f.erase("respuesta")
	f["momento"] = momento
	return f


# Apunta que se dijo (lo llama mostrar(); las pruebas pueden llamarlo sin interfaz).
static func apuntar(c: Dictionary) -> void:
	var d: Dictionary = dichos().duplicate(true)
	d[c["texto"]] = true
	if MOMENTOS.get(c.get("momento", ""), {}).get("unico", false):
		d["@" + c["momento"]] = true
	var turnos: Dictionary = d.get("@turnos", {})
	turnos[c["quien"]] = int(d.get("@cuenta", 0))
	d["@turnos"] = turnos
	d["@cuenta"] = int(d.get("@cuenta", 0)) + 1
	Engine.set_meta(META, d)


# Lo enseña en una caja pequeña abajo a la derecha (el nombre en su color y la frase) y, si la hay, la respuesta
# después. No toma el foco ni el toque. Devuelve la caja (las pruebas la miran).
static func mostrar(capa: Node, c: Dictionary) -> Control:
	apuntar(c)
	var caja := _caja(c)
	capa.add_child(caja, true)                     # nombre legible («comentario», «comentario2»…): así se reconocen
	var t := caja.create_tween()
	t.tween_property(caja, "modulate:a", 1.0, 0.25)
	t.tween_interval(duracion(c["texto"]))
	t.tween_property(caja, "modulate:a", 0.0, 0.4)
	var r = c.get("respuesta")
	if r is Dictionary:
		t.tween_callback(func():
			if is_instance_valid(capa):
				var segunda := _caja(r)
				capa.add_child(segunda, true)
				var t2 := segunda.create_tween()
				t2.tween_property(segunda, "modulate:a", 1.0, 0.25)
				t2.tween_interval(duracion(r["texto"]))
				t2.tween_property(segunda, "modulate:a", 0.0, 0.4)
				t2.tween_callback(segunda.queue_free))
	t.tween_callback(caja.queue_free)
	return caja


static func duracion(texto: String) -> float:
	return SEGUNDOS_BASE + SEGUNDOS_LETRA * texto.length()


static func _caja(c: Dictionary) -> Control:
	var Estilo = load("res://estilo.gd")
	var panel := PanelContainer.new()
	panel.name = "comentario"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", Estilo.ventana(0.72))
	panel.custom_minimum_size = Vector2(ANCHO, 0)
	panel.modulate.a = 0.0
	panel.set_meta("quien", c["quien"])
	panel.set_meta("texto", c["texto"])
	var v := VBoxContainer.new()
	v.name = "lineas"
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 2)
	panel.add_child(v)
	var nombre := Label.new()
	nombre.text = c["quien"]
	nombre.add_theme_font_override("font", Estilo.cursiva())
	nombre.add_theme_font_size_override("font_size", 24)
	nombre.add_theme_color_override("font_color", COLORES.get(c["quien"], Color.WHITE))
	v.add_child(nombre)
	var frase := Label.new()
	frase.name = "frase"
	frase.text = c["texto"]
	frase.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	frase.custom_minimum_size = Vector2(ANCHO - 28.0, 0)
	frase.add_theme_font_override("font", Estilo.normal())
	frase.add_theme_font_size_override("font_size", 26)
	frase.add_theme_color_override("font_color", Estilo.LUZ_CLARA)
	v.add_child(frase)
	# abajo a la derecha (pantalla de 1280 × 720, project.godot), creciendo hacia arriba y hacia la izquierda
	panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.offset_right = -MARGEN_DERECHO
	panel.offset_bottom = BORDE_INFERIOR - 720.0
	return panel
