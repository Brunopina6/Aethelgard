extends SceneTree
# Arboleda Mítica, tramo experimental (16/11): renderiza una figura nueva (Yedra, Nívea) como sprite 2D desde los chibis
# v12 (personajes/npc_v12/<oficio>/<oficio>.glb, sin tocarlos) con su atlas nuevo (fuente/crear_npc_chibi.py, personas
# «yedra» y «nivea», generado fuera del proyecto), con la MISMA cámara ortográfica a 38° y la MISMA luz que
# pruebas/herramientas/render_isla.gd (dorada FFE2B0 a 1,25 desde arriba a la izquierda, relleno 7FA0D8 a 0,3, ambiente
# 0,55): el mismo «revelado» que el fondo de Meshy. Se renderiza al doble y se reduce (Lanczos) a la altura del juego.
# Uso: godot --path aethelgard --script res://zonas3d/arboleda_tramo/fuente/render_figura.gd --
#      <oficio> <atlas.png (ruta del disco)> <salida.png (res:// o disco)> [alto px, 112] [clip, reposo] [segundo, 0.6]

var a: PackedStringArray
var vp: SubViewport
var frames := 0
var alto := 112
var modelo: Node3D


func _initialize() -> void:
	a = OS.get_cmdline_user_args()
	if a.size() > 3:
		alto = int(a[3])
	var clip := a[4] if a.size() > 4 else "reposo"
	var seg := float(a[5]) if a.size() > 5 else 0.6
	vp = SubViewport.new()
	vp.size = Vector2i(alto * 2, int(alto * 2.4))
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("FFE2B0").lerp(Color.WHITE, 0.4)
	env.environment.ambient_light_energy = 0.55
	vp.add_child(env)
	var luz := DirectionalLight3D.new()
	luz.light_color = Color("FFE2B0")
	luz.light_energy = 1.25
	luz.rotation_degrees = Vector3(-50, -35, 0)
	luz.shadow_enabled = true
	vp.add_child(luz)
	var relleno := DirectionalLight3D.new()
	relleno.light_color = Color("7FA0D8")
	relleno.light_energy = 0.3
	relleno.rotation_degrees = Vector3(-20, 120, 0)
	vp.add_child(relleno)
	modelo = load("res://personajes/npc_v12/%s/%s.glb" % [a[0], a[0]]).instantiate()
	vp.add_child(modelo)
	var img := Image.load_from_file(a[1])
	img.generate_mipmaps()
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	for mi in modelo.find_children("*", "MeshInstance3D", true, false):
		mi.material_override = m
	var ap := modelo.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap != null and ap.has_animation(clip):
		ap.play(clip)
		ap.seek(seg, true)
		ap.pause()
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	cam.size = 2.05
	var r := deg_to_rad(38.0)
	var centro := Vector3(0, 0.78, 0)
	cam.look_at_from_position(centro + Vector3(0, sin(r), cos(r)) * 20.0, centro)
	vp.add_child(cam)
	cam.current = true


func _process(_d: float) -> bool:
	frames += 1
	if frames < 6:
		return false
	var img := vp.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	var caja := img.get_used_rect()
	var rec := img.get_region(caja)
	var h := alto
	var w := maxi(1, int(round(rec.get_width() * float(h) / rec.get_height())))
	rec.resize(w, h, Image.INTERPOLATE_LANCZOS)
	var sal := a[2]
	if sal.begins_with("res://"):
		sal = ProjectSettings.globalize_path(sal)
	rec.save_png(sal)
	print("figura %s: %d × %d → %s" % [a[0], w, h, sal])
	return true
