extends RefCounted
# Héroes v2 (fase B, V12): el interruptor y las rutas. APAGADO por defecto: con él apagado nada cambia en el juego.
#
# Se enciende con cualquiera de estas (para pruebas):
#   - Engine.set_meta("heroes_v2", true)   (antes de crear a los héroes)
#   - el argumento de usuario «heroes_v2»   (godot ... -- heroes_v2)
#   - ACTIVO_POR_DEFECTO = true             (cuando el usuario lo apruebe)
#
# Quien crea a los héroes pide aquí qué script y qué modelo usar (ver docs/memory/agents/animaciones_v12_heroes.md,
# «Cómo se activa»): con el interruptor apagado devuelve exactamente lo que le pasan.
#   load(HeroesV2.script_de("res://kael_3d.gd")).new()
# Los scripts v2 heredan de los originales (kael_3d.gd, maga_3d.gd y garon_3d.gd), así que el combate y la
# exploración les llaman igual; si falta el GLB nuevo, cargan el modelo original.

const ACTIVO_POR_DEFECTO := false

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
	if Engine.has_meta("heroes_v2"):
		return bool(Engine.get_meta("heroes_v2"))
	if "heroes_v2" in OS.get_cmdline_user_args():
		return true
	return ACTIVO_POR_DEFECTO


# El script que hay que usar para un héroe: el v2 si el interruptor está encendido y existe; si no, el mismo.
static func script_de(ruta: String) -> String:
	if activado() and SCRIPTS.has(ruta) and ResourceLoader.exists(SCRIPTS[ruta]):
		var heroe := _heroe_de_script(ruta)
		if heroe == "" or ResourceLoader.exists(GLB[heroe]):
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
