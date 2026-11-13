extends RefCounted
# Perfiles de calidad del prototipo (Skill aet-calidad-adaptable). Todas las escenas de prueba leen
# estos valores; no copian números. El estilo es el mismo en los tres: cambian cantidades y distancias.
#   bajo:  móviles modestos (el Redmi de pruebas), objetivo 30 FPS estables (a medir).
#   medio: equilibrio.
#   alto:  la referencia artística para dispositivos potentes (PC, iPhone 15 Pro Max, a medir).
# El perfil alto NUNCA se rebaja para que quepa el bajo.
# Qué perfil usa cada aparato, su límite de FPS y los recortes del ajuste dinámico: calidad_auto.gd (detección,
# ajustes guardados en user://ajustes.cfg [calidad] y escalones) y regulador_calidad.gd (calibración y ajuste
# dinámico mientras se juega, desde vista3d.gd). Aquí solo están los valores de cada perfil.

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
	# Medio (09/11, decisión del coordinador con las medidas del Redmi, v336, banco MEDIO con tope de 30): el
	# candidato B. El de antes (0,9 · 2 tramos a 30 m · 4200/450 hierba/flores a 42 m) daba 27,1 FPS, p95 42,2 ms;
	# este, 30,3 FPS, mediana 33,3 y p95 34,3 ms a 20 m (174 dibujos, 373k triángulos). A 34 m, 27,7 FPS: ahí actúa
	# el ajuste dinámico (primero la resolución: 0,8 → 0,75 → 0,7; calidad_auto.ESCALONES). Limita la GPU (CPU 7 ms).
	"medio": {
		"escala_3d": 0.8,
		"msaa": 0,
		"sombras": true,
		"dist_sombras": 24.0,
		"sombra_tramos": 1,       # un tramo (antes 2): medido en el Redmi, junto con la escala, cand A/B
		"sombra_res": 2048,
		"hierba": 3000,
		"flores": 350,
		"dist_hierba": 34.0,
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


# Perfil en uso: el elegido con el botón CAL o un banco de medidas (se recuerda mientras la app está abierta);
# «-- movil» en la línea de órdenes fuerza el bajo (pruebas); si no, el de Ajustes o el que eligió el sistema
# (calidad_auto.gd). Sin nada guardado y sin ventana (pruebas), como antes: bajo en móviles y alto en PC.
static func actual() -> String:
	if Engine.has_meta("calidad_proto"):
		return Engine.get_meta("calidad_proto")
	if "movil" in OS.get_cmdline_user_args():
		return "bajo"
	return load("res://prototipos/calidad_auto.gd").perfil_en_uso(legado())


static func legado() -> String:
	return "bajo" if OS.has_feature("mobile") else "alto"


# ¿Lo decide el jugador o una prueba (CAL, bancos, «-- movil»)? Entonces el sistema no calibra ni recorta nada.
static func fijado_a_mano() -> bool:
	if Engine.has_meta("calidad_proto") or "movil" in OS.get_cmdline_user_args():
		return true
	return not load("res://prototipos/calidad_auto.gd").estado()["auto"]


# Valores del perfil en uso. Con el perfil del sistema (automática) llevan los recortes del ajuste dinámico que se
# hayan necesitado en este aparato, y «fps» es el límite en uso (calidad_auto.fps_de: 60 solo con «alto» medido o
# elegido por el jugador). Con CAL o un banco, el perfil tal cual, como antes.
# Pruebas A/B (Skill aet-rendimiento-android: quitar una cosa cada vez): Engine.set_meta("calidad_extra",
# {"sombras": false}) cambia solo esos valores sobre el perfil en uso.
static func datos() -> Dictionary:
	var nombre := actual()
	var d: Dictionary = PERFILES[nombre].duplicate()
	if not Engine.has_meta("calidad_proto") and not "movil" in OS.get_cmdline_user_args():
		var auto = load("res://prototipos/calidad_auto.gd")
		var e: Dictionary = auto.estado()
		d["fps"] = auto.fps_de(nombre, e, int(d["fps"]))
		d.merge(auto.recortes(nombre, auto.nivel_de(nombre, e)), true)
	d.merge(extra_pruebas(), true)
	if Engine.has_meta("calidad_extra"):
		d.merge(Engine.get_meta("calidad_extra"), true)
	return d


# Pruebas de rendimiento en el teléfono (13/11, Redmi): las mejoras del Gran Bosque que van APAGADAS por defecto se
# pueden encender desde Ajustes, SOLO en la APK de Auditoría o en el editor (user://ajustes.cfg, [calidad_pruebas]).
# En las versiones normales no se leen nunca. Se notan al volver a entrar en la región.
const EXTRA_PRUEBAS := {
	"gb_matas_casco": {"nombre": "Matas recortadas (octógono)", "valores": {"gb_matas_casco": true}},
	"gb_hojas_mipmaps": {"nombre": "Hojas con mipmaps (sesgo −1)",
		"valores": {"gb_hojas_mipmaps": true, "gb_hojas_mip_sesgo": -1.0}},
}
static var _extra_cache = null


static func pruebas_permitidas() -> bool:
	return OS.has_feature("auditoria") or OS.has_feature("editor")


static func extra_activo(clave: String) -> bool:
	if not pruebas_permitidas():
		return false
	var c := ConfigFile.new()
	if c.load("user://ajustes.cfg") != OK:
		return false
	return bool(c.get_value("calidad_pruebas", clave, false))


static func extra_pruebas() -> Dictionary:
	if _extra_cache != null:
		return _extra_cache
	var r := {}
	for clave in EXTRA_PRUEBAS:
		if extra_activo(clave):
			r.merge(EXTRA_PRUEBAS[clave]["valores"], true)
	_extra_cache = r
	return r


static func elegir_extra(clave: String, si: bool) -> Error:
	if not pruebas_permitidas() or not EXTRA_PRUEBAS.has(clave):
		return ERR_UNAUTHORIZED
	var c := ConfigFile.new()
	if FileAccess.file_exists("user://ajustes.cfg"):
		var err := c.load("user://ajustes.cfg")
		if err != OK:
			return err
	c.set_value("calidad_pruebas", clave, si)
	_extra_cache = null
	return c.save("user://ajustes.cfg")


static func siguiente() -> String:
	return ORDEN[(ORDEN.find(actual()) + 1) % ORDEN.size()]
