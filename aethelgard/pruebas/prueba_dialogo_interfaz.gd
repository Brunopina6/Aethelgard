extends SceneTree
# Prueba de la interfaz de los diálogos reutilizada (recursos.gd, carga.gd y «dialogic/layout/end_behaviour» = 1):
#   1. el proyecto oculta la interfaz al acabar un diálogo (no la borra) y el estilo existe;
#   2. precalentar_dialogos() la crea oculta una sola vez;
#   3. un diálogo la usa (la misma) y se ve;
#   4. cortado en seco (end_timeline(true), sin el final de Dialogic) no deja nada: ni texto, ni nombre, ni retratos, y la
#      interfaz sigue viva y oculta. Antes, un control: sin la limpieza de Recursos sí queda algo (si no, esta prueba no
#      comprobaría nada);
#   5. el diálogo siguiente usa la misma interfaz y no enseña nada del anterior;
#   6. con el final normal (end_timeline(): el «[clear]» de Dialogic) también acaba oculta, viva y limpia;
#   7. sigue viva tras cambiar de escena.
# Sin ventana. Usa los diálogos reales npc_rosa (con retrato) y pv_tilo.

const ESPERA_FINAL := 150                        # fotogramas para el final normal de Dialogic (anima y tarda ~1-2 s)

var R
var D
var frames := 0
var paso := 0
var f_paso := 0
var interfaz
var fallos: Array = []


func _initialize() -> void:
	R = root.get_node("Recursos")
	D = root.get_node("Dialogic")


func _fallo(texto: String) -> void:
	fallos.append(texto)


func _textos() -> String:
	var r := ""
	for n in get_nodes_in_group("dialogic_dialog_text"):
		r += str(n.text)
	for n in get_nodes_in_group("dialogic_name_label"):
		if n.is_visible_in_tree():
			r += str(n.text)
	return r.strip_edges()


func _retratos() -> int:
	return D.Portraits.get_joined_characters().size()


func _limpia(cuando: String) -> void:
	if D.current_timeline != null:
		_fallo("%s: el diálogo no ha terminado" % cuando)
	if not is_instance_valid(interfaz) or interfaz.is_queued_for_deletion() or D.Styles.get_layout_node() != interfaz:
		_fallo("%s: al acabar se ha borrado la interfaz" % cuando)
	elif interfaz.visible:
		_fallo("%s: al acabar la interfaz sigue viéndose" % cuando)
	if _retratos() > 0:
		_fallo("%s: al acabar queda un retrato" % cuando)
	if _textos() != "":
		_fallo("%s: al acabar queda texto («%s»)" % [cuando, _textos().left(40)])


func _siguiente() -> void:
	paso += 1
	f_paso = frames


func _process(_d: float) -> bool:
	frames += 1
	var f := frames - f_paso
	match paso:
		0:
			if frames < 3:
				return false
			if int(ProjectSettings.get_setting("dialogic/layout/end_behaviour", 0)) != 1:
				_fallo("1: el proyecto no oculta la interfaz al acabar (dialogic/layout/end_behaviour != 1)")
			var estilo: String = R.ruta_estilo_dialogos()
			if estilo == "" or not ResourceLoader.exists(estilo):
				_fallo("1: no se encuentra el estilo de los diálogos (%s)" % estilo)
			var us: int = R.precalentar_dialogos()
			interfaz = D.Styles.get_layout_node()
			if us <= 0 or interfaz == null:
				_fallo("2: precalentar_dialogos() no ha creado la interfaz")
			elif interfaz.visible:
				_fallo("2: la interfaz preparada se ve")
			if R.precalentar_dialogos() != 0 or D.Styles.get_layout_node() != interfaz:
				_fallo("2: precalentar_dialogos() la ha creado otra vez")
			D.timeline_ended.disconnect(R._al_acabar_dialogo)   # para el control
			_siguiente()
		1:                                          # control, sin la limpieza de Recursos: algo queda
			if f == 2:
				if not is_instance_valid(interfaz) or not interfaz.is_inside_tree():
					_fallo("2: la interfaz preparada no está en el árbol")
				D.start("npc_rosa")
			elif f == 20:
				D.end_timeline(true)
			elif f == 25:
				if _retratos() == 0 and _textos() == "":
					_fallo("control: sin la limpieza de Recursos tampoco queda nada (la prueba 4 no comprobaría nada)")
				D.clear(DialogicGameHandler.ClearFlags.KEEP_VARIABLES)
				D.timeline_ended.connect(R._al_acabar_dialogo)
				_siguiente()
		2:                                          # cortado en seco, con la limpieza
			if f == 2:
				D.start("npc_rosa")
			elif f == 20:
				if D.current_timeline == null or D.Styles.get_layout_node() != interfaz or not interfaz.visible:
					_fallo("3: el diálogo no usa la interfaz preparada o no se ve")
				if _textos() == "" or _retratos() == 0:
					_fallo("3: el diálogo no muestra texto o retrato (la prueba no comprueba nada)")
				D.end_timeline(true)
			elif f == 25:
				_limpia("4 (cortado en seco)")
				_siguiente()
		3:                                          # el siguiente diálogo; luego, final normal
			if f == 2:
				D.start("pv_tilo")
			elif f == 3:
				if D.Styles.get_layout_node() != interfaz or not interfaz.visible:
					_fallo("5: el diálogo siguiente no usa la misma interfaz")
				if _retratos() > 0:
					_fallo("5: el diálogo siguiente empieza con un retrato del anterior")
				if "Rosa" in _textos() or "flores" in _textos():
					_fallo("5: el diálogo siguiente enseña texto del anterior")
			elif f == 20:
				D.end_timeline()
			elif f == 20 + ESPERA_FINAL:
				_limpia("6 (final normal)")
				change_scene_to_packed(_escena_vacia())
				_siguiente()
		4:
			if f == 5:
				if not is_instance_valid(interfaz) or D.Styles.get_layout_node() != interfaz:
					_fallo("7: la interfaz no sigue viva tras cambiar de escena")
				print("OK interfaz de los diálogos: preparada una vez, oculta entre diálogos, limpia y viva tras cambiar de escena")
				for t in fallos:
					print("FALLO: ", t)
				print("FALLOS: %d" % fallos.size())
				quit(1 if fallos.size() > 0 else 0)
				return true
	if frames > 900:
		print("FALLO: tiempo agotado en el paso %d" % paso)
		quit(1)
		return true
	return false


func _escena_vacia() -> PackedScene:
	var p := PackedScene.new()
	p.pack(Node.new())
	return p
