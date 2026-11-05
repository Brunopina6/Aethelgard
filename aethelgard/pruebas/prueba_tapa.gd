extends SceneTree
# Busca un sitio de la isla donde Kael tenga algo delante (árbol, muro) y lo fotografía ahí.

var i: Node
var f := 0


func _initialize() -> void:
	i = load("res://isla.tscn").instantiate()
	root.add_child(i)


func _process(_d: float) -> bool:
	f += 1
	if f == 5:
		var tapa: Image = (load("res://isla/isla_tapa.png") as Texture2D).get_image()
		var mejor := Vector2.ZERO
		var mejor_dif := 0.0
		for y in range(300, 700, 3):
			for x in range(150, 620, 3):
				var p := Vector2(x * 4, y * 4)
				if not i._se_anda(p):
					continue
				var zs: float = i.suelo_img.get_pixel(x, y).r
				var delante := tapa.get_pixel(x * 2, y * 2 + 14).r       # 28 px por debajo de los pies
				if delante - zs > mejor_dif and delante - zs < 0.2:
					mejor_dif = delante - zs
					mejor = p
		print("sitio con algo delante: ", mejor, "  diferencia ", mejor_dif)
		i.jugador.position = mejor
		i.camara.reset_smoothing()
		i._poner_z()
	if f == 15:
		root.get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])
		return true
	return false
