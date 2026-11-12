extends SceneTree
# V12 (12/11): capturas del grupo con reserva y de Naira (PROPUESTA, NO CANON; modelo y retrato PROVISIONALES), con el
# interruptor «naira_v12» encendido SOLO en esta prueba. Con ventana:
#   --script res://pruebas/fotos_grupo_naira.gd -- salida=<carpeta>
# 01-03 menú Grupo: ficha de Naira (reserva), Formación (tarjetas), Formación tras cambiar a Lya por Naira;
# 04 Habilidades; 05 combate con Kael, Naira y Garon; 06 menú de magia de Naira (escuelas con el Eclipse); 07 página del
# Eclipse; 08 Naira preparando el Eclipse; 09-11 el Eclipse saliendo; 12 enemigos en Penumbra; 13 DÚO de Kael
# (Contrapeso); 14 combate con Kael, Lya y Naira y el DÚO de Lya (Equinoccio). No mide rendimiento.

var salida := ""
var frames := 0
var paso := 0
var espera := 0
var m = null
var c = null
var G
var fallos := 0


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("salida="):
			salida = a.substr(7)
	if salida == "":
		salida = OS.get_user_data_dir().path_join("fotos_grupo_naira")
	DirAccess.make_dir_recursive_absolute(salida)
	G = load("res://grupo.gd")
	for k in load("res://progreso.gd").CLAVES:
		if Engine.has_meta(k):
			Engine.remove_meta(k)
	Engine.set_meta("naira_v12", true)
	G.datos()
	for n in ["Kael", "Lya", "Garon"]:
		G.datos()[n]["nivel"] = 10
	G.unir("Naira")
	G.datos()["Naira"]["nivel"] = 10
	G.datos()["Naira"]["puntos"] = 27


# El último fotograma dibujado (antes de los cambios de este paso: cada foto espera unos fotogramas a que se vea).
func _foto(nombre: String) -> void:
	var img := root.get_texture().get_image()
	img.save_png(salida.path_join(nombre + ".png"))
	print("FOTO ", nombre)


func _process(_d: float) -> bool:
	frames += 1
	if espera > 0:
		espera -= 1
		return false
	match paso:
		0:
			m = load("res://menus.gd").new()
			m.heroe = "Naira"
			root.add_child(m)
			m.heroe = "Naira"
			m._pintar_de_nuevo()
			_siguiente(20)
		1:
			_foto("01_ficha_naira_reserva")
			m.vista_formacion = true
			m._pintar_de_nuevo()
			_siguiente(15)
		2:
			_foto("02_formacion")
			G.cambiar("Lya", "Naira")
			m._pintar_de_nuevo()
			_siguiente(15)
		3:
			_foto("03_formacion_naira_activa")
			m._salir_formacion()
			m._ir_a_pestana("Habilidades")
			_siguiente(15)
		4:
			_foto("04_habilidades")
			m.free()
			m = null
			Engine.set_meta("grupo_combate", 1)
			Engine.set_meta("tipo_combate", "normal")
			Engine.set_meta("zona", "desierto")
			c = load("res://combate.tscn").instantiate()
			root.add_child(c)
			for e in c.enemigos:
				e["vel"] = 0.2
				e["hp_max"] = 400
				e["hp"] = 400
			_siguiente(60)
		5:
			_foto("05_combate_kael_naira_garon")
			_siguiente(1)
		6:
			if c.estado == "menu" and c.actor is Dictionary and c.actor.get("hero", false):
				if c.actor["nombre"] != "Naira":
					c._defender()
				else:
					c._menu_magia()
					_siguiente(15)
		7:
			_foto("06_menu_magia_naira")
			c._menu_escuela("naira_eclipse")
			_siguiente(15)
		8:
			_foto("07_pagina_eclipse")
			c._elegir_negra("naira_eclipse", 1)
			_siguiente(40)
		9:
			_foto("08_prepara_eclipse")
			_siguiente(1)
		10:                                          # hasta que se suelta (los demás se defienden)
			if c.estado == "menu" and c.actor is Dictionary and c.actor.get("hero", false):
				if c.actor["nombre"] == "Naira" and not c.actor.has("conjuro"):
					_siguiente(1)
				else:
					c._defender()
			elif c.estado == "accion" and c.registro.text.contains("suelta"):
				_siguiente(25)
		11:
			_foto("09_eclipse_1")
			_siguiente(12)
		12:
			_foto("10_eclipse_2")
			_siguiente(12)
		13:
			_foto("11_eclipse_3")
			_siguiente(1)
		14:
			if c.estado == "menu" and c.actor is Dictionary and c.actor.get("hero", false):
				if c.actor["nombre"] == "Kael":
					var naira: Dictionary = {}
					for h in c.heroes:
						if h["nombre"] == "Naira":
							naira = h
					naira["atb"] = c.ATB_MAX * 0.7
					naira["mp"] = 30
					c._menu_magia(c.PESTANA_DUO)
					_siguiente(15)
				else:
					c._defender()
		15:
			_foto("12_penumbra_y_duo_kael")
			c.queue_free()
			c = null
			G.formar(["Kael", "Lya", "Naira"])
			c = load("res://combate.tscn").instantiate()
			root.add_child(c)
			for e in c.enemigos:
				e["vel"] = 0.2
			_siguiente(60)
		16:
			if c.estado == "menu" and c.actor is Dictionary and c.actor.get("hero", false):
				if c.actor["nombre"] == "Lya":
					for h in c.heroes:
						if h["nombre"] == "Naira":
							h["atb"] = c.ATB_MAX * 0.7
					c._menu_magia(c.PESTANA_DUO)
					_siguiente(15)
				else:
					c._defender()
		17:
			_foto("13_kael_lya_naira_duo_lya")
			_siguiente(5)
		18:
			Engine.remove_meta("naira_v12")
			print("FALLOS: %d" % fallos)
			quit(0)
	if frames > 30 * 120:
		print("FALLO: las fotos no terminaron (paso %d)" % paso)
		quit(1)
	return false


func _siguiente(n: int) -> void:
	paso += 1
	espera = n
