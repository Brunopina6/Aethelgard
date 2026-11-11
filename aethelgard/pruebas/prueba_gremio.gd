extends SceneTree
# El Gremio de aventureros (V11, hito C; gremio.gd, gremio_menu.gd y el tablón de la plaza de Oakhaven), con datos
# aislados y su propia partida:
#   1. Contrato de derrotar: aceptar, contar solo los caídos de su tipo, cobrar una vez (oro y reputación).
#   2. Contrato de entregar: con menos de lo pedido no se cobra; al cobrar se gasta lo entregado y llega el premio.
#   3. Contrato de cumplir (ayudar a Mirta): se cumple con el hito; la reputación sube de Bronce a Plata y abre
#      contratos que antes estaban bloqueados.
#   4. Guardar y cargar: el gremio va en la partida; una partida antigua sin gremio empieza en Bronce sin errores.
#   5. Un combate de verdad ganado cuenta los limos caídos para el contrato aceptado.
#   6. La ventana del tablón: un botón por contrato, Aceptar funciona, Atrás de Android la cierra.
#   7. En la ciudad 2D, junto al tablón de la plaza, el botón dice «Leer el tablón» y abre la ventana.
# Imprime «FALLOS: n».

const ARCHIVO := "user://prueba_gremio.save"
const T := 64.0
var Gr
var P
var Inv
var fallos := 0


func _ok(cond: bool, t: String) -> void:
	if not cond:
		fallos += 1
		print("FALLO: ", t)


func _initialize() -> void:
	Gr = load("res://gremio.gd")
	P = load("res://progreso.gd")
	Inv = load("res://inventario.gd")
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	_probar.call_deferred()


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _limpiar() -> void:
	for k in P.CLAVES + ["partida_lista", "grupo_combate", "combate_fijo", "tipo_combate", "zona", "desde_mapa"]:
		if Engine.has_meta(k):
			Engine.remove_meta(k)


func _probar() -> void:
	await _esperar(5)
	_limpiar()
	_derrotar()
	_entregar()
	_cumplir()
	_guardar()
	await _combate()
	await _ventana()
	await _ciudad()
	for extra in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(ARCHIVO + extra):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(ARCHIVO + extra))
	print("FALLOS: %d" % fallos)
	quit(1 if fallos > 0 else 0)


func _derrotar() -> void:
	_ok(Gr.nombre_rango() == "Bronce" and Gr.reputacion() == 0, "1: no empieza en Bronce con 0")
	_ok(Gr.estado("gr_limos") == "disponible" and Gr.estado("gr_hachas") == "bloqueado", "1: estados iniciales mal")
	_ok(Gr.cobrar("gr_limos") == "", "1: se cobra sin aceptar")
	_ok(Gr.aceptar("gr_limos") and not Gr.aceptar("gr_limos"), "1: aceptar dos veces")
	Gr.contar_derrotas(["slime", "grimfang", "slime"])
	_ok(Gr.progreso("gr_limos") == 2 and Gr.estado("gr_limos") == "aceptado", "1: cuenta mal (%d)" % Gr.progreso("gr_limos"))
	Gr.contar_derrotas(["slime"])
	_ok(Gr.estado("gr_limos") == "listo", "1: con 3 limos no está listo")
	var oro0: int = Inv.oro()
	var t: String = Gr.cobrar("gr_limos")
	_ok(t.contains("40 monedas") and Inv.oro() == oro0 + 40 and Gr.reputacion() == 2 and Gr.estado("gr_limos") == "hecho",
		"1: el cobro no da 40 monedas y 2 de reputación («%s»)" % t)
	_ok(Gr.cobrar("gr_limos") == "" and Inv.oro() == oro0 + 40, "1: se cobra dos veces")


func _entregar() -> void:
	Gr.aceptar("gr_musgo")
	Inv.agregar_objeto("Musgo de piedra", 1)
	_ok(Gr.estado("gr_musgo") == "aceptado" and Gr.cobrar("gr_musgo") == "", "2: con 1 musgo de 2 se cobra")
	Inv.agregar_objeto("Musgo de piedra", 2)
	var pociones: int = Inv.cantidad("Poción")
	var t: String = Gr.cobrar("gr_musgo")
	_ok(t != "" and Inv.cantidad("Musgo de piedra") == 1 and Inv.cantidad("Poción") == pociones + 1,
		"2: no gasta 2 musgos o no da la Poción (musgo %d, «%s»)" % [Inv.cantidad("Musgo de piedra"), t])


func _cumplir() -> void:
	Gr.aceptar("gr_formula")
	_ok(Gr.estado("gr_formula") == "aceptado", "3: el favor a la botica se cumple sin el hito")
	P.poner_hito("enc_formula_fin")
	_ok(Gr.estado("gr_formula") == "listo", "3: con el hito no está listo")
	var t: String = Gr.cobrar("gr_formula")
	_ok(Gr.reputacion() == 6 and Gr.nombre_rango() == "Plata" and t.contains("¡Rango Plata"),
		"3: con 6 de reputación no se sube a Plata («%s», %d)" % [t, Gr.reputacion()])
	_ok(Gr.estado("gr_hachas") == "disponible" and Gr.estado("gr_ambar") == "bloqueado", "3: Plata no abre lo suyo")


func _guardar() -> void:
	var d: Dictionary = P.volcar("res://mapa.tscn")
	_ok(d.has("gremio") and int(d["gremio"]["rep"]) == 6, "4: el gremio no va en la partida")
	var copia: Dictionary = str_to_var(var_to_str(d))
	Engine.remove_meta("gremio")
	_ok(Gr.nombre_rango() == "Bronce", "4: sin gremio no se vuelve a Bronce")
	P.restaurar(copia)
	_ok(Gr.reputacion() == 6 and Gr.estado("gr_limos") == "hecho" and Gr.estado("gr_musgo") == "hecho",
		"4: tras cargar, el gremio no es el mismo")
	var vieja: Dictionary = copia.duplicate(true)
	vieja.erase("gremio")
	P.restaurar(vieja)
	_ok(not Engine.has_meta("gremio") and Gr.reputacion() == 0 and Gr.estado("gr_limos") == "disponible",
		"4: una partida antigua sin gremio no empieza de cero")
	Gr.contar_derrotas(["slime"])
	_ok(not Engine.get_meta("gremio", {}).get("aceptados", {}).has("gr_limos"), "4: cuenta sin contrato aceptado")


func _combate() -> void:
	_limpiar()
	var G = load("res://grupo.gd")
	G.datos()
	Engine.set_meta("grupo_activo", ["Kael"])
	G.datos()["Kael"]["nivel"] = 5
	Engine.set_meta("zona", "ceniza")
	Engine.set_meta("tipo_combate", "normal")
	Engine.set_meta("grupo_combate", 8)                 # dos limos
	Gr.aceptar("gr_limos")
	var c = load("res://combate.tscn").instantiate()
	root.add_child(c)
	await _esperar(30)
	c.set_process(false)
	for e in c.enemigos:
		e["hp"] = 0
	c._comprobar_fin()
	for i in 400:
		await _esperar(1)
		if Gr.progreso("gr_limos") > 0:
			break
	_ok(Gr.progreso("gr_limos") == 2, "5: ganar a dos limos no cuenta 2 para el contrato (%d)" % Gr.progreso("gr_limos"))
	await _esperar(60)
	if is_instance_valid(c):
		c.queue_free()
	if current_scene != null and current_scene != c:
		current_scene.queue_free()
	await _esperar(10)


func _ventana() -> void:
	var m = load("res://gremio_menu.gd").new()
	var cerrado := [false]
	m.cerrado.connect(func(): cerrado[0] = true)
	root.add_child(m)
	await _esperar(3)
	_ok(m.botones.size() == Gr.CONTRATOS.size(), "6: el tablón no tiene un botón por contrato (%d)" % m.botones.size())
	var b: Button = m.botones["gr_musgo"]
	_ok(b.disabled or b.text != "", "6: botón vacío")
	_ok(m.cabecera.text.begins_with("Rango "), "6: no dice el rango («%s»)" % m.cabecera.text)
	# aceptar desde la ventana (con el botón, como un dedo)
	var libre := ""
	for c in Gr.CONTRATOS:
		if Gr.estado(c["id"]) == "disponible":
			libre = c["id"]
			break
	if libre != "":
		m.botones[libre].pressed.emit()
		await _esperar(2)
		_ok(Gr.estado(libre) in ["aceptado", "listo"], "6: Aceptar no acepta %s" % libre)
	root.propagate_notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await _esperar(3)
	_ok(cerrado[0] and not is_instance_valid(m), "6: Atrás no cierra el tablón")


func _ciudad() -> void:
	_limpiar()
	Engine.set_meta("archivo_partida_prueba", ARCHIVO)
	Engine.set_meta("partida_lista", true)
	Engine.set_meta("lugar", {"indice": 0, "nombre": "Oakhaven", "tipo": "ciudad"})
	var tablon: Vector2 = load("res://ciudades/oakhaven.gd").PIEZAS.filter(func(p): return p["id"] == "oak_tablon_gremio")[0]["casilla"]
	Engine.set_meta("pos_zona", (tablon + Vector2(0, 0.7)) * T)
	Engine.set_meta("pos_zona_ok", true)
	Engine.set_meta("pos_zona_lugar", 0)
	change_scene_to_file("res://ciudad_oakhaven.tscn")
	await _esperar(40)
	var z = current_scene
	_ok(z != null and z.boton_examinar.visible and z.boton_examinar.text == "Leer el tablón",
		"7: junto al tablón el botón no dice «Leer el tablón» («%s»)" % (z.boton_examinar.text if z != null else "sin ciudad"))
	z._accion()
	await _esperar(3)
	_ok(z.gremio_abierto != null and is_instance_valid(z.gremio_abierto), "7: «Leer el tablón» no abre el tablón")
	if z.gremio_abierto != null:
		z.gremio_abierto.cerrar_menu()
		await _esperar(3)
		_ok(z.gremio_abierto == null, "7: la ciudad no se entera de que se cerró el tablón")
