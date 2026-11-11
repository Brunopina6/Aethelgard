extends SceneTree
# Foto de combate de Bramavidrio (V12): el modelo provisional de zonas3d/mar_cristal/gusano.gd (anillos de piel parda,
# placas de vidrio y boca de placas planas), saliendo de un montón de arena, con fondo transparente y la luz del combate
# (dorada desde arriba a la izquierda, relleno azul). Escribe res://enemigos/bramavidrio/bramavidrio.png (400 × 520, los
# pies abajo en el centro), que usa combate.gd (MODELOS «bramavidrio», tipo «imagen»), hasta que gráficos haga su GLB.
# Necesita ventana (dibujar): Godot --path aethelgard --script res://pruebas/herramientas/foto_bramavidrio.gd
# Con datos aislados (APPDATA, LOCALAPPDATA, TEMP y TMP redirigidos), como todas las herramientas.

const SALIDA := "res://enemigos/bramavidrio/bramavidrio.png"
const TAM := Vector2i(400, 520)


func _initialize() -> void:
	_foto.call_deferred()


func _foto() -> void:
	var vp := SubViewport.new()
	vp.size = TAM
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 10.4
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1.0, 0.86, 0.78)
	env.ambient_light_energy = 0.55
	cam.environment = env
	vp.add_child(cam)
	var ang := deg_to_rad(12.0)
	cam.look_at_from_position(Vector3(0, 4.6 + sin(ang) * 12.0, cos(ang) * 12.0), Vector3(0, 4.6, 0))
	cam.current = true
	var luz := DirectionalLight3D.new()
	luz.light_color = Color(1.0, 0.88, 0.70)
	luz.light_energy = 1.35
	luz.rotation_degrees = Vector3(-35, -40, 0)
	vp.add_child(luz)
	var relleno := DirectionalLight3D.new()
	relleno.light_color = Color(0.62, 0.74, 1.0)
	relleno.light_energy = 0.35
	relleno.rotation_degrees = Vector3(-15, 140, 0)
	vp.add_child(relleno)
	var Gusano = load("res://zonas3d/mar_cristal/gusano.gd")
	var g = Gusano.new(null)
	var cuerpo: Node3D = g._modelo_gusano()
	vp.add_child(cuerpo)
	cuerpo.rotation.y = deg_to_rad(-115.0)                       # de lado, inclinado hacia los héroes (a la derecha): se ven las placas del lomo
	var monton := MeshInstance3D.new()                          # la arena que revienta alrededor
	var s := SphereMesh.new()
	s.radius = 1.0
	s.height = 1.0
	monton.mesh = s
	monton.scale = Vector3(3.0, 0.9, 2.2)
	var ma := StandardMaterial3D.new()
	ma.albedo_color = Color(0.88, 0.70, 0.48)
	ma.roughness = 1.0
	monton.material_override = ma
	monton.position = Vector3(0, 0.15, 0)
	vp.add_child(monton)
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	img.flip_x()                                                # en el combate los héroes están a la derecha: que se incline hacia ellos
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SALIDA.get_base_dir()))
	var err := img.save_png(ProjectSettings.globalize_path(SALIDA))
	print("foto_bramavidrio: %s (%d × %d) → %s" % [error_string(err), img.get_width(), img.get_height(), SALIDA])
	quit(0 if err == OK else 1)
