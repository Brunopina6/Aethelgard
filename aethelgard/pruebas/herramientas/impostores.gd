extends SceneTree
# Pinta la imagen de cada árbol (LOD0) para su impostor (experimento LOD, nivel lejano): desde la inclinación y el
# rumbo de la cámara del juego, con la misma luz del sol y el mismo ambiente, sobre fondo transparente y SIN el ajuste
# de color ni la exposición de la escena (el impostor se dibuja sin luz y la escena se los vuelve a aplicar).
# Uso (necesita ventana, no --headless): godot --path aethelgard --script res://pruebas/herramientas/impostores.gd
# Escribe vegetacion_prueba/quaternius/impostores/<árbol>.png y .json (tamaño y centro de la tarjeta).
const SALIDA := "res://vegetacion_prueba/quaternius/impostores/"
const LADO := 512
const CAPA := 1 << 19
var n := 0
var v: Node
var paso := 0
var vp: SubViewport
var cam: Camera3D
var arbol: MeshInstance3D
var datos := {}
var perfil_srgb := "srgb" in OS.get_cmdline_user_args()


func _initialize() -> void:
	Engine.set_meta("calidad_proto", "medio")
	Engine.set_meta("calidad_extra", {})
	change_scene_to_file("res://prototipos/vegetacion_paquetes.tscn")


func _process(_d: float) -> bool:
	n += 1
	if n < 60:
		return false
	v = current_scene
	if paso >= v.VARIANTES.size() * 2:
		quit()
		return true
	var i := paso / 2
	if paso % 2 == 0:
		_preparar(i)
	elif n % 20 == 0:
		var img := vp.get_texture().get_image()
		if perfil_srgb:
			img.linear_to_srgb()      # en Compatibility la imagen del SubViewport sale en lineal
		img.save_png(ProjectSettings.globalize_path(SALIDA + v.VARIANTES[i] + ".png"))
		var f := FileAccess.open(SALIDA + v.VARIANTES[i] + ".json", FileAccess.WRITE)
		f.store_string(JSON.stringify(datos))
		f.close()
		print("IMPOSTOR %s: %s" % [v.VARIANTES[i], datos])
		vp.queue_free()
		arbol.queue_free()
	else:
		return false
	paso += 1
	return false


func _preparar(i: int) -> void:
	var o: Vector3 = v.kael.global_position + Vector3(0, 9, 0)   # dentro del alcance de la sombra del sol (si no, sale sin luz directa)
	arbol = MeshInstance3D.new()
	arbol.mesh = v._malla_arbol(v.VARIANTES[i], i)
	arbol.layers = CAPA
	arbol.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	v.add_child(arbol)
	arbol.global_position = o
	var ang := deg_to_rad(v.inclinacion)
	var atras := Vector3(sin(deg_to_rad(v.GIRO)), 0, cos(deg_to_rad(v.GIRO)))
	var dir := (atras * cos(ang) + Vector3.UP * sin(ang)).normalized()     # del árbol hacia la cámara
	var caja: AABB = arbol.mesh.get_aabb()
	vp = SubViewport.new()
	cam = Camera3D.new()
	vp.size = Vector2i(LADO, LADO)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	v.add_child(vp)
	vp.add_child(cam)

	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.cull_mask = CAPA
	var c := o + caja.get_center()
	cam.look_at_from_position(c + dir * 60.0, c, Vector3.UP)
	var der := cam.global_transform.basis.x
	var arriba := cam.global_transform.basis.y
	var ancho := 0.0
	var alto := 0.0
	for k in 8:
		var q := caja.get_endpoint(k) - caja.get_center()
		ancho = maxf(ancho, absf(q.dot(der)) * 2.0)
		alto = maxf(alto, absf(q.dot(arriba)) * 2.0)
	cam.size = maxf(ancho, alto) * 1.04
	var env: Environment = null
	for x in v.get_children():
		if x is WorldEnvironment:
			env = x.environment.duplicate()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.background_color = Color(0, 0, 0, 0)
	env.fog_enabled = false
	env.adjustment_enabled = false
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.tonemap_exposure = v.EXPO_CON_SOMBRAS     # como la escena (sin ella la luz del sol se satura); se compensa al dibujar
	env.glow_enabled = false
	cam.environment = env

	cam.current = true
	datos = {"ancho": cam.size, "alto": cam.size, "centro_y": caja.get_center().dot(arriba), "exposicion": v.EXPO_CON_SOMBRAS}
