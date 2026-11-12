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
# Regiones en pruebas (EN_PRUEBAS): existen y se pueden jugar, pero solo con su argumento o elegidas en Ajustes (hoy
# el Mar de Cristal; Oakhaven 3D lo estuvo hasta el 12/11).
# Regiones por defecto con la 2D elegible (POR_DEFECTO_2D_ELEGIBLE; V12, fase 2, migración región a región): la 3D va
# por defecto y la 2D de siempre se puede elegir en Ajustes. Desde el 12/11, la Garganta del Diablo: sin nada en
# user://ajustes.cfg, la 3D; con [regiones] garganta3d = false (quien eligió «2D (la de siempre)»), la 2D, como antes.
# Argumentos para las pruebas: «garganta3d» fuerza la 3D y «garganta2d», la 2D (el primero manda). Desde el 12/11 también
# Oakhaven («oakhaven3d» / «oakhaven2d», la misma clave de Ajustes que tenía en pruebas).
# Una partida guardada en una de ellas abre la versión en uso: la de la 2D, la 3D en el sitio equivalente
# (escena_equivalente); la de la 3D con la 2D elegida, la 2D por su entrada (Oakhaven, en la misma casilla: posicion_a_2d).

const PASTOS_VERDES := 10                     # índice del lugar en el mapa (mapa.gd, LUGAR_PASTOS)
const GARGANTA := 2                           # índice del lugar en el mapa (mapa.gd, INDICE_GARGANTA)
const OAKHAVEN := 0                           # índice del lugar en el mapa (ciudades/oakhaven.gd, INDICE; T-103)
const MAR_CRISTAL := 4                        # el Mar de Arena de Calid (mapa.gd); su primer sector, el Mar de Cristal (V12)
const REGIONES := {PASTOS_VERDES: "res://zonas3d/pastos_verdes_3d.tscn",
	GARGANTA: "res://zonas3d/garganta_3d.tscn", OAKHAVEN: "res://zonas3d/oakhaven_3d.tscn",
	MAR_CRISTAL: "res://zonas3d/mar_cristal_3d.tscn"}
const EN_PRUEBAS := {MAR_CRISTAL: "mardecristal"}  # región → argumento que hace falta para usarla
# Región → [clave de Ajustes (y argumento que fuerza la 3D), argumento que fuerza la 2D]. La clave es la misma que
# cuando la región estaba en pruebas: la elección de quien ya había elegido algo se conserva.
# V12, migración de Oakhaven (12/11): Oakhaven 3D completa (vecinos, misiones, cofres, secretos, notas, gremio, tienda,
# parejas, colina, crematorio, torre y ronda) va por defecto; la 2D, elegible con «oakhaven3d» = false u «oakhaven2d».
const POR_DEFECTO_2D_ELEGIBLE := {GARGANTA: ["garganta3d", "garganta2d"], OAKHAVEN: ["oakhaven3d", "oakhaven2d"]}
# Escenas 2D que tienen versión 3D: una partida guardada dentro de la 2D vuelve a la 3D si esta se usa (escena_equivalente).
const EQUIVALENTES := {"res://garganta.tscn": GARGANTA, "res://ciudad_oakhaven.tscn": OAKHAVEN}


static func activo() -> bool:
	return OS.has_feature("rebelum3d") or "3d" in OS.get_cmdline_user_args()


# ¿Se usa la versión 3D de este lugar? Con la exploración 3D activa y, si la región está en pruebas, con su argumento
# o elegida en Ajustes (solo en la versión experimental: menus.gd; [regiones] en user://ajustes.cfg). Si es de las que
# van en 3D por defecto, salvo que se haya elegido la 2D en Ajustes (o con su argumento).
static func region_activa(indice: int) -> bool:
	var args := OS.get_cmdline_user_args()
	var hace_falta: String = EN_PRUEBAS.get(indice, "")
	if hace_falta != "" and not hace_falta in args and elegida(hace_falta):
		args.append(hace_falta)
	var claves: Array = POR_DEFECTO_2D_ELEGIBLE.get(indice, [])
	if not claves.is_empty() and not claves[0] in args and eleccion(claves[0]) == false:
		args.append(claves[1])                       # eligió la 2D en Ajustes
	return region_activa_con(indice, args, OS.has_feature("rebelum3d"))


# Lo elegido en Ajustes para una región: true, false, o null si nunca se ha elegido (sin archivo o sin la clave).
static func eleccion(clave: String) -> Variant:
	var c := ConfigFile.new()
	if c.load(AJUSTES) != OK or not c.has_section_key("regiones", clave):
		return null
	return bool(c.get_value("regiones", clave))


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
	var claves: Array = POR_DEFECTO_2D_ELEGIBLE.get(indice, [])
	if not claves.is_empty():
		return claves[0] in args or not claves[1] in args      # «garganta3d» manda sobre «garganta2d»
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
		# Al revés (V12): una partida guardada en la 3D de una región que va en 3D por defecto, con la 2D elegida en
		# Ajustes: la 2D, por su entrada (pos_zona_ok = false; los trazados no se corresponden casilla a casilla).
		for e2 in EQUIVALENTES:
			var i2: int = EQUIVALENTES[e2]
			if POR_DEFECTO_2D_ELEGIBLE.has(i2) and REGIONES.get(i2, "") == escena and activo() and not region_activa(i2):
				Engine.set_meta("pos_zona_ok", false)
				# V12, Oakhaven: con el mismo trazado en las dos, la escena 3D sabe qué casilla de la 2D es (posicion_a_2d)
				var g3 = load(escena.get_basename() + ".gd")
				var sabe := g3 is Script and (g3 as Script).get_script_method_list().any(func(m): return m["name"] == "posicion_a_2d")
				if sabe and Engine.get_meta("pos_3d_ok", false) \
						and int(Engine.get_meta("pos_3d_lugar", -1)) == i2 and Engine.get_meta("pos_3d", null) is Vector3:
					Engine.set_meta("pos_zona", g3.posicion_a_2d(Engine.get_meta("pos_3d")))
					Engine.set_meta("pos_zona_ok", true)
					Engine.set_meta("pos_zona_lugar", i2)
				Engine.set_meta("pos_3d_ok", false)
				return e2
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
