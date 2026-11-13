extends SceneTree
# Animación de combate V12 (combate_anim_v12.gd, 13/11/2026): un combate de tres COMPLETO, el mismo dos veces en el
# mismo proceso (héroes v2, «-- grupo=3 semilla=7 pm_infinitos fotos=<carpeta>», con ventana): primero con la v12
# APAGADA y luego ENCENDIDA (con el ATB al ritmo de siempre, el orden de turnos y las tiradas son los mismos). Las órdenes
# las da este guion, iguales en las dos pasadas, para que salga de todo: magia, ataque, técnica (Juicio), Embuir,
# Defender (y el golpe que le llega en guardia) y la victoria.
#   Lya:   Fuego · Defender · ataque · …        Kael:  ataque · Fuego · ataque · …
#   Garon: Juicio · Embuir (Fuego) · ataque · …
# Guarda un JPG cada 2 fotogramas de todo el combate (apagado_NNNN.jpg y encendido_NNNN.jpg) para montar el vídeo
# comparado con ffmpeg, e imprime el orden de los turnos de cada pasada y si coinciden.

const LIMITE := 3600                 # fotogramas por pasada (120 s)
const ORDENES := {
	"Lya": ["magia", "defender", "atacar"],
	"Kael": ["atacar", "magia", "atacar"],
	"Garon": ["juicio", "embuir", "atacar"],
}

var c: Node
var fase := 0
var frames := 0
var fotos := ""
var n_foto := 0
var turnos := {}
var orden := [[], []]
var fin_en := -1
var fallos := 0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("fotos="):
			fotos = a.substr(6)
	if fotos == "":
		print("FALLO: falta fotos=<carpeta>")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(fotos)
	Engine.set_meta("heroes_v2", true)
	_empezar(0)


func _empezar(f: int) -> void:
	fase = f
	frames = 0
	n_foto = 0
	fin_en = -1
	turnos.clear()
	Engine.set_meta("combate_anim_v12", f == 1)
	Engine.set_meta("camaras_combate", true)
	c = load("res://combate.tscn").instantiate()
	root.add_child(c)


func _process(_d: float) -> bool:
	if c == null:
		return false
	frames += 1
	if frames == 1:                                  # enemigos más duros (igual en las dos pasadas): da tiempo a todo
		for e in c.enemigos:
			e["hp_max"] = int(e["hp_max"]) * 3
			e["hp"] = int(e["hp"]) * 3
	if frames % 2 == 0:
		var img := root.get_viewport().get_texture().get_image()
		img.save_jpg(fotos.path_join("%s_%04d.jpg" % ["apagado" if fase == 0 else "encendido", n_foto]), 0.88)
		n_foto += 1
	if c.estado == "menu" and c.menu.activo and c.actor is Dictionary and not c.actor.get("_c12_ordenado", false):
		_ordenar(c.actor)
	if c.estado == "fin" and fin_en < 0:
		fin_en = frames
	if (fin_en >= 0 and frames - fin_en > 150) or frames >= LIMITE:
		print("PASADA %s: %d fotogramas, %d fotos, fin %s, turnos %s" % ["APAGADO" if fase == 0 else "ENCENDIDO", frames, n_foto,
			"sí" if fin_en >= 0 else "NO", str(orden[fase])])
		if fin_en < 0:
			fallos += 1
			print("FALLO: el combate no termina")
		c.queue_free()
		c = null
		if fase == 0:
			_empezar.call_deferred(1)
			return false
		if str(orden[0]) != str(orden[1]):
			print("AVISO: el orden de las órdenes cambia entre pasadas")
		print("FALLOS: %d" % fallos)
		quit(1 if fallos > 0 else 0)
		return true
	return false


func _ordenar(h: Dictionary) -> void:
	h["_c12_ordenado"] = true                        # (una orden por apertura del menú; se borra al acabar el turno)
	var n: String = h["nombre"]
	var i: int = turnos.get(n, 0)
	turnos[n] = i + 1
	var lista: Array = ORDENES.get(n, ["atacar"])
	var que: String = lista[mini(i, lista.size() - 1)]
	var obj = c._alcanzables()[0] if not c._alcanzables().is_empty() else null
	if obj == null:
		que = "defender"
	orden[fase].append("%s:%s" % [n, que])
	_soltar.call_deferred(h)
	match que:
		"magia":
			c._elegir_hechizo.call_deferred("Fuego", 1, true)
		"defender":
			c._defender.call_deferred()
		"juicio":
			c._tecnica_garon.call_deferred("Juicio", obj)
		"embuir":
			c._embuir.call_deferred("Fuego")
		_:
			c.accion = "atacar"
			c._aplicar.call_deferred(obj)


func _soltar(h: Dictionary) -> void:
	await create_timer(0.5).timeout
	h.erase("_c12_ordenado")
