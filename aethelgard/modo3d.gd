extends RefCounted
# Interruptor de la exploración 3D (rama experimental rebelum-alpha).
#
# La exploración 3D solo existe en la app experimental «Aethelgard Exp» (característica «rebelum3d» del preset
# «Android experimental») o al arrancar con «-- 3d» desde el editor y las pruebas. Sin eso, el juego es el de
# siempre: el mapa no muestra las regiones 3D, una partida guardada en 3D vuelve al mapa (progreso.gd) y la
# partida se guarda en el archivo de siempre.
#
# Cada región 3D cumple el mismo «contrato» que una zona 2D (zona.gd): encuentros por pasos con progreso.gd,
# combate y vuelta con escena_retorno, Dialogic, menús, guardado automático y salida al mapa.
#
# Regiones en pruebas (EN_PRUEBAS): existen y se pueden jugar, pero solo con su argumento. Hoy, la Garganta del Diablo
# 3D: «-- 3d garganta3d». Sin él, el mapa sigue llevando a la Garganta 2D (garganta.tscn), también en la APK
# experimental. Para que vaya por defecto, se quita su línea de EN_PRUEBAS (docs/diseno/garganta_3d.md, «Activarla
# por defecto»).

const PASTOS_VERDES := 10                     # índice del lugar en el mapa (mapa.gd, LUGAR_PASTOS)
const GARGANTA := 2                           # índice del lugar en el mapa (mapa.gd, INDICE_GARGANTA)
const OAKHAVEN := 0                           # índice del lugar en el mapa (ciudades/oakhaven.gd, INDICE; T-103)
const REGIONES := {PASTOS_VERDES: "res://zonas3d/pastos_verdes_3d.tscn",
	GARGANTA: "res://zonas3d/garganta_3d.tscn", OAKHAVEN: "res://zonas3d/oakhaven_3d.tscn"}
const EN_PRUEBAS := {GARGANTA: "garganta3d", OAKHAVEN: "oakhaven3d"}  # región → argumento que hace falta para usarla
# Escenas 2D que tienen versión 3D: una partida guardada dentro de la 2D vuelve a la 3D si esta se usa (escena_equivalente).
const EQUIVALENTES := {"res://garganta.tscn": GARGANTA, "res://ciudad_oakhaven.tscn": OAKHAVEN}


static func activo() -> bool:
	return OS.has_feature("rebelum3d") or "3d" in OS.get_cmdline_user_args()


# ¿Se usa la versión 3D de este lugar? Con la exploración 3D activa y, si la región está en pruebas, con su argumento
# o elegida en Ajustes (solo en la versión experimental: menus.gd; [regiones] en user://ajustes.cfg).
static func region_activa(indice: int) -> bool:
	var args := OS.get_cmdline_user_args()
	var hace_falta: String = EN_PRUEBAS.get(indice, "")
	if hace_falta != "" and not hace_falta in args and elegida(hace_falta):
		args.append(hace_falta)
	return region_activa_con(indice, args, OS.has_feature("rebelum3d"))


const AJUSTES := "user://ajustes.cfg"            # el mismo archivo que el volumen (sonido.gd) y el mapa (mapa_arte.gd)


# Una región en pruebas elegida en Ajustes (por ejemplo «garganta3d»). Sin archivo o sin la clave, no.
static func elegida(clave: String) -> bool:
	var c := ConfigFile.new()
	return c.load(AJUSTES) == OK and bool(c.get_value("regiones", clave, false))


# Elige o quita una región en pruebas, sin tocar lo demás del archivo (volumen, mapa).
static func elegir(clave: String, si: bool) -> Error:
	var c := ConfigFile.new()
	if FileAccess.file_exists(AJUSTES):
		var err := c.load(AJUSTES)
		if err != OK:
			return err
	c.set_value("regiones", clave, si)
	return c.save(AJUSTES)


# Lo mismo con los argumentos y la característica dados (las pruebas comprueban así los casos que no son el suyo).
static func region_activa_con(indice: int, args: PackedStringArray, rebelum3d: bool) -> bool:
	if not (rebelum3d or "3d" in args) or not REGIONES.has(indice):
		return false
	var hace_falta: String = EN_PRUEBAS.get(indice, "")
	return hace_falta == "" or hace_falta in args


# Escena 3D de un lugar del mapa, o "" si ese lugar no tiene versión 3D (o la exploración 3D no está activa).
static func escena_de(indice: int) -> String:
	if not region_activa(indice):
		return ""
	var ruta: String = REGIONES.get(indice, "")
	return ruta if ruta != "" and ResourceLoader.exists(ruta) else ""


# Una partida guardada dentro de una escena 2D que ya tiene versión 3D en uso: devuelve la escena 3D y deja en Engine
# la posición equivalente («pos_3d»), o "" si no hay que cambiar nada. Pensado para progreso.gd (restaurar), después de
# poner la partida en Engine: así una partida con la Garganta 2D a medias sigue en la 3D, en el sitio equivalente, y la
# 2D no se cuela. La escena 3D convierte la posición (posicion_desde_2d); sin posición, se entra por el principio.
static func escena_equivalente(escena: String) -> String:
	if not EQUIVALENTES.has(escena):
		return ""
	var indice: int = EQUIVALENTES[escena]
	var ruta := escena_de(indice)
	if ruta == "":
		return ""
	var guion = load(ruta.get_basename() + ".gd")       # la escena 3D sabe dónde queda cada sitio de la 2D
	if Engine.get_meta("pos_zona_ok", false) and int(Engine.get_meta("pos_zona_lugar", -1)) == indice \
			and Engine.get_meta("pos_zona", null) is Vector2 and guion != null:
		Engine.set_meta("pos_3d", guion.posicion_desde_2d(Engine.get_meta("pos_zona")))
		Engine.set_meta("pos_3d_ok", true)
		Engine.set_meta("pos_3d_lugar", indice)
	else:
		Engine.set_meta("pos_3d_ok", false)
	return ruta
