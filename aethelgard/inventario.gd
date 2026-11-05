extends RefCounted
# Inventario del grupo (Godot 4.x): objetos que se gastan, equipo que se lleva y qué lleva cada héroe.
# Se guarda en Engine.get_meta("inventario") para que dure al cambiar de escena.
# Uso desde otro script:  load("res://inventario.gd").arma_de("Kael"), .equipar("Kael", "pies", "botas_cuero")...
# Ranuras de equipo: arma, cabeza, cuerpo, pies, anillo y amuleto.

const RANURAS := ["arma", "escudo", "cabeza", "cuerpo", "pies", "anillo", "amuleto"]
const NOMBRES_RANURA := {"arma": "Arma", "escudo": "Escudo", "cabeza": "Cabeza", "cuerpo": "Cuerpo", "pies": "Pies",
	"anillo": "Anillo", "amuleto": "Amuleto"}

# Armas: "tipo" = espada (espadachines) o cetro (magas y magos). Modelo ligero (empuñadura en el
# origen, hoja hacia +Y, largo 1), texturas, largo en metros y dónde está la punta (en el modelo
# de largo 1). "ataque" se suma al ataque del héroe y "magia" al daño de sus magias.
const ARMAS := {
	"frostfang": {"nombre": "Frostfang", "tipo": "espada", "ataque": 0, "texto": "Sable de hielo de Kael.",
		"modelo": "res://sable.obj", "color": "res://sable_color.jpg", "normal": "res://sable_normal.png",
		"metal": "res://sable_metal.png", "rugosidad": "res://sable_rugosidad.png", "brillo": "",
		"largo": 1.45, "punta": 0.9},
	"colmillo_nocturno": {"nombre": "Colmillo Nocturno", "tipo": "espada", "ataque": 6,
		"texto": "Espada de acero oscuro. Sus filos brillan con luz azul.",
		"modelo": "res://espada2.obj", "color": "res://espada2_color.jpg", "normal": "res://espada2_normal.png",
		"metal": "res://espada2_metal.png", "rugosidad": "res://espada2_rugosidad.png", "brillo": "res://espada2_brillo.png",
		"largo": 1.45, "punta": 0.875},
	"cetro_loto": {"nombre": "Cetro del Loto Lunar", "tipo": "cetro", "ataque": 2, "magia": 8,
		"texto": "Cetro de la maga blanca con una flor de loto de plata.",
		"modelo": "res://vara.obj", "color": "res://vara_color.jpg", "normal": "res://vara_normal.png",
		"metal": "res://vara_metal.png", "rugosidad": "res://vara_rugosidad.png", "brillo": "",
		"largo": 1.05, "punta": 0.55},
	# Espadas de Meshy reducidas (unos 5.000 triángulos, texturas de 1024 con brillo).
	"averno": {"nombre": "Mandoble del Averno", "tipo": "espada", "ataque": 14,
		"texto": "Hoja de roca negra con lava viva entre los pinchos.",
		"modelo": "res://averno.obj", "color": "res://averno_color.jpg", "normal": "res://averno_normal.png",
		"metal": "res://averno_metal.png", "rugosidad": "res://averno_rugosidad.png", "brillo": "res://averno_brillo.png",
		"largo": 1.45, "punta": 0.9},
	"diamante_azul": {"nombre": "Espadón de Diamante Azul", "tipo": "espada", "ataque": 20,
		"texto": "Cristal azul tallado. Canta cuando corta el aire frío.",
		"modelo": "res://diamante_azul.obj", "color": "res://diamante_azul_color.jpg", "normal": "res://diamante_azul_normal.png",
		"metal": "res://diamante_azul_metal.png", "rugosidad": "res://diamante_azul_rugosidad.png", "brillo": "res://diamante_azul_brillo.png",
		"largo": 1.45, "punta": 0.9},
	# Garon lleva dos, una en cada mano (garon_3d.gd). Con su Fuerza inicial (16), cada golpe quita 50.
	"hoja_infernal": {"nombre": "Hojas Infernales", "tipo": "espada", "ataque": 34,
		"texto": "Dos espadones con runas de fuego. Garon los lleva uno en cada mano.",
		"modelo": "res://hoja_infernal.obj", "color": "res://hoja_infernal_color.jpg", "normal": "res://hoja_infernal_normal.png",
		"metal": "res://hoja_infernal_metal.png", "rugosidad": "res://hoja_infernal_rugosidad.png", "brillo": "res://hoja_infernal_brillo.png",
		"largo": 1.1, "punta": 0.9},
}

# Protecciones y accesorios: "bonus" suma atributos (fuerza, magia, defensa, velocidad, vitalidad,
# espiritu). "para" = quién puede llevarlo: "todos", "espada" (espadachines) o "cetro" (magos).
const PROTECCIONES := {
	"cinta_cuero": {"nombre": "Cinta de cuero", "ranura": "cabeza", "para": "todos", "bonus": {"defensa": 1}, "texto": "Sujeta el pelo y para algún golpe."},
	"yelmo_hierro": {"nombre": "Yelmo de hierro", "ranura": "cabeza", "para": "espada", "bonus": {"defensa": 4, "velocidad": -1}, "texto": "Pesado pero resistente."},
	"diadema_plata": {"nombre": "Diadema de plata", "ranura": "cabeza", "para": "cetro", "bonus": {"defensa": 2, "magia": 2}, "texto": "Concentra la mente al conjurar."},
	"ropa_viaje": {"nombre": "Ropa de viaje", "ranura": "cuerpo", "para": "todos", "bonus": {"defensa": 2}, "texto": "Cómoda para caminar lejos."},
	"cota_malla": {"nombre": "Cota de malla", "ranura": "cuerpo", "para": "espada", "bonus": {"defensa": 6, "velocidad": -1}, "texto": "Anillas de acero entrelazadas."},
	"tunica_lino": {"nombre": "Túnica de lino", "ranura": "cuerpo", "para": "cetro", "bonus": {"defensa": 3, "espiritu": 2}, "texto": "Bordada con runas de calma."},
	"botas_cuero": {"nombre": "Botas de cuero", "ranura": "pies", "para": "todos", "bonus": {"defensa": 1, "velocidad": 1}, "texto": "Suela gruesa para cualquier camino."},
	"botas_aladas": {"nombre": "Botas aladas", "ranura": "pies", "para": "todos", "bonus": {"velocidad": 4}, "texto": "Parecen no pesar nada."},
	"anillo_fuerza": {"nombre": "Anillo de fuerza", "ranura": "anillo", "para": "todos", "bonus": {"fuerza": 3}, "texto": "Hierro negro con una runa de toro."},
	"anillo_rubi": {"nombre": "Anillo de rubí", "ranura": "anillo", "para": "todos", "bonus": {"magia": 4}, "texto": "El rubí se calienta al conjurar."},
	"amuleto_vida": {"nombre": "Amuleto de vida", "ranura": "amuleto", "para": "todos", "bonus": {"vitalidad": 3}, "texto": "Late como un corazón."},
	"escudo_madera": {"nombre": "Escudo de madera", "ranura": "escudo", "para": "espada", "bonus": {"defensa": 3}, "texto": "Tablas reforzadas con hierro."},
	"escudo_hierro": {"nombre": "Escudo de hierro", "ranura": "escudo", "para": "espada", "bonus": {"defensa": 6, "velocidad": -1}, "texto": "Para los golpes de los orcos."},
	"escudo_runico": {"nombre": "Escudo rúnico", "ranura": "escudo", "para": "espada", "bonus": {"defensa": 8, "espiritu": 2}, "texto": "Sus runas brillan ante la magia."},
	"orbe_proteccion": {"nombre": "Orbe de protección", "ranura": "escudo", "para": "cetro", "bonus": {"defensa": 3, "magia": 2}, "texto": "Una esfera de luz que flota junto a su dueña."},
	"colgante_luna": {"nombre": "Colgante de luna", "ranura": "amuleto", "para": "todos", "bonus": {"espiritu": 3}, "texto": "Brilla un poco en la oscuridad."},
}

# Lo que lleva el grupo al empezar.
const INICIAL := {
	"oro": 150,
	"objetos": {"Poción": 5, "Éter": 3},
	"equipables": ["frostfang", "colmillo_nocturno", "cetro_loto", "cinta_cuero", "yelmo_hierro", "diadema_plata",
		"ropa_viaje", "cota_malla", "tunica_lino", "botas_cuero", "botas_aladas", "anillo_fuerza", "anillo_rubi",
		"amuleto_vida", "colgante_luna", "hoja_infernal"],
	"equipo": {"Kael": {"arma": "frostfang", "cuerpo": "ropa_viaje", "pies": "botas_cuero"},
		"Lya": {"arma": "cetro_loto", "cuerpo": "tunica_lino"},
		"Garon": {"arma": "hoja_infernal"}},
}


static func datos() -> Dictionary:
	if not Engine.has_meta("inventario"):
		Engine.set_meta("inventario", INICIAL.duplicate(true))
	var d: Dictionary = Engine.get_meta("inventario")
	if not "hoja_infernal" in d["equipables"]:      # partidas de antes de que llegara Garon
		d["equipables"].append("hoja_infernal")
	if not d["equipo"].has("Garon"):
		d["equipo"]["Garon"] = {"arma": "hoja_infernal"}
	return d


static func cantidad(objeto: String) -> int:
	return datos()["objetos"].get(objeto, 0)


static func gastar(objeto: String) -> void:
	var o: Dictionary = datos()["objetos"]
	o[objeto] = maxi(0, o.get(objeto, 0) - 1)


static func agregar(id: String) -> void:
	if objeto(id).is_empty() or id in datos()["equipables"]:
		return
	datos()["equipables"].append(id)


# Datos de un arma o protección por su id (o {} si no existe).
static func objeto(id: String) -> Dictionary:
	if ARMAS.has(id):
		var a: Dictionary = ARMAS[id].duplicate()
		a["ranura"] = "arma"
		a["para"] = a["tipo"]
		return a
	return PROTECCIONES.get(id, {})


static func equipo_de(heroe: String) -> Dictionary:
	if not datos()["equipo"].has(heroe):
		datos()["equipo"][heroe] = {}
	return datos()["equipo"][heroe]


# ¿Puede este héroe llevar este objeto? (las espadas solo los espadachines, los cetros solo los magos)
static func puede_llevar(heroe: String, id: String) -> bool:
	var o := objeto(id)
	if o.is_empty():
		return false
	var tipo: String = load("res://grupo.gd").tipo_arma(heroe) if ResourceLoader.exists("res://grupo.gd") else ""
	return o["para"] == "todos" or o["para"] == tipo


# Quién lleva puesto un objeto ("" si nadie).
static func quien_lleva(id: String) -> String:
	for h in datos()["equipo"]:
		if id in datos()["equipo"][h].values():
			return h
	return ""


# Equipa un objeto en su ranura (si otro héroe lo llevaba, se lo quita). id "" = quitar.
static func equipar(heroe: String, ranura: String, id: String) -> bool:
	if id == "":
		equipo_de(heroe).erase(ranura)
		return true
	if not id in datos()["equipables"] or not puede_llevar(heroe, id) or objeto(id)["ranura"] != ranura:
		return false
	var otro := quien_lleva(id)
	if otro != "":
		equipo_de(otro).erase(ranura)
	equipo_de(heroe)[ranura] = id
	return true


# Objetos que podría ponerse un héroe en una ranura (los suyos y los que nadie lleva).
static func opciones(heroe: String, ranura: String) -> Array:
	var r: Array = []
	for id in datos()["equipables"]:
		if objeto(id)["ranura"] == ranura and puede_llevar(heroe, id):
			r.append(id)
	return r


# Datos del arma que lleva un héroe (o {} si no lleva ninguna).
static func arma_de(heroe: String) -> Dictionary:
	return ARMAS.get(equipo_de(heroe).get("arma", ""), {})


# Texto corto con lo que da un objeto: "+6 Ataque  +2 Defensa".
static func resumen(id: String) -> String:
	var o := objeto(id)
	var partes := PackedStringArray()
	if o.get("ataque", 0) != 0:
		partes.append("%+d Ataque" % o["ataque"])
	if o.get("magia", 0) != 0:
		partes.append("%+d daño mágico" % o["magia"])
	var nombres := {"fuerza": "Fuerza", "magia": "Magia", "defensa": "Defensa", "velocidad": "Velocidad",
		"vitalidad": "Vitalidad", "espiritu": "Espíritu"}
	for k in o.get("bonus", {}):
		partes.append("%+d %s" % [o["bonus"][k], nombres[k]])
	return "  ".join(partes)


# ---------------------------------------------------------------- monedas

static func oro() -> int:
	return datos().get("oro", 0)


static func ganar_oro(n: int) -> void:
	datos()["oro"] = oro() + n


static func gastar_oro(n: int) -> bool:
	if oro() < n:
		return false
	datos()["oro"] = oro() - n
	return true


static func agregar_objeto(nombre: String, n := 1) -> void:
	var o: Dictionary = datos()["objetos"]
	o[nombre] = o.get(nombre, 0) + n