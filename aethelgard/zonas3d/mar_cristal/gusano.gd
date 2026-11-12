extends RefCounted
# Bramavidrio, el gusano colosal del Mar de Cristal (V12; nombre aprobado por el usuario el 11/11; DISENO_V12.md §4 y
# NARRATIVA_DESIERTO.md §4). Original de REBELUM: corto y grueso, como una larva enorme con placas de vidrio fundido en el
# lomo; boca de placas planas que muelen (nunca un anillo de dientes). Pasta el vidrio bajo la arena blanda; es
# territorial, no cazador: no se monta, no lo atrae un ritmo y no guarda nada.
#
# En la arena que tiembla (trazado.gd, TEMBLOR), nunca en roca, en el camino ni durante un diálogo o una tormenta:
#   1. calma: Kael pisa la arena blanda; a los ESPERA segundos, el aviso;
#   2. aviso: la arena tiembla (sonido gusano_temblor, la cámara vibra), el aviso de texto y un SURCO que nace lejos y
#      avanza hacia Kael con su polvo; a mitad de camino, el rugido sordo (gusano_rugido);
#   3. si Kael sale de la arena blanda (o pisa el camino) antes de que llegue, el surco se hunde y se aleja (DESCANSO);
#   4. si llega: la APARICIÓN (la arena estalla, el gusano sale con sus placas brillando, rugido y sacudida) y, la
#      primera vez, el encuentro especial (combate fijo «mc_bramavidrio»). Después de vencerlo, respeta a Kael: el surco
#      pasa por debajo, asoma, ruge y se va, sin combate.
# Todo es barato: un puñado de mallas y dos emisores de partículas, solo mientras hay algo que ver.
#
# V12 (11/11, animaciones): el modelo DEFINITIVO (enemigos/bramavidrio/bramavidrio_3d.gd, de fuente/crear_bramavidrio.py,
# en la versión de la calidad en uso) sustituye al provisional cuando existe. Durante el aviso va bajo el surco (clip
# «subterraneo»: solo asoma la hilera de aletas de vidrio) tras una vibración («aviso»); en la aparición sale de un
# agujero a DIST_APARICION de Kael, al este-noreste (de tres cuartos para la cámara; nunca lo tapa), mirándolo;
# revienta la arena («emerger»), ruge («rugido»), y la cámara se aleja y baja despacio para que se vea entero junto a
# Kael (PRESENTACION), y vuelve a su sitio antes del combate. El provisional (_modelo_provisional) sigue aquí: se usa
# si falta el modelo o con Engine.set_meta("bramavidrio_provisional", true).

const T := preload("res://zonas3d/mar_cristal/trazado.gd")
const COMBATE := "mc_bramavidrio"          # combate fijo (progreso.gd ganado): la primera vez
const GRUPO_COMBATE := 13                  # combate.gd GRUPOS: Bramavidrio solo
const ESPERA := 3.0                        # s en la arena blanda antes del aviso
const VELOCIDAD := 5.0                     # m/s del surco (Kael anda a unos 3 y corre a unos 5,5: se puede huir)
const DISTANCIA_SALIDA := 22.0             # m: dónde nace el surco
const DESCANSO := 25.0                     # s sin avisos tras irse
const ALCANCE := 1.6                       # m: el surco «llega»
const TEXTO_AVISO := "La arena tiembla bajo tus pies. Algo enorme se mueve debajo. ¡Sal de la arena blanda!"
const TEXTO_SE_VA := "El surco se hunde y se aleja. Bramavidrio vuelve a lo suyo."
const TEXTO_RESPETA := "Bramavidrio asoma, te mira con sus placas de vidrio… y se hunde. Te recuerda."

var region: Node3D
var activo := true                         # las pruebas lo apagan o lo fuerzan
var estado := "calma"                      # calma, aviso, aparicion, descanso
var t_estado := 0.0
var t_arena := 0.0
var surco_pos := Vector3.ZERO
var apariciones := 0
var _rugio := false
var _raiz: Node3D
var _lomo: MeshInstance3D                  # el bulto de arena que avanza
var _polvo: CPUParticles3D
var _cuerpo: Node3D                        # el gusano al asomar
var _estallido: CPUParticles3D
var _sacudida := 0.0
var _gusano3d: Node3D                      # el modelo definitivo (bramavidrio_3d.gd), si se usa
var _sitio := Vector3.ZERO                 # el agujero por donde sale
var _camara := 0.0                         # cuánto manda la presentación sobre la cámara (0…1)
var _cam_meta := 0.0
const DIST_APARICION := 11.0               # m del agujero a Kael: en reposo, la cabeza queda sobre él (9 m por delante)
const PRESENTACION := [20.0, 34.0, 5.5]    # [inclinación, distancia, altura de la mirada] de la cámara al aparecer
const GUION_3D := "res://enemigos/bramavidrio/bramavidrio_3d.gd"
const MODELO_3D := "res://enemigos/bramavidrio/bramavidrio.glb"


func _init(r: Node3D) -> void:
	region = r
	if r != null and r.has_signal("ready"):
		r.ready.connect(_precalentar, CONNECT_ONE_SHOT)


# V12 (12/11, cargas; pruebas/herramientas/medir_cargas.gd): Bramavidrio se prepara AL ENTRAR en la región, con la pantalla
# todavía tapada por Recursos.cambiar_escena, y no en el aviso. Antes sus piezas (el modelo, el surco y el polvo) se creaban
# en el aviso y sus sombreadores se compilaban al dibujarse por primera vez, en mitad del aviso y de la aparición: en el
# Redmi, segundos de imagen congelada antes del combate (v615: 35 y 61 fotogramas en ventanas de 5 s, «~18 s de negro»).
# Aquí se crean y se dibujan dos fotogramas delante de la cámara, bajo el negro, y se esconden; siguen vivos toda la visita,
# así que lo compilado sirve para cada aviso. Sin pantalla tapada (las pruebas que abren la región a mano), nada.
# Su versión de COMBATE no se prepara aquí: sus sombreadores se crean con cada modelo (Shader.new con RECORTE en
# bramavidrio*_3d.gd) y se liberan con él, así que lo compilado aquí solo serviría con la caché de sombreadores de Godot
# (user://shader_cache) y, sin ella, se pagaría en cada entrada a la región. Lo paga el combate, bajo su aviso de carga.
func _precalentar() -> void:
	var R = region.get_node_or_null("/root/Recursos")
	if not activo or R == null or not R.cambiando or region.kael == null or region.cam == null:
		return
	_construir()
	var k: Vector3 = region.kael.global_position
	var delante := k - _atras_camara() * 4.0
	delante.y = T.altura(delante.x, delante.z)
	_lomo.global_position = delante
	_lomo.visible = true
	_polvo.global_position = delante
	_polvo.emitting = true
	_estallido.global_position = delante
	_estallido.emitting = true
	if _gusano3d != null:
		_gusano3d.global_position = delante
		_mostrar_3d(true)
	else:
		_cuerpo.global_position = delante
		_cuerpo.visible = true
	for i in 2:
		await region.get_tree().process_frame
		if not is_instance_valid(region) or not region.is_inside_tree():
			return
	if estado != "calma":
		return                                                  # ya avisa (no debería, tan pronto): no se toca
	_lomo.visible = false
	_polvo.emitting = false
	_estallido.emitting = false
	if _gusano3d != null:
		_mostrar_3d(false)
	else:
		_cuerpo.visible = false


# Bramavidrio solo se mueve bajo la arena blanda de su zona, lejos del camino.
static func arena_blanda(p: Vector3) -> bool:
	return T.en_temblor(p.x, p.z) and not T.en_camino(p.x, p.z)


static func vencido() -> bool:
	return load("res://progreso.gd").ganado(COMBATE)


func actualizar(delta: float, pos: Vector3) -> void:
	t_estado += delta
	_presentar(delta)
	_sacudir(delta)
	var calla: bool = not activo or region.ocupado() or (region.clima != null and region.clima.en_tormenta())
	match estado:
		"calma":
			if calla or not arena_blanda(pos):
				t_arena = 0.0
				return
			t_arena += delta
			if t_arena >= ESPERA:
				_empezar_aviso(pos)
		"aviso":
			if calla and region.ocupado():
				return                                            # un diálogo: se queda quieto hasta que acabe
			_avanzar_surco(delta, pos)
		"aparicion":
			_animar_aparicion(delta)
		"descanso":
			if t_estado >= DESCANSO:
				_cambiar("calma")


func _cambiar(e: String) -> void:
	estado = e
	t_estado = 0.0
	t_arena = 0.0


# ================================================================= el aviso y el surco

func _empezar_aviso(pos: Vector3) -> void:
	_cambiar("aviso")
	_rugio = false
	# V12 (12/11, cargas): con el aviso empieza a pedirse en segundo plano lo del combate que aún no esté en memoria (la
	# escena y el modelo de combate de la versión en uso); la arena tiembla unos segundos antes de que emerja.
	var R = region.get_node_or_null("/root/Recursos")
	if R != null and not vencido():
		var V = load("res://enemigos/bramavidrio/bramavidrio_version.gd")
		var rutas: Dictionary = load(V.guion()).get_script_constant_map().get("RUTAS", {})
		var perfil: String = str(load("res://prototipos/calidad_proto.gd").actual()) \
			if ResourceLoader.exists("res://prototipos/calidad_proto.gd") else "alto"
		R.precargar(["res://combate.tscn", str(rutas.get(perfil, V.modelo()))])
	# nace lejos, dentro de la zona, del lado contrario al camino (al este de Kael, o al norte si no cabe)
	var dir := Vector3(1.0, 0.0, -0.35).normalized()
	var origen := pos + dir * DISTANCIA_SALIDA
	if not T.en_temblor(origen.x, origen.z):
		origen = Vector3(clampf(origen.x, T.TEMBLOR.position.x + 1.0, T.TEMBLOR.end.x - 1.0), 0.0,
			clampf(origen.z, T.TEMBLOR.position.y + 1.0, T.TEMBLOR.end.y - 1.0))
		if Vector2(origen.x - pos.x, origen.z - pos.z).length() < 10.0:
			origen = pos + Vector3(-dir.x, 0.0, dir.z) * 14.0
	surco_pos = Vector3(origen.x, T.altura(origen.x, origen.z), origen.z)
	_construir()
	if _gusano3d != null:                                       # bajo el surco: vibra y avanza (solo asoman las aletas)
		_mostrar_3d(true)
		_colocar_bajo_surco(pos)
		_gusano3d.vibrar()
	_lomo.visible = true
	_polvo.emitting = true
	_sacudida = 0.6
	region._mostrar_aviso(TEXTO_AVISO, 2.8)
	_sonar("gusano_temblor", surco_pos)


func _avanzar_surco(delta: float, pos: Vector3) -> void:
	if not arena_blanda(pos):
		_irse(TEXTO_SE_VA)
		return
	var falta := Vector3(pos.x - surco_pos.x, 0.0, pos.z - surco_pos.z)
	var d := falta.length()
	if d <= ALCANCE:
		_aparecer(pos)
		return
	surco_pos += falta / d * minf(VELOCIDAD * delta, d)
	surco_pos.y = T.altura(surco_pos.x, surco_pos.z)
	_lomo.global_position = surco_pos + Vector3(0, 0.15 + 0.12 * sin(t_estado * 9.0), 0)
	_lomo.look_at(surco_pos + falta / d * 3.0 + Vector3(0, 0.15, 0), Vector3.UP)
	_polvo.global_position = surco_pos
	if _gusano3d != null:
		_colocar_bajo_surco(pos)
	_sacudida = maxf(_sacudida, clampf(1.0 - d / DISTANCIA_SALIDA, 0.15, 0.7))
	if not _rugio and d < DISTANCIA_SALIDA * 0.55:
		_rugio = true
		_sonar("gusano_rugido", surco_pos)


func _irse(texto: String) -> void:
	region._mostrar_aviso(texto, 2.2)
	if _lomo != null:
		var t := _lomo.create_tween()
		t.tween_property(_lomo, "position:y", _lomo.position.y - 1.2, 0.8)
		t.tween_callback(func(): _lomo.visible = false)
	if _polvo != null:
		_polvo.emitting = false
	if _gusano3d != null and _gusano3d.visible:                  # se hunde y se aleja
		var g := _gusano3d
		var t2 := g.create_tween()
		t2.tween_property(g, "global_position:y", g.global_position.y - 4.0, 1.2).set_trans(Tween.TRANS_SINE)
		t2.tween_callback(func(): _mostrar_3d(false))
	_cambiar("descanso")


# ================================================================= la aparición

func _aparecer(pos: Vector3) -> void:
	_cambiar("aparicion")
	apariciones += 1
	region._parar_kael()
	_lomo.visible = false
	_polvo.emitting = false
	if _gusano3d != null:
		_aparecer_3d(pos)
		return
	var sitio := pos + Vector3(2.6, 0.0, -2.6)                  # al lado de Kael, entre él y la cámara no
	sitio.y = T.altura(sitio.x, sitio.z)
	_estallido.global_position = sitio
	_estallido.restart()
	_estallido.emitting = true
	_cuerpo.global_position = sitio + Vector3(0, -9.0, 0)
	_cuerpo.visible = true
	_cuerpo.look_at(Vector3(pos.x, _cuerpo.global_position.y, pos.z), Vector3.UP)
	_sacudida = 1.4
	_sonar("gusano_rugido", sitio)
	var t := _cuerpo.create_tween()
	t.tween_property(_cuerpo, "global_position:y", sitio.y - 0.4, 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(1.1)
	if vencido():
		t.tween_callback(func(): region._mostrar_aviso(TEXTO_RESPETA, 2.6))
		t.tween_property(_cuerpo, "global_position:y", sitio.y - 8.0, 1.2).set_trans(Tween.TRANS_SINE)
		t.tween_callback(func():
			_cuerpo.visible = false
			_cambiar("descanso"))
	else:
		t.tween_callback(func(): region.encuentro(COMBATE, GRUPO_COMBATE, "jefe", "¡Bramavidrio te cierra el paso! No hay huida."))


func _animar_aparicion(_delta: float) -> void:
	if _gusano3d != null:
		region._parar_kael()                                    # mientras se presenta, Kael no se mueve
		return
	if _cuerpo == null or not _cuerpo.visible:
		return
	for i in _cuerpo.get_child_count():                          # el cuerpo ondula: cada anillo a su ritmo
		var n := _cuerpo.get_child(i)
		if n is Node3D and n.has_meta("anillo"):
			var k: int = n.get_meta("anillo")
			n.position.x = sin(t_estado * 3.0 + k * 0.7) * 0.06 * k


# ================================================================= piezas (se crean la primera vez que hacen falta)

func _construir() -> void:
	if _raiz != null:
		return
	_raiz = Node3D.new()
	_raiz.name = "Bramavidrio"
	region.add_child(_raiz)
	var arena := StandardMaterial3D.new()
	arena.albedo_color = Color(0.86, 0.66, 0.44)
	arena.roughness = 1.0
	_lomo = MeshInstance3D.new()                                # el bulto alargado de arena removida
	var s := SphereMesh.new()
	s.radius = 1.0
	s.height = 1.0
	s.radial_segments = 16
	s.rings = 8
	_lomo.mesh = s
	_lomo.scale = Vector3(1.5, 0.55, 3.2)
	_lomo.material_override = arena
	_lomo.visible = false
	_raiz.add_child(_lomo)
	_polvo = _particulas(36, 1.1, Vector3(1.2, 0.2, 1.2), 2.5, 0.22)
	_estallido = _particulas(90, 1.6, Vector3(2.5, 0.3, 2.5), 9.0, 0.4)
	_estallido.one_shot = true
	_estallido.explosiveness = 0.85
	_cuerpo = _modelo_gusano(true)
	_cuerpo.visible = false
	_raiz.add_child(_cuerpo)
	if _cuerpo.has_method("emerger"):
		_gusano3d = _cuerpo
		_mostrar_3d(false)


func _particulas(n: int, vida: float, caja: Vector3, vel: float, tam: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = n
	p.lifetime = vida
	p.emitting = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = caja
	p.direction = Vector3(0, 1, 0)
	p.spread = 40.0
	p.initial_velocity_min = vel * 0.5
	p.initial_velocity_max = vel
	p.gravity = Vector3(0, -6.0, 0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.6
	var q := QuadMesh.new()
	q.size = Vector2(tam, tam)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.92, 0.76, 0.52, 0.8)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	q.material = m
	p.mesh = q
	_raiz.add_child(p)
	return p


# El gusano provisional (hasta que gráficos haga su modelo, modelos/desierto/bramavidrio.glb; si existe, se usa el suyo).
# Corto y grueso, como una larva enorme: segmentos abultados que se estrechan hacia la boca y se curvan hacia delante;
# lomo pardo oscuro y vientre claro; dos hileras de placas de vidrio fundido (hexágonos que brillan); la boca, cinco
# placas planas abiertas alrededor de una garganta con luz (muelen; nunca un anillo de dientes). Unas 40 mallas
# sencillas, solo mientras asoma.
const SEGMENTOS := 8
const ALTO_SEGMENTO := 0.95


# El cuerpo del gusano: el modelo definitivo si está (en_region: preparado para la exploración, bajo la arena y a escala
# real; si no, en reposo y a la escala del combate), un GLB en modelos/desierto (si gráficos lo deja ahí) o el
# provisional.
func _modelo_gusano(en_region := false) -> Node3D:
	var V = load("res://enemigos/bramavidrio/bramavidrio_version.gd")   # V12: la versión 1 o 2 (un solo interruptor)
	if not Engine.get_meta("bramavidrio_provisional", false) and ResourceLoader.exists(V.guion()) \
			and ResourceLoader.exists(V.modelo()):
		var g: Node3D = load(V.guion()).new()
		g.name = "Bramavidrio3D"
		if en_region:
			g.en_exploracion = true
			g.recortar_suelo = false
		return g
	var n := Node3D.new()
	var ruta := "res://modelos/desierto/bramavidrio.glb"
	if ResourceLoader.exists(ruta):
		n.add_child((load(ruta) as PackedScene).instantiate())
		return n
	return _modelo_provisional()


func _modelo_provisional() -> Node3D:
	var n := Node3D.new()
	var lomo := _mat(Color(0.42, 0.29, 0.21), 0.8)
	var vientre := _mat(Color(0.74, 0.58, 0.42), 0.9)
	var hueso := _mat(Color(0.86, 0.80, 0.68), 0.6)
	var vidrio := StandardMaterial3D.new()
	vidrio.albedo_color = Color(0.55, 0.90, 0.95, 0.88)
	vidrio.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vidrio.roughness = 0.08
	vidrio.metallic_specular = 1.0
	vidrio.rim_enabled = true
	vidrio.rim = 0.6
	vidrio.emission_enabled = true
	vidrio.emission = Color(0.30, 0.82, 0.95)
	vidrio.emission_energy_multiplier = 1.1
	var garganta := _mat(Color(1.0, 0.72, 0.36), 0.5)
	garganta.emission_enabled = true
	garganta.emission = Color(1.0, 0.55, 0.22)
	garganta.emission_energy_multiplier = 0.9
	var y := 0.0
	var arriba := Vector3.ZERO
	for k in SEGMENTOS:                                         # de la arena (k = 0) a la boca
		var t := float(k) / (SEGMENTOS - 1)
		var r := lerpf(1.55, 1.05, t)                           # más grueso abajo
		var seg := Node3D.new()
		seg.set_meta("anillo", SEGMENTOS - 1 - k)               # el que más ondula es el de arriba
		seg.position = Vector3(0, y, t * t * 2.2)               # se curva hacia delante (+z: hacia quien mira)
		seg.rotation.x = t * 0.55
		n.add_child(seg)
		var bulto := MeshInstance3D.new()                       # el segmento: una esfera achatada, el lomo
		var s := SphereMesh.new()
		s.radius = r
		s.height = ALTO_SEGMENTO * 1.7
		s.radial_segments = 18
		s.rings = 9
		bulto.mesh = s
		bulto.material_override = lomo
		seg.add_child(bulto)
		var panza := MeshInstance3D.new()                       # el vientre claro, por delante
		var sp := SphereMesh.new()
		sp.radius = r * 0.8
		sp.height = ALTO_SEGMENTO * 1.45
		sp.radial_segments = 14
		sp.rings = 7
		panza.mesh = sp
		panza.material_override = vientre
		panza.position = Vector3(0, 0, r * 0.32)
		seg.add_child(panza)
		if k >= 1:                                              # placas de vidrio: dos hileras en el lomo (detrás)
			for lado in [-1.0, 1.0]:
				var placa := MeshInstance3D.new()
				var c := CylinderMesh.new()
				c.top_radius = 0.34 + 0.06 * (1.0 - t)
				c.bottom_radius = c.top_radius
				c.height = 0.16
				c.radial_segments = 6
				placa.mesh = c
				placa.material_override = vidrio
				var a: float = lado * 0.75
				placa.position = Vector3(sin(a) * r * 0.95, 0.15, -cos(a) * r * 0.95)
				placa.rotation = Vector3(-PI / 2.0 + 0.35, -a, 0)
				seg.add_child(placa)
		y += ALTO_SEGMENTO
		arriba = seg.position
	var boca := Node3D.new()                                    # la boca: cinco placas planas abiertas y la garganta
	boca.position = arriba + Vector3(0, ALTO_SEGMENTO * 0.7, 0.35)
	boca.rotation.x = 0.75
	boca.set_meta("anillo", 0)
	n.add_child(boca)
	var luz_g := MeshInstance3D.new()
	var d := CylinderMesh.new()
	d.top_radius = 0.6
	d.bottom_radius = 0.75
	d.height = 0.25
	d.radial_segments = 16
	luz_g.mesh = d
	luz_g.material_override = garganta
	boca.add_child(luz_g)
	for i in 5:
		var labio := MeshInstance3D.new()
		var b := PrismMesh.new()
		b.size = Vector3(1.05, 0.55, 0.2)                      # placas anchas y bajas: muelen (13:30: altas parecían una corona)
		labio.mesh = b
		labio.material_override = hueso
		var ang := TAU * i / 5.0
		labio.position = Vector3(sin(ang) * 0.82, 0.35, cos(ang) * 0.82)
		labio.rotation = Vector3(0, ang, 0)
		labio.rotate_object_local(Vector3.RIGHT, 1.05)          # abiertas hacia fuera, casi tumbadas
		boca.add_child(labio)
	var luz := OmniLight3D.new()                                # el brillo de las placas y la garganta
	luz.light_color = Color(0.5, 0.9, 1.0)
	luz.light_energy = 1.0
	luz.omni_range = 7.0
	luz.position = arriba + Vector3(0, 0.5, -1.6)
	n.add_child(luz)
	return n


func _mat(c: Color, rugosidad: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rugosidad
	return m


# ================================================================= el modelo definitivo (bramavidrio_3d.gd)

func _mostrar_3d(si: bool) -> void:
	if _gusano3d == null:
		return
	_gusano3d.visible = si
	_gusano3d.process_mode = Node.PROCESS_MODE_INHERIT if si else Node.PROCESS_MODE_DISABLED


# Bajo el surco: la cabeza en el surco, mirando a Kael (el cuerpo queda detrás, enterrado).
func _colocar_bajo_surco(pos: Vector3) -> void:
	var g := _gusano3d
	g.global_position = surco_pos
	var d := Vector3(pos.x - surco_pos.x, 0.0, pos.z - surco_pos.z)
	if d.length() > 0.1:
		g.rotation = Vector3(0.0, atan2(d.x, d.z), 0.0)


# Hacia dónde queda la cámara desde Kael, en el suelo (la cámara del juego no gira: el sur).
func _atras_camara() -> Vector3:
	if region.cam == null or region.kael == null:
		return Vector3.BACK
	var a: Vector3 = region.cam.global_position - region.kael.global_position
	a.y = 0.0
	return a.normalized() if a.length() > 0.1 else Vector3.BACK


func _vivo() -> bool:
	return is_instance_valid(region) and region.is_inside_tree() and is_instance_valid(_gusano3d)


# La aparición: sale de un agujero al este-noreste de Kael (de tres cuartos para la cámara: se ve su silueta en S y no
# tapa a Kael), mirándolo; revienta la
# arena, se alza, baja la cabeza sobre él y ruge. La cámara se aleja y baja para que se vea entero, con Kael pequeño a sus
# pies, y vuelve antes del combate (o mientras se hunde, si ya fue vencido).
func _aparecer_3d(pos: Vector3) -> void:
	var lejos := (-_atras_camara()).rotated(Vector3.UP, deg_to_rad(-65.0))   # al este-noreste: de tres cuartos para la cámara
	_sitio = pos + lejos * DIST_APARICION
	_sitio.y = T.altura(_sitio.x, _sitio.z)
	var g := _gusano3d
	g.global_position = _sitio
	var d := pos - _sitio
	g.rotation = Vector3(0.0, atan2(d.x, d.z), 0.0)
	_mostrar_3d(true)
	_cam_meta = 1.0
	_estallido.global_position = _sitio
	_polvo.global_position = _sitio
	_sonar("gusano_temblor", _sitio)
	_sacudida = maxf(_sacudida, 0.6)
	g.rompe_arena.connect(func():
		_estallido.restart()
		_estallido.emitting = true
		_polvo.emitting = true
		_sacudida = 1.4
		_sonar("gusano_rugido", _sitio), CONNECT_ONE_SHOT)
	await g.emerger()
	if not _vivo():
		return
	_polvo.emitting = false
	g.rugido_pico.connect(func():
		_sacudida = maxf(_sacudida, 0.8)
		_sonar("gusano_rugido", _sitio), CONNECT_ONE_SHOT)
	await g.rugir()
	if not _vivo():
		return
	_cam_meta = 0.0
	if vencido():
		region._mostrar_aviso(TEXTO_RESPETA, 2.6)
		var t := g.create_tween()
		t.tween_property(g, "global_position:y", _sitio.y - 15.0, 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		t.tween_callback(func():
			_mostrar_3d(false)
			_cambiar("descanso"))
		return
	await region.get_tree().create_timer(0.9).timeout            # la cámara vuelve a Kael antes del combate
	if not _vivo():
		return
	region.encuentro(COMBATE, GRUPO_COMBATE, "jefe", "¡Bramavidrio te cierra el paso! No hay huida.")


# La cámara de la presentación: sobre la que coloca la región en cada fotograma, se aleja y baja hacia un punto entre
# Kael y el agujero, con una mezcla suave (sin giros bruscos: no marea). Vuelve sola cuando _cam_meta pasa a 0.
func _presentar(delta: float) -> void:
	_camara = move_toward(_camara, _cam_meta, delta / 0.9)
	if _camara <= 0.0 or region.cam == null or region.kael == null:
		return
	var w := _camara * _camara * (3.0 - 2.0 * _camara)
	var k: Vector3 = region.kael.global_position
	var mira := k.lerp(_sitio, 0.5) + Vector3(0.0, PRESENTACION[2], 0.0)
	var ang := deg_to_rad(PRESENTACION[0])
	var ojo := mira + _atras_camara() * cos(ang) * PRESENTACION[1] + Vector3.UP * sin(ang) * PRESENTACION[1]
	var f = region.get("foco")
	var foco0: Vector3 = (f + Vector3(0, 0.9, 0)) if f is Vector3 else k + Vector3(0, 0.9, 0)
	var cam: Camera3D = region.cam
	cam.global_position = cam.global_position.lerp(ojo, w)
	cam.look_at(foco0.lerp(mira, w), Vector3.UP)
	if cam.projection == Camera3D.PROJECTION_ORTHOGONAL:
		cam.size = lerpf(cam.size, 2.0 * PRESENTACION[1] * tan(deg_to_rad(19.0)), w)


# ================================================================= sonido y cámara

func _sonar(clave: String, pos: Vector3) -> void:
	if not Sonido.definicion(clave).is_empty():
		Sonido.efecto(clave, {"pos": pos})


# La cámara vibra con la arena: un desplazamiento pequeño que se apaga solo (la región la recoloca cada fotograma).
func _sacudir(delta: float) -> void:
	if _sacudida <= 0.0 or region.cam == null:
		return
	_sacudida = maxf(0.0, _sacudida - delta * 0.8)
	var a := _sacudida * 0.12
	region.cam.global_position += Vector3(randf_range(-a, a), randf_range(-a, a), randf_range(-a, a))
