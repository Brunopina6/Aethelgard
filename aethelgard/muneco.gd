extends AnimatedSprite2D
# Muñeco de Kael para el mapa del mundo y las zonas (Godot 4.x): corre moviendo las piernas en
# la dirección en que va y respira cuando está quieto. Los fotogramas salen de su modelo 3D
# (personajes/kael_mapa/correr_<dir>.png y quieto_<dir>.png: tiras horizontales de fotogramas).
# Uso: var m = load("res://muneco.gd").new(); jugador.add_child(m)
#      y cada fotograma: m.actualizar(direccion_del_movimiento, velocidad_relativa)
# Si faltan los fotogramas, usa la foto fija mapa_kael.png con un saltito al andar.

const CARPETA := "res://personajes/kael_mapa/"
const DIRS := ["abajo", "arriba", "izquierda", "derecha"]
const FOTOGRAMAS := {"correr": 10, "quieto": 8}
const FPS := {"correr": 16.0, "quieto": 8.0}

var mirando := "abajo"
var animado := false
var _tiempo := 0.0


func _ready() -> void:
	centered = false
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	var celda := Vector2.ZERO
	for a in FOTOGRAMAS:
		for d in DIRS:
			var ruta := CARPETA + "%s_%s.png" % [a, d]
			if not ResourceLoader.exists(ruta):
				continue
			var tira: Texture2D = load(ruta)
			var n: int = FOTOGRAMAS[a]
			var w := tira.get_width() / n
			celda = Vector2(w, tira.get_height())
			var nombre := "%s_%s" % [a, d]
			sf.add_animation(nombre)
			sf.set_animation_speed(nombre, FPS[a])
			sf.set_animation_loop(nombre, true)
			for i in n:
				var trozo := AtlasTexture.new()
				trozo.atlas = tira
				trozo.region = Rect2(i * w, 0, w, tira.get_height())
				sf.add_frame(nombre, trozo)
	animado = sf.get_animation_names().size() == FOTOGRAMAS.size() * DIRS.size()
	if animado:
		sprite_frames = sf
		offset = Vector2(-celda.x * 0.5, -celda.y)      # los pies en el origen
		play("quieto_abajo")
	elif ResourceLoader.exists("res://mapa_kael.png"):  # respaldo: la foto fija de antes
		var sf2 := SpriteFrames.new()
		var tex: Texture2D = load("res://mapa_kael.png")
		sf2.add_frame("default", tex)
		sprite_frames = sf2
		offset = Vector2(-tex.get_width() * 0.5, -tex.get_height())


# dir = hacia dónde se mueve (Vector2.ZERO si está quieto); rapidez = 0..1 de la velocidad máxima.
func actualizar(dir: Vector2, rapidez: float, delta: float) -> void:
	var moviendo := dir.length() > 0.01 and rapidez > 0.05
	if moviendo:
		if absf(dir.x) > absf(dir.y) * 1.1:
			mirando = "derecha" if dir.x > 0.0 else "izquierda"
		else:
			mirando = "abajo" if dir.y > 0.0 else "arriba"
	if not animado:                                # foto fija: saltito al andar
		_tiempo += delta
		position.y = -absf(sin(_tiempo * 11.0)) * 5.0 if moviendo else 0.0
		return
	var nombre := "%s_%s" % ["correr" if moviendo else "quieto", mirando]
	if animation != nombre:
		play(nombre)
	speed_scale = clampf(rapidez, 0.5, 1.2) if moviendo else 1.0
