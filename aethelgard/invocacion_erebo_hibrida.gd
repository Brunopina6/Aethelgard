extends "res://invocacion_erebo_nueva.gd"
# V12, Érebo híbrida (15/11): la invocación de Érebo como UNA sola acción, contra el enemigo elegido (docs en
# docs/v12/EREBO_HIBRIDA_V12.md). EXPERIMENTAL y APAGADA por defecto: solo Auditoría o editor, con su propio valor en el
# selector de la invocación cinematográfica (Ajustes → «Érebo: invocación cinematográfica» → «Híbrida»; la misma clave
# [calidad_pruebas] erebo_cine que el vídeo). Con la opción apagada todo es como antes (de siempre, nueva o vídeo).
#
#   1. Señalar   en el combate, el enemigo elegido queda iluminado y el resto se oscurece (0,9 s)
#   2. Aparecer  en el escenario 3D de la invocación (el de siempre: Lya y el MODELO de ese enemigo), la sombra de Lya
#                corre hasta él y Érebo surge del suelo a su lado
#   3. Acercarse se desliza hasta él; su tamaño y altura se adaptan al pecho (o al núcleo) del objetivo
#   4. La mano   entra en el pecho (IK de alcance: la punta de la mano llega al punto de contacto)
#   5. Extraer   un corazón espectral (vfx/erebo_extraccion.gd) sale del pecho atado por un hilo de esencia y queda en
#                su mano · FALLO: se le escapa y vuelve al pecho, la mano se cierra sobre nada y no hay orbe
#                · JEFE: el corazón se resiste y vuelve, pero arranca un trozo (el 20 % que roba)
#   6. Ritual    el corazón sube de su palma y se condensa en el orbe; corte al ritual del vídeo de siempre desde el
#                primer plano del orbe (videos/erebo_ritual.ogv = completa 8,0-20,0 s; _breve = abreviada 1,8-6,8 s,
#                derivados de los mismos renders; los originales no se tocan). Sin vídeo (o «hibrida_3d»), el ritual en
#                tiempo real de la invocación nueva (aplastar el orbe y hundirse)
#   7. Vuelta    el vídeo acaba en su destello y el combate aparece debajo; combate.gd aplica el resultado UNA vez
#
# Reglas (no cambian): el dado es el de siempre y se tira ANTES de cualquier efecto (una vez; los jefes, sin dado); el
# resultado lo aplica combate.gd una sola vez al volver (también al saltar); mismo ATB que la invocación de siempre
# (V.ATB_TEATRO); saltar con un toque o Esc en cualquier momento. Azar de los efectos propio (vfx/erebo_extraccion.gd).
# Pruebas: «erebo_cine=hibrida|hibrida_breve|hibrida_3d» (manda sobre el ajuste).

const VIDEO := "res://invocacion_erebo_video.gd"
const CLAVE_CINE := "erebo_cine"
const MODOS := ["hibrida", "hibrida_breve", "hibrida_3d"]
const RITUAL := "res://videos/erebo_ritual.ogv"
const RITUAL_BREVE := "res://videos/erebo_ritual_breve.ogv"
const LARGO := {RITUAL: 12.0, RITUAL_BREVE: 5.0}
const BAJA_MUSICA_DB := -18.0       # como el vídeo: la música se aparta mientras dura y vuelve a su volumen exacto
const T_SENALAR := 0.9
const ALTO_MAX := 3.4              # alto máximo del doble en el escenario (m)
const SEMILLA_VFX := 1729           # azar propio de los efectos (siempre el mismo dibujo)

var _c: Node                         # el combate
var _esc := {}                       # el escenario (capa, ventana, mundo, cámara...)
var _tapado: Array = []
var _vfx: Node3D
var _cabeza_m: Node = null          # la cabeza firme de Érebo (vfx/erebo_cabeza_firme.gd)
var _cabeza_original := false
var _exito := false
var _jefe := false
var _modo := "hibrida"
var _medida := AABB()
var _nucleo := Vector3.ZERO          # el punto de contacto (pecho o núcleo)
var _k := 1.0                        # escala de Érebo
var _pies := Vector3.ZERO
var _e2 := Vector3.ZERO
var _db_mus := 0.0
var _i_mus := -1
var registro: Array = []             # [fase, segundos desde el principio] (pruebas y capturas)
var _t0 := 0


# ---------------------------------------------------------------- Ajustes

static func _V():
	return load(VIDEO)


static func modo() -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("erebo_cine="):
			var m := a.substr(11)
			return m if m in MODOS else ""
	if not _V().permitido():
		return ""
	var c := ConfigFile.new()
	if c.load("user://ajustes.cfg") != OK:
		return ""
	var m := str(c.get_value("calidad_pruebas", CLAVE_CINE, "no"))
	return m if m in MODOS else ""


static func activa() -> bool:
	return modo() != ""


# El valor del selector de Ajustes (el del vídeo o el de la híbrida).
static func valor_selector() -> String:
	var m := modo()
	return m if m != "" else _V().modo()


# Elige un valor del selector: los de la híbrida aquí; los del vídeo («no», «abreviada»...), en el vídeo.
static func elegir_modo(m: String) -> Error:
	if not m in MODOS:
		return _V().elegir(m)
	if not _V().permitido():
		return ERR_UNAUTHORIZED
	var c := ConfigFile.new()
	if FileAccess.file_exists("user://ajustes.cfg"):
		var err := c.load("user://ajustes.cfg")
		if err != OK:
			return err
	c.set_value("calidad_pruebas", CLAVE_CINE, m)
	return c.save("user://ajustes.cfg")


static func ruta_ritual(m: String) -> String:
	var r: String = {"hibrida": RITUAL, "hibrida_breve": RITUAL_BREVE}.get(m, "")
	return r if r != "" and ResourceLoader.exists(r) else ""


# ---------------------------------------------------------------- desde combate.gd (_invocar_sobre)

# Toda la invocación híbrida. Tira el dado (el mismo, antes de cualquier efecto), lleva el ATB como la invocación de
# siempre, la reproduce y aplica el resultado UNA vez con «al_resultado» (la función de combate.gd). Devuelve true.
static func invocar(c: Node, obj: Dictionary, es_jefe: bool, al_resultado: Callable) -> bool:
	var V = _V()
	var exito: bool = es_jefe or randf() < c.INVOCACION["prob_muerte"]     # el dado de siempre, una vez
	for a in OS.get_cmdline_user_args():                                    # pruebas: -- erebo=exito / erebo=fallo
		if a.begins_with("erebo="):
			exito = es_jefe or a.substr(6) == "exito"
	var nueva_sel: bool = load("res://invocacion_erebo_nueva.gd").elegida()
	var pausa: bool = load("res://combate_anim_v12.gd").pausa_atb()
	var tope: float = V.atb_teatro(nueva_sel, false)
	if pausa:                                   # ATB: como la invocación de siempre (ver invocacion_erebo_video.gd)
		c.set_meta("c12_accion", int(c.get_meta("c12_accion", 0)) + 1)
		c.set_meta("c12_atb_resto", tope)
	var inv = load("res://invocacion_erebo_hibrida.gd").new()
	inv.name = "EreboHibrida"
	c.add_child(inv)
	c.inv_erebo = inv                           # tocar la pantalla o Esc la saltan (combate.gd → saltar())
	await inv.dirigir(c, obj, es_jefe, exito)
	c.inv_erebo = null
	var corrido: float = tope - maxf(float(c.get_meta("c12_atb_resto", 0.0)), 0.0)
	if pausa:
		c.set_meta("c12_accion", maxi(0, int(c.get_meta("c12_accion", 0)) - 1))
		c.set_meta("c12_atb_resto", 0.0)
	al_resultado.call({"exito": exito, "muerte": exito and not es_jefe})   # UNA vez, de vuelta en el combate
	if pausa:
		c._avanzar_atb(V.atb_teatro(nueva_sel, exito) - corrido)
	inv.queue_free()
	return true


func _fase(n: String) -> void:
	registro.append([n, _t_juego])


# Tiempo de JUEGO desde que empezó (las pruebas corren con fps fijos: el reloj real no vale para medir ni esperar).
var _t_juego := 0.0

func _process(delta: float) -> void:
	super._process(delta)
	_t_juego += delta


func _saltado() -> bool:
	return saltada() or (_c != null and is_instance_valid(_c) and _c.saltar_invocacion)


func dirigir(c: Node, obj: Dictionary, es_jefe: bool, exito: bool) -> void:
	_c = c
	_exito = exito
	_jefe = es_jefe
	_modo = modo()
	_t0 = Time.get_ticks_msec()
	resultado = {"exito": exito, "muerte": exito and not es_jefe}
	_i_mus = AudioServer.get_bus_index("Musica")
	_db_mus = AudioServer.get_bus_volume_db(_i_mus) if _i_mus >= 0 else 0.0
	if _i_mus >= 0:
		create_tween().tween_method(func(v): AudioServer.set_bus_volume_db(_i_mus, v), _db_mus, _db_mus + BAJA_MUSICA_DB, 0.5)
	# 1. señalar al enemigo en el combate mientras se monta el escenario
	_fase("senalar")
	var senal := _senalar(c, obj)
	var t_senal := _t_juego
	await _montar_escenario(c, obj)
	while _t_juego - t_senal < T_SENALAR and not _saltado():
		await get_tree().process_frame
	if not _saltado():
		var tw := create_tween()
		tw.tween_property(senal.get_meta("velo").material, "shader_parameter/cierre", 1.0, 0.3)
		await tw.finished
	_tapado = c._tapar_combate(_esc["capa"])
	senal.queue_free()
	if not _saltado():
		_esc["negro"].color.a = 1.0
		create_tween().tween_property(_esc["pantalla"], "modulate:a", 1.0, 0.35)
		# 2-6. en tiempo real: aparecer, acercarse, la mano, extraer y el corazón en la mano
		await _hasta_fin(_secuencia.bind({}))
	# 6. el ritual
	if _exito and not _saltado():
		var ruta := ruta_ritual(_modo)
		var visto := false
		if ruta != "":
			visto = await _ritual_video(ruta)
		if not visto and not _saltado() and not _esc.is_empty():
			_fase("ritual_3d")
			await _hasta_fin(_ritual_3d)
	# 7. de vuelta al combate
	await _cerrar_escenario(0.05 if _saltado() else 0.2)
	if _vfx != null and is_instance_valid(_vfx):
		_vfx.quitar()
	_vfx = null
	Engine.time_scale = 1.0
	_reponer_musica()
	_fase("fin")


func _reponer_musica() -> void:
	if _i_mus >= 0:
		AudioServer.set_bus_volume_db(_i_mus, _db_mus)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_reponer_musica()


# ---------------------------------------------------------------- 1. señalar (en el combate 2D)

const SHADER_SENAL := """
shader_type canvas_item;
uniform vec2 centro = vec2(640.0, 360.0);
uniform float radio = 150.0;
uniform float oscuro = 0.0;
uniform float cierre = 0.0;
uniform vec2 tam = vec2(1280.0, 720.0);
void fragment() {
	float d = length(UV * tam - centro);
	float a = smoothstep(radio, radio * 1.8, d) * oscuro;
	COLOR = vec4(0.03, 0.01, 0.05, mix(a, 1.0, cierre));
}
"""

func _senalar(c: Node, obj: Dictionary) -> CanvasLayer:
	var capa := CanvasLayer.new()
	capa.layer = c.capa.layer + 2
	capa.name = "EreboHibridaSenal"
	c.add_child(capa)
	var centro: Vector2 = c._a_pantalla(c._centro(obj))
	var suelo: Vector2 = c._a_pantalla(c._suelo_de(obj))
	var radio := clampf(centro.distance_to(suelo) * 1.35, 90.0, 300.0)
	var velo := ColorRect.new()
	velo.size = Vector2(1280, 720)
	velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = SHADER_SENAL
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("centro", centro)
	m.set_shader_parameter("radio", radio)
	m.set_shader_parameter("oscuro", 0.0)
	m.set_shader_parameter("cierre", 0.0)
	velo.material = m
	capa.add_child(velo)
	capa.set_meta("velo", velo)
	create_tween().tween_property(m, "shader_parameter/oscuro", 0.82, 0.35).set_trans(Tween.TRANS_SINE)
	# el aro violeta que se cierra sobre él, y su luz
	var aro_tex := GradientTexture2D.new()
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.78, 0.88, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	aro_tex.gradient = g
	aro_tex.fill = GradientTexture2D.FILL_RADIAL
	aro_tex.fill_from = Vector2(0.5, 0.5)
	aro_tex.fill_to = Vector2(0.5, 0.0)
	aro_tex.width = 256
	aro_tex.height = 256
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	for i in 2:
		var aro := Sprite2D.new()
		aro.texture = aro_tex
		aro.material = add
		aro.position = centro
		aro.modulate = Color(0.62, 0.3, 1.0, 0.0) if i == 0 else Color(0.85, 0.86, 1.0, 0.0)
		var e0 := radio * 2.6 / 256.0
		var e1 := radio * 2.0 / 256.0
		aro.scale = Vector2.ONE * e0 * (1.0 + 0.25 * i)
		capa.add_child(aro)
		var t := create_tween().set_parallel(true)
		t.tween_property(aro, "scale", Vector2.ONE * e1 * (1.0 - 0.12 * i), 0.55 + 0.15 * i).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		t.tween_property(aro, "modulate:a", 0.9 if i == 0 else 0.6, 0.3)
	return capa


# ---------------------------------------------------------------- el escenario 3D (el de la invocación de siempre)

func _montar_escenario(c: Node, obj: Dictionary) -> void:
	var movil := OS.has_feature("mobile") or "movil" in OS.get_cmdline_user_args()
	ajustes.calidad = "movil" if movil else "alta"
	var q: float = c.res_personajes if movil else 1.0
	var capa_t := CanvasLayer.new()
	capa_t.layer = c.capa.layer + 1
	capa_t.name = "EreboHibridaEscenario"
	c.add_child(capa_t)
	var negro := ColorRect.new()
	negro.color = Color(0.03, 0.01, 0.05, 0.0)
	negro.size = Vector2(1280, 720)
	negro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa_t.add_child(negro)
	var vp := SubViewport.new()
	vp.size = Vector2i(int(1280 * q), int(720 * q))
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_DISABLED if movil else Viewport.MSAA_2X
	capa_t.add_child(vp)
	var pantalla := TextureRect.new()
	pantalla.texture = vp.get_texture()
	pantalla.size = Vector2(1280, 720)
	pantalla.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pantalla.stretch_mode = TextureRect.STRETCH_SCALE
	pantalla.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pantalla.modulate.a = 0.0
	capa_t.add_child(pantalla)
	var mundo := Node3D.new()
	vp.add_child(mundo)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.07, 0.05, 0.11)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.5, 0.8)
	e.ambient_light_energy = 0.55
	e.fog_enabled = true
	e.fog_light_color = Color(0.12, 0.08, 0.18)
	e.fog_density = 0.035
	env.environment = e
	mundo.add_child(env)
	var tex_fondo: Texture2D = c._textura_fondo()
	if tex_fondo != null:
		var lejos := Sprite3D.new()
		lejos.texture = tex_fondo
		lejos.pixel_size = 30.0 / tex_fondo.get_width()
		lejos.position = Vector3(0, 4.5, -11)
		lejos.shaded = false
		lejos.modulate = Color(0.42, 0.36, 0.5)
		mundo.add_child(lejos)
	var suelo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(40, 32)
	suelo.mesh = pm
	var ms := StandardMaterial3D.new()
	ms.albedo_color = Color(0.2, 0.17, 0.22).lerp(c.luz_3d * 0.3, 0.3)
	ms.roughness = 0.95
	suelo.material_override = ms
	mundo.add_child(suelo)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-50, -40, 0)
	sol.light_color = c.LUZ_PRINCIPAL.lerp(c.luz_3d, 0.3)
	sol.light_energy = 1.2
	sol.shadow_enabled = not movil
	mundo.add_child(sol)
	var relleno := DirectionalLight3D.new()
	relleno.light_color = c.LUZ_RELLENO
	relleno.light_energy = 0.35
	relleno.rotation_degrees = Vector3(-15, 140, 0)
	mundo.add_child(relleno)
	var cam := Camera3D.new()
	cam.fov = 40
	mundo.add_child(cam)
	cam.look_at_from_position(Vector3(0.6, 2.3, 5.2), Vector3(-0.2, 0.7, 0))
	cam.current = true
	var lya = load("res://maga_3d.gd").new()
	lya.ruta_modelo = c._ruta_3d(c.MODELOS["nyx3d"])
	mundo.add_child(lya)
	lya.position = Vector3(1.7, 0, 0.5)
	# el MISMO modelo del enemigo elegido (combate.gd _doble_3d: su 3D o su dibujo de pie); una copia propia de este
	# escenario: el enemigo de verdad no se toca
	var doble: Node3D = c._doble_3d(obj)
	mundo.add_child(doble)
	doble.position = Vector3(-1.8, 0, -0.1)
	var titulo: Label = c._etiqueta(c.INVOCACION["nombre"], 64, Color(1.0, 0.85, 0.9), c.menu.f_nombre)
	titulo.size = Vector2(1280, 90)
	titulo.position = Vector2(0, 26)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.modulate.a = 0.0
	titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa_t.add_child(titulo)
	evento.connect(c._evento_erebo.bind(titulo))
	_esc = {"capa": capa_t, "negro": negro, "pantalla": pantalla, "vp": vp, "mundo": mundo, "cam": cam, "lya": lya,
		"doble": doble, "titulo": titulo}
	for i in 4:
		await get_tree().process_frame
	# los grandes, más lejos (que quepan Érebo y la cámara entre ellos y Lya)
	_medida = _medir(doble)
	if _medida.end.y > ALTO_MAX:                 # los colosos (Bramavidrio, Humbaba), a una escala en la que caben con
		doble.scale *= ALTO_MAX / _medida.end.y   # Érebo en el plano (la misma forma; solo esta copia)
		await get_tree().process_frame
		_medida = _medir(doble)
	var ancho := maxf(_medida.size.x, _medida.size.z)
	if ancho > 1.4:
		doble.position.x -= minf(ancho * 0.5 - 0.7, 6.0)
		doble.position.z -= minf(ancho * 0.25, 3.0)
		_medida = _medir(doble)
	camara = cam
	_cam_trans = cam.global_transform
	_cam_fov = cam.fov
	_crear_velo()
	_invocador = lya
	_objetivo = doble
	await _preparar({"objetivo": doble, "invocador": lya})
	# la cabeza firme (15/11, petición del usuario): un modificador propio sobre el esqueleto de ESTE Érebo
	# («erebo_cabeza=original»: sin la cabeza firme, solo para comparar; el modificador queda a peso 0 y solo mide)
	if erebo.get("skel") != null and erebo.get("gestos") != null:
		_cabeza_m = load("res://vfx/erebo_cabeza_firme.gd").new()
		_cabeza_m.name = "CabezaFirme"
		erebo.skel.add_child(_cabeza_m)
		_cabeza_m.preparar(erebo.gestos)
		_cabeza_original = "erebo_cabeza=original" in OS.get_cmdline_user_args()
	_vfx = load("res://vfx/erebo_extraccion.gd").new()
	mundo.add_child(_vfx)


# Caja del modelo en su pose de AHORA, en el mundo: los huesos de sus esqueletos (las mallas con piel dan la caja de su
# pose de reposo, que no vale: Bramavidrio la tiene tumbado) y las mallas y dibujos sin piel.
func _medir(n: Node3D) -> AABB:
	var a := AABB()
	var hay := false
	for v in n.find_children("*", "", true, false):
		var b := AABB()
		if v is Skeleton3D:
			if v.get_bone_count() == 0:
				continue
			b = AABB(v.global_transform * v.get_bone_global_pose(0).origin, Vector3.ZERO)
			for i in v.get_bone_count():
				b = b.expand(v.global_transform * v.get_bone_global_pose(i).origin)
			b = b.grow(maxf(b.size.x, maxf(b.size.y, b.size.z)) * 0.08)
		elif (v is MeshInstance3D and v.skin == null) or v is SpriteBase3D:
			if not v.is_visible_in_tree():
				continue
			b = v.global_transform * v.get_aabb()
		else:
			continue
		a = b if not hay else a.merge(b)
		hay = true
	if not hay:
		a = AABB(n.global_position - Vector3(0.4, 0, 0.4), Vector3(0.8, 1.6, 0.8))
	return a


func _cerrar_escenario(pausa: float) -> void:
	if _esc.is_empty():
		_destapar()
		return
	if is_instance_valid(_esc["capa"]):
		await get_tree().create_timer(pausa).timeout
		_destapar()
		var t := create_tween()
		t.tween_property(_esc["pantalla"], "modulate:a", 0.0, 0.3)
		t.parallel().tween_property(_esc["titulo"], "modulate:a", 0.0, 0.3)
		t.tween_property(_esc["negro"], "color:a", 0.0, 0.35)
		await t.finished
	_quitar_escenario()


func _destapar() -> void:
	if not _tapado.is_empty() and _c != null and is_instance_valid(_c):
		_c._destapar_combate(_tapado)
	_tapado = []


func _quitar_escenario() -> void:
	_destapar()
	if _esc.is_empty():
		return
	if _vfx != null and is_instance_valid(_vfx):
		_vfx.quitar()
	_vfx = null
	if erebo != null and is_instance_valid(erebo):
		erebo.cancelado = true
	if is_instance_valid(_esc["capa"]):
		_esc["capa"].queue_free()
	_esc = {}
	erebo = null                              # (se van con el escenario: que nadie los toque después)
	sombra = null
	_invocador = null
	_objetivo = null
	_luces.clear()
	_ambiente = null
	camara = null                              # (la base la mira en _process y al saltar)


# ---------------------------------------------------------------- 2-6. la acción en tiempo real

func _secuencia(_ctx: Dictionary) -> void:
	var lya: Node3D = _invocador
	var doble: Node3D = _objetivo
	_guardar_luces()
	_pies = lya.global_position
	var n: Vector3 = doble.global_position
	n.y = 0.0
	var u: Vector3 = _pies - n
	u.y = 0.0
	u = u.normalized()
	var lado_a: Vector3 = u.cross(Vector3.UP).normalized()
	if lado_a.dot(camara.global_position - n) < 0.0:
		lado_a = -lado_a
	var lado_b := -lado_a
	_lado = lado_a
	_hacia = u
	var arriba := Vector3.UP
	var alto_obj := maxf(_medida.end.y, 0.4)
	# el punto de contacto: el pecho (esqueleto), el núcleo (criaturas con «corazón»/«núcleo») o, si no, la caja
	_nucleo = _punto_contacto(doble, u)
	var centro_obj := _medida.get_center()
	centro_obj.y = 0.0
	# colocación POR LA MANO (como la invocación nueva): escala por la altura del contacto; si el contacto queda más alto
	# de lo que llega, flota hasta él; si queda más bajo, asoma desde su charco (hundido en él)
	erebo.global_position = _nucleo - u * 0.0 + Vector3(0, -_nucleo.y, 0) + u * 0.95
	erebo.mirar(-u, 0.0)
	var o: Vector3 = erebo.punta_en("Extraer", T_CONTACTO)
	var h := _nucleo.y
	_k = clampf(h / maxf(o.y, 0.01), 0.8, 1.6)
	if h >= 0.7:
		_k = maxf(_k, 1.0)
	erebo.scale = Vector3.ONE * _k
	var der_e := (-u).cross(Vector3.UP).normalized()
	var objetivo_mano := _nucleo - u * 0.05
	var e1 := objetivo_mano - (-u) * o.x * _k - der_e * o.z * _k
	e1.y = _nucleo.y - o.y * _k                                  # (0 si llega de pie)
	var e0 := e1 + u * (0.45 + 0.25 * _k)
	e0.y = minf(e1.y, 0.0)
	erebo.global_position = e0
	erebo.mano_objetivo = objetivo_mano
	var tam_c := 0.085 * _altura(erebo) * _k
	registro.append(["medida", _medida, _nucleo, _k, e1])           # (diagnóstico: caja, contacto, escala y sitio)
	_vfx.preparar(tam_c, SEMILLA_VFX)
	var S := maxf(alto_obj, 1.2)                                  # tamaño para encuadrar
	var mira_obj := Vector3(centro_obj.x, alto_obj * 0.5, centro_obj.z)

	# 2a · El enemigo señalado (1,0 s): plano del objetivo con el sello violeta a sus pies; Lya alza el bastón
	_fase("objetivo")
	if lya.has_method("lanzar_magia"):
		lya.lanzar_magia()
	_bajar_luz(0.65, 0.8)
	sonar(SND % "susurros", -8.0)
	_vfx.marcar(Vector3(centro_obj.x, 0.02, centro_obj.z), maxf(_medida.size.x, _medida.size.z) * 0.6 + 0.3)
	var p_obj := mira_obj + u * (1.5 + 1.1 * S) + lado_a * (0.8 + 0.5 * S) + arriba * (0.1 + 0.25 * S)
	plano(p_obj, mira_obj, 0.0, 42.0)
	plano(p_obj - (p_obj - mira_obj).normalized() * 0.35 * S, mira_obj, 1.0, 40.0)
	_objetivo_mira(_pies)
	_alerta(0.4)
	await esperar(1.0)
	if saltada(): return

	# 2b · La sombra de Lya corre hasta él (0,8 s) y Érebo surge (1,5 s)
	_fase("aparece")
	_apagar_sombra(lya)
	sonar(SND % "sombra", -3.0)
	var e0s := Vector3(e0.x, 0.0, e0.z)
	plano(_pies + lado_a * 1.2 + arriba * 0.45 - u * 0.2, _pies.lerp(e0s, 0.5), 0.0, 48.0)
	plano(e0s + u * 1.6 + lado_a * 1.4 + arriba * 0.5, e0s.lerp(n, 0.3) + arriba * 0.3, 0.8, 46.0)
	await _hasta_fin(sombra.viajar.bind(_pies, e0s, 0.8))
	if saltada(): return
	sombra.ocultar(0.4)
	evento.emit("invocacion")                                   # el título
	var medio := e0.lerp(Vector3(centro_obj.x, 0, centro_obj.z), 0.4)    # (Érebo, más al centro del plano)
	var alto_plano := maxf(1.1 * _k, S * 0.45)
	plano(medio + lado_a * (2.4 + 1.2 * maxf(_k, S * 0.6)) + u * 0.6 + arriba * alto_plano, medio + arriba * alto_plano * 0.75, 0.0, 46.0)
	plano(medio + lado_a * (2.1 + 1.1 * maxf(_k, S * 0.6)) + u * 0.5 + arriba * alto_plano, medio + arriba * alto_plano * 0.8, 1.5, 44.0)
	_objetivo_mira(e0s)
	await _hasta_fin(erebo.emerger_quieto.bind(1.5, 0.05))
	if saltada(): return

	# 3 · Se acerca (0,9 s): por detrás de su hombro derecho, hacia el pecho del enemigo (la cabeza, firme y fija en él)
	_fase("acercamiento")
	_cabeza(1.0, objetivo_mano, 0.45)
	var hombro := e1 + der_e * 1.25 * _k + u * 1.35 * _k + arriba * 1.15 * _k
	plano(hombro + u * 0.4 * _k + arriba * 0.1, objetivo_mano, 0.0, 40.0)
	plano(hombro, objetivo_mano.lerp(e1 + arriba * 0.8 * _k, 0.3), 1.1, 38.0)
	sonar(SND % "pulso", -6.0, 0.8)
	await _hasta_fin(erebo.deslizar.bind(e1, 0.9))
	if saltada(): return

	# 4-5 · La mano en el pecho y el corazón
	await _hasta_fin(_extraer.bind(objetivo_mano, e1, u, der_e))
	if saltada(): return

	if not _exito:
		# FALLO: la mano se cierra sobre nada; sin orbe. Érebo mira su mano vacía y se hunde
		_fase("fallo")
		evento.emit("fallo")
		_lya_gesto("fallo")
		var mano_v: Vector3 = erebo._punta_mano()                # la mano vacía, de cerca
		_cabeza(1.0, mano_v, 0.2)
		plano(mano_v + _lado * 0.95 * _k + u * 0.55 * _k + arriba * 0.15 * _k, mano_v, 0.35, 34.0)
		await esperar(0.8)
		if saltada(): return
		if _cabeza_m != null:
			registro.append(["cabeza", _cabeza_m.ladeo, _cabeza_m.ladeo_max, _cabeza_m.vel_max_medida, _cabeza_m.peso])
		if camara != null:                                      # corte al plano general: se hunde
			if _cam_tw != null and _cam_tw.is_valid():
				_cam_tw.kill()
			camara.global_transform = _cam_trans
			camara.fov = _cam_fov
		await _salida_nueva(_pies)
		return

	# 6a · El corazón (o el trozo) en su mano: se aparta y se vuelve hacia la cámara para mostrarlo
	_fase("en_la_mano")
	_cabeza(1.0, func(): return (_vfx.fragmento if _jefe else _vfx.corazon).global_position if _vfx != null and is_instance_valid(_vfx) else null, 0.2)
	_e2 = e1 + u * (0.55 * _k)
	erebo.deslizar(_e2, 0.7)
	var frente := (u * 0.45 + lado_a).normalized()            # de cara a la cámara, de espaldas al enemigo (no lo tapa)
	erebo.mirar(frente, 0.5)
	var cara := _e2 + arriba * 1.0 * _k
	plano(cara + frente * 1.85 * _k + arriba * 0.1 * _k, cara - arriba * 0.2 * _k, 0.0, 36.0)   # (corte: el viaje cruzaba su capucha)
	sonar(SND % "pulso", -3.0, 1.0)
	if not _jefe:
		_vaciar()                                               # el enemigo se queda sin fuerzas
	await esperar(0.65)
	if saltada(): return
	var en_mano: Node3D = _vfx.fragmento if _jefe else _vfx.corazon
	registro.append(["corazon_mano", en_mano.global_position.distance_to(erebo._punta_mano()), en_mano.visible])
	if _cabeza_m != null:                                       # (ladeo ahora y máximo, y giro más rápido, desde el acercamiento)
		registro.append(["cabeza", _cabeza_m.ladeo, _cabeza_m.ladeo_max, _cabeza_m.vel_max_medida, _cabeza_m.peso])
	sonar(SND % "pulso", -2.0, 1.1)
	await esperar(0.45)
	if saltada(): return

	# 6b · Sube de su palma y se condensa en el orbe, que queda flotando delante de la máscara (el primer plano del orbe
	# es donde empieza el ritual del vídeo)
	_fase("orbe")
	sonar(SND % "tension", -6.0)
	var mano: Vector3 = erebo._punta_mano()
	var flota := mano + arriba * 0.22 * _k + frente * 0.12 * _k
	_vfx.soltar(flota, 0.45)
	_cabeza(1.0, flota, 0.2)
	plano(flota + frente * 0.75 * _k + arriba * 0.05 * _k, flota, 0.9, 30.0)
	await esperar(0.45)
	if saltada(): return
	if ruta_ritual(_modo) != "":                                # el violeta del orbe del vídeo (solo en este Érebo)
		erebo._mat_orbe.set_shader_parameter("nucleo", Color(0.72, 0.5, 1.0))
		erebo._mat_orbe.set_shader_parameter("borde", Color(0.22, 0.1, 0.42))
	erebo._radio = 0.01 * _altura(erebo)
	erebo._orbe_en = ""
	erebo.orbe.global_position = flota
	erebo.orbe.visible = true
	erebo._halo.visible = true
	erebo._halo.global_position = flota
	erebo._tw().tween_property(erebo, "_radio", 0.034 * _altura(erebo), 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await _vfx.condensar(0.6)
	if saltada(): return
	if ruta_ritual(_modo) != "":
		create_tween().tween_property(_esc["titulo"], "modulate:a", 0.0, 0.3)
		destello(Color(0.93, 0.88, 1.0, 0.55), 0.35)
		await esperar(0.15)


# La mano entra, agarra y tira; el corazón sale (éxito), se escapa (fallo) o se parte (jefe).
func _extraer(objetivo_mano: Vector3, e1: Vector3, u: Vector3, lado_mano: Vector3) -> void:
	_fase("mano")
	var llegada := 1.1
	erebo.gestos.quitar_todos(0.1)
	erebo.aura_mano.visible = true
	erebo.anim.play(erebo.nombres.get("Extraer", "Extraer"), 0.2, (0.80 - 0.15) / llegada)
	erebo.anim.seek(0.15, true)
	var ik: Tween = erebo._tw()
	ik.tween_property(erebo, "ik_mano", 1.0, llegada * 0.45).set_delay(llegada * 0.4).set_trans(Tween.TRANS_SINE)
	var origen := objetivo_mano - u * 0.04 * _k
	_vfx.brillar_dentro(origen, llegada)
	await esperar(llegada)
	if saltada(): return
	erebo.anim.speed_scale = 1.0
	erebo.anim.seek(0.80, true)
	# el contacto: onda en el pecho, pausa de impacto, el enemigo se arquea
	_fase("contacto")
	if _cabeza_m != null:                                       # (mide la cabeza desde aquí: el mismo tramo con y sin)
		_cabeza_m.medir = true
	registro.append(["error_mano", erebo._punta_mano().distance_to(objetivo_mano)])   # (la punta, en el contacto)
	evento.emit("contacto")
	sonar(SND % "pulso", 0.0)
	_onda_pecho(objetivo_mano)
	sacudir(0.02, 0.15)
	_alerta(1.0)                                                # se arquea (sin su clip de herida: se movería delante)
	await congelar(0.35, 0.12)
	if saltada(): return
	# plano lateral: el pecho y la mano, de perfil
	var arriba := Vector3.UP
	var medio := (objetivo_mano + Vector3(e1.x, objetivo_mano.y, e1.z)) * 0.5
	var dist := 1.35 + 0.6 * _k
	var lado_vis := _lado if (erebo._punta_mano() - erebo.global_position).dot(_lado) > 0.0 else -_lado   # el lado de la mano
	if lado_vis.dot(lado_mano) < 0.0:
		lado_mano = lado_vis
	plano(medio + lado_mano * dist + arriba * 0.2 * _k + u * 0.2 * _k, medio, 0.0, 38.0)
	await esperar(0.25)                                         # los dedos se cierran dentro (0,80 → 1,05)
	if saltada(): return
	_fase("agarra")
	evento.emit("agarra")
	sonar(SND % "extraccion", -2.0)
	_vfx.nacer(erebo._punta_mano())
	_vfx.sigue = erebo._punta_mano
	_vfx.tension = 0.3
	# el tirón lo lleva la IK (la mano sigue un camino propio, fuera del cuerpo y a la vista): el clip se queda en el
	# agarre y la punta de la mano va del pecho hacia Érebo
	erebo.anim.speed_scale = 0.0
	var arriba2 := Vector3.UP
	var fuera := objetivo_mano + u * 0.5 * _k + arriba2 * 0.06 * _k
	if _exito and not _jefe:
		_vfx.tension = 0.6
		await _tirar(objetivo_mano.lerp(fuera, 0.45), 0.7)
		if saltada(): return
		_fase("sale")
		_cabeza(1.0, func(): return _vfx.corazon.global_position if _vfx != null and is_instance_valid(_vfx) else null, 0.2)
		_vfx.romper_hilo()                                      # sale del todo
		_vfx.tension = 0.0
		sacudir(0.03, 0.2)
		destello(Color(0.85, 0.8, 1.0, 0.25), 0.2)
		await _tirar(fuera, 0.45)
		if saltada(): return
		await esperar(0.35)
		if saltada(): return
	else:
		# se resiste: el tirón se para a medio camino y el corazón tiembla, atado al pecho
		await _tirar(objetivo_mano.lerp(fuera, 0.42), 0.55)
		if saltada(): return
		_vfx.tension = 1.0
		sonar(SND % "tension", -4.0, 1.2)
		sacudir(0.025, 0.4)
		await _tirar(objetivo_mano.lerp(fuera, 0.48), 0.45)
		if saltada(): return
		if _jefe:
			_fase("trozo")
			_cabeza(1.0, func(): return _vfx.fragmento.global_position if _vfx != null and is_instance_valid(_vfx) else null, 0.2)
			_vfx.partir(erebo._punta_mano)                      # vuelve, pero se queda un trozo en la mano
			_vfx.tension = 0.0
			sacudir(0.04, 0.25)
			destello(Color(0.85, 0.8, 1.0, 0.25), 0.2)
			await _tirar(fuera, 0.4)
		else:
			_fase("se_escapa")
			_vfx.volver(0.4)                                    # se le escapa y vuelve al pecho
			_vfx.tension = 0.0
			await _tirar(fuera, 0.35)                           # la mano se cierra sobre nada
			if saltada(): return
			_vfx.rafaga(erebo._punta_mano(), Color(0.42, 0.29, 0.55), 10, 0.35)
			erebo.evento.emit("vacia")
		if saltada(): return
		await esperar(0.5)
		if saltada(): return
	# suelta la IK y el clip termina el gesto (retira la mano)
	erebo.anim.seek(1.45, true)
	erebo.anim.speed_scale = 1.0
	var suelta: Tween = erebo._tw()
	suelta.tween_property(erebo, "ik_mano", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
	erebo.aura_mano.visible = false


# La punta de la mano hasta «a» en «dur» segundos (con la IK de alcance de Érebo).
func _tirar(a: Vector3, dur: float) -> void:
	var t: Tween = erebo._tw()
	t.tween_property(erebo, "mano_objetivo", a, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await esperar(dur)


# El punto donde entra la mano (y de donde sale el corazón), en el mundo.
func _punto_contacto(o: Node3D, u: Vector3) -> Vector3:
	var p = null
	if o.has_method("corazon"):
		p = o.corazon()                                         # Bramavidrio: «el corazón para Érebo»
	elif o.has_method("nucleo"):
		p = o.nucleo()
	elif o.has_method("punto") and String(o.get_script().resource_path).contains("humbaba"):
		p = o.punto("nucleo")
	if p is Vector3:
		# el núcleo puede estar hondo: la mano entra hasta poco antes, por el lado de Érebo
		return _hacia_fuera(p, u, 0.45)
	var sk = o.get("skel")
	var g = o.get("gestos")
	if sk != null and g != null and g.get("idx") is Dictionary and g.idx.get("pecho", -1) >= 0:
		return _pecho(o, u)
	var cen = o.get("CENTRO")
	if cen is Vector3:
		return _hacia_fuera(o.global_transform * cen, u, 0.6)
	if o.get_script() != null and String(o.get_script().resource_path).ends_with("muneco_invocacion.gd"):
		return o.global_position + Vector3(0, _altura(o) * 0.5, 0) + u * 0.08
	var c := _medida.get_center()
	return _hacia_fuera(Vector3(c.x, _medida.position.y + _medida.size.y * 0.5, c.z), u, 0.6)


# De «p» hacia fuera (dirección u) una fracción de lo que queda hasta el borde de la caja del modelo.
func _hacia_fuera(p: Vector3, u: Vector3, f: float) -> Vector3:
	var hasta := 0.0
	for i in 60:
		var q := p + u * (i * 0.05)
		if not _medida.grow(0.001).has_point(q):
			break
		hasta = i * 0.05
	return p + u * hasta * f


# ---------------------------------------------------------------- 6-7. el ritual

# El tramo del ritual en vídeo, empalmado en el primer plano del orbe. Devuelve true si el vídeo arrancó (entonces el
# escenario ya se quitó debajo); false si no llegó a arrancar (el escenario sigue: ritual en tiempo real).
func _ritual_video(ruta: String) -> bool:
	_fase("ritual_video")
	var V = _V()
	var r := {"hecho": false, "ok": false, "arranco": false}
	var parar := [false]
	var c := _c
	var al_arrancar := func():
		r["arranco"] = true
		_fase("video_arranca")
		_quitar_escenario()                    # bajo el negro del vídeo: el combate queda listo para la vuelta
	_reponer_musica()                          # (reproducir() la aparta desde su volumen de verdad)
	var lanzar := func():
		r["ok"] = await V.reproducir(c, ruta, func(): return c.saltar_invocacion or parar[0], al_arrancar)
		r["hecho"] = true
	lanzar.call()
	var t := 0.0
	var largo: float = LARGO.get(ruta, 20.0)
	var destello := false
	while not r["hecho"]:
		await get_tree().process_frame
		t += get_process_delta_time()
		if r["arranco"] and not destello:                       # (fin del vídeo: su destello final, para pruebas)
			var capa_v = c.get_node_or_null("EreboCinematica")
			if capa_v != null:
				for vp in capa_v.find_children("*", "VideoStreamPlayer", true, false):
					if not vp.visible:
						destello = true
						_fase("video_destello")
		if t > largo + 6.0:                    # salvaguarda propia: nunca se queda colgada
			parar[0] = true
	_fase("video_fin")
	if not r["arranco"] and _i_mus >= 0:
		AudioServer.set_bus_volume_db(_i_mus, _db_mus + BAJA_MUSICA_DB)
	return r["arranco"]


# El ritual en tiempo real (sin vídeo, o «hibrida_3d»): el de la invocación nueva. Toma el orbe que flota, lo aplasta
# y Érebo se hunde.
func _ritual_3d() -> void:
	if erebo == null or not is_instance_valid(erebo):
		return
	_cabeza(1.0, func(): return erebo.orbe.global_position if erebo != null and is_instance_valid(erebo) and erebo.orbe.visible else null, 0.2)
	var arriba := Vector3.UP
	var ante := _e2 + arriba * 0.85 * _k
	plano(_e2 + _lado * 2.0 * _k + _hacia * 0.25 + arriba * 1.0 * _k, ante, 0.4, 34.0)
	await _hasta_fin(erebo.aplastar.bind(_al_estallar, [0.32, 0.28, 0.24], 0.3, true))
	if saltada(): return
	await esperar(0.05)
	if saltada(): return
	await _salida_nueva(_pies)


func _al_saltar() -> void:
	for k in ["erebo", "sombra", "_invocador", "_objetivo", "kael"]:
		var v = get(k)
		if v != null and not is_instance_valid(v):
			set(k, null)
	super._al_saltar()
	if _vfx != null and is_instance_valid(_vfx):
		_vfx.quitar()
	_vfx = null
	_fase("saltada")


# La cabeza firme: «peso» en «dur» segundos y a qué mira (un punto o una función que lo da cada fotograma).
func _cabeza(peso: float, que = null, dur := 0.5) -> void:
	if _cabeza_m == null or not is_instance_valid(_cabeza_m):
		return
	if _cabeza_original:
		return
	if que is Callable:
		_cabeza_m.sigue = que
	elif que is Vector3:
		_cabeza_m.sigue = Callable()
		_cabeza_m.mirar_a = que
	create_tween().tween_property(_cabeza_m, "peso", peso, dur).set_trans(Tween.TRANS_SINE)

