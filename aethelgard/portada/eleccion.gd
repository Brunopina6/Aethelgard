extends RefCounted
# Qué pantalla de inicio se usa (encargo del 11/11): la NUEVA (portada/inicio_alternativo.tscn) o la ORIGINAL
# (carga.tscn, que sigue siendo la escena principal y no cambia: si se elige, se queda ella).
# Desde el 11/11 por la noche, el usuario eligió la nueva como la de siempre, conservando la original. Así se decide:
#   - con un argumento: «-- portada_original» usa la original y «-- portada_alternativa» la nueva (gana sobre lo demás);
#   - en Ajustes (menus.gd, en cualquier versión): sección [portada], clave «alternativa» de user://ajustes.cfg; false
#     vuelve a la original;
#   - sin nada de eso, la nueva.
# carga.gd la mira al empezar (enganche mínimo y comentado en su _ready).

const ESCENA := "res://portada/inicio_alternativo.tscn"
const AJUSTES := "user://ajustes.cfg"             # el mismo archivo que el volumen (sonido.gd) y las regiones (modo3d.gd)
const SECCION := "portada"
const CLAVE := "alternativa"
const ARG_SI := "portada_alternativa"
const ARG_NO := "portada_original"
const POR_DEFECTO := true                         # sin elección guardada: la nueva (lo eligió el usuario el 11/11)


static func usar_alternativa() -> bool:
	return usar_con(OS.get_cmdline_user_args(), elegida())


# Lo mismo con los datos dados (así lo comprueban las pruebas sin tocar los argumentos).
static func usar_con(args: PackedStringArray, en_ajustes: bool) -> bool:
	if ARG_NO in args:
		return false
	if ARG_SI in args:
		return ResourceLoader.exists(ESCENA)
	return en_ajustes and ResourceLoader.exists(ESCENA)


# ¿Está elegida la nueva? Sin archivo o sin la clave, lo de POR_DEFECTO (la nueva).
static func elegida() -> bool:
	var c := ConfigFile.new()
	if c.load(AJUSTES) != OK:
		return POR_DEFECTO
	return bool(c.get_value(SECCION, CLAVE, POR_DEFECTO))


# La elige o la quita, sin tocar lo demás del archivo (volumen, mapa, regiones, calidad).
static func elegir(si: bool) -> Error:
	var c := ConfigFile.new()
	if FileAccess.file_exists(AJUSTES):
		var err := c.load(AJUSTES)
		if err != OK:
			return err
	c.set_value(SECCION, CLAVE, si)
	return c.save(AJUSTES)
