extends RefCounted
# Héroes v2 (fase B, V12): el interruptor y las rutas. APAGADO por defecto: con él apagado nada cambia en el juego.
#
# Se enciende con cualquiera de estas (para pruebas):
#   - Engine.set_meta("heroes_v2", true)   (antes de crear a los héroes)
#   - el argumento de usuario «heroes_v2»   (godot ... -- heroes_v2)
#   - Ajustes → «Protagonistas» (user://ajustes.cfg, [heroes] v2; 13/11, para el móvil)
#   - ACTIVO_POR_DEFECTO = true             (cuando el usuario lo apruebe)
#
# Quien crea a los héroes pide aquí qué script y qué modelo usar (ver docs/memory/agents/animaciones_v12_heroes.md,
# «Cómo se activa»): con el interruptor apagado devuelve exactamente lo que le pasan.
#   load(HeroesV2.script_de("res://kael_3d.gd")).new()
# Los scripts v2 heredan de los originales (kael_3d.gd, maga_3d.gd y garon_3d.gd), así que el combate y la
# exploración les llaman igual; si falta el GLB nuevo, cargan el modelo original.

const ACTIVO_POR_DEFECTO := false
const HeroesV3 := preload("res://personajes/heroes_v3/heroes_v3.gd")

const SCRIPTS := {
	"res://kael_3d.gd": "res://personajes/heroes_v2/kael_v2_3d.gd",
	"res://maga_3d.gd": "res://personajes/heroes_v2/lya_v2_3d.gd",
	"res://garon_3d.gd": "res://personajes/heroes_v2/garon_v2_3d.gd",
}
const GLB := {
	"Kael": "res://personajes/heroes_v2/kael/kael_v2.glb",
	"Lya": "res://personajes/heroes_v2/lya/lya_v2.glb",
	"Garon": "res://personajes/heroes_v2/garon/garon_v2.glb",
}
# Modelos originales (si alguien pasa uno de estos, el script v2 lo cambia por su GLB)
const ORIGINALES := {
	"Kael": ["res://kael.fbx", "res://Meshy_AI_Azure_Starblade_biped_Meshy_Merged_Animations.fbx", "res://kael.glb"],
	"Lya": ["res://Meshy_AI_Anime_Girl_10k_Remesh_biped_Meshy_Merged_Animations.fbx", "res://maga.fbx", "res://maga.glb"],
	"Garon": ["res://garon.fbx", "res://Meshy_AI_Crimson_Helm_Guardian_20261103_animated_mixamo_All_animation.fbx",
		"res://garon.glb"],
}


static func activado() -> bool:
	return version() != "originales"


# V12, héroes v3 (personajes/heroes_v3/): qué protagonistas se usan: "originales", "v2" o "v3". Orden: la meta
# «heroes_version» → la meta «heroes_v3» (true) → la meta «heroes_v2» → los argumentos «heroes_v3» o «heroes_v2» →
# Ajustes ([heroes] version; o el [heroes] v2 de antes) → ACTIVO_POR_DEFECTO (originales).
static func version() -> String:
	if Engine.has_meta("heroes_version"):
		return _version_valida(str(Engine.get_meta("heroes_version")))
	if Engine.has_meta("heroes_v3") and bool(Engine.get_meta("heroes_v3")):
		return "v3"
	if Engine.has_meta("heroes_v2"):
		return "v2" if bool(Engine.get_meta("heroes_v2")) else "originales"
	var args := OS.get_cmdline_user_args()
	if "heroes_v3" in args:
		return "v3"
	if "heroes_v2" in args:
		return "v2"
	return version_en_ajustes()


static func _version_valida(v: String) -> String:
	return v if v in ["originales", "v2", "v3"] else "originales"


# 13/11: Ajustes → «Protagonistas: originales / v2 (prueba)» (menus.gd), para compararlos en el móvil, donde no llegan
# los argumentos. Se guarda en user://ajustes.cfg, [heroes] v2; sin elegir, ACTIVO_POR_DEFECTO (originales).
# V12, v3: [heroes] version = "originales" | "v2" | "v3" (manda sobre [heroes] v2, que se sigue escribiendo).
static func en_ajustes() -> bool:
	return version_en_ajustes() != "originales"


static func version_en_ajustes() -> String:
	var defecto := "v2" if ACTIVO_POR_DEFECTO else "originales"
	var c := ConfigFile.new()
	if c.load("user://ajustes.cfg") != OK:
		return defecto
	if c.has_section_key("heroes", "version"):
		return _version_valida(str(c.get_value("heroes", "version", defecto)))
	return "v2" if bool(c.get_value("heroes", "v2", ACTIVO_POR_DEFECTO)) else "originales"


# Lo elige en Ajustes: lo guarda y lo pone ya en Engine (los héroes que se creen desde ahora lo usan; los que ya
# están en pantalla no cambian hasta el próximo combate o la próxima región).
static func elegir_en_ajustes(si: bool) -> Error:
	Engine.set_meta("heroes_v2", si)
	if Engine.has_meta("heroes_version"):
		Engine.remove_meta("heroes_version")
	return _guardar("v2" if si else "originales")


static func elegir_version(v: String) -> Error:
	v = _version_valida(v)
	Engine.set_meta("heroes_version", v)
	return _guardar(v)


static func _guardar(v: String) -> Error:
	var c := ConfigFile.new()
	if FileAccess.file_exists("user://ajustes.cfg"):
		var err := c.load("user://ajustes.cfg")
		if err != OK:
			return err
	c.set_value("heroes", "v2", v == "v2")
	c.set_value("heroes", "version", v)
	return c.save("user://ajustes.cfg")


# El script que hay que usar para un héroe: el v3 o el v2 si están elegidos y existen; si no, el mismo. Con «v3», un
# héroe que aún no tenga su v3 usa su v2.
static func script_de(ruta: String) -> String:
	var v := version()
	if v == "originales" or not SCRIPTS.has(ruta):
		return ruta
	var heroe := _heroe_de_script(ruta)
	if v == "v3" and heroe != "" and HeroesV3.listo(heroe):
		return HeroesV3.SCRIPTS[ruta]
	if ResourceLoader.exists(SCRIPTS[ruta]) and (heroe == "" or ResourceLoader.exists(GLB[heroe])):
		return SCRIPTS[ruta]
	return ruta


static func _heroe_de_script(ruta: String) -> String:
	return {"res://kael_3d.gd": "Kael", "res://maga_3d.gd": "Lya", "res://garon_3d.gd": "Garon"}.get(ruta, "")


# Contrato de clips (biblioteca_clips.py): nombre -> {duracion, bucle, eventos}. Se lee del JSON junto al GLB.
static func contrato(heroe: String) -> Dictionary:
	var ruta: String = GLB.get(heroe, "").replace("_v2.glb", "_v2_clips.json")
	if ruta == "" or not FileAccess.file_exists(ruta):
		return {}
	var datos = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	return datos.get("clips", {}) if datos is Dictionary else {}
