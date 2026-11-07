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

const PASTOS_VERDES := 10                     # índice del lugar en el mapa (mapa.gd, LUGAR_PASTOS)
const REGIONES := {PASTOS_VERDES: "res://zonas3d/pastos_verdes_3d.tscn"}


static func activo() -> bool:
	return OS.has_feature("rebelum3d") or "3d" in OS.get_cmdline_user_args()


# Escena 3D de un lugar del mapa, o "" si ese lugar no tiene versión 3D (o la exploración 3D no está activa).
static func escena_de(indice: int) -> String:
	if not activo():
		return ""
	var ruta: String = REGIONES.get(indice, "")
	return ruta if ruta != "" and ResourceLoader.exists(ruta) else ""
