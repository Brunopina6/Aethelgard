extends RefCounted
# Qué versión de Bramavidrio se usa (V12, 11/11). UN SOLO INTERRUPTOR para el combate (combate.gd) y la exploración
# (zonas3d/mar_cristal/gusano.gd):
#   1  la versión 1, el gusano de anillos acorazados (enemigos/bramavidrio/bramavidrio_3d.gd y bramavidrio*.glb), intacta
#   2  la versión 2, «la Sierpe de la Vela» (enemigos/bramavidrio/v2/bramavidrio2_3d.gd y bramavidrio2*.glb)
#   3  la versión 3, «el Excavador» (enemigos/bramavidrio/v3/bramavidrio3_3d.gd y bramavidrio3*.glb; 12/11, en prueba:
#      el usuario la elige en Ajustes; VERSION_DEFECTO sigue siendo 2)
#   4  la versión 4, «el Ancestral» (enemigos/bramavidrio/v4/bramavidrio4_3d.gd y bramavidrio4*.glb; 12/11, en prueba: el
#      gusano de la lámina de referencia del usuario, con boca circular; se elige en Ajustes; VERSION_DEFECTO sigue en 2)
#   5  la versión 5, «la v4 resuelta» (enemigos/bramavidrio/v5/bramavidrio5_3d.gd y bramavidrio5*.glb; 12/11, noche, en
#      prueba: cuatro mandíbulas con colmillos que se despliegan, movimientos con retraso entre tramos, encuadre de la
#      Fractura y normales horneadas; se elige en Ajustes; VERSION_DEFECTO sigue en 2 hasta que el usuario la vea)
# Por orden manda:
#   - el argumento de la línea de órdenes «bramavidrio_version=1» (o 2, 3, 4 o 5) después de «--» (pruebas);
#   - Engine.set_meta("bramavidrio_version", 1) (o 2, 3, 4 o 5), antes de crear el combate o la región;
#   - Ajustes → «Bramavidrio» (user://ajustes.cfg, [bramavidrio] version), para que el jugador las compare;
#   - VERSION_DEFECTO (cambiar esta constante es la forma de volver a la v1 en el juego por defecto).
# Si faltan los archivos de la versión pedida, se usa la de VERSION_DEFECTO (y si tampoco está, la 1). Detalles:
# docs/memory/agents/animaciones_v12_bramavidrio2.md, animaciones_v12_bramavidrio3.md, animaciones_v12_bramavidrio4.md y
# animaciones_v12_bramavidrio5.md.

const VERSION_DEFECTO := 2
const GUIONES := {1: "res://enemigos/bramavidrio/bramavidrio_3d.gd", 2: "res://enemigos/bramavidrio/v2/bramavidrio2_3d.gd",
	3: "res://enemigos/bramavidrio/v3/bramavidrio3_3d.gd", 4: "res://enemigos/bramavidrio/v4/bramavidrio4_3d.gd",
	5: "res://enemigos/bramavidrio/v5/bramavidrio5_3d.gd"}
const MODELOS := {1: "res://enemigos/bramavidrio/bramavidrio.glb", 2: "res://enemigos/bramavidrio/v2/bramavidrio2.glb",
	3: "res://enemigos/bramavidrio/v3/bramavidrio3.glb", 4: "res://enemigos/bramavidrio/v4/bramavidrio4.glb",
	5: "res://enemigos/bramavidrio/v5/bramavidrio5.glb"}


static func pedida() -> int:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("bramavidrio_version="):
			return int(a.get_slice("=", 1))
	if Engine.has_meta("bramavidrio_version"):
		return int(Engine.get_meta("bramavidrio_version"))
	return en_ajustes()


# La elegida en Ajustes (o VERSION_DEFECTO si no se ha elegido).
static func en_ajustes() -> int:
	var c := ConfigFile.new()
	if c.load("user://ajustes.cfg") != OK:
		return VERSION_DEFECTO
	return int(c.get_value("bramavidrio", "version", VERSION_DEFECTO))


static func elegir_en_ajustes(v: int) -> Error:
	var c := ConfigFile.new()
	if FileAccess.file_exists("user://ajustes.cfg"):
		var err := c.load("user://ajustes.cfg")
		if err != OK:
			return err
	c.set_value("bramavidrio", "version", v)
	return c.save("user://ajustes.cfg")


static func version() -> int:
	var v := pedida()
	if not GUIONES.has(v):
		v = VERSION_DEFECTO
	for alternativa in [v, VERSION_DEFECTO, 1, 2]:
		if ResourceLoader.exists(GUIONES[alternativa]) and ResourceLoader.exists(MODELOS[alternativa]):
			return alternativa
	return v


static func guion() -> String:
	return GUIONES[version()]


static func modelo() -> String:
	return MODELOS[version()]


# El guion que corresponde a «ruta» (la de MODELOS de combate.gd): si es el de Bramavidrio (cualquier versión), el de la
# versión en uso; si no, el mismo.
static func elegir(ruta: String) -> String:
	return guion() if ruta in GUIONES.values() else ruta
