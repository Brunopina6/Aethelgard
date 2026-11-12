extends RefCounted
# Héroes v3 (V12): rutas de los protagonistas v3 y el cambio de ayudante. La ELECCIÓN (originales, v2 o v3) la hace
# heroes_v2.gd (script_de), que es a quien ya llaman combate.gd, grupo_3d.gd y vista3d.gd.

const SCRIPTS := {
	"res://kael_3d.gd": "res://personajes/heroes_v3/kael_v3_3d.gd",
	"res://maga_3d.gd": "res://personajes/heroes_v3/lya_v3_3d.gd",
	"res://garon_3d.gd": "res://personajes/heroes_v3/garon_v3_3d.gd",
}
const GLB := {
	"Kael": "res://personajes/heroes_v3/kael/kael_v3.glb",
	"Lya": "res://personajes/heroes_v3/lya/lya_v3.glb",
	"Garon": "res://personajes/heroes_v3/garon/garon_v3.glb",
}


static func listo(heroe: String) -> bool:
	return ResourceLoader.exists(GLB.get(heroe, "")) and ResourceLoader.exists(
		SCRIPTS.get({"Kael": "res://kael_3d.gd", "Lya": "res://maga_3d.gd", "Garon": "res://garon_3d.gd"}[heroe], ""))


# El script v2 ya creó su ayudante («HeroeV2») con los materiales de los v2: se deja inerte y se pone el de los v3.
static func cambiar_ayudante(h: Node3D, nombre: String, clase: Script) -> void:
	if not h.get("es_v3") or h.get("v2") == null:
		return
	var viejo: Node = h.v2
	viejo.set_process(false)
	viejo.materiales.clear()
	viejo.cara = null
	viejo.name = "HeroeV2_viejo"
	viejo.queue_free()
	var nuevo: Node = clase.new()
	nuevo.name = "HeroeV3"
	h.add_child(nuevo)
	nuevo.preparar(h, nombre)
	h.v2 = nuevo


# Contrato de clips: el JSON junto al GLB v3 (mismo formato que el de los v2).
static func contrato(heroe: String) -> Dictionary:
	var ruta: String = GLB.get(heroe, "").replace("_v3.glb", "_v3_clips.json")
	if ruta == "" or not FileAccess.file_exists(ruta):
		return {}
	var datos = JSON.parse_string(FileAccess.get_file_as_string(ruta))
	return datos.get("clips", {}) if datos is Dictionary else {}
