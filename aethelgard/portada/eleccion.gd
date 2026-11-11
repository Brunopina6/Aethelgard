extends RefCounted
# Qué pantalla de inicio se usa (encargo del 11/11): la ORIGINAL (carga.tscn, la escena principal, que no cambia) o la
# ALTERNATIVA, en pruebas (portada/inicio_alternativo.tscn). Se elige así, y sin nada de esto todo sigue como siempre:
#   - con un argumento: «-- portada_alternativa» la usa y «-- portada_original» la impide (gana sobre lo demás);
#   - en Ajustes (menus.gd, solo en la versión experimental, como las demás opciones en pruebas): sección [portada],
#     clave «alternativa» de user://ajustes.cfg. Lo de Ajustes solo vale con la exploración 3D activa (modo3d.gd), así
#     que la versión estable, que comparte user:// en el PC, nunca la ve.
# carga.gd la mira al empezar (enganche mínimo y comentado en su _ready).

const ESCENA := "res://portada/inicio_alternativo.tscn"
const AJUSTES := "user://ajustes.cfg"             # el mismo archivo que el volumen (sonido.gd) y las regiones (modo3d.gd)
const SECCION := "portada"
const CLAVE := "alternativa"
const ARG_SI := "portada_alternativa"
const ARG_NO := "portada_original"


static func usar_alternativa() -> bool:
	return usar_con(OS.get_cmdline_user_args(), load("res://modo3d.gd").activo(), elegida())


# Lo mismo con los datos dados (así lo comprueban las pruebas sin tocar los argumentos).
static func usar_con(args: PackedStringArray, experimental: bool, en_ajustes: bool) -> bool:
	if ARG_NO in args:
		return false
	if ARG_SI in args:
		return ResourceLoader.exists(ESCENA)
	return experimental and en_ajustes and ResourceLoader.exists(ESCENA)


# ¿Está elegida en Ajustes? Sin archivo o sin la clave, no.
static func elegida() -> bool:
	var c := ConfigFile.new()
	return c.load(AJUSTES) == OK and bool(c.get_value(SECCION, CLAVE, false))


# La elige o la quita, sin tocar lo demás del archivo (volumen, mapa, regiones, calidad).
static func elegir(si: bool) -> Error:
	var c := ConfigFile.new()
	if FileAccess.file_exists(AJUSTES):
		var err := c.load(AJUSTES)
		if err != OK:
			return err
	c.set_value(SECCION, CLAVE, si)
	return c.save(AJUSTES)
