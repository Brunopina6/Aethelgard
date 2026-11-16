extends "res://prototipos/vista3d.gd"
# BARRIO EXPERIMENTAL de Oakhaven (V12, 16/11): LA REGIÓN. EN PRUEBAS y APAGADO: solo se entra desde el banco de pruebas
# de Auditoría («Barrio de Oakhaven (en pruebas)», banco_pruebas.gd, EXPLORAR["barrio"]). Ninguna escena del juego lo
# enlaza; Oakhaven 3D no cambia. Fuera del banco, _ready vuelve a la pantalla de carga y no sigue.
# Plan: docs/v12/BARRIO_OAKHAVEN_PLAN.md; lo hecho y el contrato real: docs/v12/BARRIO_OAKHAVEN.md.
#
# FASE 0: un BLOCKOUT de cajas sacado del trazado (zonas3d/barrio/trazado.gd: suelos con sus cotas, rampas y escalones;
# fachadas con su altura aproximada; puertas marcadas; un StaticBody3D por caja), Kael andando por el bucle entero
# (caravanas → calle comercial → plaza → talleres → casas → atajo → caravanas) con la cámara por ZONAS sin girar (la de la
# muestra de la calle), la API de región del contrato y el reparto de _accion.
# FASE A (16/11, agente A): los tramos HORNEADOS con el acabado aprobado de la muestra (fuente/crear_barrio.py con el kit
# kit_barrio.py): cada sector con su GLB (modelos/barrio_<s>.glb: «fijo_<s>» con su mapa de luz, «piezas_<s>» y
# «vegetacion_<s>» con la luz en los vértices, un «choque_<id>» por caja), los 4 sombreados de la muestra SIN cambios
# (calle_*.gdshader) y sus texturas, la tarde dorada de la muestra (sol y cielo medidos en el horneado, barrio_luz.json),
# Kael iluminado como en la muestra (sondas por sector en PNG: sol y cielo; el tono en sombra y la sombra de contacto ya
# corregidos allí) y la visibilidad por sector (qué sectores se ven desde cada zona, medido en el recorte de Blender).
# Un sector sin su GLB sigue en blockout (cajas), con la luz provisional. Engine «barrio_solo_blockout»: todo en blockout
# (las capturas del antes).
#
# CONTRATO (lo que reciben B y C de esta región; plan §11):
#   var kael, cam, perfil, interior ("" = fuera)          signal interior_cambiado(id)
#   avisar(texto, efecto := "", seg := 2.8)               guardar()            ocupado() -> bool
#   sonda(p) -> Vector2 (sol, cielo)                      iniciar_dialogo(ruta) -> bool
#   ancla(id) -> Vector3 ("int_*" → interiores; si no, trazado)
# Reparto de _accion: «entrar_<id>» y «salir_<id>» → aquí + interiores (fundido); un id de vivo.piezas() →
# vivo.hablar(id); cualquier otro → Barrio.accion(pid).

const T := preload("res://zonas3d/barrio/trazado.gd")
const Interiores := preload("res://zonas3d/barrio/interiores.gd")
const Vivo := preload("res://zonas3d/barrio/barrio_vivo.gd")
const Barrio := preload("res://ciudades/oakhaven_barrio.gd")
const Progreso := preload("res://progreso.gd")
const BP_RUTA := "res://banco_pruebas.gd"

const INDICE := 102                        # pos_3d_lugar del barrio (0-10 mapa, 99 banco, 100 mapamundi, 101 cueva)
const META_ACTIVO := "barrio_v12"          # metas de SESIÓN (banco_pruebas.gd, METAS_SESION)
const META_INTERIOR := "barrio_interior"   # {id, pos}: solo para volver a aparecer dentro tras la recarga de CAL
const META_RELOJ := "barrio_reloj"         # (del agente C: el reloj de las rutinas)
const TEXTO_OBRAS := "Aún no se puede entrar (en obras)."
const SONDA_PROVISIONAL := Vector2(1.0, 0.7)   # (un sector en blockout, sin luz horneada)
const MODELOS := "res://zonas3d/barrio/modelos/"
const LUZ_JSON := MODELOS + "barrio_luz.json"
const META_BLOCKOUT := "barrio_solo_blockout"  # (capturas del antes: todo en blockout aunque haya GLB)
# Lo de la muestra de la calle, SIN cambios: sus 4 sombreados (sin programas nuevos: vale su precalentado) y sus texturas.
const RAIZ_MUESTRA := "res://zonas3d/muestra_calle/"
const SH_ESTATICO := preload("res://zonas3d/muestra_calle/calle_estatico.gdshader")
const SH_HOJA := preload("res://zonas3d/muestra_calle/calle_hoja.gdshader")
const SH_BRILLO := preload("res://zonas3d/muestra_calle/calle_brillo.gdshader")
const SH_VERTICE := preload("res://zonas3d/muestra_calle/calle_vertice.gdshader")
const TEXTURA_DE := {"piedra": "piedra", "tierra": "tierra", "revoque": "revoque", "madera": "madera", "tejas": "tejas",
	"sillar": "sillar", "hierro": "piedra", "tela": "tela", "barro": "revoque", "hoja": "hoja"}
const MAPA_LUZ := {"bajo": 1024, "medio": 2048, "alto": 2048}
# (de la muestra, corrección 2 del 15/11) el tono de la luz horneada en la sombra: Kael en sombra toma este tono con la
# MISMA luminancia (al sol queda igual), para que no salga azul.
const TONO_SOMBRA := Color(0.862, 0.836, 1.0)
const HZ_VISIBLES := 0.25                  # cada cuánto se revisa qué sectores se ven (s)
const RADIO_SALIR := 1.3
const DIST_PREPARAR := 8.0                 # a menos de esto de una puerta, interiores.preparar(id)
const FUNDIDO := [0.35, 0.15, 0.35]        # a negro, espera, vuelta (plan §3)

signal interior_cambiado(id: String)

var brillo_sin_sombras := 1.1               # vista3d.gd: el bajo sin sombras
var perfil: Dictionary = {}
var nombre_perfil := "alto"
var interior := ""
var interiores = null                      # zonas3d/barrio/interiores.gd (Node3D)
var vivo = null                            # zonas3d/barrio/barrio_vivo.gd (Node3D)
var exterior: Node3D
var sectores := {}                         # sector → su Node3D (para la visibilidad por sector del agente A)
var sol: DirectionalLight3D
var ambiente: Environment
var grupo: Node3D
var capa_ui: CanvasLayer
var boton_accion: Button
var boton_recargar: Button
var aviso: Label
var fundido: ColorRect
var titulo: Label
var cerca := ""
var cambiando := false                     # durante el fundido de una puerta
var dialogo_actual := ""
var ultimo_aviso := ""
var choques := 0                           # cuerpos de choque de las cajas del trazado + suelos + fondo (para las pruebas)
var choques_piezas := 0                    # (fase A) los de las piezas sueltas en lo andable (choque_<s>_p<n>)
var fuera_del_banco := false
# (fase A) la luz horneada y los sectores acabados
var luz: Dictionary = {}                   # barrio_luz.json (escala, sol, cielo, sondas y visibles por sector)
var acabados: Array = []                   # sectores con su GLB horneado (el resto, en blockout)
var materiales_sector := {}                # sector → [ShaderMaterial] estáticos (su mapa de luz; con la sombra de Kael)
var materiales_comunes: Array = []         # los de piezas y vegetación (luz en los vértices; compartidos)
var materiales_usados: Array = []          # (para las pruebas)
var tex_luz_usadas := {}                   # sector → ruta del mapa de luz cargado
var visibles := {}                         # sector → true (lo que se dibuja ahora)
var _sol_base := 1.0
var _amb_base := 0.5
var _sol_k := 1.0
var _cielo_k := 1.0
var _tono_cielo := Color(1, 1, 1)
var _t_visibles := 0.0
var _bloqueo := 0.0
var _ids_vivo := {}
var _preparados := {}
var _t_puertas := 0.0
var _avisos_cola: Array = []
var _tween_aviso: Tween


# ¿Estamos en el banco de pruebas de Auditoría?
static func en_banco_pruebas() -> bool:
	return load(BP_RUTA).en_banco()


# La guardia del prólogo (plan §1), común a toda puerta o pasaje.
static func puede_pasar() -> bool:
	return Barrio.puede_pasar()


func _ready() -> void:
	if not en_banco_pruebas():
		fuera_del_banco = true                    # (una partida vieja, F6…): a la carga, sin construir nada
		set_process(false)
		set_process_unhandled_input(false)
		_volver_a_la_carga.call_deferred()
		return
	Engine.set_meta(META_ACTIVO, true)            # la región se activa a sí misma (el banco no pone metas por caso)
	var cal = load("res://prototipos/calidad_proto.gd")
	perfil = cal.datos()
	nombre_perfil = cal.actual()
	super()
	info.visible = false
	_crear_sombra_kael()
	_crear_interfaz()
	interiores = Interiores.new()
	interiores.name = "Interiores"
	add_child(interiores)
	interiores.construir(self)
	vivo = Vivo.new()
	vivo.name = "BarrioVivo"
	add_child(vivo)
	vivo.montar(self)
	Barrio.registrar_dialogic()
	_colocar_kael(_sitio_de_entrada())
	_crear_grupo()
	_volver_dentro_tras_cal()
	var dg = get_node_or_null("/root/Dialogic")
	if dg != null:
		dg.timeline_ended.connect(_al_terminar_dialogo)
		dg.signal_event.connect(_al_senal)
	if has_node("/root/Sonido"):
		Sonido.oyente_3d(kael, cam)
		Sonido.pasos_3d(kael, suelo_de_pasos)


func _volver_a_la_carga() -> void:
	while is_inside_tree() and has_node("/root/Recursos") and Recursos.cambiando:
		await get_tree().process_frame             # (si llegó por Recursos.cambiar_escena, que acabe su fundido)
	if is_inside_tree() and has_node("/root/Recursos"):
		Recursos.cambiar_escena(load(BP_RUTA).CARGA)


func _exit_tree() -> void:
	var dg = get_node_or_null("/root/Dialogic")
	if dg != null:
		if dg.timeline_ended.is_connected(_al_terminar_dialogo):
			dg.timeline_ended.disconnect(_al_terminar_dialogo)
		if dg.signal_event.is_connected(_al_senal):
			dg.signal_event.disconnect(_al_senal)
	super()


# Cachés estáticas de la región (como las de la muestra, medido allí: los materiales de 15-16 ms a 0,1 ms por entrada;
# la luz del json, una vez por proceso). Retienen recursos de render: las suelta banco_pruebas.salir() (no deben llegar
# vivas al apagado del motor: el cierre 0xC0000005 sigue abierto).
static var _luz_cache := {}
static var _mats_cache := {}               # «perfil|sector|mapa» → {clave de material: Material}
static var _sondas_cache := {}             # sector → Image (R = sol, G = cielo)


static func soltar_caches() -> void:
	_luz_cache = {}
	_mats_cache = {}
	_sondas_cache = {}


# (16/11, pulido: precalentado) Lo que el barrio dibuja y el precalentado de la muestra no cubre. Medido con la caché de
# sombreadores VACÍA (la carga con los estudios de combate y la muestra, y luego el barrio desde el banco, los 6 tramos y
# el horno): la entrada compilaba 2 programas más; todo lo demás (tramos, interiores, utensilios) son los 4 sombreados de
# la muestra. Son los de la gente: los vecinos de C (la familia chibi con sus oficios y personas) y Avena. Se montan
# DENTRO del SubViewport del precalentado de la muestra (su mismo ambiente, sol y escala 3D: la misma variante) y
# delante de su cámara. Solo en la carga con banco_pruebas.permitido() (carga.gd), como la muestra.
static func precalentar_en(vp: Node) -> int:
	if vp == null:
		return 0
	var M = load("res://zonas3d/muestra_calle/muestra_calle.gd")
	var sitio: Vector3 = M.SITIO_FOTO
	var raiz := Node3D.new()
	raiz.name = "PrecalentadoBarrio"
	vp.add_child(raiz)
	var n := 0
	var NpcBarrio = load("res://zonas3d/barrio/npc_barrio.gd")
	var sombras := bool(load("res://prototipos/calidad_proto.gd").datos().get("sombras", false))
	for id in Barrio.NPCS:
		var ch: Array = Barrio.NPCS[id].get("chibi", [])
		if ch.size() < 2 or not NpcBarrio.hay(ch[0], ch[1]):
			continue
		var c: Node3D = NpcBarrio.crear_barrio(ch[0], ch[1])
		if not c.listo:
			c.free()
			continue
		raiz.add_child(c)
		c.sombra(sombras)
		c.position = sitio + Vector3(-3.0 + 1.2 * n, 0.0, 0.0)
		n += 1
	var ruta_caballo := "res://personajes/npc_v12/caballo/caballo.glb"
	if ResourceLoader.exists(ruta_caballo):
		var cab: Node3D = (load(ruta_caballo) as PackedScene).instantiate()
		raiz.add_child(cab)
		cab.position = sitio + Vector3(3.5, 0.0, -1.0)
		n += 1
	return n


func _leer_luz() -> Dictionary:
	if _luz_cache.is_empty() and FileAccess.file_exists(LUZ_JSON):
		var d = JSON.parse_string(FileAccess.get_file_as_string(LUZ_JSON))
		if d is Dictionary:
			_luz_cache = d
	return _luz_cache


# ¿Qué sectores tienen su GLB horneado (y su entrada en barrio_luz.json)? Con «barrio_solo_blockout», ninguno.
func _sectores_acabados() -> Array:
	var r: Array = []
	if Engine.has_meta(META_BLOCKOUT):
		return r
	var sec: Dictionary = luz.get("sectores", {})
	for s in T.ORDEN:
		if sec.has(s) and ResourceLoader.exists(MODELOS + "barrio_%s.glb" % s):
			r.append(s)
	return r


# ================================================================= mundo: la tarde dorada
# Con algún tramo horneado, la luz es LA DE LA MUESTRA (sol y cielo medidos en el horneado, bruma, mapeo de tonos y
# ajustes): sin ella el acabado aprobado no se ve igual. Todo en blockout: la provisional de la fase 0.

func _crear_ambiente() -> void:
	luz = _leer_luz()
	acabados = _sectores_acabados()
	if not acabados.is_empty():
		_crear_ambiente_horneado()
		return
	ambiente = Environment.new()
	ambiente.background_mode = Environment.BG_COLOR
	ambiente.background_color = Color(0.86, 0.80, 0.70)
	ambiente.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambiente.ambient_light_color = Color(0.62, 0.68, 0.80)
	ambiente.ambient_light_energy = 0.55
	ambiente.fog_enabled = true
	ambiente.fog_light_color = Color(0.86, 0.76, 0.62)
	ambiente.fog_density = 0.0025
	ambiente.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	ambiente.tonemap_exposure = 0.95
	var we := WorldEnvironment.new()
	we.name = "Ambiente"
	we.environment = ambiente
	add_child(we)
	sol = DirectionalLight3D.new()                 # sol bajo del oeste-suroeste (el de la muestra de la calle)
	sol.name = "Sol"
	var h := Vector3(-0.73, 0.45, 0.51).normalized()
	sol.look_at_from_position(Vector3.ZERO, -h, Vector3.UP)
	sol.light_color = Color(1.0, 0.84, 0.64)
	sol.light_energy = 1.05
	sol.shadow_enabled = bool(perfil.get("sombras", false))
	sol.directional_shadow_max_distance = float(perfil.get("dist_sombras", 40.0))
	add_child(sol)
	_guardar_luz_fija()


# La de muestra_calle.gd (_crear_ambiente), con barrio_luz.json: el mismo sol, el mismo cielo y los mismos ajustes.
func _crear_ambiente_horneado() -> void:
	brillo_sin_sombras = 1.0                   # (la luz horneada no depende de las sombras: como la muestra)
	ambiente = Environment.new()
	ambiente.background_mode = Environment.BG_COLOR
	ambiente.background_color = Color(0.86, 0.80, 0.70)
	ambiente.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	var cielo: Array = luz.get("cielo_color", [0.30, 0.34, 0.45])
	var c_cielo := Color(cielo[0], cielo[1], cielo[2])
	_amb_base = maxf(c_cielo.r, maxf(c_cielo.g, c_cielo.b))
	_tono_cielo = Color(c_cielo.r / _amb_base, c_cielo.g / _amb_base, c_cielo.b / _amb_base)
	ambiente.ambient_light_color = _tono_cielo
	ambiente.ambient_light_energy = _amb_base
	ambiente.fog_enabled = true
	ambiente.fog_light_color = Color(0.86, 0.76, 0.62)
	ambiente.fog_density = 0.0025
	ambiente.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	ambiente.tonemap_exposure = 0.86
	ambiente.adjustment_enabled = true
	ambiente.adjustment_saturation = 1.12
	ambiente.adjustment_contrast = 1.12
	if nombre_perfil == "alto":
		ambiente.glow_enabled = true
		ambiente.glow_intensity = 0.35
		ambiente.glow_bloom = 0.02
		ambiente.glow_hdr_threshold = 1.1
	var we := WorldEnvironment.new()
	we.name = "Ambiente"
	we.environment = ambiente
	add_child(we)
	sol = DirectionalLight3D.new()
	sol.name = "Sol"
	var hs: Array = luz.get("hacia_sol", [-0.73, 0.45, 0.51])
	var h := Vector3(hs[0], hs[1], hs[2]).normalized()
	sol.look_at_from_position(Vector3.ZERO, -h, Vector3.UP if absf(h.y) < 0.99 else Vector3.FORWARD)
	var sc: Array = luz.get("sol_color_medido", [1.0, 0.8, 0.6])
	var c := Color(sc[0], sc[1], sc[2])
	_sol_base = maxf(c.r, maxf(c.g, c.b))
	if _sol_base <= 0.0:
		_sol_base = 1.0
	sol.light_color = Color(c.r / _sol_base, c.g / _sol_base, c.b / _sol_base)
	sol.light_energy = _sol_base
	sol.shadow_enabled = false                 # (sombras horneadas; la de Kael va en los sombreados del suelo)
	add_child(sol)
	_guardar_luz_fija()


# ================================================================= los tramos horneados (fase A)

# Un sector con su GLB: los materiales de la muestra (el estático con el mapa de luz DEL SECTOR; piezas y vegetación con
# la luz en los vértices, compartidos), un StaticBody3D por «choque_» (lo medido como mejor) y nada más.
func _sector_horneado(s: String) -> void:
	var modelo: Node3D = (load(MODELOS + "barrio_%s.glb" % s) as PackedScene).instantiate()
	modelo.name = "Modelo"
	(sectores[s] as Node3D).add_child(modelo)
	var res := int(MAPA_LUZ.get(nombre_perfil, 2048))
	var ruta_luz := MODELOS + "barrio_%s_luz_%d.png" % [s, res]
	var tex_luz: Texture2D = load(ruta_luz) if ResourceLoader.exists(ruta_luz) else null
	tex_luz_usadas[s] = ruta_luz if tex_luz != null else ""
	var k_est := "%s|%s|%s" % [nombre_perfil, s, tex_luz_usadas[s]]
	var k_com := "%s|comunes" % nombre_perfil
	var est: Dictionary = _mats_cache.get(k_est, {})
	var com: Dictionary = _mats_cache.get(k_com, {})
	var propios: Array = []
	for mi in modelo.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var vertice := not String(m.name).begins_with("fijo")       # piezas y vegetación: luz en los vértices
		if vertice:
			if not _detalle.has(s):
				_detalle[s] = []
			_detalle[s].append(m)
		for i in m.mesh.get_surface_count():
			var orig := m.mesh.surface_get_material(i)
			var nombre := (orig.resource_name if orig != null else "").get_slice(".", 0)
			var clave := ("v:" if vertice else "") + nombre
			var dic: Dictionary = com if vertice or nombre == "brillo" else est
			if not dic.has(clave):
				dic[clave] = _material(nombre, tex_luz, vertice)
			m.set_surface_override_material(i, dic[clave])
			if not materiales_usados.has(clave):
				materiales_usados.append(clave)
	_mats_cache[k_est] = est
	_mats_cache[k_com] = com
	for clave in est:
		if est[clave] is ShaderMaterial and (est[clave] as ShaderMaterial).shader == SH_ESTATICO:
			propios.append(est[clave])
	materiales_sector[s] = propios
	for clave in com:
		var mc = com[clave]
		if mc is ShaderMaterial and (mc as ShaderMaterial).shader != SH_BRILLO and not materiales_comunes.has(mc):
			materiales_comunes.append(mc)
	for n in modelo.find_children("choque_*", "", true, false):
		_choque_glb(n as Node3D, s)


# Lo lejano (campos y árboles fuera del barrio): un GLB aparte, solo con luz en los vértices; se dibuja siempre.
func _fondo_horneado() -> void:
	var f: Node3D = (load(MODELOS + "barrio_fondo.glb") as PackedScene).instantiate()
	f.name = "FondoLejano"
	exterior.add_child(f)
	var com: Dictionary = _mats_cache.get("%s|comunes" % nombre_perfil, {})
	for mi in f.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for i in m.mesh.get_surface_count():
			var orig := m.mesh.surface_get_material(i)
			var nombre := (orig.resource_name if orig != null else "").get_slice(".", 0)
			var clave := "v:" + nombre
			if not com.has(clave):
				com[clave] = _material(nombre, null, true)
			m.set_surface_override_material(i, com[clave])
	_mats_cache["%s|comunes" % nombre_perfil] = com


# El material de la muestra (muestra_calle.gd, _material) para el barrio.
func _material(nombre: String, tex_luz: Texture2D, vertice: bool) -> Material:
	var tex: Texture2D = null
	if TEXTURA_DE.has(nombre):
		var ruta: String = RAIZ_MUESTRA + "texturas/" + TEXTURA_DE[nombre] + ".png"
		if ResourceLoader.exists(ruta):
			tex = load(ruta)
	if nombre == "brillo":
		var b := ShaderMaterial.new()
		b.shader = SH_BRILLO
		b.set_shader_parameter("energia", 1.45 if nombre_perfil == "alto" else 1.2)
		b.set_shader_parameter("usar_color_fijo", false)   # (el generador ya no multiplica los cristales por la luz)
		return b
	var e := float(luz.get("escala", 1.0))
	var m := ShaderMaterial.new()
	if nombre == "hoja" or vertice:
		m.shader = SH_HOJA if nombre == "hoja" else SH_VERTICE
		m.set_shader_parameter("textura", tex)
		m.set_shader_parameter("luz_escala", e)
		if nombre == "hoja":
			m.set_shader_parameter("viento", 1.0)
		return m
	m.shader = SH_ESTATICO
	m.set_shader_parameter("textura", tex)
	m.set_shader_parameter("luz", tex_luz)
	m.set_shader_parameter("luz_escala", e)
	return m


# Un cuerpo por caja, como la muestra (_choque): el vacío lleva el medio tamaño en su escala.
func _choque_glb(n: Node3D, s: String) -> void:
	var t := n.global_transform
	var tam := t.basis.get_scale() * 2.0
	var cuerpo := StaticBody3D.new()
	cuerpo.name = String(n.name).replace("choque_", "Choque_")
	cuerpo.transform = Transform3D(t.basis.orthonormalized(), t.origin)
	var col := CollisionShape3D.new()
	var caja := BoxShape3D.new()
	caja.size = Vector3(absf(tam.x), absf(tam.y), absf(tam.z))
	col.shape = caja
	cuerpo.add_child(col)
	(sectores[s] as Node3D).add_child(cuerpo)
	if String(n.name).begins_with("choque_%s_p" % s):
		choques_piezas += 1
	else:
		choques += 1


# ================================================================= el blockout (fase 0), sacado del trazado

const COLOR_SUELO := {"caravanas": Color(0.62, 0.55, 0.42), "comercial": Color(0.66, 0.62, 0.56),
	"plaza": Color(0.72, 0.68, 0.60), "talleres": Color(0.60, 0.54, 0.46), "residencial": Color(0.64, 0.60, 0.52),
	"atajo": Color(0.56, 0.54, 0.50)}
const COLOR_TIPO := {"casa": Color(0.86, 0.80, 0.68), "muro": Color(0.62, 0.60, 0.56), "bajo": Color(0.55, 0.45, 0.32),
	"puerta": Color(0.86, 0.52, 0.18), "decor": Color(0.70, 0.62, 0.42), "terreno": Color(0.45, 0.52, 0.32)}
const COLOR_TEJADO := Color(0.58, 0.30, 0.24)
const COLOR_FONDO := Color(0.50, 0.50, 0.40)
const GRUESO_SUELO := 2.0
const ROTULOS := {"horno": "Horno", "taller": "Taller", "vivienda": "Vivienda"}

var _caja_v: PackedVector3Array
var _caja_n: PackedVector3Array
var _mallas := {}                          # sector → SurfaceTool


func _crear_escenario() -> void:
	exterior = Node3D.new()
	exterior.name = "Exterior"
	add_child(exterior)
	var cubo := BoxMesh.new()
	var a := cubo.get_mesh_arrays()
	var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX]
	var vs: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var ns: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
	if idx.is_empty():                             # (sin índices: los vértices ya van de tres en tres)
		_caja_v = vs
		_caja_n = ns
	for i in idx:
		_caja_v.append(vs[i])
		_caja_n.append(ns[i])
	for s in T.ORDEN:
		var n := Node3D.new()
		n.name = "Sector_" + s
		exterior.add_child(n)
		sectores[s] = n
		visibles[s] = true
	# el fondo: tierra baja bajo todo (lo que no se pisa); con tramos horneados, 5 cm más abajo que su tierra (y visible
	# solo si queda algún tramo en blockout)
	var en_bloques: Array = T.ORDEN.filter(func(q): return not q in acabados)
	_caja_blockout("caravanas", Transform3D(Basis.IDENTITY, Vector3(-20.0, -0.58 if not acabados.is_empty() else -0.53, -13.0)),
		Vector3(80.0, 1.0, 70.0), COLOR_FONDO, true, "Fondo", "" if en_bloques.is_empty() else en_bloques[0])
	for s in T.SUELOS:
		_suelo(s)
	for b in T.BLOQUES:
		if not b[1] in acabados:
			_bloque(b)
	for s in acabados:
		_sector_horneado(s)
	if not acabados.is_empty() and ResourceLoader.exists(MODELOS + "barrio_fondo.glb"):
		_fondo_horneado()
	for s in _mallas:
		var st: SurfaceTool = _mallas[s]
		var mi := MeshInstance3D.new()
		mi.name = "Blockout"
		mi.mesh = st.commit()
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.roughness = 1.0
		mi.material_override = m
		(sectores[s] as Node3D).add_child(mi)
	_rotulos()


# Una losa de suelo por SUELO: llana o inclinada (rampa o escalones), con la cara de arriba exactamente en altura().
# (16/11, pulido) Cada losa se SOLAPA SOLAPE_SUELO con sus vecinas por los cuatro lados: antes las losas se tocaban justo
# en la costura (x −32 entre caravanas y comercial, z −8 al pie de la rampa…) y el rayo que baja de _altura_suelo, al caer
# exactamente en la arista, devolvía la normal de la cara del extremo (horizontal) y Kael no pasaba (NAN en (−32; 0; 2)).
# Con el solape, en la costura siempre hay una cara de arriba (la vecina más alta, a menos de 1,2 cm en los escalones).
const SOLAPE_SUELO := 0.05

func _suelo(s: Array) -> void:
	var r: Rect2 = s[1]
	var eje: String = s[2]
	var a: Vector3
	var b: Vector3
	var lado: Vector3
	if eje == "z":
		a = Vector3(r.get_center().x, s[3], r.position.y)
		b = Vector3(r.get_center().x, s[4], r.end.y)
		lado = Vector3(r.size.x, 0, 0)
	else:
		a = Vector3(r.position.x, s[3], r.get_center().y)
		b = Vector3(r.end.x, s[4], r.get_center().y)
		lado = Vector3(0, 0, r.size.y)
	var largo := a.distance_to(b)
	var dir := (b - a) / largo
	var bx: Vector3
	var by: Vector3
	var bz: Vector3
	var tam: Vector3
	if eje == "z":
		bz = dir
		bx = Vector3.RIGHT
		by = bz.cross(bx)
		tam = Vector3(lado.x + 2.0 * SOLAPE_SUELO, GRUESO_SUELO, largo + 2.0 * SOLAPE_SUELO)
	else:
		bx = dir
		bz = Vector3.BACK
		by = bz.cross(bx)
		tam = Vector3(largo + 2.0 * SOLAPE_SUELO, GRUESO_SUELO, lado.z + 2.0 * SOLAPE_SUELO)
	var base := Basis(bx, by, bz)
	var centro := (a + b) * 0.5 - by * (GRUESO_SUELO * 0.5)
	_caja_blockout(s[0], Transform3D(base, centro), tam, COLOR_SUELO.get(s[0], COLOR_FONDO), true, "Suelo",
		"" if s[0] in acabados else s[0])          # (en un tramo horneado, el suelo de choque no se dibuja: lo pone su GLB)


func _bloque(b: Array) -> void:
	var r: Rect2 = b[2]
	var base: float = b[3]
	var alto: float = b[4]
	var tipo: String = b[5]
	var abajo := base - 0.5 if tipo != "puerta" else base
	var tam := Vector3(r.size.x, base + alto - abajo, r.size.y)
	var c := Vector3(r.get_center().x, abajo + tam.y * 0.5, r.get_center().y)
	_caja_blockout(b[1], Transform3D(Basis.IDENTITY, c), tam, COLOR_TIPO.get(tipo, COLOR_FONDO), b[6], "Choque_" + String(b[0]))
	if tipo == "casa":                             # el tejado: una losa con vuelo, de otro color (sin choque)
		var t := Vector3(r.size.x + 0.6, 0.45, r.size.y + 0.6)
		_caja_blockout(b[1], Transform3D(Basis.IDENTITY, Vector3(c.x, base + alto + 0.2, c.z)), t, COLOR_TEJADO, false, "")


# Una caja en la malla de su sector (con su color en los vértices) y, si es sólida, su cuerpo de choque. «malla»: en qué
# malla se dibuja ("" = en ninguna: solo el choque); por defecto, la de su sector.
func _caja_blockout(sector: String, xf: Transform3D, tam: Vector3, color: Color, solida: bool, nombre: String,
		malla = null) -> void:
	var m_sector: String = sector if malla == null else String(malla)
	if m_sector != "":
		if not _mallas.has(m_sector):
			var nueva := SurfaceTool.new()
			nueva.begin(Mesh.PRIMITIVE_TRIANGLES)
			_mallas[m_sector] = nueva
		var st: SurfaceTool = _mallas[m_sector]
		var esc := Transform3D(Basis(xf.basis.x * tam.x, xf.basis.y * tam.y, xf.basis.z * tam.z), xf.origin)
		for i in _caja_v.size():
			st.set_color(color)
			st.set_normal((xf.basis * _caja_n[i]).normalized())
			st.add_vertex(esc * _caja_v[i])
	if not solida:
		return
	var cuerpo := StaticBody3D.new()
	cuerpo.name = nombre if nombre != "" else "Choque"
	cuerpo.transform = xf
	var col := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = tam
	col.shape = forma
	cuerpo.add_child(col)
	(sectores[sector] as Node3D).add_child(cuerpo)
	choques += 1


# Los rótulos «(en obras)» de las puertas cuyo interior todavía no existe (Interiores.ORIGEN sin su id).
func _rotulos() -> void:
	for id in T.PUERTAS:
		if Interiores.ORIGEN.has(id):
			continue
		var l := Label3D.new()
		l.name = "Rotulo_" + id
		l.text = "%s (en obras)" % ROTULOS.get(id, id)
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.font_size = 40
		l.outline_size = 10
		l.modulate = Color(1.0, 0.94, 0.78)
		l.outline_modulate = Color(0.30, 0.14, 0.08, 0.85)
		l.pixel_size = 0.01
		var umbral := T.ancla(T.PUERTAS[id]["ancla"])
		var fuera: Vector3 = T.PUERTAS[id]["fuera"]
		var hacia := Vector3(fuera.x - umbral.x, 0.0, fuera.z - umbral.z).normalized()
		l.position = umbral + hacia * 0.9 + Vector3(0, 3.0, 0)       # (delante de la fachada: no la corta)
		var s := T.sector_de(umbral.x, umbral.z)
		(sectores.get(s, exterior) as Node3D).add_child(l)


# ================================================================= Kael, cámara y grupo

func _sitio_de_entrada() -> Vector3:
	var vuelve: bool = Engine.get_meta("pos_3d_ok", false) and int(Engine.get_meta("pos_3d_lugar", -1)) == INDICE \
		and Engine.get_meta("pos_3d", null) is Vector3
	if vuelve:
		var p: Vector3 = Engine.get_meta("pos_3d")
		if Interiores.interior_de(p) == "" and T.andable(p.x, p.z):   # nunca dentro de un ORIGEN ni en lo prohibido
			return Vector3(p.x, T.altura(p.x, p.z), p.z)
	return T.ancla("inicio")


func _colocar_kael(p: Vector3) -> void:
	p.y = interiores.altura(p) if interior != "" and interiores != null else T.altura(p.x, p.z)
	kael.global_position = p
	seguro = p
	foco = T.foco_camara(p)
	destino = null
	_meta_final = null
	_rodeando = false
	_colocar_camara(1.0)
	_luz_kael(1.0)
	_sombras_kael()
	_actualizar_visibles()


func _mirar_kael(angulo: float) -> void:
	if kael != null and kael.has_method("mirar"):
		kael.mirar(Vector3(-sin(angulo), 0.0, -cos(angulo)), 0.01)


func _colocar_camara(peso: float) -> void:
	if cam == null or kael == null:
		return
	var k := kael.global_position
	if interior != "" and interiores != null:
		var c: Array = interiores.camara(interior, k)
		if c.size() >= 3:
			cam.global_position = c[0]
			cam.global_rotation_degrees = c[1]
			cam.fov = c[2]
			return
	foco = foco.lerp(T.foco_camara(k), peso)
	T.poner_camara(cam, foco)


# Por dónde se anda: fuera, el trazado; dentro, lo que diga el interior; y, en los dos, sin pisar a los vecinos (dentro
# del horno Kael tampoco atraviesa a Maela: vivo.ocupa mira la zona de Kael).
func _prohibido(p: Vector3) -> bool:
	if _prohibido_suelo(p):
		return true
	if vivo != null and vivo.ocupa(p):
		return true
	return _en_obstaculo_extra(p)


# Lo fijo (sin vecinos): fuera, el trazado; dentro, el interior.
func _prohibido_suelo(p: Vector3) -> bool:
	if interior != "":
		return interiores == null or not interiores.andable(p)
	return not T.andable(p.x, p.z)


# Fuera, lo que se pisa es la cota del trazado: si el rayo de vista3d da otra (la tapa de un bloque o de una pieza suelta
# en la misma arista de lo andable, como los cajones de x −10), no se sube encima: no se pasa.
func _altura_suelo(p: Vector3, y_actual: float) -> float:
	var h := super(p, y_actual)
	if interior != "" or is_nan(h):
		return h
	return h if absf(h - T.altura(p.x, p.z)) < 0.1 else NAN


func suelo_de_pasos(p: Vector3) -> String:
	if interior != "":
		return "madera"
	return "grava" if T.sector_de(p.x, p.z) in ["caravanas", "talleres"] else "piedra"


# Tocar el suelo: lo que queda más de 1 m por encima de lo que se pisa (tejados, el arco) no cuenta.
func _punto_suelo(pantalla: Vector2):
	var desde := cam.project_ray_origin(pantalla)
	var hasta := desde + cam.project_ray_normal(pantalla) * 500.0
	var excluir: Array[RID] = []
	for i in 8:
		var q := PhysicsRayQueryParameters3D.create(desde, hasta)
		q.exclude = excluir
		var r := get_world_3d().direct_space_state.intersect_ray(q)
		if r.is_empty():
			return null
		var p: Vector3 = r["position"]
		if interior != "" or p.y < T.altura(p.x, p.z) + 1.0:
			return p
		excluir.append(r["rid"])
	return null


# ----------------------------------------------------------------- tocar el suelo y los vecinos (petición 3 de C)
# Antes, la recta hasta lo tocado se cortaba en la primera muestra que pisaba a un vecino: si rozaba su círculo, Kael no
# se movía. Ahora el destino solo se corta por lo FIJO (trazado o interior); si la recta roza a un vecino (o a Avena),
# Kael lo RODEA: cada fotograma va a la tangente de su círculo (con HOLGURA_RODEO) por el lado más corto, así que bordea
# el círculo hasta ver la meta y sigue recto. Nunca lo atraviesa (_prohibido sigue mirando vivo.ocupa). Si lo tocado cae
# encima de un vecino, se queda delante. Si no hay rodeo andable, se para delante como antes.
const HOLGURA_RODEO := 0.22                # m de más sobre el radio del vecino al rodearlo
const ROZA := 0.04                         # una recta a menos de radio + esto «roza» (más lejos pasa recta, rozando)
const T_RODEO_MAX := 8.0                   # s: si no llega en este tiempo rodeando, se para
var obstaculos_extra: Array = []           # (para las pruebas) cápsulas [a: Vector2, b: Vector2, radio] que cuentan como vecinos
var _meta_final = null                     # adónde va Kael de verdad mientras rodea (Vector3) o null
var _puesto = null                         # el último destino que puso el rodeo (si es otro, alguien lo cambió)
var _rodeando := false
var _punto_rodeo := Vector2.ZERO
var _t_rodeo := 0.0


func _ajustar_destino(p):
	if p == null or kael == null:
		return null
	var desde := kael.global_position
	var hacia: Vector3 = p
	var n := int(Vector2(hacia.x - desde.x, hacia.z - desde.z).length() / 0.1)   # (integración: cada 0,1 m; Kael anda a pasos de 0,15)
	var ultimo = null
	for i in n + 1:
		var q := desde.lerp(hacia, float(i) / maxf(n, 1))
		if _prohibido_suelo(q):
			break
		ultimo = q
	_meta_final = ultimo
	_puesto = ultimo
	_rodeando = false
	_t_rodeo = 0.0
	_mejor_falta = INF
	_t_sin_avance = 0.0
	return ultimo


# [a, b, radio] en planta: los vecinos visibles de la zona de Kael (un punto) y Avena fuera (su eje). Los que ya tienen a
# Kael dentro no cuentan (vivo.ocupa le deja salir).
func _obstaculos() -> Array:
	var r: Array = []
	var k := Vector2(kael.global_position.x, kael.global_position.z)
	if vivo != null:
		var ro: float = vivo.RADIO_OCUPA
		for id in vivo.vecinos:
			var d: Dictionary = vivo.vecinos[id]
			if not d["visible"] or d["lugar"] != vivo.zona:
				continue
			var q: Vector3 = d["pos"]
			var c := Vector2(q.x, q.z)
			if c.distance_to(k) >= ro:
				r.append([c, c, ro])
		if vivo.zona == "" and vivo.avena != null:
			var e: Array = vivo.eje_avena()
			var a := Vector2(e[0].x, e[0].z)
			var b := Vector2(e[1].x, e[1].z)
			if _dist_punto_segmento(k, a, b) >= vivo.RADIO_AVENA:
				r.append([a, b, vivo.RADIO_AVENA])
	for o in obstaculos_extra:
		if _dist_punto_segmento(k, o[0], o[1]) >= float(o[2]):
			r.append(o)
	return r


func _en_obstaculo_extra(p: Vector3) -> bool:
	if obstaculos_extra.is_empty() or kael == null:
		return false
	var q := Vector2(p.x, p.z)
	var k := Vector2(kael.global_position.x, kael.global_position.z)
	for o in obstaculos_extra:
		if _dist_punto_segmento(q, o[0], o[1]) < float(o[2]) and _dist_punto_segmento(k, o[0], o[1]) >= float(o[2]):
			return true
	return false


func _dentro_obstaculo(q: Vector2, margen: float) -> bool:
	for o in _obstaculos():
		if _dist_punto_segmento(q, o[0], o[1]) < float(o[2]) + margen:
			return true
	return false


static func _punto_en_segmento(p: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var ab := b - a
	var l2 := ab.length_squared()
	if l2 < 0.000001:
		return a
	return a + ab * clampf((p - a).dot(ab) / l2, 0.0, 1.0)


static func _dist_punto_segmento(p: Vector2, a: Vector2, b: Vector2) -> float:
	return p.distance_to(_punto_en_segmento(p, a, b))


# Distancia entre los segmentos pq y ab, y el punto de ab más cercano a pq (muestreo fino: son tramos de pocos metros).
static func _cerca_segmentos(p: Vector2, q: Vector2, a: Vector2, b: Vector2) -> Array:
	var mejor := INF
	var punto := a
	var n := maxi(1, ceili(p.distance_to(q) / 0.05))
	for i in n + 1:
		var s := p.lerp(q, float(i) / n)
		var c := _punto_en_segmento(s, a, b)
		var d := s.distance_to(c)
		if d < mejor:
			mejor = d
			punto = c
	return [mejor, punto]


# Cada fotograma (antes de andar): si Kael va a una meta tocada y la recta roza a alguien, el destino de este fotograma es
# la tangente del círculo por el lado más corto. Si un vecino que anda se le cruza y le corta un paso, lo vuelve a
# intentar (los vecinos se mueven); se rinde si en T_SIN_AVANCE no se acerca a la meta o tras T_RODEO_MAX.
const T_SIN_AVANCE := 1.5
var _mejor_falta := INF
var _t_sin_avance := 0.0


func _rodear(delta: float) -> void:
	if _meta_final == null:
		return
	var k := Vector2(kael.global_position.x, kael.global_position.z)
	var meta: Vector3 = _meta_final
	var m := _delante_de_vecino(k, Vector2(meta.x, meta.z))
	if direccion_teclas.length() > 0.1 or k.distance_to(m) < 0.15:   # las teclas o el stick mandan; o ya llegó
		if direccion_teclas.length() <= 0.1:
			destino = null
		_dejar_de_rodear()
		return
	if destino != null and not (destino as Vector3).is_equal_approx(_puesto):
		_dejar_de_rodear()                             # alguien puso otro destino
		return
	var falta := k.distance_to(m)
	if falta < _mejor_falta - 0.05:
		_mejor_falta = falta
		_t_sin_avance = 0.0
	else:
		_t_sin_avance += delta
	if _rodeando:
		_t_rodeo += delta
	if _t_sin_avance > T_SIN_AVANCE or _t_rodeo > T_RODEO_MAX:
		destino = null                                 # (no avanza: se queda donde está, como el vigilante de atascos)
		_dejar_de_rodear()
		return
	var w = _tangente(k, m)
	if w == null:
		destino = Vector3(m.x, meta.y, m.y)
		_rodeando = false
	else:
		_rodeando = true
		_punto_rodeo = w
		destino = Vector3(w.x, kael.global_position.y, w.y)
	_puesto = destino


# Si ahora hay un vecino encima de la meta, la meta de este fotograma es delante de él (en la recta desde Kael); si se va,
# Kael sigue hasta la meta tocada.
func _delante_de_vecino(k: Vector2, m: Vector2) -> Vector2:
	var atras := k - m
	var largo := atras.length()
	if largo < 0.001:
		return m
	var dir := atras / largo
	var andado := 0.0
	while andado < largo and _dentro_obstaculo(m + dir * andado, 0.05):
		andado += 0.1
	return m + dir * minf(andado, largo)


func _dejar_de_rodear() -> void:
	_meta_final = null
	_rodeando = false
	_t_rodeo = 0.0
	_mejor_falta = INF
	_t_sin_avance = 0.0


# El punto al que ir para rodear el primer obstáculo que roza la recta k→m (null si no roza ninguno o no hay rodeo).
func _tangente(k: Vector2, m: Vector2):
	var primero = null
	var t_min := INF
	for o in _obstaculos():
		var cs: Array = _cerca_segmentos(k, m, o[0], o[1])
		if float(cs[0]) < float(o[2]) + ROZA:
			var t := k.distance_to(cs[1])
			if t < t_min:
				t_min = t
				primero = [cs[1], float(o[2])]
	if primero == null:
		return null
	var c: Vector2 = primero[0]
	var rho: float = float(primero[1]) + HOLGURA_RODEO
	var kc := k - c
	var d := kc.length()
	var candidatos: Array = []
	if d > rho + 0.02:
		var alfa := acos(rho / d)
		var th := kc.angle()
		for s in [1.0, -1.0]:
			var tg := c + Vector2.from_angle(th + s * alfa) * rho
			candidatos.append(tg + (tg - k).normalized() * 0.3)       # (un poco más allá: no se para en la tangente)
	else:                                          # ya en la holgura: de lado, alejándose un poco
		var u := kc / maxf(d, 0.001)
		for s in [1.0, -1.0]:
			candidatos.append(k + u.orthogonal() * s * 0.5 + u * 0.1)
	candidatos.sort_custom(func(a, b): return k.distance_to(a) + a.distance_to(m) < k.distance_to(b) + b.distance_to(m))
	for w in candidatos:
		if _recta_suelo(k, w):
			return w
	return null


func _recta_suelo(a: Vector2, b: Vector2) -> bool:
	var y := kael.global_position.y
	var n := maxi(1, ceili(a.distance_to(b) / 0.1))
	for i in n + 1:
		var q := a.lerp(b, float(i) / n)
		if _prohibido_suelo(Vector3(q.x, y, q.y)):
			return false
	return true


func _crear_grupo() -> void:
	if not perfil.get("grupo", true):
		return
	var G = load("res://grupo.gd")
	var activos: Array = G.activos()
	var nombres: Array = []
	for n in G.EN_EL_GRUPO:
		if n != "Kael" and n in activos:
			nombres.append(n)
	grupo = load("res://zonas3d/grupo_3d.gd").new()
	grupo.name = "Grupo"
	add_child(grupo)
	grupo.pasos_superficie = suelo_de_pasos
	grupo.preparar(self, kael, nombres)
	grupo.colocar(Vector3.BACK)


func _parar_kael() -> void:
	destino = null
	_meta_final = null
	_rodeando = false
	if movimiento != "":
		movimiento = ""
		if kael.has_method("parar_marcha"):
			kael.parar_marcha()
		else:
			kael.reposo()


func ocupado() -> bool:
	if cambiando:
		return true
	var dg = get_node_or_null("/root/Dialogic")
	return dg != null and dg.current_timeline != null


func _crear_panel_rnd(capa: CanvasLayer) -> void:
	super(capa)
	for n in capa.get_children():
		if n is Button and n.text in ["PRUEBA", "DIAG", "TOPE", "ARB"]:
			n.queue_free()


# CAL recarga la escena entera: la posición va en la partida (la puerta de fuera si está dentro) y, solo para la sesión,
# el interior en el que estaba, para volver a aparecer dentro.
func _cambiar_perfil() -> void:
	guardar_posicion()
	if interior != "" and kael != null:
		Engine.set_meta(META_INTERIOR, {"id": interior, "pos": kael.global_position})
	super()


func _volver_dentro_tras_cal() -> void:
	if not Engine.has_meta(META_INTERIOR):
		return
	var d = Engine.get_meta(META_INTERIOR)
	Engine.remove_meta(META_INTERIOR)
	if not d is Dictionary or not Interiores.ORIGEN.has(str(d.get("id", ""))):
		return
	_pasar_dentro(str(d["id"]))
	var p = d.get("pos", null)
	if p is Vector3 and interiores.andable(p):
		_colocar_kael(p)


# ================================================================= API de región (contrato)

func avisar(texto: String, efecto := "", seg := 2.8) -> void:
	ultimo_aviso = texto
	if efecto != "" and has_node("/root/Sonido"):
		Sonido.efecto(efecto)
	if aviso == null:
		return
	aviso.text = texto
	if _tween_aviso != null and _tween_aviso.is_valid():
		_tween_aviso.kill()
	_tween_aviso = create_tween()
	_tween_aviso.tween_property(aviso, "modulate:a", 1.0, 0.2)
	_tween_aviso.tween_interval(seg)
	_tween_aviso.tween_property(aviso, "modulate:a", 0.0, 0.5)


# Guarda la partida (solo en el banco: va a su archivo, user://banco_pruebas.save).
func guardar() -> void:
	if not en_banco_pruebas():
		return
	guardar_posicion()
	Progreso.guardar(scene_file_path)


# La posición para la partida: dentro de un interior, SIEMPRE la puerta de fuera (nunca un ORIGEN lejano).
func guardar_posicion() -> void:
	if kael == null:
		return
	var p: Vector3 = kael.global_position
	if interior != "" and T.PUERTAS.has(interior):
		p = T.PUERTAS[interior]["fuera"]
	Engine.set_meta("pos_3d", p)
	Engine.set_meta("pos_3d_ok", true)
	Engine.set_meta("pos_3d_lugar", INDICE)


# Cuánto sol (x) y cuánto cielo (y) llega a 1 m del suelo en p: fuera, la rejilla de 0,25 m de su sector horneado
# (modelos/barrio_<s>_sondas.png, R = sol, G = cielo; interpolada); un sector en blockout, la provisional; dentro, la del
# interior (agente B). Sirve igual para Kael, los vecinos y los objetos de mano (agente C).
func sonda(p: Vector3) -> Vector2:
	if interior != "" and interiores != null:
		return interiores.sonda(p)
	var s := T.sector_de(p.x, p.z)
	if not s in acabados:
		for q in acabados:                         # (lo que no se pisa: el primer sector horneado cuya rejilla lo cubra)
			if _en_rejilla(q, p):
				s = q
				break
	if not s in acabados:
		return SONDA_PROVISIONAL
	return _sonda_sector(s, p)


func _meta_sondas(s: String) -> Dictionary:
	return ((luz.get("sectores", {}) as Dictionary).get(s, {}) as Dictionary).get("sondas", {})


func _en_rejilla(s: String, p: Vector3) -> bool:
	var m := _meta_sondas(s)
	if m.is_empty():
		return false
	var o: Array = m["origen"]
	var paso: float = m["paso"]
	return p.x >= float(o[0]) and p.z >= float(o[1]) and p.x <= float(o[0]) + paso * (int(m["nx"]) - 1) \
		and p.z <= float(o[1]) + paso * (int(m["nz"]) - 1)


func _sonda_sector(s: String, p: Vector3) -> Vector2:
	var m := _meta_sondas(s)
	if not _sondas_cache.has(s):
		var ruta := MODELOS + "barrio_%s_sondas.png" % s
		_sondas_cache[s] = load(ruta) if ResourceLoader.exists(ruta) else null
	var img = _sondas_cache[s]
	if m.is_empty() or not img is Image:
		return SONDA_PROVISIONAL
	var o: Array = m["origen"]
	var paso: float = m["paso"]
	var nx: int = mini(int(m["nx"]), (img as Image).get_width())
	var nz: int = mini(int(m["nz"]), (img as Image).get_height())
	var fx := clampf((p.x - float(o[0])) / paso, 0.0, nx - 1.001)
	var fz := clampf((p.z - float(o[1])) / paso, 0.0, nz - 1.001)
	var ix := int(fx)
	var iz := int(fz)
	var tx := fx - ix
	var tz := fz - iz
	var c00: Color = img.get_pixel(ix, iz)
	var c10: Color = img.get_pixel(ix + 1, iz)
	var c01: Color = img.get_pixel(ix, iz + 1)
	var c11: Color = img.get_pixel(ix + 1, iz + 1)
	var c := c00.lerp(c10, tx).lerp(c01.lerp(c11, tx), tz)
	return Vector2(c.r, c.g)


# ================================================================= Kael con la luz horneada (la de la muestra)

static func _lum(c: Color) -> float:
	return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b


# LA LUZ DE KAEL (y de los vecinos con sombreado normal): UNA SOLA AUTORIDAD, la región (acuerdo con B, 16/11; docs §9).
# Fuera: el sol y el cielo siguen a la sonda de su sector (muestra_calle.gd, _luz_kael, con la corrección 2 del tono en
# sombra). Dentro: interiores.sonda(p) con el tono de cada sala (Interiores.LUZ_KAEL, de B): el sol de las ventanas sube
# en sus manchas y el relleno (cielo y fuegos) sube el ambiente; el fondo oscuro y sin bruma. Lo de B en
# interiores.mostrar() queda tapado: la región escribe después en el mismo fotograma (_pasar_dentro / _pasar_fuera →
# _colocar_kael → aquí, con la pantalla en negro), así que no se ve ningún salto al entrar ni al salir.
const SOL_MANCHA := 1.2                    # dentro: el sol de Kael en una mancha de sol de ventana (sonda 1) = sala × (1 + esto)
var _luz_fija := {}                        # lo de fuera tal como lo crea la región (fondo, bruma, colores; blockout: todo)
var _luz_en := "?"                         # dónde se pusieron por última vez el fondo, la bruma y los colores


func _guardar_luz_fija() -> void:
	if ambiente == null or sol == null:
		return
	_luz_fija = {"fondo": ambiente.background_color, "amb_color": ambiente.ambient_light_color,
		"amb": ambiente.ambient_light_energy, "bruma": ambiente.fog_enabled, "sol": sol.light_energy,
		"sol_color": sol.light_color}


func _luz_kael(peso: float) -> void:
	if kael == null or sol == null or ambiente == null:
		return
	if _luz_fija.is_empty():
		_guardar_luz_fija()
	if interior != "" and interiores != null:
		_luz_kael_dentro(peso)
		return
	if _luz_en != "":
		_luz_en = ""
		ambiente.background_color = _luz_fija["fondo"]
		ambiente.fog_enabled = _luz_fija["bruma"]
		sol.light_color = _luz_fija["sol_color"]
		if acabados.is_empty():                    # (todo en blockout: la luz provisional, fija)
			sol.light_energy = _luz_fija["sol"]
			ambiente.ambient_light_color = _luz_fija["amb_color"]
			ambiente.ambient_light_energy = _luz_fija["amb"]
	if acabados.is_empty():
		return
	var v := sonda(kael.global_position)
	_sol_k = lerpf(_sol_k, v.x, peso)
	_cielo_k = lerpf(_cielo_k, v.y, peso)
	sol.light_energy = _sol_base * _sol_k
	var energia := _amb_base * (0.55 + 0.45 * _cielo_k)
	var w := 1.0 - clampf(_sol_k, 0.0, 1.0)
	if w <= 0.001:
		ambiente.ambient_light_color = _tono_cielo
		ambiente.ambient_light_energy = energia
		return
	var antes := _tono_cielo.srgb_to_linear()
	var t := antes.lerp(TONO_SOMBRA, w)
	var mx := maxf(t.r, maxf(t.g, t.b))
	t = Color(t.r / mx, t.g / mx, t.b / mx)
	ambiente.ambient_light_color = t.linear_to_srgb()
	ambiente.ambient_light_energy = energia * _lum(antes) / _lum(t)


func _luz_kael_dentro(peso: float) -> void:
	var l: Dictionary = Interiores.LUZ_KAEL.get(interior, {})
	if l.is_empty():
		return
	if _luz_en != interior:
		_luz_en = interior
		ambiente.background_color = Interiores.FONDO_DENTRO
		ambiente.fog_enabled = false
		ambiente.ambient_light_color = l["amb_color"]
		sol.light_color = l["sol_color"]
	var v: Vector2 = interiores.sonda(kael.global_position)
	_sol_k = lerpf(_sol_k, v.x, peso)
	_cielo_k = lerpf(_cielo_k, v.y, peso)
	sol.light_energy = float(l["sol"]) * (1.0 + SOL_MANCHA * clampf(_sol_k, 0.0, 1.0))
	ambiente.ambient_light_energy = float(l["amb"]) * clampf(0.85 + 0.5 * _cielo_k, 0.95, 1.35)


# La dirección y el largo de la sombra larga (los de la muestra: el sol horneado, 1,45 m de Kael).
func _crear_sombra_kael() -> void:
	var hs: Array = luz.get("hacia_sol", [-0.73, 0.45, 0.51])
	var lejos := -Vector2(hs[0], hs[2]).normalized()
	var elev := asin(clampf(float(hs[1]), -1.0, 1.0))
	var largo := clampf(1.45 / tan(maxf(elev, 0.2)), 1.2, 3.4)
	for s in materiales_sector:
		for m in materiales_sector[s]:
			m.set_shader_parameter("sombra_dir", lejos)
			m.set_shader_parameter("sombra_largo", largo)
	for m in materiales_comunes:
		m.set_shader_parameter("sombra_dir", lejos)
		m.set_shader_parameter("sombra_largo", largo)


# La sombra de contacto y la larga de Kael (corrección 3 de la muestra), solo en los materiales que se dibujan ahora:
# los comunes y los de los sectores visibles.
func _sombras_kael() -> void:
	if kael == null or acabados.is_empty():
		return
	var p := kael.global_position if interior == "" else Vector3(0.0, -100.0, 0.0)
	var s := clampf(_sol_k, 0.0, 1.0)
	var larga := 0.62 * s
	var contacto := lerpf(0.70, 0.78, s)
	var lista: Array = materiales_comunes.duplicate()
	for q in materiales_sector:
		if visibles.get(q, true):
			lista.append_array(materiales_sector[q])
	for m in lista:
		m.set_shader_parameter("kael_pos", p)
		m.set_shader_parameter("sombra_fuerza", larga)
		m.set_shader_parameter("contacto_fuerza", contacto)
		m.set_shader_parameter("sol_kael", s)


# Visibilidad manual por sector (plan §8). En Blender se midió, desde cada cámara posible (Kael en cada metro de lo
# andable), qué parte de la pantalla ocupa cada sector (una rejilla de 64 × 36 rayos: barrio_luz.json, «camaras» y
# «cobertura»). Aquí se toman las 3 cámaras medidas más cercanas a la de ahora y se dibujan los sectores que ocupan al
# menos UMBRAL_VISTA de la pantalla en alguna de ellas, más el de Kael y los que siguen en blockout. Dentro de un
# interior, el exterior entero ya está oculto.
const UMBRAL_VISTA := 0.025                # lo fijo de un sector (con su mapa de luz) se dibuja si ocupa ≥ 2,5 % (≈ 58 rayos)
const UMBRAL_DETALLE := 0.015              # sus piezas (losas, atrezo) y su vegetación, si sus piezas ocupan ≥ 1,5 %
var _camaras_medidas: Array = []           # [Vector3]
var _detalle := {}                         # sector → [MeshInstance3D] de piezas y vegetación
var detalle_visible := {}                  # sector → true si se dibujan sus piezas y su vegetación (para las medidas)


func _cobertura(cob: Dictionary, clave: String, cerca: Array) -> float:
	var f: Array = cob.get(clave, [])
	var k := 0.0
	for c in cerca:
		if int(c[1]) < f.size():
			k = maxf(k, float(f[c[1]]))
	return k


func _actualizar_visibles() -> void:
	var cob: Dictionary = luz.get("cobertura", {})
	if acabados.is_empty() or cob.is_empty() or kael == null or cam == null:
		return
	if _camaras_medidas.is_empty():
		for c in luz.get("camaras", []):
			_camaras_medidas.append(Vector3(c[0], c[1], c[2]))
	var p := T.foco_camara(kael.global_position) + T.OFFSET_CAMARA
	var cerca: Array = []                      # [[distancia², índice]] de las 3 más cercanas
	for i in _camaras_medidas.size():
		var d: float = (_camaras_medidas[i] as Vector3).distance_squared_to(p)
		if cerca.size() < 3 or d < cerca[-1][0]:
			cerca.append([d, i])
			cerca.sort_custom(func(a, b): return a[0] < b[0])
			if cerca.size() > 3:
				cerca.pop_back()
	var aqui := T.sector_de(kael.global_position.x, kael.global_position.z)
	for s in T.ORDEN:
		var k := 1.0 if s == aqui else _cobertura(cob, s, cerca)                 # lo fijo
		var kd := 1.0 if s == aqui else _cobertura(cob, s + "/piezas", cerca)    # las piezas (losas, atrezo)
		var ver: bool = k >= UMBRAL_VISTA or kd >= UMBRAL_DETALLE or not s in acabados
		var entero: bool = kd >= UMBRAL_DETALLE or not s in acabados
		visibles[s] = ver
		detalle_visible[s] = ver and entero
		(sectores[s] as Node3D).visible = ver
		for mi in _detalle.get(s, []):
			(mi as MeshInstance3D).visible = entero


func ancla(id: String) -> Vector3:
	if id.begins_with("int_"):
		return interiores.ancla(id) if interiores != null else Vector3.ZERO
	return T.ancla(id)


# Empieza un diálogo de Dialogic. Sus señales «bar:…» van a Barrio.aplicar; al acabar se guarda y se reanudan las
# rutinas. false si no se pudo (no hay Dialogic, no existe la ruta o ya hay otro).
func iniciar_dialogo(ruta: String) -> bool:
	var dg = get_node_or_null("/root/Dialogic")
	if dg == null or ruta == "" or not ResourceLoader.exists(ruta) or dg.current_timeline != null:
		return false
	_parar_kael()
	boton_accion.visible = false
	_ocultar_aviso()                               # (petición 2 de C: el aviso no se superpone al globo)
	dialogo_actual = ruta
	dg.start(ruta)
	return true


func _ocultar_aviso() -> void:
	if _tween_aviso != null and _tween_aviso.is_valid():
		_tween_aviso.kill()
	if aviso != null:
		aviso.modulate.a = 0.0


func _al_senal(arg) -> void:
	var s := str(arg)
	if not s.begins_with("bar:"):
		return
	var t := Barrio.aplicar(s)
	if t != "":
		_avisos_cola.append(t)


func _al_terminar_dialogo() -> void:
	if dialogo_actual == "":
		return                                     # (un diálogo que no empezó el barrio)
	dialogo_actual = ""
	_bloqueo = 0.4
	guardar()
	if vivo != null:
		vivo.reanudar_todos()


# ================================================================= cada fotograma

func _process(delta: float) -> void:
	if kael == null or fuera_del_banco:
		return
	_bloqueo = maxf(0.0, _bloqueo - delta)
	if ocupado():
		_parar_kael()
		boton_accion.visible = false
		_colocar_camara(1.0 - exp(-suavizado * delta))
		return
	if not _avisos_cola.is_empty() and (_tween_aviso == null or not _tween_aviso.is_running()):
		avisar(str(_avisos_cola.pop_front()), "", 3.2)
	_rodear(delta)
	super(delta)
	_luz_kael(1.0 - exp(-6.0 * delta))
	_sombras_kael()
	_t_visibles -= delta
	if _t_visibles <= 0.0:
		_t_visibles = HZ_VISIBLES
		_actualizar_visibles()
	_comprobar_cerca()
	_t_puertas -= delta
	if _t_puertas <= 0.0:
		_t_puertas = 0.25
		_preparar_cercanos()


func _preparar_cercanos() -> void:
	if interior != "" or interiores == null:
		return
	for id in T.PUERTAS:
		if not _preparados.has(id) and Interiores.ORIGEN.has(id) \
				and _dist_plana(kael.global_position, T.PUERTAS[id]["fuera"]) < DIST_PREPARAR:
			_preparados[id] = true
			interiores.preparar(id)


func _dist_plana(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


# ================================================================= lo que se usa

# [id, posición, radio, texto del botón] de lo que hay en la zona de Kael (fuera o en su interior).
func piezas_al_alcance() -> Array:
	var r: Array = []
	if interior == "":
		for id in T.PUERTAS:
			var d: Dictionary = T.PUERTAS[id]
			var texto: String = d["texto"]
			if id == "vivienda" and Barrio.activado() and Barrio.interior_hecho("vivienda") and not Barrio.estado("viv_llamado"):
				texto = "Llamar a la puerta"                 # (integración: la primera vez se llama; C, puerta())
			r.append(["entrar_" + id, d["fuera"], d["radio"], texto])
	elif interiores != null:
		r.append(["salir_" + interior, interiores.salida(interior), RADIO_SALIR, "Salir"])
	_ids_vivo.clear()
	if vivo != null:
		for pz in vivo.piezas():
			_ids_vivo[str(pz[0])] = true
			r.append(pz)
	for pid in Barrio.PIEZAS:
		var d: Dictionary = Barrio.PIEZAS[pid]
		var a := str(d.get("ancla", ""))
		var de_dentro := a.begins_with("int_")
		if (interior == "" and de_dentro) or (interior != "" and not a.begins_with("int_%s_" % interior)):
			continue
		r.append([pid, ancla(a), float(d.get("radio", 1.4)), Barrio.boton(pid)])   # (petición 1 de C: según el estado)
	return r


func _comprobar_cerca() -> void:
	cerca = ""
	var mejor := INF
	var p := kael.global_position
	for pz in piezas_al_alcance():
		var q: Vector3 = pz[1]
		var d := _dist_plana(p, q)
		if d < float(pz[2]) and d < mejor and absf(p.y - q.y) < 1.6:
			mejor = d
			cerca = pz[0]
			boton_accion.text = pz[3]
	boton_accion.visible = cerca != "" and _bloqueo <= 0.0


func _unhandled_input(ev: InputEvent) -> void:
	if fuera_del_banco or kael == null or ocupado():
		return
	if ev.is_action_pressed("ui_accept") and boton_accion.visible:
		_accion()
		get_viewport().set_input_as_handled()
		return
	super(ev)


func _accion() -> void:
	if _bloqueo > 0.0 or ocupado() or cerca == "":
		return
	_bloqueo = 0.5
	var id := cerca
	if id.begins_with("entrar_"):
		_entrar(id.trim_prefix("entrar_"))
	elif id.begins_with("salir_"):
		_salir_interior()
	elif _ids_vivo.has(id):
		vivo.hablar(id)
	else:
		_accion_barrio(id)


func _accion_barrio(pid: String) -> void:
	var r: Dictionary = Barrio.accion(pid)
	if r.is_empty():
		return
	if str(r.get("dialogo", "")) != "" and iniciar_dialogo(str(r["dialogo"])):
		pass
	elif str(r.get("texto", "")) != "":
		avisar(str(r["texto"]), str(r.get("efecto", "")))
	if r.get("guardar", false):
		guardar()


# ================================================================= puertas e interiores (con el agente B)

func _entrar(id: String) -> void:
	if not puede_pasar():
		avisar(Barrio.TEXTO_PROLOGO, "", 2.8)
		return
	var a := Barrio.puerta(id)
	if a != "":
		avisar(a, "", 2.8)
		return
	if not Interiores.ORIGEN.has(id):
		avisar(TEXTO_OBRAS, "", 2.4)
		return
	interiores.preparar(id)
	await _fundir(_pasar_dentro.bind(id))
	if is_inside_tree():
		guardar_posicion()


func _pasar_dentro(id: String) -> void:
	interior = id
	interiores.mostrar(id)
	exterior.visible = false
	_colocar_kael(interiores.entrada(id))
	_mirar_kael(interiores.mira_entrada(id))
	if grupo != null:
		grupo.colocar(Vector3.BACK)
	if vivo != null:
		vivo.al_interior(id)
	interior_cambiado.emit(id)


func _salir_interior() -> void:
	if interior == "":
		return
	await _fundir(_pasar_fuera)
	if is_inside_tree():
		guardar_posicion()


func _pasar_fuera() -> void:
	var id := interior
	interior = ""
	interiores.mostrar("")
	exterior.visible = true
	var d: Dictionary = T.PUERTAS.get(id, {"fuera": T.INICIO, "mira": 0.0})
	_colocar_kael(d["fuera"])
	_mirar_kael(float(d["mira"]))
	if grupo != null:
		grupo.colocar(Vector3.BACK)
	if vivo != null:
		vivo.al_interior("")
	interior_cambiado.emit("")


# El fundido de las puertas (plan §3: 0,35 s a negro, 0,15 s, 0,35 s de vuelta), sin cambio de escena.
func _fundir(cambio: Callable) -> void:
	if cambiando:
		return
	cambiando = true
	_parar_kael()
	boton_accion.visible = false
	var t := create_tween()
	t.tween_property(fundido, "color:a", 1.0, FUNDIDO[0])
	await t.finished
	cambio.call()
	await get_tree().create_timer(FUNDIDO[1]).timeout
	if not is_inside_tree():
		return
	t = create_tween()
	t.tween_property(fundido, "color:a", 0.0, FUNDIDO[2])
	await t.finished
	cambiando = false


# ================================================================= interfaz

func _crear_interfaz() -> void:
	capa_ui = CanvasLayer.new()
	capa_ui.layer = 50
	add_child(capa_ui)
	titulo = Label.new()
	titulo.text = "Barrio de Oakhaven (en pruebas) · %s · perfil %s" % [
		"bloques provisionales" if acabados.is_empty() else "%d de 6 tramos horneados" % acabados.size(), nombre_perfil]
	titulo.position = Vector2(250, 40)
	titulo.add_theme_font_size_override("font_size", 18)
	titulo.add_theme_color_override("font_color", Color(1.0, 0.95, 0.84))
	titulo.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.06, 0.85))
	titulo.add_theme_constant_override("outline_size", 6)
	capa_ui.add_child(titulo)
	boton_accion = Button.new()
	boton_accion.position = Vector2(960, 600)
	boton_accion.custom_minimum_size = Vector2(290, 84)
	boton_accion.add_theme_font_size_override("font_size", 28)
	boton_accion.focus_mode = Control.FOCUS_NONE
	boton_accion.visible = false
	boton_accion.pressed.connect(_accion)
	capa_ui.add_child(boton_accion)
	boton_recargar = Button.new()                  # plan §7: la prueba de guardar y cargar de verdad (solo en el banco)
	boton_recargar.text = "Guardar y recargar"
	boton_recargar.position = Vector2(16, 152)
	boton_recargar.custom_minimum_size = Vector2(210, 48)
	boton_recargar.add_theme_font_size_override("font_size", 19)
	boton_recargar.focus_mode = Control.FOCUS_NONE
	boton_recargar.pressed.connect(guardar_y_recargar)
	capa_ui.add_child(boton_recargar)
	aviso = Label.new()
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	aviso.size = Vector2(1000, 120)
	aviso.position = Vector2(140, 470)
	aviso.add_theme_font_size_override("font_size", 28)
	aviso.add_theme_color_override("font_color", Color(1.0, 0.97, 0.88))
	aviso.add_theme_color_override("font_outline_color", Color(0.16, 0.10, 0.08, 0.9))
	aviso.add_theme_constant_override("outline_size", 8)
	aviso.modulate.a = 0.0
	capa_ui.add_child(aviso)
	fundido = ColorRect.new()
	fundido.color = Color(0, 0, 0, 0)
	fundido.size = Vector2(1280, 720)
	fundido.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa_ui.add_child(fundido)


# «Guardar y recargar» (plan §7): guarda, lee el archivo del banco, lo restaura y vuelve a ESTA escena directamente
# (restaurar devolvería el mapa para zonas3d/ si la exploración 3D está apagada).
func guardar_y_recargar() -> void:
	if ocupado() or not en_banco_pruebas() or not has_node("/root/Recursos") or Recursos.cambiando:
		return
	guardar()
	var d = Progreso.leer(Progreso.archivo())
	if d is Dictionary:
		Progreso.restaurar(d)
	Recursos.cambiar_escena(scene_file_path)
