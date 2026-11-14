extends Node2D
# V12 (14/11), fase 3C, EXPERIMENTAL y APAGADO por defecto: la magia AGUA mejorada (Agua, Torrente y Maremoto), solo
# presentación. La magia de siempre está en combate.gd (_carga_magia, _proyectil, _efecto_agua y _maremoto); estos
# ganchos solo actúan con la opción encendida:
#   carga      anticipación en quien lanza: ondas que se CIERRAN hacia sus pies (el agua acude) y tres corrientes que
#              suben en espiral hasta su mano, con gotas; sigue al círculo mágico (aparece y se apaga con él). Al soltar
#              la magia, las corrientes se recogen en la mano y salpican.
#   proyectil  la bola de agua: un orbe de agua con volumen que tiembla, se estira en la dirección del vuelo y deja gotas
#              detrás (el brillo de siempre queda debajo, más suave).
#   impacto    EN el mismo fotograma del daño (combate.gd: _quitar_pv → _golpe_visual → _efecto_agua): aro de
#              salpicadura, una membrana de agua que envuelve al enemigo y revienta a los 0,66 s (Agua y Torrente), gotas
#              que caen con gravedad y salpican al tocar el suelo, bruma, aro de espuma y un charco que se seca.
#   ola        Maremoto: la ola tiene cuerpo (agua translúcida con cresta de espuma, rizo, cortina y rompiente) y deja un
#              rastro de espuma en el suelo que se seca. La cresta pasa por cada enemigo en el instante de su golpe.
#
# - Opción «Magia Agua v12» (Ajustes, SOLO en la APK de Auditoría o en el editor; [calidad_pruebas] magia_agua_v12 de
#   user://ajustes.cfg). En pruebas: argumento «agua_v12» (encendida) o «agua_v12_no» (apagada). Sin la opción, la
#   magia es exactamente la de siempre (los ganchos ni se crean).
# - No cambia daño, costes, tiempos ni el orden del combate. El AZAR TAMPOCO: cada CPUParticles2D que se crea toma una
#   tirada del azar global (ver combate_anim_v12.gd, _chispas), así que el impacto conserva las mismas llamadas de
#   siempre que crean partículas (géiser 3D o chorro 2D, espiral y, a los 0,7 s, la salpicadura y la bruma), en el
#   mismo orden y momento (solo cambia cuántas partículas sueltan, que no toma tiradas); lo nuevo se dibuja a mano, con
#   valores fijos. Lo comprueba pruebas/prueba_magia_agua_v12.gd (mismo daño, mismos fotogramas de golpe y misma tirada
#   siguiente con la opción apagada y encendida).
# - Identidad: agua, no hielo (azules hondos y saturados, espuma blanca, formas redondas que tiemblan, caen con gravedad y
#   salpican; nada de aristas ni cian pálido quieto). Lo que tapaba sin contar nada (el destello de toda la pantalla, el
#   globo de luz y los tres aros) se sustituye; el géiser 3D, la espiral de gotas y la salpicadura final se conservan.
# - Legibilidad: todo va en la escena del combate, por DEBAJO de la capa de números, barras y avisos; la ola es
#   translúcida y pasa en ≈0,4 s por cada sitio. En Torrente (tres a la vez) cada impacto lleva menos; en Maremoto la ola
#   manda: los impactos no llevan membrana y la espiral y la salpicadura de siempre sueltan menos.
# - Coste: todo con dos texturas pequeñas (gota y aro, 32 y 64 px) dibujadas como rectángulos sin girar, para que se
#   agrupen en pocas llamadas de dibujo; sin luces nuevas, sin 3D, sin sombreadores. Móvil (CALIDAD_MOVIL): las
#   cantidades se multiplican por la calidad del combate (0,4). «Reducir destellos» (argumento «reducir_destellos» o
#   Engine.set_meta("reducir_destellos", true)): sin fogonazo de pantalla y con los brillos a la mitad.
# - Limpieza: cada pieza se borra sola al acabar su vida y cuelga de la escena del combate (o de la bola o la ola, que se
#   borran antes); el único temporizador (el de siempre, 0,7 s) va con referencia débil: al saltar, morir o cambiar de
#   escena todo se va con el combate. Repetir no acumula (prueba_magia_agua_v12: repetir ×3 y borrar el combate).

const CLAVE := "magia_agua_v12"
const GRUPO := "agua_v12"
const RUTA := "res://vfx/agua_v12.gd"

const AZUL_HONDO := Color(0.05, 0.2, 0.55)
const AZUL := Color(0.14, 0.46, 0.95)
const AZUL_CLARO := Color(0.55, 0.83, 1.0)
const ESPUMA := Color(0.94, 0.98, 1.0)
const GRAVEDAD := 1150.0

static var _activo_cache = null

var modo := ""
var t := 0.0
var vida := 1.0
var c: Node = null                   # el combate
var aditivo: Node2D = null           # capa de brillos (mezcla aditiva)
var brillo := 1.0                    # 0,5 con «reducir destellos»
var q := 1.0                         # cantidad de partículas (calidad del combate)
var datos := {}
var rng := RandomNumberGenerator.new()


# ---------------------------------------------------------------- opción (Auditoría / editor / pruebas)

static func permitido() -> bool:
	return OS.has_feature("auditoria") or OS.has_feature("editor")


static func activo() -> bool:
	for a in OS.get_cmdline_user_args():
		if a == "agua_v12":
			return true
		if a == "agua_v12_no":
			return false
	if _activo_cache == null:
		_activo_cache = false
		if permitido():
			var cf := ConfigFile.new()
			_activo_cache = cf.load("user://ajustes.cfg") == OK and bool(cf.get_value("calidad_pruebas", CLAVE, false))
	return bool(_activo_cache)


static func elegir(si: bool) -> Error:
	if not permitido():
		return ERR_UNAUTHORIZED
	var cf := ConfigFile.new()
	if FileAccess.file_exists("user://ajustes.cfg"):
		var err := cf.load("user://ajustes.cfg")
		if err != OK:
			return err
	cf.set_value("calidad_pruebas", CLAVE, si)
	_activo_cache = null
	return cf.save("user://ajustes.cfg")


static func reducir_destellos() -> bool:
	return "reducir_destellos" in OS.get_cmdline_user_args() or bool(Engine.get_meta("reducir_destellos", false))


# Cuántas piezas vivas hay (pruebas).
static func vivos(arbol: SceneTree, de_modo := "") -> int:
	var n := 0
	for x in arbol.get_nodes_in_group(GRUPO):
		if not x.is_queued_for_deletion() and (de_modo == "" or x.modo == de_modo):
			n += 1
	return n


# ---------------------------------------------------------------- ganchos (combate.gd)

# _carga_magia: anticipación bajo quien lanza; sigue al círculo (su transparencia) y se suelta con soltar().
static func carga(cb: Node, o: Dictionary, circulo: Node2D) -> void:
	var n = _nuevo(cb, "carga", circulo.position, 12.0)
	n.datos = {"circulo": circulo, "o": o, "tam": circulo.scale.x, "alfa": 0.0, "suelta": -1.0, "fin": -1.0,
		"mano": Vector2(0, -170)}
	n.datos["mano"] = n._mano_local()
	cb.escena.add_child(n)


# _proyectil (Agua): el orbe de agua sobre la bola de siempre (que queda más suave, debajo).
static func proyectil(cb: Node, bola: Node2D) -> void:
	_soltar_cargas(cb)
	bola.self_modulate.a *= 0.5
	var n = _nuevo(cb, "proyectil", Vector2.ZERO, 3.0)
	n.scale = Vector2.ONE / maxf(bola.scale.x, 0.01)
	n.datos = {"ultima": Vector2.INF, "vel": Vector2(-1, 0)}
	bola.add_child(n)


# _efecto_agua: el golpe. Llamado en el MISMO fotograma del daño. potencia: 1 Agua, 0,7 Torrente, 1,0001 Maremoto.
static func impacto(cb: Node, centro: Vector2, suelo: Vector2, potencia := 1.0) -> void:
	var q0 := potencia
	var en_ola := potencia > 1.0
	# 1) Lo de siempre que toma tiradas del azar global: las mismas llamadas, en el mismo orden y momento (cuántas
	#    partículas suelta cada una no toma tiradas; en Maremoto, menos, porque la ola ya llena la pantalla).
	if not cb._vfx_3d(cb.VFX_AGUA, suelo):          # géiser 3D (o chorro 2D si no cabe)
		cb._particulas(suelo, Color(0.55, 0.8, 1.0, 0.8), Color(0.15, 0.4, 1.0, 0.0), int(110 * q0), 1.1, Vector2(450, 750),
			35.0, Vector2(0, -1), 9.0, Vector2(0, 1100), 0.11)
	var esp: CPUParticles2D = cb._particulas(suelo + Vector2(0, -20), Color(0.8, 0.95, 1.0, 1.0), Color(0.3, 0.6, 1.0, 0.0),
		int((22 if en_ola else 40) * q0), 1.0, Vector2(10, 30), 85.0, Vector2(0, -1), 20.0, Vector2(0, -260), 0.1)   # espiral
	esp.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE_SURFACE
	esp.orbit_velocity_min = 0.9
	esp.orbit_velocity_max = 1.3
	var ref: WeakRef = weakref(cb)                     # (si el combate se borra antes, no hace nada ni da error)
	cb.get_tree().create_timer(0.7).timeout.connect(func():
		var cv = ref.get_ref()
		if cv != null and cv.is_inside_tree():
			cv._particulas(centro, Color(0.9, 0.97, 1.0, 1.0), Color(0.3, 0.6, 1.0, 0.0), int((18 if en_ola else 34) * q0), 0.8,
				Vector2(250, 480), 40.0, Vector2(0, -1), 180.0, Vector2(0, 900), 0.09)
			cv._humo(suelo + Vector2(0, -30), Color(0.85, 0.92, 1.0), 6 if en_ola else 10))
	# 2) Lo nuevo (sin azar global).
	if potencia == 1.0 and not reducir_destellos():
		cb._fogonazo(Color(0.3, 0.6, 1.0), 0.1, 0.25)   # antes 0,22: ahora el golpe lo cuenta el agua
	cb._luz(Color(0.45, 0.75, 1.0), 2.2, 5.0, 1.0, centro)
	var alto := clampf(suelo.y - centro.y, 70.0, 420.0)
	var n = _nuevo(cb, "impacto", centro, 1.5)
	n.z_index = 6                                      # delante del enemigo, como el géiser
	n.datos = {"suelo": suelo, "pot": potencia, "membrana": not en_ola,
		"r": clampf(alto * 1.05, 110.0, 260.0) * (0.85 if potencia < 1.0 else 1.0)}
	n._preparar_impacto()
	cb.escena.add_child(n)
	var ch = _nuevo(cb, "charco", suelo, 2.1)
	ch.datos = {"r": clampf(alto * 1.25, 120.0, 300.0) * (1.15 if en_ola else (0.85 if potencia < 1.0 else 1.0)),
		"charco": not en_ola}
	ch._preparar_charco()
	cb.sombras.add_child(ch)                           # en el suelo, detrás de los luchadores


# _maremoto: la ola con cuerpo y su rastro de espuma.
static func ola(cb: Node, nodo_ola: Node2D, dur: float) -> void:
	_soltar_cargas(cb)
	for h in nodo_ola.get_children():                  # las manchas de luz de siempre, por dentro y más suaves
		if h is Sprite2D:
			h.self_modulate.a *= 0.3
	var n = _nuevo(cb, "ola", Vector2.ZERO, dur + 0.8)
	nodo_ola.add_child(n)
	var e = _nuevo(cb, "estela", Vector2(0, nodo_ola.position.y), dur + 2.2)
	e.datos = {"ola": nodo_ola, "muestras": [], "paso": 26.0 if e.q >= 0.99 else 40.0, "ultima_x": INF}
	cb.sombras.add_child(e)


static func _soltar_cargas(cb: Node) -> void:
	for x in cb.get_tree().get_nodes_in_group(GRUPO):
		if x.modo == "carga" and not x.is_queued_for_deletion():
			x.soltar()


static func _nuevo(cb: Node, m: String, pos: Vector2, v: float) -> Node2D:
	var n = load(RUTA).new()
	n.c = cb
	n.modo = m
	n.vida = v
	n.position = pos
	n.q = clampf(float(cb.calidad), 0.2, 1.0)
	n.brillo = 0.5 if reducir_destellos() else 1.0
	n.rng.seed = 7103 + m.length() * 31             # generador propio con semilla fija: no toca el azar del combate
	return n


# Las dos texturas (gota: disco de borde suave; aro: anillo fino junto al borde) se guardan en el combate (meta):
# se crean una vez por combate y se van con él (nada estático retenido al salir).
func _tex(clave: String) -> Texture2D:
	var k := "agua_v12_" + clave
	if c.has_meta(k):
		return c.get_meta(k)
	var g := Gradient.new()
	var lado := 32
	if clave == "gota":
		g.offsets = PackedFloat32Array([0.0, 0.5, 0.78, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.95), Color(1, 1, 1, 0.45), Color(1, 1, 1, 0)])
	else:
		lado = 64
		g.offsets = PackedFloat32Array([0.0, 0.7, 0.85, 0.92, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 0.7), Color(1, 1, 1, 0)])
	var tx := GradientTexture2D.new()
	tx.gradient = g
	tx.fill = GradientTexture2D.FILL_RADIAL
	tx.fill_from = Vector2(0.5, 0.5)
	tx.fill_to = Vector2(1.0, 0.5)
	tx.width = lado
	tx.height = lado
	c.set_meta(k, tx)
	return tx


# ---------------------------------------------------------------- ciclo

func _ready() -> void:
	add_to_group(GRUPO)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR   # las texturas son pequeñas y se estiran: suavizadas
	aditivo = Node2D.new()
	aditivo.material = c.mat_aditivo
	aditivo.draw.connect(_dibujar_aditivo)
	add_child(aditivo)
	queue_redraw()


func _process(delta: float) -> void:
	t += delta
	match modo:
		"carga":
			_proceso_carga()
		"proyectil":
			var gp := global_position
			if datos["ultima"] != Vector2.INF and delta > 0.0:
				var v: Vector2 = (gp - datos["ultima"]) / delta
				if v.length() > 20.0:
					datos["vel"] = (datos["vel"] as Vector2).lerp(v, 0.5)
			datos["ultima"] = gp
		"estela":
			_proceso_estela()
	if t >= vida:
		queue_free()
		return
	queue_redraw()
	aditivo.queue_redraw()


func _draw() -> void:
	match modo:
		"carga":
			_dibujar_carga(false)
		"proyectil":
			_dibujar_proyectil(false)
		"impacto":
			_dibujar_impacto(false)
		"charco":
			_dibujar_charco(false)
		"ola":
			_dibujar_ola(false)
		"estela":
			_dibujar_estela()


func _dibujar_aditivo() -> void:
	match modo:
		"carga":
			_dibujar_carga(true)
		"proyectil":
			_dibujar_proyectil(true)
		"impacto":
			_dibujar_impacto(true)
		"charco":
			_dibujar_charco(true)
		"ola":
			_dibujar_ola(true)


# Una gota (disco suave) de ancho «tam», «alto» veces más alta que ancha (gotas que caen o suben: estiradas).
func _gota(en: CanvasItem, pos: Vector2, tam: float, col: Color, alto := 1.0) -> void:
	if col.a <= 0.003 or tam <= 0.3:
		return
	en.draw_texture_rect(_tex("gota"), Rect2(pos.x - tam * 0.5, pos.y - tam * alto * 0.5, tam, tam * alto), false, col)


# Un disco suave elíptico (charco, destello).
func _disco(en: CanvasItem, centro: Vector2, rx: float, ry: float, col: Color) -> void:
	if col.a <= 0.003 or rx <= 0.3:
		return
	en.draw_texture_rect(_tex("gota"), Rect2(centro.x - rx, centro.y - ry, rx * 2.0, ry * 2.0), false, col)


# Un aro elíptico (ondas, salpicaduras): radio «r», alto = r × «aplasta».
func _aro(en: CanvasItem, centro: Vector2, r: float, aplasta: float, col: Color) -> void:
	if col.a <= 0.003 or r <= 0.5:
		return
	en.draw_texture_rect(_tex("aro"), Rect2(centro.x - r, centro.y - r * aplasta, r * 2.0, r * 2.0 * aplasta), false, col)


static func _suave(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)


static func _ruido(i: int, s: int) -> float:              # 0..1 fijo para (i, s): formas que no parpadean
	var h := sin(float(i) * 12.9898 + float(s) * 78.233) * 43758.5453
	return h - floor(h)


# ---------------------------------------------------------------- carga (anticipación)

func _mano_local() -> Vector2:
	var o: Dictionary = datos["o"]
	var maga = c._p3d(o)
	if maga != null and is_instance_valid(maga) and maga.has_method("punto_magia") and o.has("cam3d") \
			and o.has("partes") and o["partes"].has("sprite"):
		var cam: Camera3D = o["cam3d"]
		var spr: Sprite2D = o["partes"]["sprite"]
		return c.escena.to_local(spr.to_global(cam.unproject_position(maga.punto_magia()))) - position
	return c._centro(o) + Vector2(0, -80) - position


func soltar() -> void:
	if modo == "carga" and float(datos["suelta"]) < 0.0:
		datos["suelta"] = t
		vida = minf(vida, t + 0.45)


func _proceso_carga() -> void:
	var circ = datos["circulo"]
	var vivo: bool = is_instance_valid(circ) and not circ.is_queued_for_deletion()
	if vivo:
		datos["alfa"] = float(circ.modulate.a)
	elif float(datos["fin"]) < 0.0 and float(datos["suelta"]) < 0.0:
		datos["fin"] = t                                 # se fue el círculo sin soltar (cancelado): apagar
		vida = minf(vida, t + 0.25)
	if float(datos["suelta"]) < 0.0:
		datos["mano"] = _mano_local()


# Punto de la corriente «j» a la altura «u» (0 suelo, 1 mano) y si va por detrás de quien lanza.
func _corriente(j: int, u: float, mano: Vector2, tam: float) -> Array:
	var r := lerpf(110.0 * tam, 12.0, pow(u, 0.8))
	var a := j * TAU / 3.0 + u * 4.2 + t * 2.6
	return [mano * u + Vector2(cos(a) * r, sin(a) * r * 0.32), sin(a) < 0.0]


func _dibujar_carga(luz: bool) -> void:
	var en: CanvasItem = aditivo if luz else self
	var tam: float = datos["tam"]
	var alfa: float = float(datos["alfa"]) * _suave(t / 0.5)
	var ts: float = datos["suelta"]
	var s := 0.0 if ts < 0.0 else clampf((t - ts) / 0.2, 0.0, 1.0)
	if float(datos["fin"]) >= 0.0:
		alfa *= 1.0 - clampf((t - float(datos["fin"])) / 0.25, 0.0, 1.0)
	var mano: Vector2 = datos["mano"]
	var recoge := 1.0 - s
	if not luz:
		for i in 3:                                      # ondas que se CIERRAN hacia los pies: el agua acude
			var u := fmod(t / 0.9 + i / 3.0, 1.0)
			_aro(en, Vector2.ZERO, lerpf(175.0, 35.0, u) * tam, 0.32, Color(AZUL_CLARO, 0.8 * sin(u * PI) * alfa * recoge))
		for j in 3:                                      # tres corrientes de agua en espiral hasta la mano
			var pts := PackedVector2Array()
			var cols := PackedColorArray()
			for k in 19:
				var u := k / 18.0
				var cp: Array = _corriente(j, u, mano, tam)
				pts.append((cp[0] as Vector2).lerp(mano, s))
				cols.append(Color(AZUL.lerp(AZUL_CLARO, u), pow(sin(u * PI), 0.8) * (0.3 if cp[1] else 0.85) * alfa * recoge))
			en.draw_polyline_colors(pts, cols, 7.0)
	var n := maxi(3, int(6 * q))                         # gotas que suben por cada corriente
	for j in 3:
		for i in n:
			var u := fmod(t * 0.62 + float(i) / n + j * 0.13, 1.0)
			var cp: Array = _corriente(j, u, mano, tam)
			var p: Vector2 = (cp[0] as Vector2).lerp(mano, s)
			var al := pow(sin(u * PI), 0.7) * alfa * recoge * (0.4 if cp[1] else 1.0)
			var tm := lerpf(18.0, 9.0, u)
			if luz:
				_gota(en, p + Vector2(-2.0, -3.0), tm * 0.45, Color(1, 1, 1, 0.6 * al * brillo))
			else:
				_gota(en, p, tm, Color(AZUL.lerp(AZUL_CLARO, u), 0.95 * al), 1.4)
	if ts >= 0.0:                                        # al soltar: salpicadura en la mano
		var k := clampf((t - ts) / 0.3, 0.0, 1.0)
		if luz:
			_gota(en, mano, lerpf(30.0, 90.0, k), Color(0.6, 0.85, 1.0, 0.7 * (1.0 - k) * brillo))
		else:
			_aro(en, mano, lerpf(12.0, 70.0, k), 0.8, Color(AZUL_CLARO, 0.9 * (1.0 - k)))
			for i in 8:
				var d := Vector2.RIGHT.rotated(TAU * i / 8.0 + 0.3)
				_gota(en, mano + d * lerpf(14.0, 80.0, k) + Vector2(0, 100.0 * k * k), 10.0, Color(AZUL_CLARO, 0.9 * (1.0 - k)), 1.5)


# ---------------------------------------------------------------- proyectil (orbe de agua)

func _dibujar_proyectil(luz: bool) -> void:
	var en: CanvasItem = aditivo if luz else self
	var v: Vector2 = datos["vel"]
	var dir := v.normalized() if v.length() > 1.0 else Vector2.LEFT
	var ang := dir.angle()
	var r := 30.0 * _suave(t / 0.08 + 0.3)
	if luz:
		_gota(en, Vector2(-0.35, -0.45) * r, r * 0.55, Color(1, 1, 1, 0.9 * brillo), 0.7)
		_gota(en, Vector2(0.3, 0.38) * r, r * 0.45, Color(0.55, 0.85, 1.0, 0.45 * brillo))
		return
	for i in 4:                                          # gotas que se quedan detrás (primero: van debajo)
		var d := -dir * (r * 1.25 + i * 15.0) + dir.orthogonal() * sin(t * 13.0 + i * 1.7) * 6.0
		_gota(self, d, 15.0 - i * 2.5, Color(AZUL_CLARO.lerp(AZUL, i / 4.0), 0.9 - i * 0.15))
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		var rr := r * (1.0 + 0.08 * sin(3.0 * a + t * 11.0) + 0.05 * sin(5.0 * a - t * 17.0))
		var p := Vector2(cos(a) * rr * 1.2, sin(a) * rr * 0.88)
		if cos(a) < 0.0:
			p.x *= 1.3                                   # cola: un poco más larga por detrás
		pts.append(p.rotated(ang + PI))
	draw_colored_polygon(pts, Color(AZUL, 0.72))
	var dentro := PackedVector2Array()                   # volumen: más claro arriba
	for p in pts:
		dentro.append(p * 0.62 + Vector2(-0.12, -0.22) * r)
	draw_colored_polygon(dentro, Color(AZUL_CLARO, 0.45))
	var borde := pts.duplicate()
	borde.append(pts[0])
	draw_polyline(borde, Color(AZUL_CLARO, 0.9), 3.0)


# ---------------------------------------------------------------- impacto

func _preparar_impacto() -> void:
	var pot: float = datos["pot"]
	var en_ola := pot > 1.0
	var suelo: Vector2 = datos["suelo"]
	var r: float = datos["r"]
	var gotas: Array = []
	var n := maxi(6, int((20 if en_ola else (22 if pot >= 1.0 else 14)) * q))
	for i in n:                                         # la salpicadura del golpe (desde el cuerpo del enemigo)
		var a := deg_to_rad(rng.randf_range(-165.0, -95.0) if en_ola else rng.randf_range(-165.0, -15.0))
		gotas.append(_nueva_gota(Vector2(rng.randf_range(-26, 26), rng.randf_range(-20, 20)),
			Vector2.RIGHT.rotated(a) * rng.randf_range(300.0, 620.0), rng.randf_range(0.0, 0.04), rng.randf_range(13.0, 22.0),
			suelo.y - position.y + rng.randf_range(-10.0, 22.0)))
	if datos["membrana"]:
		var nb := maxi(5, int((16 if pot >= 1.0 else 10) * q))
		for i in nb:                                    # al reventar la membrana (0,66 s), desde su borde
			var a := TAU * i / nb + rng.randf_range(-0.2, 0.2)
			var d := Vector2(cos(a), sin(a) * 1.15)
			gotas.append(_nueva_gota(d * r, d * rng.randf_range(160.0, 320.0) + Vector2(0, -110), 0.66 + rng.randf_range(0.0, 0.04),
				rng.randf_range(9.0, 15.0), suelo.y - position.y + rng.randf_range(-10.0, 22.0)))
	datos["gotas"] = gotas
	var nieblas: Array = []
	for i in (3 if q >= 0.99 else 2):
		nieblas.append([Vector2(rng.randf_range(-80, 80), rng.randf_range(-30, 60)), rng.randf_range(0.7, 1.0)])
	datos["nieblas"] = nieblas


# Una gota con su caída: cuándo toca el suelo (y dónde) para dibujar allí su salpicadura.
func _nueva_gota(p0: Vector2, v: Vector2, retraso: float, tam: float, suelo_y: float) -> Dictionary:
	var dy := suelo_y - p0.y
	var disc := v.y * v.y + 2.0 * GRAVEDAD * dy
	var tc := (-v.y + sqrt(maxf(disc, 0.0))) / GRAVEDAD
	return {"p0": p0, "v": v, "r": retraso, "tam": tam, "tc": tc, "x": p0.x + v.x * tc, "y": suelo_y}


func _dibujar_gotas(en: CanvasItem, luz: bool) -> void:
	for g in datos["gotas"]:
		var tl: float = t - float(g["r"])
		if tl < 0.0:
			continue
		var tc: float = g["tc"]
		if tl < tc:
			var v: Vector2 = g["v"]
			var p: Vector2 = g["p0"] + v * tl + Vector2(0, 0.5 * GRAVEDAD * tl * tl)
			var vy := absf(v.y + GRAVEDAD * tl)
			var alto := clampf(vy * 0.0025, 1.0, 2.2)
			var tm: float = g["tam"]
			if luz:
				_gota(en, p + Vector2(-tm * 0.15, -tm * 0.2), tm * 0.4, Color(1, 1, 1, 0.65 * brillo), alto)
			else:
				_gota(en, p, tm, Color(AZUL_CLARO.lerp(AZUL, 0.25), 0.95), alto)
		elif not luz and tl < tc + 0.3:                 # al tocar el suelo: salpica
			var k := (tl - tc) / 0.3
			var at := Vector2(g["x"], g["y"])
			_aro(en, at, lerpf(5.0, 28.0, k), 0.35, Color(ESPUMA, 0.85 * (1.0 - k)))
			_gota(en, at + Vector2(0, -16.0 * sin(k * PI)), 7.0 * (1.0 - k), Color(AZUL_CLARO, 0.85 * (1.0 - k)), 1.3)


func _dibujar_impacto(luz: bool) -> void:
	var en: CanvasItem = aditivo if luz else self
	var r: float = datos["r"]
	if luz:
		var k := clampf(t / 0.1, 0.0, 1.0)              # destello del golpe, pequeño y breve (no de pantalla)
		var a := (1.0 - clampf((t - 0.1) / 0.15, 0.0, 1.0)) * 0.42 * brillo
		_disco(en, Vector2.ZERO, lerpf(40.0, r * 1.1, k), lerpf(40.0, r * 1.0, k), Color(0.5, 0.8, 1.0, a))
		if t < 0.3:
			var k2 := t / 0.3
			_aro(en, Vector2.ZERO, lerpf(18.0, r * 1.15, 1.0 - pow(1.0 - k2, 3.0)), 0.78, Color(1, 1, 1, 0.3 * (1.0 - k2) * brillo))
	else:
		for nb in datos["nieblas"]:                     # bruma (sin brillo): da cuerpo y se disipa
			var k := clampf(t / 1.2, 0.0, 1.0)
			var a := sin(minf(t / 0.25, 1.0) * PI * 0.5) * (1.0 - k) * 0.2
			var tm: float = nb[1]
			var s := 128.0 * lerpf(tm, tm * 1.7, k)
			var p: Vector2 = nb[0] + Vector2(0, -40.0 * k)
			en.draw_texture_rect(c.glow_tex, Rect2(p.x - s, p.y - s, s * 2.0, s * 2.0), false, Color(0.85, 0.93, 1.0, a))
		if t < 0.32:                                     # aro de salpicadura que se abre desde el golpe
			var k := t / 0.32
			_aro(en, Vector2.ZERO, lerpf(22.0, r * 1.25, 1.0 - pow(1.0 - k, 3.0)), 0.78, Color(AZUL_CLARO, 0.95 * pow(1.0 - k, 1.3)))
	_dibujar_gotas(en, luz)
	if datos["membrana"]:
		_dibujar_membrana(en, luz, r)


# Agua que envuelve al enemigo: tiembla, brilla en el borde y revienta a los 0,66 s.
func _dibujar_membrana(en: CanvasItem, luz: bool, r: float) -> void:
	if t < 0.03 or t > 0.76:
		return
	var crece := _suave((t - 0.03) / 0.17)
	var rev := clampf((t - 0.62) / 0.12, 0.0, 1.0)
	var rr := r * (0.35 + 0.65 * crece + 0.3 * rev)
	var a := (1.0 - rev) * minf(crece * 1.5, 1.0)
	if luz:
		var arco := PackedVector2Array()                 # brillo curvo arriba a la izquierda
		for i in 10:
			var ang := deg_to_rad(lerpf(195.0, 255.0, i / 9.0))
			arco.append(Vector2(cos(ang) * rr * 0.8, sin(ang) * rr * 0.92))
		en.draw_polyline(arco, Color(1, 1, 1, 0.8 * a * brillo), 9.0)
		_gota(en, Vector2(-0.42, -0.66) * rr, rr * 0.16, Color(1, 1, 1, 0.85 * a * brillo))
		for i in 3:                                      # reflejos que se mueven por dentro (cáusticas)
			var ang := t * (1.6 + i * 0.5) + i * 2.1
			_gota(en, Vector2(cos(ang), sin(ang) * 1.15) * rr * 0.5, rr * 0.2, Color(0.55, 0.85, 1.0, 0.28 * a * brillo), 1.6)
		return
	var pts := PackedVector2Array()
	for i in 40:
		var ang := TAU * i / 40.0
		var w := 1.0 + 0.06 * sin(3.0 * ang + t * 9.0) + 0.04 * sin(5.0 * ang - t * 13.0)
		pts.append(Vector2(cos(ang) * rr * w, sin(ang) * rr * w * 1.15))
	draw_colored_polygon(pts, Color(AZUL, 0.22 * a))
	var borde := pts.duplicate()
	borde.append(pts[0])
	var dentro := PackedVector2Array()
	for p in borde:
		dentro.append(p * 0.9)
	draw_polyline(dentro, Color(AZUL, 0.3 * a), 12.0)
	draw_polyline(borde, Color(AZUL_CLARO, 0.8 * a), 6.0)


# ---------------------------------------------------------------- charco y aro de espuma (en el suelo)

func _preparar_charco() -> void:
	var esp: Array = []
	var n := maxi(10, int(28 * q))
	for i in n:
		esp.append([TAU * i / n + rng.randf_range(-0.1, 0.1), rng.randf_range(0.86, 1.1), rng.randf_range(12.0, 22.0)])
	datos["espuma"] = esp


func _dibujar_charco(luz: bool) -> void:
	var en: CanvasItem = aditivo if luz else self
	var r: float = datos["r"]
	if datos["charco"]:
		var abre := _suave(t / 0.3)
		var seca := clampf((t - 1.0) / 0.95, 0.0, 1.0)
		var rx := r * lerpf(0.35, 1.05, abre) * lerpf(1.0, 0.82, seca)
		var a := abre * (1.0 - seca)
		if luz:
			_disco(en, Vector2(-rx * 0.25, -rx * 0.05), rx * 0.45, rx * 0.06, Color(0.6, 0.88, 1.0, 0.3 * a * brillo))
		else:
			_disco(en, Vector2.ZERO, rx * 1.1, rx * 0.31, Color(AZUL_HONDO, 0.45 * a))
			_aro(en, Vector2.ZERO, rx, 0.28, Color(AZUL_CLARO, 0.55 * a))
	if not luz and t < 0.8:                              # aro de espuma que se abre
		var k := t / 0.8
		var ra := lerpf(40.0, r * 1.45, 1.0 - pow(1.0 - k, 2.5))
		for e in datos["espuma"]:
			var ang: float = e[0]
			var p := Vector2(cos(ang) * ra * e[1], sin(ang) * ra * e[1] * 0.3)
			_gota(en, p, e[2] * (1.0 - k * 0.5), Color(ESPUMA, 0.9 * (1.0 - k)), 0.6)


# ---------------------------------------------------------------- Maremoto: la ola

# Perfil de la ola (origen: el suelo bajo la cresta; avanza hacia la izquierda). Cuerpo: de la base trasera a la cresta,
# el rizo que vuelca hacia delante y la cara que cae hasta la rompiente.
const PERFIL := [Vector2(520, 12), Vector2(430, -18), Vector2(340, -66), Vector2(255, -122), Vector2(175, -176),
	Vector2(105, -220), Vector2(45, -250), Vector2(-10, -264), Vector2(-56, -258), Vector2(-92, -238), Vector2(-112, -212),
	Vector2(-100, -196), Vector2(-76, -200), Vector2(-56, -180), Vector2(-46, -140), Vector2(-50, -96), Vector2(-66, -56),
	Vector2(-92, -20), Vector2(-128, 12), Vector2(-60, 22), Vector2(40, 8), Vector2(140, 24), Vector2(240, 10),
	Vector2(340, 22), Vector2(430, 8)]
const CRESTA := [4, 5, 6, 7, 8, 9, 10]                # índices del perfil con espuma


func _punto_ola(i: int) -> Vector2:
	var p: Vector2 = PERFIL[i]
	var alto := clampf(-p.y / 260.0, 0.0, 1.0)
	p.y += sin(p.x * 0.021 + t * 6.0) * 7.0 * alto
	if i > 18:                                           # el pie de la ola, irregular y vivo
		p.y += sin(p.x * 0.05 - t * 9.0) * 6.0
	if i >= 8 and i <= 12:                               # el rizo cabecea
		p += Vector2(sin(t * 8.0) * 6.0, cos(t * 8.0) * 3.0)
	p.y *= _suave(t / 0.25)                              # la ola se levanta al empezar
	return p


func _dibujar_ola(luz: bool) -> void:
	var en: CanvasItem = aditivo if luz else self
	if t < 0.04:                                         # aún plana (el polígono no se podría triangular)
		return
	if luz:
		for f in [0.42, 0.68]:                           # brillos que recorren la cara de la ola
			var linea := PackedVector2Array()
			for i in range(1, 8):
				var p := _punto_ola(i)
				linea.append(Vector2(p.x, p.y * f + sin(t * 5.0 + i) * 4.0))
			en.draw_polyline(linea, Color(0.6, 0.88, 1.0, 0.25 * brillo), 5.0)
		for i in maxi(5, int(12 * q)):                   # rocío que salta de la cresta
			var u := fmod(t * 1.3 + i / 12.0 * 1.7, 1.0)
			var base := _punto_ola(int(CRESTA[i % CRESTA.size()]))
			_gota(en, base + Vector2(-u * 140.0, -u * 80.0 + u * u * 150.0), 9.0, Color(1, 1, 1, 0.55 * (1.0 - u) * brillo))
		return
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	for i in PERFIL.size():
		var p := _punto_ola(i)
		pts.append(p)
		var h := clampf(-p.y / 265.0, 0.0, 1.0)
		cols.append(Color(AZUL_HONDO.lerp(AZUL, minf(0.35 + h * 1.4, 1.0)).lerp(AZUL_CLARO, maxf(h - 0.6, 0.0) * 2.0), lerpf(0.5, 0.62, h)))
	draw_polygon(pts, cols)
	var cara := PackedVector2Array()                     # cara iluminada bajo la cresta (volumen)
	for i in range(4, 11):
		var p := _punto_ola(i)
		cara.append(Vector2(p.x, p.y * 0.93))
	for i in range(10, 3, -1):
		var p := _punto_ola(i)
		cara.append(Vector2(p.x + 26.0, p.y * 0.62))
	draw_colored_polygon(cara, Color(AZUL_CLARO, 0.22))
	var cresta := PackedVector2Array()
	for i in CRESTA:
		cresta.append(_punto_ola(int(i)) + Vector2(0, 3))
	draw_polyline(cresta, Color(ESPUMA, 0.92), 12.0)
	var nc := maxi(8, int(18 * q))                       # espuma de la cresta
	for i in nc:
		var k := float(i) / maxf(1.0, nc - 1)
		var a: int = CRESTA[int(k * (CRESTA.size() - 1.001))]
		var b: int = CRESTA[mini(int(k * (CRESTA.size() - 1.001)) + 1, CRESTA.size() - 1)]
		var f := fmod(k * (CRESTA.size() - 1), 1.0)
		var p := _punto_ola(a).lerp(_punto_ola(b), f) + Vector2(sin(t * 9.0 + i * 2.3) * 4.0, -4.0 + cos(t * 7.0 + i) * 4.0)
		_gota(self, p, 16.0 + 10.0 * _ruido(i, 3), Color(ESPUMA, 0.92))
	var labio := _punto_ola(10)                          # cortina que cae del rizo
	for i in maxi(6, int(14 * q)):
		var u := fmod(t * 1.7 + i / 14.0, 1.0)
		_gota(self, labio + Vector2(-u * 34.0 + (_ruido(i, 5) - 0.5) * 30.0, u * u * 210.0), 12.0, Color(AZUL_CLARO, 0.9 * (1.0 - u)), 1.8)
	for i in maxi(12, int(34 * q)):                      # rompiente y espuma a lo largo de la base
		var x := -140.0 + _ruido(i, 7) * 600.0 * (0.35 if i % 2 == 0 else 1.0)
		var y := (_ruido(i, 9) - 0.5) * 22.0 + 14.0
		var lat := sin(t * 10.0 + i * 1.9)
		var cerca := 1.0 - clampf((x + 140.0) / 560.0, 0.0, 1.0)
		_gota(self, Vector2(x + lat * 6.0, y - absf(lat) * 10.0 * cerca), (14.0 + 12.0 * _ruido(i, 11)) * (0.6 + cerca * 0.6),
			Color(ESPUMA, 0.55 + 0.35 * cerca), 0.7)


# Rastro de espuma en el suelo por donde pasa la ola: muestras fijas cada «paso» px que se secan con el tiempo.
func _proceso_estela() -> void:
	var o = datos["ola"]
	if is_instance_valid(o) and not o.is_queued_for_deletion() and o.modulate.a > 0.3:
		var x: float = o.position.x - 60.0
		var ultima: float = datos["ultima_x"]
		var paso: float = datos["paso"]
		if ultima == INF:
			datos["ultima_x"] = x
		else:
			while ultima - x >= paso:
				ultima -= paso
				(datos["muestras"] as Array).append([ultima, t, (datos["muestras"] as Array).size()])
			datos["ultima_x"] = ultima
	else:
		var muestras: Array = datos["muestras"]
		if muestras.is_empty() or t - float(muestras[muestras.size() - 1][1]) > 1.5:
			vida = minf(vida, t)


func _dibujar_estela() -> void:
	for m in datos["muestras"]:
		var edad: float = t - float(m[1])
		if edad > 1.5:
			continue
		var i: int = m[2]
		var x: float = m[0]
		var a := 1.0 - edad / 1.5
		_disco(self, Vector2(x, (_ruido(i, 1) - 0.5) * 30.0), 46.0, 18.0, Color(AZUL_HONDO, 0.28 * a))
		for j in 2:
			var p := Vector2(x + (_ruido(i, 2 + j) - 0.5) * 30.0, (_ruido(i, 4 + j) - 0.5) * 28.0)
			_gota(self, p, (14.0 + 12.0 * _ruido(i, 6 + j)) * (1.0 + edad * 0.5), Color(ESPUMA, 0.8 * a * a), 0.55)
