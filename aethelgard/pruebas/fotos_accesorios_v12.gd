extends SceneTree
# V12 (12/11): capturas de los accesorios nuevos en los menús (docs/v12/ACCESORIOS_V12.md), con el interruptor
# «accesorios_v12» encendido SOLO aquí. Con ventana:
#   --script res://pruebas/fotos_accesorios_v12.gd -- salida=<carpeta>
# 01 tienda de Oakhaven, pestaña Equipo, SIN interruptor (la de siempre: antes); 02 la misma con el interruptor (aviso,
# iconos, colores y notas de rareza); 03 la misma bajando la lista; 04 ficha de Lya (Alba, Eco y Rosario); 05 ficha de
# Garon (cuarzo, Talismán y Broche); 06 Objetos (lista de equipo). No mide rendimiento.

var salida := ""
var paso := 0
var espera := 10
var t = null
var m = null
var X
var I
var G


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
	if salida == "":
		salida = OS.get_user_data_dir().path_join("fotos_accesorios_v12")
	DirAccess.make_dir_recursive_absolute(salida)
	X = load("res://equipo_extra.gd")
	I = load("res://inventario.gd")
	G = load("res://grupo.gd")
	for k in load("res://progreso.gd").CLAVES + [X.INTERRUPTOR_V12, "lugar"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	G.datos()
	I.datos()
	I.ganar_oro(2000)
	Engine.set_meta("lugar", {"indice": 0, "nombre": "Oakhaven", "tipo": "ciudad", "zona": "llanura", "texto": "x"})


func _foto(nombre: String) -> void:
	root.get_texture().get_image().save_png(salida.path_join(nombre + ".png"))
	print("FOTO ", nombre)


func _tienda() -> void:
	t = load("res://tienda.gd").new()
	t.pestana = "Equipo"
	root.add_child(t)


func _process(_d: float) -> bool:
	if espera > 0:
		espera -= 1
		return false
	espera = 15
	match paso:
		0:
			_tienda()
		1:
			_foto("01_tienda_sin_interruptor")
			t.free()
			Engine.set_meta(X.INTERRUPTOR_V12, true)
			_tienda()
		2:
			_foto("02_tienda_prueba_v12")
			var marco: ScrollContainer = t.find_children("*", "ScrollContainer", true, false)[0]
			marco.scroll_vertical = 330
		3:
			_foto("03_tienda_prueba_v12_abajo")
			t.free()
			for id in X.ACCESORIOS:
				if X.es_v12(id):
					X.conseguir(id)
			I.equipar("Lya", "anillo", "anillo_alba")
			I.equipar("Lya", "amuleto", "colgante_eco")
			I.equipar("Lya", "accesorio", "rosario_loto")
			I.equipar("Garon", "anillo", "anillo_cuarzo")
			I.equipar("Garon", "amuleto", "talisman_ceniza")
			I.equipar("Garon", "accesorio", "broche_guardian")
			m = load("res://menus.gd").new()
			root.add_child(m)
			m.heroe = "Lya"
			m._pintar_de_nuevo()
		4:
			_foto("04_ficha_lya")
			m.heroe = "Garon"
			m._pintar_de_nuevo()
		5:
			_foto("05_ficha_garon")
			m.pestana = "Objetos"
			m._pintar_de_nuevo()
		6:
			_foto("06_objetos")
			m.free()
			for k in [X.INTERRUPTOR_V12, "lugar"]:
				Engine.remove_meta(k)
			quit(0)
	paso += 1
	return false
