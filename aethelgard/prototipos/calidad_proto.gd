extends RefCounted
# Perfiles de calidad del prototipo (Skill aet-calidad-adaptable). Todas las escenas de prueba leen
# estos valores; no copian números. El estilo es el mismo en los tres: cambian cantidades y distancias.
#   bajo:  móviles modestos (el Redmi de pruebas), objetivo 30 FPS estables (a medir).
#   medio: equilibrio.
#   alto:  la referencia artística para dispositivos potentes (PC, iPhone 15 Pro Max, a medir).
# El perfil alto NUNCA se rebaja para que quepa el bajo.

const PERFILES := {
	"bajo": {
		"escala_3d": 0.75,      # el 3D se dibuja al 75 % y se amplía; la interfaz va a resolución completa
		"msaa": 0,
		"sombras": false,
		"dist_sombras": 0.0,
		"sombra_tramos": 0,
		"sombra_res": 2048,
		"hierba": 2400,
		"flores": 280,
		"dist_hierba": 30.0,    # la hierba se deja de dibujar más allá (en trozos)
		"relieve": false,       # sin mapas de relieve (el grano de color se mantiene)
		"luces_faroles": false, # los faroles brillan por emisión, sin luz real
		"refraccion": false,
		"reflejo_cielo": false, # Pastos Verdes: sin reflejo del cielo (medido en el Redmi: −3,3 ms a 20 m; brillo −0,7 %)
		"espuma": 30,
		"arbol_matas": 0.65,     # árboles: menos matas y algo más grandes (medido en el Redmi)
		"arbol_sombra_simple": true,
		"fps": 30,
	},
	"medio": {
		"escala_3d": 0.9,
		"msaa": 0,
		"sombras": true,
		"dist_sombras": 30.0,
		"sombra_tramos": 2,       # 2 tramos en vez de los 4 de Godot: la escena se pinta 2 veces menos para la sombra
		"sombra_res": 2048,
		"hierba": 4200,
		"flores": 450,
		"dist_hierba": 42.0,
		"relieve": true,
		"luces_faroles": false, # medido en el Redmi: −7 ms; halo falso en su lugar
		"refraccion": false,
		"reflejo_cielo": false, # medido en el Redmi: −3,3 ms a 20 m y −8 ms a 34 m (ronda 8)
		"espuma": 60,
		"arbol_matas": 0.65,
		"arbol_sombra_simple": true,  # sombra de la copa con forma sencilla (la de hoja a hoja costaba mucho)
		"fps": 30,
	},
	"alto": {
		"escala_3d": 1.0,
		"msaa": 2,
		"sombras": true,
		"dist_sombras": 55.0,
		"sombra_tramos": 2,
		"sombra_res": 4096,
		"hierba": 7000,
		"flores": 700,
		"dist_hierba": 80.0,
		"relieve": true,
		"luces_faroles": true,
		"refraccion": true,
		"reflejo_cielo": true,  # alto: el reflejo original del cielo (referencia de máxima calidad)
		"espuma": 90,
		"arbol_matas": 1.0,
		"arbol_sombra_simple": false, # alto: todas las matas y sombra hoja a hoja
		"fps": 60,
	},
}
const ORDEN := ["bajo", "medio", "alto"]


# Perfil en uso: el elegido con el botón (se recuerda mientras la app está abierta); si no, por defecto
# bajo en móviles y alto en PC. «-- movil» en la línea de órdenes fuerza el bajo (pruebas).
static func actual() -> String:
	if Engine.has_meta("calidad_proto"):
		return Engine.get_meta("calidad_proto")
	if "movil" in OS.get_cmdline_user_args() or OS.has_feature("mobile"):
		return "bajo"
	return "alto"


# Pruebas A/B (Skill aet-rendimiento-android: quitar una cosa cada vez): Engine.set_meta("calidad_extra",
# {"sombras": false}) cambia solo esos valores sobre el perfil en uso.
static func datos() -> Dictionary:
	var d: Dictionary = PERFILES[actual()].duplicate()
	if Engine.has_meta("calidad_extra"):
		d.merge(Engine.get_meta("calidad_extra"), true)
	return d


static func siguiente() -> String:
	return ORDEN[(ORDEN.find(actual()) + 1) % ORDEN.size()]
