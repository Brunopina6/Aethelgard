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
		"hierba": 2400,
		"flores": 280,
		"dist_hierba": 30.0,    # la hierba se deja de dibujar más allá (en trozos)
		"relieve": false,       # sin mapas de relieve (el grano de color se mantiene)
		"luces_faroles": false, # los faroles brillan por emisión, sin luz real
		"refraccion": false,
		"espuma": 30,
		"fps": 30,
	},
	"medio": {
		"escala_3d": 0.9,
		"msaa": 0,
		"sombras": true,
		"dist_sombras": 30.0,
		"hierba": 4200,
		"flores": 450,
		"dist_hierba": 42.0,
		"relieve": true,
		"luces_faroles": true,
		"refraccion": false,
		"espuma": 60,
		"fps": 30,
	},
	"alto": {
		"escala_3d": 1.0,
		"msaa": 2,
		"sombras": true,
		"dist_sombras": 55.0,
		"hierba": 7000,
		"flores": 700,
		"dist_hierba": 80.0,
		"relieve": true,
		"luces_faroles": true,
		"refraccion": true,
		"espuma": 90,
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
