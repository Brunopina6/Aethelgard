extends RefCounted
# Oakhaven vivo (narrativa, 09/11): lo que dicen los vecinos y la gente al pasar cerca, sin abrir un diálogo ni parar a
# Kael. Solo datos y la elección de la frase: la ciudad 2D (ciudad_oakhaven.gd) los pinta sobre la cabeza de quien
# habla; el Oakhaven 3D (T-103, gráficos) puede usar lo mismo con un Label3D.
#
#   const Vida := preload("res://ciudades/oakhaven_vida.gd")
#   var t := Vida.frase("posadera", "anochecer", dichos)    # "" si no hay ninguna que toque
#
# QUÉ CAMBIA: cada frase puede pedir una condición «si» (la misma sintaxis que ciudades/oakhaven.gd, cumple(): hitos,
# estados de la ciudad, decisiones, grupo…) y una «franja»: «anochecer» (al llegar a la ciudad, la hora azul del arte) o
# «manana» (después de dormir en la posada, hasta salir). La franja no se guarda: sale de lo que pasa en la visita.
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
		{"texto": "Mi abuela dice que no hable con mayores.", "franja": "anochecer"},
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
		{"texto": "¡Otra ronda para la mesa del fondo!", "franja": "anochecer"},
		{"texto": "¡Que alguien cante algo alegre!", "franja": "anochecer"},
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
	var tocan: Array = frases_de(id).filter(func(f): return f.get("franja", franja) == franja \
		and (not f.has("si") or Oak.cumple(f["si"])))
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
