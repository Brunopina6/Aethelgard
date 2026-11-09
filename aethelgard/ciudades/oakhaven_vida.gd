extends RefCounted
# Oakhaven vivo (narrativa, 09/11): lo que dicen los vecinos y la gente al pasar cerca, sin abrir un diálogo ni parar a
# Kael. Solo datos y la elección de la frase: la ciudad 2D (ciudad_oakhaven.gd) los pinta sobre la cabeza de quien
# habla; el Oakhaven 3D (T-103, gráficos) puede usar lo mismo con un Label3D.
#
#   const Vida := preload("res://ciudades/oakhaven_vida.gd")
#   var t := Vida.frase("posadera", "anochecer", dichos)    # "" si no hay ninguna que toque
#
# QUÉ CAMBIA: cada frase puede pedir una condición «si» (la misma sintaxis que ciudades/oakhaven.gd, cumple(): hitos,
# estados de la ciudad, decisiones, grupo…) y una «franja» (o varias, en una lista): «manana», «tarde» o «anochecer».
# LA FRANJA (FRANJAS): no hay reloj en el juego. Al llegar a la ciudad es la tarde (la hora azul del arte); tras
# DURACION_FRANJA segundos en ella, el anochecer, que dura hasta dormir; al despertar en la posada, la mañana, y tras
# DURACION_FRANJA, otra vez la tarde. Se recuerda en la sesión (Engine «oak_franja»), no en la partida.
# RUTINAS: dónde está cada vecino en cada franja, qué hace y una frase suya de esa hora. FAUNA: gatos, palomas y
# gallinas, como datos (sin modelos nuevos: en 3D, fauna_simple.gd; en 2D, aún sin dibujo).
# CUÁNTO: una frase en pantalla como mucho; PAUSA segundos entre dos; PAUSA_QUIEN antes de que la misma persona vuelva
# a hablar; y cada frase, una vez por visita («dichos»), hasta que se acaban las que tocan y se empieza de nuevo.
# Nada de lo que espera decisión del usuario (D-073) ni de Érebo (D-033): lo comprueba prueba_oakhaven_vida.

const RADIO := 3.2                    # casillas: a esta distancia de Kael, la persona puede decir algo
const PAUSA := 7.0                    # s entre dos frases (de quien sea)
const PAUSA_QUIEN := 30.0             # s antes de que la misma persona vuelva a hablar
const SEGUNDOS := 3.2                 # en pantalla: base + por letra
const SEGUNDOS_LETRA := 0.03
const LARGO_MAX := 48                 # una línea sobre la cabeza, legible en el móvil

# Los ocho vecinos (ids de ciudades/oakhaven.gd, NPCS). Sin condición, siempre pueden salir.
const VECINOS := {
	"aldric": [
		{"texto": "Tres faroles apagados en la muralla. Mal asunto.", "si": "!hito:oak_faroles"},
		{"texto": "Faroles encendidos, puerta cerrada. Así sí.", "si": "hito:oak_faroles"},
		{"texto": "Otra noche sin Hollines. De momento.", "franja": "anochecer"},
		{"texto": "Buenos días. Lo que la niebla deje de ellos.", "franja": "manana"},
	],
	"selene": [
		{"texto": "¿Llevas Éter? Hazme caso: lleva Éter."},
		{"texto": "Esa niebla huele a magia vieja."},
		{"texto": "Saluda a Lya de mi parte. Y cuídala.", "si": "!grupo:Lya"},
		{"texto": "Lya, cuida de ese. Corre demasiado.", "si": "grupo:Lya"},
	],
	"pip": [
		{"texto": "Psst. Yo no estoy aquí."},
		{"texto": "Una moneda, un secreto. Oferta del día.", "si": "!decision:pip_oak=pagado"},
		{"texto": "Lo del callejón, ni una palabra.", "si": "decision:pip_oak=pagado"},
		{"texto": "¿Ese cucharón? Me lo encontré. En una cocina.", "si": ["estado:favores", "!estado:favor_cucharon"]},
	],
	"rosa": [
		{"texto": "¡Flores para la mesa! Para quien las pague."},
		{"texto": "Ojalá alguien pasara por los Pastos…", "si": ["estado:lavanda", "!hito:oak_lavanda"]},
		{"texto": "El Árbol huele a lavanda. ¡Gracias otra vez!", "si": "hito:oak_lavanda"},
		{"texto": "Buenos días. Las flores madrugan más que yo.", "franja": "manana"},
	],
	"posadera": [
		{"texto": "¡Sopa caliente! Y silencio, si el fondo calla."},
		{"texto": "Ese cucharón no vuelve solo, ¿eh?", "si": ["estado:favores", "!hito:oak_favores"]},
		{"texto": "Lo de hoy no se olvida. Esta noche invito yo.", "si": ["hito:oak_favores", "estado:noche_gratis"]},
		{"texto": "¿Ya en pie? El pan acaba de salir.", "franja": "manana"},
	],
	"albar": [
		{"texto": "Paso tranquilo, muchacho. Aquí nadie corre."},
		{"texto": "El fuego no tiene prisa. Yo tampoco."},
		{"texto": "La puerta, ni mirarla. Ya lo sabes."},
	],
	"bastian": [
		{"texto": "¡Ciento nueve! …Sí. Ciento nueve.", "si": "!hito:oak_faroles"},
		{"texto": "¡Ciento doce! Los he contado dos veces.", "si": "hito:oak_faroles"},
		{"texto": "¿Has subido a la torre? ¡Se ve todo!", "si": "estado:vista_torre"},
		{"texto": "Mi abuela dice que no hable con mayores."},
	],
	"encina": [
		{"texto": "Shh. El roble está escuchando."},
		{"texto": "Dos mil anillos y uno negro. Siempre el negro."},
		{"texto": "Huele a lavanda. Al roble le gusta.", "si": "hito:oak_lavanda"},
	],
}

# La gente sin nombre: voces desde una puerta, una ventana o un puesto. «casilla»: de dónde sale la voz (en
# ciudades/oakhaven.gd, coordenadas de casilla, en una calle o junto a ella).
const VOCES := [
	{"id": "voz_taberna", "nombre": "Desde la taberna", "casilla": Vector2(18, 25.6), "frases": [
		{"texto": "¡Otra ronda para la mesa del fondo!", "franja": ["tarde", "anochecer"]},
		{"texto": "¡Que alguien cante algo alegre!", "franja": ["tarde", "anochecer"]},
		{"texto": "¡Eso no es cantar, es ladrar!", "franja": "anochecer"},
		{"texto": "¿Quién se ha comido mi pan?", "franja": "manana"},
	]},
	{"id": "voz_mercado", "nombre": "Un vendedor", "casilla": Vector2(55, 29.5), "frases": [
		{"texto": "¡Manzanas de los Pastos! ¡Maduras, no verdes!"},
		{"texto": "¡Telas finas! ¡Para la boda o para el frío!"},
		{"texto": "¡Recién llegado de Sunken City! Bueno, casi."},
	]},
	{"id": "voz_plaza", "nombre": "Unos niños", "casilla": Vector2(41, 27), "frases": [
		{"texto": "¡Te pillé! ¡Ahora la llevas tú!", "franja": "manana"},
		{"texto": "¡El último en la fuente es un Hollín!"},
		{"texto": "¡Ha subido alguien a la torre!", "si": "estado:vista_torre"},
	]},
	{"id": "voz_guardia", "nombre": "Un guardia", "casilla": Vector2(44.5, 46.5), "frases": [
		{"texto": "Ronda de noche: tres vueltas y a dormir.", "franja": "anochecer"},
		{"texto": "¿Quién ha dejado este libro abierto?"},
		{"texto": "Los faroles de la muralla, encendidos. Bien.", "si": "hito:oak_faroles"},
	]},
]


# Las franjas, en orden, y lo que suena en cada una (sonido.gd, fijar_momento).
const FRANJAS := ["manana", "tarde", "anochecer"]
const MOMENTO_SONIDO := {"manana": "dia", "tarde": "tarde", "anochecer": "noche"}
const FRANJA_AL_LLEGAR := "tarde"
const DURACION_FRANJA := 240.0              # s de juego en la ciudad hasta que pasa a la siguiente (no tras el anochecer)

# Qué hace un vecino («hace»): «quieto», «trabaja» (lo suyo, en su sitio), «mira» (vigila o contempla) o «pasea» (va y
# viene entre «casilla» y «hasta»). En 2D: quietos los tres primeros (respiran, como siempre) y el paseo, de verdad; en
# 3D, la animación que gráficos tenga más parecida (reposo, gesto de trabajo, mirar, andar).
const HACE := ["quieto", "trabaja", "mira", "pasea"]

# Las rutinas de los ocho vecinos. La tarde es su sitio de siempre (ciudades/oakhaven.gd, NPCS: «casilla»), y así al
# llegar todo está donde estaba. La posadera no se mueve de la puerta del Cuervo (la posada y sus favores). Casillas de
# ciudades/oakhaven.gd (calles, plazas y patios; lejos de lo que se examina: lo comprueba prueba_oakhaven_rutinas).
const RUTINAS := {
	"aldric": {
		"manana": {"casilla": Vector2(38.5, 53.5), "hace": "mira", "donde": "Puerta del Sur, mirando el camino",
			"frase": "Puerta abierta. Que pase quien venga en paz."},
		"tarde": {"casilla": Vector2(40, 49.5), "hace": "quieto", "donde": "de guardia en la Puerta del Sur",
			"frase": "Sin novedad. Como debe ser."},
		"anochecer": {"casilla": Vector2(38.5, 52.5), "hasta": Vector2(42.5, 52.5), "hace": "pasea",
			"donde": "rondando la Puerta del Sur", "frase": "De noche no sale nadie. Ni tú, muchacho."},
	},
	"selene": {
		"manana": {"casilla": Vector2(36, 41), "hace": "trabaja", "donde": "ordenando la botica",
			"frase": "Hierbas frescas. Las mejores, antes del sol."},
		"tarde": {"casilla": Vector2(36, 41), "hace": "quieto", "donde": "a la puerta de la botica",
			"frase": "La botica cierra tarde. La magia, nunca."},
		"anochecer": {"casilla": Vector2(43, 23.5), "hace": "mira", "donde": "tomando el fresco junto a la fuente",
			"frase": "El agua suena distinta de noche."},
	},
	"pip": {
		"manana": {"casilla": Vector2(49, 31), "hasta": Vector2(58, 31), "hace": "pasea", "donde": "merodeando por el mercado",
			"frase": "Solo miro. Mirar es gratis, ¿no?"},
		"tarde": {"casilla": Vector2(23.5, 30), "hace": "quieto", "donde": "en el callejón del Cuervo",
			"frase": "Este callejón es mío. Bueno, casi."},
		"anochecer": {"casilla": Vector2(8, 26), "hace": "mira", "donde": "rondando la puerta del Cuervo",
			"frase": "A esta hora, la taberna cuenta secretos."},
	},
	"rosa": {
		"manana": {"casilla": Vector2(44, 29), "hace": "trabaja", "donde": "montando el puesto de flores",
			"frase": "Recién cogidas. Huelen a mañana."},
		"tarde": {"casilla": Vector2(44, 29), "hace": "quieto", "donde": "en su puesto de flores",
			"frase": "Las que quedan, a mitad de precio."},
		"anochecer": {"casilla": Vector2(40, 19.5), "hasta": Vector2(40, 14), "hace": "pasea",
			"donde": "llevando flores al Árbol por la Calle del Árbol", "frase": "Las que sobran, para el Árbol."},
	},
	"posadera": {
		"manana": {"casilla": Vector2(16, 26), "hace": "trabaja", "donde": "barriendo la puerta del Cuervo",
			"frase": "Primero se barre. Luego, se abre."},
		"tarde": {"casilla": Vector2(16, 26), "hace": "quieto", "donde": "a la puerta del Cuervo",
			"frase": "¡Hay sitio dentro! Poco, pero hay."},
		"anochecer": {"casilla": Vector2(16, 26), "hace": "trabaja", "donde": "sirviendo en la puerta del Cuervo",
			"frase": "La última ronda siempre es la penúltima."},
	},
	"albar": {
		"manana": {"casilla": Vector2(59.5, 11.5), "hace": "trabaja", "donde": "cuidando el jardín de urnas",
			"frase": "Las urnas también quieren sol."},
		"tarde": {"casilla": Vector2(63, 17), "hace": "quieto", "donde": "junto al crematorio",
			"frase": "Buena tarde para no tener prisa."},
		"anochecer": {"casilla": Vector2(61, 17.5), "hace": "mira", "donde": "mirando el humo blanco de la chimenea",
			"frase": "El humo sube recto. Noche tranquila."},
	},
	"bastian": {
		"manana": {"casilla": Vector2(50, 26), "hasta": Vector2(66, 26), "hace": "pasea",
			"donde": "contando los faroles de la Calle del Mercado", "frase": "Uno, dos, tres… ¡Este está torcido!"},
		"tarde": {"casilla": Vector2(40, 43), "hace": "quieto", "donde": "en la Calle Mayor",
			"frase": "Pronto los encienden. ¡Me encanta!"},
		"anochecer": {"casilla": Vector2(39.6, 34), "hasta": Vector2(39.6, 47), "hace": "pasea",
			"donde": "de farol en farol por la Calle Mayor", "frase": "¡Encendido! ¡Y ese! ¡Y ese también!"},
	},
	"encina": {
		"manana": {"casilla": Vector2(35, 10), "hace": "trabaja", "donde": "contando anillos en las raíces",
			"frase": "Mil novecientos… ¿por dónde iba?"},
		"tarde": {"casilla": Vector2(35, 10), "hace": "quieto", "donde": "en las raíces del Árbol",
			"frase": "Habla bajo. Aquí todo escucha."},
		"anochecer": {"casilla": Vector2(33, 6), "hace": "mira", "donde": "sentada entre las raíces, mirando la copa",
			"frase": "De noche, el Árbol cruje como un barco."},
	},
}

# Fauna de la ciudad, solo datos (sin modelos nuevos). «sitios»: casillas donde aparecen; «cuantos»: a la vez;
# «franjas»: cuándo; «hace»: lo que hacen; «como»: el comportamiento de prototipos/fauna_simple.gd que vale en 3D
# (el conejo da saltitos por su zona y huye si Kael se acerca; el pájaro planea en círculos).
const FAUNA := [
	{"tipo": "gato", "sitios": [Vector2(13, 31), Vector2(24, 33), Vector2(34, 42)], "cuantos": 2,
		"franjas": ["manana", "tarde", "anochecer"], "hace": "duerme al sol o se escabulle si Kael se acerca", "como": "conejo"},
	{"tipo": "paloma", "sitios": [Vector2(38, 27), Vector2(44, 25.5), Vector2(41, 29.5)], "cuantos": 3,
		"franjas": ["manana", "tarde"], "hace": "picotea junto a la fuente y vuela si Kael pasa cerca", "como": "conejo"},
	{"tipo": "paloma", "sitios": [Vector2(40, 22)], "cuantos": 2, "franjas": ["manana", "tarde"],
		"hace": "da vueltas sobre la plaza", "como": "pajaro"},
	{"tipo": "gallina", "sitios": [Vector2(46, 51), Vector2(47.5, 50)], "cuantos": 2, "franjas": ["manana", "tarde"],
		"hace": "picotea en el patio de la guardia", "como": "conejo"},
	{"tipo": "gato", "sitios": [Vector2(60, 11)], "cuantos": 1, "franjas": ["anochecer"],
		"hace": "vigila el jardín de urnas desde un muro", "como": "conejo"},
]


static func rutina(id: String, franja: String) -> Dictionary:
	return RUTINAS.get(id, {}).get(franja, {})


static func franja_siguiente(franja: String) -> String:
	match franja:
		"manana":
			return "tarde"
		"tarde":
			return "anochecer"
	return franja                                  # el anochecer dura hasta dormir


static func fauna_de(franja: String) -> Array:
	return FAUNA.filter(func(f): return franja in f["franjas"])


static func _toca_franja(f: Dictionary, franja: String) -> bool:
	var x = f.get("franja", franja)
	return franja in x if x is Array else x == franja


# Las frases de alguien (vecino o voz).
static func frases_de(id: String) -> Array:
	if VECINOS.has(id):
		return VECINOS[id]
	for v in VOCES:
		if v["id"] == id:
			return v["frases"]
	return []


# Una frase que toque ahora: que cumpla su condición y su franja y que no se haya dicho en esta visita («dichos»:
# texto → true). Si ya se dijeron todas las que tocan, vuelve a empezar (se borran las suyas de «dichos»).
static func frase(id: String, franja: String, dichos: Dictionary) -> String:
	var Oak = load("res://ciudades/oakhaven.gd")
	var tocan: Array = frases_de(id).filter(func(f): return _toca_franja(f, franja) \
		and (not f.has("si") or Oak.cumple(f["si"])))
	var r := rutina(id, franja)                    # y la de su rutina a esa hora
	if r.has("frase"):
		tocan.append({"texto": r["frase"], "franja": franja})
	if tocan.is_empty():
		return ""
	var libres: Array = tocan.filter(func(f): return not dichos.has(f["texto"]))
	if libres.is_empty():
		for f in tocan:
			dichos.erase(f["texto"])
		libres = tocan
	# las que dependen de la partida (con condición o con franja) primero: dicen que la ciudad se ha dado cuenta
	for f in libres:
		if f.has("si") or f.has("franja"):
			return f["texto"]
	return libres[0]["texto"]


static func duracion(texto: String) -> float:
	return SEGUNDOS + SEGUNDOS_LETRA * texto.length()


static func nombre_de(id: String) -> String:
	for v in VOCES:
		if v["id"] == id:
			return v["nombre"]
	return ""
